# Decision Log

Use this append-only template:

## DEC-000 — Title
- Date:
- Status: proposed | accepted | superseded
- Context:
- Evidence:
- Options considered:
- Decision:
- Why:
- Consequences:
- Risks:
- Reversal trigger:
- Files/tests affected:

## DEC-001 — Project hooks run Python via uv
- Date: 2026-07-17
- Status: accepted
- Context: `.claude/settings.json` hooks invoked bare `python`; system Python is absent on this machine, so guard/log hooks failed silently on every tool call.
- Evidence: `uv 0.11.11` present; WORKLOG 2026-07-12 toolchain audit.
- Options considered: install system Python; keep broken hooks; uv-managed interpreter.
- Decision: hook commands use `uv run --no-project python`.
- Why: zero-install, matches the toolchain policy already recorded in the worklog.
- Consequences: hooks only activate when a session is opened at the repo root (see KI-001).
- Risks: uv upgrade changing interpreter resolution (low).
- Reversal trigger: system Python becomes a managed prerequisite.
- Files/tests affected: `.claude/settings.json`.

## DEC-002 — Slice 001 scene is built procedurally; input map registered in code
- Date: 2026-07-17
- Status: accepted
- Context: `project.godot` referenced a main scene and three autoloads that did not exist. A physics proof must be reviewable and headless-verifiable.
- Evidence: recovery audit 2026-07-17; headless selftest passes (logs/SELFTEST_RESULTS.json).
- Options considered: editor-authored .tscn node trees; procedural construction from one script.
- Decision: `main.tscn` holds a single root node + script; all geometry, HUD, camera and the InputMap are created in code (`main.gd`, `core/input_config.gd`). The crane starts unpowered and a 3-item pre-use inspection (keys 1–3) must be completed before the rig accepts motion commands.
- Why: everything diffable/reviewable as text, deterministic, no hidden editor state, testable headless; unpowered start enforces the safety-first rule at the scene layer.
- Consequences: art passes later will introduce authored scenes; the rig module keeps `powered=true` as its own default, so every scene must explicitly set `powered=false` at spawn (KI-003).
- Risks: procedural visuals stay placeholder-grade (accepted for a proof).
- Reversal trigger: first visual-fidelity milestone.
- Files/tests affected: `src/simulator/slice_overhead/*`, `src/simulator/core/{loc,settings,input_config}.gd`.

## DEC-003 — Wind sequence always advances; the toggle only gates application
- Date: 2026-07-17
- Status: accepted
- Context: wind must be deterministic per seed, and reset must reproduce identical trajectories regardless of when the operator toggles wind.
- Evidence: `reset_deterministic` and `zero_wind_deterministic` tests pass with identical MD5 trajectory hashes across independent process runs.
- Options considered: step the RNG only while enabled; always-step + conditional application.
- Decision: `wind_model.step()` runs every physics tick; the toggle selects whether the vector is applied to the load.
- Why: wind state at time t is a pure function of (seed, t), independent of toggle history — the strongest reproducibility guarantee for training debriefs.
- Consequences: toggling wind ON at the same tick always yields the same gusts.
- Risks: none identified.
- Reversal trigger: multi-source weather system replacing the single OU model.
- Files/tests affected: `slice_overhead/main.gd`, `tests/selftest_driver.gd`, `tests/module_tests.gd`.

## DEC-004 — Two-tier verification: pure-module tests + in-scene selftest driver
- Date: 2026-07-17
- Status: accepted
- Context: "files created" is not success; the scene must be proven to run and respond headlessly, with results on disk.
- Evidence: `logs/MODULE_TEST_RESULTS.json` (7/7), `logs/SELFTEST_RESULTS.json` (16/16), process exit codes 0.
- Options considered: manual playtesting only; external test framework (GUT); built-in drivers.
- Decision: tier 1 — `tests/module_tests.gd` (SceneTree script, no scene/autoloads) validates pendulum period, determinism, wind displacement, NaN safety. Tier 2 — `tests/selftest_driver.gd`, instantiated by `main.gd` only under `-- --selftest`, drives the real InputMap actions tick-by-tick through the real scene and exits 0/1.
- Why: no third-party dependency; both tiers are CI-able commands with machine-readable output.
- Consequences: discrete key handling in `main.gd` uses explicit edge detection (`_edge()`), which works identically for hardware keys and `Input.action_press` injection.
- Risks: selftest tick schedules must respect drive settle times (caught once, fixed; see TEST_LOG).
- Reversal trigger: adoption of a project-wide test framework in a later phase.
- Files/tests affected: `src/simulator/tests/*`, `slice_overhead/main.gd`.
