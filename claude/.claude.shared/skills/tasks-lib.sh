# shellcheck shell=bash
# Sourced by tasks-report.sh and tasks-board.sh: the aven workspace and the
# owner lookup.

# aven + Jira repos keep their tasks in the work workspace (see trackers.md).
ws=
if common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) &&
  grep -q '^## Local orchestration: aven' "$(dirname "$common")/docs/agents/issue-tracker.md" 2>/dev/null; then
  ws=work
fi
av() { aven "$@" ${ws:+--workspace "$ws"}; }

# jq definitions, prefixed to a filter. On `aven context --json --full`:
# latest($p) is the first line of the last note starting with $p, $p stripped,
# and owner is the latest Orchestrated by note as {name, group} or null. Last
# by array order: two notes can share a created_at second. On `agent-manager
# sessions --json`: live($o) lists the running, non-archived sessions named
# $o.name in group $o.group.
# shellcheck disable=SC2016,SC2034 # jq source, used by the sourcing scripts
tasks_jq='
def latest($p): [.notes[].body | split("\n")[0] | select(startswith($p)) | ltrimstr($p)] | last;
def owner: (latest("Orchestrated by ") | values | capture("^(?<name>.*?) in (?<group>.*)$")) // null;
def live($o): [.[] | select(.name == $o.name and .group == $o.group and .running and (.archived | not))];
'
