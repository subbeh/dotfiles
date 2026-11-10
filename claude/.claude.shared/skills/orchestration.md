# Orchestration

How a `/tasks-pickup` orchestrator session and the **worker** sessions it spawns talk
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
| `review` | once the PR is open; send it again after each later fix. PR-only |
| `done` | once the work has landed: per the repo's `CLAUDE.md` when it says how (e.g. on `main`), else merged for a PR (the user says when it has merged; the worker is idle until then), else pushed. When the acceptance criteria need a live change (a Deploy, a config edit on a host), also once it is live and those criteria are checked. A run that needs the user's go-ahead is a `landing` report, asked outright, not a step left in the report. Never while a path the worker touched is uncommitted: report `landing` instead. Send it again after any later commit lands |

Once its PR is open, a worker reports `review` and goes idle; it never starts
`/monitor-pr` on its own. It acts again only when pinged (the user asks it to
monitor the PR or fix something, or reports the merge). It leaves a draft as a
draft.

Once its PR is open, and only when its session name starts with the lowercase
ref (a user-named session keeps its name), a worker renames itself with
agent-manager's `rename` to `<ref>-#<n>-<slug>` (`dot-kq4b-session-pr` becomes
`dot-kq4b-#123-session-pr`), then adds a fresh claim line
(`Claimed by <new name> in <dir>`): the board matches the claim by running
session name, so the old line goes stale. The name keeps starting with
`<ref>-`, which is how the board finds the task's worker.

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

A task's `model-` and `effort-` labels, set at triage, pick its worker's model
and effort: see [`worker-sizing.md`](worker-sizing.md).
