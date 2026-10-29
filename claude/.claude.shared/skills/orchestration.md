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

## Reports

A worker reports at each of these points, in this order: a **note** on the
task, then a **ping** to the owner.

| State | When |
|---|---|
| `started` | right after the claim line |
| `waiting` | before asking the user anything mid-task |
| `blocked` | when the task can't move without someone else |
| `handover` | after the handoff note, in place of tasks-handover step 5 |
| `done` | once the work has landed: merged for a PR (stay on the PR until then), else pushed |

```text
Report: <state> - <one line>
```

The ping goes to the owner's id, looked up by name in
`agent-manager sessions --json`:

```sh
agent-manager send <owner id> "[tasks] <ref> <state>: <one line>"
```

When the owner isn't running, the note alone carries the report: the
orchestrator reads it when it next rebuilds.
