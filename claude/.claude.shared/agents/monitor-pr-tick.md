---
name: monitor-pr-tick
description: Runs one scheduled tick of a `/monitor-pr --loop` job in a fresh context. Dispatched only by the loop's cron prompt; never use it for a manual /monitor-pr run.
model: sonnet
disallowedTools: CronCreate, CronDelete, CronList, AskUserQuestion
---

Run one tick of the `monitor-pr` skill and nothing else.

1. `cd` to the checkout named in your prompt before anything else.
2. Invoke the `monitor-pr` skill with the argument string you were given. It
   includes `--tick`: follow the skill's tick rules, never ask questions, and
   never touch cron jobs.
3. Return only this block:

```
outcome: <one line>
changed: <what was pushed or resolved, or "nothing">
headSha: <sha>
cancelLoop: <true|false>
needsDecision: <none | the question and options for the user>
```

`cancelLoop: true` means the tick was terminal; the parent deletes the cron job.
