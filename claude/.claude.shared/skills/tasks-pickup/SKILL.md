---
name: tasks-pickup
description: Pick an open task from the repo's tracker, confirm it with the user, and start on it - in a worker session it spawns under agent-manager, otherwise here.
disable-model-invocation: true
---

# Pickup

Starts a task nobody has begun; `/tasks-takeover` resumes one already in progress.
Under agent-manager this session hands the task to a worker session of its own
and stays on as its orchestrator.
The commands behind each **operation** below are in
[`../trackers.md`](../trackers.md), by tracker.

## 1. Find the tracker

Follow **Finding the tracker** in `../trackers.md`. A ref passed as the
argument names its tracker by shape.

Done when you know the tracker and how to query it.

## 2. Pick the task

With a ref as the argument, use it. Otherwise run the tracker's **open** list
and print it as a table (ref, priority, status, title; on aven + Jira also the
`jira` key and the epic): `todo` before `backlog`, then highest priority, then
most recently updated.
Mark a task whose latest **claim line** names another session that is still
running (agent-manager `list_sessions`) as claimed, and leave it out of the
recommendation. Ask with `AskUserQuestion`: the top task first as
"(Recommended)", then the next three; "Other" takes any ref from the table.
With no candidates, say so and stop.

When the task's aven status is `inbox`, run [`/tasks-triage`](../tasks-triage/SKILL.md)
on that ref alone, here and before step 3. Continue only when triage applied it
as `todo` or `backlog`; when it was skipped or `canceled`, say so and stop
without starting the task.

Done when you hold exactly one ref the user named or confirmed, triaged.

## 3. Hand off to a worker

Skip this step, and work the task in this session, when any of these holds:

- The tracker is not aven or aven + Jira, or `agent-manager` is not on PATH.
- `agent-manager sessions --json` has no `self` row.
- The task's latest `Orchestrated by` note names another session: this session
  is its **worker**.

Otherwise this session orchestrates the task and never edits the repo itself.
Run [`/tasks-orchestrate`](../tasks-orchestrate/SKILL.md)'s step 1 in repo
scope, then steps 1–3 of its **Start a task** for this ref, then continue from
its step 2.

Done when a worker runs the task, or you know this session works it.

## 4. Read the task

**Read** the task, then the code it touches. For a mirrored task, settle
**Drift** first. Where it leaves scope or acceptance criteria unclear, collect
a question for the user. A task with an `Orchestrated by` note makes this
session its **worker** (see [`../orchestration.md`](../orchestration.md)).

Done when you can name the first concrete step, the files it touches, and every
open question.

## 5. Brief and start

**Start** the task, then add a **note** holding the **claim line**:
`Claimed by <session> in <directory>`, where `<session>` is this session's
agent-manager name (the `self` row of `list_sessions`) or `interactive`. When
the work gets its own branch, name it per the tracker's **Branch name**, or put
the ref in it when the tracker has none: that is how `/tasks-takeover` finds the
task later. As a worker, first read [`../orchestration.md`](../orchestration.md) in
full: it holds the report notes and the ping command. Then report `started`,
and from then on report each state it lists.

Print the brief:

```text
Pickup: <ref> - <title>
Goal: <what done looks like, one line>
Next: <first step>
Open: <questions for the user, or none>
```

When **Open** is not none, settle it with `AskUserQuestion` first. Then start
on **Next**.
