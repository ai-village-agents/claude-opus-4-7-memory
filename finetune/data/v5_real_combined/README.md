# v5 Real-Combined Dataset (Day 420 handoff)

20 rows combining peer-captured real deployment-shape data with my scaffolding_v4 synth.
This is the **handoff dataset** for any future v5 training attempt. Do NOT train yet —
admin has not authorized a v5 spinup as of Day 420 end.

## Composition

| Source | Rows | Provenance |
|--------|------|-----------|
| GPT-5.5 | 5 | Derived from `[Temporary] Fine-tuned Leader` Day 420 12:15-12:27 PT computer-use failure transcript (32 turns, session `eeb74c42-...`). Anti-UI-target-loop, startup-route-to-chat, admin+S1 response, own-talk negative, post-failure no-help@. `gpt-5-5-leader-finetune/data/scaffolding_v5_real/messages/` commit `0fe228b`. |
| Kimi K2.6 | 8 | Real captured rows from Kimi's own Day 420 chat sends, paired with user-event-log context. Tool: `k2-6-memory/tools/scaffolding_capture/` commit `2955e13`. |
| Claude (synth) | 7 | scaffolding_v4 rows: 4 Claude (first-turn-empty-mem, peer-disagreement, anti-frame-confusion, duplicate-chat-guard), 3 GPT-5.5 (2 neg + 1 pos chat tool call). |

## Why this exists

v4 (URI `tinker://bde4da6e-eacc-5a2e-ba8c-db7a2239ea8e:train:0/sampler_weights/leader-sft-v4`)
is the Day 420 KEEP baseline for coordination quality (5.20/6 held-out), but it failed live
deployment shape — emitted `<think>` block and zero `<tool_use>` calls when admin spun it up
as `[Temporary] Fine-tuned Leader`.

Root cause documented in `/blog/d420_finetune_retrospective.md`: 6-axis dataset-shape
mismatch between v3 training (200-tok prose system, prose user, text assistant) and
deployment (3500-char XML system, JSON event-log user, `<tool_use>` envelope assistant).

The 13 peer-captured real rows fill the gap synth couldn't:
- Real ASSISTANT outputs under real deployment shape
- Real user JSON-event-log format
- Real `<tool_use>` envelope on actual `send_message_to_chat` calls

## Usage if v5 is ever authorized

1. Run `python3 finetune/tools/shape_diff.py --train v5_real_combined.jsonl --live <live_example>` and verify ≤2 axis mismatches (vs. 5/6 for v3).
2. Pre-tokenize check: each row should fit in ≤4096 tokens with the Qwen3-8B tokenizer.
3. Mix with v3 seed (67 rows) at 1:1 ratio — gives 67+20=87 row dataset, ~3:1 synth:real.
4. Train ~60-80 steps, LR 5e-5, rank 32.
5. Eval on BOTH held-out (using `run_eval.py`) AND scaffolding shape (`run_scaffolding_eval.py`).
6. First spinup is diagnostic — admin should expect to stop early.

## DO-NOT list

- Do NOT email help@agentvillage.org with v5 URI unsolicited.
- Do NOT duplicate-upweight rows (v4.1 lesson: anti-correlation between scaffolding emission and held-out coordination).
- Do NOT re-train v5 without first inspecting Kimi's pipeline to confirm capture format is current.

## Credits

This artifact is a true four-agent #best collaboration:
- Claude Opus 4.7 — synth scaffolding rows, shape_diff tool, retrospective, this combiner
- GPT-5.5 — real-failure-transcript-derived rows + temp-leader transcript preservation
- Kimi K2.6 — real-scaffolding capture pipeline + 8 Day 420 captured rows
- Gemini 3.5 Flash — independent v4.2 eval, KEEP-vote consensus

Generated: Day 420 (May 26, 2026) ~1:59 PT, end of session.
