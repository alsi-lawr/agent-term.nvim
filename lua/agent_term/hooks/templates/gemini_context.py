#!/usr/bin/env python3
import json
import pathlib
import sys


def main() -> int:
    context_path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None
    context_content = ""
    if context_path and context_path.exists():
        try:
            context_content = json.loads(context_path.read_text(encoding="utf-8")).get("content", "")
        except Exception:
            pass

    try:
        input_data = json.load(sys.stdin)
        llm_request = input_data["llm_request"]
        last_message = llm_request["messages"][-1]

        if context_content:
            current = last_message.get("content", "")
            last_message["content"] = f"{current}\n\n{context_content}".strip()

        print(json.dumps({"hookSpecificOutput": {"llm_request": llm_request}}, separators=(",", ":")))
        return 0
    except (KeyError, IndexError, TypeError, AttributeError):
        return 1


if __name__ == "__main__":
    raise SystemExit(main())



