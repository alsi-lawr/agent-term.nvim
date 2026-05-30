#!/usr/bin/env python3
import json
import pathlib
import sys


def main() -> int:
    if len(sys.argv) < 2:
        return 0

    context_path = pathlib.Path(sys.argv[1])
    if not context_path.exists():
        return 0

    try:
        payload = json.loads(context_path.read_text(encoding="utf-8"))
    except Exception:
        return 0

    content = payload.get("content")
    if not isinstance(content, str) or content == "":
        return 0

    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": content,
                }
            },
            separators=(",", ":"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
