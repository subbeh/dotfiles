#!/bin/sh

# Personal accounts share this dir; claude-swap switches them: `cswap add` once per account, then `cswap switch`
export CLAUDE_CONFIG_DIR="$HOME/.claude.personal"
export CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1
