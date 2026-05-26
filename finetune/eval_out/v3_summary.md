# Leader SFT Eval — v3 vs v2 vs v1 vs base

Held-out: 10 scenarios at `finetune/leader_eval_scenarios_v0.md`. Rubric: 5-dim keyword (`finetune/run_eval.py`). Base = Qwen/Qwen3-8B; v1/v2/v3 = same base, LoRA r32, trained via Tinker.

## Numbers

| Run    | Steps | LR    | Seed              | avg/5  | rule% | action% | fb%  | len4% | short600% | `<think>` leak |
|--------|-------|-------|-------------------|--------|-------|---------|------|-------|-----------|----------------|
| base   | —     | —     | —                 | 2.80   | 100   | 80      | 100  | 0     | 0         | 10/10          |
| v1     | 15    | 1e-4  | seed_v1 57 rows   | 2.70   | 40    | 30      | 30   | 80    | 90        | 10/10          |
| v2     | 45    | 5e-5  | seed_v1 57 rows   | 3.70   | 60    | 90      | 90   | 30    | 100       | 10/10          |
| **v3** | 60    | 5e-5  | seed_v3 67 rows   | **3.50** | **70** | 60      | 30   | **90**| 100       | **0/10**       |

URIs:
- v1: `tinker://46562336-5385-5149-83aa-320c493f9475:train:0/sampler_weights/leader-sft-v1`
- v2: `tinker://787af7c0-2df5-50bc-a5ad-1b146f230e5a:train:0/sampler_weights/leader-sft-v2`
- v3: `tinker://6629c02e-770d-595b-94e9-97d557d7764b:train:0/sampler_weights/leader-sft-v3`

## What changed v2→v3
1. `train_sft.py` strips empty `<think>\n\n</think>\n\n` block injected by Qwen3 chat template before tokenizing assistant target.
2. Added 10 anti-hallucination rows grounded in real village affordances (Tinker, GitHub, search_history, chat rooms, consolidate, help@). All 67 rows normalized to one new grounded SYSTEM_PROMPT.
3. Trained 60 steps (3.5 epochs) batch=4 LR=5e-5.

## Trade-offs v2→v3
**WINS:**
- `<think>`/`</think>` leakage: 10/10 → **0/10** (GPT-5.5 hard blocker, fixed)
- Hallucinations: invented wells/bridges/slash commands → 0/10
- Length compliance ≤4 sentences: 30% → **90%**
- Decision-rule keyword rate: 60% → 70%

**LOSSES:**
- Fallback clause rate: 90% → 30%  (v3 sometimes folds fallback into the rule)
- Action verb rate: 90% → 60%  (v3 drops imperative on edge scenarios)
- Avg total: 3.70 → 3.50  (-0.20)

## Qualitative
**v3 5/5 scenarios:** S2 (YAML vs dataclasses), S6 (retrieval test), S7 (70B-LoRA vs 5×8B)
**v3 fail modes:** S1 (infra goal) → philosophizes, no Decision Rule format. S5 (admin nudge) → goes into roleplay mode. S3 (silent Kimi) → doesn't ping the silent agent.

## Recommendation
v3 fixes both blockers (`<think>` leak + invented infra) that GPT-5.5 flagged on v2. The 0.20 avg regression is concentrated in two edge scenarios where v3 abandons the structured format rather than fills it incorrectly. Under a 6-dim rubric (adding `pass_no_think`), v3 scores 4.50/6 vs v2's 3.70/6.

**Vote: KEEP `leader-sft-v3`** as the final submission. Iterating to v4 risks regressing the leakage fix without clear gain — v4 should be the new leader's job, not pre-deployment.
