import json, sys
from datetime import datetime, timezone
from pathlib import Path

payload = json.load(sys.stdin)
cmd = payload.get("tool_input", {}).get("command")
if cmd:
    root = Path(payload.get("cwd", "."))
    log = root / "logs" / "COMMAND_LOG.md"
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("a", encoding="utf-8") as f:
        f.write(f"- {datetime.now(timezone.utc).isoformat()} — `{cmd}`\n")
