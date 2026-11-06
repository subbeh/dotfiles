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

A worker reports at each of these points, in this order: a **note** on the
task, then a **ping** to the owner. `started` is a note only: its ping would
arrive stale and cost the owner a turn. `waiting` is a note only too: the user
answers in the worker's own session, so a ping only asks them twice.

| State | When |
|---|---|
| `started` | right after the claim line |
| `waiting` | before asking the user anything mid-task |
| `blocked` | when the task can't move without someone else |
| `handover` | after the handoff note, in place of tasks-handover step 5 |
| `review` | once the PR is open with CI green, no Claude review comment unanswered, and only teammates' reviews left; send it again after each later fix |
| `done` | once the work has landed: per the repo's `CLAUDE.md` when it says how (e.g. on `main`), else merged for a PR (stay on the PR until then), else pushed. When the acceptance criteria need a live change (a Deploy, a config edit on a host), also once it is live and those criteria are checked. A run that needs the user's go-ahead is a `waiting` question, asked outright, not a step left in the report |

Once its PR is open, a worker runs `/monitor-pr <n> --loop=15m`
and fixes or answers every Claude review comment before it reports `review`.
It leaves a draft as a draft.

```text
Report: <state> - <one line>
```

The ping goes to the owner's id: the row of `agent-manager sessions --json`
whose name and group both match the ownership note. Every orchestrator is
named `tasks`, so a name alone finds the wrong one:

```sh
agent-manager send <owner id> "[tasks] <ref> <state>: <one line>"
```

When the owner isn't running, the note alone carries the report: the
orchestrator reads it when it next rebuilds.

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
at triage. `agent-manager spawn` takes `--model` (an alias: `sonnet`, `opus`)
and `--effort` (`low`, `medium`, `high`, `xhigh`, `max`, for every Claude
model). A restart, revive or fork keeps the model.

| Label | When |
|---|---|
| `model-sonnet` | docs-only, research or "find whether / decide" tasks; a single config tweak with clear acceptance |
| `model-opus` | code with tests; any live change or Deploy on a Host; secrets or security; open design questions |
| `effort-low` | mechanical edits |
| `effort-medium` | small changes with clear acceptance |
| `effort-high` | code, live changes, design |

A task with no `model-` or `effort-` label gets the rule's pick. A successor
takes the task's labels.
