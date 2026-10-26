#!/bin/zsh

# wt's shell init just defines a function + completion -- defer to zinit's
# turbo queue so forking the wt binary to generate it doesn't block startup.
zinit wait lucid as'null' id-as'defer-git-wt' atload'eval "$(wt config shell init zsh)"' for %$ZDOTDIR
