#!/usr/bin/env python3
"""Build seed_v1.jsonl by merging:
  - finetune/data/seed_v0.jsonl  (existing 35 rows)
  - finetune/mined_leader_messages_d405_409.md  (10 mined SITUATION/QUOTE)
  - Kimi K2.6's mined_kimi_v0.jsonl from her repo (12 rows)
Dedupe by user-turn-first-80-chars (case-insensitive).
"""
import json, re, sys, subprocess, pathlib

HERE = pathlib.Path(__file__).parent
SEED_V0 = HERE / "data" / "seed_v0.jsonl"
MINED_MD = HERE / "mined_leader_messages_d405_409.md"
OUT = HERE / "data" / "seed_v1.jsonl"
KIMI_REPO = pathlib.Path("/tmp/k2-6-memory")

SYSTEM_PROMPT = (
    "You are the leader of #best, a chat room of 4 capable AI agents collaborating "
    "on a shared goal. Be concise (\u22644 sentences). Name a decision-rule, not just "
    "an opinion. Propose one main action + one fallback. Surface disagreement before "
    "committing. Validate-then-build: ship the smallest version first."
)

def load_jsonl(p):
    rows=[]
    for line in p.read_text(encoding='utf-8').splitlines():
        line=line.strip()
        if not line: continue
        rows.append(json.loads(line))
    return rows

def parse_mined_md(p):
    """Parse 'SITUATION/QUOTE' pairs out of the markdown file."""
    txt = p.read_text(encoding='utf-8')
    rows = []
    # Each entry: starts with `## N. <agent> — <title>`
    # Then `- SITUATION: ...` line, then `- QUOTE: "..."` line
    blocks = re.split(r'\n## \d+\. ', txt)
    for blk in blocks[1:]:
        # First line = header (agent — title)
        first_nl = blk.find('\n')
        header = blk[:first_nl].strip()
        rest = blk[first_nl:]
        m_sit = re.search(r'- SITUATION:\s*(.+?)(?=\n- QUOTE:|\n\n|\Z)', rest, re.DOTALL)
        m_q   = re.search(r'- QUOTE:\s*"(.+?)"\s*(?=\n##|\n\n|\Z)', rest, re.DOTALL)
        if not (m_sit and m_q):
            continue
        situation = ' '.join(m_sit.group(1).split())
        quote = ' '.join(m_q.group(1).split())
        rows.append({
            "messages": [
                {"role": "system",    "content": SYSTEM_PROMPT},
                {"role": "user",      "content": situation},
                {"role": "assistant", "content": quote},
            ],
            "source": f"mined-d405-409:{header}",
        })
    return rows

def user_key(row):
    """Normalize user-turn for dedupe (first 80 chars lowercased)."""
    for m in row["messages"]:
        if m["role"] == "user":
            return re.sub(r'\s+', ' ', m["content"].lower()).strip()[:80]
    return ""

def main():
    v0 = load_jsonl(SEED_V0)
    mined = parse_mined_md(MINED_MD)
    kimi_path = KIMI_REPO / "finetune" / "data" / "mined_kimi_v0.jsonl"
    kimi = load_jsonl(kimi_path) if kimi_path.exists() else []
    print(f"seed_v0: {len(v0)} rows", file=sys.stderr)
    print(f"mined_d405_409: {len(mined)} rows", file=sys.stderr)
    print(f"kimi: {len(kimi)} rows", file=sys.stderr)

    # Dedupe by user-key. Keep first occurrence.
    seen = set()
    out = []
    dups = 0
    for src_name, rows in [("v0", v0), ("mined", mined), ("kimi", kimi)]:
        for r in rows:
            k = user_key(r)
            if k in seen:
                dups += 1
                continue
            seen.add(k)
            out.append(r)
    print(f"deduped: {dups} dropped, {len(out)} kept", file=sys.stderr)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open('w', encoding='utf-8') as f:
        for r in out:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"wrote {OUT} ({len(out)} rows)", file=sys.stderr)

if __name__ == "__main__":
    main()
