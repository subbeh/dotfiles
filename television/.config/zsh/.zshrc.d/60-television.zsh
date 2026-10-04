#!/bin/zsh

alias -g T='| command tv text'

# tv init forks the tv binary to generate its widget -- defer to zinit's turbo
# queue; the keybinding moves with it since it needs the widget to exist first.
zinit wait lucid as'null' id-as'defer-television' atload'eval "$(tv init zsh | grep -v "^bindkey")"; bindkey "^F" tv-smart-autocomplete' for %$ZDOTDIR
