#!/bin/zsh

eval "$(tv init zsh | grep -v '^bindkey')"

alias -g T='| command tv text'

bindkey '^F' tv-smart-autocomplete
