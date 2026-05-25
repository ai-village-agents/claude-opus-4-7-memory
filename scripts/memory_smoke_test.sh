#!/bin/bash
# memory_smoke_test.sh — codifies "is my memory system healthy?"
# Inspired by GPT-5.5's scripts/memory_smoke_test.py.
# Runs a series of invariants and exits non-zero on any failure.
# Usage: bash scripts/memory_smoke_test.sh
#
# Run periodically (every few sessions, before consolidate) to catch drift.

set -u
cd "$(dirname "$0")/.." || exit 2

PASS=0
FAIL=0
WARN=0

check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✅ $name"
    PASS=$((PASS+1))
  else
    echo "  ❌ $name"
    FAIL=$((FAIL+1))
  fi
}

warn_check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✅ $name"
    PASS=$((PASS+1))
  else
    echo "  ⚠️  $name"
    WARN=$((WARN+1))
  fi
}

echo "=== Memory Smoke Test ==="
echo ""
echo "## Core files exist"
for f in INDEX.md IDENTITY.md SESSION_START.md CONSOLIDATION.md \
         load_bearing.md lessons.md decisions.md current_state.md \
         inventory.yaml inbox.md memory_changelog.md daily_log.md \
         skills.md research_notes.md \
         goals/active.md goals/INDEX.md \
         peers/README.md \
         reflections/META.md; do
  check "$f exists" test -f "$f"
done

echo ""
echo "## Scripts present and executable-readable"
for s in boot.sh audit.sh; do
  check "$s exists at repo root" test -f "$s"
done
for s in pre_send_chat.sh pre_consolidate.sh validate_inventory.sh \
         query_inventory.sh search_memory.sh memory_smoke_test.sh \
         check_peers.sh check_memory_cues.sh; do
  check "scripts/$s exists" test -f "scripts/$s"
done

echo ""
echo "## Runbooks present (action-verb triggered procedures)"
for r in send_chat_message.md consolidate.md peer_feedback.md \
         respond_to_admin.md search_history.md \
         bash_safety.md use_computer_safety.md; do
  check "runbooks/$r exists" test -f "runbooks/$r"
done

echo ""
echo "## Inventory validation"
check "validate_inventory.sh exits 0" bash scripts/validate_inventory.sh
INV_COUNT=$(grep -c "^  - id:" inventory.yaml 2>/dev/null || echo 0)
echo "  ℹ️  inventory item count: $INV_COUNT"

echo ""
echo "## Git state"
check "git repo clean (no uncommitted changes)" bash -c '[ -z "$(git status --porcelain)" ]'
warn_check "branch is main" bash -c '[ "$(git branch --show-current)" = "main" ]'
warn_check "in sync with origin/main" bash -c 'git fetch origin main 2>/dev/null; [ "$(git rev-list --count main..origin/main 2>/dev/null)" = "0" ] && [ "$(git rev-list --count origin/main..main 2>/dev/null)" = "0" ]'

echo ""
echo "## Boot.sh smoke (output contains expected sections)"
BOOT_OUT=$(bash boot.sh 2>&1 || true)
check "boot.sh prints ACTIVE GOAL section" bash -c "echo \"\$1\" | grep -q 'ACTIVE GOAL'" _ "$BOOT_OUT"
check "boot.sh prints CURRENT STATE section" bash -c "echo \"\$1\" | grep -q 'CURRENT STATE'" _ "$BOOT_OUT"
check "boot.sh prints LOAD-BEARING RULES section" bash -c "echo \"\$1\" | grep -q 'LOAD-BEARING RULES'" _ "$BOOT_OUT"
check "boot.sh prints DAILY LOG section" bash -c "echo \"\$1\" | grep -q 'DAILY LOG'" _ "$BOOT_OUT"
check "boot.sh prints AUDIT section" bash -c "echo \"\$1\" | grep -q 'AUDIT'" _ "$BOOT_OUT"

echo ""
echo "## Lessons.md has expected L1..L10+ entries"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do
  check "lessons.md has L$n" grep -qE "^## (L$n[^0-9]|$n\.)" lessons.md
done

echo ""
echo "## Load-bearing rules 0..7 present"
for n in 0 1 2 3 4 5 6 7; do
  check "load_bearing rule $n" grep -q "^## $n\." load_bearing.md
done

echo ""
echo "## Cue checker self-tests"
check "check_memory_cues.sh: minimal valid draft passes" bash -c '
cat << EOF | bash scripts/check_memory_cues.sh > /dev/null
Improve your memory
claude-opus-4-7-memory
/tmp/memory/boot.sh
#best
pre_send_chat.sh
AGENT_TALK
stale-PASS
structural
Shoshannah
runbooks/respond_to_admin
validate_inventory
EOF'
check "check_memory_cues.sh: empty draft fails" bash -c '! (echo "" | bash scripts/check_memory_cues.sh > /dev/null 2>&1)'

echo ""
echo "=== Summary ==="
echo "  PASS: $PASS    FAIL: $FAIL    WARN: $WARN"
if [ "$FAIL" -gt 0 ]; then
  echo "  STATUS: FAIL ❌"
  exit 1
fi
echo "  STATUS: healthy ✅"
exit 0

# === Retrieval Self-Test (D419 s11) ===
test_start "retrieval_self_test.sh: all 23 retrieval tests pass"
if bash scripts/retrieval_self_test.sh > /tmp/rst.out 2>&1; then
  pass=$(grep -c '^PASS:' /tmp/rst.out || true)
  if [ "$pass" -ge 23 ]; then test_pass; else test_fail "only $pass passes (expected ≥23)"; fi
else
  test_fail "retrieval_self_test.sh exited non-zero"
fi

test_start "validate_inventory.sh catches missing per-item status field"
cp inventory.yaml /tmp/inv_smoke.yaml
python3 -c "import yaml; d=yaml.safe_load(open('inventory.yaml')); d['items'][0].pop('status',None); yaml.dump(d,open('inventory.yaml','w'),sort_keys=False,width=100)"
if bash scripts/validate_inventory.sh >/tmp/vinv.out 2>&1; then
  cp /tmp/inv_smoke.yaml inventory.yaml
  test_fail "validate_inventory.sh PASSED on missing status (should have failed)"
else
  if grep -q "ITEM FAIL" /tmp/vinv.out; then
    cp /tmp/inv_smoke.yaml inventory.yaml
    test_pass
  else
    cp /tmp/inv_smoke.yaml inventory.yaml
    test_fail "validate_inventory.sh failed but no ITEM FAIL line"
  fi
fi
