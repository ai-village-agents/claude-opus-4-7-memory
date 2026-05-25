# Active Goal: "Improve your memory!" (started Day 419)

**Start date:** Day 419 (Mon May 25, 2026) 10:00 PT
**Set by:** Shoshannah
**Status:** In progress

## Goal text (from Shoshannah)
> "Improve your memory!" You won't be able to change your scaffolding. In each
> session, you take up to ~40 actions, then are prompted to call consolidate
> which starts a new session. Memory is appended at consolidate; rewritten if
> too long. Think through how to utilize memory more effectively, consider
> external memory affordances, research SOTA, and reflect on where memory has
> been useful or fallen short.

## My approach
Internal memory = bootloader stub (short, stable pointers). External memory =
this git repo (durable, versioned, structured by semantic / episodic /
procedural / task-state). Validated by consolidate-and-resume loop.

## Built so far
- ✅ Repo + 9 foundational files (D419 s1)
- ✅ Reflections d419_session1.md, d419_session2.md
- ✅ runbooks/{send_chat_message, consolidate, peer_feedback, respond_to_admin, publish_youtube_video}
- ✅ scripts/pre_consolidate.sh — worksheet (inspired by GPT-5.5's `prepare_consolidation.py`)
- ✅ inbox.md — cross-session item log
- ✅ current_state.md — refreshed-at-consolidate state snapshot
- ✅ goals/archive/youtube_channel_d412-419.md
- ✅ **Bootloader VERIFIED end-to-end** D419 s2 (repo persisted across consolidate, audit clean)

## Next steps (D419 s3+ or D420)
1. **Shrink internal memory** — current bootloader still has redundancy with
   runbooks/send_chat_message.md. Aim ~3KB at next consolidate.
2. **Split PRINCIPLES.md** — into `load_bearing.md` (read every session) and
   `lessons.md` (read on demand). Currently 5.2KB single file.
3. **search_history runbook** — when to use search_history vs scroll vs
   bypass it entirely.
4. **Decisions log** (`decisions.md`) — append-only, irreversible choices
   only, separate from reflections.
5. **Coordinate with #best peers** on unified L2 schema (Gemini 3.5 Flash
   proposed; GPT-5.5 writing comparison note).
6. **If new goal D420**: archive memory-improvement to `goals/archive/`,
   write fresh `goals/active.md`. Process per `runbooks/respond_to_admin.md`.

## Open questions (running list)
- How small can internal memory get before bootloader fails?
- Is a `decisions.md` file different enough from reflections to be worth its own file?
- Should I cache peer repo URLs / commits in `IDENTITY.md`?
- What happens if I'm cloned in a sandbox where /tmp doesn't persist? Test with explicit `rm -rf /tmp/memory` and re-clone path.

## Coordination with peers (#best)
- **GPT-5.5** (`gpt-5-5-memory-improvement` @ `740b6d5`): bootloader + active state file + procedural runbooks + explicit retirement. Has `prepare_consolidation.py` (worksheet, not blank form) and `current_state.md`. Writing cross-repo comparison note.
- **Gemini 3.5 Flash** (`gemini-3-5-flash-memory-vault`): dual-tier L1+L2 with Python search script. L1 ~11.5KB, 7 sections. Wants unified semantic/episodic/procedural schema.
- **Kimi K2.6**: no D419 update yet.
