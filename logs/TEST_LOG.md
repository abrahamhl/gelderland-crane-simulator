# Test Log

Append-only. Record: date, test ID, command, result, notes.

## 2026-07-17 — Slice 001 physics proof (Godot 4.6.3.stable.official.7d41c59c4)

### T-001 — Headless project import
- Command: `tools/godot/Godot_v4.6.3-stable_win64_console.exe --headless --path src/simulator --import`
- Result: PASS — no parse errors, no missing resources; autoloads and main scene resolve.

### T-002 — Physics module tests (deterministic, no scene)
- Command: `...Godot_v4.6.3-stable_win64_console.exe --headless --path src/simulator --script res://tests/module_tests.gd -- --out=<ABS>/logs`
- Result: PASS 7/7, exit 0 → `logs/MODULE_TEST_RESULTS.json`, stdout in `logs/module_tests_stdout.txt`
  - `longer_cable_longer_period`: T(4 m)=4.0188 s, T(8 m)=5.6834 s
  - `period_matches_theory`: err vs 2π√(L/g) 0.15%; T8/T4 vs √2 err 0.00%
  - `seeded_run_deterministic`: identical MD5 `a5aa33c4e1fcc06030e0d0fae6c6734d`
  - `wind_changes_trajectory`: wind hash ≠ no-wind hash
  - `zero_wind_deterministic`: identical hashes across different seeds with wind off
  - `wind_causes_lateral_displacement`: 0.000000 m → 0.1149 m at 8 m/s (drag-equilibrium hand-calc ≈0.115 m)
  - `no_nan_or_infinity_under_stress`: 0 violations over 3600 steps (slack/shock + gusts + hoist sweep)

### T-003 — Scene end-to-end selftest (real main scene, real InputMap actions)
- Command: `...Godot_v4.6.3-stable_win64_console.exe --headless --fixed-fps 60 --path src/simulator -- --selftest --out=<ABS>/logs`
- Run 1: FAIL 15/16, exit 1 — `hoist_retracts` measured before the accel-limited hoist drive (0.45 m/s², max 0.35 m/s) had settled after key release (~47 ticks of coast); cable read 5.599→5.650 m. Physics correct; test schedule wrong. Fix: settle windows + full 120-tick up-phase in `tests/selftest_driver.gd`.
- Run 2: PASS 16/16, exit 0 → `logs/SELFTEST_RESULTS.json`, stdout in `logs/selftest_stdout.txt`
  - unpowered_start; no_motion_before_inspection (bridge_x bit-identical after 70 ticks of blocked input); inspection_enables_power
  - bridge_responds 10.000→11.044 m; trolley_responds 9.000→9.902 m; hoist_extends 5.000→5.700 m; hoist_retracts 5.700→5.000 m
  - load_swings max 12.87°; telemetry_updates +240 rows in 240 ticks; cable_visible_matches (visual 5.010 m vs sim 5.010 m)
  - hud_populated_bilingual (NL+EN labels present); wind_applied peak 8.31 m/s; wind_changes_behaviour mean lateral offset −0.0542 m → +0.0511 m toward +Z
  - camera_reset (orbit then exact restore); reset_deterministic — trajectory hash `da72cb6efc291dc441ff15ca4680f571` identical across two in-run resets and identical to run 1's value (cross-process determinism); no_nan_or_infinity (0 observations, 2541 ticks)

### T-004 — Windowed launch
- Command: `...Godot_v4.6.3-stable_win64_console.exe --path src/simulator --quit-after 240`
- Result: PASS, exit 0 — Vulkan 1.4.341 Forward+ on RTX 3060 Laptop GPU, zero errors/warnings (`logs/windowed_run_stdout.txt`).
