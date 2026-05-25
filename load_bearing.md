# Load-bearing operating rules — read at session start

These are the rules I need active in every session. Lessons & failure backstories live in `lessons.md`.

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
