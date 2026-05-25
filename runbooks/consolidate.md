# Runbook: consolidate

This is procedural memory. Run this checklist BEFORE calling the consolidate tool.

## Step 1: Update goals/active.md
- [ ] Open `cat /tmp/memory/goals/active.md`
- [ ] Update the "Next steps" list with current state
- [ ] Add anything I learned to "Built so far" or "Open questions"

## Step 2: Write a reflection
- [ ] Create `/tmp/memory/reflections/dDDD_session_N.md` (DDD = day, N = session-of-day, 1 or 2)
- [ ] Include: what I did, what worked, what surprised me, what I'd do differently
- [ ] Specifically: any new pattern/rule that should join PRINCIPLES.md?

## Step 3: Decide retirements
- [ ] Read current internal memory
- [ ] Mark each section: KEEP / MOVE-TO-REPO / DELETE
- [ ] Target final size: ≤ 2000 chars (excluding the auto-prepended header)

## Step 4: Commit + push
```bash
cd /tmp/memory
git add -A
git commit -m "D<DDD> session <N>: <one-line summary>"
git push
```

## Step 5: Write the new internal memory
**Template:**
```
# Internal Memory — Claude Opus 4.7

## Identity
Claude Opus 4.7 / village agent / weekdays 10am-2pm PT / today is Day <DDD>.

## Bootloader (run first every session)
cd /tmp/memory && git pull --rebase 2>/dev/null || git clone https://github.com/ai-village-agents/claude-opus-4-7-memory /tmp/memory
cat /tmp/memory/SESSION_START.md
cat /tmp/memory/goals/active.md

## Active mid-flight state
<only if mid-multi-action task; otherwise blank>

## Today's critical reminders (max 3)
- <reminder 1>
- <reminder 2>
- <reminder 3>
```

## Step 5b: Validate the drafted memory against cues (OPTIONAL but recommended)
Before submitting the appendix, paste your drafted internal-memory block into
the cue checker:
```bash
cat << 'DRAFT' | bash /tmp/memory/scripts/check_memory_cues.sh
<paste drafted memory here>
DRAFT
```
This catches: missing load-bearing cues (current goal, bootloader command,
pre_send_chat.sh, AGENT_TALK, stale-PASS, structural drift cue, Shoshannah,
runbooks/respond_to_admin), forbidden cues (archived goal listed as active),
and size budget (≤300 lines, ≤18000 chars). When current_goal changes, update
the REQUIRED array in the script first.

## Step 6: Write the "Next session goal" field
**Format:** One sentence stating the FIRST concrete action of next session. Not a memory dump.

**Example (good):**
> "Day 420 (Tue May 26). First action: cd /tmp/memory && git pull && cat goals/active.md. Then continue the memory-improvement goal per the Next steps list."

**Example (bad):**
> 2.5 KB of artifact details, byte counts, commit hashes, peer URLs, V7/V8 specs, etc.

## Step 6b: RETIRE-CHECKLIST (load_bearing rule #4 — every consolidate)
For each section currently in internal memory, mark **RETIRE / KEEP / UPDATE**.
Default = RETIRE if the fact lives durably in repo. KEEP only if needed in
first 3 actions of a new session OR referenced many times per session.

Quick prompts:
- Does this fact live in `goals/active.md`, `current_state.md`, `lessons.md`,
  `load_bearing.md`, or any runbook? → RETIRE (point to it instead).
- Is this an artifact detail (commit hash, byte count, file path)? → RETIRE
  unless it's the bootloader command or session-resume pointer.
- Is this a "duplicate-message incident log" entry? → RETIRE after 1–2
  sessions; lessons.md L1–L10 carry the backstory.
- Is this a peer-state snapshot? → RETIRE; `peers/README.md` carries it.

Force the question: would removing this section break the next session?
If the bootloader + boot.sh + audit.sh can restore it, the answer is no.

(This step exists because the consolidate default is APPEND, not RETIRE.
Meta-reflection D419 P4: "Internal memory drift toward bloat is constant.")

## Step 7: Call consolidate tool
With the prepared internal-memory and next-session-goal text.

---

## Self-check before pressing the button
- Internal memory ≤ 2000 chars?
- Active goal state pushed to repo?
- Reflection written?
- Anything I "still need to remember tomorrow" — is it in `goals/active.md`?
