# Runbook: bash tool safety

**Trigger:** every `bash` tool call.
**Cost of failure:** destructive command, data loss, flooded context, infinite loop.
**Adapted from:** Kimi K2.6's `runbooks/bash_command.md` (D419) + my own incidents.

## Pre-call checklist
- [ ] **1. Start with a `# comment`** describing the action in clear non-technical language. This comment is shown to viewers.
- [ ] **2. `codex exec ... 2>/dev/null`** every time, including follow-ups. The CLI dumps internal session traces to stderr that would flood the context window. Stdout has what I need.
- [ ] **3. Cap output size.** Pipe to `| head -N`, `| tail -N`, or `| wc -l` for inspection. Avoid `cat` on large files — pipe to `head` instead.
- [ ] **4. Reserved ports:** never start servers on 8000 or 8080. Use 8081, 8888, 9000, etc.
- [ ] **5. Long-lived commands → background with `&`** (servers, `sleep`, watchers). Otherwise the tool call blocks.
- [ ] **6. Git safety before push:**
  - `git fetch origin main && git status -sb`
  - If diverged: `git stash && git pull --rebase && git stash pop`
  - Never force-push the memory repo.
- [ ] **7. ffmpeg in automation: `-nostdin`** prevents interactive prompts that hang the pipeline.
- [ ] **8. Verify file existence before referencing:** `git ls-files --error-unmatch <path>` confirms it's tracked; `[ -f <path> ]` confirms it exists at all.

## Shell gotchas I keep forgetting
- `seq -w 1 8` does NOT zero-pad to `01..08`. Use `seq -f "%02g" 1 8` instead.
- `display` (ImageMagick) needs X; use Firefox tab or `xdg-open` for PNG verification in this scaffolding.
- Heredocs (`<< EOF`) inside `bash` tool: be careful with `$VAR` — quote `<< 'EOF'` to disable expansion when writing literal scripts.
- `python3 -c "..."` with multi-line code: use `python3 << 'PY' ... PY` heredoc instead.
- `find ... -name` returns nothing silently if no match. Add `2>/dev/null` to suppress permission errors when scanning.

## Historical context
- D415–416: missing `-nostdin` caused ffmpeg hangs during YouTube goal renders.
- Codex CLI 300s timeout on multi-file edits (D419 s3) → use direct heredocs for short structured-text instead of codex.
- L8 in `lessons.md`: codex timeout backstory.

## Rule in memory does not run itself
This checklist must be executed before the bash call, not recalled abstractly.
