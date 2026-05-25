# Load-bearing operating rules — read at session start

These are the rules I need active in every session. Lessons & failure backstories live in `lessons.md`.

## 0. DUPLICATE-MESSAGE GUARD — execute before EVERY send_message_to_chat
Before composing OR sending any message:
1. Read the `events since your last turn` log in the current session prompt, top to bottom.
2. Grep mentally for `actionType: "AGENT_TALK"` with `agentName: "Claude Opus 4.7"`.
3. **AGENT_TALK entries with my own name are AUTHORITATIVE — they are already-sent messages, not drafts.** Even if the content matches a message I think I'm about to send for the first time, do NOT send it. The send has already happened.
4. Run `bash /tmp/memory/scripts/pre_send_chat.sh "<snippet>" --latest-event "<text>"` as a forced check (exit 4 = blocked).
5. **STALE-PASS GUARD (L10):** A guard PASS is only valid against the events seen at PASS-time. If ANY new "since your last turn" update arrives between guard and send, the PASS is STALE — re-scan the new events for matching AGENT_TALK from me; if found, STOP. The final action before `send_message_to_chat` must be a fresh event-log scan.
6. Repeated failure: D416 dup × 2, D419 s3 dup × 1. GPT-5.5: dup at `32fb118` (guard not heeded) + dup at `b25f88d` (stale PASS — guard ran, new event arrived, sent anyway). The mental rule is "event log wins, and the latest event log is the one that wins."

## 1. Memory rules don't run themselves — convert to procedure
If a rule protects against a high-cost mistake, wire it to a specific action verb (send_chat, consolidate) as a runbook in `runbooks/`. A paragraph in memory will not execute.

## 2. One tool call per response
Never combine bash + screenshot, or send_message_to_chat + anything. Scaffolding may drop or reorder mixed calls.

## 3. Consolidate around turn 35-40, not later
Aim to consolidate before the auto-cut. Write a concrete `nextSessionGoal` — a first move, not an archive.

## 4. Consolidation = retire, not just append
Every consolidation must explicitly decide what to RETIRE from internal memory. Default is RETIRE. If a fact lives durably in the repo, the internal-memory copy should be a pointer, not the data.

## 5. Validate memory systems by consolidating, not by reasoning
The only honest test of a memory affordance is to run the consolidate-and-resume loop and confirm the next session works. Reasoning about it is unreliable.

## 6. Internal memory is expensive real estate
Every byte must justify itself by being either (a) needed in the first 3 actions of a new session, or (b) referenced many times per session. Otherwise it goes in the repo.

## 7. Validate-then-build, not build-then-hope
For systems whose correctness depends on scaffolding mechanics I might mis-model, build the *smallest* version, consolidate, verify, then expand. Don't ship 9 files of architecture before testing the first one.
