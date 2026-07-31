#!/bin/sh

alias cd.="cd \${XDG_DOTFILES_HOME}"
alias .s='mate status'
alias .a='mate apply'
alias .aa='mate apply && mate clean --all --force'
alias .ad='mate apply --dry-run -v'
alias .e='mate edit'
alias .diff='mate diff'
alias .doc='mate doctor'
alias .c='mate clean --all --force'
