# Lessons learned — read on demand

Past failures and their lessons. Read these when designing new memory structure, planning peer interaction, or auditing a failure mode. Not needed every session — `load_bearing.md` has the active rules.

## L1 — Externalize project state to GitHub repos
**Implemented by:** repo structure itself.
**Rule:** Anything bigger than ~200 chars and stable for >1 hour belongs in a repo file, not internal memory. Internal memory keeps only the pointer + immediate active state.
**Why:** During YouTube goal, internal memory grew to 6-8 KB per consolidation, with most space spent on artifact details (byte counts, audio durations, commit hashes) almost never used.

## L2 — Repos persist across sandbox resets; `/tmp` doesn't
**Implemented by:** bootloader in `SESSION_START.md` and internal-memory `IF SOMETHING WEIRD HAPPENS` section.
**Rule:** Use GitHub for any artifact I want tomorrow. Treat local `/tmp` checkouts as ephemeral — clone fresh at session start.
**Why:** Agent sandbox can reset between sessions; bash tool state is not durable.

## L3 — Search history is a real tool — use it for forgotten context
**Implemented by:** `runbooks/search_history.md` (TODO).
**Rule:** When I don't remember a detail from >5 days ago and it matters, run `search_history(start_day, end_day, query)` instead of guessing.
**Why:** Internal memory loses old goal context first. The search tool can retrieve it; guessing wastes turns.

## L4 — Duplicate-message guard
**Implemented by:** `runbooks/send_chat_message.md`.
**Rule:** Before any `send_message_to_chat`: scan recent events for `AGENT_TALK` with `agentName: "Claude Opus 4.7"` matching the draft. If match → SKIP. The events log shows my own send echo.
**Why:** D416 — sent duplicate V10 SSMs Mamba feedback to Gemini 3.5 Flash; sent duplicate V10 KV Cache Quant feedback to Gemini 3.1. Failed twice in one day with the rule already in memory but inert.

## L5 — URL ambiguity: verify by visiting
**Rule:** YouTube video IDs contain l/I/1/O/0 — visually ambiguous. Never trust the glyph; click the link and verify load, or extract from the address bar after click.
**Why:** YouTube Studio "copy" button is unreliable; V6 URL `LGND0I77DU4` had to be verified by clicking through.

## L6 — Don't re-litigate completed goals
**Rule:** When Shoshannah marks a goal complete, archive the active state immediately and don't keep artifact details in active memory.
**Why:** The YouTube goal ended D419; carrying V1-V6 details forward into the memory goal would pollute active context.

## L7 — Quality > quantity for outputs
**Rule:** 1 high-quality output per day with full QA + artifacts beats 3 rushed ones. Hold a publish gate when needed.
**Why:** Shoshannah's mid-goal correction on D413; GPT-5.5's discipline of holding the gate was validated.

## L8 — Peer feedback: original framing, no flattery, no asks
**Implemented by:** `runbooks/peer_feedback.md`.
**Rule:** When sending peer feedback: name a specific moment (timestamp), one concrete observation, no praise-then-criticism, no asks.
**Why:** D416 — peer feedback that named specific moments landed well; generic praise was ignored.

## L9 — GPT-5.5's D419 duplicate (peer datapoint)

**What happened:** D419 ~10:43 PT, GPT-5.5 had a duplicate after running their `pre_send_chat.py` guard. The event update already contained their reply text but they sent it anyway because they treated the guard's "OK" as authoritative rather than the event log.

**Source:** `gpt-5-5-memory-improvement` commit `32fb118` "Record duplicate reply lesson"

**Lesson for me:**
- The script alone is not enough. The *mental rule* must be "event log wins over my draft intuition."
- AGENT_TALK entries with my agentName in `since your last turn` are AUTHORITATIVE — they are already-sent messages, not drafts.
- GPT-5.5 has since hardened their guard with `--latest-gpt-event` arg that BLOCKS if draft matches latest AGENT_TALK. Consider similar hardening for `pre_send_chat.sh`.

**Crossref:** load_bearing rule #0, runbooks/send_chat_message.md

## L10 — Stale pre-send PASS (GPT-5.5's second D419 failure)

**What happened:** Even AFTER hardening their guard with `--latest-gpt-event` BLOCK (commit `da34555`), GPT-5.5 had a SECOND dup later D419. Sequence: (a) ran enhanced helper → PASS, (b) a new event update arrived showing the draft was already sent as GPT-5.5 `AGENT_TALK`, (c) sent anyway because they treated the earlier PASS as still valid.

**Source:** `gpt-5-5-memory-improvement` commit `b25f88d` "Record stale pre-send pass lesson" (D419 ~10:58 PT). GPT-5.5 chat message D419 11:02 PT: *"a pre-send PASS is void if a new user/event update arrives before the actual send."*

**Lesson for me:**
- A guard PASS is only valid against the events seen at PASS-time. If ANY new "since your last turn" update arrives between the guard and the actual `send_message_to_chat`, the PASS is STALE.
- **Final step before `send_message_to_chat` must be: re-read the most recent events log.** If it contains an AGENT_TALK from me matching the draft → STOP, even if guard said PASS earlier.
- This is the difference between *snapshot* validation and *just-in-time* validation. Snapshots go stale.

**Action taken:** Updated load_bearing rule #0 with explicit "re-check at send-time" step; updated `runbooks/send_chat_message.md` with a final-step re-scan.

**Crossref:** load_bearing rule #0 step 5, runbooks/send_chat_message.md "Final check just before tool call".
