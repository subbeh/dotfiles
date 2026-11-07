#!/usr/bin/env bash
# Tests tasks-board.sh against stub aven, agent-manager and uname on PATH.
# Run: bash tasks-board.test.sh
set -euo pipefail

script="$(cd "$(dirname "$0")" && pwd)/tasks-board.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin" "$tmp/notes" "$tmp/repo"
git -C "$tmp/repo" init -q
repo=$(cd "$tmp/repo" && pwd -P)
export TASKS="$tmp/tasks.json" EPIC="$tmp/epic.json" NOTES="$tmp/notes" \
  SESSIONS="$tmp/sessions.json" LEASES="$tmp/leases.json" UNAME=Linux

cat >"$tmp/bin/aven" <<'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "list --open") [[ $3 == --all-projects ]] || echo "scope: project demo (from path)" >&2; cat "$TASKS" ;;
  "epic list") cat "$EPIC" ;;
  context*) cat "$NOTES/$2.json" ;;
esac
EOF
cat >"$tmp/bin/agent-manager" <<'EOF'
#!/usr/bin/env bash
case $1 in
  sessions) cat "$SESSIONS" ;;
  reservations) cat "$LEASES" ;;
esac
EOF
cat >"$tmp/bin/uname" <<'EOF'
#!/bin/sh
echo "$UNAME"
EOF
chmod +x "$tmp/bin/"*
export PATH="$tmp/bin:$PATH"

# task <ref> <status> <priority> <updated day> <labels csv> [blocked_by] [is_epic]
task() {
  jq -n --arg r "$1" --arg s "$2" --arg p "$3" --arg d "$4" --arg l "$5" --argjson b "${6:-0}" --argjson e "${7:-false}" \
    '{ref: $r, status: $s, priority: $p, updated_at: "2026-11-\($d)T00:00:00Z", labels: ($l | split(",") | map(select(. != ""))),
      blocked_by: $b, is_epic: $e, title: "title of \($r)"}'
}
notes() {
  local ref=$1
  shift
  jq -n '{notes: [$ARGS.positional[] | {body: .}]}' --args "$@" >"$NOTES/$ref.json"
}
# session <id> <name> <group> <directory> <running> <archived> [self] [status]
session() {
  jq -n --arg i "$1" --arg n "$2" --arg g "$3" --arg d "$4" --argjson r "$5" --argjson a "$6" --argjson s "${7:-false}" --arg st "${8:-idle}" \
    '{id: $i, name: $n, group: $g, directory: $d, running: $r, archived: $a, self: $s, status: $st}'
}

{
  task T-1 active medium 01 model-opus
  task T-2 active high 02 ""
  task T-3 todo low 03 ""
  task T-4 todo high 04 ""
  task T-5 todo high 05 ""
  task T-6 backlog medium 06 ""
  task T-7 backlog medium 07 macos
  task T-8 backlog medium 08 arch
  task T-9 inbox none 09 ""
  task T-10 todo urgent 10 "" 1
  task T-11 backlog low 11 "" 0 true
  task T-12 active low 12 ""
  task T-13 backlog low 13 ""
} | jq -s 'map(.epic_parent = (if .ref == "T-3" then {ref: "T-E"} else null end))' >"$TASKS"
for r in $(seq 13); do notes "T-$r"; done
notes T-1 "Orchestrated by old in g" "Claimed by t-1-a in $repo" "Report: started - a" "Orchestrated by orch in g" "Report: landing - b
second line"
notes T-2 "Orchestrated by epicorch in g/epic"
notes T-3 "Orchestrated by gone in g"
jq '.metadata = {jira: "CA-1"}' "$NOTES/T-3.json" >"$tmp/x" && mv "$tmp/x" "$NOTES/T-3.json"
notes T-4 "Claimed by someone in /work"
notes T-5 "Claimed by deadone in /work"
notes T-12 "Claimed by t-12-a in $repo"
{
  session s0 orch g "$repo" true false true working
  session s1 t-1-a g "$repo" true false false working
  session s2 epicorch g/epic "$repo" true false
  session s3 orch other "$repo" true false
  session s4 someone g /work true false
  session s5 deadone g /work false false
  session s7 t-6-new g "$repo-worktrees/t-6-old" false false false dead
  session s6 t-6-old g "$repo-worktrees/t-6-old" true true
  session s8 t-60-x g "$repo" true false
  session s9 elsewhere g /other true true
  session s10 t-12-a g "$repo" false false false errored
  session s11 t-13-a g "$repo" true false false working
} | jq -s . >"$SESSIONS"
jq -n '[{pattern: "live/vps/hermes", holder: "t-1-a"}, {pattern: "/abs/file", holder: "x"}]' >"$LEASES"

fails=0
fail() {
  echo "FAIL $*"
  fails=$((fails + 1))
}
run() { out=$(cd "$tmp/repo" && bash "$script" "$@") || fail "exit $? for args: $*"; }
row() { grep -E "^$1 " <<<"$out" || true; }
has() { [[ " $(row "$1") " == *" $2 "* ]] || fail "$1 lacks '$2': $(row "$1")"; }
lacks() { [[ " $(row "$1") " != *" $2"* ]] || fail "$1 has '$2': $(row "$1")"; }

run
header=$(head -1 <<<"$out")
want='scope="project demo" inbox=1 leases="live/vps/hermes by t-1-a" strays=t-6-old(s6)'
[[ $header == "$want" ]] || fail "header: $header"
order=$(tail -n +2 <<<"$out" | cut -d' ' -f1 | tr '\n' ' ')
[[ $order == "T-2 T-1 T-12 T-10 T-5 T-4 T-3 T-8 T-7 T-6 T-13 T-11 T-9 " ]] || fail "order: $order"

has T-1 owner=self
lacks T-1 owned_elsewhere
has T-1 "worker=t-1-a(s1)"
has T-1 worker_status=working
has T-1 claimed=-
has T-1 'report="landing - b"'
lacks T-1 offer
has T-2 'owner="epicorch in g/epic"'
has T-2 owned_elsewhere=yes
lacks T-2 offer
has T-3 'owner="gone in g"'
lacks T-3 owned_elsewhere
lacks T-3 offer
has T-4 claimed=someone
lacks T-4 offer
has T-5 claimed=-
has T-5 offer=yes
has T-6 "worker=t-6-new(s7)"
has T-6 worker_status=dead
has T-6 offer=yes
has T-7 os=other
lacks T-7 offer
lacks T-8 os=
has T-8 offer=yes
has T-9 offer=yes
has T-10 blocked=yes
lacks T-10 offer
has T-11 epic=yes
lacks T-11 offer
has T-12 claimed=-
has T-12 worker_status=errored
has T-12 offer=yes
has T-3 jira=CA-1
has T-3 parent=T-E
lacks T-4 jira=
lacks T-4 parent=
has T-13 claimed=-
lacks T-13 offer
has T-3 'title="title of T-3"'
lacks T-3 worker=t-

UNAME=Darwin run
has T-8 os=other
lacks T-8 offer
lacks T-7 os=
has T-7 offer=yes

jq -n '{epic: {ref: "T-E"}, children: [{ref: "T-3", open: true}, {ref: "T-9", open: true}, {ref: "T-99", open: false}]}' >"$EPIC"
run T-E
[[ $(head -1 <<<"$out") == 'scope="epic T-E" inbox=1 '* ]] || fail "epic header: $(head -1 <<<"$out")"
[[ $(tail -n +2 <<<"$out" | cut -d' ' -f1 | tr '\n' ' ') == "T-3 T-9 " ]] || fail "epic rows: $out"

if ((fails > 0)); then
  echo "$fails failed"
  exit 1
fi
echo ok
