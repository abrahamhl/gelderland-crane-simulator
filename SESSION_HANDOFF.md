# Session Handoff

## Session S-2026-07-28-C — portfolio release preparation

- Replaced the inaccurate public README with a verified simulator/AI-direction
  presentation.
- Added Apache-2.0 and `docs/AI_ORCHESTRATION_CASE_STUDY.md`.
- Corrected both Windows launchers so their visible controls and test counts
  match the current pendant-control build.
- Reran the real Godot verification locally: module tests **14/14 PASS** and
  scene self-test **21/21 PASS**.
- Publication audit found that the original private history contains raw
  research material and personal commit metadata. This repository is the
  resulting curated export: those materials are excluded and author email is
  rewritten to GitHub's no-reply address.
- Simulator scope is unchanged. After the portfolio release, the next product
  milestone remains the `SC-002+` scenario-variety work described below.

## Session S-2026-07-27-B — same-day correction: pendant control, real bounce, safety radius, key overlay

Continuation of S-2026-07-27-A (Hito 1) in the same session. The user played the build, confirmed it was "muchísimo mejor" than the previous physics-only proof, but flagged one **factual** error and several missing mechanics — all addressed below.

### The correction that mattered most
The user has real factory lifting-floor experience and corrected the core interaction model: **this overhead crane (bovenloopkraan) is operated from a pendant/remote control on the factory floor, not from a cabin.** There is nothing to climb. The previous session's fixed-cabin-with-ladder design (DEC-006) was not a stylistic choice — it was wrong about how this equipment works. This is now fixed (DEC-014, supersedes DEC-006):
- `MachineAccess` states are now just `OUTSIDE` / `IN_ZONE` / `CONTROLLING` — no climbing, picking the pendant up/down is instant.
- The control station sits at `Vector3(1.0, 0.0, 9.0)` — x=1.0 is strictly outside `CraneRig.bridge_limits.x` (2.0), so the crane can PHYSICALLY never reach the operator there. Provably safe, not just usually clear.
- `CameraDirector` lost its CABIN mode entirely; the home view is always first-person (walking and operating are the same physical situation for this machine — DEC-011 amended).

### Other feedback addressed this turn
- **Real impact physics** (DEC-015): the load now bounces off the floor and columns (restitution 0.3, damping 0.8), applied externally to `sim.load_pos`/`load_vel` so the validated free-swing integrator in `cable_load_sim.gd` is never touched. Found and fixed a real 0.5 m offset bug in the same code path: floor/column checks had been using the cable-attachment point directly instead of the load's visual box centre.
- **Safety radius / near-miss** (DEC-016): a 2.0 m caution zone around the load, larger than its exact collision box, per `.claude/rules/simulation-physics.md`'s "separate physical volumes from safety/near-miss volumes." A translucent red disc on the floor follows the load and shows it in real time; entering it flashes an amber caution (lighter than the red "contact" warning) and is scored separately as a near-miss, not a hard failure.
- **Big, live key-cap overlay** (DEC-017): WASD in their physical layout, plus Shift/Space-or-Q/E, each lighting up the instant its bound action is held — directly answers "que se vea dónde estoy pulsando."
- **Explicitly deferred, not dropped** (DEC-018): the user also asked for several scenario variants (approach-and-lift from boxes, bigger load, load wedged between boxes, higher/lower placements). This is real, separate scope — deferred to the next session as its own milestone, building on the now-corrected foundation. `objectives.gd`'s data-driven design already supports adding SC-002+ from JSON alone for most of this.

### Files touched this turn
- `core/machine_access.gd` — simplified state machine (no climbing).
- `core/camera_director.gd` — CABIN mode removed.
- `core/load_body.gd` — added `resolve_floor_contact`, `resolve_column_contact`, `is_within_safety_radius`; fixed the box-centre offset contract (all functions now clearly expect a box CENTRE, not the raw cable-attachment point).
- `core/objectives.gd` — added `near_misses` tracking (`update()`'s new parameter defaults to 0, old callers unaffected).
- `core/world_builder.gd` — ladder marker replaced with a control-box/post visual; added the safety-radius floor ring.
- `core/tutorial_guide.gd`, `core/loc.gd` — climbing-related states/text removed; pendant-related text added; the one leftover "climb down" string in `obj_delivered` fixed to "put down the pendant."
- `core/hud.gd` — `KeyCap` component + key cluster; caution/impact toast labels; `in_cabin` renamed to `controlling` throughout.
- `core/settings.gd` — `ACCESS_POINT` moved to the provably-safe `(1.0, 0.0, 9.0)`; `CABIN_ANCHOR`/`CLIMB_DURATION_S` removed; added `LOAD_SAFETY_RADIUS_M`, `IMPACT_RESTITUTION`, `IMPACT_DAMPING`.
- `slice_overhead/main.gd` — `_drive_player_or_climb()` replaced with the much simpler `_drive_player()`; added `_resolve_load_impacts()` and `_check_near_miss()`; `is_in_cabin()` renamed `is_controlling()` throughout.
- `tests/module_tests.gd` — rewrote the access-state-machine test for instant transitions; added `_test_load_body_impact_response` and `_test_load_safety_radius`; updated the tutorial-guide test cases.
- `tests/selftest_driver.gd` — approach phase no longer waits through a climb (picks up the pendant within 1-2 ticks of the key press instead of up to 1400); checks renamed `pendant_pickup_works`/`pendant_putdown_works`.

### Bugs found and fixed via headless verification this turn
1. `var floor_ok := floor_hit.hit and ...` / `var col_ok := ...` in the new module tests — same class of bug as Hito 1's DEC (type inference fails when the expression touches `Dictionary`-typed `.field` access); fixed with explicit `: bool` annotations.
2. The real 0.5 m box-centre offset bug described above (found while implementing bounce, not by accident this time — DEC-015 documents it).

### Evidence
- Module tests: **14/14 PASS** (`logs/MODULE_TEST_RESULTS.json`) — the 12 from Hito 1 (with the access-machine test rewritten for the new instant-pickup model) plus 2 new: impact response, safety radius.
- Scene selftest: **21/21 PASS** (`logs/SELFTEST_RESULTS.json`) — same 21 checks as Hito 1, renamed where the underlying mechanic changed (`cabin_entry_works` → `pendant_pickup_works`, etc.), all still passing; `reset_deterministic`'s hash is UNCHANGED (`da72cb6e...`) confirming the bounce-physics code path never triggers during the normal tested sequence (the load never reaches the floor/a column in that scripted run), so nothing about the validated trajectory shifted.
- Clean headless import, clean windowed launch (Vulkan/RTX 3060).

### What is explicitly OUT of scope still
- Multiple scenario variants (boxes, heights, tight spaces) — DEC-018, next milestone.
- Textures/PBR/HDRI sky — still pending, Poly Haven CC0 pre-approved.
- A second machine.
- Visual inspection of the HUD/gauges/bounce/key-overlay layout — verified to run and compute correctly, not verified to LOOK right (KI-008). The user should look at it.

### Next exact task
**Scenario variety milestone.** Add 3-5 new scenario JSON files (SC-002..SC-00N) plus whatever box-stack geometry each needs, exercising: pickup requiring the player to walk around an obstacle, a heavier/bigger load, a load wedged between boxes, a higher placement, a lower placement. Reuse `objectives.gd`, `load_body.gd`, `world_builder.gd`'s zone-marker pattern — none of those need new capabilities, just new data and geometry. One session, verified, committed, stop.

### How to run
```
START_SIMULATOR.bat          (double-click, or from a terminal in the repo root)
RUN_TESTS.bat                 (double-click; runs both test tiers, reports OK/FAIL)
```
Manual commands:
```
tools/godot/Godot_v4.6.3-stable_win64_console.exe --path src/simulator
tools/godot/Godot_v4.6.3-stable_win64_console.exe --headless --path src/simulator --script res://tests/module_tests.gd -- --out=<ABS_LOGS_DIR>
tools/godot/Godot_v4.6.3-stable_win64_console.exe --headless --fixed-fps 60 --path src/simulator -- --selftest --out=<ABS_LOGS_DIR>
```
Controls: mouse look, WASD walk, Shift sprint/fine, Space jump, **E near the pendant station to pick it up** (instant — E = hoist-down once controlling), F to put it down, 1-2-3 pre-use inspection (required before the crane powers on), Q/E hoist, W/S bridge, A/D trolley, V wind, R reset (resets the machine, not your position — DEC-007), Tab cycle camera, C reset current camera view, F1 help, L language, Esc toggle mouse capture. Stay clear of the red safety ring on the floor — it follows the load and marks the caution radius.
