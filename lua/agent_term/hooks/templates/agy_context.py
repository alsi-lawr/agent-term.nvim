#!/usr/bin/env python3
import json
import pathlib
import sys


def _read_context(path):
    if not path:
        return ""

    context_path = pathlib.Path(path)
    if not context_path.exists():
        return ""

    try:
        context_record = json.loads(context_path.read_text(encoding="utf-8"))
    except Exception:
        return ""

    content = context_record.get("content")
    if not isinstance(content, str) or content == "":
        return ""
    return content


def main() -> int:
    context_path = sys.argv[1] if len(sys.argv) > 1 else None
    content = _read_context(context_path)

    if content == "":
        print(json.dumps({"injectSteps": []}, separators=(",", ":")))
        return 0

    print(
        json.dumps(
            {"injectSteps": [{"userMessage": content}]},
            separators=(",", ":"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
