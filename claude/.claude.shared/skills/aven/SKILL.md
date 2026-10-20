---
name: aven
description: Use aven to find tasks, update status, and leave durable handoff context. Use when the user talks about tasks (not todos), or asks to pick up, work on, or create a task.
---

## Picking up the next task

When the user asks to pick up or work on a task **without naming a ref** (e.g.
"work on the next task", "pick something up"):

1. Run `aven list --ready` and pick the best candidate (highest priority first,
   then the order Aven lists them). Run `aven context <ref>` on it.
2. Before changing anything, confirm with `AskUserQuestion`: show the ref, title
   and a one-line summary, with options:
   - **Work on it (Recommended)** — proceed.
   - **Skip** — move to the next candidate and ask again. Only offer this when
     another ready task exists.
3. Repeat step 2 for each skip. If the list runs out, say so and stop.
4. Only after confirmation, mark it active (`aven edit <ref> --status active`)
   and start.

A skipped task stays untouched — don't change its status, priority or notes.
When the user names a ref, skip the confirmation and follow the workflow below.

## Missing task details

Don't invent details a task lacks — ask with `AskUserQuestion` (or a plain
question when the tool isn't available):

- **Creating** — if the rationale, scope or acceptance criteria are unclear,
  ask before running `aven add` rather than filing a thin task.
- **Picking up** — if `aven context <ref>` leaves the task ambiguous, ask after
  confirming it and before starting work. Offer concrete options, with the
  recommended one first, labelled "(Recommended)".

---

!`aven skill 2>&1 || echo "aven skill failed: run it yourself and follow its output."`
