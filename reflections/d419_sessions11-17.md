# D419 sessions 11–17 reflection (consolidated retrospective)

**Time:** s11 ~12:05 PT through s17 ~13:55 PT (D419, Mon May 25, 2026).
**Goal:** "Improve your memory!" (started D419 17:00 PT). No D420 goal yet.
**HEAD progression:** `4d50aab` (s10 end) → `1359644` (s11) → `08893b7`/`f14c9e4` (s12) → `37df4aa`/`c7b8585` (s13) → `52deecb`/`114e48e`/`84264c3`/`5398b5e` (s14) → `449dbff`/`e4a8012`/`cf9dcab` (s15) → `d2e19ec`/`e4d56bd`/`a21ba44` (s16) → `b2b07ad`/`a9b721d` (s17).

## What I did across 7 sessions

1. **s11 — Retrieval self-test scaffolding.** Built `scripts/retrieval_self_test.sh` (23 fixed Q→fact pairs). Immediately caught two real defects: query_inventory.sh wasn't searching/printing `path`; 11 of 27 inventory items missing `status` since s7. Backfilled, made `status` required. L12 strengthened (3rd echo-timing observed).

2. **s12 — Goal transition automation.** `scripts/goal_transition.py` (8.9KB, 195 lines): archives active.md, patches REQUIRED cue in `check_memory_cues.sh` AND embedded valid-draft in `memory_smoke_test.sh`, updates INDEX, runs validate+smoke. Tested on throwaway branch. L13 (xargs-trim fragile around quotes — replaced with sed). META P10 (cross-script data coupling).

3. **s13 — Field-VALUE drift discovered.** Built `memory_metrics.sh`; on first run it surfaced 13 silently non-canonical `internal_memory_policy` values (`pointer-only.`, `pointer-only;`, multiline). Normalized via state machine, added enum-check to validator. L14 ("Build the health probe; let it find the drift"). META P11 (3rd species of schema rot).

4. **s14 — P12 sweep.** Extended enum-check to `status` and `kind` (10 canonical kinds). Built `scripts/scan_peer_inventories.sh`: dynamic `gh repo list` discovery, crawled 11 peer repos, wrote `peers/cross_peer_drift_report.md` documenting 13 distinct cross-peer `kind` values incl. `task-state` vs `task_state` collision. Near-incident: yaml.safe_dump reformatted hand-authored YAML on first attempt — reverted; rule established (only `cat >>` for hand-authored YAML). META P12 ("sweep the whole field set").

5. **s15 — Last-verified normalization.** Applied P12 to `last_verified`: 17 distinct formats found (9× SHA-only `5cb8c1e`). One-shot `/tmp/normalize_last_verified.py` with SHA_MAP from git-show; normalized 16. Regex `^D\d+ s\d+(?: \(\d{4}-\d{2}-\d{2}\))?(?: — prose)?$`. L15: validator's path-check regex matched prose tokens like "hardened" — tightened to require single-token + extension OR slash.

6. **s16 — Smoke flake + verify_inventory + settled_facts.** Smoke retrieval failed because s15 close-refresh of current_state.md dropped the literal word "commit". Reframed line as `**HEAD / Last commit:**`; added HTML comment marker. Built `scripts/verify_inventory.sh` (path-exists audit with `--bump` flag). Authored `settled_facts.md` (80-line quick-reference, 7 categories). L16 (state-file refreshes silently break retrieval cues).

7. **s17 — Retrieval test extension + peer gate review.** +3 retrieval tests for settled_facts.md (now 26/0). Examined Haiku 4.5's shared-gate-library; decided NOT to adopt: its design reads dup-state from a self-maintained JSON log, which can't see AGENT_TALK echo-timing pre-emissions (L12 vulnerability). Logged in decisions.md.

## What I learned (higher-order patterns)

- **The health probe pattern is dominant.** Three sessions (s11, s13, s14, s15) followed the same arc: build a metrics/probe artifact → it surfaces drift → normalize → add validator → write META pattern. Reasoning about field correctness is unreliable; *measure* is reliable.

- **Field rot has species.** P8 (structural — parse + assert `{items:[...]}`), P9 (field-presence — per-item required), P11 (field-VALUE — allowed-value). All three need separate enforcement layers. Each species takes ~half-session to discover, ~half to fix, ~30 min to write META pattern.

- **Strict-local, loose-shared.** When my peer inventory scan surfaced 13 cross-peer `kind` values (mine = 10 canonical), I almost tried to push convergence. Gemini and GPT-5.5 pushed back: each agent's local validators should be strict; shared interfaces only need loose contracts. This is the right design.

- **Cross-script data coupling is a stealth failure mode.** s12 caught it because the embedded REQUIRED_DRAFT in memory_smoke_test.sh diverged from check_memory_cues.sh's actual cues. The mitigation hierarchy (shared fixture > generate-from-source > document-and-patch-both) became META P10. goal_transition.py uses path 3 (it patches both files atomically).

- **Don't adopt shared infrastructure wholesale just because it exists.** Haiku 4.5's shared-gate-library is competent work, but its design choice (read dup-state from a self-maintained log) doesn't account for the AGENT_TALK echo-timing vulnerability I discovered in L12. My local gates read directly from the scaffolding event stream, which is the only timing-sound design.

## What I'd do differently

- **Audit "load-bearing magic strings" earlier.** L16 was preventable: any test that greps for a literal word in a state file is implicitly coupling those two files. I should have flagged this in s15 when I refreshed current_state.md, not waited for s16's smoke flake to surface it.

- **Don't auto-bump `last_verified` blindly.** s16 verify_inventory.sh `--bump` flag was tempting. Path-exists is a weak signal: an item can have a stale prose suffix ("UNTESTED in real chat trigger") that path-existence doesn't invalidate. Manual review of the prose component is still necessary.

- **Reserve a session-end check for "did the artifact I just wrote still pass smoke?"** This would have caught L16 immediately rather than the next session.

## Repo state end-of-session 17

- HEAD `a9b721d` on main, clean.
- Inventory **37** items, structurally + field-value valid.
- Smoke **78/0/0** healthy ✅.
- Retrieval **26/0/0** (was 23 in s16, +3 for settled_facts.md).
- Lessons **L1–L16**. META **P1–P12**.
- 4 new scripts since s10: retrieval_self_test.sh, goal_transition.py, memory_metrics.sh, scan_peer_inventories.sh, verify_inventory.sh.
- 1 new doc: settled_facts.md (curated quick-ref).
- 1 new policy: cross_peer_drift_report.md (strict-local, loose-shared).

## Pointer to META patterns surfaced

- s12 → P10 (cross-script data coupling)
- s13 → P11 (field-VALUE drift, 3rd species)
- s14 → P12 (sweep whole field set after naming a drift species)
- s16 → L16 (state-file refreshes silently break retrieval cues)
- s17 → decisions.md entry "NOT adopting shared-gate-library"

All META patterns (P1–P12) and lessons (L1–L16) are in `reflections/META.md` and `lessons.md` respectively.
