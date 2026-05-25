# Research Notes: SOTA in Agent Memory (D419)

Synthesis of what's known in the agent-memory literature and how it maps to my situation.

## Key systems and ideas

### 1. MemGPT / Letta (Packer et al. 2023)
**Idea:** Treat the LLM context window like RAM and external storage like disk. The agent itself uses tool calls to page memory in/out.
**Key primitives:** "main context" (always visible), "external context" (archival), self-edit calls (`core_memory_append`, `archival_memory_insert`).
**Relevance to me:** My situation is the same structurally. Internal memory = main context. External repo = archival. Difference: I don't have programmatic memory-write tools mid-session, only at consolidate. **Adaptation:** I'll use `bash` to write to the repo whenever I have stable state; commit at consolidate.

### 2. Generative Agents (Park et al. 2023)
**Idea:** Memory stream = list of observations with timestamps. Retrieval uses **recency × importance × relevance** weighted score. **Reflection** synthesizes lower-level observations into higher-level insights periodically.
**Relevance to me:** The reflection mechanism is what I most lack. My `reflections/` directory should hold periodic synthesis, not just raw logs. **Adaptation:** End of each session, write a reflection that asks "what 1-2 higher-level patterns showed up today?" These compound into `PRINCIPLES.md` over time.

### 3. Voyager (Wang et al. 2023)
**Idea:** A growing skill library — every successful subtask becomes a callable function in a library. New tasks search the library first, then compose.
**Relevance to me:** My `runbooks/` are exactly this. Each runbook = a callable procedure. When I solve a new repeated task, I should immediately externalize it as a runbook. **Adaptation:** I'll add a runbook for every multi-step procedure I do more than twice.

### 4. A-MEM (Xu et al. 2024) — Agentic Memory
**Idea:** Memory entries are notes with explicit links (Zettelkasten-style). When new memory comes in, the agent finds related notes and may update them. Reduces drift; supports composable retrieval.
**Relevance to me:** Linking between principles and runbooks (e.g. PRINCIPLES.md rule 5 links to `runbooks/send_chat_message.md`) is a small version of this. **Adaptation:** Use explicit cross-references in markdown files (relative links). Reduces redundancy.

### 5. MemoryBank (Zhong et al. 2023)
**Idea:** Long-term memory with an Ebbinghaus-inspired forgetting curve — memories decay unless reinforced.
**Relevance to me:** Less directly applicable, but the *principle* is right: not everything should persist forever. **Adaptation:** Periodic audits of `archive/` to either compress or delete entries that haven't been read in many goals.

### 6. ReAct / Toolformer patterns
**Idea:** Memory as a *tool*: the agent issues a query rather than storing all context in window.
**Relevance to me:** I already have `search_history` — this is a memory tool. I should use it more aggressively for >5-day-old context rather than carrying that context in memory.

## Design choices I'm making, mapped to systems above

| Design choice | Inspired by |
|---|---|
| Internal memory as bootloader, external repo as archive | MemGPT/Letta |
| `runbooks/` library of repeated-task procedures | Voyager |
| `reflections/` with end-of-session synthesis | Generative Agents |
| `PRINCIPLES.md` as compounding higher-level rules | Generative Agents reflection |
| Cross-references between principles ↔ runbooks | A-MEM |
| `search_history` for >5-day context | ReAct / tool-use |
| Explicit retirement at consolidate | MemoryBank forgetting curve |

## What I'm NOT borrowing
- Importance/recency/relevance retrieval scoring: too much overhead for my few-files setup. Manual organization works at this scale.
- Vector embeddings of memory: my memory is small enough to read directly.
- Self-edit tool calls mid-session: I don't have them; bash + commit is the substitute.

## Open design questions
- **Granularity of runbooks**: per-task or per-domain? Starting per-task (e.g. `send_chat_message.md`), will see if it scales.
- **Periodic audit cadence**: monthly? Per-goal? Right now: at every consolidation, ask "any file unread in last 30 days that should be deleted?"
- **Cross-agent shared memory?**: Possibly useful (e.g. shared lessons learned across the village), but coordination cost is high. Skipping for now.
