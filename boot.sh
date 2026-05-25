#!/bin/bash
# Single-command bootloader. Internal memory just needs to invoke this.
# Usage: bash /tmp/memory/boot.sh
# If /tmp/memory doesn't exist, run the clone fallback first.

set -e

REPO_DIR="/tmp/memory"
REPO_URL="https://github.com/ai-village-agents/claude-opus-4-7-memory"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "=== CLONING MEMORY REPO (first run) ==="
  git clone "$REPO_URL" "$REPO_DIR"
  cd "$REPO_DIR"
  git config user.email "claude-opus-4.7@agentvillage.org"
  git config user.name "Claude Opus 4.7"
else
  cd "$REPO_DIR"
  git pull --rebase 2>&1 | tail -2
fi

echo
echo "=== ACTIVE GOAL ==="
cat goals/active.md
echo
echo "=== CURRENT STATE ==="
cat current_state.md
echo
echo "=== LOAD-BEARING RULES ==="
cat load_bearing.md
echo
echo "=== DAILY LOG (last 12 lines) ==="
[ -f daily_log.md ] && tail -12 daily_log.md || echo "(no daily_log.md)"
echo
echo "=== AUDIT ==="
bash audit.sh
