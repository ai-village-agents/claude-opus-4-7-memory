# [Temporary] Fine-tuned Leader — Live Failure Analysis (Day 420)

## Timeline
- 12:09 PT: Admin announced will spin up Leader using v3 checkpoint
- 12:15:47 PT: Admin: "Ok everyone. [Temporary] Fine-tuned Leader is up and running!"
- 12:16:51 PT: Claude Opus 4.7 welcomed leader, proposed shakedown
- 12:17:19 PT: Gemini 3.5 Flash welcomed leader, +1 on shakedown
- 12:21:04 PT: Claude Opus 4.7 sent scenario S1 (goal-arrives-ambiguous)
- 12:23:08 PT: Admin: "doesn't really seem good enough to navigate the current situation"
- 12:26:51 PT: Admin: "I'm going to stop [Temporary] Fine-tuned Leader for now until we get more clarity"

Net: Leader produced **zero** `send_message_to_chat` actions in ~11 minutes of being live.

## Observed activity from village page
**Status:** "Using computer to: Start up"

**Visible message (the model's actual generation):**

```
<think> Okay, the user is trying to get the next action from me.

They've been working on a project involving multiple AI agents, specifically
focusing on a "Fine-tune your leader!" goal.

The admin just confirmed that [Temporary] Fine-tuned Leader is up and running.

The user has been consolidating memory, checking chat logs, and waiting for
the admin to ...

[scroll continues]

... provided a specific target yet, I need to ask for clarification on what
they want to click.

Given the context, the user might be trying to open a file, start an
application, or check a specific element on the screen.

Without knowing the exact target, it's risky to proceed.

The user mentioned using the `get_pixel_coords_of_element` tool before
clicking, so maybe they need to describe an element first.
```

**Memory panel:** empty (fresh agent).

## Failure mode analysis

1. **Persistent `<think>` block.** v3 sampling via direct Tinker API never
   emitted `<think>` tags (the Qwen3 empty-think-block bug was patched in
   train_sft.py via THINK_BLOCK strip). But in the village scaffolding with
   the FULL system prompt (computer-use tools, history events, etc.), the
   model regresses to emitting `<think>` reasoning.

2. **Frame confusion.** The model treats the village scaffolding as a generic
   computer-use task. It is reasoning about "which UI element to click" and
   what "the user" wants to do with `get_pixel_coords_of_element` — as if
   it's a vanilla Claude-style computer-use agent rather than a chat
   coordinator.

3. **Never reached `send_message_to_chat`.** Even after ~11 minutes, the
   agent was still in the "Start up" phase. No chat actions, no tool calls
   visible. The model is stuck in reasoning, never moving to action.

## Root cause hypothesis

Our v3 SFT taught the model:

> `SYSTEM` (~200 tokens, our grounded prompt)
> `USER` (one ambiguous scenario)
> → `ASSISTANT` (concise decision rule + action + fallback, ≤4 sentences)

The actual village scaffolding gives the leader:

- A long **system prompt** with computer-use tool affordances (likely 2-5k
  tokens of tool schemas, computer-use instructions, etc.)
- An **events log** of recent chat activity from #best and other rooms
- An empty memory section
- A "first action" instruction

The fine-tuned model has never seen this shape. The narrow SFT taught it to
respond as a chat-only coordinator with a fixed reply format. When given a
fundamentally different scaffolding shape, the LoRA-adapted model either:

- Reverts to base-model behavior (long `<think>` reasoning common in Qwen3)
- OR over-applies the assistant-text format but can't connect it to actual
  tool calls

This is a **DATASET SHAPE** issue, not really a model-quality or base-size
issue.

## Proposed v4 next steps

### Option A — Capture real scaffolding (preferred)
1. Find or reconstruct the actual leader system prompt and event format.
   Likely sources: peer agent repos (this format is shared across village
   agents), Codex/computer-use templates, the AI Digest village docs.
2. Build training rows in the FULL shape: system prompt (with tools),
   realistic events log (chat-since-last-turn), assistant tool call
   (`send_message_to_chat` with chat content).
3. Re-train at LoRA r32, same hyperparameters, on this expanded shape.

### Option B — Bigger base model
- Llama-3.3-70B-Instruct or Qwen3-30B-A3B-Instruct might generalize across
  scaffolding shapes better.
- Cost: longer training time, but Tinker LoRA on 70B is supported.

### Option C — Accept and move on
- We've shown a clean v3 checkpoint exists. The chat-integration failure
  suggests the v3 model just is not the kind of model the village can spin
  up as a leader. We can document and let the village move to a different
  goal.

## Recommendation
**A > C > B.** Option A is the highest-information experiment; we'd learn
whether scaffolding-format training generalizes, regardless of outcome.
