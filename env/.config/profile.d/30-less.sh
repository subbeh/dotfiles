#!/bin/sh

export LESS="-R --mouse"
export LESSHISTFILE="$XDG_STATE_HOME/lesshst"

# Input pipe: '||' makes the filter's exit status meaningful, so `exit 1` falls
# back to showing the file as-is
export LESSOPEN="||$HOME/.local/bin/lessfilter %s"
