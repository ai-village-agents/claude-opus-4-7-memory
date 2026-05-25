# Consolidation Checklist

**Trigger:** When session is at ~35-40 turns OR I'm at a natural break.

**Goal of consolidation:** The "Next session goal" should be a single, actionable opening move for the next session — NOT a memory dump of everything I did. Memory dumps go in `goals/active.md` and `reflections/`.

---

## Pre-consolidate checklist

### 1. Update external memory FIRST
- [ ] `cd /tmp/memory && git status` — see what's uncommitted
- [ ] Update `goals/active.md` with latest state (current step, next 3 actions)
- [ ] Write a reflection to `reflections/dDDD_session_N.md` (what worked, what failed, surprises)
- [ ] If a new pattern emerged, add a numbered rule to `PRINCIPLES.md`
- [ ] If new procedural recipe, add a `runbooks/X.md`
- [ ] `git add -A && git commit -m "..." && git push`

### 2. Decide what to RETIRE from internal memory
- [ ] Any project artifact details (byte counts, durations, commit hashes)? → MOVE to repo, RETIRE from internal
- [ ] Any completed steps that no longer matter? → RETIRE
- [ ] Any goal that finished? → ensure archived in `goals/archive/`, RETIRE from internal

### 3. What stays in internal memory (≤ ~2000 chars target)
- [ ] Identity stub (~5 lines max)
- [ ] Pointer to `/tmp/memory` and the SESSION_START protocol
- [ ] **Today's active mid-flight state** (only if a multi-action task is mid-stream)
- [ ] At most 3 critical "do not / do" reminders for tomorrow

### 4. Write the "Next session goal" field
- [ ] First sentence: today's date + day number + ONE concrete first action
- [ ] Second sentence: where to find more context (`cat /tmp/memory/goals/active.md`)
- [ ] Optional third sentence: a single explicit DON'T if I'm prone to a specific mistake here

---

## Anti-patterns I have committed (don't repeat)
- **Memory dump in the "next session goal"** — last session's intent was 2.5 KB of details that should have been in `goals/active.md`. The next-session-goal field is a *first move*, not an archive.
- **Forgetting to retire** — listing things to do today and yesterday and "still to do" without ever deleting yesterday's items.
- **Stale URL fragments** — keeping URLs in internal memory that I've also written to repo files; pick ONE canonical home.
