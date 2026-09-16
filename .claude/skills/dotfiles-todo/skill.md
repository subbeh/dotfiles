---
name: dotfiles-todo
description: Comprehensive TODO management for dotfiles - add, check off, interview/spec, organize
trigger: todo|/todo|TODO
---

# Dotfiles TODO Skill

Manages the TODO.md file in the dotfiles repository. Handles adding items, checking off completed items, interviewing vague items to create detailed specs, and organizing/prioritizing the backlog.

## When to use

- User says "todo", "/todo", "add to TODO", "check off TODO", "what's in my TODO"
- User mentions TODO.md or asks about pending work
- User wants to clarify or expand a vague TODO item
- User wants to organize or prioritize the TODO list

## What it does

Provides comprehensive TODO management:

1. **Add items** - Add new TODO items to the appropriate section (FIX/FEAT/BACKLOG)
2. **Check off items** - Mark items as complete `[x]`
3. **Interview and spec** - Clarify vague items and expand them inline with detailed specs
4. **Organize** - Reorder items by priority, dependencies, or user preference

## Key behaviors

- **Context-aware**: Detects what you need based on your request
- **Inline expansion**: Spec details go directly under the TODO item, not separate files
- **Preserves structure**: Maintains section headers and formatting
- **No deletion**: Keeps `[x]` completed items for history

## Usage examples

```
User: add a TODO to fix the clipboard issue in vifm
→ Adds item to FIX section

User: check off the nvim indent todo
→ Marks it [x]

User: what does the "hypr monitor reload" todo mean?
→ Interviews you, expands item inline with details

User: organize my TODOs by priority
→ Reorders items, shows you the result
```

## Spec format (inline expansion)

When interviewing/spec'ing a vague item, expand it in place:

```markdown
- [ ] vague description
  - **Problem:** Clear problem statement
  - **Solution:** Proposed approach
  - **Details:**
    - Specific detail 1
    - Specific detail 2
  - **Acceptance:**
    - [ ] Criterion 1
    - [ ] Criterion 2
```

## Section meanings

- **FIX**: Bugs, broken functionality, things that need fixing
- **FEAT**: New features, enhancements, additions
- **BACKLOG**: Lower priority, future work, ideas

The skill routes new items to the appropriate section based on their nature.
