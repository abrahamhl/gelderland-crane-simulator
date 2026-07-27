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

## 2026-07-27 — Hito 1 verification (Godot 4.6.3.stable.official.7d41c59c4)

### T-005 — Headless project import (post-refactor)
- Command: `...Godot_v4.6.3-stable_win64_console.exe --headless --path src/simulator --import`
- Result: PASS, clean. Two parse errors found and fixed during development before this final clean run: (1) `_sync_visuals()`/`_update_cable_visual()` were dropped when `main.gd` was rewritten as an orchestrator — restored, reading from `world.*` instead of local fields; (2) `var t := access.climb_progress()` failed type inference because `access` is statically typed as the base `RefCounted` — fixed with an explicit `var t: float =`.

### T-006 — Pure-logic module tests (no scene)
- Command: `...Godot_v4.6.3-stable_win64_console.exe --headless --path src/simulator --script res://tests/module_tests.gd -- --out=<ABS>/logs`
- Result: PASS 12/12, exit 0 → `logs/MODULE_TEST_RESULTS.json`, stdout in `logs/module_tests_stdout.txt`. The original 7 (pendulum period, determinism, wind, NaN stress) unchanged and still pass; 5 new:
  - `objectives_pickup_then_delivery`: not_started → carrying → delivered, `score.passed=true` (max swing 0.50°)
  - `objectives_fails_on_excess_swing`: delivered=true but `passed=false` when max swing (5.00°) exceeds the 2.0° budget
  - `tutorial_guide_covers_all_states`: 8/8 state → instruction mappings correct
  - `machine_access_full_cycle`: outside → in_zone → interact → climbing_up → in_cabin → exit → climbing_down → outside, all transitions correct. First run of this test FAILED (ended at "in_zone" instead of "outside") — not a code defect: the test kept feeding the ladder's exact coordinates after climbing down, and the state machine correctly re-detected "still standing at the ladder foot" as IN_ZONE. Fixed by stepping the simulated player away before the final assertion.
  - `load_body_collision_math`: unconditional danger flag, push vector nonzero, AABB overlap true/false cases, floor and column contact true/false cases — all correct.

### T-007 — Scene end-to-end selftest (real main scene, real InputMap actions, real CharacterBody3D collision)
- Command: `...Godot_v4.6.3-stable_win64_console.exe --headless --fixed-fps 60 --path src/simulator -- --selftest --out=<ABS>/logs`
- Run 1: FAIL 20/21 (`cabin_entry_works` — "did not reach cabin within 1401 approach ticks"). Diagnosed with temporary debug prints: the player successfully walked to and was correctly detected inside the ladder's access zone (`access=in_zone`) at approach-tick 700, then never moved again for the rest of the run. Root cause: the new approach-phase code pressed AND released the `interact` input action within the same driver call; `main.gd`'s edge detector (which runs once per physics frame, before the driver's own frame — established since Hito 0) never observed a "just pressed" frame, so `access.try_interact()` was never invoked. Documented as DEC-012 (a property of the whole test harness: any test-driven discrete action must be held across two ticks, matching the pattern Hito 0 already used everywhere else, e.g. `inspect_1` pressed at tick 80 / released at tick 81). Fixed by splitting the press and release across two ticks (`_interact_press_pt`).
- Run 1 also surfaced two `[FAIL]` results caused by a second, unrelated bug: `camera_reset` ("orbited=false") and `camera_modes_distinct` ("all views identical at (2.0, 9.3, 2.2)"). Root cause: `core/camera_director.gd` reads its OWN `rig`/`sim` fields (declared for this exact purpose) but `main.gd` never assigned them — every camera mode except CABIN's position-only line silently failed with `Nonexistent function 'support_point' in base 'Nil'` (2484 occurrences in the log), so the camera transform never actually updated for ORBIT/HOOK/TOPDOWN. Fixed by assigning `cam.rig = rig; cam.sim = sim` every frame in `main._process()` (a one-time assignment in `_ready()` would go stale, since `_reset_all()` replaces `rig`/`sim` with new instances on every reset).
- Run 2 (after both fixes): **PASS 21/21, exit 0** → `logs/SELFTEST_RESULTS.json`, stdout in `logs/selftest_stdout.txt`.
  - `player_spawns_on_foot`; `player_blocked_by_column` (real `CharacterBody3D` walked into a real `StaticBody3D` column at x=10, drift 0.0000 m over 60 ticks while still pressing forward, position clear of the column face); `cabin_entry_works` (entered after 843 approach ticks / 14.1 s of dynamic steering + climb)
  - All 16 original Hito-0 checks unchanged and still passing (unpowered start, inspection gate, bridge/trolley/hoist response, swing, telemetry, cable visual, wind, reset determinism — trajectory hash `da72cb6e...` still bit-identical, no NaN/Infinity)
  - `hud_populated_bilingual` — assertion updated to check "Cable length" + "Longitud de cable" (EN/ES, the new default pair) instead of the old EN/NL pair — an intentional change matching DEC-005, not a weakened check
  - `camera_reset` (now via explicit Tab-into-ORBIT first, per DEC-011); `camera_modes_distinct` (hook/topdown/cabin/orbit-default all pairwise distinct transforms)
  - `cabin_exit_works` (in_cabin=false 160 ticks after pressing F — within the 2.5 s climb-down duration + buffer)

### T-008 — Windowed launch (post-refactor)
- Command: `...Godot_v4.6.3-stable_win64_console.exe --path src/simulator --quit-after 300`
- Result: PASS, exit 0 — Vulkan 1.4.341 Forward+ on RTX 3060 Laptop GPU, zero errors/warnings.

### Not verified this session
Visual appearance of the HUD gauges, minimap and tutorial panel layout was NOT visually inspected (no screenshot tool used against the native Godot window this session) — see KI-008. All 33 automated checks (12 module + 21 scene) pass, which verifies behavioural correctness, not on-screen layout/readability.
