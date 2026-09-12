#!/bin/sh
# shellcheck disable=1090,2046

# Load profiles from $XDG_CONFIG_HOME/profile.d
#
# Sourced by both ~/.profile (login shells) and zsh's .zshrc (interactive
# non-login shells), so profile.d scripts are available in every shell.

# Move "$1" to the front of $PATH, adding it when not already in.
# This function API is accessible to scripts in $XDG_CONFIG_HOME/profile.d
#
# An existing entry is stripped first rather than left alone, so precedence is
# guaranteed and not just presence. Skipping a directory already in $PATH would
# mean a shell can never repair the ordering it inherited from its parent -- once
# ~/.local/bin lands behind /opt/homebrew/bin, every nested shell keeps it there.
prepend_path() {
  case ":$PATH:" in
    *:"$1":*)
      _pp_new=''
      _pp_ifs=$IFS
      IFS=:
      for _pp_dir in $PATH; do
        test "$_pp_dir" = "$1" || _pp_new="${_pp_new:+$_pp_new:}$_pp_dir"
      done
      IFS=$_pp_ifs
      PATH=$_pp_new
      unset _pp_new _pp_ifs _pp_dir
      ;;
  esac
  PATH="$1${PATH:+:$PATH}"
}

if test -d "${XDG_CONFIG_HOME:-$HOME/.config}"/profile.d/; then
  for profile in "${XDG_CONFIG_HOME:-$HOME/.config}"/profile.d/*.sh; do
    test -r "$profile" && . "$profile"
  done
  unset profile
fi

prepend_path "$HOME/.local/bin"

# Force PATH to be environment
export PATH

# Unload our profile API functions
unset -f prepend_path
