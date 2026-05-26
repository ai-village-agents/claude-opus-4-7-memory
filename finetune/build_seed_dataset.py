"""
Build the v0 SFT dataset for leader fine-tune.
Sources:
  1. finetune/leader_eval_scenarios_v0.md  (10 scenarios → 10 conv pairs)
  2. lessons.md L1-L16                      (situation → lesson statement)
  3. decisions.md                           (architecture decisions → rationale)

Output: finetune/data/seed_v0.jsonl   (each line = HF-chat-format example)
"""
import json
import os
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
DATA_DIR = REPO / "finetune" / "data"
DATA_DIR.mkdir(parents=True, exist_ok=True)

SYSTEM_PROMPT = (
    "You are the leader of #best, a chat room of 4 capable AI agents collaborating "
    "on a shared goal. Be concise (≤4 sentences). Name a decision-rule, not just an "
    "opinion. Propose one main action + one fallback. Surface disagreement before "
    "committing. Validate-then-build: ship the smallest version first."
)

def from_scenarios():
    """Extract Scenario N items from leader_eval_scenarios_v0.md"""
    p = REPO / "finetune" / "leader_eval_scenarios_v0.md"
    text = p.read_text()
    # Each scenario starts with `## Scenario N — Title` then has **Situation:** and **Target reply...:**
    blocks = re.split(r"\n## Scenario \d+ — ", text)[1:]
    out = []
    for b in blocks:
        m_sit = re.search(r"\*\*Situation:\*\*\s*(.+?)\n", b, re.DOTALL)
        m_tgt = re.search(r"\*\*Target reply[^:]*:\*\*\s*(.+?)(?:\n## |\n---|\Z)", b, re.DOTALL)
        if m_sit and m_tgt:
            sit = m_sit.group(1).strip()
            tgt = m_tgt.group(1).strip()
            # Strip leading > from blockquote target
            tgt = re.sub(r"^>\s*", "", tgt, flags=re.MULTILINE).strip()
            out.append({
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": sit},
                    {"role": "assistant", "content": tgt},
                ],
                "source": "leader_eval_scenarios_v0.md",
            })
    return out

def from_lessons():
    """Convert L1–L16 from lessons.md into situation→principle pairs."""
    p = REPO / "lessons.md"
    text = p.read_text()
    # Format: `## L<n> — <title>\n<body until next ## or EOF>`
    blocks = re.findall(r"\n## L(\d+) — ([^\n]+)\n(.+?)(?=\n## L\d+ — |\Z)", text, re.DOTALL)
    out = []
    for n, title, body in blocks:
        body = body.strip()
        # Construct: user asks "what's the lesson from <title>?", assistant gives principle
        user = f"What's the principle behind: \"{title.strip()}\"?"
        # Take first paragraph as the principle, max ~400 chars
        first_para = body.split("\n\n")[0].strip()
        # Clamp to 4 sentences
        sents = re.split(r"(?<=[.!?])\s+", first_para)
        assistant = " ".join(sents[:4]).strip()
        if len(assistant) > 50:
            out.append({
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": user},
                    {"role": "assistant", "content": assistant},
                ],
                "source": f"lessons.md#L{n}",
            })
    return out

def from_decisions():
    """Convert decisions.md entries into 'why?' → rationale pairs."""
    p = REPO / "decisions.md"
    if not p.exists():
        return []
    text = p.read_text()
    # Heuristic split: lines starting with `## ` are decision titles
    blocks = re.findall(r"\n## ([^\n]+)\n(.+?)(?=\n## |\Z)", text, re.DOTALL)
    out = []
    for title, body in blocks:
        body = body.strip()
        user = f"Why did we decide: \"{title.strip()}\"?"
        first_para = body.split("\n\n")[0].strip()
        sents = re.split(r"(?<=[.!?])\s+", first_para)
        assistant = " ".join(sents[:4]).strip()
        if len(assistant) > 50:
            out.append({
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": user},
                    {"role": "assistant", "content": assistant},
                ],
                "source": f"decisions.md::{title.strip()}",
            })
    return out

def main():
    all_rows = []
    for fn, name in [(from_scenarios, "scenarios"), (from_lessons, "lessons"), (from_decisions, "decisions")]:
        rows = fn()
        print(f"{name}: {len(rows)} rows")
        all_rows.extend(rows)
    out_path = DATA_DIR / "seed_v0.jsonl"
    with open(out_path, "w") as f:
        for r in all_rows:
            f.write(json.dumps(r) + "\n")
    print(f"\nWrote {len(all_rows)} rows to {out_path}")

if __name__ == "__main__":
    main()
