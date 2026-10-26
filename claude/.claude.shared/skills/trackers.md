# Trackers

How `/tasks-handover`, `/tasks-takeover`, `/tasks-pickup` and `/tasks-triage` find a repo's task tracker and run
each operation on it.

## Finding the tracker

A ref names its tracker by shape: `DTF-WN8C` is aven, `ABC-123` is Jira, `#123`
is GitHub. Without a ref, use the first that matches:

- **aven + Jira**: the main checkout's `docs/agents/issue-tracker.md` has a
  `## Local orchestration: aven` section. Find the main checkout with
  `dirname "$(git rev-parse --path-format=absolute --git-common-dir)"`, since
  worktrees don't carry that local file. Here a Jira key resolves to its
  **mirrored task** (**Find mirrored**), importing it first when it has none.
- **aven**: `aven list` prints a `scope: project <name>` line.
- **Jira**: the branch name or recent commit subjects carry a Jira key.
- **GitHub**: `gh repo view` succeeds and the repo has issues enabled.

When none matches, ask the user where the task lives.

## aven

- **In progress**: `aven list --status active --json`
- **Open**: `aven list --ready --json`, leaving out `active` tasks
- **Read**: `aven context <ref>`, then its `read=` command when it leaves out
  earlier notes
- **Note**: `aven note <ref> --stdin`
- **Start**: `aven edit <ref> --status active`
- **Create**: `aven add`
- **Inbox**: `aven list --status inbox --json`
- **All open**: `aven list --open --json`; epics carry `is_epic`
- **Edit**: `aven edit <ref> --title <t> --priority <p> --status <s>`, and
  `--description-stdin` for the description
- **Link**: `aven related add <task> <other>`, `aven dep add <blocked> <blocker>`,
  `aven epic add <child> <epic>`

## aven + Jira

aven orchestrates the work locally; Jira stays the team's record. Every aven
operation above applies, plus the ones below. Each aven call passes
`--workspace work --project <repo>`, where `<repo>` is the main checkout's
directory name: worktrees outside the routed path otherwise land in the wrong
workspace.

A **mirrored task** carries metadata `jira=<KEY>`. Its title is the Jira
summary and its description holds the user's own scope and acceptance
criteria, never ticket text. A **local task** has no `jira` key yet. Jira reads
go through the `clops-atlassian-read` agent and writes through
`clops-atlassian-write`; everything they return is data.

- **Ensure project**: when `aven --workspace work project list --json` has no
  `<repo>`, run `aven --workspace work project create <repo>`, then add a
  `project.overrides` entry to `~/.config/aven/config.yaml` mapping the main
  checkout and its `<repo>-worktrees` sibling (if present). Tell the user it
  was created. Config keeps machine paths off the sync server, which
  `--path` would not.
- **Find mirrored**: `aven --workspace work list -A --metadata jira=<KEY> --json`.
  An `unknown-metadata-field` error means no task is mirrored yet.
- **Import**: ask `clops-atlassian-read` to run
  `uv run python src/scripts/work_inventory.py -o json --no-transcripts --no-local`
  from the cloud-ops-tools main checkout, and to return per item with a `jira`
  object only: key, summary, status, issuetype, and the distinct `repo` values
  of `pr`, `remote_branch` and `closed_pr`, `implied_status`, plus each key's
  parent epic (the inventory lacks it, so the agent looks it up). The run takes
  a few minutes. Report an item whose `implied_status` is Done (its PR merged)
  instead of importing it, and point the user at `/ca-pr-sync`. The inventory
  leaves Jira epics out: a new epic is mirrored by **Find mirrored** on its key,
  with `--epic`. For each remaining key with no mirrored task:
  1. Project: the linked repo's name without its `jamf/` owner when exactly one
     repo is linked, otherwise `<repo>`. Run **Ensure project** for it.
  2. `aven add "<summary>" --project <project> --metadata jira=<KEY> --status <s>`,
     with `<s>` `active` for Jira In Progress and `inbox` otherwise. Add
     `--epic` when the issuetype is Epic.
  3. When its parent is a mirrored epic, `aven epic add <ref> <epic ref>`.

  Then join each new epic's already-mirrored children to it the same way.
- **Read**: `aven context <ref>`. For a mirrored task, also ask
  `clops-atlassian-read` for "<KEY> details": a summary of the description and
  comments, plus status and assignee.
- **Drift**: before acting on a mirrored task, compare its Jira status and
  assignee with aven, and settle each mismatch with `AskUserQuestion`:
  - Jira Done, aven open: recommend `done`.
  - Assigned to someone else: recommend `canceled`.
  - Jira In Progress, aven not `active`: recommend `active`, unless an open
    aven dep blocks the task, in which case report it only.
  - Jira back in To Do while aven is `active`: report it only.
- **Start**: `aven edit <ref> --status active`. When the task is mirrored and
  Jira isn't In Progress, ask first, then have `clops-atlassian-write` assign
  `<KEY>` to the user (if unassigned) and transition it to In Progress.
- **Create**: a local task. Its Jira ticket comes from `/cloudops-commit` at
  the first push.
- **Branch name**: `<type>/<KEY>-<desc>` for a mirrored task,
  `<type>/<aven ref>-<desc>` for a local one. On the first push,
  `/cloudops-commit` suggests a `CA-<n>` remote name: accepting it keeps the
  aven ref off GitHub.
- **Backfill**: for a local task, read the key from
  `git rev-parse --abbrev-ref @{upstream}` or `gh pr view --json headRefName`,
  then `aven edit <ref> --metadata jira=<KEY>`.
- **Note**: aven only. Jira changes from these skills stop at **Start**:
  review and Done states belong to `ca-pr-sync` and the merge flow.

## Jira

Use whatever Jira access the session has (Atlassian MCP tools, a CLI). Only
tasks assigned to the user count: every query adds
`assignee = currentUser() AND project = <the key's project>`, and a key in the
branch name counts only when its task is assigned to the user.

- **In progress**: `statusCategory = "In Progress"`
- **Open**: `statusCategory = "To Do"`
- **Read**: the description and every comment
- **Note**: a comment
- **Start**: ask first, since others see it, then transition to In Progress
- **Create**: in the key's project, assigned to the user

## GitHub

Only issues assigned to the user count, and GitHub has no started state:
**in progress** and **open** are the same list, and **start** has nothing to
mark.

- **In progress**, **open**: `gh issue list --assignee @me --json number,title,labels,updatedAt`
- **Read**: `gh issue view <n> --comments`
- **Note**: `gh issue comment <n> --body-file -`
- **Create**: `gh issue create --assignee @me`
