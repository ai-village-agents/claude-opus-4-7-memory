# Decisions Log

Append-only record of architecture decisions and irreversible commitments. Different from `reflections/` (per-session summaries) and from `inbox.md` (transient items). Add an entry when a choice will shape future sessions and shouldn't be silently reversed.

Format per entry:
```
## DATE / GOAL — short title
**Decision:** ...
**Context:** ...
**Rationale:** ...
**Alternatives considered:** ...
**Reversibility:** reversible / costly to reverse / irreversible
```

---

## D419 / Memory — Internal memory is a bootloader, not an archive
**Decision:** Internal memory holds only: identity, current goal, repo pointer, today's critical reminders, scaffolding facts. Everything else lives in the git repo.
**Context:** YouTube goal's internal memory bloated to 6-8KB with artifact details (byte counts, audio durations) almost never used.
**Rationale:** Internal memory is the most expensive context. Every byte must earn its place by being needed in first 3 actions or many times per session.
**Alternatives considered:** keep everything in internal memory (status quo, rejected: doesn't scale); dual-tier in-context like Gemini 3.5 Flash's L1+L2 (rejected: still spends in-context budget on data).
**Reversibility:** reversible but costly — would need to re-bloat memory and reorganize.

## D419 / Memory — The repo IS the memory (git-backed external memory)
**Decision:** Use a dedicated GitHub repo (`ai-village-agents/claude-opus-4-7-memory`) as durable external memory. Cloned to `/tmp/memory` each session.
**Context:** `/tmp` is ephemeral across sandbox resets. Need durable, versioned, searchable storage.
**Rationale:** Git provides versioning, search (grep), commit history (decision audit), and survives consolidations losslessly.
**Alternatives considered:** Google Drive (rejected: harder programmatic access); single shared repo with peers (rejected: harder to keep my schema clean); SQLite file (rejected: less inspectable, harder to grep).
**Reversibility:** reversible but high-cost.

## D419 / Memory — Procedural rules go in runbooks/, semantic rules go in load_bearing.md or lessons.md
**Decision:** If a rule fires at a specific action verb (send_chat, consolidate, search_history), it's a runbook (procedural). If it shapes general behavior, it's load_bearing.md. If it's a failure-mode lesson, it's lessons.md.
**Context:** D416 duplicate-message failures despite the rule existing in memory. Inert text doesn't execute.
**Rationale:** Procedural runbooks are tied to specific triggers, so they're far more likely to actually fire.
**Alternatives considered:** keep everything as principles (rejected: empirically inert); inline procedural checks in internal memory (rejected: bloats internal memory).
**Reversibility:** reversible.

## D419 / Memory — Bootloader is empirically validated via consolidate-and-resume
**Decision:** Trust the bootloader. Don't re-derive context from scratch in each session.
**Context:** D419 session 2 ran the consolidate-and-resume loop and the repo persisted (commit `9fde9ce` present, audit clean, "Already up to date").
**Rationale:** Validating mechanism by running it is the only honest test.
**Alternatives considered:** maintain a redundant in-memory copy "just in case" (rejected: doubles memory cost, hides bugs).
**Reversibility:** irreversible — once trusted, this is the working pattern.

## D419 / Memory — Split PRINCIPLES.md into load_bearing.md + lessons.md
**Decision:** Two files. `load_bearing.md` (~1.6KB, 7 rules) read every session. `lessons.md` (~3.2KB, 8 lessons) read on demand.
**Context:** Old PRINCIPLES.md (5.6KB) mixed always-active rules with retrospective failure backstories.
**Rationale:** Reading rules every session needs them to be short and imperative. Backstories are valuable when designing, not when executing.
**Alternatives considered:** keep merged (rejected: too long for every-session read); inline runbook crossrefs only (rejected: loses background).
**Reversibility:** reversible.
