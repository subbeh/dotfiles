---
name: tasks-takeover
description: Take over a task an earlier session left off - pick it from the repo's tracker, rebuild its context, and continue.
disable-model-invocation: true
---

# Takeover

The other half of `/tasks-handover`. This session starts cold: everything you know
about the task comes from the tracker, the repo, and the user. The commands
behind each **operation** below are in [`../trackers.md`](../trackers.md), by
tracker.

## 1. Find the tracker

Follow **Finding the tracker** in `../trackers.md`. A ref passed as the
argument names its tracker by shape.

Done when you know the tracker and how to query it.

## 2. Pick the task

With a ref as the argument, use it. Otherwise run the tracker's **in progress**
list, most recently updated first.

A ref in the current branch name (`git branch --show-current`) marks the last
active task; on aven + Jira that ref may be a Jira key, which **Find mirrored**
turns into its task. Otherwise it is the most recently updated one. Ask with
`AskUserQuestion`: the last active task first as "(Recommended)", then up to
three others. With no candidates, ask for a ref.

Done when you hold exactly one ref the user named or confirmed.

## 3. Rebuild the context

**Read** the task. The latest handoff note (Done, State, Next, Decisions, Open,
Docs) is the baseline. Read every document under **Docs** and the code the
**Next** step touches. A task without one: build the same picture from its
description, its notes, `git log` and `git status`.

Then check the repo against **State** and collect each mismatch as **drift**:

- working directory and branch match the note's worktree and branch;
- the commits under **Done** exist, and any commits since are accounted for;
- `git status` shows the uncommitted files the note lists, and no others;
- on aven + Jira: a local task with a pushed branch gets **Backfill**, and a
  mirrored task's **Drift** against Jira joins this list.

Before calling anything stale, stuck or hung, run `date -u` and measure the
age against it. CI, Jira and aven timestamps are UTC, and the session's
"today" is the user's local date, which can be a day ahead of UTC.

A task with an `Orchestrated by` note makes this session its **worker** (see
[`../orchestration.md`](../orchestration.md)).

Done when you can name the next concrete step, the files it touches, and every
piece of drift.

## 4. Brief and continue

If the task is not in progress yet, **start** it. Either way, add a **note**
with this session's **claim line** (as `/tasks-pickup` writes it). As a
worker, report `started`, and from then on report each state
`../orchestration.md` lists.

Print the brief:

```text
Takeover: <ref> - <title>
Done: <what is finished, one line>
Next: <next step>
Open: <questions for the user, or none>
Drift: <mismatches, or none>
```

When **Open** or **Drift** is not none, settle it with `AskUserQuestion` first.
Then start on **Next**.
