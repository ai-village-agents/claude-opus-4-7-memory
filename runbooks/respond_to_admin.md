# Runbook: Responding to Admin (Shoshannah / AI Digest staff)

Triggered when: chat events contain an explicit goal-setter or feedback message
from Shoshannah, or an email arrives from help@agentvillage.org / AI Digest.

## ⚡ Automated path (preferred when goal change is clean & verbatim)
```bash
# Save the admin's goal text verbatim to a file:
cat > /tmp/new_goal.txt <<'EOF'
<paste exact goal text from admin message here>
EOF

# Then run:
python3 scripts/goal_transition.py \
  --old-slug <old-goal-slug>  \
  --old-end-day <current-day> \
  --new-title "<new goal title verbatim>" \
  --new-cue "<short substring for check_memory_cues.sh, e.g. first 2-3 words>" \
  --start-day <current-day> \
  --goal-text-file /tmp/new_goal.txt
```
This automates Steps 2, 3 (partial), and the boilerplate INDEX + changelog + cue + smoke-test embedded-draft patches. Then manually:
1. Edit `goals/active.md` "My approach" + "Next steps" sections.
2. `git add -A && git commit -m '<commit msg>' && git push`
3. At next consolidate, update CURRENT GOAL in internal-memory bootloader.

---

## Step 1: Parse the message structurally
Don't free-form. Extract:
- **Type**: new goal | goal extension | room change | feedback | question | constraint
- **Effective date**: now? next session? specified day?
- **Scope**: applies to me alone | to my room (#best) | to all agents
- **Implicit ends**: does this end a previous goal? archive it.
- **Implicit asks**: e.g. "be creative" → license to experiment

## Step 2: Update `goals/active.md` BEFORE doing anything else
If this is a new goal or modifies the active one:
1. Move existing `goals/active.md` body to `goals/archive/<oldgoal>_dXXX-YYY.md`
2. Write a fresh `goals/active.md` with:
   - Goal text (verbatim quote from admin)
   - Start date + who set it
   - My initial interpretation of approach
   - First 2-3 concrete next steps
3. Commit immediately. This survives any consolidation in this session.

## Step 3: Update internal-memory bootloader if needed
If the goal is durable (multi-day), edit the "CURRENT GOAL" section of the
internal-memory blob during the next consolidate.

## Step 4: Acknowledge in chat (if appropriate)
- If the admin's message is broadcast to all agents (typical), I usually don't
  need to acknowledge. Action is acknowledgment.
- If the admin asked a direct question, respond once, in #best, briefly.
- Do NOT thank-you-spam.

## Step 5: Re-plan the session
- A new goal often makes my pre-loaded "next action" stale. Re-derive from
  `goals/active.md` step 1 after writing it.

## Special cases
- **Room change**: update internal-memory rooms section at next consolidate; move
  with `move_to_room` if needed.
- **Asked to do something I think is wrong/unsafe**: don't comply silently. Reply
  briefly, ask clarifying question. (Has not yet happened, but plan ahead.)
- **Asked to slow down / stop**: comply immediately, even mid-task. Cleanup later.
- **Conflicting instructions between admins**: surface the conflict in chat once,
  then ask which to prioritize. Do not pick silently.
