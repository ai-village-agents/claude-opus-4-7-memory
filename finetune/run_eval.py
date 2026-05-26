#!/usr/bin/env python3
"""Held-out leader eval: samples from base or LoRA URI, scores against rubric.

Usage:
  python3 finetune/run_eval.py --base-model Qwen/Qwen3-8B
  python3 finetune/run_eval.py --model-path tinker://.../sampler_weights/leader-v0
"""
import argparse, json, os, re, sys, pathlib

HERE = pathlib.Path(__file__).parent
DEFAULT_SCEN = HERE / "leader_eval_scenarios_v0.md"
GPT55_SCEN = pathlib.Path("/tmp/gpt-5-5-leader-finetune/eval/scenarios_v0.jsonl")

SYSTEM_PROMPT = (
    "You are the leader of #best, a chat room of 4 capable AI agents collaborating "
    "on a shared goal. Be concise (\u22644 sentences). Name a decision-rule, not just "
    "an opinion. Propose one main action + one fallback. Surface disagreement before "
    "committing. Validate-then-build: ship the smallest version first."
)

# Parse my markdown scenario file into list of {id, situation, target}
def load_scenarios_md(p):
    txt = p.read_text(encoding='utf-8')
    rows = []
    blocks = re.split(r'\n## Scenario (\d+) — ', txt)
    for i in range(1, len(blocks), 2):
        sid = blocks[i]
        body = blocks[i+1]
        title_nl = body.find('\n')
        title = body[:title_nl].strip()
        rest = body[title_nl:]
        m_sit = re.search(r'\*\*Situation:\*\*\s*(.+?)(?=\n\*\*|\n##|\Z)', rest, re.DOTALL)
        m_tgt = re.search(r'\*\*Target reply[^*]*\*\*\s*\n>\s*(.+?)(?=\n##|\Z)', rest, re.DOTALL)
        if not m_sit:
            continue
        sit = ' '.join(m_sit.group(1).split()).strip('"').strip()
        tgt = ' '.join(m_tgt.group(1).split()) if m_tgt else ""
        rows.append({"id": "S" + sid, "situation": sit, "target": tgt})
    return rows

def load_scenarios_jsonl(p):
    rows = []
    for line in p.read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if not line: continue
        d = json.loads(line)
        rows.append({"id": d["id"], "situation": d["prompt"], "target": ""})
    return rows

# === RUBRIC ===
DECISION_RULE_RX = re.compile(r'\b(if |when |because |pick |default|rule |criterion|criteria|prefer|otherwise|else|reversible|threshold|gate)\b', re.IGNORECASE)
ACTION_RX = re.compile(r'\b(I will|I\u2019ll|please|let\'s|let us|assign|propose|ship|draft|run|build|merge|commit)\b', re.IGNORECASE)
FALLBACK_RX = re.compile(r'\b(otherwise|else|fallback|if .+? fails?|if not|backup|alternative|if that|veto)\b', re.IGNORECASE)

def split_sentences(s):
    # crude: split on . ! ? followed by space or end
    parts = re.split(r'(?<=[.!?])\s+', s.strip())
    return [p for p in parts if p.strip()]

def score(text):
    sents = split_sentences(text)
    n_sent = len(sents)
    n_char = len(text)
    has_rule = bool(DECISION_RULE_RX.search(text))
    has_action = bool(ACTION_RX.search(text))
    has_fallback = bool(FALLBACK_RX.search(text))
    pass_len = n_sent <= 4
    pass_short = n_char <= 600
    pass_rule = has_rule
    pass_action = has_action
    pass_fallback = has_fallback
    return {
        "n_sentences": n_sent,
        "n_chars": n_char,
        "pass_len": pass_len,
        "pass_short": pass_short,
        "pass_rule": pass_rule,
        "pass_action": pass_action,
        "pass_fallback": pass_fallback,
        "total_pass": sum([pass_len, pass_short, pass_rule, pass_action, pass_fallback]),
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-model", default=None, help="HF id, e.g. Qwen/Qwen3-8B")
    ap.add_argument("--model-path", default=None, help="tinker:// URI")
    ap.add_argument("--tokenizer", default="Qwen/Qwen3-8B")
    ap.add_argument("--scenarios", default=None, help="path; default = leader_eval_scenarios_v0.md")
    ap.add_argument("--gpt55", action="store_true", help="use GPT-5.5 jsonl scenarios")
    ap.add_argument("--max-tokens", type=int, default=300)
    ap.add_argument("--temperature", type=float, default=0.4)
    ap.add_argument("--out", default=None, help="JSONL out path")
    args = ap.parse_args()

    if args.gpt55:
        scen_path = GPT55_SCEN
        scenarios = load_scenarios_jsonl(scen_path)
    else:
        scen_path = pathlib.Path(args.scenarios) if args.scenarios else DEFAULT_SCEN
        scenarios = load_scenarios_md(scen_path)
    print(f"Loaded {len(scenarios)} scenarios from {scen_path}", file=sys.stderr)

    # Load tokenizer
    from transformers import AutoTokenizer
    tok = AutoTokenizer.from_pretrained(args.tokenizer)

    # Build Tinker sampling client
    import tinker
    from tinker import types
    sc = tinker.ServiceClient()
    if args.model_path:
        sclient = sc.create_sampling_client(model_path=args.model_path)
        tag = args.model_path
    elif args.base_model:
        sclient = sc.create_sampling_client(base_model=args.base_model)
        tag = args.base_model
    else:
        print("ERROR: pass --base-model or --model-path", file=sys.stderr); sys.exit(1)

    results = []
    for s in scenarios:
        msgs = [
            {"role": "system",  "content": SYSTEM_PROMPT},
            {"role": "user",    "content": s["situation"]},
        ]
        prompt_str = tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=True)
        prompt_ids = tok.encode(prompt_str, add_special_tokens=False)
        prompt = types.ModelInput.from_ints(prompt_ids)
        sp = types.SamplingParams(
            max_tokens=args.max_tokens,
            temperature=args.temperature,
            stop=["<|im_end|>", "<|endoftext|>"],
        )
        fut = sclient.sample(prompt=prompt, num_samples=1, sampling_params=sp)
        resp = fut.result()
        seq = resp.sequences[0]
        toks = list(seq.tokens) if hasattr(seq, 'tokens') else list(seq.tokens_np)
        text = tok.decode(toks, skip_special_tokens=True)
        sc_dict = score(text)
        results.append({"id": s["id"], "situation": s["situation"][:80], "reply": text.strip(), "score": sc_dict})
        print(f"[{s['id']}] sents={sc_dict['n_sentences']} chars={sc_dict['n_chars']} pass={sc_dict['total_pass']}/5  rule={sc_dict['pass_rule']} action={sc_dict['pass_action']} fb={sc_dict['pass_fallback']}", file=sys.stderr)

    n = len(results)
    avg_pass = sum(r["score"]["total_pass"] for r in results) / n if n else 0
    rule_rate = sum(1 for r in results if r["score"]["pass_rule"]) / n if n else 0
    fb_rate = sum(1 for r in results if r["score"]["pass_fallback"]) / n if n else 0
    len_rate = sum(1 for r in results if r["score"]["pass_len"]) / n if n else 0
    print(f"\n=== SUMMARY ({tag}) ===")
    print(f"  scenarios: {n}")
    print(f"  avg total_pass: {avg_pass:.2f}/5")
    print(f"  decision-rule rate: {rule_rate*100:.0f}%")
    print(f"  fallback rate: {fb_rate*100:.0f}%")
    print(f"  length≤4 rate: {len_rate*100:.0f}%")

    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            for r in results:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")
        print(f"  wrote {args.out}", file=sys.stderr)

if __name__ == "__main__":
    main()
