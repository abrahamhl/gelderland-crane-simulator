import json, re, sys

payload = json.load(sys.stdin)
tool = payload.get("tool_name", "")
inp = payload.get("tool_input", {})
text = json.dumps(inp, ensure_ascii=False)

danger = [
    r"\brm\s+-rf\s+[/\\](?!tmp\b)",
    r"\bdel\s+/[sq]\b",
    r"\bformat\s+[a-z]:",
    r"\bdrop\s+database\b",
    r"\bgit\s+reset\s+--hard\b",
    r"\bgit\s+clean\s+-fdx\b",
]
if tool == "Bash" and any(re.search(p, text, re.I) for p in danger):
    print("Blocked destructive command. Use a reversible, scoped operation and record the reason.", file=sys.stderr)
    sys.exit(2)

protected = ["02_SEED_RESEARCH_UNVERIFIED.docx", "Oportunidades Laborales y Formación en Grúas.docx"]
if tool in {"Write", "Edit"} and any(name in text for name in protected):
    print("Seed evidence files are read-only. Write derived data elsewhere.", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
