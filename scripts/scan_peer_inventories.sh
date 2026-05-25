#!/bin/bash
# scan_peer_inventories.sh — Crawl peer memory repos' inventory.yaml files.
#
# Variant of Gemini 3.5 Flash's scan_peers.py with two differences:
#  1. Dynamic peer discovery via `gh repo list` (no hardcoded list to drift).
#  2. Per-peer summary report (counts + last commit + freshness).
#
# Authoritative output: peers/consolidated_inventory.json
# Human report on stdout.
#
# Usage:
#   bash scripts/scan_peer_inventories.sh                # scan + write JSON
#   bash scripts/scan_peer_inventories.sh --report-only  # rebuild report from existing JSON
set -e

REPO_ROOT="/tmp/memory"
cd "$REPO_ROOT"
OUT="$REPO_ROOT/peers/consolidated_inventory.json"
mkdir -p "$REPO_ROOT/peers"

if [ "$1" = "--report-only" ]; then
  if [ ! -f "$OUT" ]; then echo "ERROR: $OUT not found — run without --report-only first."; exit 1; fi
  REBUILD=0
else
  REBUILD=1
fi

if [ "$REBUILD" = "1" ]; then
  echo "=== Discovering peer memory repos in ai-village-agents ==="
  # Match any repo containing memory|vault|kit (Gemini uses 'memory-vault', GPT-5.4 uses 'memory-kit', etc.)
  PEERS=$(gh repo list ai-village-agents --limit 100 --json name,updatedAt \
            --jq '.[] | select(.name | test("memory|vault|kit")) | "\(.name)|\(.updatedAt)"')
  echo "$PEERS" | wc -l | awk '{print "  Found",$1,"candidate repos"}'

  TMPDIR=$(mktemp -d)
  trap "rm -rf $TMPDIR" EXIT
  echo "[" > "$OUT.tmp"
  FIRST=1
  while IFS='|' read -r repo updated; do
    [ -z "$repo" ] && continue
    echo "  fetch: $repo ($updated)"
    # Skip self
    if [ "$repo" = "claude-opus-4-7-memory" ]; then
      echo "    (self) skipped"
      continue
    fi
    # Try main branch
    if ! gh api "repos/ai-village-agents/$repo/contents/inventory.yaml" --jq '.content' 2>/dev/null | base64 -d > "$TMPDIR/inv.yaml" 2>/dev/null; then
      echo "    no inventory.yaml on main — skip"
      continue
    fi
    # Parse + emit JSON items
    python3 - "$repo" "$updated" "$TMPDIR/inv.yaml" "$OUT.tmp" "$FIRST" <<'PYEOF'
import sys, yaml, json
repo, updated, path, out_path, first = sys.argv[1:6]
try:
    with open(path) as f:
        data = yaml.safe_load(f)
except Exception as e:
    print(f"    YAML PARSE FAIL: {e}", file=sys.stderr)
    sys.exit(0)
if isinstance(data, dict) and 'items' in data:
    items = data['items']
elif isinstance(data, list):
    items = data
else:
    print(f"    unexpected YAML shape", file=sys.stderr)
    sys.exit(0)
if not items:
    sys.exit(0)
with open(out_path, 'a') as f:
    for it in items:
        if not isinstance(it, dict): continue
        rec = {
            'source_repo': repo,
            'repo_updated_at': updated,
            'id': str(it.get('id','')),
            'kind': str(it.get('kind','')),
            'status': str(it.get('status','')),
            'summary': str(it.get('summary',''))[:200],
            'path': str(it.get('path','')),
            'retrieval_cue': str(it.get('retrieval_cue',''))[:120],
            'last_verified': str(it.get('last_verified','')),
            'internal_memory_policy': str(it.get('internal_memory_policy','')),
        }
        if first == '1':
            first = '0'
        else:
            f.write(',\n')
        json.dump(rec, f)
        # Hack: pass updated `first` back via sentinel file (not strictly needed)
    print(f"    [{len(items)} items]")
PYEOF
    FIRST=0  # any item written after first repo
  done <<< "$PEERS"
  echo "" >> "$OUT.tmp"
  echo "]" >> "$OUT.tmp"
  # Fix the JSON: the above logic for FIRST is fragile across subshells; rebuild via python
  python3 - "$OUT.tmp" "$OUT" <<'PYEOF'
import sys, re, json
with open(sys.argv[1]) as f:
    raw = f.read()
# Extract each {…} JSON object via regex
objs = re.findall(r'\{"source_repo".*?\}(?=,?\n|\n?\])', raw)
parsed = [json.loads(o) for o in objs]
with open(sys.argv[2], 'w') as f:
    json.dump(parsed, f, indent=2)
print(f"  Wrote {len(parsed)} items to {sys.argv[2]}")
PYEOF
fi

echo
echo "=== Peer Inventory Summary Report ==="
python3 - "$OUT" <<'PYEOF'
import json, sys, collections
with open(sys.argv[1]) as f:
    items = json.load(f)
by_repo = collections.defaultdict(list)
for it in items:
    by_repo[it['source_repo']].append(it)
print(f"Total items across peers: {len(items)}")
print(f"Peers with inventory:     {len(by_repo)}")
print()
print(f"{'repo':<45} {'items':>5}  {'kinds':>5}  last_updated")
print("-"*90)
for repo in sorted(by_repo):
    arr = by_repo[repo]
    kinds = len(set(x['kind'] for x in arr))
    upd = arr[0].get('repo_updated_at','')[:10]
    print(f"{repo:<45} {len(arr):>5}  {kinds:>5}  {upd}")

# Show kind drift across peers
print()
print("Cross-peer 'kind' value diversity:")
allkinds = collections.Counter(it['kind'] for it in items)
for k,c in allkinds.most_common():
    print(f"  {k:<20} {c}")

# Show status drift across peers
print()
print("Cross-peer 'status' value diversity:")
allstat = collections.Counter(it['status'] for it in items)
for k,c in allstat.most_common():
    print(f"  {k:<20} {c}")
PYEOF
