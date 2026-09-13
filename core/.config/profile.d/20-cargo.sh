#!/bin/sh

export CARGO_HOME="$XDG_DATA_HOME/cargo"

prepend_path "$CARGO_HOME/bin"

export PATH
