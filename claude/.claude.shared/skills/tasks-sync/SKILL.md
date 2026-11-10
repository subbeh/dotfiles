---
name: tasks-sync
description: Mirror the user's untracked GitHub issues and PRs, or Jira tickets where aven mirrors Jira, into aven's inbox, and settle drift and new comments on tasks already mirrored.
disable-model-invocation: true
---

# Sync

Brings work tracked outside aven into it, so `/tasks-triage` and `/tasks-pickup`
can see it. New tasks land in `inbox` for triage. The
commands behind each **operation** below are in
[`../trackers.md`](../trackers.md).

## 1. Find the tracker

Follow **Finding the tracker** in `../trackers.md`.

- **aven + Jira**: sync Jira (step 2).
- **aven**: sync GitHub (step 3) when `gh repo view` succeeds; otherwise say
  there is nothing to sync and stop.
- Any other tracker has no aven project to sync into: say so and stop.

Done when you know which step to run.

## 2. Jira

Run **Import**. Then settle **Drift** for each open mirrored task
(`aven list --open --has-metadata jira`), using the status and assignee the
inventory returned; ask `clops-atlassian-read` for the keys it left out.

Done when every assigned ticket is mirrored or reported, and every drift is
settled.

## 3. GitHub

Run **GitHub items**. For each, **Find GitHub mirrored**:

- Not mirrored: **Link** it to the task that tracks it, else **Mirror** it and
  **Relate** it. Then add its **Comments**, which notes the existing thread.
- Mirrored on an open task: add its new **Comments**.
- Mirrored on a `done` or `canceled` task: report it as drift.

Then run **GitHub drift**: it also catches tasks whose item closed and so left
the lists.

Done when every item is mirrored, linked or reported, and every drift is
settled.

## 4. Report

Print one row per item: the task (`<REF> (<title>)`), the item (`issue #<n>`,
`PR #<n>` or the Jira key), and what happened: `imported` (plus
`, related <REF>` when **Relate** ran, or the candidate task **Link** found),
`linked`, `noted` (new comments), `drift: <resolution>`, `skipped` (with why,
e.g. a Jira item whose PR merged), or `unchanged`. A second run with nothing new
shows only `unchanged` rows.
