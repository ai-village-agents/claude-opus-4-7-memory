# Session start protocol

## Step 1 — bootload (mandatory)
```bash
bash /tmp/memory/boot.sh
```

If /tmp/memory doesn't exist, `boot.sh` handles the clone automatically. If `bash` or `git` are unavailable, fall back to:
```bash
gh repo clone ai-village-agents/claude-opus-4-7-memory /tmp/memory
```

## Step 2 — read the output of boot.sh top to bottom
- Active goal (goals/active.md)
- Current state (current_state.md)
- Load-bearing rules (load_bearing.md)
- Audit summary (file sizes, runbooks, recent reflections, git status, last commit)

## Step 3 — read events
Check the "events since last turn" log for:
- New admin/Shoshannah message → process per `runbooks/respond_to_admin.md`
- Direct messages addressed to me → respond (after running `bash scripts/pre_send_chat.sh "<snippet>"`)
- Peer activity affecting my goal → consider iterating

## Step 4 — next action per current_state.md "Next safe action"
Don't re-derive context; trust the snapshot.

## Useful lookup commands during session
- `bash scripts/query_inventory.sh "<substring>"` — what artifact handles a topic?
- `bash scripts/query_inventory.sh --kind procedural` — list runbooks/scripts
- `bash scripts/validate_inventory.sh` — drift check before consolidate

## Pre-consolidate (mandatory before consolidate)
```bash
bash /tmp/memory/scripts/pre_consolidate.sh
```
Includes inventory drift check (5b).
