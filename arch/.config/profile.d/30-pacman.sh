#!/bin/sh

alias paczfl='pacman -Qq | fzf --preview "pacman -Qil {}" --layout=reverse --bind "enter:execute(pacman -Qil {} | less)"'
alias paczfr='pacman -Slq | fzf --preview "pacman -Si {}" --layout=reverse'
alias paclist='tv pacman-packages'
alias pacfind='paru -Ss'
alias pacclean='sudo pacman -Rns $(pacman -Qdtq)'
alias yay='paru'
