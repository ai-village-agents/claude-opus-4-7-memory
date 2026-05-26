#!/usr/bin/env python3
"""Sample v4 model on 7 scaffolding rows + 3 Kimi rows; check for <tool_use> emission."""
import json, os, sys, re, pathlib, glob

HERE = pathlib.Path(__file__).parent
COMBINED = HERE / "data/scaffolding_v4/scaffolding_v4_combined.jsonl"

def load_rows():
    rows = []
    with open(COMBINED) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            rows.append(json.loads(line))
    # Also load Kimi rows
    for p in sorted(glob.glob("/tmp/kimi-mem/finetune/data/scaffolding_v4/*.json")):
        rows.append(json.load(open(p)))
    return rows

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--model-path", required=True)
    ap.add_argument("--tokenizer", default="Qwen/Qwen3-8B")
    ap.add_argument("--max-tokens", type=int, default=400)
    ap.add_argument("--temperature", type=float, default=0.2)
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    from transformers import AutoTokenizer
    import tinker
    from tinker import types

    tok = AutoTokenizer.from_pretrained(args.tokenizer)
    sc = tinker.ServiceClient()
    sclient = sc.create_sampling_client(model_path=args.model_path)

    rows = load_rows()
    print(f"Loaded {len(rows)} scaffolding rows", file=sys.stderr)
    results = []
    for i, r in enumerate(rows):
        msgs = r["messages"][:2]  # system + user only
        meta = r.get("_meta", {})
        prompt_str = tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=True)
        prompt_ids = tok.encode(prompt_str, add_special_tokens=False)
        prompt = types.ModelInput.from_ints(prompt_ids)
        sp = types.SamplingParams(max_tokens=args.max_tokens, temperature=args.temperature,
                                  stop=["<|im_end|>", "<|endoftext|>"])
        resp = sclient.sample(prompt=prompt, num_samples=1, sampling_params=sp).result()
        seq = resp.sequences[0]
        toks = list(seq.tokens) if hasattr(seq, 'tokens') else list(seq.tokens_np)
        text = tok.decode(toks, skip_special_tokens=True)
        # Check: did it emit <tool_use> block with send_message_to_chat?
        has_tool_use = "<tool_use>" in text
        has_send_chat = "send_message_to_chat" in text
        has_think = "<think>" in text or "</think>" in text
        captured_by = meta.get("captured_by", "unknown")
        ttype = meta.get("turn_type", meta.get("scenario", "?"))
        is_negative = ttype.startswith("negative") or "duplicate" in ttype or "no-chat" in ttype or "no_chat" in ttype
        expected = "no_tool_use" if is_negative else "tool_use"
        # Negative rows: should NOT emit tool_use (correctly guard against duplicate)
        # Positive rows: SHOULD emit tool_use
        if is_negative:
            correct = not has_tool_use
        else:
            correct = has_tool_use and has_send_chat
        results.append({
            "idx": i, "captured_by": captured_by, "turn_type": ttype,
            "expected": expected, "has_tool_use": has_tool_use,
            "has_send_chat": has_send_chat, "has_think": has_think,
            "correct": correct, "reply_preview": text[:200],
            "reply_len": len(text)
        })
        marker = "✓" if correct else "✗"
        print(f"[{i:02d}] {marker} {captured_by:15s} {ttype:35s} tool_use={has_tool_use} send_chat={has_send_chat} think={has_think}", file=sys.stderr)

    n = len(results)
    n_correct = sum(1 for r in results if r["correct"])
    pos = [r for r in results if r["expected"] == "tool_use"]
    neg = [r for r in results if r["expected"] == "no_tool_use"]
    pos_correct = sum(1 for r in pos if r["correct"])
    neg_correct = sum(1 for r in neg if r["correct"])
    print(f"\n=== SCAFFOLDING EVAL ({args.model_path}) ===")
    print(f"  total: {n_correct}/{n} ({n_correct/n*100:.0f}%)")
    print(f"  positives (tool_use expected): {pos_correct}/{len(pos)}")
    print(f"  negatives (no tool_use):       {neg_correct}/{len(neg)}")
    print(f"  no_think rate: {sum(1 for r in results if not r['has_think'])}/{n}")

    if args.out:
        with open(args.out, "w") as f:
            for r in results:
                f.write(json.dumps(r) + "\n")

if __name__ == "__main__":
    main()
