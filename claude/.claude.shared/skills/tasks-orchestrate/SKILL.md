---
name: tasks-orchestrate
description: Run the repo's tasks (or one epic's) from this session - spawn a worker session per task, track their reports, and close tasks once landed.
disable-model-invocation: true
---

# Orchestrate

This session is the project manager: it starts each task in a **worker**
session of its own and never edits the repo itself. Workers report back through
the protocol in [`../orchestration.md`](../orchestration.md). The commands
behind each **operation** below are in [`../trackers.md`](../trackers.md).

## 1. Set up

Follow **Finding the tracker** in `../trackers.md`. Orchestration runs on aven
and aven + Jira; on any other tracker, say so and stop. Without `agent-manager`
on PATH, say so and stop.

Take this session's name, group and directory from the `self` row of
`agent-manager sessions --json`. The **scope** is the epic passed as the
argument (its children, `aven epic list <epic>`), or else the repo's project.
In epic scope, **Read** the epic: the decisions its description records are
settled, so never ask the user to make them again.

Done when you hold the tracker, your own name and group, and the scope.

## 2. Rebuild

Build the state from aven and agent-manager alone: this conversation's memory
of earlier rounds counts for nothing.

- Every open task in scope (**All open**), and the **Inbox** count.
- For each task, from **Read**: its owner (latest `Orchestrated by` note) and
  its **Latest report**.
- `agent-manager sessions --json`: a task's sessions are those whose name
  starts with its lowercase ref.
- `agent-manager reservations --json`: the `live/` leases (see **Live
  Services** in `../orchestration.md`) and their holders.

A task whose owner is another session that is still running is **owned
elsewhere**. A repo-wide orchestrator sees epic orchestrators' tasks this way.

Done when every task in scope has its owner, last report and sessions.

## 3. Report and ask

Print one table: ref, priority, title, aven status, worker session, its model
and effort, its state, last report, any `live/` lease it holds, and `owned by <name>` where
that applies. Mention it when more than 3 workers are `working` at once.

When the **Inbox** count is above 0, first ask with `AskUserQuestion` whether to
triage it now. On yes, triage the inbox (step 4), then go back to step 2.

Ask with `AskUserQuestion`. Options come from the table, recommended in this
order:

1. A dead or errored worker.
2. A `done` report: close the task.
3. A `handover` report: start the successor.
4. A `landing` report: name the session to attach to, where the go-ahead to
   land its finished work is asked.
5. A `waiting` report: name the session to attach to, where its question is.
6. Start the next task.

Check a session (`agent-manager read`) and take over a task owned elsewhere go
last. A `review` report is parked on teammates and gets no option: show its PR's
CI and review state in the table, and recommend the task again once that PR
merges (close it) or goes red or gets comments (ping its worker).

Act on the answer (step 4), then go back to step 2.

A user turn starting with `[tasks]` is a worker's ping. Check the task's
**Latest report** first: when it is not the report the ping carries, the ping
is stale, so acknowledge it in one line and stop there. Otherwise go back to
step 2 and recommend that task first.

## 4. Actions

### Start a task

Show tasks in scope that nobody owns and nobody has claimed (pickup's
**claim line** rule), in pickup's order: `todo` before `backlog`, then
highest priority, then most recently updated. Name each option's model and effort: the task's `model-` and `effort-`
labels, else the rule in **Worker model and effort** of
[`../orchestration.md`](../orchestration.md). Ask which one. Then:

1. Write the ownership **note**: `Orchestrated by <your name> in <group>`.
2. Pick the group. In repo scope it is your group. In epic scope it is
   `<your group>/<epic-slug>`: run `agent-manager create-group <path> --directory <repo>`
   the first time.
3. Spawn the worker:

```sh
agent-manager spawn --name <ref>-<slug> --group <group> --directory <repo> --worktree --model <alias> --effort <level> --prompt "<entry>"
```

   When the repo's `CLAUDE.md` says work lands on `main` with no PRs
   (dotfiles), leave out `--worktree`: the worker runs in the main checkout on
   `main` and commits straight to it. Workers share that checkout, so each
   stages explicit paths and may `reserve_files` what it edits.

The name is kebab-case, 2–4 words, and starts with the lowercase ref. `<entry>`
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
closable until the PR merges: leave the task and its worker running, since the
worker monitors the PR and fixes what CI, Sonar or review raise. If both pass,
ask before you:

1. **Edit** the task to `done`.
2. Archive each of its sessions (`agent-manager archive <id>`).
3. Tell the user to delete the row that owns the worktree, which is its first
   worker, with `d` in agent-manager. This removes the worktree and its `am/`
   branch, and nothing else can. A worker spawned without `--worktree` has
   none: skip this step.
4. When it was the epic's last open task, offer
   `agent-manager delete-group <path>`.

When the `done` report says the task needs more PRs, skip step 1 and step 4:
the task stays open, and its next PR goes into **Start a task**'s options as
a new worker (`/tasks-takeover <ref>`, fresh `--worktree`).

### Start a successor

For a `handover` report: archive the worker, then spawn the successor in its
directory (that is the worktree) with a new name, following the same rule:

```sh
agent-manager spawn --name <ref>-<slug> --group <group> --directory <worker directory> --model <alias> --effort <level> --prompt "/tasks-takeover <ref>"
```

The successor takes the task's labels.

### Dead or errored worker

Ask whether to revive it (`agent-manager revive <id>`, which resumes its
conversation), start a successor as above, or leave it.

### Take over a task owned elsewhere

Ask first, then write a new ownership note naming you.

### Triage the inbox

Run [`../tasks-triage/SKILL.md`](../tasks-triage/SKILL.md) here, in this
session.
