# CLAUDE.md

Dotfiles managed by [statemate](https://github.com/subbeh/statemate) (`mate`).
Reference docs: `$XDG_PROJECTS_DIR/statemate/docs/` — read
those (or `internal/` when the docs are thin) instead of guessing at behavior.
Run the `mate` on `PATH`; it is what a real apply uses. The checkout's `./mate`
is a dev build and may be ahead — say so if a feature you need only exists there.

## Layout

| Path | What |
|------|------|
| `mate.yaml` | sources, profiles, age recipients, variables |
| `.mate/theme.yaml` | colour variables, `include`d by `mate.yaml` |
| `<source>/` | stow-style; contents deploy relative to `~` |
| `<source>/.mate.yaml` | per-source packages, `targets`, `generate` |
| `<source>/.matescripts/` | lifecycle scripts |
| `install.sh` | bootstrap for a new machine — keep `README.md` in sync with it |
| `TODO.md` | gitignored scratch backlog. Read it, tick off what you fix, add new items |

Profiles: `linux`, `macos`, `personal` (Arch), `work` (macOS). `personal` and
`work` add their own `sources:` on top of the base list.

**Edit the source in this repo, never the deployed file in `~`.** Reading `~` (or
`mate managed`) to diagnose current state is fine; writing there is not — the next
apply overwrites it.

## Commands

- Run freely: `status`, `diff`, `check`, `eval`, `cat`, `managed`, `profile`,
  `config`, `doctor`, `packages list`, `scripts list`, `secrets status|list`.
- Ask first — these mutate the live machine: `apply`, `clean`, `delete`, `forget`,
  `packages apply`, `scripts run`, `secrets fetch`.
- `edit`, `encrypt`, `decrypt`, `rename` touch only the repo; use them freely to
  carry out a requested change.
- `mate doctor` is the first diagnostic when something behaves oddly.

## Attributes

`#`-suffixes on a filename, stripped from the target. Any number, any order.

| Attribute | Effect |
|-----------|--------|
| `#tmpl` | render as a Go template (sprig available) |
| `#enc` | age-encrypted in the repo, decrypted on apply |
| `#import` | target is authoritative; changes flow back into the source |
| `#profile:<name>` | only deploys under that profile |
| `#perm:600` `#owner:u` `#group:g` | mode/owner/group; `-r` variants recurse |
| `#link` | recreate a symlink (source must be one) |

Changing attributes means renaming the file. Use `mate encrypt` / `mate decrypt` /
`mate rename` — they keep the state DB and target consistent, so the next apply
doesn't see a spurious add + delete. Then let git record the rename.

## Templates

Variables: `.Profile` `.Hostname` `.OS` `.Arch` `.HomeDir` `.Username`
`.SourceDir` `.Vars` `.Env`. Own functions: `bitwarden <item> <type> <field>`.
`.mate.yaml` files and `#tmpl` scripts are rendered too.

`.mate/theme.yaml` feeds `.Vars.color.*` into ~15 templates (kitty, tmux, nvim
`colors.lua`, waybar, rofi, hyprlock, swaync, vivid, k9s). Adding a colour is
safe; renaming or removing one breaks all of them — grep first.

Verify every template you touch: `mate eval <path>`, plus
`mate eval -p personal <path>` for profile-scoped ones.

## Shell load order

`profile.d/` and `zshrc.d/` files are sourced in numeric order, so the prefix is
the contract: `00` base, `01`–`05` early env, `10` functions, `11` aliases,
`20` language/tool env, `30` tool config, `50` per-app, `90` last. Pick a number
in the right band rather than appending. Per-OS variants use `#profile:` on
otherwise identically-numbered files (`11-aliases-linux.sh#profile:linux`).

## Lifecycle scripts

`<order>-<name>.sh#<frequency>#<timing>[#tmpl][#profile:<name>]` — frequency
is `once`, `onchange`, `always`, `daily`, `weekly`, `monthly`, or omitted (manual
only); timing is `before` (default) or `after`. Order bands mirror `profile.d`:
`00` daemons/system, `50` installs, `60`–`70` plugin updates, `90` anything
interactive. Scripts must be idempotent — `once` can be replayed with
`mate scripts run` — and must not prompt for input.

```bash
#!/usr/bin/env bash
# description: Install/update foo plugins

set -euo pipefail

command -v foo &>/dev/null || exit 0
foo update
```

## Secrets

- Never print decrypted contents into the transcript. Never touch
  `~/.config/statemate/key.txt`.
- Never hardcode a secret — use the `bitwarden` template function, or a
  `generate:` block (see `ssh/.mate.yaml`).
- Never drop an `#enc` suffix; check the staged diff for it before committing.
- Edit an encrypted file without decrypting into the worktree. `mate edit` execs
  `$VISUAL` directly, so it must be an **executable file path**, not a shell string:

```bash
cat >/tmp/mate-editor.sh <<'EOF'
#!/bin/sh
exec python3 /tmp/patch.py "$1"      # or sed -i, etc.
EOF
chmod +x /tmp/mate-editor.sh
VISUAL=/tmp/mate-editor.sh mate edit 'work/.config/profile.d/05-work.sh#tmpl#enc'
```

Confirm the result with `mate cat`, then delete the scratch files.

## Packages

Live in `<source>/.mate.yaml` as a `packages:` list, one package per item. A bare
name goes to the system manager (brew, else pacman; never the AUR). `name: manager`
or `name: [managers]` pins managers, and a list entry renames it per manager —
cf. `git/.mate.yaml`: `lazygit` is bare, `gh: [brew, {pacman: github-cli}]`.
The old manager-keyed `common:`/`brew:` lists are rejected. Details:
statemate's `docs/packages.md`.

## Adding a source

1. `mkdir <name>/` and lay out files relative to `~`.
1. Register it: `sources:` in `mate.yaml`, or a profile's `sources:` if it is
   machine-specific.
1. Add `<name>/.mate.yaml` for its packages.
1. `mate status` — a half-built source in `sources:` breaks apply on every machine.

## Verify before calling it done

In a worktree, run each `mate` check with `STATEMATE_DIR=$PWD` (see Worktrees).

- `mate status` / `mate diff` shows only the intended paths.
- `mate eval` on every touched `#tmpl`.
- `stylua --check` and `luacheck` on touched Lua (`nvim/`, `hyprland/`); `selene`
  if installed.
- `shellcheck` on touched shell scripts.

## Git

Everything lands on `main`; no PRs, no long-lived branches. Commit only when
asked, and never push unless told to.

### Worktrees

Agent workers run in agent-manager worktrees (`dotfiles-worktrees/<name>`, branch
`am/<name>`); every other session works in the main checkout on `main`. The main
checkout is `dirname "$(git rev-parse --path-format=absolute --git-common-dir)"`.

- Bare `mate` reads the main checkout's source, not the worktree. Run read-only
  commands as `STATEMATE_DIR=$PWD mate status|diff|eval|check|cat` so they check
  this worktree's files.
- Deploying waits until the work has landed: `apply`, `clean`, `delete`,
  `forget`, `scripts run` and `packages apply` run from the main checkout.
  `mate rename` also renames the deployed target, so in a worktree change
  attributes with `git mv` and note in the report that the next apply removes
  the old target and deploys the new one.

**Land** a worktree once its commits are made and `git status` is clean:

1. `git rebase main` in the worktree. On a conflict, stop and ask.
1. `git -C <main checkout> merge --ff-only am/<name>`. When `main` moved again,
   rebase again. When the main checkout's uncommitted changes touch the same
   files, stop and ask; leave them as they are.
1. Report the landed commits and what the user still runs: `mate apply`, any
   `mate clean` for removed or renamed sources, and the push.

**Use the `/dotfiles-commit` skill** — it handles Conventional Commits format,
intelligent file grouping, and commit splitting rules. The skill analyzes actual
diffs, groups files logically, and creates properly formatted commits with
interactive review.

**Safety**: Stage explicit paths per commit; never `git add -A` or `git commit -a`.
The skill enforces this. If one file holds multiple commits' worth of changes,
`git diff <file>` → trim the patch → `git apply --cached` (`git add -p` is
interactive and can't be driven).
