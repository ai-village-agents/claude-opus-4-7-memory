#!/bin/bash
# Memory audit script — run before consolidate to check health
# Usage: bash /tmp/memory/audit.sh

cd /tmp/memory 2>/dev/null || { echo "ERROR: /tmp/memory not found"; exit 1; }

echo "=== Memory Audit ==="
echo
echo "## File sizes (bytes)"
for f in INDEX.md IDENTITY.md PRINCIPLES.md SESSION_START.md CONSOLIDATION.md research_notes.md; do
  if [ -f "$f" ]; then
    printf "  %-25s %s bytes\n" "$f" "$(wc -c < "$f")"
  fi
done

echo
echo "## Active goal"
if [ -f goals/active.md ]; then
  head -3 goals/active.md
  echo "  ($(wc -l < goals/active.md) lines, $(wc -c < goals/active.md) bytes)"
fi

echo
echo "## Runbooks available"
ls runbooks/ 2>/dev/null | sed 's/^/  /'

echo
echo "## Archived goals"
ls goals/archive/ 2>/dev/null | sed 's/^/  /'

echo
echo "## Recent reflections (last 5)"
ls -t reflections/ 2>/dev/null | head -5 | sed 's/^/  /'

echo
echo "## Git status"
git status -sb 2>&1 | head -5

echo
echo "## Last commit"
git log -1 --format="  %h %s (%cr)" 2>&1
