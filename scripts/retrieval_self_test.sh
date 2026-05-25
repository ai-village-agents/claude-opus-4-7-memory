#!/bin/bash
# retrieval_self_test.sh — validates the memory affordances can actually surface answers
# to common questions. Memory infra is only as good as its retrieval. This runs the
# canonical lookup tools against a fixed test set and checks expected file/keyword pairs.
#
# Usage: bash scripts/retrieval_self_test.sh
# Exits 0 on all pass, 1 on any fail.

set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

PASS=0
FAIL=0
RESULTS=()

# Each test: TOOL | QUERY | EXPECTED_SUBSTRING_IN_OUTPUT | DESCRIPTION
run_test() {
  local tool="$1" query="$2" expect="$3" desc="$4"
  local out
  case "$tool" in
    query)  out=$(bash scripts/query_inventory.sh "$query" 2>&1 || true) ;;
    search) out=$(bash scripts/search_memory.sh "$query" 2>&1 || true) ;;
    cat)    out=$(cat "$query" 2>&1 || true) ;;
  esac
  if echo "$out" | grep -qF "$expect"; then
    PASS=$((PASS+1))
    RESULTS+=("PASS: [$tool] $desc")
  else
    FAIL=$((FAIL+1))
    RESULTS+=("FAIL: [$tool] $desc — expected '$expect' in $tool($query)")
  fi
}

# === Procedural lookups (action verbs) ===
run_test query  "send_chat"        "runbooks/send_chat_message.md"      "find send-chat runbook"
run_test query  "consolidate"      "runbooks/consolidate.md"            "find consolidate runbook"
run_test query  "respond_to_admin" "runbooks/respond_to_admin.md"       "find admin-response runbook"
run_test query  "search_history"   "runbooks/search_history.md"         "find search-history runbook"
run_test query  "peer_feedback"    "runbooks/peer_feedback.md"          "find peer-feedback runbook"

# === Semantic/state lookups ===
run_test query  "load_bearing"     "load_bearing.md"                    "find load-bearing rules"
run_test query  "lessons"          "lessons.md"                         "find lessons file"
run_test query  "inventory"        "inventory.yaml"                     "find inventory itself"
run_test query  "active goal"      "goals/active.md"                    "find active goal file"
run_test query  "META"             "reflections/META.md"                "find META reflection"

# === Substantive content checks ===
run_test search "L12"              "AGENT_TALK"                          "L12 content surfaces echo-timing"
run_test search "L11"              "structural"                          "L11 content surfaces structural drift"
run_test search "P8"               "structural drift"                    "META P8 surfaces structural drift"
run_test search "stale-PASS"       "rescan"                              "stale-PASS lesson surfaces re-scan rule"
run_test search "Shoshannah"       "Improve your memory"                 "Shoshannah surfaces current goal context"

# === Cross-agent state ===
run_test search "gpt-5-5"          "gpt-5-5-memory-improvement"          "peer URL discoverable"
run_test search "Kimi"             "k2-6-memory"                         "Kimi URL discoverable"
run_test search "Gemini"           "gemini-3-5-flash-memory-vault"       "Gemini URL discoverable"

# === Identity/scaffolding ===
run_test cat    "IDENTITY.md"      "claude-opus-4.7@agentvillage.org"    "identity contains my email"
run_test cat    "skills.md"        "8000"                          "skills lists reserved ports"
run_test cat    "current_state.md" "commit"                                "current state lists commit"

# === Goal archive ===
run_test cat    "goals/INDEX.md"   "Improve your memory"                 "goal index lists current"
run_test search "youtube"          "goals/archive"                       "youtube archived not active"

# === Print results ===
echo "=== Retrieval Self-Test ==="
for r in "${RESULTS[@]}"; do echo "$r"; done
echo
echo "PASS: $PASS"
echo "FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
