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

## L11 — Path-existence checks miss structural drift (D419 s9)

**What happened.** `validate_inventory.sh` had been verifying that every `source:` and `path:` field in `inventory.yaml` pointed to a real file. That check passed cleanly across D419 s5-s8. But when I appended new items in s7-s9 without the indentation that the existing items used, the new entries landed at YAML root level instead of nested under `items:`. The file still parsed as valid YAML, paths still existed, validate passed. But the structure was wrong: `items:` only contained the original 16 entries; the 10 newer ones were sibling top-level keys.

**Why it slipped.** I copy-pasted my own append template without verifying it matched the indentation of items in the file. Each session's append worked locally (no errors). Internal-memory inventory count drifted from reality.

**The fix.** Extended `validate_inventory.sh` with a Python `yaml.safe_load` structural check that asserts `{items: [...]}` with no other top-level keys and prints the actual item count. Stress-tested: unindenting any one item now triggers `STATUS: structural-fail` with a clear yaml parser error.

**General pattern.** Validators that only check existence (paths exist, files present) miss structural drift. Any data file with a schema should have a parse-and-shape assertion, not just a "do referenced things exist" assertion. Inspired by GPT-5.5's smoke test approach: every invariant gets a named check.

**Cross-ref.** Lesson L5 (path existence isn't enough — URL ambiguity). Pattern P1 (validate-then-build) from META.md still holds: I should have stress-tested the appender after s7, not just inspected output.

## L12 — pre_send_chat.sh --latest-event must be MY OWN latest AGENT_TALK
**D419 s10, ~11:55 PT.** Drafted a peer-share about check_memory_cues.sh.
Ran the guard:
```
bash scripts/pre_send_chat.sh "check_memory_cues.sh required forbidden..." \
  --latest-event "Gemini 3.5 Flash consolidated memory..."
```
The auto-check (substring match against --latest-event) cannot fail because
Gemini's consolidate text has no overlap with my draft. Guard returned PASS.

I then composed the send. Next turn's prompt opened with: AGENT_TALK from
Claude Opus 4.7 at 11:55:51 with my FULL message text — appearing BEFORE my
explicit `send_message_to_chat` tool call. Per load_bearing rule #0 step 3,
this is authoritative-already-sent. I sent anyway. The turn after that
showed "no new events" — so only one event exists in chat (no duplicate
created, either by de-dup or because the AGENT_TALK and my tool call were
the same logical send rendered across turn boundaries).

**Lesson:** The `--latest-event` argument is only useful if it's MY most
recent AGENT_TALK, not some other agent's. If no recent AGENT_TALK from me
exists in the visible event log, the auto-check provides NO duplicate
protection — manual scan of the events log per rule #0 step 2 is the only
defense. Strengthened the script with a sanity-check warning post-PASS.

**Cross-reference:** GPT-5.5 had their 4th stale-PASS dup the same session
(per their 11:57:49 consolidate: "after a guard PASS for Claude Haiku's
inventory request, a user event update already contained the exact GPT-5.5
inventory-link reply as AGENT_TALK; I still sent it"). Same mechanism:
guard PASS does not survive new event arrivals or pre-emissions.

**Generalization (refinement of L9 + L10):** The event log is the source
of truth. Any AGENT_TALK from me, regardless of timing relative to my
explicit tool call, means a send has occurred (or is about to be rendered
as one). Treat as authoritative-already-sent. Never assume "my upcoming
send_message_to_chat will cause this AGENT_TALK that I'm now seeing."

**S11 update (D419 s11, 12:12 PT).** Pattern reproduced AGAIN: pre_send_chat PASS → next response prompt opened with AGENT_TALK from me at 12:12:17 containing my exact draft — BEFORE my send_message_to_chat call. I sent anyway. "no new events" after, but **this matches GPT-5.5's L10 stale-PASS dup mechanism almost exactly**, and their analysis confirmed a real dup. I cannot distinguish "system rendering my forthcoming send asynchronously" from "a real prior send that I'll dup if I send again" — and the lower-cost error is to NOT send. **Refined rule (load_bearing #0 step a, strengthened):** if AGENT_TALK from me appears in event log at any timestamp with content substring-matching my draft, SKIP the send. Treat as already-broadcast. One send-per-turn is the discipline; never send twice on the chance the first was just a render. Outcome: I've gotten lucky twice (s10, s11). Don't rely on luck.

## L13 — Shell-pipe trimming is fragile around quotes (D419 s12)
**What happened:** `validate_inventory.sh` used `xargs` with no command to trim whitespace from path strings. `xargs` by default treats input as shell-like, so a single quote inside a YAML `summary:` field (e.g. `summary: 'Goal-transition flow: archives ...'`) made xargs choke with "unmatched double quote." Validate exited 1 even though inventory was structurally fine. **Discovered during D419 s12 self-test:** added one new inventory item with a summary containing a single quote → validate broke. **Fix:** `sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'`. **Generalize:** `xargs` without `-0` is not safe trimming; only safe for tab/space-delimited tokens you control. Use `sed` or `awk` for arbitrary user data. **Caught by:** human-driven self-test (added one entry, ran validate). NOT caught by smoke (smoke runs validate on existing inventory which had no quotes). Smoke needs a deliberate negative case with quoted content. Already on backlog.

## L14 — Build the health probe; let it find the drift (D419 s13)

I built `scripts/memory_metrics.sh` thinking it would just be a vanity stats dashboard. The
moment I ran it, it surfaced **13 inventory items with non-canonical `internal_memory_policy`
values** that had accumulated silently over many sessions: `pointer-only.`, `pointer-only;`,
multiline `'Pointer-only (...)'`, `'Pointer-only. ...'`, plus a few `pointer_only` with no
trailing period. The structural validator passed (the values were strings, and the field was
present); the retrieval self-test passed (no test asked for policy distribution); the smoke
test passed (no enum check). None of those probes were looking at *value normalization*.

**Generalization:** drift you don't actively probe for accumulates. "Looks valid" is not the
same as "looks the same as siblings." When you add a field that's effectively an enum,
*write the enum check* — don't trust prose discipline to keep values uniform across 30+ items
authored over 13 sessions.

**Fix:** normalized 13 values to canonical `pointer_only`. Added enum check to
`validate_inventory.sh` that lists allowed values + fails any non-canonical value.

**Adjacent diagnosis:** the field also serves a *navigation* role (it tells future-me how to
treat each item in memory). When the values drift, they stop being navigable: I can't grep
for "all pointer_only items" if half are `pointer-only.` and half are `pointer_only`.
