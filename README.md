# Gelderland Crane Simulator

A playable overhead-crane simulator built in Godot 4.6.3 with deterministic
pendulum physics, automated verification and an auditable record of the
human decisions used to direct an AI coding agent.

> **Scope:** this is a portfolio project and training aid. It is not a legal
> certificate, TCVT registration, VCA diploma, driving licence or substitute
> for supervised practical training.

## Verified status

| Signal | Current evidence |
|---|---|
| Pendulum validation | Measured period differs by **0.15%** from `2π√(L/g)` |
| Automated verification | **35/35 checks pass**: 14 module + 21 scene checks |
| Determinism | Matching trajectory hashes after resets and separate runs |
| Safety gate | Crane remains unpowered until the three pre-use checks pass |
| Current interaction model | Ground-level pendant control, corrected from an earlier cabin design |

Machine-readable results live in
[`logs/MODULE_TEST_RESULTS.json`](logs/MODULE_TEST_RESULTS.json) and
[`logs/SELFTEST_RESULTS.json`](logs/SELFTEST_RESULTS.json). The append-only
test history, including failures found before the final passing runs, is in
[`logs/TEST_LOG.md`](logs/TEST_LOG.md).

## The human-in-the-loop correction

The AI agent initially designed an elevated operator cabin with a ladder.
Factory-floor experience showed that this crane should instead be operated
from a pendant control on the ground.

The correction was not silently patched:

1. `DEC-006` records the original cabin decision.
2. `DEC-014` explicitly supersedes it and explains the operational evidence.
3. Commit `c34c2ee` implements the corrected pendant-control model.
4. The complete 35-check suite verifies the resulting build.

See the
[`AI orchestration case study`](docs/AI_ORCHESTRATION_CASE_STUDY.md) and the
append-only [`DECISIONS.md`](DECISIONS.md).

## What is playable

- First-person movement through a placeholder factory hall with collision.
- Ground-level pendant pickup and release.
- Three-step pre-use inspection before power is enabled.
- Bridge, trolley and hoist control.
- A 500 kg pickup-to-drop-off scenario with swing, impact and near-miss scoring.
- Deterministic pendulum and wind behaviour.
- Load collision with floor and columns, including restitution and damping.
- First-person, orbit, hook and top-down camera views.
- English, Spanish and Dutch interface text.

## Run locally

### With Godot already installed

Open the project at `src/simulator/project.godot`, or run:

```text
godot --path src/simulator
```

### Windows portable layout used by this repository

The Godot binary is intentionally not committed. Place the official Godot
4.6.3 console executable at:

```text
tools/godot/Godot_v4.6.3-stable_win64_console.exe
```

Then double-click:

- `START_SIMULATOR.bat` to run the simulator.
- `RUN_TESTS.bat` to run both verification suites.

## Controls

| Control | Action |
|---|---|
| Mouse / WASD | Look and walk |
| Shift | Sprint on foot; fine control while operating |
| Space | Jump |
| E | Pick up pendant when nearby; hoist down while operating |
| F | Put down pendant |
| 1, 2, 3 | Complete the required pre-use inspection |
| W / S | Move bridge while operating |
| A / D | Move trolley while operating |
| Q / E | Hoist up / down while operating |
| V | Toggle wind |
| R | Reset machine state |
| Tab | Cycle camera |
| C | Reset current camera |
| F1 | Help |
| L | Change language |
| Esc | Toggle mouse capture |

## Repository map

| Path | Purpose |
|---|---|
| `src/simulator/` | Godot project, simulation modules and automated tests |
| `logs/` | Test outputs, work log, known issues and recovery audit |
| `DECISIONS.md` | Append-only architecture decision record |
| `PROJECT_STATE.md` | Current verified scope and limitations |
| `SESSION_HANDOFF.md` | Exact continuation state |
| `.claude/` | Agent roles, rules, skills and safety hooks used in the build |
| `docs/AI_ORCHESTRATION_CASE_STUDY.md` | Portfolio case study with evidence map |
| `research/` | Early career/licence research; seed material is explicitly unverified |

## Honest limitations

- Visuals are placeholder geometry; there is no production art pass.
- Bounce constants are plausible first-pass values, not measurements from a
  physical reference rig.
- The latest HUD, safety ring and bounce behaviour have automated behavioural
  verification but still need a documented visual-usability review.
- The repository demonstrates simulation and AI-governance practice; it does
  not claim professional crane-operation competence or certification.

## Licence

Apache License 2.0. See [`LICENSE`](LICENSE).
