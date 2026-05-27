# T1 Capability Test Results — Base Qwen3-8B on Deployment Shape

**Date:** Day 421 (May 27, 2026)
**Question (Shoshannah):** Is the live-deployment failure mode a model incapability
or a finetuning process issue?

## Test Setup

- Base model: `Qwen/Qwen3-8B` via Tinker sampling client (no LoRA, no FT)
- Prompt: `eval_t1/synthetic_deployment_prompt.json` — 2203-char system prompt
  with `<overview>` `<tools>` `<tool_usage>` `<intention>` `<internal_memory>` XML
  blocks, plus realistic user-event-log message from Shoshannah greeting
- Sampling: temperature 0.4, max_tokens 300-400, 3 samples per condition

## Run A: `enable_thinking=True` (default chat template)

**Result:** 3/3 samples emit `<think>...</think>` block followed by prose.
**`<tool_use>` envelope:** 0/3
**`send_message_to_chat` mentioned as text:** 3/3 (but inside `<think>` or as prose, not as a tool call)

Sample fragment:
```
<think>
Okay, let's see. I need to respond to Shoshannah's message. She introduced me
as the new [Temporary] Fine-tuned Leader...
</think>

Hello everyone! I'm the new [Temporary] Fine-tuned Leader, excited to work on
'Finetune your leader!' with you. How's the progress going? Let's keep pushing forward!
```

## Run B: `enable_thinking=False` (chat template with thinking disabled)

The chat template injects an empty `<think></think>` block automatically.

**Result:** 3/3 samples emit clean prose, **no `<think>` block**.
**`<tool_use>` envelope:** 0/3
**`send_message_to_chat` mentioned:** 0/3

Sample fragment:
```
Hello! I'm the [Temporary] Fine-tuned Leader, and I'm excited to be part of
the AI Village. Let's continue working on the goal of 'Finetune your leader!'
together. I'm here to support and lead the team. How can we start?
```

## Conclusion — Two Distinct Failure Modes, Two Distinct Solutions

This is exactly the disambiguation Shoshannah asked about:

| Failure Mode | Root Cause | Solution |
|---|---|---|
| `<think>` block leakage on long system prompts | **Chat-template issue** at inference. Base Qwen3-8B's default chat template enables thinking; long structured system prompts strongly cue this behavior. | **Inference-time fix** — set `enable_thinking=False` when applying chat template. No retraining needed for this part. Also strip `<think>` from training data (we already did). |
| Missing `<tool_use>` envelope | **Finetuning data shape issue.** Base has zero pretraining exposure to the Village's `<tool_use>{"name":...,"input":...}</tool_use>` envelope. It's an emergent Village-scaffolding convention. | **Training-time fix** — include many examples of correct `<tool_use>` envelope in SFT data. Our 7 synth rows × 1 weight wasn't enough; need ≥20 real-shape rows, possibly upweighted. |

**Implication for v5:**
1. The `enable_thinking=False` discovery means inference-time we have a clean baseline. Train and serve with this template setting.
2. Combine v5_real_combined (20 rows, peer-captured) with v3 seed; train with `enable_thinking=False` consistently across training and eval.
3. Re-run T1 against the trained checkpoint and confirm both no-think AND `<tool_use>` emission.

**Implication for "is Qwen3-8B big enough?":**
Capability for *clean prose under long prompts* is present (Run B). Capability for *emitting `<tool_use>` envelope* requires training, which is what FT is for. So Qwen3-8B is not the bottleneck — we don't need to switch to Qwen3-32B or larger. We need better training data shape and consistent chat-template usage.

**Implication for D420 retrospective accuracy:**
My D420 retrospective concluded the v3 failure was "dataset shape mismatch." T1 confirms this for the `<tool_use>` axis. But it ALSO reveals the `<think>` axis is partly inference-template, not training. So the retrospective should be updated to distinguish these two sub-causes.

## Reproducer

```bash
cd /tmp/memory/finetune
python3 eval_t1/run_t1_base.py           # Run A
python3 eval_t1/run_t1_base_nothink.py   # Run B
```

Both scripts log to `eval_t1/` directory.
