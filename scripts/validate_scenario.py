import json, sys
from pathlib import Path

path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("scenarios/scenario.json")
data = json.loads(path.read_text(encoding="utf-8"))
required = {
    "id", "title", "machine", "environment", "full_work_cycle",
    "physical_parameters", "hazards", "controls", "assessment",
    "simplifications", "legal_disclaimer"
}
missing = required - set(data)
if missing:
    print("SCENARIO VALIDATION FAILED: " + ", ".join(sorted(missing)))
    sys.exit(1)
stages = set(data.get("full_work_cycle", {}).keys())
needed = {"briefing", "access", "inspection", "setup", "operation", "shutdown", "debrief"}
if not needed <= stages:
    print("SCENARIO VALIDATION FAILED: missing lifecycle stages " + ", ".join(sorted(needed - stages)))
    sys.exit(1)
print("SCENARIO VALIDATION PASSED")
