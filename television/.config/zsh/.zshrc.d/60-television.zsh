#!/bin/zsh

eval "$(tv init zsh | grep -v '^bindkey')"

alias -g T='| tv text'

bindkey '^F' tv-smart-autocomplete
