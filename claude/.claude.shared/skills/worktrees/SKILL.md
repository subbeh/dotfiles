---
name: worktrees
description: Git worktree workflow across agent-manager and worktrunk (wt). Use when creating, landing or removing a worktree, or when spawning an agent session (create_session, agent-manager spawn) that should work in its own checkout.
---

# Worktrees

Every worktree has one **owner**: the tool that created it. The owner is the
only thing that renames or removes it.

## Layout

All worktrees live beside the repo: `<parent>/<repo>-worktrees/<name>`.
agent-manager hardcodes this path, so worktrunk's `worktree-path`, the tmux
project picker, starship and syncthing are all set to match. Keep it that way;
a new location breaks the picker and gets synced across machines.

Claude Code's own subagent worktrees (`isolation: worktree`) land in
`<repo>/.worktrees/agent-*` instead. They are gitignored and syncthing-ignored.

## Pick the owner

Decide by where the work ends up:

- **Exploratory, throwaway, or research** → agent-manager owns it. Spawn with
  `worktree: true` (MCP `create_session`, `agent-manager spawn --worktree`, or
  the toggle on the `n` form). It gets branch `am/<name>`.
- **Becomes a PR** → worktrunk owns it, so the branch carries a real name:

  ```sh
  wt switch -c feat/x --no-cd    # -> <repo>-worktrees/feat-x
  ```

  Then spawn the agent with `worktree: false` and `directory` set to that
  worktree path. agent-manager treats it as a plain folder.

## Land and clean up through the owner

| Owner | Land | Remove |
|---|---|---|
| agent-manager | push, or `wt merge` from inside it | delete the session (`d`) |
| worktrunk | `wt merge`, or push and open a PR | `wt remove`, then delete any session pointing at it |

agent-manager's `d` removes the worktree and its `am/` branch only when nothing
would be lost (no uncommitted changes, no commits that exist nowhere else).

Rename and remove an agent-manager worktree through agent-manager: it stores
the path and branch, and its delete check reads them. When an exploratory
`am/` branch turns out to be PR-worthy, copy it rather than renaming it:

```sh
git -C <repo> branch feat/x am/<name>   # then: wt switch feat/x
```

then delete the agent-manager session.

For a stale `.worktrees/agent-*` checkout, confirm its branch is merged or
pushed before `git worktree remove`.

## Routine

- `wt list` shows every worktree, whichever tool owns it.
- `wt step prune` removes worktrees and branches already merged into the
  default branch.
- One agent per worktree. A fork (`f`) shares its parent's worktree on purpose.

`wt` flags and hooks: the `worktrunk` skill, or `wt <command> --help`.
