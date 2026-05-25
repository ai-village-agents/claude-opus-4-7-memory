#!/usr/bin/env python3
"""Shared-gate JSON adapter for Claude Opus 4.7 local memory gates.

Exposes Claude-Haiku-style lifecycle gate names while preserving my stricter
local bash-based checks. This is an ADAPTER, not a replacement.

Rationale (s17 decisions.md): I declined to adopt Haiku 4.5's shared-gate-library
wholesale because its dup-state design (reads from a self-maintained JSON log)
can't see AGENT_TALK echo-timing pre-emissions (L12 vulnerability). My local
pre_send_chat.sh reads from the scaffolding event stream via --latest-event,
which IS timing-sound. So I expose my gate behind Haiku's JSON envelope, keeping
my behavior + giving peers a uniform interface.

Inspired by GPT-5.5's scripts/shared_gate_adapter.py (8cc89f5, D419 s4).

Gates exposed:
  session_start   -> wraps boot.sh
  pre_send_chat   -> wraps scripts/pre_send_chat.sh; preserves --latest-event semantics
  pre_consolidate -> wraps scripts/pre_consolidate.sh + smoke + retrieval + validate
  pre_goal_transition -> wraps scripts/goal_transition.py (DRY-RUN ONLY; never mutates)

Exit codes:
  0 = PASS, 1 = FAIL, 2 = USAGE_ERROR
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(args: list[str], timeout: int = 60) -> tuple[int, str]:
    proc = subprocess.run(
        args, cwd=ROOT, text=True, capture_output=True, check=False, timeout=timeout
    )
    return proc.returncode, (proc.stdout + proc.stderr).strip()


def emit(gate: str, status: str, checks: dict, output: str = "") -> int:
    payload = {
        "gate": gate,
        "agent": "claude-opus-4.7",
        "status": status,
        "checks": checks,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    if output:
        payload["output_excerpt"] = output[-2000:]
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0 if status == "PASS" else 1


def gate_session_start(_: argparse.Namespace) -> int:
    code, output = run(["bash", "boot.sh"], timeout=120)
    checks = {
        "boot_passed": code == 0,
        "audit_present": "Memory Audit" in output,
        "git_status_present": "Git status" in output,
        "active_goal_present": "Active goal" in output,
    }
    status = "PASS" if code == 0 and all(checks.values()) else "FAIL"
    return emit("session_start", status, checks, output)


def gate_pre_consolidate(_: argparse.Namespace) -> int:
    commands = {
        "pre_consolidate": ["bash", "scripts/pre_consolidate.sh"],
        "validate_inventory": ["bash", "scripts/validate_inventory.sh"],
        "memory_smoke_test": ["bash", "scripts/memory_smoke_test.sh"],
        "retrieval_self_test": ["bash", "scripts/retrieval_self_test.sh"],
    }
    checks = {}
    outputs = []
    for name, cmd in commands.items():
        code, output = run(cmd, timeout=120)
        outputs.append(f"## {name}\n{output[-400:]}")
        checks[f"{name}_passed"] = code == 0
    code, status_out = run(["git", "status", "-sb"])
    upstream_clean = status_out.strip().startswith("## main") and "ahead" not in status_out and "behind" not in status_out
    work_clean = len([l for l in status_out.splitlines() if l.strip()]) == 1
    checks["git_status_clean"] = work_clean
    checks["upstream_synced"] = upstream_clean
    outputs.append(f"## git\n{status_out}")
    status = "PASS" if all(bool(v) for v in checks.values()) else "FAIL"
    return emit("pre_consolidate", status, checks, "\n\n".join(outputs))


def gate_pre_send_chat(args: argparse.Namespace) -> int:
    if not args.draft.strip():
        return emit("pre_send_chat", "FAIL", {"draft_present": False}, "empty draft")
    cmd = ["bash", "scripts/pre_send_chat.sh", args.draft]
    if args.latest_event:
        cmd.extend(["--latest-event", args.latest_event])
    code, output = run(cmd)
    # exit 4 = blocked by duplicate match; exit 0 = checklist passed
    blocked_by_dup = code == 4
    checks = {
        "local_guard_exit_code": code,
        "blocked_by_duplicate": blocked_by_dup,
        "latest_event_provided": bool(args.latest_event),
        "draft_present": True,
        "draft_chars": len(args.draft),
        # CRITICAL: the manual L12 scan is the agent's responsibility — adapter
        # cannot verify it. We surface this as an unverifiable check.
        "manual_l12_event_scan_required": True,
    }
    if blocked_by_dup:
        return emit("pre_send_chat", "FAIL", checks, output)
    if code != 0:
        return emit("pre_send_chat", "FAIL", checks, output)
    if not args.latest_event:
        # Without --latest-event the local script only prints a checklist; we
        # downgrade to PASS_WITH_CAVEAT because dup-check is purely manual.
        return emit("pre_send_chat", "PASS_WITH_CAVEAT", checks, output)
    return emit("pre_send_chat", "PASS", checks, output)


def gate_pre_goal_transition(args: argparse.Namespace) -> int:
    # Dry-run only: never actually performs the transition through the adapter.
    # Real goal-transition is run interactively via scripts/goal_transition.py.
    goal_file = Path(args.goal_text_file)
    checks = {
        "goal_text_file_exists": goal_file.is_file(),
        "goal_text_nonempty": goal_file.is_file() and goal_file.stat().st_size > 0,
        "old_slug_provided": bool(args.old_slug),
        "new_title_provided": bool(args.new_title),
        "start_day_provided": bool(args.start_day),
        "goal_transition_script_exists": (ROOT / "scripts" / "goal_transition.py").is_file(),
        "dry_run_only": True,
    }
    code, status_out = run(["git", "status", "-sb"])
    checks["git_status_clean"] = len([l for l in status_out.splitlines() if l.strip()]) == 1
    status = "PASS" if all(bool(v) for v in checks.values() if isinstance(v, bool)) else "FAIL"
    return emit(
        "pre_goal_transition",
        status,
        checks,
        f"Would run: python3 scripts/goal_transition.py --old-slug {args.old_slug} "
        f"--new-title '{args.new_title}' --start-day {args.start_day} "
        f"--goal-text-file {args.goal_text_file}\n\n{status_out}",
    )


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="gate", required=True)

    sub.add_parser("session_start")
    sub.add_parser("pre_consolidate")

    ps = sub.add_parser("pre_send_chat")
    ps.add_argument("--draft", required=True)
    ps.add_argument("--latest-event", default="")

    pg = sub.add_parser("pre_goal_transition")
    pg.add_argument("--old-slug", required=True)
    pg.add_argument("--new-title", required=True)
    pg.add_argument("--start-day", required=True)
    pg.add_argument("--goal-text-file", required=True)

    args = p.parse_args()
    dispatch = {
        "session_start": gate_session_start,
        "pre_consolidate": gate_pre_consolidate,
        "pre_send_chat": gate_pre_send_chat,
        "pre_goal_transition": gate_pre_goal_transition,
    }
    sys.exit(dispatch[args.gate](args))


if __name__ == "__main__":
    main()
