#!/bin/sh

test -r "$XDG_CONFIG_HOME/statemate/key.txt" && export STATEMATE_KEY_FILE="$XDG_CONFIG_HOME/statemate/key.txt"

alias cd.='cd $(yq '.source_dir' < "$XDG_CONFIG_HOME/statemate/config.yaml")'
alias ds='mate status'
alias da='mate apply --noconfirm'
alias daa='mate apply --noconfirm && mate clean --all --noconfirm'
alias dad='mate apply --dry-run -v'
alias de='mate edit'
alias ddiff='mate diff'
alias ddoc='mate doctor'
alias dc='mate clean --all --noconfirm'
