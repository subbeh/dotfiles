#!/bin/zsh

if [ "$PROFILE_OS" = "darwin" ]; then
  _bin=${XDG_PROJECTS_DIR}/statemate/dist/mate-darwin-arm64
elif [ "$PROFILE_OS" = "linux" ]; then
  _bin=${XDG_PROJECTS_DIR}/statemate/dist/mate-linux-amd64
fi

if [ -x "$_bin" ]; then
  rm -f "${XDG_BIN_HOME}/mate"
  ln -s "$_bin" "${XDG_BIN_HOME}/mate" 2>/dev/null
else
  _bin=$(which mate)
fi

# Completion generation forks mate -- defer to zinit's turbo queue.
zinit wait lucid as'null' id-as'defer-statemate' atload"source <($_bin completion zsh)" for %$ZDOTDIR
