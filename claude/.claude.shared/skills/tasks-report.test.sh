#!/usr/bin/env bash
# Tests tasks-report.sh against stub aven and agent-manager on PATH.
# Run: bash tasks-report.test.sh
set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/tasks-report.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin" "$tmp/plain" "$tmp/jira"
export LOG="$tmp/log" NOTES="$tmp/notes.json" SESSIONS="$tmp/sessions.json"

cat >"$tmp/bin/aven" <<'EOF'
#!/usr/bin/env bash
echo "aven $*" >>"$LOG"
case $1 in
  context) cat "$NOTES" ;;
  note) [[ -z ${AVEN_NOTE_FAIL:-} ]] || exit 1; cat >>"$LOG" ;;
esac
EOF
cat >"$tmp/bin/agent-manager" <<'EOF'
#!/usr/bin/env bash
echo "agent-manager $*" >>"$LOG"
case $1 in
  sessions) cat "$SESSIONS" ;;
  send) [[ -z ${SEND_FAIL:-} ]] || { echo "no such session" >&2; exit 1; } ;;
esac
EOF
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH"

git -C "$tmp/jira" init -q
mkdir -p "$tmp/jira/docs/agents"
printf '# Tracker\n\n## Local orchestration: aven\n' >"$tmp/jira/docs/agents/issue-tracker.md"

notes() { jq -n '{notes: [$ARGS.positional[] | {body: .}]}' --args "$@" >"$NOTES"; }
session() { printf '{"id":"%s","name":"%s","group":"%s","running":%s,"archived":%s}' "$@"; }
sessions() { jq -s . >"$SESSIONS"; }

owned() { notes "Orchestrated by old in dotfiles" "Report: started - x" "Orchestrated by tasks in dotfiles"; }
decoys() {
  session d1 tasks other true false
  session d2 tasks dotfiles true true
  session d3 tasks dotfiles false false
  session d4 old dotfiles true false
}

fails=0
# check <name> <want rc> <want stdout> <dir> -- <args...>
check() {
  local name=$1 want_rc=$2 want_out=$3 dir=$4 rc=0 out
  shift 5
  : >"$LOG"
  out=$(cd "$dir" && bash "$script" "$@" 2>/dev/null) || rc=$?
  if [[ $rc != "$want_rc" || $out != "$want_out" ]]; then
    echo "FAIL $name: rc=$rc out='$out' (want rc=$want_rc out='$want_out')"
    fails=$((fails + 1))
  fi
}
logged() { grep -qF -- "$2" "$LOG" || { echo "FAIL $1: log lacks '$2'"; fails=$((fails + 1)); }; }
unlogged() { ! grep -qF -- "$2" "$LOG" || { echo "FAIL $1: log has '$2'"; fails=$((fails + 1)); }; }

owned
{ decoys; session own tasks dotfiles true false; } | sessions

for s in started waiting; do
  check "$s no ping" 0 "noted" "$tmp/plain" -- REF-1 "$s" "one line"
  logged "$s note" "Report: $s - one line"
  unlogged "$s no ping" "agent-manager"
done
for s in landing blocked handover review "done"; do
  check "$s pings" 0 "noted, pinged tasks in dotfiles (own)" "$tmp/plain" -- REF-1 "$s" "one line"
  logged "$s note" "Report: $s - one line"
  logged "$s ping" "agent-manager send own [tasks] REF-1 $s: one line"
done
unlogged "plain workspace" "--workspace"

check "jira workspace" 0 "noted" "$tmp/jira" -- REF-1 started "x"
logged "jira context" "aven context REF-1 --json --full --workspace work"
logged "jira note" "aven note REF-1 --stdin --workspace work"

decoys | sessions
check "owner not running" 0 "noted, owner tasks in dotfiles not running" "$tmp/plain" -- REF-1 landing "x"
logged "owner not running note" "Report: landing - x"
unlogged "owner not running" "agent-manager send"

{ session a tasks dotfiles true false; session b tasks dotfiles true false; } | sessions
check "ambiguous" 0 "noted, owner ambiguous: 2 sessions named tasks in dotfiles" "$tmp/plain" -- REF-1 "done" "x"
unlogged "ambiguous" "agent-manager send"

session own tasks dotfiles true false | sessions
SEND_FAIL=1 check "send fails" 0 "noted, ping failed: no such session" "$tmp/plain" -- REF-1 "done" "x"

AVEN_NOTE_FAIL=1 check "note fails" 1 "" "$tmp/plain" -- REF-1 "done" "x"
unlogged "note fails" "agent-manager"

notes "Report: started - x" "Coordination: nothing"
check "not orchestrated" 2 "" "$tmp/plain" -- REF-1 "done" "x"
unlogged "not orchestrated" "aven note"

owned
check "unknown state" 2 "" "$tmp/plain" -- REF-1 finished "x"
check "missing line" 2 "" "$tmp/plain" -- REF-1 "done"
unlogged "bad usage" "aven"

if ((fails > 0)); then echo "$fails failed"; exit 1; fi
echo ok
