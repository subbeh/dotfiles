#!/bin/zsh

# A tmux pane keeps the environment it started with, so a pane opened at the
# desktop still asks pinentry-auto for the GUI after you attach over SSH.
# Before each command, re-read SSH_CONNECTION from the tmux session (refreshed
# on attach via update-environment) and set PINENTRY_USER_DATA to match.
#
# `tmux show-environment` forks the tmux binary and round-trips to its server,
# which is too slow to pay synchronously on every command. So preexec applies
# the last cached value (a plain file read) and kicks the real tmux query off
# in the background to refresh that cache for next time.

if [[ -n "$TMUX" ]]; then
  _gnupg_ssh_cache="${XDG_CACHE_HOME}/gnupg/ssh-connection-tmux-${TMUX//[\/,]/_}"
  mkdir -p "${_gnupg_ssh_cache:h}"

  function gnupg_pinentry_preexec() {
    [[ -r "$_gnupg_ssh_cache" ]] && eval "$(<"$_gnupg_ssh_cache")"
    {
      tmp=$(mktemp "${_gnupg_ssh_cache}.XXXXXX" 2>/dev/null) || return
      if tmux show-environment -s SSH_CONNECTION >|"$tmp" 2>/dev/null; then
        command mv -f "$tmp" "$_gnupg_ssh_cache"
      else
        rm -f "$tmp"
      fi
    } &|

    if [[ -n "$SSH_CONNECTION" ]]; then
      export PINENTRY_USER_DATA=USE_CURSES
    else
      unset PINENTRY_USER_DATA
    fi
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook preexec gnupg_pinentry_preexec
fi
