# Gelderland Operator Academy

Evidence-driven desktop training simulator and career-preparation system for crane, lifting and heavy-equipment roles near Arnhem (Gelderland, NL).

**This simulator is a training aid. It is not a legal certificate, TCVT registration, VCA diploma or driving licence.**

## What is here

| Path | Purpose |
|---|---|
| `01_MASTER_PROMPT_V2.md` | Full mission and scope |
| `CLAUDE.md`, `AGENTS.md`, `.claude/` | Agent governance, rules, skills, hooks |
| `DECISIONS.md` | Append-only decision log |
| `research/` | Vacancy and licence evidence (seed = unverified; verified files carry dates and quotes) |
| `docs/` | Architecture, simulation spec, licence matrix |
| `src/simulator/` | Godot 4 project (the simulator) |
| `tests/physics/` | Physics validation reports |
| `scripts/` | Deterministic validation and build scripts |
| `logs/` | Worklog, research log, test log, known issues |

## Run the simulator (no console needed)

1. Double-click `START_SIMULATOR.bat`.
2. It checks prerequisites, writes `logs/launcher.log`, and opens the simulator.

## Develop

- Python scripts: `uv run --no-project python scripts/<script>.py` (uv manages Python; no system install needed).
- Godot editor: `tools/godot/` (fetched by `scripts/get_godot.ps1`).
- Headless physics tests: `scripts/run_physics_tests.bat`.

## Language policy

Technical English first; literal Spanish beside it; useful Dutch terms in parentheses — e.g. "Overhead crane operator — Operador de grúa puente — Machinist bovenloopkraan".
