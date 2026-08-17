#!/bin/bash

# check command
chkcmd() { command -v "$1" >/dev/null 2>&1 || return 1; }

# mkdir & cd
md() { [ $# = 1 ] && mkdir -p "$@" && cd "$@" || echo "Error - no directory passed!"; }

# retry previous command
retry() {
  until eval $(fc -ln -1); do
    sleep "${1:-1}"
  done
}

# watch previous command
ck() { watch -n"${1:-5}" "$(fc -ln -1)"; }

# copy full path to clipboard
xf() {
  chkcmd pbcopy && echo -n "${PWD}/$*" | pbcopy
  chkcmd wl-copy && echo -n "${PWD}/$*" | pbcopy -n
}

# copy with rsync
cpr() {
  rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1 --exclude='.snapshots' --exclude='.vifm-Trash*' "$@"
}

# move with rsync
mvr() {
  rsync --archive -hh --partial --info=stats1,progress2 --modify-window=1 --remove-source-files "$@"
}

# user login
chkcmd machinectl && chusr() {
  machinectl shell $1@
}

# calculator
_calc() { printf "%s\n" "$*" | bc -l; }
alias calc='noglob _calc'

# random file generator
rand() {
  if [[ -z "$1" ]]; then
    file="$(find . -type f | shuf -n 1)"
  else
    file="$(find . -type f -name "*$1*" | shuf -n 1)"
  fi
  echo "$file"
}
