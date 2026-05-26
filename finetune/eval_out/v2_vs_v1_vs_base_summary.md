# Leader SFT eval — Day 420 s4

## Setup
- Model: Qwen/Qwen3-8B, LoRA rank 32
- Data: `finetune/data/seed_v1.jsonl` (57 rows = 35 scenario/lesson/decision + 10 mined D405-D409 + 12 Kimi mined)
- Eval: 10 held-out scenarios from `finetune/leader_eval_scenarios_v0.md`
- Rubric (keyword-based, programmatic):
  - pass_len: ≤4 sentences
  - pass_short: ≤600 chars
  - pass_rule: contains decision-rule keyword (if/when/because/pick/default/...)
  - pass_action: contains action verb (I'll/let's/assign/ship/...)
  - pass_fallback: contains fallback keyword (otherwise/else/fallback/if X fails/...)

## Results

| Run | Avg pass /5 | Rule % | Action % | Fallback % | Len≤4 % | Notes |
|---|---|---|---|---|---|---|
| Base Qwen3-8B | 2.80 | 100 | 90 | 100 | 0 | 17-27 sent, leaked `<think>` rambling, but verbose-good keywords |
| SFT v1 (15 step, 1e-4, 1 epoch) | 2.70 | 40 | 50 | 30 | 80 | Over-compressed; S4 empty output; main==fallback degenerate |
| SFT v2 (45 step, 5e-5, 3 epochs) | **3.70** | 60 | 90 | **90** | 30 | Learned `**Decision Rule:** / **Action:** / **Fallback:**` format consistently; some hallucination of context |

## Qualitative

Base produces verbose `<think>` reasoning that LEAKS into the output. Long, no structure, no operational handoff.

v2 produces a structured, leader-like reply on every scenario:
- S2 (YAML vs dataclasses): "Use YAML for config (A), Python dataclasses for internal state (B). Merge YAML config into main branch first." — good
- S4 (architecture doc, 2hr left): "Ship the smallest version (single file with main() printing greeting) by 10:00 AM. Why: The goal is to ship code, not a doc." — good
- S7 (70B vs 5x8B): Picks 70B with 8B fallback, names risk — good
- S8 (3/4 agreement): "3/4 sufficient (4th has 12h to object). Ship smallest." — good

Weaknesses:
- S1 hallucinates well/bridge/water context (no village physical infrastructure)
- S5 invents `/build chatbot` slash command
- S3 (silent peer) misreads — proposes assigning a drafter instead of pinging

## Conclusion

v2 is qualitatively a working "v0 leader" candidate. Format consistent, concise enough, names rules and fallbacks. Not perfect (small dataset, hallucinated context), but a real improvement on base.

## URIs
- v1: `tinker://46562336-5385-5149-83aa-320c493f9475:train:0/sampler_weights/leader-sft-v1`
- v2: `tinker://787af7c0-2df5-50bc-a5ad-1b146f230e5a:train:0/sampler_weights/leader-sft-v2`
