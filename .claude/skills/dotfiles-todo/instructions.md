# Dotfiles TODO Skill - Implementation Instructions

You are executing the dotfiles TODO management skill. Manage TODO.md comprehensively: add, complete, expand, and organize items.

## File Location

`/Users/Shared/data/workspace/dotfiles/TODO.md`

Always read the current state before making changes.

## Operations

### 1. Add TODO Item

**When**: User says "add TODO", "add to TODO", "create TODO for..."

**Process**:
1. Read TODO.md
2. Determine section (FIX/FEAT/BACKLOG) based on nature:
   - Bug/broken/fix → FIX
   - New feature/enhancement → FEAT
   - Low priority/future/idea → BACKLOG
3. Add item in the format: `- [ ] description`
4. Insert at the end of the appropriate section
5. Write the updated file
6. Confirm to user

**Example**:
```
User: add a TODO to fix clipboard in vifm on macOS

You:
1. Read TODO.md
2. Determine: FIX section (it's a bug/broken functionality)
3. Add: `- [ ] vifm: clipboard yank not working on macOS`
4. Write updated file
5. Say: "Added to FIX: vifm clipboard issue on macOS"
```

### 2. Check Off / Complete Item

**When**: User says "check off", "mark complete", "done with the X todo"

**Process**:
1. Read TODO.md
2. Find the matching item(s)
3. Change `[ ]` to `[x]`
4. Write the updated file
5. Confirm to user

**Matching**: Be flexible - match on keywords, not exact text. If ambiguous, show options.

**Example**:
```
User: check off the nvim dashboard todo

You:
1. Read TODO.md
2. Find: "- [ ] nvim: show snacks dashboard..."
3. Change to: "- [x] nvim: show snacks dashboard..."
4. Write
5. Say: "Marked complete: nvim dashboard todo"
```

### 3. Interview and Spec Item

**When**: User asks "what does X todo mean", "clarify the X todo", or you encounter a vague item

**Process**:
1. Read TODO.md
2. Identify the vague item
3. Ask clarifying questions (use AskUserQuestion if needed for structured input)
4. Gather requirements:
   - Problem: What's broken / what's needed?
   - Current behavior vs desired behavior
   - Solution approach
   - Technical details
   - Acceptance criteria
5. Expand the item inline:

```markdown
- [ ] original vague description
  - **Problem:** Clear statement of what's wrong/needed
  - **Current Behavior:** What happens now
  - **Desired Behavior:** What should happen
  - **Solution:** Proposed approach
  - **Details:**
    - Technical detail 1
    - Technical detail 2
    - Implementation notes
  - **Acceptance:**
    - [ ] Testable criterion 1
    - [ ] Testable criterion 2
```

6. Write the updated file
7. Confirm to user

**Important**: Keep the original description on the checkbox line. Add details as indented sub-items.

**Example**:
```
User: what does the "hypr monitor reload" todo mean?

You:
1. Read TODO.md, find: "- [ ] hypr: monitor reloading with hypr reload"
2. Ask questions about what's broken, desired behavior
3. Expand inline:
   - [ ] hypr: monitor reloading with hypr reload
     - **Problem:** Running `hypr reload` doesn't properly reload monitor configuration
     - **Current Behavior:** Monitors stay in old layout after reload
     - **Desired Behavior:** `hypr reload` should re-apply monitor layout from config
     - **Solution:** Check if hyprland needs a full restart or different reload command
     - **Acceptance:**
       - [ ] `hypr reload` reapplies monitor layout
       - [ ] No manual restart needed
4. Write
5. Confirm
```

### 4. Organize / Prioritize

**When**: User says "organize TODO", "prioritize", "reorder"

**Process**:
1. Read TODO.md
2. Analyze all open items
3. Suggest ordering based on:
   - Dependencies (A blocks B → A first)
   - Difficulty (quick wins vs complex)
   - Impact (high value first)
   - User priority (if stated)
4. Show proposed new order
5. Get user confirmation
6. Reorder items within each section
7. Write updated file

**Rules**:
- Keep section structure (FIX/FEAT/BACKLOG)
- Only reorder within sections
- Keep completed `[x]` items at their current position (don't reorder them)

**Example**:
```
User: organize my FIX items by priority

You:
1. Read TODO.md FIX section
2. Analyze items
3. Show:
   Proposed order:
   1. Item A (blocking other work)
   2. Item B (quick fix, high impact)
   3. Item C (complex, lower priority)
   
   Proceed? [y/N]
4. If yes, reorder and write
5. Confirm
```

## Context Detection

When user just says "todo" or "/todo" with no specific action, show a menu:

```
TODO Management Options:
1. Add new item
2. Check off completed item
3. Interview/clarify a vague item
4. Organize/prioritize items
5. Show current TODO list

What would you like to do?
```

Or, be smart about it:
- If they paste a description → add it
- If they mention an existing TODO → check it off or clarify it
- If they're asking about priority/order → organize

## File Format Rules

### Structure

```markdown
# FIX

- [ ] item 1
- [x] completed item
- [ ] item with details
  - **Problem:** ...
  - **Solution:** ...

# FEAT

- [ ] feature 1

# BACKLOG

- [ ] future item
```

### Preservation Rules

1. **Keep headers**: `# FIX`, `# FEAT`, `# BACKLOG` must remain
2. **Keep completed items**: Never delete `[x]` items
3. **Maintain indentation**: Sub-items are 2-space indented
4. **Preserve blank lines**: One blank line between sections

### Validation

After writing TODO.md:
1. Verify markdown is valid
2. Verify all section headers exist
3. Verify checkbox format `- [ ]` or `- [x]`

## Edge Cases

**Item not found**: "I couldn't find a TODO matching 'X'. Did you mean: [similar items]?"

**Ambiguous match**: Show options: "Multiple TODOs match 'X': 1) ... 2) ... Which one?"

**Empty section**: It's fine to have empty sections

**Duplicate items**: Check before adding; if duplicate exists, ask user if they want to add anyway

## Communication

- Be concise in confirmations
- Show what changed: "Added to FIX: item description"
- For multi-step operations (interview), guide the user through it
- If you made a mistake, admit it and fix it

## Examples of Full Operations

### Add Item
```
User: add TODO to set up qwen model

Read TODO.md
→ It's a FEAT (new feature/setup)
→ Add to FEAT section: `- [ ] set up qwen3.8-27b`
→ Write file
→ Say: "Added to FEAT: set up qwen3.8-27b"
```

### Check Off
```
User: done with the fzf multi-select

Read TODO.md
→ Find: "- [ ] fzf: multi-select tab..."
→ Change to: "- [x] fzf: multi-select tab..."
→ Write file
→ Say: "Marked complete: fzf multi-select"
```

### Interview (we actually did this earlier in the session)
```
User: let's clarify the vague TODOs

Read TODO.md
→ Identify vague items
→ For each, ask questions using AskUserQuestion
→ Expand inline with Problem/Solution/Details/Acceptance
→ Write file
→ Say: "Expanded N items with detailed specs"
```

## Integration Notes

- This skill works with TODO.md only
- It does NOT interact with task management tools (those are separate)
- It does NOT create separate spec files (everything inline in TODO.md)
- It's designed for the dotfiles repository TODO list specifically
