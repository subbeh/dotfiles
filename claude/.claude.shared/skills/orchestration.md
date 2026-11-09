# Orchestration

How a `/tasks-orchestrate` session and the **worker** sessions it spawns talk
through aven and agent-manager. The aven commands behind each **operation** are
in [`trackers.md`](trackers.md).

## Ownership

The orchestrator writes a **note** on a task before it spawns that task's worker:

```text
Orchestrated by <orchestrator name> in <group>
```

The latest such note names the task's **owner**. A session that runs
`/tasks-pickup` or `/tasks-takeover` on a task carrying one is that task's
worker until the task closes, through handovers and restarts.

A worker delivers one PR, or one landed change where the repo has no PRs. It
never starts, suggests or offers work past that: not the next PR of a
multi-PR task, not a follow-up task, not another ref, and no reply ends on a
"next I could..." offer. Follow-ups it spots go in a note on the task. When
its PR merges and the task needs more, its `done` report says what remains,
and the owner starts the next PR in a new worker.

## Reports

A worker reports at each of these points with one command, run from the
repo:

```sh
bash <skill-dir>/../tasks-report.sh <ref> <state> "<one line>"
```

It writes the report note and pings the owner when the state calls for it.
It prints one line saying what it did; exit 1 means the note failed, so retry
or tell the user. Exit 2 means the task has no owner, so the session is not a
worker and reports nothing.

| State | When |
|---|---|
| `started` | right after the claim line |
| `waiting` | before asking the user anything mid-task |
| `landing` | once the work is finished and only the user's go-ahead to land it (commit, push, merge, a live run) is left; the one line says which. In a repo without PRs this is where every worker ends |
| `blocked` | when the task can't move without someone else |
| `handover` | after the handoff note, in place of tasks-handover step 5 |
| `review` | once the PR is open with CI green, no Claude review comment unanswered, and only teammates' reviews left; send it again after each later fix. PR-only |
| `done` | once the work has landed: per the repo's `CLAUDE.md` when it says how (e.g. on `main`), else merged for a PR (the user says when it has merged; the worker is idle until then), else pushed. When the acceptance criteria need a live change (a Deploy, a config edit on a host), also once it is live and those criteria are checked. A run that needs the user's go-ahead is a `landing` report, asked outright, not a step left in the report |

Once its PR is open, a worker runs `/monitor-pr <n> --loop=15m`
and fixes or answers every Claude review comment before it reports `review`.
It ends the loop with that report and goes idle: it acts again only when pinged
(the user reports the merge, or asks for a fix). It leaves a draft as a draft.

The task's status after `active` belongs to its owner: a worker reports `done`
and stops, and the orchestrator sets `done` after its close check.

## Live Services

Before a live config edit, restart or Deploy, a worker takes a **lease** on
each Service it touches, so two workers never change a running Service at once.
A lease is an exclusive agent-manager reservation on `live/<host>/<service>`
(e.g. `live/vps/hermes`), a name rather than a file:

```sh
agent-manager reserve live/<host>/<service> --note "<ref>: <what and why>" --ttl 1h --json
```

- **When**: reserve before asking the user for the run, with a TTL that covers
  the change and its verification (default 30m, max 4h).
- **Conflict**: `reserve` always succeeds and exits 0; another holder shows up
  only in the `conflicts` list, with its name and note. Then release yours
  (`agent-manager release-files live/<host>/<service>`) and report `blocked`
  naming the holder. Don't ask the user for the run.
- **Release**: hold the lease through verification, then release it by path.
  `release-files` with no path drops every lease the session holds.

The orchestrator shows each held lease and its holder in its table.

## Worker model and effort

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
