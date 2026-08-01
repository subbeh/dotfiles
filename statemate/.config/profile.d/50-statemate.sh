#!/bin/sh

alias cd.="cd $(cut -d: -f2 "$XDG_CONFIG_HOME/statemate/mate.yaml" | sed 's/~/$HOME/')"
alias ds='mate status'
alias da='mate apply'
alias daa='mate apply && mate clean --all --force'
alias dad='mate apply --dry-run -v'
alias de='mate edit'
alias ddiff='mate diff'
alias ddoc='mate doctor'
alias dc='mate clean --all --force'
