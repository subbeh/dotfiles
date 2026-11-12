---
name: tasks-pickup
description: Run the repo's tasks (or one epic's), or start one task - under agent-manager this session orchestrates a worker session per task; a worker, or a session without agent-manager, works the task itself.
disable-model-invocation: true
---

# Pickup

Starts tasks nobody has begun; `/tasks-takeover` resumes one already in
progress. Under agent-manager this session is the project manager: it starts
each task in a **worker** session of its own, tracks their reports, closes
tasks once landed, and never edits the repo itself. Workers report back
through the protocol in [`../orchestration.md`](../orchestration.md). The
commands behind each **operation** below are in
[`../trackers.md`](../trackers.md), by tracker.

## 1. Set up

Follow **Finding the tracker** in `../trackers.md`. A ref passed as the
argument names its tracker by shape. When it is an aven ref, run
`aven context <ref>`: its notes and `epic=` field pick the mode.

Pick the mode, first match wins:

- **Worker**: the argument is a task whose latest `Orchestrated by` note names
  another session. Go to step 2.
- **Solo**: the tracker is not aven or aven + Jira, `agent-manager` is not on
  PATH, or `agent-manager sessions --json` has no `self` row. Go to step 2.
- **Orchestrator**: everything else. Take this session's name, group and
  directory from the `self` row. The **scope** is the epic passed as the
  argument (`epic=yes`; its children, `aven epic list <epic>`), or else the
  repo's project, leaving out every task in an epic: an epic is run on its
  own with `/tasks-pickup <epic ref>`. In epic scope, the decisions the
  epic's description records are settled, so never ask the user to make them
  again. With a task passed as the argument, run step 2 for it, then **Start
  a task** for it: the Nighthawk check, or on Local worker steps 1–3; then go
  to step 5.
  Otherwise go straight to step 5.

Done when you hold the tracker and the mode, and as orchestrator also your own
name and group and the scope.

## 2. Pick the task

With a ref as the argument, use it. Otherwise print the open tasks as a table
(ref, priority, status, title; on aven + Jira also the `jira` key and the
epic):

- On aven and aven + Jira, run `bash <skill-dir>/../tasks-board.sh` from the
  repo. Its rows other than `status=active` and `os=other` make the table, in
  its order, with `jira` and `parent` for the last two columns. Mark rows with
  an owner or a `claimed` session, and recommend only `offer=yes` rows.
- On other trackers, run the tracker's **open** list: `todo` before
  `backlog`, then highest priority, then most recently updated. Mark a task
  whose latest **claim line** names another session that is still running
  (agent-manager `list_sessions`) as claimed, and leave it out of the
  recommendation.

Ask with `AskUserQuestion`: the top task first as
"(Recommended)", then the next three; "Other" takes any ref from the table.
With no candidates, say so and stop.

When the task's aven status is `inbox`, run [`/tasks-triage`](../tasks-triage/SKILL.md)
on that ref alone, here and before going on. Continue only when triage applied
it as `todo` or `backlog`; when it was skipped or `canceled`, say so and stop
without starting the task.

Done when you hold exactly one ref the user named or confirmed, triaged.

## 3. Read the task

**Read** the task, then the code it touches. For a mirrored task, settle
**Drift** first. Where it leaves scope or acceptance criteria unclear, collect
a question for the user.

Done when you can name the first concrete step, the files it touches, and every
open question.

## 4. Brief and start

**Start** the task, then add a **note** holding the **claim line**:
`Claimed by <session> in <directory>`, where `<session>` is this session's
agent-manager name (the `self` row of `list_sessions`) or `interactive`. When
the work gets its own branch, name it per the tracker's **Branch name**, or put
the ref in it when the tracker has none: that is how `/tasks-takeover` finds the
task later. As a worker, first read [`../orchestration.md`](../orchestration.md) in
full: it holds when to report, the one-PR rule and leases. Then report `started`
with its `tasks-report.sh`, and from then on report each state it lists.

Print the brief:

```text
Pickup: <ref> - <title>
Goal: <what done looks like, one line>
Next: <first step>
Open: <questions for the user, or none>
```

When **Open** is not none, settle it with `AskUserQuestion` first. Then start
on **Next**. Steps 5–7 are the orchestrator's alone.

## 5. Rebuild

Build the state from aven and agent-manager alone: this conversation's memory
of earlier rounds counts for nothing. Run the board from the repo, passing the
epic in epic scope:

```sh
bash <skill-dir>/../tasks-board.sh [<epic ref>]
```

Its first line holds the scope, the `inbox` count, the `live/` leases (see
**Live Services** in `../orchestration.md`) with their holders, and `strays`:
archived sessions still running. Every other line is one open task in scope,
in step 2's order, with its owner, worker session, the worker's status and the
latest `report`; the script's header comment lists every field.
`owned_elsewhere=yes` marks a task whose owner is another session that is
still running.
`nighthawk=<run id>` marks a task whose worker is a Nighthawk run: it has no
session, so take its state from `jx nighthawk runs get <id> -o json`.

Done when you hold this round's board.

## 6. Report and ask

Print one table from the board's rows: ref, priority, title, aven status,
worker session, its model and effort, its state, last report, any `live/` lease
it holds, and `owned by <name>` where that applies. A Nighthawk row shows
`nighthawk <run id>` as its worker and the run's state as its state. Mention
it when more than 3 workers are `working` at once. When `strays` isn't `-`,
name them: archive alone leaves a session running (agent-manager issue #915),
and the user decides whether to kill them.

When a Nighthawk run has opened its draft PR and the row has no `pr`, record
it before asking: **Start** the task if it isn't `active`, add a **note**
with the PR URL and the run's cost, and set the task's `pr` metadata with
**Link** in `../trackers.md`.

When the board's `inbox` count is above 0, first ask with `AskUserQuestion` whether to
triage it now. On yes, triage the inbox (step 7), then go back to step 5.

Ask with `AskUserQuestion`. Options come from the table, recommended in this
order:

1. A dead or errored worker, or a failed or canceled Nighthawk run.
2. A `done` report: close the task.
3. A `handover` report: start the successor.
4. A `landing` report: name the session to attach to, where the go-ahead to
   land its finished work is asked.
5. A `waiting` report: name the session to attach to, where its question is.
6. Start the next task.

Check a session (`agent-manager read`) and take over a task owned elsewhere go
last. A `review` report, or a Nighthawk run whose PR is open, is parked on
teammates and gets no option: show its PR's CI and review state in the table,
and recommend the task again once the user reports the merge (ping its worker
to report `done`, then close it; a Nighthawk task has no worker to ping) or
asks for a fix (ping its worker). A fix on a Nighthawk task has no worker to
ping: run the availability check in `../nighthawk.md`, then launch `jx
nighthawk iterate <KEY> --repo <repo> --pr <n> -o json` through the
`vector-nighthawk:cli` skill, add a **note** `Nighthawk run <id> on <KEY>`,
and report its outcome and cost.

When `../nighthawk.md` exists, a task with a `review` report, or a Nighthawk
run whose PR is open, also gets a "Nighthawk review" option, unless its PR is
a draft the user hasn't marked ready (offer it then only when asked). Run the
availability check, then launch `jx nighthawk run <KEY> --skill pr-review:review
--param pr_url=<url> -o json` through the `vector-nighthawk:cli` skill, add a
**note** `Nighthawk review <id> on <KEY>` (not `Nighthawk run`: the board reads
that as the task's worker), and report the rating, the cost and
that the findings landed in Jira. Acting on them stays the user's call: ping
the worker, or run `iterate`. A task with no `jira` key gets none.

Act on the answer (step 7), then go back to step 5.

A user turn starting with `[tasks]` is a worker's ping. Run step 5 first, then
compare the ping's `<state>: <line>` with the task's `report`
(`<state> - <line>`): when they differ, the ping is stale, so acknowledge it in
one line and stop there. Otherwise continue here and recommend that task first.

## 7. Actions

### Start a task

Show the board's `offer=yes` rows, in its order. Name each option's model and
effort: the task's `model-` and `effort-` labels, else the rule in
[`../worker-sizing.md`](../worker-sizing.md). Ask which one, unless the task
came as the argument.

**Nighthawk check**: when `../nighthawk.md` exists and the tracker is aven +
Jira, read that file and run its availability check. Then ask "Nighthawk fix
(Recommended)" / "Local worker" / "Cancel"; when `unavailable`, drop the first
option and give its setup note. On Nighthawk:

1. Write the ownership **note** as in step 1 below.
2. A local task with no `jira` key gets one first: **Ticket** in
   `../trackers.md`.
3. Launch through the `vector-nighthawk:cli` skill:
   `jx nighthawk fix <KEY> --repo <repo> -o json` (`--repos` per repo when the
   task spans several), with the task's scope and acceptance criteria in
   `--context`. No aven ref goes in `--context`, Jira or the PR.
4. Add a **note** `Nighthawk run <id> on <KEY>`, and report the outcome, cost
   and PR link the skill gives.

On Local worker:

1. Write the ownership **note**: `Orchestrated by <your name> in <your group>`.
2. Pick the subgroup: `<your group>/<name>`, where `<name>` is the epic's slug
   in epic scope and your own session name in repo scope (e.g. `dotfiles/tasks`).
   The first time, run `agent-manager create-group <path> --directory <repo>`.
3. Spawn the worker:

```sh
agent-manager spawn --name <ref>-<slug> --group <subgroup> --directory <repo> --worktree --model <alias> --effort <level> --prompt "<entry>"
```

   Leave out `--worktree` when the group's own stored worktree setting is
   `off`:

```sh
agent-manager export --groups - 2>/dev/null | jq -r '.groups[] | select(.name=="<subgroup>") .worktree'
```

   A subgroup with an empty value takes the
   nearest ancestor's non-empty value; empty all the way up means `--worktree`.
   Don't use `agent-manager groups --json`: it reports null for an `off` group.
   Without a worktree the worker runs in the repo's checkout and shares it with
   the group's other workers, so each stages explicit paths and may
   `reserve_files` what it edits.

Leave out `--effort` for a `model-haiku` task: it lists no effort levels.

The name is kebab-case, 2–4 words, and starts with the lowercase ref; a task
whose PR is open names it `<ref>-#<n>-<slug>`. `<entry>`
is `/tasks-takeover <ref>` for an `active` task, otherwise
`/tasks-pickup <ref>`.

### Relay a decision

Before you send a worker a decision, check the user hasn't settled it in the
worker's own session since: **Read** the task's latest note and
`agent-manager read` the worker's screen. When they conflict, ask the user
instead of sending. Date the message: `As of <HH:MM>, the user chose <X>.`

A go-ahead to commit, push, merge or delete is never relayed: workers act on it
only when it's typed in their own session. Name the session to attach to instead.

After sending, run `agent-manager message-status <message id>`. `held` means
the worker is at a dialog, so tell the user to answer it there.

### Close a task

In the worker's directory, `git status --porcelain` is empty, and its commits
are on `main` (`git merge-base --is-ancestor HEAD main`) or pushed
(`git branch -r --contains HEAD`). A worker in the main checkout shares it
with others: only paths the worker touched count for the first check, and the
second holds by construction. If either check
fails, report what is missing and stop. Work that goes through a PR is not
closable until the PR merges: leave the task and its worker running, idle: the
worker acts when pinged. If both pass,
ask before you:

1. **Edit** the task to `done`.
2. Kill, then archive, each of its sessions (`agent-manager kill <id>`, then
   `agent-manager archive <id>`): archive alone leaves it running (agent-manager
   issue #915; drop the kill once that ships).
3. Tell the user to delete the row that owns the worktree, which is its first
   worker, with `d` in agent-manager. This removes the worktree and its `am/`
   branch, and nothing else can. A worker spawned without `--worktree` has
   none: skip this step.
4. In epic scope, when the epic has no open tasks left and its subgroup no
   sessions, offer `agent-manager delete-group <path>`. Repo scope never offers
   it: the next spawn recreates the subgroup.

A Nighthawk task has no session, worktree or local commits: its close check is
its PR merged (`gh pr view <n> --repo <owner>/<repo> --json state`), and only
step 1, and step 4 in epic scope, apply.

When the `done` report says the task needs more PRs, skip step 1 and step 4:
the task stays open, and its next PR goes into **Start a task**'s options as
a new worker (`/tasks-takeover <ref>`, with a fresh worktree unless the group's is `off`).

### Start a successor

For a `handover` report: kill and archive the worker (as in **Close a task**
step 2, #915), then spawn the successor in its
directory (its worktree, if it has one) with a new name, following the same rule
(`<ref>-#<n>-<slug>` while the task's PR is open):

```sh
agent-manager spawn --name <ref>-<slug> --group <subgroup> --directory <worker directory> --model <alias> --effort <level> --prompt "/tasks-takeover <ref>"
```

The successor takes the task's labels.

### Dead or errored worker

Ask whether to revive it (`agent-manager revive <id>`, which resumes its
conversation), start a successor as above, or leave it.

For a failed or canceled Nighthawk run, ask whether to re-run it (**Start a
task**'s Nighthawk steps 3–4, or the `iterate` launch in step 6 when its PR is
open), start a local worker (**Start a task**'s Local worker steps), or leave
it.

### Take over a task owned elsewhere

Ask first, then write a new ownership note naming you.

### Triage the inbox

Run [`../tasks-triage/SKILL.md`](../tasks-triage/SKILL.md) here, in this
session.
