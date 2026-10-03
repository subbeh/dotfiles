#!/bin/zsh

# A tmux pane keeps the environment it started with, so a pane opened at the
# desktop still asks pinentry-auto for the GUI after you attach over SSH.
# Before each command, re-read SSH_CONNECTION from the tmux session (refreshed
# on attach via update-environment) and set PINENTRY_USER_DATA to match.

if [[ -n "$TMUX" ]]; then
  function gnupg_pinentry_preexec() {
    eval "$(tmux show-environment -s SSH_CONNECTION 2>/dev/null)"
    if [[ -n "$SSH_CONNECTION" ]]; then
      export PINENTRY_USER_DATA=USE_CURSES
    else
      unset PINENTRY_USER_DATA
    fi
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook preexec gnupg_pinentry_preexec
fi
