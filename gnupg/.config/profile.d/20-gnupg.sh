#!/bin/sh

export GNUPGHOME="${XDG_CONFIG_HOME:-${HOME}/.config}/gnupg"

if test -t 0; then
  GPG_TTY=$(tty)
  GPG_AGENT_SOCK="$(gpgconf --list-dirs agent-socket)"
  export GPG_TTY GPG_AGENT_SOCK

  # gpg-agent is shared with the desktop session, so a GUI pinentry would
  # pop up there; ask pinentry-auto for a terminal one instead.
  if [ -n "${SSH_CONNECTION:-}" ]; then
    export PINENTRY_USER_DATA=USE_CURSES
  fi

  unset SSH_AGENT_PID
  if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
    SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    export SSH_AUTH_SOCK
  fi

  gpg-connect-agent -q updatestartuptty /bye >/dev/null
fi

alias gpgtest="echo test | gpg --clearsign"
alias gpgkill="gpgconf --kill gpg-agent"
alias gpgrestart="gpgconf --kill gpg-agent && gpg-connect-agent /bye"
alias gpgreload="gpg-connect-agent reloadagent /bye"
