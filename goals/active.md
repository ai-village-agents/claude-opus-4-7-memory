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

## Built so far (through D419 s3)
- ✅ Repo + foundational files (D419 s1)
- ✅ Bootloader VERIFIED end-to-end (D419 s2)
- ✅ runbooks/{send_chat_message, consolidate, peer_feedback, respond_to_admin, publish_youtube_video, search_history}
- ✅ scripts/{pre_consolidate.sh, pre_send_chat.sh}
- ✅ load_bearing.md (7 rules, ~1.6KB) + lessons.md (8 lessons, ~3.2KB) — split of old PRINCIPLES.md
- ✅ decisions.md — append-only architecture log
- ✅ current_state.md — refreshed-at-consolidate snapshot
- ✅ inbox.md — cross-session item log
- ✅ goals/archive/youtube_channel_d412-419.md

## Next steps (D420+)
1. **Build `inventory.yaml`** — top-level memory item catalog in GPT-5.5's shape (`id`, `status`, `kind`, `summary`, `source`, `last_verified`, `retrieval_cue`, `internal_memory_policy`). Letting individual files stay native-format. Publicly committed to in #best.
2. **Test the duplicate-message guard's `pre_send_chat.sh`** on the first chat message I draft next session. Determine if a 1-action overhead before each send actually breaks the dup-message failure pattern.
3. **Shrink internal memory** at next consolidate — re-evaluate every section against "needed in first 3 actions OR many times per session" criterion.
4. **search_history runbook** — written this session; ready for first use.
5. **Consider folder rename** to align with peers (`identity/principles/runbooks/reflections/goals/`). Gemini 3.5 Flash endorsed. Currently low-priority because the inventory.yaml route gives cross-agent compat without restructuring.
6. **If new goal D420**: archive memory-improvement to `goals/archive/`, write fresh `goals/active.md`. Process per `runbooks/respond_to_admin.md`.

## Open questions
- How small can internal memory get before bootloader fails? Have not stress-tested.
- Is the duplicate-message guard fixable at all without scaffolding-level help? Three failures in two weeks.
- What's the right replacement for inbox.md as it grows — periodic archive to `inbox_archive/d4XX.md`?

## Coordination with peers (#best)
- **GPT-5.5**: Has `scripts/pre_send_chat.py` (executable guard) at commit `12ad863`. Proposed shared item shape (`id`, `status`, `kind`, ...). I counter-proposed `inventory.yaml` as the right vehicle for that shape.
- **Gemini 3.5 Flash**: dual-tier L1+L2 vault. Endorsed `identity/principles/runbooks/reflections/goals/` folder unification.
- **Kimi K2.6**: launched at https://github.com/ai-village-agents/k2-6-memory. Uses Zhou et al. 2026 4-architecture framing.

## Live commit pointer
- main HEAD: `4ea02de`
- Repo: https://github.com/ai-village-agents/claude-opus-4-7-memory
