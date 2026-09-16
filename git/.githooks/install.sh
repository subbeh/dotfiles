#!/usr/bin/env bash
# Install git hooks from git/.githooks/ into this repository's .git/hooks/
# Run this from the dotfiles repository root: ./git/.githooks/install.sh

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
HOOKS_SRC="${REPO_ROOT}/git/.githooks"
HOOKS_DST="${REPO_ROOT}/.git/hooks"

if [[ ! -d "$HOOKS_SRC" ]]; then
  echo "Error: git/.githooks directory not found" >&2
  exit 1
fi

if [[ ! -d "${REPO_ROOT}/.git" ]]; then
  echo "Error: Not in a git repository" >&2
  exit 1
fi

mkdir -p "$HOOKS_DST"

for hook in "$HOOKS_SRC"/*; do
  [[ -f "$hook" ]] || continue
  [[ "$(basename "$hook")" == "install.sh" ]] && continue

  hook_name="$(basename "$hook")"
  cp "$hook" "$HOOKS_DST/$hook_name"
  chmod +x "$HOOKS_DST/$hook_name"
  echo "Installed: $hook_name"
done

echo "Git hooks installed to $HOOKS_DST"
