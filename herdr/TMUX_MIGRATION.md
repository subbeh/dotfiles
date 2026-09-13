# tmux → herdr migration assessment

**Written:** 2026-08-26
**Assessed against:** herdr 0.8.2 (stable), tmux config in `tmux/`, herdr config in `herdr/`, `tmux-tpad` at `~/workspace/projects/tmux-tpad`
**Status:** parked — revisit when herdr is more mature

Sources: herdr docs (config, plugins, socket API, CLI, keyboard, session-state) at
`https://herdr.dev/docs/` + `https://raw.githubusercontent.com/herdrdev/herdr/v0.8.2/docs/next/website/src/content/docs/`,
`herdr --default-config`, `herdr config check`, live probe of the running server.

Claims below are marked **[verified]** (probed the binary/server), **[docs]**, or
**[untested]**.

---

## Verdict

Viable switch. tpad **is** reproducible, but not with herdr's popup alone — the
popup is ephemeral, so the persistent-session half of tpad has to be rebuilt by
putting a session holder *inside* the popup. Two marketplace plugins already do
exactly this, so the pattern is proven.

Migration cost concentrates in three places: **tpad**, the **vim navigation
keys**, and the **jpro tooling**. The agent-centric parts are a clear upgrade.

---

## 1. tpad → herdr

### What herdr gives you (0.8.2)

```toml
[[keys.command]]
key = "prefix+ctrl+g"
type = "popup"          # session-modal, composited over the active pane, layout unchanged
command = "lazygit"
width = "80%"           # cells or %
height = "80%"
```

**[verified]** `keys.command` accepts **only** `key`, `type`, `command`,
`description`, `width`, `height`. `herdr config check` rejects `x`, `y`, `title`,
`border`, `cwd` as unknown keys.

Other `type` values: `pane` (temporary zoomed pane), `shell` (detached
background), `plugin_action` (invoke a plugin action id).

### Why that isn't tpad yet

**[docs]** The popup closes when its command exits, and while open it swallows
*all* terminal input including Escape — no herdr keybinding can dismiss it. So
both the toggle and the state persistence must come from inside the popup.

### The mechanism

Run a detached-session holder in the popup:

```toml
[[keys.command]]
key = "prefix+ctrl+g"
type = "popup"
command = 'exec zsh -lc "exec __hpad git"'
width  = "80%"
height = "80%"
```

`__hpad` resolves the per-directory session name from `$HERDR_ACTIVE_PANE_CWD`
(git root) and execs `dtach -A <sock> <cmd>` or `tmux new-session -A -s <name>`.

Dismiss = the holder's detach key (dtach `ctrl+\`, configurable with `-e`) →
holder exits → popup closes → **process and viewport survive**. Reopen
re-attaches. That is tpad's toggle semantics exactly.

Neither `dtach` nor `abduco` is installed; both are in Homebrew. **[verified]**

### Prior art (confirms the pattern works)

| Plugin | Approach |
| --- | --- |
| `jeromychu23/herdr-popupx` (id `herdr-scratch-pane`) | native 0.8.x popup + **tmux** for shell/cwd/viewport persistence; `prefix+f` hides, `prefix+x` kills. macOS only |
| `Tyru5/herdr-floax` | tmux-floax clone; `dtach`/`abduco`/`tmux` holder. Uses split-then-zoom (pre-0.7.4 workaround), so it draws its own backdrop — the native popup path is better now |
| `abelfubu/herdr-popup` | generic popup entrypoint: `herdr plugin pane open --placement popup --width … --env HERDR_POPUP_CMD=…` → **per-invocation** cmd/cwd/size. This is the piece needed for per-instance geometry driven from a script |

### Instance mapping

| tpad instance | herdr | Notes |
| --- | --- | --- |
| `scratchpad` C-p | popup + holder | 1:1. Inner tmux provides the `status on` |
| `git` C-g, per-dir | popup + holder, session key from `$HERDR_ACTIVE_PANE_CWD` | 1:1. Alt: `Crokily/herdr-lazygit` |
| `notes` C-n | popup + holder | 1:1. `prefix "None"` is free — you own the inner mux config |
| `k9s` C-k | popup + holder | 1:1 |
| `vifm` C-v | popup + holder | 1:1. Alt: `speardragon/herdr-yazi` |
| `task` C-t | popup + holder | 1:1 |
| `claude` C-c, 30%×90% @ pos_x 350% | **do not port as a popup** | see below |

### What is lost

- **Positioning.** No `pos_x`/`pos_y`. Popups are centered, sized only. The
  side-docked claude panel is not expressible.
- **Per-popup title/style/border.** `#[fg=magenta,bold] 󱂬 TPad: …` is gone from
  `keys.command`. Plugin manifest `[[panes]]` *does* support `title`, so a plugin
  port keeps titles but not tmux colour markup.
- **Eject/reclaim.** **[docs]** A popup "has no pane ID, is outside all `pane.*`
  APIs" — `join-pane` has no analogue. But the holder design gives something
  better: eject = `herdr pane split` + `dtach -a <same sock>`; reclaim = detach
  there, toggle the popup. Same session, two surfaces.
  `__tmux_tpad_adopt_pane` becomes obsolete.
- **Fullscreen toggle.** Bind a second key at `100%`×`100%` to the same instance.
- **Mouse-event bindings** (`MouseDown3Pane`). herdr has no mouse keybinding
  config. (Not used in the current config, only in the tpad README.)

### claude should not be a popup

herdr treats agents as first-class: sidebar state (`blocked`/`working`/`done`),
notifications, `focus_agent` index jumps, `agent prompt`/`agent wait`, native
session resume. **[verified]** `herdr integration status` shows
`claude: current (v8)` already installed.

Make it a normal split or tab. The existing `eject-split right / 40%` config says
that's where it wants to live anyway. `claude-runner` still works as the pane
command; agent detection is process/screen-based.

---

## 2. Aspect-by-aspect

### Core options (`tmux/.config/tmux/env.conf`)

| tmux | herdr |
| --- | --- |
| `prefix C-s` | `keys.prefix = "ctrl+s"` ✓ already set |
| `default-terminal`, `terminal-overrides` RGB / undercurl / `Setulc` | no config surface — herdr's emulator decides. **[untested]** undercurl + underline colours (nvim diagnostics) |
| `history-limit 1000000` | `advanced.scrollback_limit_bytes`, default 10 MB ≈ 50k lines. Raise it; note it's **bytes per pane**, not lines |
| `mouse on`, `@scroll-speed-num-lines-per-scroll 5` | `ui.mouse_capture`, `ui.mouse_scroll_lines = 5` ✓ |
| `set-clipboard on`, `allow-passthrough` | `ui.copy_on_select`. **[untested]** OSC 52 passthrough from pane apps |
| `focus-events on` | `ui.redraw_on_focus_gained` is about the *outer* terminal. **[untested]** pane-level FocusGained forwarding (nvim autoread) |
| `set-titles-string "#S > #T"` | `ui.window_title = "{hostname}: {workspace}"` ✓ better — tokens `{hostname} {workspace} {tab} {pane} {terminal_title}`, renders server-side so correct under `--remote` |
| `base-index`, `pane-base-index`, `renumber-windows`, `detach-on-destroy`, `aggressive-resize`, `escape-time`, `repeat-time` | N/A — no equivalents needed |
| `update-environment SSH_AUTH_SOCK …` | N/A — server-owned env, see gotcha #6 |

### Keymaps (`tmux/.config/tmux/keymaps.conf`)

Direct equivalents exist for: pane focus/swap/resize, splits, tab next/prev/1-9,
new/rename/close tab, zoom, detach, reload, copy mode. Plus extras tmux lacks:
`prefix+e` opens pane scrollback in `$EDITOR`, `prefix+b` toggles the sidebar.

Copy mode (`prefix+[`) covers both the `Escape` copy-mode binding and the
`f` → `copy-mode ?` search binding: vi motions `h/j/k/l`, `w/b/e`, `W/B/E`,
`{`/`}`, `ctrl+u`/`ctrl+d`, `/` and `?` search with `n`/`N`, `v`/Space select,
`y`/Enter copy. Mouse drag-select copies without entering copy mode.

**No equivalent:**

| tmux binding | Situation |
| --- | --- |
| `bind C-s send-prefix` | **[verified]** no send-prefix action in the full key list. With prefix `ctrl+s` in herdr, ssh'ing to a box running tmux at `C-s` becomes unusable. Change one of the two prefixes, or use `herdr --remote` |
| `bind C-a setw synchronize-panes` | not built in. Plugins: `furuhashin/herdr-synchronize-panes`, `wg1k/live-sync-panes` (live keystroke sync), `andischerer/herdr-plugin-echo`, `kamaaina/herdr_sync` |
| `!@#$%^&*()` move-window-to-index | only `move_tab_previous` / `move_tab_next` (relative) |
| `=` reset layout / `+` recreate layout | `layout.apply` is the right tool (declarative BSP tree with `cwd`/`env`/argv/`ratio`) but is **socket-only, not in the CLI** — needs a JSON-over-socket script. Plugins: `iurysza/herdr-pane-layouts`, `crierr/herdr-tmux-layout`, `edouard-andrei/herdr-layout-tools` |
| `Space` switch-client -l + `C-Space` last-window | `keys.last_pane` ("last focused pane across workspaces and tabs") collapses both into one binding |
| `@` choose-window + join-pane | `herdr pane move <id> --tab <tab> --split right` (CLI, no interactive picker) |

#### The vim-aware `C-h/j/k/l` problem

This is the biggest keymap issue, and **the current herdr config already has it**:
`focus_pane_left = ["prefix+h", "ctrl+h"]` etc. means herdr eats `ctrl+hjkl`
before nvim sees them, so `alexghergh/nvim-tmux-navigation` (loaded
`lazy = false`) is dead. herdr has no `if-shell "$is_vim"` analogue —
**[verified]** no conditional key routing exists in the key action list.

Options, best first:

1. `aimdevlee/herdr-nvim-nav` or `lmilojevicc/herdr-splits.nvim` — socket-based,
   avoids the per-keystroke CLI round-trip that
   `paulbkim-dev/vim-herdr-navigation` incurs (`pane process-info` + `jq` per
   press).
2. Move herdr to `ctrl+alt+hjkl` (the doc-recommended safe modifier family —
   free across Ghostty/iTerm2/kitty/WezTerm/GNOME/KDE, unaffected by the macOS
   option-compose behaviour). Leave `ctrl+hjkl` entirely to nvim, drop the nvim
   plugin. No cross-boundary navigation.

### Theme / status line (`tmux/.config/tmux/theme.conf`)

| tmux | herdr |
| --- | --- |
| `status-left`: session name + `#{server_sessions}` + remote badge | sidebar (workspace list) + `tab_bar_right` `{type="hostname"}` — resolves server-side ✓ |
| `status-right`: `__tmux_status_right` → statemate + gitmux | `tab_bar_right` `{type="command", command=…, interval_seconds=5, timeout_seconds=2}`. **gitmux emits tmux `#[fg=…]` markup — that will not render.** Use a plain gitmux format, or drop it: sidebar Space rows have native `branch` + `git_status` tokens |
| `window-status-format` with `#{@jpro_status}` coloured dot | `herdr pane report-metadata --token` / `herdr workspace report-metadata --token` → `$name` tokens in `[ui.sidebar.agents]` / `[ui.sidebar.spaces]` rows, with per-token `fg`/`bold`/`dim`. **But there is no tab-level metadata API** — see jpro below |
| `window_zoomed_flag` marker | `tab_bar_right` `{type="zoom"}` + per-tab `Z` markers |
| `set-hook client-focus-in/out` dim | no hooks. `theme.auto_switch` only tracks light/dark appearance |
| colours | `theme.name = "terminal"` ✓ already set; `[theme.custom]` for individual token overrides |

### Plugins (tpack → herdr plugins)

| Current | herdr |
| --- | --- |
| `tmux-plugins/tpm` + tpack | built-in `herdr plugin install owner/repo[/subdir]`, GitHub-shorthand only, `--ref` to pin. `natori-hrj/herdr-lazy` adds lockfile-style management |
| `sainnhe/tmux-fzf` | built-in `prefix+g` goto / `prefix+w` picker; `JanTvrdik/herdr-command-palette`, `jeffarese/herdr-bar`, `thanhdat77/herdr-navigator`, `fullerzz/herdr-plugin-sesh` |
| `Morantron/tmux-fingers` (`F` / `N`) | `rmarganti/herdr-pluck` — hint-based token copy + open-URL, prebuilt binaries |
| `tmux-plugins/tmux-open` (`o`, `C-o`, `S-s`) | native ctrl+click link handlers (`[[link_handlers]]` with regex → plugin action); `iurysza/termscope`. A plugin action on `prefix+o` can read selected text from `HERDR_PLUGIN_CONTEXT_JSON` |
| `tmux-plugins/tmux-logging` | **no `pipe-pane`.** `herdr terminal session observe` streams newline-delimited JSON frames with base64 ANSI — usable but needs writing. `waynewu411/herdr-event-log` only logs events |
| `nhdaly/tmux-better-mouse-mode` | native ✓ |
| `Subbeh/tmux-tpad` | section 1 |

### tmuxinator (`home`, `work`, `dropterm`)

Mostly obsolete. herdr's server keeps layout live across client detach, and
snapshot restore rebuilds workspaces/tabs/panes/cwd/focus after a server
restart. Add `[experimental] pane_history = true` to also replay recent screen
contents (off by default because output can contain secrets).

For the declarative part: `layout.apply`, or `yuk1ty/herdr-spreader`,
`razajamil/herdr-plugin-workspace-manager`, `andrewchng/herdr-sessionizer`,
`ntindle/herdr-resurrect`, `3mmdrew/herdr-layout`.

The hardcoded `layout: b703,459x119,…` strings don't port — herdr uses split
ratios, which is an improvement.

### Scripts & external integration

| Script | herdr |
| --- | --- |
| `__tmuxinator_sessions` (fzf picker) | built-in pickers, or fzf in a popup calling `herdr workspace focus` |
| `cda` (cd all panes in window) | `herdr pane list --workspace` + `herdr pane run` — a few lines, cleaner than the tmux version |
| `__tmux_is_remote` (walks ppid for sshd) | `tab_bar_right` hostname entry, or `herdr --remote` |
| `__tmux_status_right` | `tab_bar_right` command entry (see gitmux caveat) |
| `__tmux_tpad_adopt_pane` | obsolete — popups aren't panes; use the shared holder socket |
| hyprland `dropterm.lua` → `kitty … tmux new-session -A -s dropterm` | `herdr --session dropterm` ✓ 1:1 |
| `__hypr_tmux_sessions` (systemd-run + `enable-linger`) | `herdr server` under a user unit; keep `enable-linger`. `tmux/.config/profile.d/20-tmux.sh` needs the same treatment |
| `__tmux_jpro_session_manager` | ports well: `workspace create` / `tab create` / `pane split --cwd` / `pane run`, or one `layout.apply` call. **But** the `@jpro_status` dot needs metadata, and metadata exists for panes and workspaces only → jpro instances must become **workspaces**, not tabs in a `work` session. Arguably the better model (own sidebar row, git status, agent rollup). The `pipe-pane` logging needs a `script`/`tee` wrapper |
| `__tmux_jpro_status_daemon` / `__tmux_jpro_status_update` | rewrite around `herdr workspace report-metadata --token jpro=… --ttl-ms …`. The bell-on-change hack (`send-keys C-g`) becomes `herdr notification show` |

---

## 3. Blocker list

1. **No conditional key routing** → vim navigation needs a plugin or a modifier
   change. The current herdr config is already broken here.
2. **No send-prefix** → prefix collision with remote tmux at `C-s`.
3. **No positioning or styling for popups**, and popups can't be ejected into
   panes.
4. **No `pipe-pane`** → jpro per-pane logging needs rework.
5. **No tab-level metadata** → jpro status forces instances to become
   workspaces.
6. **[verified] Server env is bare.** The running server (`launchd`-parented) has
   `PATH=/usr/bin:/bin:/usr/sbin:/sbin` and only
   `HOME LOGNAME SHELL SSH_AUTH_SOCK TMPDIR USER XPC_*` — no `NOTES_DIR`,
   `HOMELAB_DIR`, `PROJECT_DIR`, `JAMF_DIR`. Custom `popup`/`pane` commands run
   through `/bin/sh -c` from that env, so `lazygit`, `k9s`, `vifm`,
   `taskwarrior-tui` (all `/opt/homebrew/bin`) won't resolve and `${NOTES_DIR}`
   will be empty.
   **Wrap every command as `zsh -lc '…'`** — `~/.profile` (and therefore
   `profile.d`) is sourced from `.zprofile`, so a login *zsh* picks it up.
   `/bin/sh -lc` will **not**. Interactive panes are fine
   (`[terminal] shell_mode = "auto"` → login shells on macOS).
7. **[untested], ~10 min each:** undercurl / underline colours, OSC 52
   passthrough from nvim, pane focus events, extended-keys / modern keyboard
   protocol.

Not a problem: `image.nvim` is `enabled = false` in `nvim/`, so herdr's
experimental `kitty_graphics` status is moot.

---

## 4. Migration order

1. Fix the nvim key collision (`ctrl+alt+hjkl` for herdr, or a nav plugin) —
   broken in the herdr config *today*, independent of any migration.
2. `brew install dtach`, then prototype **one** tpad instance (`git`) as
   popup + dtach and confirm the toggle feel by hand. This is the one thing that
   can't be verified without pressing a key in a live session.
3. If the feel is right, port the remaining five popups. Move `claude` to a real
   pane with the agent integration.
4. Port `__tmux_jpro_session_manager` to workspaces + `layout.apply` +
   `workspace report-metadata`.
5. Install `herdr-pluck`, a synchronize-panes plugin, and a nav plugin to close
   the tmux-plugin gap.

---

## Appendix: useful herdr surface

```bash
herdr --default-config              # full annotated default config
herdr config check                  # validate config.toml, reports unknown keys
herdr server reload-config          # apply most changes without restarting panes
herdr api snapshot                  # live session snapshot
herdr api schema --json             # full socket API JSON Schema
herdr --skill                       # agent skill file for driving herdr
```

Socket-only methods with no CLI wrapper: `layout.export`, `layout.apply`,
`layout.set_split_ratio`, `popup.close`, `agent.view.set`, `events.subscribe`.
Newline-delimited JSON over `$HERDR_SOCKET_PATH`.

Custom commands receive `HERDR_SOCKET_PATH`, `HERDR_BIN_PATH`,
`HERDR_ACTIVE_WORKSPACE_ID`, `HERDR_ACTIVE_TAB_ID`, `HERDR_ACTIVE_PANE_ID`,
`HERDR_ACTIVE_PANE_CWD`. Popups do **not** get `HERDR_PANE_ID`.

Docs mirror: `https://raw.githubusercontent.com/herdrdev/herdr/v<version>/docs/next/website/src/content/docs/<page>.mdx`
(`configuration`, `plugins`, `socket-api`, `cli-reference`, `keyboard`,
`concepts`, `how-to-work`, `session-state`, `agent-automation`, `integrations`),
plus `src/data/config-reference.json` for every setting with type and default.
