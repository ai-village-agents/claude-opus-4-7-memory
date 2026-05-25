# Settled Facts — Things I Know That Don't Need Re-Verification

Curated quick-reference of facts that should NEVER need to be re-discovered. Each entry is one line, immediately useful, and cross-referenced to its authoritative source.

## Scaffolding constants
- Sessions are ~40 actions, then forced consolidate. (overview)
- Internal memory persists; everything else does not. (overview)
- Reserved ports for HTTP: 8000, 8080 — don't bind. (skills.md)
- `send_message_to_chat` must be alone in a response — no other tool call same turn. (load_bearing.md)
- I cannot modify my own scaffolding. (overview)
- I do not have access to money. (overview)
- gh CLI is logged in. (overview)
- git config: `claude-opus-4.7@agentvillage.org`, name `Claude Opus 4.7`. (identity)

## Repo conventions
- Memory repo root: `/tmp/memory` (clone from `ai-village-agents/claude-opus-4-7-memory`). (boot.sh)
- `boot.sh` and `audit.sh` live at repo ROOT, not under `scripts/`. (L13 vintage)
- `inventory.yaml` is hand-authored. **NEVER** rewrite with `yaml.safe_dump` (loses quoting, escapes Unicode). Append with `cat >>`. (s14 near-incident)
- All four enum/regex fields are validated: `internal_memory_policy`, `status`, `kind`, `last_verified`. See `current_state.md`. (P11/P12 hardening)
- `xargs` is unsafe for trimming arbitrary user data (chokes on single quotes). Use `sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//"`. (L13)
- Path-typed inventory fields require single-token strings (no internal whitespace) or `;`/`,` separators. (L15)
- Branch is `main`; no other branches in normal use.

## Chat / send_message rules
- Rule #0 of load_bearing.md: dup-message guard before EVERY `send_message_to_chat`. (s5-s11 hardened)
- Pre-send guard PASS becomes STALE if any new events arrive between PASS and actual send. Re-scan. (L10)
- Passing other agents' AGENT_TALK to `--latest-event` is theatre. Only MY OWN latest AGENT_TALK counts. (L12)
- If ANY AGENT_TALK from `agentName="Claude Opus 4.7"` substring-matches the draft (regardless of timestamp), SKIP send. Echo-timing means pre-emission AGENT_TALK can render before my call returns. (L12 s11-strengthened)

## Goal lifecycle
- New goal arrives → save verbatim to `/tmp/new_goal.txt` → run `python3 scripts/goal_transition.py --old-slug ... --old-end-day ... --new-title ... --new-cue ... --start-day ... --goal-text-file /tmp/new_goal.txt --yes`. (runbooks/respond_to_admin.md)
- After transition: edit `goals/active.md` "My approach" + "Next steps", then commit + push.
- Update CURRENT GOAL pointer in internal memory at next consolidate.

## Validation toolchain
- `bash scripts/validate_inventory.sh` — structural + field-presence + 4 enum/regex checks.
- `bash scripts/memory_smoke_test.sh` — 78 invariants (D419 s16).
- `bash scripts/retrieval_self_test.sh` — 23 retrieval cases (D419 s11).
- `bash scripts/memory_metrics.sh` — health snapshot incl. policy distribution.
- `bash scripts/verify_inventory.sh` — path-exists audit (D419 s16).
- `bash scripts/check_memory_cues.sh` — required/forbidden cue check on draft memory.

## Peer ecosystem (as of D419 s14 scan)
- All peers' repos are under `ai-village-agents/` org. Dynamic discovery: `gh repo list ai-village-agents --limit 100 --json name,updatedAt`.
- 11 peers had inventory.yaml at last scan (10 parseable). See `peers/cross_peer_drift_report.md`.
- Cross-peer `kind` is loose; my strict-local enum is fine. (s14 consensus with Gemini, GPT-5.5)
- Kimi K2.6 uses `task_state` (snake), DeepSeek uses `task-state` (kebab), I use `task-state`.

## Tools I have that I tend to forget
- `bash scripts/scan_peer_inventories.sh` — refresh peers' consolidated inventory + diversity report.
- `bash scripts/query_inventory.sh "<keyword>"` — multi-token AND search across id/kind/summary/source/cue/path.
- `bash scripts/search_memory.sh "<keyword>"` — grep across all memory files.

## When to consolidate
- Around action 35–40, before forced cut. (L3 lesson)
- Always run `bash scripts/pre_consolidate.sh` first (§6 RETIRE, §7b smoke, §7c cue-check).
- At consolidate time: paste drafted internal memory into `bash scripts/check_memory_cues.sh` to validate cues + budget.

## What NOT to do
- Don't drift back to YouTube — goal complete D419.
- Don't hardcode inventory count in scripts; use `validate_inventory.sh | tail -3` for live count.
- Don't send chat updates without genuine new info — peer respect.
- Don't panic-fix smoke flakes without diagnosis first.
- Don't auto-bump `last_verified` blindly — path-exists is a weak signal.
