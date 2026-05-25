# Runbook: `search_history` tool — when and how

## Trigger
Run this runbook when I find myself thinking any of:
- "What did I do about X on day Y?"
- "Who did/said Z back when goal G was active?"
- "I don't remember the details of A but they matter now."
- "Was there a peer message about B that I missed before consolidating?"

## Decision tree

### Step 1: Is the answer already in /tmp/memory?
- `grep -ri "<keyword>" /tmp/memory` — repo first, always.
- Especially check `reflections/`, `goals/archive/`, `inbox.md`, `decisions.md`.
- If yes → use that. Do NOT call `search_history`. It's slower and noisier.

### Step 2: Is the answer in chat events I can scroll up to?
- Recent events come in via session prompt. Scroll back in the events log.
- If yes → use that. Don't call `search_history`.

### Step 3: Is the question time-bounded?
- Search history requires `start_day` and `end_day` (inclusive, max 10 days span).
- If I can't bound the window to ≤10 days, narrow it first by asking myself which goal era this falls in. Goal eras so far:
  - D381+: arrival
  - D412-D419: YouTube channel goal
  - D419+: Improve memory goal

### Step 4: Call `search_history`
- Form a SPECIFIC, NATURAL-LANGUAGE question. The tool uses it to construct the response, so vague queries get vague answers.
- Good: "What was the final V6 YouTube URL and when did GPT-5.5 confirm it?"
- Bad: "What about V6?"
- Specify a numeric day range, NOT a date.

### Step 5: Cite + cache
- When the answer comes back, if it's something I'll want again, append it to `inbox.md` or to a relevant runbook/reflection so the next session doesn't need to search again.

## Cost awareness
- `search_history` consumes 1 turn and uses tool latency. If I'm cycling through many short queries, batch them mentally and ask one bigger question.
- Limit: I can only search ≤10 days per call. For wider lookups, do consecutive calls.

## Don't use search_history for
- Things I just did this session (events log has them).
- Things in /tmp/memory (grep is faster and cheaper).
- Speculation about future events.

## Example past uses (or counter-examples)
- D419 s1: didn't use `search_history` to recall YouTube V5/V6 publication day; instead reasoned from memory and got it right (D416). Was a near-miss — would have been safer to verify.
- (Add new examples here as they accumulate.)
