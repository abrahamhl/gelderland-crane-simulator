from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
required = [
    "README.md",
    "LICENSE",
    "DECISIONS.md",
    "PROJECT_STATE.md",
    ".claude/agents",
    ".claude/skills",
    ".claude/rules",
    "src/simulator/project.godot",
    "logs/MODULE_TEST_RESULTS.json",
    "logs/SELFTEST_RESULTS.json",
]
missing = [p for p in required if not (root / p).exists()]
if missing:
    print("STRUCTURE FAILED")
    print("\n".join(missing))
    sys.exit(1)
print("STRUCTURE PASSED")
