#!/bin/bash
# verify_inventory.sh — auto-verify inventory items by checking their `path` exists,
# and (with --bump) update last_verified to a target session for items that pass.
#
# Usage:
#   bash scripts/verify_inventory.sh                  # report only (no writes)
#   bash scripts/verify_inventory.sh --bump "D419 s16"  # bump last_verified for all passing items
#       (only items currently OLDER than target are bumped; prose suffix is preserved)
#
# CAUTION: only run --bump after you have actually exercised the items in this session.
# Path-exists alone is a weak verification signal.
#
# Note: paths in inventory may include multiple files separated by "; " or ", ".
# A pass requires that AT LEAST ONE listed file exists.

set -u
cd "$(dirname "$0")/.." || exit 2

BUMP=""
if [ "${1:-}" = "--bump" ]; then
  BUMP="${2:-}"
  if [ -z "$BUMP" ]; then
    echo "ERROR: --bump requires a target session string, e.g. 'D419 s16'" >&2
    exit 2
  fi
  if ! echo "$BUMP" | grep -qE '^D[0-9]+ s[0-9]+( \([0-9]{4}-[0-9]{2}-[0-9]{2}\))?( — .+)?$'; then
    echo "ERROR: bump target '$BUMP' must match canonical last_verified regex" >&2
    exit 2
  fi
fi

python3 - "$BUMP" << 'PYEOF'
import sys, re, yaml, os
bump = sys.argv[1]
with open('inventory.yaml') as f:
    raw = f.read()
data = yaml.safe_load(raw)

passing = []
failing = []
skipped = []
for it in data['items']:
    iid = it.get('id','<unknown>')
    p = it.get('path')
    if not p:
        skipped.append((iid, 'no path'))
        continue
    # Tokenize by ; or , surrounded by whitespace
    candidates = re.split(r'\s*[;,]\s*', str(p))
    ok = False
    for cand in candidates:
        cand = cand.strip()
        if not cand: continue
        # strip trailing punctuation
        cand = cand.rstrip('.')
        if os.path.exists(cand):
            ok = True
            break
    if ok:
        passing.append(iid)
    else:
        failing.append((iid, p))

print(f"PASS: {len(passing)}   FAIL: {len(failing)}   SKIP: {len(skipped)}")
if failing:
    print("\nFailing items (path not found):")
    for iid, p in failing:
        print(f"  {iid:40s}  path={p!r}")
if skipped:
    print("\nSkipped items (no path):")
    for iid, why in skipped:
        print(f"  {iid:40s}  ({why})")

def parse_day_sess(s):
    m = re.match(r'^D(\d+) s(\d+)', str(s).strip())
    if not m: return None
    return (int(m.group(1)), int(m.group(2)))

if bump and passing:
    # Apply bump only to items whose current last_verified is OLDER than target.
    target_tuple = parse_day_sess(bump)
    if target_tuple is None:
        print(f"ERROR: bump target '{bump}' is not parseable as D<day> s<session>", file=sys.stderr)
        sys.exit(2)
    text = raw
    n_changed = [0]
    n_fresh = [0]
    n_unparseable = [0]
    for it in data['items']:
        iid = it.get('id','')
        if iid not in passing: continue
        cur_lv = str(it.get('last_verified','')).strip()
        cur_tuple = parse_day_sess(cur_lv)
        if cur_tuple is None:
            n_unparseable[0] += 1
            continue
        if cur_tuple >= target_tuple:
            n_fresh[0] += 1
            continue
        # bump (preserve trailing " — prose" suffix if any)
        pattern = re.compile(
            r'(- id: ' + re.escape(iid) + r'\b[\s\S]*?last_verified: )([^\n]*)',
            re.MULTILINE
        )
        prose_m = re.match(r'^D\d+ s\d+(?: \(\d{4}-\d{2}-\d{2}\))?(?: — (.+))?$', cur_lv)
        prose = prose_m.group(1) if prose_m and prose_m.group(1) else None
        replacement = bump + (f' — {prose}' if prose else '')
        def rep(m, _r=replacement):
            n_changed[0] += 1
            return m.group(1) + _r
        text, _ = pattern.subn(rep, text, count=1)
    with open('inventory.yaml','w') as f:
        f.write(text)
    print(f"\nAlready-fresh items (>= target): {n_fresh[0]}")
    if n_unparseable[0]:
        print(f"Unparseable last_verified (skipped): {n_unparseable[0]}")
    print(f"Bumped last_verified → '{bump}' on {n_changed[0]} items.")

# Exit non-zero if any failures
sys.exit(0 if not failing else 1)
PYEOF
