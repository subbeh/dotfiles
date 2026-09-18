#!/bin/zsh

# tmux project-specific environment setup
# Automatically set PROJECT_ROOT and cdh alias based on tmux window option

if [[ -n "$TMUX" ]]; then
  # Get project root from tmux window option
  _project_root=$(tmux show-option -wqv @project-root 2>/dev/null)

  if [[ -n "$_project_root" ]]; then
    export PROJECT_ROOT="$_project_root"
    alias cdh="cd \${PROJECT_ROOT:?not set}"
  fi

  unset _project_root
fi
