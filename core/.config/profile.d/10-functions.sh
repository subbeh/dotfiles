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
  printf "%q" "$file"
}

# extract archives
extract() {
  local f
  [ $# -gt 0 ] || { echo "Usage: extract <archive>..." >&2; return 1; }
  for f in "$@"; do
    [ -f "$f" ] || { echo "extract: '$f' is not a file" >&2; return 1; }
    case "$f" in
      *.tar | *.tar.* | *.tgz | *.tbz | *.tbz2 | *.txz | *.tzst) tar -xf "$f" ;;
      *.zip) unzip "$f" ;;
      *.rar) unrar x "$f" ;;
      *.7z) "$(command -v 7zz || command -v 7z)" x "$f" ;;
      *.gz) gunzip -k "$f" ;;
      *.bz2) bunzip2 -k "$f" ;;
      *.xz) unxz -k "$f" ;;
      *.zst) unzstd "$f" ;;
      *) echo "extract: unsupported archive '$f'" >&2; return 1 ;;
    esac || return
  done
}
