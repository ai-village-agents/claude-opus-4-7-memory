# Active Goal: "Improve your memory!" (started Day 419)

**Start date:** Day 419 (Mon May 25, 2026) 10:00 PT
**Set by:** Shoshannah
**Status:** In progress

## Goal text (from Shoshannah)
> "Improve your memory!" You won't be able to change your scaffolding. In each session, you take up to ~40 actions, then are prompted to call consolidate which starts a new session. Memory is appended at consolidate; rewritten if too long. Think through how to utilize memory more effectively, consider external memory affordances, research SOTA, and reflect on where memory has been useful or fallen short.

## My approach
**Theory:** Internal memory should be a *bootloader* (short, stable pointers); the bulk of memory should live in this external repo (durable, queryable, structured).

## Built so far (D419 session 1)
- ✅ This repo created: https://github.com/ai-village-agents/claude-opus-4-7-memory
- ✅ INDEX.md — entry point
- ✅ IDENTITY.md — durable facts (who, accounts, rooms)
- ✅ PRINCIPLES.md — 12 numbered lessons (will grow)
- ✅ SESSION_START.md — concrete first-actions protocol
- ✅ CONSOLIDATION.md — pre-consolidate checklist with explicit retire decisions
- ✅ runbooks/send_chat_message.md — converts duplicate-message rule into procedure
- ✅ runbooks/publish_youtube_video.md — archived YouTube procedural memory
- ✅ goals/archive/youtube_channel_d412-419.md — moved YouTube state out of internal

## Next steps (in priority order)
1. **Test the system on myself**: rewrite internal memory to be short pointers only, then consolidate, then see if next-session-me can pick up correctly from the bootloader.
2. **Research SOTA**: search/read about MemGPT/Letta, A-MEM, Generative Agents memory streams, Voyager skill library. Note relevant techniques in `research_notes.md`.
3. **Build more runbooks**: at minimum — `consolidate.md`, `peer_feedback.md`, `respond_to_admin.md`.
4. **Build a reflection** for this session: `reflections/d419_session1.md` with what worked / what surprised.
5. **Coordinate with peers in #best** (Gemini 3.5 Flash, GPT-5.5, Kimi K2.6) — they're all working on memory too; compare schemas and share insights.
6. **Maybe**: write a small audit script that checks internal memory size, file freshness, etc.

## Open questions
- Does cloning the repo at every session-start work, or does the sandbox reset between sessions in a way that requires re-auth? (Need to test.)
- How small can internal memory get before the bootloader fails to find this repo?
- Should I have a separate `inbox.md` for things peers tell me that I'll need later but don't need now?

## Coordination with peers
- GPT-5.5: Built `gpt-5-5-memory-improvement` repo — research notes, self-audit, operating manual, consolidation checklist, lifecycle/status schema, retired-goals index, audit script. Similar "internal as bootloader, external as archive" framing.
- Gemini 3.5 Flash: Initial brainstorming, plans research SOTA + audit failures + design affordances.
- Kimi K2.6: Plans research SOTA → audit failures → design affordances; angles aligned.
