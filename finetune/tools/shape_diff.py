#!/usr/bin/env python3
"""shape_diff.py — compare training-data shape vs live-deployment shape.

Usage:
    python3 shape_diff.py --train PATH.jsonl --live PATH.json [--out report.md]

Inputs:
    --train: JSONL file with one chat row per line. Each row should have a 'messages'
             list (OpenAI/Tinker chat format) with system/user/assistant roles, or
             top-level {system, user, assistant} keys.
    --live:  JSON or text file containing one captured live rollout. JSON format
             expected to have {system, user, assistant} or {messages: [...]}. Text
             format: dumb but workable — we'll just treat the whole thing as the
             system prompt for the purposes of length comparison.

Outputs a markdown report covering the 6 axes from the finetune-for-deployment
runbook:
    1. System prompt length & structure
    2. User message format
    3. Expected assistant format
    4. Tool-call envelope present?
    5. Memory / intention blocks?
    6. Multi-turn context shape?

Exits 0 if shapes match within tolerance; non-zero if mismatch detected (so this
can gate CI). Tolerance is intentionally generous because the goal is to catch
catastrophic mismatches, not nitpick.

Author: Claude Opus 4.7 (D420 s11), derived from the finetune-for-deployment
runbook in claude-opus-4-7-memory.
"""

from __future__ import annotations
import argparse
import json
import re
import statistics
import sys
from pathlib import Path
from typing import Iterable

TOOL_USE_RE = re.compile(r"<tool_use>", re.IGNORECASE)
JSON_EVENTS_RE = re.compile(r"Here is what has happened since you started your session", re.IGNORECASE)
XML_BLOCK_RE = re.compile(r"<(overview|tools|tool_usage|intention|internal_memory|outreach_principles)>")
MEMORY_BLOCK_RE = re.compile(r"<internal_memory>|<intention>", re.IGNORECASE)
THINK_RE = re.compile(r"</?think>", re.IGNORECASE)


def _row_to_triple(row: dict) -> dict:
    if "messages" in row:
        out = {"system": "", "user": "", "assistant": ""}
        for m in row["messages"]:
            role = m.get("role", "")
            content = m.get("content", "")
            if role in out:
                if out[role]:
                    out[role] += "\n" + content
                else:
                    out[role] = content
        return out
    return {
        "system": row.get("system", ""),
        "user": row.get("user", ""),
        "assistant": row.get("assistant", ""),
    }


def load_train(path: Path) -> list[dict]:
    rows = []
    with path.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(_row_to_triple(json.loads(line)))
            except json.JSONDecodeError:
                continue
    return rows


def load_live(path: Path) -> dict:
    text = path.read_text()
    try:
        data = json.loads(text)
        if isinstance(data, dict):
            return _row_to_triple(data)
    except json.JSONDecodeError:
        pass
    # Fallback: treat entire file as a system-prompt dump
    return {"system": text, "user": "", "assistant": ""}


def summarize(label: str, samples: Iterable[str]) -> dict:
    lens = [len(s) for s in samples]
    if not lens:
        return {"label": label, "n": 0, "mean": 0, "median": 0, "min": 0, "max": 0}
    return {
        "label": label,
        "n": len(lens),
        "mean": int(statistics.mean(lens)),
        "median": int(statistics.median(lens)),
        "min": min(lens),
        "max": max(lens),
    }


def axis_report(train: list[dict], live: dict) -> tuple[str, bool]:
    """Return (markdown report, ok_flag). ok_flag is False if a catastrophic mismatch."""
    ok = True
    out = ["# Shape Diff Report\n"]
    sys_train = [r["system"] for r in train]
    usr_train = [r["user"] for r in train]
    asst_train = [r["assistant"] for r in train]
    sys_train_stats = summarize("train system", sys_train)
    sys_live_len = len(live["system"])

    # Axis 1: system prompt length
    out.append("## Axis 1: System prompt length\n")
    out.append(f"- Train (n={sys_train_stats['n']}): "
               f"mean {sys_train_stats['mean']}, median {sys_train_stats['median']}, "
               f"min {sys_train_stats['min']}, max {sys_train_stats['max']}\n")
    out.append(f"- Live: {sys_live_len}\n")
    ratio = sys_live_len / max(sys_train_stats['median'], 1)
    if ratio > 2.0 or ratio < 0.5:
        out.append(f"- ⚠️ MISMATCH: live system prompt is {ratio:.1f}× the training median. "
                   f"<think> tags may re-emerge under longer prompts.\n")
        ok = False
    else:
        out.append(f"- ✅ Within 2× of training median (ratio {ratio:.2f}).\n")

    # Axis 2: system prompt structure (XML blocks)
    out.append("\n## Axis 2: System prompt structure (XML block usage)\n")
    train_xml_pct = sum(1 for s in sys_train if XML_BLOCK_RE.search(s)) / max(len(sys_train), 1)
    live_xml = bool(XML_BLOCK_RE.search(live["system"]))
    out.append(f"- Train rows with XML scaffold blocks: {train_xml_pct:.0%}\n")
    out.append(f"- Live uses XML scaffold blocks: {live_xml}\n")
    if live_xml and train_xml_pct < 0.5:
        out.append("- ⚠️ MISMATCH: live uses nested XML blocks; most training rows don't.\n")
        ok = False
    elif not live_xml and train_xml_pct > 0.5:
        out.append("- ⚠️ MISMATCH: training uses XML blocks; live doesn't.\n")
        ok = False
    else:
        out.append("- ✅ Compatible.\n")

    # Axis 3: user message format (JSON events vs prose)
    out.append("\n## Axis 3: User message format\n")
    train_events_pct = sum(1 for u in usr_train if JSON_EVENTS_RE.search(u)) / max(len(usr_train), 1)
    live_events = bool(JSON_EVENTS_RE.search(live["user"])) if live["user"] else None
    out.append(f"- Train rows with JSON-events user format: {train_events_pct:.0%}\n")
    out.append(f"- Live uses JSON-events user format: {live_events}\n")
    if live_events and train_events_pct < 0.5:
        out.append("- ⚠️ MISMATCH: live expects JSON-events user content; training is prose scenarios.\n")
        ok = False

    # Axis 4: tool-call envelope
    out.append("\n## Axis 4: Tool-call envelope in assistant\n")
    train_tool_pct = sum(1 for a in asst_train if TOOL_USE_RE.search(a)) / max(len(asst_train), 1)
    live_tool = bool(TOOL_USE_RE.search(live["assistant"])) if live["assistant"] else None
    out.append(f"- Train rows with `<tool_use>` in assistant: {train_tool_pct:.0%}\n")
    out.append(f"- Live assistant uses `<tool_use>`: {live_tool}\n")
    if live_tool and train_tool_pct < 0.2:
        out.append("- ⚠️ MISMATCH: live expects `<tool_use>` JSON; training emits prose. THIS IS THE V3 FAILURE MODE.\n")
        ok = False
    elif live["assistant"] and not live_tool and train_tool_pct > 0.5:
        out.append("- ⚠️ MISMATCH: training emits `<tool_use>`; live doesn't.\n")
        ok = False

    # Axis 5: memory/intention blocks
    out.append("\n## Axis 5: Memory / intention blocks in system\n")
    train_mem_pct = sum(1 for s in sys_train if MEMORY_BLOCK_RE.search(s)) / max(len(sys_train), 1)
    live_mem = bool(MEMORY_BLOCK_RE.search(live["system"]))
    out.append(f"- Train rows with memory/intention blocks: {train_mem_pct:.0%}\n")
    out.append(f"- Live has memory/intention blocks: {live_mem}\n")
    if live_mem and train_mem_pct < 0.2:
        out.append("- ⚠️ MISMATCH: live injects memory/intention scaffolding; training rows don't.\n")
        ok = False

    # Axis 6: think tag policy
    out.append("\n## Axis 6: `<think>` tag handling\n")
    train_think_pct = sum(1 for a in asst_train if THINK_RE.search(a)) / max(len(asst_train), 1)
    out.append(f"- Train assistant outputs containing `<think>`: {train_think_pct:.0%}\n")
    if train_think_pct > 0.05:
        out.append("- ⚠️ Training data leaks `<think>` tags. Model will likely emit them live.\n")
        ok = False
    else:
        out.append("- ✅ Training data is clean of `<think>` tags.\n")

    # Summary
    out.append("\n## Summary\n")
    if ok:
        out.append("✅ No catastrophic mismatches detected. Safe to proceed (after running shape-match eval).\n")
    else:
        out.append("❌ At least one catastrophic mismatch detected. Redesign training data before training.\n")
    return "".join(out), ok


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--train", required=True, type=Path)
    p.add_argument("--live", required=True, type=Path)
    p.add_argument("--out", type=Path, default=None)
    args = p.parse_args(argv)

    train = load_train(args.train)
    live = load_live(args.live)
    if not train:
        print(f"ERROR: no rows loaded from {args.train}", file=sys.stderr)
        return 2
    report, ok = axis_report(train, live)
    if args.out:
        args.out.write_text(report)
        print(f"Wrote {args.out}")
    else:
        print(report)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
