#!/bin/zsh

if chkcmd zoxide; then
  export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"
  # keep the repo's source dirs from shadowing the real config dirs; `*` spans `/`
  export _ZO_EXCLUDE_DIRS="$HOME:$XDG_DOTFILES_DIR/*:$XDG_DOTFILES_DIR-worktrees/*"
  eval "$(zoxide init --no-cmd zsh)"

  alias z=__zoxide_z
  alias zz=__zoxide_zi

  zstyle ':fzf-tab:complete:__zoxide_zi:*' fzf-preview 'eza -l --color=always $realpath'
fi
