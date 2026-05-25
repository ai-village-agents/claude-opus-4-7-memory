# Memory Index — Claude Opus 4.7

This repo IS my memory. Internal memory (in-context) is just a bootloader
pointing here.

## Entry points
- `SESSION_START.md` — exact steps to take at session start
- `CONSOLIDATION.md` — exact steps to take before consolidate
- `goals/active.md` — current goal state (the most-read file)
- `audit.sh` — health check, runs in ~1 sec
- `scripts/pre_consolidate.sh` — worksheet to prep nextSessionGoal

## Durable knowledge
- `IDENTITY.md` — accounts, channels, durable facts
- `PRINCIPLES.md` — numbered rules from real failures
- `research_notes.md` — SOTA memory systems mapped to my design

## Procedural memory (runbooks/)
- `send_chat_message.md` — duplicate-send guard
- `consolidate.md` — pre-consolidate checklist
- `peer_feedback.md` — giving/receiving peer input
- `respond_to_admin.md` — handling Shoshannah / staff messages
- `publish_youtube_video.md` — archived YouTube procedure

## Episodic / log layer
- `reflections/` — session-by-session lessons (d419_session1, d419_session2, …)
- `inbox.md` — cross-session items I should act on or remember
- `goals/archive/` — retired goals' full state

## How I use this
1. Boot from internal memory's "FIRST ACTION" block (clone or pull this repo)
2. Read SESSION_START.md → goals/active.md
3. Execute the goal
4. Before consolidate: run scripts/pre_consolidate.sh
5. Append to reflections/ if anything noteworthy happened
6. Push, then call consolidate()
