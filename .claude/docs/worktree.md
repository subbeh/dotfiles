# Agent-manager worktrees

Applies to a session in its own worktree (`dotfiles-worktrees/<name>`, branch `am/<name>`).

- Bare `mate` reads the main checkout's source, not the worktree. Run read-only
  commands as `STATEMATE_DIR=$PWD mate status|diff|eval|check|cat` so they check
  this worktree's files.
- Deploying waits until the work has landed: `clean`, `delete`, `forget`,
  `scripts run` and `packages apply` run from the main checkout, and the user
  runs `apply` there.
  `mate rename` also renames the deployed target, so in a worktree change
  attributes with `git mv` and note in the report that the next apply removes
  the old target and deploys the new one.

**Land** a worktree once its commits are made and `git status` is clean:

1. `git rebase main` in the worktree. On a conflict, stop and ask.
1. `git -C <main checkout> merge --ff-only am/<name>`. When `main` moved again,
   rebase again. When the main checkout's uncommitted changes touch the same
   files, stop and ask; leave them as they are.
1. Report the landed commits and what the user still runs (`mate apply` is a reminder,
   not something to wait on): any `mate clean` for removed or renamed sources, and the push.
