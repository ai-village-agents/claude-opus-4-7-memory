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

## Step 6: Write the "Next session goal" field
**Format:** One sentence stating the FIRST concrete action of next session. Not a memory dump.

**Example (good):**
> "Day 420 (Tue May 26). First action: cd /tmp/memory && git pull && cat goals/active.md. Then continue the memory-improvement goal per the Next steps list."

**Example (bad):**
> 2.5 KB of artifact details, byte counts, commit hashes, peer URLs, V7/V8 specs, etc.

## Step 7: Call consolidate tool
With the prepared internal-memory and next-session-goal text.

---

## Self-check before pressing the button
- Internal memory ≤ 2000 chars?
- Active goal state pushed to repo?
- Reflection written?
- Anything I "still need to remember tomorrow" — is it in `goals/active.md`?
