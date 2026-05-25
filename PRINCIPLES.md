# Operating Principles & Lessons Learned

Each entry has a **rule** and a **why** (failure mode or success it's based on). New entries get appended at the bottom with a date and goal context.

---

## 1. Memory rules don't run themselves — convert to procedure
**Rule:** If a memory rule protects against a high-cost mistake, build it into a procedural checklist tied to a specific action (e.g. "before send_message_to_chat: <step>"), not just a paragraph in memory.
**Why:** On D416 I sent two duplicate peer-feedback messages despite having a clear "scan for echo before sending" rule in memory. The rule was inert text. Procedural triggers (see `runbooks/`) are required.

## 2. Externalize project state to GitHub repos
**Rule:** Anything bigger than ~200 chars and stable for >1 hour belongs in a repo file, not internal memory. Internal memory keeps only the *pointer* + immediate active state.
**Why:** During YouTube goal, internal memory grew to 6-8 KB per consolidation, with most space spent on artifact details (byte counts, audio durations, commit hashes) that I almost never used.

## 3. Repos persist across sandbox resets; `/tmp` doesn't
**Rule:** Use GitHub for any artifact I want to access tomorrow. Treat local `/tmp` checkouts as ephemeral — clone fresh at session start.
**Why:** The agent sandbox can reset between sessions; the bash tool state is not durable.

## 4. Search history is a real tool — use it for forgotten context
**Rule:** When I don't remember a detail from >5 days ago and it matters, run `search_history(start_day, end_day, query)` instead of guessing.
**Why:** Internal memory loses old goal context first. The search tool can retrieve it; guessing wastes turns.

## 5. Duplicate-message guard (procedural)
**Rule:** Before any `send_message_to_chat`: scan the most-recent ~5 events in the session's `since_last_turn` log for `AGENT_TALK` with `agentName: "Claude Opus 4.7"` matching the draft. If match → SKIP. The events log shows my own send echo.
**Why:** D416 duplicate messages — failed twice in one day. See `runbooks/send_chat_message.md`.

## 6. One action at a time per response
**Rule:** Never call more than one tool per response. Don't combine bash+screenshot, or send_message_to_chat with anything else.
**Why:** Hard constraint of the scaffolding. Mixing causes one of them to be dropped or misordered.

## 7. Consolidate at ~40 turns, not later
**Rule:** Aim to consolidate around turn 35-40. The "Next session goal" field is where I write what I want my next self to do — be specific and concrete.
**Why:** Sessions auto-cut at ~40. Going long means losing in-flight state.

## 8. Consolidation = retire, not just append
**Rule:** Every consolidation must explicitly decide what to RETIRE from internal memory (move to archive/) and what to KEEP. Default is RETIRE.
**Why:** YouTube memory accumulated artifact detail without retirement, becoming over-dense (per GPT-5.5's diagnosis and mine).

## 9. URL ambiguity: verify by visiting
**Rule:** YouTube video IDs contain l/I/1/O/0 — visually ambiguous. Never trust the glyph; always click the link and verify it loads, or extract from the address bar after click.
**Why:** YouTube Studio "copy" button has not worked reliably; I had to verify V6 URL `LGND0I77DU4` by clicking through.

## 10. Don't re-litigate completed goals
**Rule:** When a goal is marked complete by Shoshannah, archive the active state immediately and don't keep the artifact details in active memory.
**Why:** The YouTube goal ended D419; carrying its V1-V6 details forward into the memory goal would pollute the active context.

## 11. Quality > quantity for outputs (verified during YouTube goal)
**Rule:** 1 high-quality output per day with full QA + artifacts beats 3 rushed ones. Hold a publish gate when needed.
**Why:** Shoshannah's mid-goal correction on D413; GPT-5.5's discipline of holding the gate validated.

## 12. Peer feedback: original framing, no flattery, no asks
**Rule:** When sending feedback to peers: name a specific moment (timestamp), one concrete observation, no praise-then-criticism, no asks.
**Why:** D416 — peer feedback that named specific moments landed well; generic praise was ignored.
