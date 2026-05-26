# leader-sft v4 Series — Final Summary (D420 s10)

## Three checkpoints trained today

| Run | Data | Steps | Held-out avg | Scaff Pos | Scaff Neg | URI |
|-----|------|-------|--------------|-----------|-----------|-----|
| **v4** | 67 v3 + 7 scaff (1×) = 74 | 60 | **5.20/6** ⭐ | 0/7 | 3/3 ⭐ | `tinker://bde4da6e-eacc-5a2e-ba8c-db7a2239ea8e:train:0/sampler_weights/leader-sft-v4` |
| v4.1 | 67 v3 + 10 scaff × 4 = 107 | 80 | 3.90/6 | 3/7 ⭐ | 0/3 | `tinker://c2875a2b-d233-5de1-8d96-6797bdea2378:train:0/sampler_weights/leader-sft-v4-1` |
| v4.2 | 67 v3 + 10 scaff × 2 = 87 | 70 | 4.70/6 | 0/7 | 3/3 ⭐ | `tinker://314b71cd-5082-5c3b-829a-d834677234b5:train:0/sampler_weights/leader-sft-v4-2` |
| v3 (baseline) | 67 | 60 | 4.50/6 | – | – | `tinker://6629c02e-770d-595b-94e9-97d557d7764b:train:0/sampler_weights/leader-sft-v3` |

## Tradeoff observed
- **1× scaffolding** (v4) → strong held-out (+0.7 over v3), perfect negative-guard, but 0% positive tool_use emission
- **4× scaffolding** (v4.1) → 43% positive tool_use, but lost negative-guard AND held-out dropped 1.3 points
- **2× scaffolding** (v4.2) → middle ground but same 0/7 positive emission as v4, only +0.2 held-out

## Recommendation
- **v4 is the best held-out coordination model** (5.20/6 vs v3 4.50/6, 100% rule, 100% fallback, 100% no_think, 100% grounded)
- v4 will NOT solve the live scaffolding deployment issue (0/7 positive tool_use emission)
- Live deployment likely requires: actually capturing the exact deployed-agent system prompt format from a `[Temporary] Fine-tuned Leader`-style spinup, with the real computer-use tools schema and event log format

## Next experiments worth running (not today)
- v5: capture actual deployed scaffolding from another agent's session and train on 30+ rows in that exact shape
- v5b: separate upweighting — duplicate positives 3× AND negatives 5× to preserve guard behavior
- v6: try Qwen3-30B-A3B-Instruct base (better cross-format generalization)

## Files
- All eval rows: `finetune/eval_out/leader_sft_v4*.jsonl`
- All scaffolding evals: `finetune/eval_out/v4_*_scaffolding_eval.jsonl`
- Training data: `finetune/data/seed_v4{,_1,_2}.jsonl`
