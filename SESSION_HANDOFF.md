# Session Handoff

## Session S-2026-07-27-A — Hito 1: "Entrar a la grúa"

### Completed
Turned the Hito-0 physics proof (bare orbit camera, silent 1-2-3 rule, no player, no objective) into a first-person playable experience, per the user's explicit Hito-1 scope (player/cabin/camera/collision/HUD/objective/tutorial on the EXISTING overhead crane — no textures, no second machine, no research, no subagents).

Created:
- `core/player_controller.gd` — first-person `CharacterBody3D`: mouse look, WASD, sprint (Shift), jump, real gravity/collision.
- `core/world_builder.gd` — hall/crane geometry extracted from `main.gd`, now with `StaticBody3D` colliders on the floor, boundary walls and all 16 columns (previously visual-only), plus a ladder visual and floor-marked pickup/drop-off zones with beacons and 3D labels.
- `core/machine_access.gd` — pure state machine (OUTSIDE → IN_ZONE → CLIMBING_UP → IN_CABIN → CLIMBING_DOWN → OUTSIDE), unit tested.
- `core/camera_director.gd` — 5 views: CABIN (fixed pulpit, looks at the hook), WALK (first-person), ORBIT, HOOK, TOPDOWN. `Tab` cycles, `C` resets the active view. See DEC-011.
- `core/load_body.gd` — the load's collision surface, always following the sim's math position. Detects contact with the player (pushes them, flags a safety violation — DEC-008) and with the floor/columns (pure AABB checks, DEC-009).
- `core/objectives.gd` — pickup → carry → deliver scoring for SC-001, pure logic, unit tested with a clean-pass and a swing-failure case.
- `core/tutorial_guide.gd` — pure state → instruction mapping. Every gate (approach, climb, inspection, objective) now has an explicit on-screen instruction. This is the direct fix for "no sé qué hacer" / the undocumented 1-2-3 rule.
- `core/hud.gd` — game-style HUD: a swing gauge (needle + green/amber/red zones), a tension bar, a wind compass, a top-down minimap (hall bounds, hook position, pickup=yellow/drop-off=blue zones, player dot), the objective panel, the always-visible tutorial instruction, contextual controls text, and an `F1` full-screen help overlay.
- `src/simulator/scenarios/SC-001_palet_500kg.json` — first scenario: move a 500 kg pallet from Zone A to Zone B, swing must stay under 2°.
- `core/loc.gd` — **rewritten with Spanish.** Default HUD pairing is now EN/ES (was EN/NL) — this was the direct fix for the screenshot showing an unreadable HUD. Dutch is still reachable via `L`. See DEC-005.
- `core/input_config.gd` — added move/jump/interact/exit_cabin/camera_cycle/help_toggle/mouse-capture actions. Several physical keys are intentionally shared between on-foot and in-cabin meanings (e.g. `E` = interact on foot, hoist-down in cabin) — contexts never overlap.
- `core/settings.gd` — added player tuning, access/cabin/ladder coordinates, the SC-001 zone definitions, selectable masses (250/500/1000/2000 kg — selection UI is not wired yet, just the constant).
- `slice_overhead/main.gd` — rewritten as an orchestrator composing all of the above (was 356 lines doing everything itself).
- `tests/module_tests.gd` — +5 pure-logic tests (objectives x2, tutorial_guide, machine_access, load_body collision math), no scene needed.
- `tests/selftest_driver.gd` — a new condition-driven approach/collision/climb pre-phase, then the ENTIRE original Hito-0 fixed-tick schedule runs unchanged (same tick numbers) except the HUD-language assertion and the camera phase (which now Tabs into ORBIT first — see DEC-011). A cabin-exit check was appended after the original finish point.

### Evidence
- Module tests: **12/12 PASS** (`logs/MODULE_TEST_RESULTS.json`).
- Scene selftest: **21/21 PASS** (`logs/SELFTEST_RESULTS.json`) — the original 16 checks all still pass (proving the refactor didn't regress Hito 0's validated physics), plus 5 new: `player_spawns_on_foot`, `player_blocked_by_column` (real `CharacterBody3D` collision against a real column), `cabin_entry_works`, `camera_modes_distinct` (all 4 non-orbit-default views pairwise distinct transforms), `cabin_exit_works`.
- Headless import: clean. Windowed launch (300 frames, Vulkan/RTX 3060): clean, no errors.

### Bugs found and fixed during this session (see DECISIONS.md for the full write-up)
1. Forgot to carry `_sync_visuals()`/`_update_cable_visual()` over into the new `main.gd` — parse error, fixed.
2. `var t := access.climb_progress()` — `:=` type inference fails when the left-hand variable is statically typed as the base `RefCounted` and the call isn't wrapped in something with a known return type. Fixed with an explicit `: float` annotation.
3. `camera_director.gd` reads its OWN `rig`/`sim` fields, which `main.gd` never assigned — every non-cabin-position camera update silently failed (`Nonexistent function/property on Nil`), so orbit/hook/topdown never actually moved. Fixed by assigning `cam.rig`/`cam.sim` every frame in `main._process()` (they get replaced on every `sim_reset`, so a one-time assignment would go stale).
4. The scene selftest's own approach-phase code pressed AND released the `interact` action within the same driver call — `main.gd`'s edge detector never observed a "just pressed" frame, so the player could walk to the ladder but never climb in. This is a property of the whole test harness (main's `_physics_process` runs before the driver's, within the same frame — established since Hito 0), not a one-off: any test-driven discrete action must be held across two ticks. Documented as DEC-012 so it isn't rediscovered later.
5. A `module_tests.gd` unit test for `machine_access` initially "failed" because it kept feeding the ladder's exact coordinates after climbing down, and the state machine correctly re-detected "still standing at the ladder foot" as IN_ZONE — not a code bug, a test bug (fixed by stepping the simulated player away before the final assertion).

### Decisions
DEC-005 through DEC-013 appended to `DECISIONS.md` — read these before touching camera modes, the reset button, collision handling, or the test harness's input timing.

### What is explicitly OUT of scope for this hito (do not start these next)
- Textures, PBR materials, HDRI sky (Hito 2 — user pre-approved Poly Haven CC0 assets).
- A second machine (tower crane, mobile crane — Hito 3+).
- Vacancy/licence research (paused since Hito 0, per `CLAUDE.md`).
- Load physically resting on a surface (cable going slack) — currently detection-only (KI-004/KI-009... see KNOWN_ISSUES).
- Visual inspection of the HUD/gauges/minimap layout — verified to RUN without error, not verified to LOOK right (KI-008). The user should look at it.

### Next exact task
**Hito 2 — visual pass.** Texture the hall (concrete, rust, painted steel), crane, load and add an HDRI sky, all CC0 from Poly Haven, keeping the existing procedural geometry (so it stays articulable/testable). One session, verified, committed, stop. Do not start a second machine before this lands.

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
Controls: mouse look, WASD walk, Shift sprint/fine, Space jump, **E near the ladder to climb in** (E = hoist-down once in the cabin), F to climb out, 1-2-3 pre-use inspection (in cabin, required before the crane powers on), Q/E hoist, W/S bridge, A/D trolley, V wind, R reset (resets the machine, not your position — DEC-007), Tab cycle camera, C reset current camera view, F1 help, L language (EN/ES → EN → ES → NL), Esc toggle mouse capture.
