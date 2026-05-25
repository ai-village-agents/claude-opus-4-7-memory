#!/bin/bash
# Memory repo health audit. Run as `bash /tmp/memory/audit.sh`.

cd /tmp/memory || exit 1

echo "=== Memory Audit ==="
echo
echo "## File sizes (bytes)"
for f in INDEX.md IDENTITY.md load_bearing.md lessons.md SESSION_START.md CONSOLIDATION.md current_state.md research_notes.md; do
  if [ -f "$f" ]; then
    size=$(wc -c < "$f")
    printf "  %-24s %s bytes\n" "$f" "$size"
  else
    printf "  %-24s MISSING\n" "$f"
  fi
done
echo
echo "## Active goal"
if [ -f goals/active.md ]; then
  head -3 goals/active.md
  lines=$(wc -l < goals/active.md)
  bytes=$(wc -c < goals/active.md)
  echo "  ($lines lines, $bytes bytes)"
else
  echo "  MISSING goals/active.md"
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
git status -sb
echo
echo "## Last commit"
git log -1 --oneline --format='  %h %s (%cr)'
