from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
required = [
    "CLAUDE.md", "AGENTS.md", "DECISIONS.md", "PROJECT_STATE.md",
    ".claude/agents", ".claude/skills", ".claude/rules", "01_MASTER_PROMPT_V2.md"
]
missing = [p for p in required if not (root / p).exists()]
if missing:
    print("STRUCTURE FAILED")
    print("\n".join(missing))
    sys.exit(1)
print("STRUCTURE PASSED")
