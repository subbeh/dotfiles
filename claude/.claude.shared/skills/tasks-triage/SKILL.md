---
name: tasks-triage
description: Triage the aven inbox - import assigned Jira tickets where aven mirrors Jira, then rename, describe, prioritise and link each task and move it to todo or backlog.
disable-model-invocation: true
---

# Triage

Turns every **inbox** task into one `/tasks-pickup` can start cold. Runs on aven
and aven + Jira: the other trackers have no inbox. Follow **Finding the
tracker** in [`../trackers.md`](../trackers.md); the commands behind each
**operation** below are in its aven section, and in its aven + Jira section
when that tracker applies.

## 1. Load the inbox

On aven + Jira, run **Import** first and report how many tasks it added, as
`active` and as `inbox`. Then run **Inbox**. With no tasks, say so and stop. Run
**All open** too: those are the tasks and epics an inbox task may duplicate or
link to.

Done when you hold every inbox ref and the open-task list.

## 2. Triage each task

One task at a time, in the order **Inbox** lists them. **Read** it, then the
code it touches, until you can judge its scope. For a mirrored task, settle
**Drift** before drafting.

Run a **redundancy** check: search the repo for an existing implementation of
the behaviour the task asks for, by what it does rather than the task's wording
(keymaps, aliases, scripts, plugin defaults), and note where you looked. A hit
makes the draft `canceled`, with the description pointing at where it lives.
On a mirrored task, also tell the user its Jira ticket stays open: closing it is
theirs.

Draft:

- **Title**: `type(scope): subject`, like the tracker's other titles; the scope
  is the area of the repo it touches. A mirrored task keeps its Jira summary.
- **Description**: stands alone for a cold session: why, what is in scope, and
  acceptance criteria. Build it only from the task, its notes, the code, and
  the user's answers; every gap becomes a question. For a mirrored task, write
  the user's answers in your own words: ticket text stays in Jira. A research
  task's acceptance criterion is its findings, written into its own description.
- **Project** (aven + Jira): the one **Import** chose; the user can move it to
  another repo's project.
- **Priority**: `urgent` to `none`, from its impact and what it blocks.
- **Status**: `todo` for soon, `backlog` for someday, `canceled` when the
  redundancy check found it already done.
- **Links**: a duplicate (propose cancelling one), a related task, a blocker,
  or an epic it belongs to.

Ask with `AskUserQuestion`: **Apply** (Recommended), **Edit**, **Skip**, with
the gap questions in the same call. The user sees only the question, so the
**Apply** option's `preview` carries the whole draft: each field's current and
proposed value, the full proposed description, and the redundancy result with
where you looked. **Edit** takes the user's changes and asks again. **Skip**
leaves the task untouched in the inbox.

Done when every inbox task is applied or skipped.

## 3. Apply

For each applied task, first add a **note** holding its original title and
description, then **Edit** it (with `--project` when the project changed) and
**Link** it.

Done when `aven context <ref>` shows the new values on every applied task.

## 4. Report

Print one row per inbox task: ref, new title, priority, status, links, or
`skipped`.
