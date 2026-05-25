#!/usr/bin/env bash
# memory_metrics.sh — compact health snapshot of the Opus 4.7 memory repo.
# Exits non-zero only if a required guard script is missing.
# Use as a quick health probe at session start, before consolidate, or when
# diagnosing memory drift. Inspired by GPT-5.5's memory_metrics.py.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

echo "## git"
git_head=$(git log -1 --oneline 2>/dev/null || echo "(no commits)")
echo "  HEAD: $git_head"
if git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
  ab=$(git rev-list --left-right --count @{u}...HEAD 2>/dev/null || echo "?\t?")
  echo "  upstream behind/ahead: $ab"
else
  echo "  upstream: (none)"
fi
dirty=$(git status -s | wc -l | trim)
echo "  dirty_files: $dirty"
echo

echo "## active goal"
if [ -f goals/active.md ]; then
  head -1 goals/active.md | sed 's/^/  /'
else
  echo "  (no goals/active.md)"
fi
echo

echo "## inventory"
inv="inventory.yaml"
if [ -f "$inv" ]; then
  # Count items: top-level "- id:" lines that appear under items:
  total=$(grep -cE '^\s*-\s+id:' "$inv")
  echo "  total_items: $total"
  # Status distribution
  echo "  status_distribution:"
  grep -E '^\s+status:' "$inv" | sed 's/.*status:[[:space:]]*//' | sort | uniq -c | sort -rn | \
    awk '{printf "    %-20s %s\n", $2, $1}'
  echo "  kind_distribution:"
  grep -E '^\s+kind:' "$inv" | sed 's/.*kind:[[:space:]]*//' | sort | uniq -c | sort -rn | \
    awk '{printf "    %-20s %s\n", $2, $1}'
  pol_total=$(grep -cE '^\s+internal_memory_policy:' "$inv")
  if [ "$pol_total" -gt 0 ]; then
    echo "  policy_distribution:"
    grep -E '^\s+internal_memory_policy:' "$inv" | sed 's/.*internal_memory_policy:[[:space:]]*//' | sort | uniq -c | sort -rn | \
      awk '{printf "    %-20s %s\n", $2, $1}'
  fi
else
  echo "  (no inventory.yaml)"
fi
echo

echo "## scripts (required guards)"
missing=0
for s in \
  boot.sh \
  audit.sh \
  scripts/pre_send_chat.sh \
  scripts/pre_consolidate.sh \
  scripts/validate_inventory.sh \
  scripts/query_inventory.sh \
  scripts/search_memory.sh \
  scripts/memory_smoke_test.sh \
  scripts/check_peers.sh \
  scripts/check_memory_cues.sh \
  scripts/retrieval_self_test.sh \
  scripts/goal_transition.py \
  scripts/memory_metrics.sh
do
  if [ -f "$s" ]; then echo "  OK      $s"
  else echo "  MISSING $s"; missing=$((missing+1)); fi
done
echo

echo "## lessons"
if [ -f lessons.md ]; then
  max_l=$(grep -oE '^## L[0-9]+' lessons.md | grep -oE '[0-9]+' | sort -n | tail -1)
  count_l=$(grep -cE '^## L[0-9]+' lessons.md)
  echo "  count: $count_l  max: L${max_l:-?}"
else
  echo "  (no lessons.md)"
fi
echo

echo "## meta patterns"
if [ -f reflections/META.md ]; then
  max_p=$(grep -oE '^## P[0-9]+' reflections/META.md | grep -oE '[0-9]+' | sort -n | tail -1)
  count_p=$(grep -cE '^## P[0-9]+' reflections/META.md)
  echo "  count: $count_p  max: P${max_p:-?}"
else
  echo "  (no reflections/META.md)"
fi
echo

echo "## runbooks"
if [ -d runbooks ]; then
  ls runbooks/ | sed 's/^/  /'
else
  echo "  (no runbooks/)"
fi
echo

echo "## daily log"
if [ -f daily_log.md ]; then
  sess=$(grep -cE '^- D' daily_log.md)
  echo "  session_entries: $sess"
  last=$(grep -E '^- D' daily_log.md | tail -1)
  echo "  last_entry: $last"
else
  echo "  (no daily_log.md)"
fi
echo

echo "## file sizes (bytes)"
for f in load_bearing.md lessons.md reflections/META.md goals/active.md inventory.yaml current_state.md daily_log.md; do
  if [ -f "$f" ]; then
    sz=$(wc -c < "$f" | trim)
    printf "  %-30s %s\n" "$f" "$sz"
  else
    printf "  %-30s MISSING\n" "$f"
  fi
done
echo

echo "## retrieval affordances"
echo "  index_files: INDEX.md, goals/INDEX.md"
echo "  query_tools: scripts/query_inventory.sh, scripts/search_memory.sh"
if [ -f scripts/retrieval_self_test.sh ]; then
  cases=$(grep -cE '^\s*CASE\b|^\s*# CASE\b|^\s*case\(\)|expect ' scripts/retrieval_self_test.sh 2>/dev/null)
  # safer: count lines matching "EXPECT" or quoted "expected"
  cases2=$(grep -cE "^run_test " scripts/retrieval_self_test.sh 2>/dev/null)
  echo "  retrieval_self_test_cases: ${cases2:-?}"
fi
echo "  smoke_tests_script: scripts/memory_smoke_test.sh"

if [ "$missing" -gt 0 ]; then
  echo
  echo "FAIL: $missing guard script(s) missing."
  exit 1
fi
exit 0
