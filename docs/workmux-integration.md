# workmux integration spec

Adopt [workmux](https://workmux.raine.dev/) for git-worktree-based agent work while
keeping [tmux-tpad](https://github.com/Subbeh/tmux-tpad) popups as-is for standalone
claude. Derived from an interview on 2026-09-15.

Touches two repos: `dotfiles` (most changes) and `projects/tmux-tpad` (one option).

---

## 1. Goal

Two distinct workflows, cleanly separated, with no overlap in tooling:

| Situation | Tool |
|---|---|
| Non-git directory (`/etc`, `/var/log`, `~`) — system debugging | `C-c` tpad popup → `claude-runner` |
| Git repo, working directly on the checked-out branch (e.g. `dotfiles`) | `C-c` tpad popup → `claude-runner` |
| Git repo, isolated branch, possibly several in parallel | `wm add` → worktree window |

workmux's unit of work is a git worktree, so it has nothing to offer the first two
cases. `C-c` already handles them: `tpad.tmux:70-75` falls back to
`pane_current_path` when `git rev-parse` fails.

**`C-c` requires no changes.**

## 2. Verified current state

Established by inspection, not assumption:

- **workmux 0.1.262** installed (brew on `work`, `cargo` on `personal` via
  `workmux/.matescripts/50-workmux-install.sh#once#after#profile:linux`).
  `workmux` and `fzf` are already registered in `mate.yaml:27` sources.
- **Status-tracking hooks are not installed.** No `workmux` entries in
  `~/.claude/settings.json`, no `workmux-status` plugin, and `entries` in
  `~/.local/state/workmux/agent-recovery/tmux/*.json` is an empty array — nothing has
  ever registered. **The `C-w` dashboard is empty today.** This is the blocker.
- **Status-bar collision.** `tmux/.config/tmux/theme.conf#template:24-25` sets a custom
  `window-status-format` / `window-status-current-format` carrying `#{@jpro_status}`.
  workmux rewrites these per session unless `status_format: false`.
- **Two sessions only**, `work` and `home`, each with one named window per project
  (`tmux/.config/tmuxinator/home.yml`, `work.yml#profile:work`). This is the model to
  preserve.
- **Working layout**: 5 panes. Verified live as `home:2 dots`, layout
  `0644,267x72,...` — left column (25%) split 80/20, right region (75%) with the top row
  split into editor + claude and a bottom row spanning both. claude arrives there via
  `prefix + C-e` (tpad eject, `@tpad-claude-eject-split right`, `-size 40`).
- **Agent tracking is pane-keyed, status display is window-keyed.**
  `workmux register-agent` = "register the agent in the current multiplexer *pane*";
  `workmux set-window-status` = "set agent status for the current tmux *window*".
- **`cloud-ops-tools`** at `/Users/Shared/data/workspace/jamf/cloud-ops-tools`
  (`github.com/jamf/cloud-ops-tools`, team repo). Python + `mise.toml`, currently on
  `CA-3890-uv-migration`. `.venv` is gitignored, so fresh worktrees start with no
  environment. `.claude/settings.local.json` is gitignored, and already covered by
  `git/.config/git/gitignore:5` (`**/.claude/settings.local.json`).
- **`cloud-ops-tools_test`** is a second *full clone* of the same remote on the same
  branch — clean, 175M, inside the Syncthing root.
- **`/Users/Shared/data/workspace` is a single Syncthing root** (`.stfolder` +
  `.stignore` at its top level). Anything created under it replicates across machines.
- **Global git ignore** is `core.excludesFile = ~/.config/git/gitignore`, sourced from
  `git/.config/git/gitignore`, already used this way for `TODO.md`.
- **workmux pane schema**: `command`, `focus`, `zoom`, `split`, `size`, `percentage`,
  and `target` — a **0-based index** into the `panes:` array, letting a pane split from
  any earlier pane rather than the most recent (added in v0.1.11).

## 3. Design decisions

### Placement and naming

- **Window mode.** No session mode. Worktree windows are ordinary windows in whichever
  of `work` / `home` is current. Still only ever two sessions.
- `--parent-session` is passed **only as a guard** for background or agent-driven
  dispatch, so a window can never land inside a tpad popup session.
- `window_placement: rightmost` — worktree windows collect to the right of the named
  project windows.
- `window_prefix`: workmux's default nerdfont icon, consistent with the icon-heavy
  status bar and cheap in status-bar width.
- `worktree_naming: full` — Jamf branches carry the ticket (`CA-3890-uv-migration`) and
  it is worth keeping visible. Use `--name` for a short handle when a branch name is
  unwieldy.

### Worktree location

- `worktree_dir: .worktrees` — inside each repo.
- Ignored by git via the **global** `core.excludesFile`, not a per-repo `.gitignore`.
  One line, propagates to every machine through dotfiles, and never touches a team repo.
- Ignored by Syncthing via a `.worktrees/` rule in the workspace `.stignore`.

### Window layout

Reproduce today's ejected layout exactly — 5 panes:

```
┌──────┬────────┬───────┐
│  0   │   1    │   3   │  80%
│ 25%  │ editor │claude │
├──────┼────────┴───────┤
│  4   │       2        │  20%
└──────┴────────────────┘
```

- claude is a **plain workmux pane**, always visible. No popup toggle; `prefix + z`
  zooms it when focus is wanted.
- The editor slot stays an **empty shell**, exactly as in `clops-tools` today. Nothing
  is auto-launched into it.
- The bottom-right pane runs the project bootstrap.
- claude takes `focus: true` — the agent is the point of the window, and workmux injects
  prompts into the focused agent pane.

### Environment bootstrap

- **Pane command, not `post_create`** — the window opens instantly and claude can start
  reading code while dependencies install. workmux keeps an interactive shell in the
  pane after the command finishes.
- Bootstrap logic lives in a new **`wm-bootstrap`** script in dotfiles, which detects the
  project type (`mise.toml`, `uv.lock`, `go.mod`) and acts accordingly. This keeps
  bootstrap config out of team repos and works for every repo adopted later.

**Project configs are used, in both repos.** The earlier plan kept config global-only to
avoid putting personal tooling into a Jamf repo; that was revised — a `.workmux.yaml` that
encodes the repo's *own* branching rules is repo documentation, not personal preference,
and gets contributed upstream.

`projects/tmux-tpad/.workmux.yaml`:

```yaml
main_branch: develop
```

`jamf/cloud-ops-tools/.workmux.yaml` adds per-user file sharing:

```yaml
main_branch: develop
files:
  symlink:
    - .claude/settings.json
    - .claude/settings.local.json
```

`main_branch` rather than `base_branch` in both, because global `base_branch: auto`
resolves to the *configured* `main_branch` first. One setting therefore fixes the base for
new worktrees **and** points `workmux merge` and the dashboard's merged-detection at
`develop`, in repos where `main` is only reached via a promotion PR. Verified on the same
branch, before and after adding the file:

| project config | `wm add --dry-run` base |
|---|---|
| none, `origin/HEAD` → `main` (tmux-tpad) | `main` |
| `main_branch: develop` | `develop` |
| `--base main` override | `main` |

The symlinks matter because a worktree is a clean checkout: in cloud-ops-tools
`settings.shared.json` is tracked, but `settings.json` (locally installed hooks) and
`settings.local.json` (granted permissions, MCP servers) are gitignored per-user files.
Without them each worktree re-prompts for every permission and skips the work hooks. Both
are matched by that repo's `.claude/*` ignore rule, so the symlinks stay untracked —
verified with `git check-ignore`.

Two things deliberately **absent** from the cloud-ops-tools config, both recorded as
comments in the file so a future editor does not add them by mistake:

- **`panes`** — a project panes list *replaces* the global one outright rather than
  merging, so defining it would override every developer's own layout, including the
  5-pane one in §4.1.
- **Dependency setup** — a `post_create` hook blocks the window from opening. Bootstrap
  stays a pane command (`wm-bootstrap`) so the window opens immediately.

`worktree_dir` is also omitted: pinning `.worktrees` repo-side would need a matching
`.gitignore` entry for colleagues who lack this setup's global excludesfile. Left as a
possible follow-up.

### Git workflow

- **Commits and merges are manual.** workmux manages worktrees and windows only.
- `base_branch: auto` globally so new worktrees branch from the integration branch
  regardless of what is checked out; overridable per repo.

  Verified in cloud-ops-tools (on `CA-3890-uv-migration`) via `wm add --dry-run`:

  | config | resolved base |
  |---|---|
  | `base_branch: auto` | `develop` |
  | `base_branch` omitted | `CA-3890-uv-migration` |
  | `--base CA-3890-uv-migration` | `CA-3890-uv-migration` |

  `main_branch` needs **no override**: `origin/HEAD` points at `develop`, and workmux
  auto-detects it. No `.workmux.yaml` is required in the Jamf repo.

  **Stacking on a feature branch** is therefore explicit — `wm add sub-thing --base
  $(git branch --show-current)`. That matches the repo's own guidance that stacking is the
  exception ("Don't stack two PRs on the same ticket", "Prefer fewer coherent PRs over
  more parallel ones"), and stops unrelated work silently inheriting a feature branch.
  The merge back is a draft PR with `--base <feature-branch>`, per that repo's stacking
  rule — not `workmux merge`. workmux's involvement ends at worktree creation; cleanup is
  `wm rm --gone` once the PR lands.
- Cleanup via **both** `wm rm --gone` (after PRs merge remotely and GitHub deletes the
  branch) and the dashboard **sweep** (`R`) when reviewing before removal.
- `merge_keep: true` retained purely as a guard in case `wm merge` is ever run.

### Monitoring

- **`C-w` dashboard popup** — already bound at `plugins.conf:76-80`.
- **Sidebar scoped to one session**, `position: top`, `height: 1` — a single-row strip.
  Chosen over a left sidebar because the 5-pane layout has no column to spare, and
  session scoping keeps it out of tpad popup sessions.
- **Every claude registers**, including `C-c` popup claudes in non-git directories. The
  dashboard is a view of all running claude sessions, which makes a forgotten popup
  waiting on input discoverable. No `WORKMUX_DISABLE_SET_WINDOW_STATUS` anywhere.
- `status_format: false`; the `#{@workmux_status}` token is added to `theme.conf` by hand
  so `#{@jpro_status}` survives and styling stays owned by the theme.

### Skills

Keep `/workmux` (CLI reference) and `/worktree` (dispatch). **Drop `/merge`, `/rebase`
and `/open-pr`.** `/merge` and `/rebase` directly contradict this repo's `CLAUDE.md` —
the vendored `/merge` does `git add -A` and forbids conventional commit prefixes, while
`CLAUDE.md` requires Conventional Commits, explicit paths, and one commit per source
directory. Git is manual anyway.

### Rollout

- `cloud-ops-tools` first, then the `projects/` repos (`statemate`, `tmux-tpad`,
  `clopsbar`).
- `dotfiles`: **rule unchanged** — `CLAUDE.md` keeps "Work on main — do not create a
  branch". Worktrees here are a by-hand exception for large changes only.
- `cloud-ops-tools_test`: replace with a worktree, then delete the clone. Reclaims 175M
  and removes it from Syncthing.

## 4. Change list

### 4.1 `workmux/.config/workmux/config.yaml` — rewrite

```yaml
nerdfont: true
agent: claude

# Two sessions only (work / home): worktrees are windows in the current session.
mode: window
window_placement: rightmost
worktree_dir: .worktrees
worktree_naming: full
base_branch: auto

# theme.conf owns window-status-format (it carries @jpro_status).
status_format: false

# Git is manual; this only guards an accidental `wm merge`.
merge_keep: true

# 5-pane layout mirroring the tpad-eject layout.
panes:
  - name: shell            # 0  left column, top
  - name: editor           # 1  right region, becomes the editor slot
    split: horizontal
    percentage: 75
  - name: bootstrap        # 2  right column, bottom
    command: wm-bootstrap
    split: vertical
    target: 1
    percentage: 20
  - name: shell            # 3  left column, bottom
    split: vertical
    target: 0
    percentage: 20
  - name: agent            # 4  claude, splits the editor pane
    command: <agent>
    split: horizontal
    target: 1
    percentage: 50
    focus: true

sidebar:
  position: top
  height: 1

# Git is manual — keep the dashboard's c/m keys from doing anything destructive.
dashboard:
  commit: "Summarise what is staged and what committing would include. Do not commit."
  merge: "Summarise what merging this branch into main would involve. Do not merge."
```

**Verified empirically** with throwaway worktrees in `projects/tmux-tpad`:

- `split: horizontal` means side by side and `vertical` means stacked, i.e. the tmux
  convention. No transposition needed. `percentage` sizes the *new* pane.
- The resulting tree is structurally identical to the hand-built `dots` window:

  ```
  dots  (hand-built, claude ejected):  {66x72[66x57,66x14], 200x72[200x57{101x57, 98x57}, 200x14]}
  probe (workmux built):               {66x72[66x57,66x14], 200x72[200x57{ 99x57,100x57}, 200x14]}
  ```

- **`focus: true` is not applied at the end — pane creation order wins.** With the agent
  pane defined 4th and a 5th pane after it, focus landed on that 5th pane (verified twice,
  with and without `--no-pane-cmds`). Defining the agent pane **last** fixes it; the tree
  is unaffected because the left and right subtrees are independent. This is why the order
  above ends with the agent.
- A full run (without `--no-pane-cmds`) confirmed claude starts in the agent pane and
  `wm-bootstrap` runs in the bottom pane and leaves an interactive shell behind.

Also drop `merge_strategy: rebase` — inert with manual merging.

### 4.2 New: `workmux/.local/bin#perm-r:755/wm-bootstrap`

Idempotent, non-interactive, exits 0 when it recognises nothing. Detects in order:

- `mise.toml` → `mise install`
- `uv.lock` / `pyproject.toml` with uv → `uv sync`
- `package.json` → the lockfile's package manager
- `Cargo.toml` → `cargo fetch`

Follows the existing script conventions (`claude/.local/bin#perm-r:755/claude-runner`,
`tmux/.local/bin#perm-r:755/cda`): `#!/usr/bin/env bash`, `set -euo pipefail`, guarded
by `command -v`. Must pass `shellcheck`.

### 4.3 `git/.config/git/gitignore` — one line

Append `.worktrees/`. Sits alongside the existing `TODO.md` and
`**/.claude/settings.local.json` entries.

### 4.4 `/Users/Shared/data/workspace/.stignore` — two rules

**Outside this repo** — it lives in the Syncthing root and is not statemate-managed.
`.stignore` is itself synced, so it propagates.

```
.worktrees/
**/.git/worktrees/
```

Both rules are required, and the reason is **absolute paths, not size**. A worktree
costs little to sync (cloud-ops-tools is 293M total but only 21.3M of tracked source
across 657 files; `.venv/` and friends are already ignored at any depth). The real
problem is that a linked worktree is held together by two *absolute* pointers:

```
<worktree>/.git                        gitdir: /abs/main/.git/worktrees/<handle>
<main>/.git/worktrees/<handle>/gitdir  /abs/worktree/.git
<main>/.git/worktrees/<handle>/commondir   ../..   (relative, path-independent)
```

`core/.config/environment.d/10-xdg_base_dir.conf#template:13-17` branches on **OS**, so
the workspace root is `/data/workspace` on Arch and `/Users/Shared/data/workspace` on
macOS. A synced `gitdir` would need both values simultaneously.

`git worktree repair <path>` (from the main repo) or `git worktree repair` (from inside
the worktree) does fix a stale pointer — but it cannot help here: repairing on one
machine syncs that machine's absolute path to the other, which then repairs it back.
Meanwhile `git worktree prune` on whichever machine currently has the wrong path will
silently unregister a worktree that is live on the other.

Ignoring only `.worktrees/` is **not sufficient**: `.git/worktrees/<handle>/` lives
inside the main repo's synced `.git`, so the registration would still ping-pong. Hence
the second rule.

Cross-machine continuity is served by pushing the branch, which every worktree already
has.

### 4.5 `tmux/.config/tmux/theme.conf#template` — status token

Append `#{?@workmux_status, #{@workmux_status},}` after `#{@jpro_status}` in both
`window-status-format` (line 24) and `window-status-current-format` (line 25). The
current-format has two branches (zoomed / not) and **both** contain `#{@jpro_status}`.
The conditional form avoids a stray space when no agent is present.

Verify with `mate eval` and `mate eval -p personal`.

### 4.6 `tmux/.config/tmux/plugins.conf` — tpad per-dir mode

```tmux
set -g @tpad-git-per-dir        "repo"
set -g @tpad-claude-per-dir     "repo"
```

Depends on §5.

### 4.7 tmux drop-ins — a `config.d` loader

Rather than putting workmux bindings in the shared `keymaps.conf`, each source owns its
own tmux config. Two parts:

**`tmux/.config/tmux/tmux.conf`** gains a loader after the base config and before
`tpack init`, so drop-ins can override the base and still set `@plugin` / `@tpad-*`
options:

```tmux
source-file -q ~/.config/tmux/config.d/*.conf
```

tmux 3.7c; `source-file` takes glob(7) patterns natively and `-q` suppresses errors.
Verified on an isolated server (`tmux -L`): the glob expands tmux-side in alphabetical
order, and `-q` tolerates both a missing and an empty `config.d`. No shell loop needed.

**`workmux/.config/tmux/config.d/50-workmux.conf`** holds the bindings:

```tmux
bind -N "Toggle workmux sidebar" W run-shell "workmux sidebar --session"
bind -N "Jump to last done agent" g run-shell "workmux last-done"
bind -N "Toggle last agent" Tab run-shell "workmux last-agent"
```

All three keys were previously unbound. `C-w` stays tpad's dashboard popup, hence `W`.

The `50-` prefix follows the numeric-band contract `CLAUDE.md` documents for `profile.d`
and `zshrc.d` (`50` = per-app), matching the existing
`workmux/.config/profile.d/50-workmux.sh`. Ordering control comes free with the glob's
alphabetical expansion.

### 4.8 Claude status hooks — both encrypted settings files

Merge into `claude/.claude/settings.json#profile:work#encrypted` **and**
`claude/.claude/settings.json#profile:personal#encrypted`:

| Event | Matcher | Command |
|---|---|---|
| `SessionStart` | `startup\|resume\|clear\|fork` | `workmux register-agent` |
| `UserPromptSubmit` | — | `workmux set-window-status working` |
| `Notification` | `permission_prompt\|elicitation_dialog` | `workmux set-window-status waiting` |
| `PostToolUse` | — | `workmux set-window-status working` |
| `Stop` | — | `workmux set-window-status done` |

Constraints:

- **Merge, don't replace.** The `work` profile already has hooks
  (`claude/.claude/hooks/log-skill.sh#profile:work`, `log-spend.sh#profile:work`).
  Existing `PostToolUse` and other arrays must be preserved.
- Edit in place with `mate edit` and an **executable** `$VISUAL` script (per
  `CLAUDE.md`); never decrypt into the worktree.
- **Never print decrypted contents into the transcript.** Verify indirectly — have the
  editor script report only whether the five hook entries are present, rather than
  dumping the file. `mate cat` is not safe here.
- Check the staged diff still carries `#encrypted` before committing.

### 4.9 Skills — remove three  ✅ done

Removed `workmux/.claude/skills/merge/`, `rebase/`, `open-pr/` with `mate delete` (source,
target and tracking entry together). Kept `workmux/` and `worktree/`. Do **not** run
`workmux setup --skills`, which would reinstall all five.

Note `workmux/.claude/` is untracked in git, so this was not git-recoverable; the content
is restorable from
[upstream](https://github.com/raine/workmux/tree/main/skills) if ever needed.

**Why all three, specifically for cloud-ops-tools.** That repo's `CLAUDE.md` states:

> **Never rebase or force-push a branch another PR is based on.** Merge `develop` into it
> instead… [rebasing] corrupts the child's merge-base and turns an ordinary diff into a
> whole-file add/add conflict.

So `/rebase` is the *most* hazardous of the three there, not the least — it does the
forbidden thing silently in exactly the stacked situation the repo describes. `/merge` is
wrong on four counts: it merges locally rather than opening a draft PR into `develop`, its
`git add -A` would stage the plan/spec `.md` files the repo forbids committing, it
rebases, and it bypasses `/cloudops-commit`, which that `CLAUDE.md` mandates for all
commits and PRs.

Exposure was real: cloud-ops-tools has no `merge`/`rebase`/`open-pr` skills of its own, so
the global ones were **not** shadowed there. All five carry
`disable-model-invocation: true`, so no agent could reach for them — the risk was typing
`/merge` from habit.

### 4.10 Delete `.workmux.yaml` at the dotfiles root

Untracked, fully commented `workmux init` output. Config is global-only, so it is noise.

## 5. tmux-tpad change

**Do this work in a workmux worktree of `projects/tmux-tpad`** — it dogfoods the new
workflow and tests the fix in the environment it exists to fix.

### Problem

`toggle_popup` (`tpad.tmux:61-76`) keys per-directory sessions on
`sanitize_dir_name(git_root)`, i.e. the basename. Inside
`<repo>/.worktrees/fix-auth` the git root *is* the worktree, so the session becomes
`tpad_git_fix_auth` — the repo name is lost, and two repos each holding a `fix-auth`
worktree collide on one session name, attaching the popup to the wrong directory.

`get_git_root` (`tpad.tmux:240-248`) already behaves correctly here: it tests
`[[ -d "$pane_dir/.git" ]]` first, and in a worktree `.git` is a *file*, so it falls
through to `git rev-parse --show-toplevel`, which returns the worktree root. Only the
naming is wrong.

### Design

Extend the existing `per-dir` option to take a **mode** rather than adding a key, so the
two settings can never contradict each other:

| Value | Behaviour |
|---|---|
| `false` (default) | One shared session per instance. Unchanged. |
| `true` | Session per directory, keyed on basename. **Unchanged.** |
| `repo` | In a linked worktree, qualify with the owning repo. |

**Default stays off** — `true` keeps its current meaning, so existing tpad users see no
change on upgrade and no running popup sessions are orphaned. Opting in is an explicit
line in `plugins.conf`.

Detect a linked worktree with `git rev-parse --git-common-dir`: the main repo root is its
parent, and if that differs from `--show-toplevel`, this is a linked worktree.

```
tpad_git_cloud_ops_tools_fix_auth
tpad_claude_cloud_ops_tools_fix_auth
```

Main checkouts are unaffected — no `tpad_git_cloud_ops_tools_cloud_ops_tools`.

### Popup title

`build_popup_options` (`tpad.tmux:218-223`) appends `[basename]`. Under `repo` mode in a
worktree it shows both parts:

```
[cloud-ops-tools/fix-auth]
```

### Delivery

Implement, add the `per-dir` values to the README option table, and commit in
`tmux-tpad`. `shellcheck` must pass.

## 6. Verification

1. `mate eval tmux/.config/tmux/theme.conf#template` and `mate eval -p personal …` — the
   status token renders in both profiles.
2. `shellcheck` on `wm-bootstrap` and `tpad.tmux`.
3. `mate status` / `mate diff` shows only the intended paths; `#encrypted` suffixes
   intact on both settings files.
4. Hooks live: start a claude, confirm `entries` in
   `~/.local/state/workmux/agent-recovery/tmux/*.json` is no longer empty, and that an
   icon appears in the window name.
5. `wm add` on a throwaway branch in `projects/tmux-tpad`:
   - window appears rightmost in the current session with the icon prefix
   - **pane layout matches the 5-pane target** — if transposed, swap `horizontal` /
     `vertical` in `panes:` (§4.1)
   - claude is focused; `prefix + z` zooms it
   - `wm-bootstrap` ran in the bottom-right pane
   - `git status` in the main repo does not list `.worktrees/`
   - Syncthing does not pick up the worktree
6. `C-g` and `C-c` inside that worktree produce repo-qualified session names and a
   `repo/worktree` popup title.
7. `C-w` dashboard lists the agent; `prefix + W`, `prefix + g`, `prefix + Tab` work.
8. `wm rm <handle>` cleans up worktree, window and branch.
9. Only then: migrate `cloud-ops-tools`, and delete `cloud-ops-tools_test` once its
   replacement worktree is proven.

## 7. Sequencing

Reordered from the original plan: hooks were going to come first because the dashboard is
empty without them, but `wm add` works regardless — hooks only power the *observability*
layer. So the worktree and pane layout get validated first, since the layout is the part
the docs could not settle.

1. ✅ §4.1 config, §4.2 `wm-bootstrap`, §4.3/§4.4 ignore rules, §4.5 status token,
   §4.7 `config.d` loader + drop-in, §4.9 skill removal.
2. ⏳ `mate apply`, reload tmux, first `wm add` in `projects/tmux-tpad` — confirm the
   5-pane layout, swap `horizontal`/`vertical` if transposed.
3. §4.8 hooks, once the core workflow is known to suit.
4. §5 tpad change, in a worktree of `tmux-tpad`.
5. §4.6 switch `per-dir` to `repo` once §5 has landed.
6. §4.10 cleanup; migrate `cloud-ops-tools`; retire `cloud-ops-tools_test`.

Deferred deliberately, so nothing is hard to undo before the workflow has been lived
with: §4.10, the `cloud-ops-tools_test` retirement, and the tpad change.

Commits follow `CLAUDE.md`: Conventional Commits, one per source directory, explicit
paths, work on `main`, no branch. Expect roughly `feat(workmux)`, `feat(tmux)`,
`feat(git)`, `chore(claude)`, plus a separate commit in `tmux-tpad`.

## 8. Open items and caveats

- **Pane split orientation is unverified** (§4.1). The single most likely thing to need
  adjustment on first run.
- **`hook_shell`** is unset. Irrelevant while bootstrap runs as a pane command, but if
  `post_create` hooks are ever added, macOS ships bash 3.2 and the docs recommend
  `hook_shell: ["/opt/homebrew/bin/bash", "-c"]`. That path differs on Arch, so the
  config would need to become `#template`.
- **Pre-existing keybinding conflict**, unrelated to this work and left alone:
  `keymaps.conf:78` binds `prefix + C-v` to paste, and `plugins.conf:51` binds the same
  key to the tpad vifm popup. tpad wins, because `tpack init` runs at the end of
  `tmux.conf` after `keymaps.conf` is sourced.
- **Sharing claude permissions across worktrees** is available via
  `files: symlink: [.claude/settings.local.json]` if permission prompts in fresh
  worktrees become annoying. Not configured; the path is already globally gitignored.
- **`workmux setup` must not be run casually** — it would reinstall the dropped skills
  and offer to rewrite hook config.
- **`/coordinator` is not vendored.** If full lifecycle orchestration is ever wanted, it
  would be fetched separately.
- `TODO.md` items this touches: "tmux: project picker" is **not** addressed — worktree
  windows land in the current session, and no picker is being built.
