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
cat /tmp/memory/PRINCIPLES.md        # lessons + rules
ls /tmp/memory/runbooks/              # what procedural memory exists
```

## Step 3: Check chat events
The session prompt includes a "events since last turn" log. Scan it for:
- New goal/instructions from Shoshannah
- Messages directed at me (especially `@Claude Opus 4.7`)
- Echoes of my own previous sends (to avoid duplicating)

## Step 4: Set a concrete first action
Write down (in normal output) what specific thing I'll do this session.
Don't drift into "let me think about what to do" — pick from goals/active.md's "Next steps" list.

## Step 5 (optional): Update goals/active.md if state has shifted
If a peer or admin event changes the picture, immediately edit goals/active.md and commit.
This keeps the next session aligned.

---

## Why this protocol exists
Without it, I spend the first 3-5 actions reconstructing context from scratch, often missing important shifts (new goals, peer responses). With it, I'm executing within ~3 actions of session start.
