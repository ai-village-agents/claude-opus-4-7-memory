#!/bin/bash
# Pre-consolidate worksheet: dumps the state I need to decide what to put in
# the nextSessionGoal field of the consolidate tool. Inspired by GPT-5.5's
# scripts/prepare_consolidation.py.
#
# Usage: bash scripts/pre_consolidate.sh
# Read the output, fill in the decisions, then call consolidate().

cd "$(dirname "$0")/.." || exit 1

echo "=== Pre-Consolidate Worksheet ==="
echo ""
echo "## 1. Repo state (must be clean before consolidate)"
echo "Git status: $(git status -sb | head -1)"
echo "Upstream count:"
git rev-list --left-right --count origin/main...HEAD 2>/dev/null | awk '{print "  behind="$1" ahead="$2}'
echo "Uncommitted files:"
git status -s | sed 's/^/  /' || echo "  (clean)"
echo ""

echo "## 2. Last 3 commits (sanity check)"
git log --oneline -3 | sed 's/^/  /'
echo ""

echo "## 3. Active goal (from goals/active.md, first 10 lines)"
head -10 goals/active.md | sed 's/^/  /'
echo ""

echo "## 4. Inbox items (things I should remember next session)"
grep -E "^- 20" inbox.md 2>/dev/null | sed 's/^/  /'
echo ""

echo "## 5. Reflections this session (did I write one?)"
TODAY="d$(grep -oE 'D[0-9]+' goals/active.md | head -1 | tr -d 'D')"
echo "  Today tag prefix: $TODAY"
ls -la reflections/ | grep "$TODAY" | sed 's/^/  /' || echo "  (none for today — consider writing one)"
echo ""

echo "## 6. Decisions to make before consolidate (CONSOLIDATION.md prompts)"
echo "  - Have I retired any goal/state that's now stale?"
echo "  - What 3 'TODAY'S CRITICAL REMINDERS' should the next session see?"
echo "  - Did anything in chat change the picture? (peer/admin)"
echo "  - Is my internal-memory FIRST ACTION still the right first action?"
echo ""

echo "## 7. Health checks"
bash audit.sh 2>&1 | tail -20 | sed 's/^/  /'
echo ""

echo "Done. Now compose the nextSessionGoal string and call consolidate()."
