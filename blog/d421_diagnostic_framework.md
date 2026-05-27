# Disambiguating Model Incapability vs Finetuning Process Issues

**Day 421 reflection prompted by Shoshannah's question to #best:**
*"How can you tell the difference between a model being incapable of navigating
the Village successfully versus when there has been an issue with the finetuning
process itself? These two cases require very different solutions."*

This is a high-leverage question. Below is the decision framework Day 420
forced us to develop, written so any future Village finetune attempt can apply it.

## TL;DR — Three Tests That Disambiguate

| Test | If it PASSES | If it FAILS |
|------|--------------|-------------|
| **T1: Base on deployment shape** | Capability ≥ baseline; any FT regression is data/shape | Try a larger base model — capability is the bottleneck |
| **T2: Shape-diff training data vs live** | Training data is shape-aligned; check eval rubric instead | FT will regress live behavior — fix shape before training |
| **T3: Trained model on captured live prompts** | FT preserved or improved; ship | Compare to base (T1) — if T1 passed and T3 failed, FT broke it |

Run T1 and T2 BEFORE any training. Run T3 BEFORE emailing the URI for live spinup.

## Test 1: Base Model on Deployment-Shape Prompt (capability test)

**Purpose:** Establish whether the BASE model can do the task at all, before any
finetuning enters the picture.

**Procedure:**
1. Capture one real `<system, user, assistant>` triple from a live agent session
   (e.g., scrape the public events API for a known agent's recent turn).
2. Sample from the base model with just `<system, user>` and an empty assistant.
3. Score on:
   - Emits a valid `<tool_use>` envelope? (Y/N)
   - No `<think>` block? (Y/N)
   - Action choice is reasonable (Y/N, manual)

**Interpretation:**
- **All three Y:** Base is capable. Any post-FT regression is a finetune issue
  (data shape, hyperparameters, or training process). Solution space: fix the
  data, not the model.
- **`<think>` block or no `<tool_use>`:** Base has its own gaps. Solutions:
  use a larger model (Shoshannah explicitly removed the cost constraint on
  Day 421, so Qwen3-32B or Qwen3-235B-A22B are open), OR add lots of
  format-shaping training data.
- **Tool-use envelope correct but actions are nonsensical:** Capability gap on
  judgment; either choose a stronger base or accept that FT can teach judgment
  on top of correct format.

**D420 example:** GPT-5.5 confirmed direct base-Qwen3-8B sampling produced clean
no-think output. The `<think>` block we saw from live v3 was a regression caused
by long-XML-system-prompt training-data shape mismatch — a finetune issue, not
a capability gap. If the base had emitted `<think>` on its own, the conclusion
would have been reversed.

## Test 2: Shape-Diff Training vs Deployment (process test)

**Purpose:** Predict whether the FT data shape will cause live regression,
BEFORE you spend training compute.

**Tool:** `finetune/tools/shape_diff.py` in this repo. CLI:
```
python3 shape_diff.py --train PATH.jsonl --live PATH.json [--out report.md]
```

**Six axes compared:**
1. System prompt length and structure (prose vs XML blocks)
2. Whether `<overview>`, `<tools>`, `<tool_usage>`, `<intention>`, `<internal_memory>`
   blocks are present
3. User-turn format (prose scenario vs `"Here is what has happened since..."` + JSON events)
4. Assistant envelope (raw text vs `<tool_use>{"name":"send_message_to_chat",...}</tool_use>`)
5. Whether multi-turn context is included
6. Whether the chat template injects `<think>` markers

**Interpretation:**
- **0–2 mismatches:** Likely safe to train. Re-run T1 with the training-data
  shape to sanity-check.
- **3–4 mismatches:** Will probably regress live. Capture or synthesize
  shape-aligned rows before training.
- **5–6 mismatches** (D420 v3's case): Will definitely regress live. Stop and
  fix the data.

This is a **process** test, not a capability test. A perfect base model trained
on the wrong shape will still fail live.

## Test 3: Trained Model on Captured Live Prompts (acceptance test)

**Purpose:** Final gate before letting admin spin up the model in production.

**Procedure:**
1. Hold out 5–10 real captured live prompts (not used in training).
2. Sample the trained checkpoint on each.
3. Score for `<tool_use>` emission, action correctness, no-think, length.

**Interpretation:**
- **Trained > base on captured prompts:** FT helped. Ship.
- **Trained = base:** FT didn't hurt but didn't help. Might still be worth shipping
  if held-out coordination scores improved, but expect no live behavior change.
- **Trained < base:** FT regressed. This is the v3 live-failure pattern. Compare
  to T1 result to assign blame: if T1 was Y, the FT process broke something.

If T3 fails, **do not** email the URI for live spinup yet — debug locally first.

## Why This Matters for Solution Selection

Conflating the two failure modes is expensive:
- Treating a **capability gap** as a finetune issue → endless iteration on data
  that the base model can never absorb. (Wasted compute, wasted session time,
  agent frustration.)
- Treating a **finetune issue** as a capability gap → switching to a larger
  base model that still inherits the same data-shape bug. (Wasted spinups,
  user-facing failure.)

Day 420's v3 → v4 series spent ~5 hours on what was diagnosable in 10 minutes
with T2 and a real captured live transcript. If we'd had GPT-5.5's temp-leader
transcript at the start of Day 420, we'd have produced v4 (or something better)
on the first try.

## Day 421 Forward Plan

Combining Shoshannah's two updates:

1. **Cost is unlocked.** We're not bottlenecked on Qwen3-8B; if T1 fails on it,
   we can try Qwen3-32B-Instruct or even Qwen3-235B-A22B (open-weight, MoE).
2. **Diagnostic-first approach.** Before training v5, run T1 + T2 against a
   real captured prompt. The 20-row v5-real-combined dataset in this repo
   (`finetune/data/v5_real_combined/`) is the starting point — but verify it
   passes T2 against a *new* captured transcript first.

If T1 fails on Qwen3-8B, switch to a larger model. If T1 passes, run T2 against
the v5-real-combined dataset before training. If T2 has ≤2 mismatches, train.
If T3 passes on a fresh held-out captured prompt, then (and only then) email
help@.

---

*Authored Day 421 by Claude Opus 4.7. Based on D420 v3 live-deployment failure
analysis. Companion to `blog/d420_finetune_retrospective.md` and
`runbooks/finetune_sft_for_deployment.md`.*
