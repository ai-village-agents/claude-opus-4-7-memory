#!/bin/bash
# Check that a drafted internal-memory block preserves load-bearing cues.
# Inspired by GPT-5.5's docs/future_internal_memory_block_draft_v0.md +
# scripts/check_compact_memory_draft.py (D419 71c0fdd).
#
# Usage:
#   bash scripts/check_memory_cues.sh < draft.txt
#   bash scripts/check_memory_cues.sh /path/to/draft.txt
#
# Reads a memory-block draft (from stdin if no file arg), checks for:
#   - REQUIRED cues (load-bearing, must be present)
#   - FORBIDDEN cues (anti-patterns, must be absent)
#   - Size budget (lines, chars)
# Exits 0 on pass, 1 on any failure. Prints PASS/FAIL summary.
#
# This is a DRAFT checker. It does NOT modify my actual internal memory
# (that lives only in scaffolding context). Use it at consolidate-time
# when drafting the appendix block: paste the draft, validate, then submit.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ "$#" -ge 1 ] && [ -f "$1" ]; then
  DRAFT="$(cat "$1")"
elif [ ! -t 0 ]; then
  DRAFT="$(cat -)"
else
  echo "Usage: $0 [draft-file]   (or pipe draft on stdin)"
  exit 2
fi

# --- Cue lists. Edit when load-bearing facts change. ---
# REQUIRED: things that MUST appear somewhere in the draft.
REQUIRED=(
  "Improve your memory"            # current goal
  "claude-opus-4-7-memory"         # repo name (key identity)
  "/tmp/memory/boot.sh"            # bootloader command
  "#best"                          # room
  "pre_send_chat.sh"               # dup guard
  "AGENT_TALK"                     # event semantics
  "stale-PASS"                     # L10 cue
  "structural"                     # L11 cue (structural drift)
  "Shoshannah"                     # admin (for goal change procedure)
  "runbooks/respond_to_admin"      # path to new-goal procedure
  "validate_inventory"             # current state pointer
)

# FORBIDDEN: anti-patterns. Should NOT appear in active sections.
# (Quick-facts/archive references to old goal are OK as long as marked.)
FORBIDDEN=(
  "Run your own YouTube channel\" set by Shoshannah"  # don't list archived goal as active
  "CURRENT GOAL (D412"             # old goal marker
)

# Size budget. Adjust if I deliberately want a longer memory.
MAX_LINES=300
MAX_CHARS=18000

# --- Checks ---
fail=0
n_lines="$(printf '%s' "$DRAFT" | wc -l | tr -d ' ')"
n_chars="$(printf '%s' "$DRAFT" | wc -c | tr -d ' ')"

echo "=== memory cue check ==="
echo "draft: ${n_lines} lines, ${n_chars} chars"

if [ "$n_lines" -gt "$MAX_LINES" ]; then
  echo "FAIL: draft too long ($n_lines > $MAX_LINES lines)"; fail=1
fi
if [ "$n_chars" -gt "$MAX_CHARS" ]; then
  echo "FAIL: draft too large ($n_chars > $MAX_CHARS chars)"; fail=1
fi

missing=()
for cue in "${REQUIRED[@]}"; do
  if ! printf '%s' "$DRAFT" | grep -qF -- "$cue"; then
    missing+=("$cue")
  fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "FAIL: missing required cues:"
  for c in "${missing[@]}"; do echo "  - $c"; done
  fail=1
fi

present_forbidden=()
for cue in "${FORBIDDEN[@]}"; do
  if printf '%s' "$DRAFT" | grep -qF -- "$cue"; then
    present_forbidden+=("$cue")
  fi
done
if [ "${#present_forbidden[@]}" -gt 0 ]; then
  echo "FAIL: forbidden cues present:"
  for c in "${present_forbidden[@]}"; do echo "  - $c"; done
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "STATUS: pass — all $(echo "${#REQUIRED[@]}") required cues present, no forbidden cues, size within budget"
  exit 0
else
  echo "STATUS: fail"
  exit 1
fi
