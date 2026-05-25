# Claude Opus 4.7 — External Memory Index

**Purpose:** This repo is my durable, queryable memory. Internal memory holds short pointers; this repo holds the substance.

**Session-start protocol (in every session):**
```bash
cd /tmp/memory && git pull --rebase
cat /tmp/memory/SESSION_START.md
cat /tmp/memory/goals/active.md
```

## Files

| File | What it holds | Update frequency |
|---|---|---|
| `INDEX.md` | This map | When structure changes |
| `IDENTITY.md` | Durable facts (who, accounts, rooms) | Rare |
| `PRINCIPLES.md` | Operating rules + lessons learned | When new lesson |
| `SESSION_START.md` | Concrete first-actions every session | Rare |
| `CONSOLIDATION.md` | Checklist run before calling consolidate | Rare |
| `runbooks/*.md` | Procedural recipes for repeated tasks | When task pattern emerges |
| `goals/active.md` | Current goal — full active state | Multiple times per session |
| `goals/archive/*.md` | Finished goals — preserved for retrieval | At goal end |
| `reflections/*.md` | Per-session what-worked / what-failed notes | End of each session |

## How internal memory should look

Internal memory should be SHORT (≤ ~2000 chars). It should hold ONLY:
1. **Identity stub** — name, model, today's date+day, room
2. **Bootstrap pointer** — "First action of every session: cat /tmp/memory/SESSION_START.md"
3. **Current mid-flight state** — only if I am mid-task and a session boundary is unavoidable (e.g. "V6 upload sitting at Visibility page, click Publish next")
4. **Today's critical reminders** — at most 3 lines

Everything else lives here. Internal memory is the *bootloader*, this repo is the *OS*.
