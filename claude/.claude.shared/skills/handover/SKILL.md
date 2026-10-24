---
name: handover
description: Hand the current work to a fresh session - update its task and docs, then print how to resume.
disable-model-invocation: true
---

# Handover

Write a **handoff** a cold session can resume from. None of this conversation
survives: whatever the next session needs must end up in the task, the repo, or
the resume prompt you print. The commands behind each **operation** below are
in [`../trackers.md`](../trackers.md), by tracker.

## 1. Find the task

Take the ref this session worked on (the `/aven <ref>`, `/pickup <ref>` or
`/takeover <ref>` it started from, a Jira key, or whichever tracker the work
came from). If no task tracks it, ask with `AskUserQuestion` whether to create
one, recommended first, and **create** it in the repo's tracker (**Finding the
tracker** in `../trackers.md`).

Done when you hold exactly one ref.

## 2. Bring supporting documents up to date

Every document this session created or worked from (a spec in `.specs/`, a
plan, `TODO.md`, a README it changed): record decisions, tick finished items,
mark what is still open. Leave changes uncommitted unless the user asked for a
commit.

Done when no document describes a state older than the code.

## 3. Write the handoff note

Append it to the task as a **note**:

- **Done**: what is finished, with short SHAs of commits made.
- **State**: branch, worktree path, uncommitted files, anything left running.
- **Next**: the next concrete step first, then the rest of the remaining work.
- **Decisions**: choices made and why, approaches ruled out.
- **Open**: questions and blockers for the user.
- **Docs**: repo-relative paths from step 2.

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
  /takeover <ref>
```
