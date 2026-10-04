#!/bin/zsh

# atuin init forks the atuin binary to generate its hooks/widget -- defer to
# zinit's turbo queue so it doesn't block startup.
zinit wait lucid as'null' id-as'defer-atuin' atload'eval "$(atuin init zsh --disable-up-arrow)"' for %$ZDOTDIR
