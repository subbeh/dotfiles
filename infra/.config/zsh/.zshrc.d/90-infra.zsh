#!/bin/zsh

chkcmd direnv && eval "$(direnv hook zsh)"
chkcmd mise && eval "$(mise activate zsh)"
