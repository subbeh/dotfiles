#!/bin/sh

alias pacman='sudo pacman'
alias paczfl='pacman -Qq | fzf --preview "pacman -Qil {}" --layout=reverse --bind "enter:execute(pacman -Qil {} | less)"'
alias paczfr='pacman -Slq | fzf --preview "pacman -Si {}" --layout=reverse'
alias paclist='tv pacman-packages'
alias pacclean='sudo pacman -Rns $(pacman -Qdtq)'
alias yay='paru'

unalias pacfind 2>/dev/null # a shell that sourced the old alias can't parse the function below
pacfind() {
    [ $# -gt 0 ] || { echo "usage: pacfind <term>" >&2; return 1; }
    # tmux popup, except in dropterm, which is already a terminal of its own
    popup=--tmux=90%,80%
    [ -z "$TMUX" ] || [ "$(tmux display-message -p '#S')" != dropterm ] || popup=
    pkgs=$(paru -Ss "$@" | awk '
        /^[^ ]/ { split($1, a, "/"); repo = a[1]; name = a[2]; ver = $2; mark = / \[installed/ ? "✓" : " "; next }
        { sub(/^ +/, ""); printf "%-10s %-32s %-24s %s  %s\n", repo, name, ver, mark, $0 }' |
        fzf ${popup:+"$popup"} --multi --layout=reverse --preview 'paru -Si {2}') || return 0
    [ -n "$pkgs" ] || return 0
    # zsh doesn't word-split $(...), so build the argument list by hand
    set --
    while read -r _ name _; do set -- "$@" "$name"; done <<EOF
$pkgs
EOF
    paru -S "$@"
}
