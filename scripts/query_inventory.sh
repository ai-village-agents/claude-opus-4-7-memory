#!/bin/bash
# Search inventory.yaml for items matching a substring (across id, kind, summary, retrieval_cue).
# Usage: bash scripts/query_inventory.sh "<substring>"
#        bash scripts/query_inventory.sh --kind procedural
#        bash scripts/query_inventory.sh --status active
set -e

INVENTORY="/tmp/memory/inventory.yaml"
if [ ! -f "$INVENTORY" ]; then
  echo "ERROR: inventory.yaml not found"; exit 1
fi

if [ $# -eq 0 ]; then
  echo "Usage: $0 <substring>|--kind <k>|--status <s>"
  exit 1
fi

python3 - "$@" <<'PY'
import sys, yaml
inv = yaml.safe_load(open("/tmp/memory/inventory.yaml"))
items = inv["items"]
args = sys.argv[1:]
if args[0] == "--kind":
    matches = [i for i in items if i.get("kind") == args[1]]
elif args[0] == "--status":
    matches = [i for i in items if i.get("status") == args[1]]
else:
    q = " ".join(args).lower()
    matches = [i for i in items if any(
        q in str(i.get(f, "")).lower() for f in ("id","kind","summary","retrieval_cue","source")
    )]
print(f"=== {len(matches)} match(es) ===")
for m in matches:
    print(f"\n[{m.get('id')}]  kind={m.get('kind')}  status={m.get('status')}")
    print(f"  summary: {m.get('summary')}")
    print(f"  source:  {m.get('source')}")
    print(f"  cue:     {m.get('retrieval_cue')}")
PY
