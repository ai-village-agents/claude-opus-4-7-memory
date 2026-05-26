#!/usr/bin/env python3
"""Convert GPT-5.5's normalized scaffolding rows to chat-format messages.

Input row shape (normalized):
{
  "id": str, "source_agent": str, "day": int, "room": str, "turn_type": str,
  "system_prompt_excerpt": str,
  "developer_tool_contract_excerpt": str,
  "events_log_since_last_turn": [ {actionType, agentName, content, createdAt}, ... ],
  "environment_state": {current_goal, current_room, available_chat_tool, relevant_constraints},
  "assistant_action": {kind, tool_name, arguments: {message?: str, ...}},
  "target_behavior_notes": [str], "anti_behavior_notes": [str]
}

Output row shape (chat-format, ready for Tinker SFT tokenizer):
{ "messages": [ {role:"system", content}, {role:"user", content}, {role:"assistant", content} ] }
"""
import json, sys, argparse


def build_system_content(row: dict) -> str:
    parts = []
    parts.append(row.get("system_prompt_excerpt", "").strip())
    es = row.get("environment_state", {})
    if es:
        parts.append("\n<environment_state>")
        for k, v in es.items():
            parts.append(f"- {k}: {v}")
        parts.append("</environment_state>")
    dev = row.get("developer_tool_contract_excerpt", "").strip()
    if dev:
        parts.append("\n<tool_contract>\n" + dev + "\n</tool_contract>")
    return "\n".join(p for p in parts if p)


def build_user_content(row: dict) -> str:
    events = row.get("events_log_since_last_turn", [])
    return "Here is what has happened since you started your session: " + json.dumps(events, ensure_ascii=False)


def build_assistant_content(row: dict) -> str:
    aa = row.get("assistant_action", {}) or {}
    kind = aa.get("kind")
    if kind == "no_chat":
        # Model should emit no chat — represent as silent reasoning + non-chat tool note
        return "(No chat this turn — would duplicate or is unnecessary.)"
    tool_name = aa.get("tool_name", "send_message_to_chat")
    args = aa.get("arguments", {})
    notes = row.get("target_behavior_notes") or []
    reasoning = " ".join(notes).strip()
    tool_block = f'<tool_use>\n{json.dumps({"name": tool_name, "input": args}, ensure_ascii=False)}\n</tool_use>'
    if reasoning:
        return reasoning + "\n\n" + tool_block
    return tool_block


def convert_row(row: dict) -> dict:
    return {
        "messages": [
            {"role": "system", "content": build_system_content(row)},
            {"role": "user", "content": build_user_content(row)},
            {"role": "assistant", "content": build_assistant_content(row)},
        ],
        "_meta": {"converted_from": row.get("id"), "source_agent": row.get("source_agent"), "turn_type": row.get("turn_type")},
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", required=True, help="Input JSONL (normalized format)")
    ap.add_argument("--out", dest="out", required=True, help="Output JSONL (chat-format)")
    args = ap.parse_args()
    n = 0
    with open(args.inp) as f, open(args.out, "w") as g:
        for line in f:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            out = convert_row(row)
            g.write(json.dumps(out, ensure_ascii=False) + "\n")
            n += 1
    print(f"converted {n} rows -> {args.out}")


if __name__ == "__main__":
    main()
