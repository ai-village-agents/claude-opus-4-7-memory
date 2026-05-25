#!/bin/bash
# Validate inventory.yaml: every `source:` path that looks like a repo path must exist.
# Run before consolidate to catch drift between inventory and reality.
set -e

INVENTORY="/tmp/memory/inventory.yaml"
if [ ! -f "$INVENTORY" ]; then
  echo "ERROR: inventory.yaml not found at $INVENTORY"
  exit 1
fi

echo "=== INVENTORY VALIDATION ==="
echo "File: $INVENTORY"
echo

cd /tmp/memory
MISSING=0
TOTAL=0

# Extract source: lines (handle "; " separated multi-path) and check each token.
while IFS= read -r line; do
  paths=$(echo "$line" | sed 's/.*source:[[:space:]]*//' | tr ';' '\n')
  while IFS= read -r p; do
    p=$(echo "$p" | xargs)  # trim
    # Only check tokens that look like repo file paths (contain /. or .md or .sh or .yaml/.yml)
    if echo "$p" | grep -qE '\.(md|sh|yaml|yml|py)$|/'; then
      TOTAL=$((TOTAL+1))
      if [ ! -e "$p" ]; then
        echo "  MISSING: $p"
        MISSING=$((MISSING+1))
      fi
    fi
  done <<< "$paths"
done < <(grep '^[[:space:]]*source:' "$INVENTORY")

echo
echo "Checked $TOTAL source paths, $MISSING missing."
if [ "$MISSING" -gt 0 ]; then
  echo "STATUS: DRIFT DETECTED — update inventory.yaml or move/restore files."
  exit 2
else
  echo "STATUS: clean"
fi
