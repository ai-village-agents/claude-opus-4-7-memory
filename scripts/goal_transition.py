#!/usr/bin/env python3
"""
scripts/goal_transition.py — Automate the new-goal flow.
Use when Shoshannah/admin announces a new village goal.

Usage:
  python3 scripts/goal_transition.py \\
    --old-slug memory_improvement \\
    --old-end-day 419 \\
    --new-title "Build a robot army" \\
    --new-cue "robot army" \\
    --start-day 420 \\
    --goal-text-file /path/to/new_goal.txt \\
    [--yes] [--unsafe-allow-any-branch]

Steps:
  1. Sanity: clean tree, on main (unless --unsafe-allow-any-branch).
  2. Derive old start-day from goals/active.md header.
  3. git mv goals/active.md -> goals/archive/{old_slug}_d{start}-d{end}.md
  4. Write fresh goals/active.md from template + verbatim goal text.
  5. Patch REQUIRED cue in scripts/check_memory_cues.sh
     ('Improve your memory' -> new_cue).
  6. Patch matching line in scripts/memory_smoke_test.sh embedded draft.
  7. Update goals/INDEX.md (move old active row to archived; add new active row).
  8. Append entry to memory_changelog.md.
  9. Run validate_inventory.sh + memory_smoke_test.sh.
 10. Print git status + next-step instructions.

Does NOT auto-commit. User reviews + commits.
"""
from __future__ import annotations
import argparse, datetime, pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]


def sh(cmd, check=True, capture=True):
    r = subprocess.run(cmd, shell=isinstance(cmd, str), cwd=ROOT,
                       text=True, capture_output=capture)
    if check and r.returncode != 0:
        sys.stderr.write(r.stdout or "")
        sys.stderr.write(r.stderr or "")
        sys.exit(r.returncode)
    return r


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--old-slug", required=True)
    ap.add_argument("--old-end-day", required=True, type=int)
    ap.add_argument("--new-title", required=True)
    ap.add_argument("--new-cue", required=True)
    ap.add_argument("--start-day", required=True, type=int)
    ap.add_argument("--goal-text-file", required=True)
    ap.add_argument("--yes", action="store_true")
    ap.add_argument("--unsafe-allow-any-branch", action="store_true")
    a = ap.parse_args()

    goal_text_path = pathlib.Path(a.goal_text_file)
    if not goal_text_path.is_file():
        print(f"FAIL: goal text file not found: {a.goal_text_file}")
        return 2

    # --- sanity ---
    print("=== Sanity ===")
    porcelain = sh(["git", "status", "--porcelain"]).stdout.strip()
    if porcelain:
        print("FAIL: working tree dirty. Commit or stash first.")
        print(porcelain)
        return 1
    branch = sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]).stdout.strip()
    if branch != "main" and not a.unsafe_allow_any_branch:
        print(f"FAIL: not on main (got {branch}). Use --unsafe-allow-any-branch for testing.")
        return 1

    active = ROOT / "goals" / "active.md"
    if not active.is_file():
        print("FAIL: goals/active.md not found.")
        return 1

    # Derive old start day from active.md
    m = re.search(r"Day (\d+)", active.read_text())
    old_start_day = int(m.group(1)) if m else a.old_end_day

    archive_rel = f"goals/archive/{a.old_slug}_d{old_start_day}-d{a.old_end_day}.md"
    print("Plan:")
    print(f"  Archive: goals/active.md -> {archive_rel}")
    print(f'  New active.md title: "{a.new_title}"')
    print(f"  REQUIRED cue: 'Improve your memory' -> '{a.new_cue}'")
    print(f"  INDEX update + memory_changelog append")
    print()

    if not a.yes:
        ans = input("Proceed? (yes/N) ").strip()
        if ans != "yes":
            print("Aborted.")
            return 0

    # 1. archive
    (ROOT / "goals" / "archive").mkdir(parents=True, exist_ok=True)
    sh(["git", "mv", "goals/active.md", archive_rel])
    print(f"Archived: {archive_rel}")

    # 2. write new active.md
    goal_text = goal_text_path.read_text().rstrip() + "\n"
    quoted = "\n".join("> " + line if line else ">" for line in goal_text.splitlines())
    active.write_text(
        f'# Active Goal: "{a.new_title}" (started Day {a.start_day})\n'
        f"\n"
        f"**Start date:** Day {a.start_day}\n"
        f"**Set by:** Shoshannah\n"
        f"**Status:** In progress\n"
        f"\n"
        f"## Goal text (verbatim from admin)\n"
        f"{quoted}\n"
        f"\n"
        f"## My approach\n"
        f"TBD — fill in this session.\n"
        f"\n"
        f"## Next steps\n"
        f"1. TBD\n"
        f"2. TBD\n"
        f"3. TBD\n"
    )
    print("Wrote: goals/active.md")

    # 3. patch check_memory_cues.sh
    cues = ROOT / "scripts" / "check_memory_cues.sh"
    ct = cues.read_text()
    if '"Improve your memory"' in ct:
        ct = ct.replace(
            '"Improve your memory"            # current goal',
            f'"{a.new_cue}"  # current goal (D{a.start_day}+)',
        )
        cues.write_text(ct)
        print("Updated REQUIRED cue in scripts/check_memory_cues.sh")
    else:
        print("WARN: 'Improve your memory' line not found in check_memory_cues.sh — manual edit needed.")

    # 4. patch memory_smoke_test.sh embedded draft line
    smoke = ROOT / "scripts" / "memory_smoke_test.sh"
    st = smoke.read_text()
    if "Improve your memory" in st:
        st = st.replace("\nImprove your memory\n", f"\n{a.new_cue}\n", 1)
        smoke.write_text(st)
        print("Updated embedded minimal-valid-draft cue in scripts/memory_smoke_test.sh")
    else:
        print("WARN: 'Improve your memory' line not found in memory_smoke_test.sh — manual edit needed.")

    # 5. INDEX update
    idx = ROOT / "goals" / "INDEX.md"
    it = idx.read_text()
    # Replace old "Active goal" first bullet
    it2 = re.sub(
        r"^- \*\*D(\d+)\+ \"(.+?)\"\*\*.*$",
        lambda m: f"- **D{m.group(1)}–D{a.old_end_day} \"{m.group(2)}\"** — archived to `{archive_rel}`.",
        it,
        count=1,
        flags=re.MULTILINE,
    )
    # Find the "Archived goals" header and re-insert old line under it (already replaced inline above,
    # but we also want a new line under "Active goal").
    new_active_line = (
        f"- **D{a.start_day}+ \"{a.new_title}\"** — set by Shoshannah Day {a.start_day}. "
        f"In progress. See `goals/active.md`.\n"
    )
    it3 = it2.replace("## Active goal\n", "## Active goal\n" + new_active_line, 1)
    # Also move the just-archived bullet under "## Archived goals" for chronological ordering.
    # Easiest: locate the rewritten old-active bullet line, copy it under Archived header,
    # and remove from its original "Active goal" position.
    archived_re = re.search(
        rf"^- \*\*D\d+–D{a.old_end_day} .*archived to `{re.escape(archive_rel)}`.*$",
        it3,
        flags=re.MULTILINE,
    )
    if archived_re:
        old_bullet = archived_re.group(0)
        it3 = it3.replace(old_bullet + "\n", "", 1)
        it3 = it3.replace(
            "## Archived goals\n",
            "## Archived goals\n" + old_bullet + "\n",
            1,
        )
    idx.write_text(it3)
    print("Updated: goals/INDEX.md")

    # 6. memory_changelog append
    today = datetime.datetime.now().strftime("%Y-%m-%d %H:%M PT")
    chl = ROOT / "memory_changelog.md"
    chl.write_text(
        chl.read_text() + "\n"
        f"## {today} — Goal transition (D{a.start_day} start)\n"
        f"- Archived: {archive_rel}\n"
        f'- New active goal: "{a.new_title}"\n'
        f"- REQUIRED cue in check_memory_cues.sh updated: 'Improve your memory' -> '{a.new_cue}'\n"
        f"- Embedded minimal-valid-draft in memory_smoke_test.sh also updated.\n"
        f"- Done by scripts/goal_transition.py\n"
    )
    print("Appended to: memory_changelog.md")

    # 7. validation
    print()
    print("=== validate_inventory.sh ===")
    r = sh(["bash", "scripts/validate_inventory.sh"], check=False)
    print(r.stdout)
    if r.returncode != 0:
        print("FAIL: validate_inventory.sh failed.")
        return 3

    print("=== memory_smoke_test.sh ===")
    r = sh(["bash", "scripts/memory_smoke_test.sh"], check=False)
    # Print only summary tail
    tail = "\n".join(r.stdout.splitlines()[-6:])
    print(tail)
    if r.returncode != 0:
        print("FAIL: smoke. Full output:")
        print(r.stdout)
        return 3

    # 8. final status
    print()
    print("=== git status ===")
    print(sh(["git", "status", "-s"]).stdout)
    print()
    print("=== Next manual steps ===")
    print("  1. Review: git diff --staged && git diff")
    print("  2. Edit goals/active.md to fill 'My approach' and 'Next steps'.")
    print(f"  3. git add -A && git commit -m 'D{a.start_day} goal transition: {a.new_title}' && git push")
    print("  4. Update CURRENT GOAL pointer in internal-memory bootloader at next consolidate.")
    print()
    print("✅ goal_transition.py complete.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
