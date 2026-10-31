---
name: dotfiles-commit
description: Intelligent commit workflow for dotfiles - groups changes, analyzes relationships, creates Conventional Commits
trigger: commit|create commit|/commit
model: sonnet
---

# Dotfiles Commit Skill

This skill replaces the manual commit workflow documented in CLAUDE.md. It analyzes changed files, groups them by logical relationship, and creates properly formatted Conventional Commits following the project's conventions.

## First: delegate to the commit session

A long-lived agent-manager session named `commit` may own commits for this checkout. Look for it
before anything else:

```bash
command -v agent-manager >/dev/null &&
  agent-manager sessions --json | jq -r --arg dir "$(git rev-parse --show-toplevel)" '
    (map(select(.self))[0].group) as $g
    | .[] | select(.name == "commit" and .running and (.archived | not) and (.self | not)
        and .group == $g and .directory == $dir) | .id'
```

An id means a running `commit` session shares this session's group and checkout: run
`agent-manager send <id> "/dotfiles-commit"`, tell the user to review the commits in that session, and
stop. Don't wait, and commit nothing here. No output (inside the commit session, in a worktree, no
such session, no agent-manager) means run the workflow below in place.

Read [`instructions.md`](instructions.md) before Phase 1: it holds every phase, check and prompt of the
workflow.

## In a worktree: commit, then land

A worktree has `git rev-parse --git-dir` different from `git rev-parse --git-common-dir`. There:

- Commit on the worktree's `am/` branch, and run every `mate` verifier as `STATEMATE_DIR=$PWD mate ...`.
- After the last group, when `git status --porcelain` is empty, ask with `AskUserQuestion`: **Land on main**
  (Recommended) or **Keep on the branch**. Landing follows **Land** under Worktrees in the repo's
  `CLAUDE.md`.
- The workflow ends once `main` holds the commits (`git merge-base --is-ancestor HEAD main`) or the user
  chose to keep them. An orchestrated worker then reports `done`.

## When to use

- User says "commit", "create commit", "commit changes", "/commit"
- User wants to commit staged or unstaged changes
- You need to create git commits in the dotfiles repository

## What it does

1. **Analyzes repository state** - checks git status and diffs
1. **Groups files intelligently** - uses AI to understand logical relationships between changed files
1. **Cleanliness check** - scans each group for debug leftovers, unresolved markers, and unfinished code before review
1. **Interactive review** - shows each group with reasoning and suggested commit message
1. **Executes commits** - creates commits following Conventional Commits format

## Key behaviors

- **Analyzes actual diffs**: Reads full diffs to understand scope, not just filenames or TODO items
- **AI-driven grouping**: Groups by logical relationships and actual changes, not just directory
- **Cleanliness check**: Before review, scans each group's diff for debug prints, TODO/FIXME/WIP markers, merge conflict artifacts, stray commented-out code, and placeholder values; runs `shellcheck`/`mate eval`/`stylua`/`luacheck` on touched files and `gitleaks protect --staged` for secrets. Anything found is surfaced via AskUserQuestion instead of being committed silently
- **Never renders secrets into the transcript**: skips `mate eval` on any template calling `bitwarden(...)` and checks it via a redirected exit-code-only probe instead, since `mate eval` prints the real decrypted secret to stdout
- **Shows reasoning**: Explains WHY files were grouped together based on what changed
- **Interactive prompts**: Uses AskUserQuestion for Commit / Skip / Show diff / Chat / Quit actions
- **Show diff option**: View the actual code changes for a group before deciding
- **Chat option**: Discuss grouping, ask questions, or provide different instructions
- **Follows project rules**: All CLAUDE.md conventions (types, scopes, special cases)
- **Never uses**: `git add -A`, `git add .`, `git commit -a` - always explicit file paths
- **Secret scanning**: Runs `gitleaks protect --staged` itself in the cleanliness check, rather than relying on `.git/hooks/pre-commit` (which no-ops for non-interactive commits since it checks for a TTY)

## Usage

```
User: commit these changes
```

The skill will:

1. Analyze all modified files
1. Group them logically with AI reasoning
1. Show you each group for review
1. Execute commits as approved

## Special cases handled

- Cross-cutting changes (theme updates) → single commit

- New sources → one commit including mate.yaml registration

- Generated/import files → separate `chore` commit

- Per-source splitting → default grouping by source directory

- `#enc` files → `git diff` only shows ciphertext. Diff the plaintext with `mate cat`,
  then delete the scratch files:

  ```bash
  git show 'HEAD:<path>' >/tmp/old.age && mate cat /tmp/old.age >/tmp/old.txt
  mate cat '<path>' >/tmp/new.txt
  diff -u /tmp/old.txt /tmp/new.txt
  rm -f /tmp/old.age /tmp/old.txt /tmp/new.txt
  ```

  Show only the diff, never the whole file. `#import` syncs (kubeconfig, claude settings)
  can stay generic `chore(work): sync imported ...` and don't need a plaintext diff.

## Commit message format

```
type(scope): subject

Optional body with bullet points explaining WHY
```

**Types**: feat, fix, docs, style, refactor, perf, test, build, ci, chore, pkg\
**Scope**: source directory name (or `mate`, `theme` for cross-cutting)\
**Subject**: imperative, lowercase, no period, concise
