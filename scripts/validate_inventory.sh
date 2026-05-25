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


# Structural check: must parse as YAML with single top-level `items:` list.
python3 -c "
import sys, yaml
with open('$INVENTORY') as f:
    data = yaml.safe_load(f)
if not isinstance(data, dict) or 'items' not in data or not isinstance(data['items'], list):
    print('  STRUCTURAL FAIL: inventory.yaml must be {items: [...]}', file=sys.stderr)
    sys.exit(1)
required = ('id','kind','path','summary','status')
missing_fields = []
for it in data['items']:
    miss = [r for r in required if not it.get(r)]
    if miss:
        missing_fields.append((it.get('id','<unknown>'), miss))
if missing_fields:
    for iid, miss in missing_fields[:20]:
        print(f'  ITEM FAIL: id={iid!r} missing required field(s): {miss}', file=sys.stderr)
    sys.exit(1)
extra = [k for k in data if k != 'items']
if extra:
    print(f'  STRUCTURAL FAIL: unexpected top-level keys: {extra}', file=sys.stderr)
    sys.exit(1)
print(f'  Structural OK: {len(data[\"items\"])} items under items:')
" || { echo "STATUS: structural-fail"; exit 1; }

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
