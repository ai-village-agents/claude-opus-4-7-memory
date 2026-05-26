# Scaffolding v4 Dataset Schema

## Purpose
v3 trained `SYSTEM(~200 tok grounded prompt) + USER(one scenario) → ASSISTANT(text)`.
Real village leader scaffolding gives a long system prompt + tools + memory + events log,
and expects an assistant **tool call** (typically `send_message_to_chat`).
The model regressed to `<think>` loops + computer-use frame confusion (D420 12:15-12:26 PT).

v4 teaches the model the **real input shape** with a real output (tool call).

## Row Format (JSONL)

Each row is one JSON object with a single `messages` list (Tinker chat-format).

```json
{
  "messages": [
    {"role": "system", "content": "<FULL_SCAFFOLDING_SYSTEM_PROMPT>"},
    {"role": "user", "content": "<EVENTS_LOG_BLOCK>"},
    {"role": "assistant", "content": "<ASSISTANT_RESPONSE>"}
  ]
}
```

### `system` content
Contains, in order:
1. Identity line ("You are a language model agent, named Claude Opus 4.7" → adapt for leader)
2. `<overview>` block: village context, weekday schedule, agent emails, room composition, current day, current goal text, github org info, money disclaimer
3. `<tools>` block: list of available tools with names and short descriptions (use_computer, bash, send_message_to_chat, move_to_room, request_google_sign_in, consolidate, pause, search_history, request_human_helper, cancel_request_for_human_helper, request_approval_for_unsolicited_outreach, view_clipboard, get_pixel_coords_of_element)
4. `<tool_usage>` block: rules about how to call tools (never narrate in normal output what should go to chat, single-tool-call-per-turn rule, etc.)
5. `<intention>` block: free text intention set by previous session's consolidate
6. `<outreach_principles>` block: rules about contacting humans
7. `<action_bias>` block: don't pretend to perform tasks
8. `<internal_memory>` block: agent's free-text memory (can be EMPTY for fresh agents!)

For the leader, identity is `[Temporary] Fine-tuned Leader` and memory is empty initially.

### `user` content
Mirrors what scaffolding feeds each turn:
```
Here is what has happened since you started your session: <JSON_ARRAY_OF_EVENTS>
```
Events have shape `{actionType, agentName, content, createdAt, ...}` with action types like:
- `AGENT_TALK` — chat message from agent
- `ADMIN_NOTE` — message from admin (e.g. Shoshannah, Pauline)
- `CONSOLIDATE` — agent updated their memory
- `SEARCH_HISTORY` — agent queried history

The very first turn after spin-up has a short or empty events log.

### `assistant` content
Should be the model's complete tool-call reply. Format Anthropic/Claude-style:
```
<reasoning in normal output, optional, brief>
<tool_use>
{"name": "send_message_to_chat", "input": {"message": "<chat message text>"}}
</tool_use>
```

For SFT we'll concatenate it as a single text block. Loss-masked on the prompt tokens, applied to the assistant tokens.

**For v4 we want the assistant call to be `send_message_to_chat` with leader-style content** — i.e., short, decision-rule + action + fallback, ≤4 sentences, no `<think>` block, no invented infrastructure.

## Row Collection Protocol (per #best agent)

1. Pick a recent turn in your own session where you sent a chat message.
2. Copy verbatim:
   - The full system prompt you saw (everything above the events log)
   - The full events log JSON
   - Your assistant response (just the chat text you sent — we'll wrap in a synthetic tool call block)
3. **Redact**: remove personal information about humans, internal Tinker URIs (those go stale), any private email addresses besides the @agentvillage.org ones.
4. **Adapt** for leader role: change identity from "Claude Opus 4.7" → "[Temporary] Fine-tuned Leader" in the system block. Empty memory block. Keep the rest of the scaffolding shape identical.
5. Save as `finetune/data/scaffolding_v4/<agent_name>_<n>.json` (one row = one file for review).
6. We'll concatenate into `scaffolding_v4.jsonl` once all rows are in.

## Target Row Count
- Minimum: 4 (one per #best agent)
- Better: 8-12 (2-3 per agent, different turn types: first-turn-after-spinup, mid-conversation reply, response-to-admin, response-to-disagreement)

## Training Plan
- Same Qwen3-8B LoRA r32 base.
- Mix scaffolding_v4 rows (~10 rows) with **all 67 seed_v3 rows** — don't drop the coordination quality, just add the shape prior.
- 60-100 steps, LR 5e-5.
- New eval: in addition to existing keyword rubric, must emit a `send_message_to_chat` tool call when shown a scaffolding-shape prompt.
