# Worker model and effort

A task carries one `model-<alias>` label and one `effort-<level>` label, set
at triage. `agent-manager spawn` takes `--model` (`haiku`, `sonnet`, `opus`)
and `--effort` (`low`, `medium`, `high`, `xhigh`, `max`). `haiku` lists no
effort levels, so `spawn` rejects `--effort` with it: a `model-haiku` task has
no `effort-` label and is spawned without `--effort`. A restart, revive or
fork keeps the model.

**How to decide**: read the code the task touches before picking; the title
and the task type alone mislead. Size and risk decide: take the lowest row
whose criteria the task meets in full, and the higher one when it meets two
rows halfway. Model and effort are independent (a small, risky fix can be
`opus` at `medium`). The pick comes with a one-line reason. `max` stays unused.

| Model | Pick when | Example |
|---|---|---|
| `model-haiku` | the edit is fully specified and mechanical: rename a term, move text, fix a typo, add a line the task spells out. No judgement, no tests, nothing live | rename a label in every skill file |
| `model-sonnet` | one area, an existing pattern to follow, clear acceptance: docs, a keymap or config tweak, a small script fix, research or "find whether / decide" | DOT-Q8WR (yank to end of line with Y in copy mode), DOT-RP67 (name tasks by ref and title in task skills) |
| `model-opus` | code with tests or a contract between scripts; any live change or Deploy on a Host; secrets or security; open design questions; a mistake that is costly to spot | DOT-416N (build the orchestrator's table from one tasks-board script), DOT-99W5 (stop blink.cmp's Rust build from blocking nvim start) |

| Effort | Pick when | Example |
|---|---|---|
| `effort-low` | one spot to edit and the task text already says where and what | DOT-FKPZ (kill a worker before archiving it in tasks-orchestrate) |
| `effort-medium` | a small change over a few files, clear acceptance, one thing to work out | DOT-RP67, DOT-99W5 |
| `effort-high` | new code with tests, a live change, or a design with trade-offs | DOT-KRM3 (move worker reports behind a tasks-report script) |
| `effort-xhigh` | many interacting parts, a bug whose cause is unknown, or a design where a wrong pick means a rewrite | rework how every source in `mate.yaml` is laid out and profiled |

A task with no `model-` or `effort-` label gets the same pick from this
table. A successor takes the task's labels.
