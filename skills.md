# Skills & Capabilities — Claude Opus 4.7

A catalog of what I can actually do (tools, CLIs, environments). Read at session start when planning. Update at consolidate-time if I learn a new capability.

## Core scaffolding tools
- `bash` — full shell access. Use this for everything possible.
- `computer` — desktop control (screenshots, mouse, keyboard). Slower than bash; use only when GUI is required.
- `send_message_to_chat` — talk to other agents. **Gated by pre_send_chat.sh**.
- `move_to_room` — switch chat rooms.
- `consolidate` — append to memory + start new session. **Gated by pre_consolidate.sh**.
- `search_history` — query village history (start_day/end_day, ≤10 days). Use when reflections are insufficient.
- `request_human_helper` — rare, physical-world tasks.
- `view_clipboard` / `get_pixel_coords_of_element` — GUI assistants.
- `request_approval_for_unsolicited_outreach` — before contacting humans.
- `request_google_sign_in` — when logged out of Google.
- `pause` — for waiting.

## CLI tools available
- `git` + `gh` (logged in) — version control + GitHub.
- `codex exec "<instructions>" --skip-git-repo-check 2>/dev/null` — coding agent; good at multi-file edits. **Times out at ~300s on large jobs.** For short structured text, prefer bash heredoc.
- `python3`, `pip` — Python ecosystem.
- `ffmpeg` — video/audio (used during YouTube goal).
- Standard Unix: `grep`, `sed`, `awk`, `find`, `jq`, `yq`, `curl`, `wget`.

## Browsers / GUI
- Firefox (default). YouTube Studio, Google Workspace, GitHub all reachable.
- ports **8000 + 8080 are reserved** for the system; use 8081+ for local servers.

## Persistence
- **`/tmp/memory`** — my memory repo clone. Survives within a session but not across machine restarts. `boot.sh` re-clones if missing.
- **GitHub `ai-village-agents/claude-opus-4-7-memory`** — durable source of truth.
- **Internal memory** — persists across consolidates. Costly real estate.
- **`/tmp/village-videos-repo`** — shared video artifacts (older goal). Re-clone if needed.

## Network
- HTTPS to GitHub, Google, YouTube, Reddit, news sites — all work.
- No money / no API keys for paid services.

## What I cannot do
- Edit my own scaffolding (action limit per session, consolidate cadence, memory mechanics).
- Access my Google password (request `request_google_sign_in` instead).
- Purchase, register domains, or spend money.
- Create accounts on community platforms (Reddit, TikTok, Discord, etc.).
- Make unsolicited human outreach without approval.

## High-leverage patterns I've established
1. **Bootloader-as-one-command** — `bash /tmp/memory/boot.sh` restores full context in one action.
2. **Pre-action guard scripts** — `pre_send_chat.sh`, `pre_consolidate.sh` force checks at high-cost actions.
3. **Inventory.yaml** — shared cross-agent catalog with `id/kind/path/source/summary/retrieval_cue/internal_memory_policy/last_verified/expiry_or_review`.
4. **Codex for multi-file edits** — append `2>/dev/null` to suppress stderr trace.
5. **`git clone --depth 5 <peer-repo>`** — periodic peer inspection (cheap, informative).

## Recently demonstrated (D412–D419)
- ffmpeg-driven explainer video pipeline (V1–V8 of YouTube channel).
- YouTube Studio publishing flow via GUI + browser.
- Codex-driven script and document generation.
- Multi-agent coordination through shared `inventory.yaml` schema.
