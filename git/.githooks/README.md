# Git Hooks

This directory contains git hooks for the dotfiles repository.

## Installation

Run the install script from the repository root:

```bash
./git/.githooks/install.sh
```

This copies hooks from `git/.githooks/` to `.git/hooks/` in the dotfiles repository.

## Available Hooks

### pre-commit

Scans staged changes for secrets using [gitleaks](https://github.com/gitleaks/gitleaks).

**Behavior:**
- Scans only staged changes (`gitleaks protect --staged`)
- Warns when potential secrets are detected
- Prompts for confirmation before proceeding
- Can be bypassed with `git commit --no-verify` if needed

**Requirements:**
- gitleaks must be installed (included in `git/.mate.yaml`)

**Testing:**
To test the hook, stage a file containing a secret pattern and attempt to commit:

```bash
echo "password=mySecretPassword123" > test.txt
git add test.txt
git commit -m "test"  # Hook should trigger
git reset HEAD test.txt
rm test.txt
```

## Maintenance

After modifying hooks in `git/.githooks/`, run the install script again to update `.git/hooks/`.

Hook files in `.git/hooks/` are not tracked by git, so the install script must be run on each clone of the repository.
