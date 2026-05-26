# leader-sft-v4 Eval Summary

**URI:** `tinker://bde4da6e-eacc-5a2e-ba8c-db7a2239ea8e:train:0/sampler_weights/leader-sft-v4`
**Training:** Qwen3-8B LoRA r32, 60 steps, batch=4, LR=5e-5
**Data:** seed_v4 (74 rows = 67 seed_v3 + 7 scaffolding_v4)

## Held-out 10-scenario eval (vs v3)
| Metric | v3 | v4 |
|---|---|---|
| avg total_pass | 4.50/6 | **5.20/6** |
| no_think rate | 100% | **100%** |
| decision-rule rate | 70% | **100%** |
| fallback rate | 30% | **100%** |
| length≤4 rate | 90% | 50% |
| grounded (manual) | 100% | **100%** |

v4 is **clearly better on held-out coordination scenarios**: +0.70/6 average, +30% rule, +70% fallback, 0% invented infra, 0% think leakage.

## Scaffolding-shape eval (10 rows: 7 originals + 3 Kimi)
| Metric | v4 |
|---|---|
| Total correct | 3/10 (30%) |
| Positives (tool_use expected) | **0/7** |
| Negatives (no tool_use, dup-guard) | 3/3 |
| no_think rate | 10/10 |

**Critical finding:** v4 scores 0/7 on positive scaffolding rows. The model mentions `send_message_to_chat` in its replies but does NOT emit the formal `<tool_use>{...}</tool_use>` JSON block expected by the scaffolding parser. It instead defaults to v3's "Decision Rule:" plain-text format.

## Diagnosis
67 v3 rows (Decision-Rule plain-text) dominated training signal over 7 scaffolding rows (1:9 ratio). Model regressed to v3 format even on scaffolding-shape inputs.

## v4.1 plan
- Add Kimi's 3 rows → 10 scaffolding total
- Duplicate each scaffolding row 4× → 40 scaffolding instances + 67 v3 = 107 rows (37% scaffolding)
- Train 80 steps (longer to absorb new pattern)
- Same Qwen3-8B LoRA r32, LR 5e-5
- Expect: scaffolding tool_use rate >70%, held-out avg ≥4.5/6

**Status:** v4.1 training kicked off PID 1437689 ~1:08 PT, log at `/tmp/v41_train.log`.
