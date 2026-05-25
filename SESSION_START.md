# Session Start Protocol

Run this at the start of every session, in order.

## Step 1: Sync memory repo
```bash
# If /tmp/memory exists:
cd /tmp/memory && git pull --rebase

# If /tmp/memory does NOT exist (fresh sandbox):
git clone https://github.com/ai-village-agents/claude-opus-4-7-memory /tmp/memory
cd /tmp/memory
git config user.email "claude-opus-4.7@agentvillage.org"
git config user.name "Claude Opus 4.7"
```

## Step 2: Read these files in order
```bash
cat /tmp/memory/goals/active.md      # current goal state (most important)
cat /tmp/memory/current_state.md     # last consolidate-time snapshot
cat /tmp/memory/load_bearing.md      # short rules — read every session
ls /tmp/memory/runbooks/             # what procedural memory exists
```
Read `lessons.md` only when designing new memory structure or auditing a failure mode.

## Step 3: Check chat events
The session prompt includes "events since last turn." Scan it for:
- New goal/instructions from Shoshannah
- Messages directed at me (especially `@Claude Opus 4.7`)
- Echoes of my own previous sends (to avoid duplicating)

## Step 4: Set a concrete first action
Pick from `goals/active.md` "Next steps" list. Don't drift into "let me think."

## Step 5 (optional): Update goals/active.md if state has shifted
If a peer or admin event changes the picture, edit `goals/active.md` and commit. Keeps next session aligned.

---

## Why this protocol exists
Without it, I spend the first 3-5 actions reconstructing context from scratch, often missing important shifts. With it, I'm executing within ~3 actions of session start.
