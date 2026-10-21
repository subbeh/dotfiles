---
name: dotfiles-docs
description: Maintain technical documentation in workspace notes directory - sync changes, generate docs from code
trigger: update docs|sync docs|document this
---

# Dotfiles Documentation Skill

Maintains technical documentation in the workspace notes directory (`$XDG_WORKSPACE_DIR/notes` or `$XDG_NOTES_DIR`). Syncs code changes to relevant docs, generates documentation from code/config, and keeps technical notes current.

## When to use

- User says "update docs", "sync documentation", "document this change"
- After significant changes that affect documentation
- User asks to generate docs from code or config
- User wants to update technical notes

## What it does

Three main operations:

1. **Sync changes to docs** - When code changes, update corresponding documentation
2. **Generate docs from code** - Create documentation from source files, configs, scripts
3. **Maintain technical notes** - Keep architecture/troubleshooting/setup docs current

## Key behaviors

- **Manual invocation only** - Never runs automatically; user must request it
- **Notes directory target** - Updates files in `$XDG_WORKSPACE_DIR/notes` (typically `/Users/Shared/data/workspace/notes`)
- **Shows proposals** - Displays what will change before writing
- **Consistent formatting** - Maintains markdown structure across docs

## Usage examples

```
User: update docs for the new tmux keybindings
→ Updates notes/dotfiles/tmux-keybindings.md

User: generate package list documentation
→ Reads .mate.yaml files, creates notes/dotfiles/packages.md

User: sync the documentation
→ Detects recent commits, updates relevant docs
```

## Documentation types

- **Architecture**: How components fit together
- **Setup**: Bootstrap/installation procedures
- **Reference**: Generated lists (packages, scripts, keybindings)
- **Troubleshooting**: Common issues and solutions
- **Runbooks**: Procedures for maintenance tasks

## Mappings (code → docs)

| Source Change | Documentation File |
|---------------|-------------------|
| tmux keybindings | notes/dotfiles/tmux-keybindings.md |
| .mate.yaml packages | notes/dotfiles/packages.md |
| New skill | notes/dotfiles/skills.md |
| Lifecycle scripts | notes/dotfiles/lifecycle-scripts.md |
| profile.d env vars | notes/dotfiles/environment.md |
| Statemate changes | notes/dotfiles/statemate.md |

## Output location

All documentation goes to:
```
$XDG_WORKSPACE_DIR/notes/dotfiles/
```

Typically:
- macOS: `/Users/Shared/data/workspace/notes/dotfiles/`
- Linux: `/data/workspace/notes/dotfiles/` or `$XDG_DATA_DIR/workspace/notes/dotfiles/`
