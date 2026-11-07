#!/usr/bin/env bash
# Usage: tasks-report.sh <ref> <state> "<one line>"
# Writes a worker's report note on an orchestrated task, then pings the task's
# owner for the states that ping. Prints one line. Exit 0: noted (a failed ping
# only warns). 1: the note failed, no ping. 2: bad usage, unknown state or task
# not orchestrated; nothing written.
set -euo pipefail

usage() {
  echo "usage: tasks-report.sh <ref> <started|waiting|landing|blocked|handover|review|done> \"<one line>\"" >&2
  exit 2
}
[[ $# -eq 3 && -n $1 && -n $3 ]] || usage
ref=$1 state=$2 line=$3
case $state in
  started | waiting) ping=false ;;
  landing | blocked | handover | review | done) ping=true ;;
  *) usage ;;
esac

# shellcheck source=tasks-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/tasks-lib.sh"

if ! owner=$(av context "$ref" --json --full | jq -r "$tasks_jq"'owner | values | "\(.name) in \(.group)"'); then
  echo "tasks-report: cannot read $ref" >&2
  exit 2
fi
if [[ -z $owner ]]; then
  echo "tasks-report: $ref has no Orchestrated by note, so there is no owner to report to" >&2
  exit 2
fi
name=${owner%% in *} group=${owner#* in }

if ! printf 'Report: %s - %s\n' "$state" "$line" | av note "$ref" --stdin >/dev/null; then
  echo "tasks-report: aven note failed, no ping sent" >&2
  exit 1
fi
if ! $ping; then
  echo noted
  exit 0
fi

if ! sessions=$(agent-manager sessions --json) ||
  ! match=$(jq -r --arg n "$name" --arg g "$group" \
    "$tasks_jq"'live({name: $n, group: $g}) | map(.id) | "\(length) \(.[0] // "")"' <<<"$sessions"); then
  echo "noted, ping failed: cannot list agent-manager sessions"
  exit 0
fi
count=${match%% *} id=${match#* }

if ((count == 0)); then
  echo "noted, owner $name in $group not running"
elif ((count > 1)); then
  echo "noted, owner ambiguous: $count sessions named $name in $group"
elif err=$(agent-manager send "$id" "[tasks] $ref $state: $line" 2>&1 >/dev/null); then
  echo "noted, pinged $name in $group ($id)"
else
  echo "noted, ping failed: ${err%%$'\n'*}"
fi
