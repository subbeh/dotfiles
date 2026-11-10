# Nighthawk

Jamf's hosted agent. It reads a Jira ticket, works the code in a Jamf org repo
and opens a draft PR, on Jamf quota instead of this session's tokens. This file
deploys to `~/.claude.work` only: a shared `tasks-*` skill offers Nighthawk
only when `../nighthawk.md` exists, and the offers and run steps live in those
skills, not here.

## When to offer it

Offer it first, ahead of a local worker, only when all hold:

- The repo is aven + Jira (see `trackers.md`) and the repo is in the Jamf org.
  Nighthawk needs a Jira key; a task without one gets one first, per the
  tracker. Other trackers never see the option.
- The work is bounded: implement a ticket (`fix`), address PR feedback
  (`iterate`), add tests (`test`), plan (`plan`), review a PR (`run`).
  Interactive or exploratory work stays with a local worker.
- Availability is `available` or `unverified` (below).

Cost and limits: about $1-5 and 5-15 min per run, on Jamf quota. 60 min hard
cap per run. Multi-repo takes `--repos` (the limit is 25 per `jx nighthawk fix
--help`; the research said 15, so check the help). The worker has no Docker, no
custom credentials, no prompts, cannot edit `.github/workflows/**`, and needs
the VPN (`*.jamf.build`). The task's `model-` and `effort-` labels don't apply.

## Availability

Each check ends in exactly one result: `available`, `unavailable` or
`unverified`. Follow step 3 of cloud-ops-tools'
`.claude/skills/clops-plan-dispatch/SKILL.md` (the skill list for
`vector-nighthawk:cli`, then one Bash call for `jx nighthawk --help` and
`claude plugin list`) rather than a copy here. Skip `jx nighthawk whoami`: it
is the launch's own preflight and makes a network call.

When `unavailable`, lead with what is missing and give this setup note: install
the `vector-nighthawk` plugin (`/plugin`, then restart the session), install the
CLI with `brew install jamf/internal/jx`, and sign in once with
`jx nighthawk login`.

## Launching

Launch through the `vector-nighthawk:cli` skill, which holds the command
syntax. Pass `-o json` and keep the run id from its output. Never put an aven
ref in `--context`, Jira or the PR: they are private to this setup.

## Hand-off protocol

A Nighthawk run is not a worker session:

- No agent-manager session, and no `tasks-report.sh` pings: nothing reports
  `started`, `working` or `waiting`.
- The orchestrator tracks a run by Jira key and run id, kept in a task note
  beside the `Orchestrated by` note. Poll with `jx nighthawk runs get <id>` or
  block with `jx nighthawk runs wait <id>` (exit 0 completed, 1 settled
  otherwise, 10 when `--max` ran out); `jx nighthawk runs cancel <id>` stops it.
- Results land in Jira and as a draft PR. Review is the PR being open; done is
  the PR merged, as for a local worker.
- A fix after that is a new `iterate` run on the same PR, not a takeover.
