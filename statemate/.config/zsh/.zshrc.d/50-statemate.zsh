#!/bin/zsh

if [ "$PROFILE_OS" = "darwin" ]; then
  _bin=${XDG_PROJECTS_HOME}/statemate/dist/mate-darwin-arm64
elif [ "$PROFILE_OS" = "linux" ]; then
  _bin=${XDG_PROJECTS_HOME}/statemate/dist/mate-linux-amd64
fi

if [ -x "$_bin" ]; then
  rm -f "${XDG_BIN_HOME}/mate"
  ln -s "$_bin" "${XDG_BIN_HOME}/mate" 2>/dev/null
else
  _bin=$(which mate)
fi

source <($_bin completion zsh)
