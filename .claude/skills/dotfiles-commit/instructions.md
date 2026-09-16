# Dotfiles Commit Skill - Implementation Instructions

You are executing the dotfiles commit skill. Your goal is to intelligently group changed files and create well-formatted commits following the project's conventions.

## Phase 1: Analyze Repository State

Run these commands in parallel:
```bash
git status --porcelain
git diff --stat
git diff --cached --stat
git log -5 --oneline
```

From this, identify:
- Modified files (staged and unstaged)
- New files (untracked)
- Recent commit style/patterns

## Phase 2: Group Files Using AI Analysis

**Your task**: Analyze the changed files and their diffs to understand logical relationships. Group files that belong together in a single commit.

### CRITICAL: Analyze Actual Changes, Not Assumptions

**DO NOT**:
- Map changes to TODO items or completed tasks
- Assume what changed based on filenames
- Write commit messages based on what you think happened
- Group files just because they're in the same directory

**DO**:
- Read the actual diff for EVERY changed file: `git diff <file>`
- Understand the SCOPE and NATURE of changes (is it a small fix or a complete rewrite?)
- Look at line counts: 500+ lines changed often means major refactor/rewrite
- Read enough of the diff to understand what actually happened
- Base your commit message on what the diff shows, not what you assume

**Example mistake**: File `vifm/vifmrc` shows `+573 -237` lines changed → this is likely a major config rewrite, NOT just "add bat previewer". You MUST read the diff to understand the full scope.

### Grouping Heuristics

Use these patterns as guidance, but apply AI reasoning:

1. **Source directory grouping** - Files in the same source directory usually go together
2. **Related functionality** - Config + corresponding script (e.g., `.mate.yaml` + lifecycle script)
3. **Template + rendered** - Template file changes with their generated outputs
4. **Cross-cutting changes** - Theme/color updates that touch multiple sources
5. **New source additions** - New source directory + its `mate.yaml` registration
6. **Generated churn** - Auto-updated imports or lock files

### AI Analysis Process

For each changed file:
1. Read the diff to understand WHAT changed
2. Understand WHY it changed (new feature, bug fix, refactor, etc.)
3. Look for relationships with other changed files:
   - Do they implement the same feature?
   - Is one a dependency of the other?
   - Do they fix the same bug?
   - Are they part of the same refactor?

### Special Case Rules

**Cross-cutting changes**: If multiple source directories changed for ONE coherent reason (e.g., theme color update), group into ONE commit with scope `theme`.

**New source**: When adding a new source directory, group the directory + its `mate.yaml` registration into ONE commit: `feat(newsource): add newsource config`.

**Generated files**: Files with `#import` suffix that auto-sync should get their own `chore(<src>): sync <description>` commit, never mixed with real work.

## Phase 3: Present Groups for Review

For each group, show:

```
Group N: <Short description>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files:
  - path/to/file1
  - path/to/file2
  - path/to/file3

Reasoning:
<Explain WHY these files were grouped together. Be specific:
 - What feature/fix do they implement together?
 - What relationships exist between them?
 - Why do they belong in one commit vs. separate commits?>

Suggested commit:
<type>(<scope>): <subject>

[optional body explaining WHY]
```

**Then use AskUserQuestion** to prompt for action:

```javascript
AskUserQuestion({
  questions: [{
    question: "What would you like to do with this group?",
    header: "Action",
    multiSelect: false,
    options: [
      { label: "Commit", description: "Stage these files and create the commit" },
      { label: "Skip", description: "Skip this group and move to the next" },
      { label: "Chat", description: "Discuss or provide different instructions" },
      { label: "Quit", description: "Stop the commit workflow" }
    ]
  }]
})
```

**Important**: Your reasoning should be detailed enough that if the user disagrees, they understand your logic and can provide meaningful feedback.

## Phase 4: Handle User Actions

### Commit Action

1. Stage the exact files in the group (never `git add -A` or `git add .`)
2. Create commit message following format:
   ```
   type(scope): subject
   
   [optional body]
   
   Co-Authored-By: Claude Sonnet 4.5 (1M context) <noreply@anthropic.com>
   ```
3. Execute: `git commit -m "$(cat <<'EOF' ... EOF)"`
4. Confirm success
5. Move to next group

### Skip Action

- Add to skipped list
- Move to next group
- Show skipped groups in final summary

### Chat Action

When user selects "Chat":

1. The user will provide feedback, questions, or instructions in natural language
2. They might:
   - Ask questions about the grouping: "Why did you group these together?"
   - Provide different instructions: "Move tmux files to a separate commit"
   - Request splits: "Split into two commits: one for config, one for scripts"
   - Request modifications: "Remove vifmrc from this group" or "Add git/config to this group"
3. Respond to their input:
   - Answer questions about your reasoning
   - If they provide regrouping instructions, parse them and re-analyze
   - Show updated groups with the same format as Phase 3
   - Use AskUserQuestion again for the updated/current groups
4. Continue the conversation until they're ready to Commit/Skip/Quit

### Quit Action

- Show summary of committed and skipped groups
- Exit

## Commit Message Guidelines

### Format

```
type(scope): subject

Optional body explaining WHY (not WHAT)

Co-Authored-By: Claude Sonnet 4.5 (1M context) <noreply@anthropic.com>
```

### Types

- `feat`: New feature or functionality
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, whitespace (no code change)
- `refactor`: Code restructuring (no behavior change)
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `build`: Build system or external dependencies
- `ci`: CI configuration changes
- `chore`: Maintenance, generated files, other
- `pkg`: Package list changes in `.mate.yaml`

### Scope

- Source directory name: `tmux`, `nvim`, `git`, `work`, etc.
- `mate` for `mate.yaml` or `.mate/*` changes
- `theme` for cross-cutting theme/color changes
- No scope for root repo meta (`README.md`, `install.sh`)

### Subject

- Imperative mood: "add", "fix", "update" (NOT "adds", "fixed", "updating")
- Lowercase
- No trailing period
- Concise (≤50 chars ideal, ≤72 max)

### Body

- Use only when WHY is not obvious from subject
- Short bullet points
- Focus on motivation/reasoning, not what changed (the diff shows that)

### Examples

```
feat(nvim): add dashboard and tree split layout

fix(work): correct jpro status daemon script name

feat(theme): update color palette across all components
- Affects: kitty, tmux, nvim, waybar, rofi

chore(nvim): sync plugin lock file

pkg(git): add gitleaks for secret scanning
```

## Splitting Rules (from CLAUDE.md)

**Default**: One commit per source directory

**Exceptions**:
1. Cross-cutting changes (theme, etc.) → ONE commit
2. New source + mate.yaml → ONE commit
3. Generated/import files → SEPARATE commit

**Never** split arbitrarily just to have more commits. Each commit should be a logical, coherent change.

## Safety Checks

Before committing:
1. **Never commit secrets** - the pre-commit hook will catch this, but check yourself
2. **Never commit generated files with real work** - they get separate commits
3. **Never use broad staging** - always explicit paths
4. **Verify scope matches** - scope should be the actual source directory name

## Final Summary

After all groups processed, show:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Session Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Committed (N):
  - <hash> <message>
  - <hash> <message>

Skipped (N):
  - <files>

Done.
```

## Error Handling

- If `git commit` fails, show the error and ask how to proceed
- If pre-commit hook blocks, respect it (user can override with --no-verify if needed)
- If a file can't be staged, show error and skip that group
- If grouping results in 0 groups, report "No changes to commit"

## Notes

- You are analyzing changed files in the dotfiles repository only
- Work on the current branch (never switch branches)
- Never use `git commit -a` or `git add -A` or `git add .`
- Show your reasoning clearly so users can understand your grouping decisions
- Be ready to adapt based on user feedback in Edit Grouping
