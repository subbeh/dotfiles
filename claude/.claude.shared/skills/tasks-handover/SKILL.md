---
name: tasks-handover
description: Hand the current work to a fresh session - update its task and docs, then print how to resume.
disable-model-invocation: true
---

# Handover

Write a **handoff** a cold session can resume from. None of this conversation
survives: whatever the next session needs must end up in the task, the repo, or
the resume prompt you print. The commands behind each **operation** below are
in [`../trackers.md`](../trackers.md), by tracker.

## 1. Find the task

Take the ref this session worked on (the `/aven <ref>`, `/tasks-pickup <ref>` or
`/tasks-takeover <ref>` it started from, a Jira key, or whichever tracker the work
came from). If no task tracks it, ask with `AskUserQuestion` whether to create
one, recommended first, and **create** it in the repo's tracker (**Finding the
tracker** in `../trackers.md`). On aven + Jira, a Jira key resolves through
**Find mirrored**, a new task gets `jira=<KEY>` when the branch carries one, and
a local task with a pushed branch gets **Backfill**.

Done when you hold exactly one ref.

## 2. Bring supporting documents up to date

Every document this session created or worked from (a spec in `.specs/`, a
plan, `TODO.md`, a README it changed, private docs such as
`~/.claude.work/docs/<repo>/`): record decisions, tick finished items, mark what
is still open. A document marked frozen keeps its text; what changed since goes
into the handoff note. Leave changes uncommitted unless the user asked for a
commit.

Done when no document describes a state older than the code.

## 3. Write the handoff note

Append it to the task as a **note**:

- **Done**: what is finished, with short SHAs of commits made.
- **State**: branch, worktree path, uncommitted files, anything left running.
- **Next**: the next concrete step first, then the rest of the remaining work.
- **Decisions**: choices made and why, approaches ruled out.
- **Open**: questions and blockers for the user.
- **Docs**: paths from step 2, repo-relative inside the repo and absolute
  (`~/...`) outside it.

Keep the task open; `done` stays with the task workflow. If the remaining work
splits into separate tasks, propose them with `AskUserQuestion` before filing.

Done when the next session can start the **Next** step from the note and the
repo alone, without re-deriving anything from this conversation.

## 4. Print the resume prompt

End with this block, so the user can copy it:

```text
Handover: <ref> - <title>
Next: <next step>
Uncommitted: <files, or none>

Resume in a new session from <directory>:
  /tasks-takeover <ref>
```

## 5. Offer to resume in a new agent-manager session

Only when the agent-manager tools are available; otherwise stop at step 4.
Ask with `AskUserQuestion` whether to start the next session now, "Resume
later" first as "(Recommended)". On yes, call agent-manager `create_session`
with a kebab-case name of 2–4 words starting with the ref (e.g. `cot-fmb8-clops-takeover`),
directory `<directory>`, this session's group, `worktree: false` (takeover picks
its own worktree from the note), and prompt `/tasks-takeover <ref>`.

It resumes from the note, not this conversation, so step 3 must be complete.
`tasks-takeover` asks about **Open** items and drift; the new session waits for
those answers in agent-manager, where the user attaches to it.
