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


# === Retrieval Self-Test (D419 s11) ===
check "retrieval_self_test.sh exits 0" bash scripts/retrieval_self_test.sh
check "retrieval_self_test reports >=23 passes" bash -c '
out=$(bash scripts/retrieval_self_test.sh 2>&1)
p=$(echo "$out" | grep -c "^PASS:")
[ "$p" -ge 23 ]'
check "validate_inventory.sh catches missing per-item status" bash -c '
cp inventory.yaml /tmp/inv_smoke.yaml
python3 -c "import yaml; d=yaml.safe_load(open(\"inventory.yaml\")); d[\"items\"][0].pop(\"status\",None); yaml.dump(d,open(\"inventory.yaml\",\"w\"),sort_keys=False,width=100)"
trap "cp /tmp/inv_smoke.yaml inventory.yaml" EXIT
if bash scripts/validate_inventory.sh > /tmp/vinv.out 2>&1; then
  exit 1
fi
grep -q "ITEM FAIL" /tmp/vinv.out'

# L13 D419 s12: validate_inventory.sh must handle quote-containing summary fields
check "validate_inventory.sh handles quote-containing summary fields" python3 scripts/_test_validate_handles_quotes.py

# L14 / META P11 D419 s13: validate_inventory.sh must catch non-canonical internal_memory_policy
check "validate_inventory.sh catches non-canonical internal_memory_policy" bash -c '
cp inventory.yaml /tmp/inv_smoke_pol.yaml
python3 -c "import yaml; d=yaml.safe_load(open(\"inventory.yaml\")); 
items=[it for it in d[\"items\"] if it.get(\"internal_memory_policy\")]
if items: items[0][\"internal_memory_policy\"]=\"pointer-only.\"
yaml.dump(d,open(\"inventory.yaml\",\"w\"),sort_keys=False,width=100)"
trap "cp /tmp/inv_smoke_pol.yaml inventory.yaml" EXIT
if bash scripts/validate_inventory.sh > /tmp/vinv_pol.out 2>&1; then
  exit 1
fi
grep -q "non-canonical internal_memory_policy" /tmp/vinv_pol.out'

# D419 s14: validate_inventory.sh must catch non-canonical status
check "validate_inventory.sh catches non-canonical status" bash -c '
cp inventory.yaml /tmp/inv_smoke_st.yaml
python3 -c "import yaml; d=yaml.safe_load(open(\"inventory.yaml\")); 
d[\"items\"][0][\"status\"]=\"STALE\"
yaml.dump(d,open(\"inventory.yaml\",\"w\"),sort_keys=False,width=100)"
trap "cp /tmp/inv_smoke_st.yaml inventory.yaml" EXIT
if bash scripts/validate_inventory.sh > /tmp/vinv_st.out 2>&1; then
  exit 1
fi
grep -q "non-canonical status" /tmp/vinv_st.out'

# D419 s14: validate_inventory.sh must catch non-canonical kind
check "validate_inventory.sh catches non-canonical kind" bash -c '
cp inventory.yaml /tmp/inv_smoke_kd.yaml
python3 -c "import yaml; d=yaml.safe_load(open(\"inventory.yaml\")); 
d[\"items\"][0][\"kind\"]=\"madeupkind\"
yaml.dump(d,open(\"inventory.yaml\",\"w\"),sort_keys=False,width=100)"
trap "cp /tmp/inv_smoke_kd.yaml inventory.yaml" EXIT
if bash scripts/validate_inventory.sh > /tmp/vinv_kd.out 2>&1; then
  exit 1
fi
grep -q "non-canonical kind" /tmp/vinv_kd.out'

# D419 s15: validate_inventory.sh must catch non-canonical last_verified format
check "validate_inventory.sh catches non-canonical last_verified" bash -c '
cp inventory.yaml /tmp/inv_smoke_lv.yaml
python3 -c "import yaml; d=yaml.safe_load(open(\"inventory.yaml\")); 
d[\"items\"][0][\"last_verified\"]=\"2026-05-25\"
yaml.dump(d,open(\"inventory.yaml\",\"w\"),sort_keys=False,width=100)"
trap "cp /tmp/inv_smoke_lv.yaml inventory.yaml" EXIT
if bash scripts/validate_inventory.sh > /tmp/vinv_lv.out 2>&1; then
  exit 1
fi
grep -q "non-canonical last_verified" /tmp/vinv_lv.out'

# D419 s15: validate_inventory.sh path-check must NOT match prose-with-internal-slashes (L15)
check "validate path-check ignores prose with internal slashes" bash -c '
cp inventory.yaml /tmp/inv_smoke_pr.yaml
trap "cp /tmp/inv_smoke_pr.yaml inventory.yaml" EXIT
# Inject prose source containing a slash. If the validator treats it as a path,
# it will fail (since e.g. "v5/v6" wont exist on disk).
python3 -c "import yaml; d=yaml.safe_load(open(\"inventory.yaml\"));
d[\"items\"][0][\"source\"]=\"built s2, hardened in s5/s6/s7\"
yaml.dump(d,open(\"inventory.yaml\",\"w\"),sort_keys=False,width=100)"
bash scripts/validate_inventory.sh > /tmp/vinv_pr.out 2>&1'


# L14 D419 s13: scripts/memory_metrics.sh exits 0 (all guards present)
check "memory_metrics.sh exits 0 when guards intact" bash scripts/memory_metrics.sh

# L14 D419 s13: memory_metrics.sh prints policy distribution
check "memory_metrics.sh prints policy distribution" bash -c '
out=$(bash scripts/memory_metrics.sh)
echo "$out" | grep -q "policy_distribution"'

echo ""
echo "=== Summary ==="
echo "  PASS: $PASS    FAIL: $FAIL    WARN: $WARN"
if [ "$FAIL" -gt 0 ]; then
  echo "  STATUS: FAIL ❌"
  exit 1
fi
echo "  STATUS: healthy ✅"
exit 0
