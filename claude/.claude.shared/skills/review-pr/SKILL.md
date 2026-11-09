---
name: review-pr
description: Review someone else's GitHub pull request end to end as a collaborator, from checkout to a posted verdict. Use for "review PR 123", "what's in my review queue", or deciding whether to approve a PR.
---

# Review a PR

You review as a **collaborator**: your approval counts toward merge, so it is a
claim you checked the change, not a skim. The repo is the source of truth for
what a review covers; this skill is the route through it.

The review runs in a **review session** of its own, in an agent-manager
worktree, so deleting the session removes the checkout too. Steps 1–2 pick the
PR and its mode and hand off; the review session does the rest. When the
arguments carry `--here`, you are the review session: skip to step 3 in the
worktree you were started in, in the mode the arguments name.

Two modes:

- **Build** (`--build`): build the app for the user to run by hand in a
  sandbox, then stop. CI and the review bots cover tests and lint.
- **Full** (`--full`): steps 3–10, with the local test suite and a written
  review.

## 1. Pick the PR

Given a number or URL, use it. Otherwise list the queue and ask with
`AskUserQuestion` which one to take:

```sh
gh pr list --search "review-requested:@me"
gh pr list --search "-author:@me -is:draft review:none"
```

Unless the arguments name a mode, ask with `AskUserQuestion`: **Build only
(Recommended)** or **Full review**.

## 2. Hand off

Spawn the review session in agent-manager, filed under a `review` subgroup:

1. `list_groups`. The parent is the group whose directory is the repo's main
   checkout; when none matches, this session's own group.
2. Create `<parent>/review` with `create_group` if it is missing, with the
   main checkout as its directory.
3. `list_sessions`. A `review-pr-<N>` session that still exists owns the
   PR's worktree: hand it the new run with `send_session` instead of
   spawning, since a second spawn collides on the worktree path.
4. Otherwise `create_session` with `group: <parent>/review`,
   `name: review-pr-<N>`, `directory` set to the main checkout,
   `worktree: true` (agent-manager creates and owns the `am/review-pr-<N>`
   worktree), and `prompt: /review-pr <N> --here --build` (or `--full`).
   Size the session to the mode with `model` and `effort`:
   - **build**: `model: sonnet`, `effort: low`. It builds and explains,
     nothing to judge.
   - **full**: `model: opus`, `effort: high`. Its approval rests on the
     judgement.

   A name the CLI refuses comes back with the ones it lists: pick the
   matching one from that list and retry.

Tell the user the session's name and stop here: the review and its
conversation belong to that session.

Without the agent-manager MCP tools, check the PR out with
`wt switch pr:<N> --no-cd`, then continue in that worktree from step 4.

## 3. Check out the PR

Point the worktree's branch at the PR head. The PR is fetched into a
remote-tracking ref so its commits count as saved: agent-manager's delete
removes a worktree only when every commit in it exists on a remote, and a
fork PR's commits are on no branch of `origin`.

```sh
git fetch origin +pull/<N>/head:refs/remotes/origin/pr/<N>
git reset --hard origin/pr/<N>
```

## 4. Build the app

Build the PR's binary into a sandbox directory outside the worktree,
`/tmp/review-pr-<N>` (anything left in the worktree keeps it from being
removed, and a socket path under the worktree runs past the 104-character
limit), and give the user the command that runs it there,
following the repo's own recipe for running a built binary in isolation (in
agent-manager: Capturing a TUI frame in `CONTRIBUTING.md`, a throwaway `HOME`
and a short `TMUX_TMPDIR`, minus the outer tmux the user does not need):

```sh
go build -o /tmp/review-pr-<N>/agent-manager .
mkdir -p /tmp/review-pr-<N>/home /tmp/review-pr-<N>/sock
env -u TMUX HOME=/tmp/review-pr-<N>/home TMUX_TMPDIR=/tmp/review-pr-<N>/sock /tmp/review-pr-<N>/agent-manager
```

A throwaway `HOME` has no CLI logins, so an agent CLI there asks to sign in.

### Test plan

End with a short test plan for the user, built from the PR body (its own test
steps first), the linked issue, and the diff:

- **What changed**: one or two sentences, the behaviour the user will see.
- **Steps**: three to six numbered steps, each one action in the sandbox and
  the result that shows the change works, as `<keys or click>: <what you
  see>`.
- **Regression check**: one step on the nearest behaviour the diff touches
  that should stay as it was.

Name the exact keys, clicks, and commands; a step the user has to work out is
not a step. Where the repo requires both keyboard and mouse, cover both.

In **build** mode, stop here: the user runs and judges the change.

## 5. Read the context

```sh
gh pr view <N> --json title,body,author,files,reviews,reviewDecision,statusCheckRollup,closingIssuesReferences
gh pr view <N> --comments
```

- Read the linked issue: it is the **spec** the change answers.
- Read the repo's review rules in full: `REVIEW.md`, `AGENTS.md` (or
  `CLAUDE.md`), the review section of `CONTRIBUTING.md`, and `CODEOWNERS`.
- Stop and tell the user when the author is you (`gh api user -q .login`):
  nobody approves their own PR.
- Note unanswered bot findings (CodeRabbit and the like). Where the repo says
  human review waits for them, say so and ask whether to continue.

## 6. Run it

Run the full check set the repo's agent docs name (format, vet, the test
command with its environment), from the worktree. A check you skipped is
reported as skipped.

## 7. Review it

Invoke the `code-review` skill from the worktree with the merge base against
`origin/<base branch>` as the fixed point, and the linked issue as the spec.

Then apply **every** rule in the repo's review policy to the diff and give each
one a verdict: met, missed (with file and line), or not applicable. Read every
changed file, not only the hunks. Done means every rule has a verdict and every
changed file has been read.

## 8. Draft the verdict

Draft the review for the user, without posting:

- **Event**: approve, comment, or request changes, with the reason.
- **Summary**: what you checked and ran, what you skipped.
- **Inline comments**: file, line, comment. One finding per comment, phrased
  as what to change and why.

Approval rules:

- A PR touching a path `CODEOWNERS` reserves for the maintainer gets a comment,
  with the approval left to them.
- A change that breaks behaviour or shifts the project's direction needs the
  maintainer's agreement before approval; tag them in the summary.
- The review text carries only what is in the repo: no local paths, hostnames,
  other projects, or employer details.

## 9. Post it

Post only after the user approves the draft.

```sh
gh pr review <N> --approve|--comment|--request-changes --body-file <file>
```

Inline comments go in one review through the API:

```sh
gh api repos/{owner}/{repo}/pulls/<N>/reviews --input review.json
# {"event":"COMMENT","body":"...","comments":[{"path":"a.go","line":12,"side":"RIGHT","body":"..."}]}
```

## 10. Clean up

When the user is done with the PR:

1. Stop the sandbox app if it still runs, naming its socket so the user's own
   server is untouched:
   `tmux -S /tmp/review-pr-<N>/sock/tmux-$(id -u)/agentmgr kill-server`.
2. `rm -rf /tmp/review-pr-<N>`.
3. The user deletes the `review-pr-<N>` session in agent-manager (`d`), which
   removes the worktree and its `am/` branch. A "worktree kept" notice means
   something in it is uncommitted or unpushed: show `git status` there and let
   the user decide.

A push to the PR after your review needs a fresh one: rerun step 3, then
review `<old head>..HEAD`.
