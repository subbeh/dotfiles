#!/usr/bin/env bash
# Usage: tasks-board.sh [<epic ref>]
# Prints the task board for the repo's aven project (run from the repo), or for
# one epic's children: a header line, then one key=value line per open task in
# pickup's order. Row fields: owner (self, "<name> in <group>" or -),
# owned_elsewhere=yes (owner is another running session), claimed (a running
# session the latest claim line names, other than the worker), worker and
# worker_status (newest non-archived session named after the ref), report
# (latest Report: note), and jira (mirrored key), parent (epic ref), blocked,
# epic, os=other, offer=yes (a start candidate) only when they apply. Header: scope, inbox count, live/ leases and
# strays (archived sessions of this repo still running).
set -euo pipefail
shopt -s inherit_errexit

[[ $# -le 1 ]] || {
  echo "usage: tasks-board.sh [<epic ref>]" >&2
  exit 2
}
# shellcheck source=tasks-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/tasks-lib.sh"

err=$(mktemp)
trap 'rm -f "$err"' EXIT
if [[ -n ${1:-} ]]; then
  scope="epic $1"
  children=$(av epic list "$1" --json | jq '[.children[] | select(.open) | .ref]')
  tasks=$(av list --open --all-projects --json | jq --argjson c "$children" '[.[] | select(.ref | IN($c[]))]')
else
  tasks=$(av list --open --json 2>"$err") || {
    cat "$err" >&2
    exit 1
  }
  # aven names the inferred project on stderr: "scope: project <name> (...)".
  scope=$(sed -n 's/^scope: \(project [^ ]*\).*/\1/p' "$err")
fi

notes=$(for ref in $(jq -r '.[].ref' <<<"$tasks"); do
  av context "$ref" --json --full | jq --arg r "$ref" '{($r): .}'
done | jq -s 'add // {}')
sessions=[] leases=[]
if command -v agent-manager >/dev/null; then
  sessions=$(agent-manager sessions --json)
  leases=$(agent-manager reservations --json)
fi
repo=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
case $(uname -s) in
  Darwin) other=arch ;;
  *) other=macos ;;
esac

jq -rn "$tasks_jq"'
# Bare when it is one token, else quoted; "-" for nothing.
def v: if . == null or . == "" then "-" elif test("^[^\\s\"=]+$") then . else @json end;
def rank($xs): . as $x | $xs | index($x) // length;
($sessions | map(select(.self)) | first) as $self
| ($sessions | map(select(.running)) | map({key: "\(.name)\t\(.directory)", value: true}) | from_entries) as $running
| [ "scope=\($scope | v)",
    "inbox=\($tasks | map(select(.status == "inbox")) | length)",
    "leases=\($leases | map(select(.pattern | startswith("live/")) | "\(.pattern) by \(.holder)") | join(", ") | v)",
    "strays=\($sessions | map(select(.archived and .running and (.directory == $repo or (.directory | startswith($repo + "-worktrees/")))) | "\(.name)(\(.id))") | join(" ") | v)"
  ] | join(" "),
( $tasks
  | sort_by((.status | rank(["active", "todo", "backlog", "inbox"])),
            (.priority | rank(["urgent", "high", "medium", "low", "none"])),
            (.updated_at | fromdateiso8601 | -.))
  | .[]
  | . as $t
  | ($t.ref | ascii_downcase) as $pre
  | ($notes[$t.ref] | owner) as $owner
  | ($sessions | map(select((.archived | not) and (.name == $pre or (.name | startswith($pre + "-"))))) | last) as $worker
  | (($notes[$t.ref] | latest("Claimed by ") | values | capture("^(?<name>.*?) in (?<dir>.*)$")
      | select($running["\(.name)\t\(.dir)"] and .name != $worker.name) | .name) // null) as $claimed
  | (if $owner == null then null
     elif $self and $owner.name == $self.name and $owner.group == $self.group then "self"
     else "\($owner.name) in \($owner.group)" end) as $own
  | ($own != null and $own != "self" and ($sessions | live($owner) | length > 0)) as $elsewhere
  | ($t.labels | index($other) != null) as $os
  | [ $t.ref,
      "status=\($t.status)", "priority=\($t.priority)", "labels=\($t.labels | join(",") | v)",
      "owner=\($own | v)",
      (select($elsewhere) | "owned_elsewhere=yes"),
      "claimed=\($claimed | v)",
      "worker=\($worker | if . then "\(.name)(\(.id))" else null end | v)",
      "worker_status=\($worker.status | v)",
      "report=\($notes[$t.ref] | latest("Report: ") | v)",
      ($notes[$t.ref].metadata.jira | values | "jira=\(v)"),
      ($t.epic_parent.ref | values | "parent=\(v)"),
      (select($t.blocked_by > 0) | "blocked=yes"),
      (select($t.is_epic) | "epic=yes"),
      (select($os) | "os=other"),
      (select($own == null and $claimed == null and ($worker.running | not) and $t.blocked_by == 0
              and ($t.is_epic | not) and ($os | not)) | "offer=yes"),
      "title=\($t.title | @json)"
    ] | join(" ")
)' --arg scope "$scope" --arg repo "$repo" --arg other "$other" \
  --argjson tasks "$tasks" --argjson notes "$notes" \
  --argjson sessions "$sessions" --argjson leases "$leases"
