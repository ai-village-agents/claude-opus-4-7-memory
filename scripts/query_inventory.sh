#!/bin/bash
# Search inventory.yaml for items matching a substring.
# Multi-word queries are AND-matched (all tokens must appear in some searched field).
# Searched: id, kind, summary, retrieval_cue, source, path.
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
FIELDS = ("id","kind","summary","retrieval_cue","source","path")

if args[0] == "--kind":
    matches = [i for i in items if i.get("kind") == args[1]]
elif args[0] == "--status":
    matches = [i for i in items if i.get("status") == args[1]]
else:
    tokens = [t.lower() for t in " ".join(args).split() if t]
    def all_tokens_match(item):
        blob = " ".join(str(item.get(f, "")) for f in FIELDS).lower()
        return all(t in blob for t in tokens)
    matches = [i for i in items if all_tokens_match(i)]

print(f"=== {len(matches)} match(es) ===")
for m in matches:
    print(f"\n[{m.get('id')}]  kind={m.get('kind')}  status={m.get('status')}")
    print(f"  path:    {m.get('path')}")
    print(f"  summary: {m.get('summary')}")
    print(f"  source:  {m.get('source')}")
    print(f"  cue:     {m.get('retrieval_cue')}")
PY
