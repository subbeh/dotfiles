#!/bin/zsh

source <(fzf --zsh)

# fzf-tab (loaded via zinit in 30-zinit.zsh) replaces the completion menu with
# fzf. Disable zsh's own menu so it can capture the unambiguous prefix.
zstyle ':completion:*' menu no

# fzf-tab tuning
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1a --color=always $realpath'
zstyle ':fzf-tab:*' fzf-flags --multi
zstyle ':fzf-tab:*' fzf-bindings 'tab:toggle+down'
# When the popup opens above the cursor, ftb-tmux-popup appends
# `--bind=tab:up,btab:down` after our flags, and fzf lets the later --bind win --
# which silently kills tab:toggle+down. Opting out keeps Tab as multi-select.
zstyle ':fzf-tab:*' popup-smart-tab no

# Render fzf-tab completions in a floating tmux popup (falls back to inline fzf
# when not inside tmux). Requires tmux >= 3.2.
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:complete:cd:*' popup-pad 30 0
