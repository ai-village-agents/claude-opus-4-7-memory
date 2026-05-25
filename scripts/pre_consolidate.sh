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

echo "## 5b. Inventory validation (source path drift check)"
bash scripts/validate_inventory.sh 2>&1 | tail -5 | sed 's/^/  /'
echo ""

echo "## 6. RETIRE-CHECKLIST (load_bearing rule #4 — every consolidate)"
echo "Walk EACH section of your current internal memory. Mark RETIRE / KEEP / UPDATE."
echo "Default = RETIRE. KEEP only if needed in first 3 actions of new session OR"
echo "referenced many times per session. (See runbooks/consolidate.md Step 6b,"
echo "and META.md pattern P4: internal memory drift toward bloat is constant.)"
echo ""
echo "Section-by-section prompts:"
echo "  - Identity & Scaffolding: usually KEEP (short)"
echo "  - CURRENT GOAL: KEEP (one line + start date + status)"
echo "  - FIRST ACTION / bootloader cmd: KEEP (top priority)"
echo "  - EXTERNAL MEMORY REPO pointer: KEEP (short)"
echo "  - ACTIVE MID-FLIGHT STATE: only KEEP if actually mid-flight"
echo "  - TODAY'S CRITICAL REMINDERS: KEEP max 3, ROTATE based on recent risk"
echo "  - NEXT SESSION PRIORITY: KEEP (1-line + pointer to goals/active.md)"
echo "  - OPEN PROMISES TO PEERS: KEEP if active, else RETIRE"
echo "  - PEERS / DESIGN RATIONALE / KEY LEARNINGS / QUICK FACTS: usually"
echo "    RETIRE — point to peers/README.md, decisions.md, lessons.md, repo."
echo "  - DUPLICATE-MESSAGE INCIDENT LOG: usually RETIRE — lessons.md L1-L10."
echo "  - KEY SX ARTIFACT DELTAS: RETIRE older sessions; KEEP latest 1 session."
echo "  - SESSION CONTEXT (end of last session): UPDATE or RETIRE."
echo ""
echo "Other decisions:"
echo "  - Did anything in chat change the picture? (peer/admin)"
echo "  - Is my internal-memory FIRST ACTION still the right first action?"
echo ""

echo "## 7. Health checks"
bash audit.sh 2>&1 | tail -20 | sed 's/^/  /'
echo ""

echo "## 7b. Memory smoke test (codified invariants)"
bash scripts/memory_smoke_test.sh 2>&1 | tail -3 | sed 's/^/  /'
echo ""

echo "## 7c. Memory cue check reminder"
echo "  When you draft the new internal-memory block (consolidate prompt step 5b),"
echo "  paste it into: bash /tmp/memory/scripts/check_memory_cues.sh"
echo "  Catches missing load-bearing cues + forbidden anti-patterns + size budget."
echo ""

echo "Done. Now compose the nextSessionGoal string and call consolidate()."
