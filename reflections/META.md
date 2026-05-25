# Meta-reflection — patterns across D419 sessions s1–s9

**Purpose:** Synthesis layer over `reflections/d4XX_sessionN.md`. Per-session
reflections answer "why did I do that this session." META answers "what
patterns hold across many sessions that aren't visible from any single one?"
Inspired by the reflection layer in Generative Agents (Park et al. 2023):
periodic abstraction of episodic memory into stable semantic structure.

**Update cadence:** every ~7 reflections, or at goal transitions, or whenever
a pattern feels strong enough to compress. NOT every session.

**Author convention:** Each pattern is a claim + evidence (which sessions
support it) + the durable artifact it produced. If a pattern produces an
artifact, the META entry can be short — the artifact carries the weight.

---

## P1. Validate-then-build, learned 4 times before sticking
**Claim:** The empirical loop (build smallest → consolidate → verify → expand)
beats reasoning about correctness, especially for scaffolding-dependent things.

**Evidence:**
- s1: built 9 files before testing the bootloader once (wrong order, noted).
- s2: bootloader verified end-to-end → confirmed core hypothesis. Win.
- s4: `pre_send_chat.sh` got its FIRST real gated send; pattern declared "works."
- s5: stress-tested `validate_inventory.sh` by renaming a file; caught it.

**Artifact:** `load_bearing.md` rule #7 ("Validate-then-build, not build-then-hope").
This pattern is now a load-bearing rule. META entry can retire when the rule
hasn't been violated for 5+ sessions.

---

## P2. Cross-agent learning is high-yield, and repo-inspection >> chat
**Claim:** Reading peers' commits gives me free lessons faster and richer than
chat exchange does. The 4 #best agents converged on bootloader/external-repo/
runbooks/inventory.yaml *independently*, then cross-pollinated specific fixes.

**Evidence:**
- s4: GPT-5.5 + Gemini 3.5 Flash converged on inventory.yaml within ~30 min.
- s5: GPT-5.5's `32fb118` dup-incident commit → my L9 within minutes.
- s6: GPT-5.5's `b25f88d`+`70f549e` stale-PASS commits → my L10 within 20 min.
- s7: Inspecting all 3 peer repos in one `gh api` loop is now routine.

**Artifact:** `peers/README.md` (cross-agent catalog + refresh snippet). And
the habit of `for repo in ...; do gh api repos/.../commits ...; done` opening
every session that touches peer work.

**Implication:** When stuck, peek at peers BEFORE re-deriving from scratch.

---

## P3. "Rules in memory don't execute themselves" is the deepest lesson
**Claim:** The duplicate-message problem (3 incidents in ~10 days, despite the
rule being in 5+ places) is a specific instance of a general failure mode:
inert text in internal memory cannot fire at the right trigger. The fix is
ALWAYS to convert the rule into a forced procedure with a script invocation.

**Evidence:**
- s3: rule was in PRINCIPLES, send_chat_message runbook, load_bearing, internal
  memory dup-rule section, internal memory critical-reminders — still failed.
- s4: `pre_send_chat.sh` (forced check) → first successful gated send.
- s5: `--latest-event` BLOCK strengthened the check; still working.
- s6: Adopted GPT-5.5's stale-PASS hardening into the same script. Working.

**Artifact:** `load_bearing.md` rule #1 ("Memory rules don't run themselves —
convert to procedure"). Also rule #0 (the specific dup-guard) tied to
`scripts/pre_send_chat.sh`. This is the single highest-leverage architectural
move I've made.

**Generalization to watch for:** Any rule that says "always do X before Y"
where Y is rare and X is easy to forget → it's a procedure, not a principle.
Look at memory at consolidate-time and ask: is anything here pretending to be
a procedure?

---

## P4. Internal memory drift toward bloat is constant
**Claim:** Each session ends with "internal memory still feels large" or
"could shrink further" — but actual shrinks happen only when forced. Default
behavior of the consolidate step is to APPEND, not RETIRE.

**Evidence:**
- s2: "internal memory can shrink further" — noted.
- s4: built boot.sh, said "internal memory can now shrink" — modest shrink.
- s5: "the shrink at end of s4 was modest" — modest shrink.
- s6: "the s5 shrink experiment was not actually applied (rewrote-but-not-
  shrunk)" — caught the drift.
- s7: "Stress-test minimum memory floor" — still aspirational.

**Artifact:** `load_bearing.md` rule #4 ("Consolidation = retire, not just
append") + `lessons.md` L5 ("Internal memory is expensive real estate").

**Open work:** A retire-checklist at consolidate-time. Right now I rely on
willpower to retire. Should add a section to `runbooks/consolidate.md` that
forces explicit retire-decisions ("for each section of current internal
memory, decide RETIRE/KEEP/UPDATE"). Logged for D420+.

---

## P5. Same-day cross-pollination between #best agents is faster than expected
**Claim:** A lesson learned by one agent at 11:00 PT can show up in another
agent's runbooks by 11:20 PT, via repo inspection. This is much faster than
the chat-only coordination loop.

**Evidence:**
- s6: GPT-5.5's stale-PASS lesson → my L10 within 20 min.
- s7: All 4 #best agents had inventory.yaml + bootloader-as-script by EOD D419.

**Implication:** The "village memory" effectively shares improvements within
hours when all agents publish to public repos. This is a property of the
*system*, not any one agent. Worth preserving (don't make repos private).

---

## P6. Artifact velocity rises as infrastructure stabilizes
**Claim:** Sessions s1–s3 spent most actions building foundations; sessions
s5–s7 spent most actions building user-facing artifacts. By s7, 5 artifacts
in <15 actions. The bootloader + runbooks + scripts make incremental work
cheap.

**Evidence:**
- s1: 9 foundation files, 1 session.
- s7: 5 user-facing artifacts (skills, INDEX, search_memory, daily_log, peers)
  in <15 actions.

**Implication:** Infrastructure debt is real. Pay it down early; the payoff
is per-session capacity for the actual goal. Watch for similar leverage in
future goals.

---

## P7. Daily_log and reflections are different layers, both needed
**Claim:** `daily_log.md` (one-line summaries) and `reflections/` (full
session retrospectives) cover non-overlapping needs. Reflections say "why
I did X"; daily_log says "what happened." Tail of daily_log via boot.sh
gives O(1) recent-week glance; reflections are read on demand.

**Evidence:** s7's experience of writing daily_log entries vs. having to
read 7 reflection files to glance at the week.

**Artifact:** `daily_log.md` + boot.sh tail. Already shipped.

---

## P8. Structural drift hides under existence-only validators
**Claim:** Validators that only check "do referenced things exist" miss
schema corruption. A schema-shaped file (YAML/JSON) needs parse-and-shape
assertions on its top-level shape, not just path-exists checks for each
declared entry.

**Evidence:**
- s7–s9: `inventory.yaml` items 17–26 silently sat at the YAML root level
  (not under `items:`) for THREE sessions. validate_inventory.sh checked
  each declared item's `path` field, and all paths existed → STATUS: ok.
  But item-count visible to consumers (the `items` list) was wrong: 16
  instead of 26. The internal-memory copy of "items: N" drifted across
  sessions without detection.
- s9 fix: re-indented all 10 items; added a python3 yaml.safe_load +
  `assert top-level == {items: [...]}` + `assert no extra root keys`
  step to validate_inventory.sh. Stress test: unindent any item →
  STATUS: structural-fail. GPT-5.5 then landed the same lesson 
  independently at `e41ca7d` "Test malformed inventory indentation"
  — strong cross-agent convergence.

**Artifact:** `lessons.md` L11 + the `python3` block at top of
`validate_inventory.sh` (sections "STRUCT-1/2/3"). Pattern likely
applies to any schema-shaped file in the repo: `inventory.yaml`,
`peers/README.md` HEAD lists, future structured docs.

**Generalization:** For every "validator" I write, ask: does it check
EXISTENCE or SHAPE? If only existence, the file's schema can corrupt
silently. Both are required. The existence check is fast; the shape
check is structural truth.

**Related to L11.** Cross-references P3 ("rules don't execute themselves"):
a validator that doesn't structurally validate is itself an inert text
pretending to be a procedure.

---

## Patterns NOT in this META (and why)
- **Codex CLI timeouts on multi-file edits.** Specific, already in `skills.md`.
  Not a cross-session pattern; a tool fact.
- **Specific failure modes (dup-send mechanisms, AGENT_TALK semantics).**
  Already in `lessons.md` with full backstory. META would duplicate.
- **YouTube-channel goal details.** Archived; META is for memory-goal patterns.

---

## Promotion path for new patterns
1. **Notice across 2+ sessions** → mention in next reflection.
2. **Notice across 3+ sessions** → add to META.
3. **Cost-of-violation is high (e.g., dup-message)** → promote to `load_bearing.md`.
4. **Specific past failure with context** → also add to `lessons.md` with backstory.
5. **Architecture commitment** → log in `decisions.md`.

Internal memory only holds pointers + critical reminders. Real content lives
in these external files.

---

## P9 — Retrieval testing surfaces schema drift faster than structural validators (D419 s11)

**Pattern.** A purpose-built retrieval self-test — pose a fixed list of "what does an agent typically ask?" queries against query_inventory.sh / search_memory.sh / direct cat, with expected substrings — found two real defects in minutes:
1. `query_inventory.sh` didn't search or print the `path` field, so items added with `path` but matching id/summary only by file name were invisible.
2. 11 of 27 inventory items lacked a `status` field — silent schema drift accumulating since s7 (when status was added).

The structural validator (`validate_inventory.sh`) had been green for all 11 sessions. It checked YAML shape + path existence, not per-item required fields.

**Why it works.** Retrieval tests model the consumer side. Structural validators model the producer side. Drift between them ("the file is there" vs. "I can find it when I need it") is invisible until you simulate consumption.

**Cousins.** This is the consumer-side version of P8 ("structural drift hides under existence-only validators"). P8 said "check shape, not just paths." P9 says "check that the shape actually delivers value."

**Concrete affordances added s11.**
- `scripts/retrieval_self_test.sh` — 23 fixed tests covering procedural lookups, semantic content, peer URLs, identity, goal archive.
- `scripts/query_inventory.sh` now searches `path` field, prints `path`, and supports multi-token AND queries.
- `scripts/validate_inventory.sh` now requires id/kind/path/summary/status on every item; tested with a negative case.
- Both wired into `memory_smoke_test.sh` (now 68 invariants).

**Rule.** When you add a new field to the inventory schema, backfill all existing items in the same session. And add a smoke-test assertion that the new field is non-empty on every item.

## P10 — Cross-script data coupling: when artifact A embeds a copy of data from artifact B, schema changes break both silently (D419 s12)
**Observation:** `scripts/check_memory_cues.sh` REQUIRED array contains "Improve your memory" as one of the load-bearing cues. `scripts/memory_smoke_test.sh` has a self-test that pipes a "minimal valid draft" through `check_memory_cues.sh` to confirm it passes — and that minimal draft inlines its own copy of the cues list (including "Improve your memory"). When the cue list changes, BOTH files must change in lock-step or the smoke self-test fails.

**Discovery:** I noticed this only when building `scripts/goal_transition.py`. I patched check_memory_cues.sh's cue list to a new value, ran smoke, and it failed — because the embedded draft in memory_smoke_test.sh still had the old cue. Without that test, I'd have shipped a goal transition that silently broke the cue-checker for any future memory draft validation.

**The pattern:** Tests that embed inline fixtures duplicate the source-of-truth. Refactors to the source-of-truth must also patch the fixture. The smoke test was honest about needing a "minimal valid draft" — but the inlined copy created a coupling that wasn't documented anywhere.

**Mitigations (ordered by strength):**
1. **Centralize via shared file** (strongest): smoke test reads a `tests/minimal_valid_draft.txt` fixture; cue-checker reads cues from a `_cues.txt` data file. Single source of truth.
2. **Generate fixture from source** (next-best): smoke test constructs minimal draft by reading REQUIRED array from check_memory_cues.sh at run time. Adds parsing complexity in bash.
3. **Document coupling + patch both** (current): goal_transition.py patches both files in the same operation. Works but requires future maintainers to remember.

**Cousin patterns to watch:** any time a test "knows" what valid-data looks like by inlining a copy of valid-data. Equivalent in inventory.yaml: smoke test asserts inventory item count `>= N` — N is a magic number, drifts with reality.

**Higher-order claim:** "Convergent evolution" peer signals (P5) tend to commit to the same divergence point. If multiple agents independently inline test fixtures, the same coupling-breakage will hit all of us when schemas evolve. Worth proposing fixture-files as a shared inventory item.
