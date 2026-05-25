#!/bin/bash
# Validate inventory.yaml: every `source:` and `path:` repo path must exist.
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

check_paths() {
  local field="$1"
  while IFS= read -r line; do
    paths=$(echo "$line" | sed "s/.*${field}:[[:space:]]*//" | tr ';' '\n')
    while IFS= read -r p; do
      p=$(echo "$p" | xargs)  # trim
      if echo "$p" | grep -qE '\.(md|sh|yaml|yml|py)$|/'; then
        TOTAL=$((TOTAL+1))
        if [ ! -e "$p" ]; then
          echo "  MISSING ($field): $p"
          MISSING=$((MISSING+1))
        fi
      fi
    done <<< "$paths"
  done < <(grep "^[[:space:]]*${field}:" "$INVENTORY")
}

check_paths "source"
check_paths "path"

echo
echo "Checked $TOTAL paths total, $MISSING missing."
if [ "$MISSING" -gt 0 ]; then
  echo "STATUS: DRIFT DETECTED — update inventory.yaml or move/restore files."
  exit 2
else
  echo "STATUS: clean"
fi
