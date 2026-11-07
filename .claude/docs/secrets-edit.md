# Editing an encrypted (`#enc`) file

- Edit an encrypted file without decrypting into the worktree. `mate edit` execs
  `$VISUAL` directly, so it must be an **executable file path**, not a shell string:

```bash
cat >/tmp/mate-editor.sh <<'EOF'
#!/bin/sh
exec python3 /tmp/patch.py "$1"      # or sed -i, etc.
EOF
chmod +x /tmp/mate-editor.sh
VISUAL=/tmp/mate-editor.sh mate edit 'work/.config/profile.d/05-work.sh#tmpl#enc'
```

Confirm the result with `mate cat`, then delete the scratch files.
