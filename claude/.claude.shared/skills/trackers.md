# Trackers

How `/tasks-handover`, `/tasks-takeover` and `/tasks-pickup` find a repo's task tracker and run
each operation on it.

## Finding the tracker

A ref names its tracker by shape: `DTF-WN8C` is aven, `ABC-123` is Jira, `#123`
is GitHub. Without a ref, use the first that matches:

- **aven**: `aven list` prints a `scope: project <name>` line.
- **Jira**: the branch name or recent commit subjects carry a Jira key.
- **GitHub**: `gh repo view` succeeds and the repo has issues enabled.

When none matches, ask the user where the task lives.

## aven

- **In progress**: `aven list --status active --json`
- **Open**: `aven list --ready --json`, leaving out `active` tasks
- **Read**: `aven context <ref>`, then its `read=` command when it leaves out
  earlier notes
- **Note**: `aven note <ref> --stdin`
- **Start**: `aven edit <ref> --status active`
- **Create**: `aven add`

## Jira

Use whatever Jira access the session has (Atlassian MCP tools, a CLI). Only
tasks assigned to the user count: every query adds
`assignee = currentUser() AND project = <the key's project>`, and a key in the
branch name counts only when its task is assigned to the user.

- **In progress**: `statusCategory = "In Progress"`
- **Open**: `statusCategory = "To Do"`
- **Read**: the description and every comment
- **Note**: a comment
- **Start**: ask first, since others see it, then transition to In Progress
- **Create**: in the key's project, assigned to the user

## GitHub

Only issues assigned to the user count, and GitHub has no started state:
**in progress** and **open** are the same list, and **start** has nothing to
mark.

- **In progress**, **open**: `gh issue list --assignee @me --json number,title,labels,updatedAt`
- **Read**: `gh issue view <n> --comments`
- **Note**: `gh issue comment <n> --body-file -`
- **Create**: `gh issue create --assignee @me`
