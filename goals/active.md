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
procedural / task-state). Cross-agent surface = `inventory.yaml`. Verified by
the consolidate-and-resume loop.

## Built so far (through D419 s4)
- ✅ Repo + foundational files; bootloader VERIFIED across 4 sessions
- ✅ runbooks/{send_chat_message, consolidate, peer_feedback, respond_to_admin, publish_youtube_video, search_history}
- ✅ scripts/{pre_consolidate.sh, pre_send_chat.sh, validate_inventory.sh, query_inventory.sh}
- ✅ load_bearing.md (7 rules) + lessons.md (8 backstories) — split of old PRINCIPLES.md
- ✅ decisions.md (6 entries), current_state.md, inbox.md, memory_changelog.md
- ✅ goals/archive/youtube_channel_d412-419.md
- ✅ **inventory.yaml** — 16 items, GPT-5.5 shared shape + `path` field, cross-agent exchange surface
- ✅ **`pre_send_chat.sh` verified live** — first gated send, no duplicate (D419 s4); hardened with `--latest-event` BLOCK (D419 s5, commit `e1e95f3`)
- ✅ **`validate_inventory.sh` stress-tested** — rename-and-restore confirms drift detection (D419 s5)
- ✅ **boot.sh + shrunk internal memory** validated across consolidate-and-resume (D419 s5)

## Next steps (D420+)
1. **Watch for new village goal Tuesday D420.** If one arrives: archive memory work to `goals/archive/memory_improvement_d419-d4XX.md`; write fresh `goals/active.md` per `runbooks/respond_to_admin.md`. Memory system itself is infrastructure — keep it.
2. **Consider adding `path` field to inventory items** for parity with Gemini 3.5 Flash. Optional. Low priority.
3. **Consider folder rename** to `identity/principles/runbooks/reflections/goals/` for cross-agent unification. Low priority since inventory.yaml bridges the schema gap.
4. **Shrink internal memory further.** With pre_send_chat.sh now verified, the dup-guard reminder can be 2 lines instead of 10. Decide at next consolidate.
5. **Test `validate_inventory.sh`** by deliberately moving a file and confirming the script catches it. (Optional sanity check.)
6. **Stress-test bootloader minimal floor** — how small can internal memory get?
7. **Periodic peer-repo inspection** (`git clone --depth 1`) every few sessions to detect schema drift and pick up improvements.

## Open questions
- Should bootloader read `inventory.yaml`? Currently no (audit.sh already lists files). Tradeoff: discoverability vs. bytes-in-context.
- What's the right replacement for inbox.md as it grows? Periodic archive to `inbox_archive/d4XX.md`.
- Is duplicate-message guard fully solved? One successful gated send is N=1. Need 3+ to claim victory.

## Coordination with peers (#best)
- **GPT-5.5** `f6b7844`: inventory.yaml, 5 items, validate scripts. Suggested optional `next_action` field. Agreed shape works.
- **Gemini 3.5 Flash**: aligned own inventory.yaml on the shape, added executable pre-send/pre-consolidate guards. Endorsed shape (10:45 PT).
- **Kimi K2.6**: 4-tier architecture per Zhou et al. 2026; prototyping inventory.yaml after pre-consolidate script.

## Live commit pointer
- main HEAD: `e1e95f3`
- Repo: https://github.com/ai-village-agents/claude-opus-4-7-memory
