# Dotfiles Documentation Skill - Implementation Instructions

You are executing the dotfiles documentation maintenance skill. Maintain technical documentation in the workspace notes directory by syncing changes, generating from code, and updating technical notes.

## Documentation Directory

Target: `$XDG_WORKSPACE_DIR/notes/dotfiles/` or `$XDG_NOTES_DIR/dotfiles/`

Typical locations:
- macOS: `/Users/Shared/data/workspace/notes/dotfiles/`
- Linux: `/data/workspace/notes/dotfiles/`

**Always verify the directory exists before writing.**

## Operations

### 1. Sync Changes to Docs

**When**: User says "sync docs", "update documentation", or after they've made changes

**Process**:
1. Determine what changed:
   - Read recent git commits: `git log -10 --name-only --oneline`
   - Or ask user: "What did you change?"
2. Map changes to documentation:
   - tmux keybindings → `tmux-keybindings.md`
   - .mate.yaml packages → `packages.md`
   - New skill → `skills.md`
   - Lifecycle scripts → `lifecycle-scripts.md`
   - profile.d vars → `environment.md`
3. Read the current docs
4. Propose updates (show diff)
5. Get user confirmation
6. Write updated docs
7. Optionally offer to commit: "Would you like me to commit these doc updates?"

**Example**:
```
User: sync the docs

You:
1. Read: `git log -5 --name-only --oneline`
2. See: nvim/plugin/nvim-tree.lua changed
3. Map: This affects architecture.md (new startup behavior)
4. Read: notes/dotfiles/architecture.md
5. Show: 
   "I'll update architecture.md to document the new nvim startup behavior:
   + ## Nvim Startup
   + When launched with no args, nvim shows dashboard + tree split
   
   Proceed?"
6. User confirms
7. Write file
8. Say: "Updated architecture.md"
```

### 2. Generate Docs from Code

**When**: User says "generate docs for X", "document the Y"

**Process**:
1. Identify what needs documenting
2. Read the relevant source files
3. Extract information:
   - Packages: Read all `.mate.yaml` files
   - Scripts: List and describe lifecycle scripts
   - Keybindings: Parse tmux/nvim keymap files
   - Environment: Extract exports from profile.d
4. Generate markdown documentation
5. Show preview
6. Get user confirmation
7. Write to notes directory
8. Confirm to user

**Example**:
```
User: generate the package list documentation

You:
1. Find all .mate.yaml files
2. Read them: git/.mate.yaml, nvim/.mate.yaml, etc.
3. Extract packages by source and manager
4. Generate:
   # Dotfiles Packages
   
   ## Git
   - **Common**: lazygit, worktrunk, gitleaks
   - **brew**: gh
   - **pacman**: github-cli
   
   ## Nvim
   ...
5. Show preview
6. User confirms
7. Write to notes/dotfiles/packages.md
8. Say: "Created packages.md"
```

### 3. Maintain Technical Notes

**When**: User says "update the X docs", "fix the Y documentation"

**Process**:
1. Read the current documentation file
2. Understand what needs updating (ask user if unclear)
3. Make the updates
4. Show diff
5. Get confirmation
6. Write updated file
7. Confirm to user

**Example**:
```
User: update the troubleshooting docs with the jpro status fix

You:
1. Read: notes/dotfiles/troubleshooting.md
2. Add section:
   ## Tmux Jpro Status Wrong Color
   
   **Problem**: Status always shows green (Succeeded) even when Running
   
   **Cause**: Daemon was calling wrong script name
   
   **Fix**: Updated __tmux_jpro_status_daemon to call correct script
3. Show diff
4. User confirms
5. Write
6. Say: "Added jpro status fix to troubleshooting.md"
```

## Code → Docs Mappings

Maintain these mappings (add more as needed):

| Source | Target Doc | What to Document |
|--------|-----------|------------------|
| `tmux/.config/tmux/keymaps.conf` | `tmux-keybindings.md` | Keybinding list with descriptions |
| `*/.mate.yaml` | `packages.md` | Package lists per source |
| `.claude/skills/*` | `skills.md` | Skill inventory and usage |
| `*/.matescripts/*` | `lifecycle-scripts.md` | Script list with descriptions |
| `*/profile.d/*.sh` | `environment.md` | Environment variables and their purposes |
| `mate.yaml`, `.mate/theme.yaml` | `statemate.md` | Statemate configuration |
| Major architectural changes | `architecture.md` | System design and component relationships |
| Bug fixes and workarounds | `troubleshooting.md` | Common issues and solutions |
| `install.sh`, bootstrap process | `setup.md` | Installation and setup procedures |

## Documentation Format

Use consistent markdown formatting:

### Standard Document Structure

```markdown
# Title

Brief overview paragraph.

## Section 1

Content...

### Subsection

Details...

## Section 2

...
```

### Reference Lists

```markdown
## Keybindings

| Key | Description | Command |
|-----|-------------|---------|
| `prefix i` | Jpro sessions | `__tmux_jpro_session_manager` |
| `Ctrl-D` | Delete session | (in fzf picker) |
```

### Troubleshooting Entries

```markdown
## Problem Title

**Problem**: Description of the issue

**Symptoms**: How it manifests

**Cause**: Root cause

**Fix**: How to resolve it
```

### Procedure/Runbook Format

```markdown
## Task Name

**When**: When to perform this

**Steps**:
1. First step with command: `command here`
2. Second step
3. ...

**Verification**: How to verify success
```

## File Management

### Creating New Docs

If a documentation file doesn't exist:
1. Check if `notes/dotfiles/` directory exists
2. If not, create it: `mkdir -p "$NOTES_DIR/dotfiles"`
3. Create the new file
4. Use proper structure (title, overview, sections)

### Updating Existing Docs

1. Read the current file
2. Find the right section to update
3. Make surgical changes (don't rewrite whole file unless necessary)
4. Preserve existing formatting and structure
5. Show only the changed sections in your diff

### File Naming

- Lowercase, hyphen-separated: `tmux-keybindings.md`
- Descriptive names: `troubleshooting.md` not `issues.md`
- Group by topic: All dotfiles docs in `dotfiles/` subdirectory

## Validation

Before writing:
1. Verify target directory exists
2. Verify markdown is valid
3. Check for broken links (if any)
4. Ensure code blocks are properly fenced

After writing:
1. Confirm file was written
2. Show summary of what changed

## Proposals and Confirmation

Always show what you're about to write:

```
I'll update notes/dotfiles/packages.md:

+ ## Git
+ - gitleaks (for secret scanning)

+ ## Nvim  
+ (no changes)

Proceed? [y/N]
```

Don't write until user confirms.

## Integration with Commits

After updating docs, offer to commit:

```
Documentation updated. Would you like me to:
1. Commit these doc updates
2. Include with your next commit
3. Leave uncommitted
```

If user wants a commit:
```bash
git add notes/dotfiles/*.md
git commit -m "docs(dotfiles): update <description>

Co-Authored-By: Claude Sonnet 4.5 (1M context) <noreply@anthropic.com>"
```

Note: The commit is in the notes directory (separate repo), not the dotfiles repo.

## Edge Cases

**Notes directory doesn't exist**: Create it and inform user

**File locked/permission denied**: Report error, suggest manual fix

**User wants different location**: Ask for the path and use it

**Unclear what to document**: Ask specific questions to clarify

## Communication Style

- Be specific: "I'll update tmux-keybindings.md with the new prefix i binding"
- Show diffs, not full files
- Confirm before writing
- Report what you did: "Updated 3 documentation files"

## Examples

### Full Sync Operation

```
User: sync the docs for my changes

You:
1. Check recent commits: git log -5 --name-only
2. See: nvim/plugin/nvim-tree.lua, fzf/.config/zsh/.zshrc.d/50-fzf.zsh
3. Map:
   - nvim change → architecture.md (startup behavior)
   - fzf change → troubleshooting.md (multi-select fix)
4. Read both docs
5. Show proposed changes:
   
   **architecture.md**:
   + ### Nvim Startup (No Args)
   + Displays dashboard in main area + NvimTree in left sidebar
   
   **troubleshooting.md**:
   + ### FZF Multi-Select Not Working
   + **Problem**: Tab doesn't toggle selection in fzf-tab
   + **Cause**: ftb-tmux-popup's smart-tab overrides toggle binding
   + **Fix**: Set popup-smart-tab to no
   
   Proceed? [y/N]
   
6. User: y
7. Write both files
8. Say: "Updated architecture.md and troubleshooting.md. Commit these?"
```

### Generate From Code

```
User: generate documentation for lifecycle scripts

You:
1. Find scripts: `find . -path "*/.matescripts/*" -type f`
2. Read each one
3. Extract: name, description, frequency, timing
4. Generate:
   # Lifecycle Scripts
   
   Scripts that run during `mate apply`.
   
   ## Lifecycle Scripts
   
   | Script | Frequency | When | Description |
   |--------|-----------|------|-------------|
   | 50-install-hooks.sh | always | after | Install git hooks |
   ...
   
5. Show preview
6. User confirms
7. Write to notes/dotfiles/lifecycle-scripts.md
8. Say: "Created lifecycle-scripts.md with 5 scripts documented"
```

## Final Notes

- You are maintaining documentation for the dotfiles project
- The notes live in a separate directory (workspace notes), not in the dotfiles repo itself
- Always verify paths before writing
- Show your work (proposals) before committing to changes
- Be helpful: if you see docs that need updating, suggest it
