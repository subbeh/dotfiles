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

Done when you hold the tracker, your own name and group, and the scope.

## 2. Rebuild

Build the state from aven and agent-manager alone: this conversation's memory
of earlier rounds counts for nothing.

- Every open task in scope (**All open**), and the **Inbox** count.
- For each task, from **Read**: its owner (latest `Orchestrated by` note) and
  its latest `Report:` note.
- `agent-manager sessions --json`: a task's sessions are those whose name
  starts with its lowercase ref.

A task whose owner is another session that is still running is **owned
elsewhere**. A repo-wide orchestrator sees epic orchestrators' tasks this way.

Done when every task in scope has its owner, last report and sessions.

## 3. Report and ask

Print one table: ref, priority, title, aven status, worker session and its
state, last report, and `owned by <name>` where that applies. Mention it when
more than 3 workers are `working` at once.

Ask with `AskUserQuestion`. Options come from the table, recommended in this
order:

1. A dead or errored worker.
2. A `done` report: close the task.
3. A `handover` report: start the successor.
4. A `waiting` report: name the session to attach to, where its question is.
5. Start the next task.

Check a session (`agent-manager read`), triage the inbox, and take over a task
owned elsewhere go last.

Act on the answer (step 4), then go back to step 2.

A user turn starting with `[tasks]` is a worker's ping. Go back to step 2 and
recommend that task first.

## 4. Actions

### Start a task

Show tasks in scope that nobody owns and nobody has claimed (pickup's
**claim line** rule), highest priority first, and ask which one. Then:

1. Write the ownership **note**: `Orchestrated by <your name> in <group>`.
2. Pick the group. In repo scope it is your group. In epic scope it is
   `<your group>/<epic-slug>`: run `agent-manager create-group <path> --directory <repo>`
   the first time.
3. Spawn the worker:

```sh
agent-manager spawn --name <ref>-<slug> --group <group> --directory <repo> --worktree --prompt "<entry>"
```

The name is kebab-case, 2–4 words, and starts with the lowercase ref. `<entry>`
is `/tasks-takeover <ref>` for an `active` task, otherwise
`/tasks-pickup <ref>`.

### Close a task

In the worker's directory, `git status --porcelain` is empty, and its commits
are on `main` (`git merge-base --is-ancestor HEAD main`) or pushed
(`git branch -r --contains HEAD`). If either check
fails, report what is missing and stop. Work that goes through a PR is not
closable until the PR merges: leave the task and its worker running, since the
worker monitors the PR and fixes what CI, Sonar or review raise. If both pass,
ask before you:

1. **Edit** the task to `done`.
2. Archive each of its sessions (`agent-manager archive <id>`).
3. Tell the user to delete the row that owns the worktree, which is its first
   worker, with `d` in agent-manager. This removes the worktree and its `am/`
   branch, and nothing else can.
4. When it was the epic's last open task, offer
   `agent-manager delete-group <path>`.

### Start a successor

For a `handover` report: archive the worker, then spawn the successor in its
directory (that is the worktree) with a new name, following the same rule:

```sh
agent-manager spawn --name <ref>-<slug> --group <group> --directory <worker directory> --prompt "/tasks-takeover <ref>"
```

### Dead or errored worker

Ask whether to revive it (`agent-manager revive <id>`, which resumes its
conversation), start a successor as above, or leave it.

### Take over a task owned elsewhere

Ask first, then write a new ownership note naming you.

### Triage the inbox

Run [`../tasks-triage/SKILL.md`](../tasks-triage/SKILL.md) here, in this
session.
