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
      p=$(echo "$p" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//")  # trim (no xargs — bad with quotes)
      # Path candidate: a single token (no internal spaces) ending in source-extension OR containing slashes.
      # Prose with embedded slashes (e.g. "s5/s6") wouldn't match because it has spaces.
      if echo "$p" | grep -qE '^[^[:space:]]+\.(md|sh|yaml|yml|py|json)$|^[^[:space:]]+/[^[:space:]]+$'; then
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
CANONICAL_POLICIES = {'keep_pointer', 'keep_summary', 'pointer_only'}
bad_policy = []
for it in data['items']:
    pol = it.get('internal_memory_policy')
    if pol is None:
        continue
    if pol not in CANONICAL_POLICIES:
        bad_policy.append((it.get('id','<unknown>'), pol))
if bad_policy:
    for iid, pol in bad_policy[:20]:
        print(f'  ITEM FAIL: id={iid!r} non-canonical internal_memory_policy: {pol!r}', file=sys.stderr)
    print(f'  Allowed: {sorted(CANONICAL_POLICIES)}', file=sys.stderr)
    sys.exit(1)
CANONICAL_STATUS = {'active', 'retired', 'reference'}
bad_status = []
for it in data['items']:
    st = it.get('status')
    if st is None:
        continue
    if st not in CANONICAL_STATUS:
        bad_status.append((it.get('id','<unknown>'), st))
if bad_status:
    for iid, st in bad_status[:20]:
        print(f'  ITEM FAIL: id={iid!r} non-canonical status: {st!r}', file=sys.stderr)
    print(f'  Allowed status: {sorted(CANONICAL_STATUS)}', file=sys.stderr)
    sys.exit(1)
CANONICAL_KINDS = {'procedural','semantic','script','episodic','working','test','task-state','social','pointer','gate'}
bad_kind = []
for it in data['items']:
    k = it.get('kind')
    if k is None:
        continue
    if k not in CANONICAL_KINDS:
        bad_kind.append((it.get('id','<unknown>'), k))
if bad_kind:
    for iid, k in bad_kind[:20]:
        print(f'  ITEM FAIL: id={iid!r} non-canonical kind: {k!r}', file=sys.stderr)
    print(f'  Allowed kind: {sorted(CANONICAL_KINDS)}', file=sys.stderr)
    sys.exit(1)
import re as _re
LV_RE = _re.compile(r'^D\\d+ s\\d+(?: \\(\\d{4}-\\d{2}-\\d{2}\\))?(?: — .+)?$')
bad_lv = []
for it in data['items']:
    lv = it.get('last_verified')
    if lv is None:
        continue
    if not LV_RE.match(str(lv)):
        bad_lv.append((it.get('id','<unknown>'), lv))
if bad_lv:
    for iid, lv in bad_lv[:20]:
        print(f'  ITEM FAIL: id={iid!r} non-canonical last_verified: {lv!r}', file=sys.stderr)
    print(f'  Allowed format: D<day> s<session>[ (YYYY-MM-DD)][ — prose]', file=sys.stderr)
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
