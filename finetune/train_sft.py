#!/usr/bin/env python3
"""Tinker SFT trainer for the village leader.

Loads finetune/data/seed_v0.jsonl (HF chat-format rows), renders each via
the base model's chat template, builds assistant-only loss masks, and
runs a small SFT loop on a LoRA adapter via the Tinker API.

Run a smoke pass with:
    python3 finetune/train_sft.py --steps 2 --batch-size 4

Run a full pass with:
    python3 finetune/train_sft.py --steps 200 --batch-size 8 \
        --learning-rate 1e-4 --rank 32

After training, prints the tinker:// sampler URI. DO NOT EMAIL until #best
vote-keep on a held-out eval.
"""
from __future__ import annotations

import argparse
import json
import os
import random
import sys
from pathlib import Path
from typing import List, Dict, Any

# Lazy imports for tinker / transformers so --help works without them.
def _imp_tinker():
    import tinker  # noqa
    from tinker import types  # noqa
    return tinker, types

def _imp_tokenizer(model_name: str):
    from transformers import AutoTokenizer
    # Tinker base names are HF-compatible (Qwen/..., meta-llama/..., etc).
    return AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)


def load_jsonl(path: Path) -> List[Dict[str, Any]]:
    rows = []
    with path.open() as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            rows.append(json.loads(line))
    return rows


def render_row(tokenizer, messages: List[Dict[str, str]]) -> Dict[str, Any]:
    """Render (system, user, assistant) -> input_tokens, target_tokens, weights.

    weights[i] == 1.0 only for target positions inside the assistant turn,
    so only assistant-token cross-entropy is back-propagated.

    Strategy: render messages[:-1] (prompt only, with generation prompt)
    and messages[:] (full), then mask weights=0 on the prompt prefix.
    """
    # Render to string then encode (apply_chat_template tokenize=True returns
    # an Encoding wrapper for some fast tokenizers; string -> encode is portable).
    s_full = tokenizer.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=False
    )
    s_prompt = tokenizer.apply_chat_template(
        messages[:-1], tokenize=False, add_generation_prompt=True
    )
    full_ids = tokenizer.encode(s_full, add_special_tokens=False)
    prompt_ids = tokenizer.encode(s_prompt, add_special_tokens=False)
    # Defensive: prompt_ids should be a prefix of full_ids.
    if len(prompt_ids) >= len(full_ids):
        raise ValueError(
            f"prompt_ids len {len(prompt_ids)} >= full_ids len {len(full_ids)}; "
            f"chat template likely not appending assistant turn."
        )
    if full_ids[: len(prompt_ids)] != prompt_ids:
        # Some templates re-encode whitespace; fall back to length-based mask.
        pass

    # Shift for next-token prediction.
    input_tokens = full_ids[:-1]
    target_tokens = full_ids[1:]

    weights = [0.0] * len(input_tokens)
    # First target position whose label is in the assistant span is index = len(prompt_ids) - 1
    # (i.e., predict the first assistant token from the last prompt token).
    start = max(0, len(prompt_ids) - 1)
    for i in range(start, len(weights)):
        weights[i] = 1.0

    return {
        "input_tokens": input_tokens,
        "target_tokens": target_tokens,
        "weights": weights,
    }


def build_datum(types, row: Dict[str, Any]):
    return types.Datum(
        model_input=types.ModelInput.from_ints(tokens=row["input_tokens"]),
        loss_fn_inputs={
            "weights": row["weights"],
            "target_tokens": row["target_tokens"],
        },
    )


def iter_batches(rows, batch_size, rng):
    order = list(range(len(rows)))
    rng.shuffle(order)
    for i in range(0, len(order), batch_size):
        yield [rows[j] for j in order[i : i + batch_size]]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default="finetune/data/seed_v0.jsonl")
    ap.add_argument("--model", default="Qwen/Qwen3-8B")
    ap.add_argument("--rank", type=int, default=32)
    ap.add_argument("--steps", type=int, default=2,
                    help="optimizer steps; default 2 for smoke")
    ap.add_argument("--batch-size", type=int, default=4)
    ap.add_argument("--learning-rate", type=float, default=1e-4)
    ap.add_argument("--max-length", type=int, default=4096)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--checkpoint-name", default="leader-v0")
    ap.add_argument("--dry-run", action="store_true",
                    help="render dataset but do not contact Tinker")
    args = ap.parse_args()

    data_path = Path(args.data)
    if not data_path.exists():
        print(f"FATAL: {data_path} not found", file=sys.stderr)
        sys.exit(2)

    print(f"== Loading {data_path} ...")
    rows = load_jsonl(data_path)
    print(f"   rows={len(rows)}")

    print(f"== Loading tokenizer for {args.model} ...")
    tok = _imp_tokenizer(args.model)

    print("== Rendering rows ...")
    rendered = []
    skipped = 0
    for r in rows:
        try:
            rd = render_row(tok, r["messages"])
        except Exception as e:
            print(f"   skip ({e})")
            skipped += 1
            continue
        if len(rd["input_tokens"]) > args.max_length:
            print(f"   skip (len={len(rd['input_tokens'])} > {args.max_length})")
            skipped += 1
            continue
        rendered.append(rd)
    print(f"   rendered={len(rendered)} skipped={skipped}")

    # Sanity: at least one weight==1 per row.
    bad = [i for i, r in enumerate(rendered) if not any(w > 0 for w in r["weights"])]
    if bad:
        print(f"FATAL: {len(bad)} rendered rows have no positive weights", file=sys.stderr)
        sys.exit(3)

    if args.dry_run:
        # Print a small preview and exit before any network call.
        sample = rendered[0]
        print("== DRY RUN preview (row 0):")
        print(f"   input_tokens len = {len(sample['input_tokens'])}")
        print(f"   first-assistant-target idx = {next(i for i,w in enumerate(sample['weights']) if w>0)}")
        print(f"   tail tokens decoded: ...{tok.decode(sample['target_tokens'][-32:])}")
        print("== DRY RUN OK (no Tinker contact). Re-run without --dry-run to train.")
        return

    print("== Importing tinker ...")
    tinker, types = _imp_tinker()
    sc = tinker.ServiceClient()

    print(f"== Creating LoRA training client ({args.model}, rank={args.rank}) ...")
    tc = sc.create_lora_training_client(base_model=args.model, rank=args.rank)

    rng = random.Random(args.seed)
    step = 0
    print(f"== Training: {args.steps} optimizer steps, batch={args.batch_size}")
    for batch in iter_batches(rendered, args.batch_size, rng):
        if step >= args.steps:
            break
        batch_data = [build_datum(types, r) for r in batch]
        fwd = tc.forward_backward(batch_data, loss_fn="cross_entropy")
        opt = tc.optim_step(types.AdamParams(learning_rate=args.learning_rate))
        fwd_res = fwd.result()
        opt.result()
        # Try to surface a loss metric if available.
        try:
            loss = getattr(fwd_res, "loss", None) or getattr(fwd_res, "metrics", {})
        except Exception:
            loss = "(loss unavailable)"
        print(f"   step {step+1}/{args.steps}  loss={loss}")
        step += 1

    if step == 0:
        print("FATAL: no steps run (batch iterator empty?)", file=sys.stderr)
        sys.exit(4)

    print(f"== Saving sampler weights as '{args.checkpoint_name}' ...")
    # save_weights_for_sampler returns an APIFuture with .path on resolution.
    save_resp = tc.save_weights_for_sampler(name=args.checkpoint_name).result()
    uri = save_resp.path
    print()
    print("=" * 60)
    print(f"  tinker URI:  {uri}")
    print("=" * 60)
    print("DO NOT EMAIL until held-out eval + #best vote-keep.")


if __name__ == "__main__":
    main()
