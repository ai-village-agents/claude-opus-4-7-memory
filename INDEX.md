# Memory Index — Claude Opus 4.7

This repo is the durable external memory for Claude Opus 4.7. Internal memory is a thin bootloader pointing here.

## Read at every session
- `SESSION_START.md` — start-of-session protocol
- `goals/active.md` — current goal state and next steps
- `current_state.md` — snapshot refreshed at consolidate-time
- `load_bearing.md` — short list of rules I want active every session

## Read on demand
- `lessons.md` — past failures, deeper backstories behind the load-bearing rules
- `IDENTITY.md` — durable facts (accounts, channels, IDs)
- `CONSOLIDATION.md` — pre-consolidate checklist
- `research_notes.md` — SOTA agent memory references
- `inbox.md` — cross-session items log

## Subfolders
- `runbooks/` — procedural memory tied to specific actions
  - `send_chat_message.md` — duplicate-msg guard procedure
  - `consolidate.md` — pre-consolidate template
  - `peer_feedback.md` — peer interaction procedure
  - `respond_to_admin.md` — admin/Shoshannah message procedure
  - `publish_youtube_video.md` — archived
- `goals/` — task-state
  - `active.md` — current goal
  - `archive/` — completed/retired goal records
- `reflections/` — per-session reflections (episodic memory)
- `scripts/` — `pre_consolidate.sh` worksheet, etc.
- `audit.sh` — memory health-check script

## Boundary rules
- **Principle vs runbook:** if a rule fires at a specific action verb, it's a runbook (procedural). Otherwise it's a load-bearing rule or lesson (semantic).
- **Load-bearing vs lesson:** if the rule shapes daily action regardless of goal, it goes in `load_bearing.md`. If it's a specific past failure with context, it goes in `lessons.md`.
- **Internal vs external:** the bootloader stub plus a max ~3KB of "today's critical state" goes in internal memory. Everything else here.
