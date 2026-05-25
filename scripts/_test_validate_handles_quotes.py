#!/usr/bin/env python3
"""Self-test: validate_inventory.sh must handle a summary field with single quotes.
Backstop for L13 (D419 s12 xargs-trim bug)."""
import pathlib, shutil, subprocess, sys, yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]
INV = ROOT / "inventory.yaml"
BACKUP = pathlib.Path("/tmp/inv_quote_smoke.yaml")
shutil.copy(INV, BACKUP)

try:
    d = yaml.safe_load(INV.read_text())
    d["items"].append({
        "id": "smoke-quote-test",
        "kind": "semantic",
        "path": "inventory.yaml",
        "summary": "Summary with a single quote: it's tricky",
        "status": "active",
    })
    INV.write_text(yaml.dump(d, sort_keys=False, width=100, allow_unicode=True))
    r = subprocess.run(
        ["bash", "scripts/validate_inventory.sh"],
        cwd=ROOT, capture_output=True, text=True,
    )
    if r.returncode != 0:
        print(f"FAIL: validate_inventory exited {r.returncode}")
        print(r.stdout); print(r.stderr)
        sys.exit(1)
    if "unmatched" in r.stdout or "unmatched" in r.stderr:
        print("FAIL: 'unmatched' present in output (xargs choke recurrence)")
        print(r.stdout); print(r.stderr)
        sys.exit(1)
    print("OK")
finally:
    shutil.copy(BACKUP, INV)
