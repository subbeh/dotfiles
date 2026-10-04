---
name: dotfiles-commit
description: Intelligent commit workflow for dotfiles - groups changes, analyzes relationships, creates Conventional Commits
trigger: commit|create commit|/commit
model: sonnet
---

# Dotfiles Commit Skill

This skill replaces the manual commit workflow documented in CLAUDE.md. It analyzes changed files, groups them by logical relationship, and creates properly formatted Conventional Commits following the project's conventions.

## When to use

- User says "commit", "create commit", "commit changes", "/commit"
- User wants to commit staged or unstaged changes
- You need to create git commits in the dotfiles repository

## What it does

1. **Analyzes repository state** - checks git status and diffs
1. **Groups files intelligently** - uses AI to understand logical relationships between changed files
1. **Interactive review** - shows each group with reasoning and suggested commit message
1. **Executes commits** - creates commits following Conventional Commits format with proper attribution

## Key behaviors

- **Analyzes actual diffs**: Reads full diffs to understand scope, not just filenames or TODO items
- **AI-driven grouping**: Groups by logical relationships and actual changes, not just directory
- **Shows reasoning**: Explains WHY files were grouped together based on what changed
- **Interactive prompts**: Uses AskUserQuestion for Commit / Skip / Show diff / Chat / Quit actions
- **Show diff option**: View the actual code changes for a group before deciding
- **Chat option**: Discuss grouping, ask questions, or provide different instructions
- **Follows project rules**: All CLAUDE.md conventions (types, scopes, special cases)
- **Never uses**: `git add -A`, `git add .`, `git commit -a` - always explicit file paths
- **Secret scanning**: Integrates with pre-commit hook for security

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

- `#encrypted` files → `git diff` only shows ciphertext. Diff the plaintext with `mate cat`,
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

Co-Authored-By: Claude Sonnet 4.5 (1M context) <noreply@anthropic.com>
```

**Types**: feat, fix, docs, style, refactor, perf, test, build, ci, chore, pkg\
**Scope**: source directory name (or `mate`, `theme` for cross-cutting)\
**Subject**: imperative, lowercase, no period, concise
