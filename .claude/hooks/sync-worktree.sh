#!/usr/bin/env bash
# description: Rebase a stale agent worktree onto main at session start

set -euo pipefail

[ "$(git rev-parse --git-dir)" = "$(git rev-parse --git-common-dir)" ] && exit 0
branch=$(git branch --show-current)
case "$branch" in am/*) ;; *) exit 0 ;; esac
git merge-base --is-ancestor main HEAD && exit 0

behind=$(git rev-list --count HEAD..main)

if [ -n "$(git status --porcelain)" ]; then
  echo "WARNING: $branch is $behind commits behind main and has uncommitted changes. Ask before rebasing."
  exit 0
fi

if ! git rebase -q main >/dev/null 2>&1; then
  git rebase --abort
  echo "WARNING: $branch is $behind commits behind main and rebasing conflicts. Ask how to resolve it."
  exit 0
fi

echo "Rebased $branch onto main ($behind commits)."
# CLAUDE.md was loaded before this hook ran.
git diff --quiet ORIG_HEAD HEAD -- CLAUDE.md || echo "CLAUDE.md changed: re-read it before starting."
