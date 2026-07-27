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

## DEC-005 — HUD gains Spanish; default pairing becomes EN/ES, not EN/NL
- Date: 2026-07-27
- Status: accepted
- Context: the user (Spanish-speaking) opened slice 001 and could not read the HUD, which shipped English/Dutch only — a defect against `01_MASTER_PROMPT_V2.md`'s explicit "English first, Spanish literal beside it, Dutch preserved in parentheses" rule, not a new feature request.
- Evidence: user screenshot showing an unreadable HUD; master prompt §project mission.
- Options considered: add Spanish as a third equal-weight language; make EN/ES the default pair (Dutch demoted to an explicit single-language mode).
- Decision: `core/loc.gd` entries are now `[en, es, nl]`. Combined default mode returns "EN / ES". Dutch is reachable via the `L` cycle (`EN_ES -> EN -> ES -> NL`) but no longer shown by default.
- Why: the user's understanding is the actual product goal; Dutch professional terms remain available for on-the-job vocabulary practice without cluttering the default HUD.
- Consequences: `tests/selftest_driver.gd`'s `hud_populated_bilingual` check now asserts "Cable length" + "Longitud de cable" instead of "Cable length" + "Kabellengte" — an intentional, documented change to the test's expectation, not a silently weakened check.
- Risks: none identified.
- Reversal trigger: none expected; would revisit only if Dutch-first training becomes a stated priority.
- Files/tests affected: `core/loc.gd`, `slice_overhead/main.gd`, `tests/selftest_driver.gd`.

## DEC-006 — Fixed operator cabin (pulpit), not a cab that rides the bridge
- Date: 2026-07-27
- Status: accepted
- Context: the user asked for a first-person player who walks to the machine, climbs in, and operates it — matching `01_MASTER_PROMPT_V2.md` §6 "Access and cabin entry" and §8 "cab/first-person", neither of which was implemented before this session.
- Evidence: real factory overhead cranes are commonly operated either from a pendant control walking the floor or from a fixed elevated pulpit near one end of the runway — both keep the operator's access point static, unlike a mobile/tower crane's cab which travels with the machine.
- Options considered: (a) a fixed pulpit with a static ladder; (b) a cab physically mounted on the moving trolley, requiring a ladder that also moves.
- Decision: (a) — a fixed booth + ladder near the runway's `x=2` end (`AppSettings.ACCESS_POINT`, `CABIN_ANCHOR`). The CABIN camera sits at that fixed point and looks toward the current hook/load position each frame.
- Why: physically correct for this machine type, and far simpler to build/verify than a moving ladder; a genuinely cab-mounted view is deferred to a machine where it is the realistic choice (e.g. a mobile crane in H4).
- Consequences: KI-007. The climb is a scripted camera/position interpolation (2.5 s), not physics-driven, since there is nothing to walk on that moves.
- Risks: none identified for this machine type.
- Reversal trigger: building a machine whose real-world cab travels with the structure.
- Files/tests affected: `core/machine_access.gd`, `core/camera_director.gd`, `slice_overhead/main.gd`, `core/settings.gd`.

## DEC-007 — R resets the machine, not the operator's position or cabin state
- Date: 2026-07-27
- Status: accepted
- Context: adding a player who can be on-foot, climbing, or in the cabin created an ambiguity the original single-state slice never had: what should the Reset key do to the *operator*, as opposed to the crane/load/wind?
- Evidence: `tests/selftest_driver.gd`'s Phase 8 (reset-determinism) presses `sim_reset` twice *while already in the cabin* and expects rig/trolley/hoist control to keep working immediately after each reset, with no re-entry step.
- Options considered: full scene reset (eject the player back outside, replay the whole approach); machine-only reset (rig/cable/wind/telemetry/objective), leaving the operator wherever they are.
- Decision: machine-only reset. `main.gd::_reset_all()` touches `rig`, `sim`, `wind_model`, `telemetry`, `objectives`, camera orbit defaults — never `access` or `player`.
- Why: matches real operator expectise ("retry the lift") and keeps the existing reset-determinism test valid without inventing an auto-re-entry mechanic. Also the more realistic reading of a training "retry" button.
- Consequences: a player who resets while on foot stays on foot; a player who resets in the cabin stays in the cabin, immediately able to keep training.
- Risks: none identified.
- Reversal trigger: a future scenario that specifically wants a full-site reset (e.g. multi-operator handover training).
- Files/tests affected: `slice_overhead/main.gd`.

## DEC-008 — Any load-to-person contact is a safety violation, not an energy threshold
- Date: 2026-07-27
- Status: accepted
- Context: the user asked for real collision — "que me pueda golpear la grúa por la inercia" — and for the detector to be unambiguous.
- Evidence: standard lifting-safety doctrine: personnel must never be positioned under or against a suspended load, regardless of its speed at the moment of contact — the risk is the mass overhead, not the current velocity.
- Options considered: kinetic-energy threshold (only count "hard" hits); unconditional violation on any contact.
- Decision: `core/load_body.gd::is_dangerous_impact()` always returns `true`. The push imparted to the player still scales with the load's speed (for game feel), but the safety-violation count does not depend on it.
- Why: teaches the correct rule (stay clear, always) instead of an artificial "it was a soft touch" exception a trainee could learn to exploit.
- Consequences: `Objectives.score().passed` requires `violations == 0` — any contact fails the lift, full stop.
- Risks: none identified.
- Reversal trigger: none expected.
- Files/tests affected: `core/load_body.gd`, `core/objectives.gd`.

## DEC-009 — Structure/floor contact is detected geometrically, not by engine collision response
- Date: 2026-07-27
- Status: accepted
- Context: the load's position is authored by `cable_load_sim.gd`'s deterministic math (per `.claude/rules/simulation-physics.md`: fixed timestep, deterministic seeds); handing the load to the physics engine as a real dynamic RigidBody3D would let the engine's own solver silently diverge from that validated math.
- Evidence: KI-004 (now resolved) — the load previously had no contact detection at all.
- Options considered: full RigidBody3D physics for the load once near a surface; keep the sim authoritative and add pure-geometry AABB/floor checks alongside it.
- Decision: the sim stays authoritative. `LoadBody.check_floor_contact()` / `check_column_contact()` are static AABB/plane checks run every tick against the sim's own `load_pos`, independent of the engine's physics step. `LoadBody` (an `Area3D`) only *detects* the player via `body_entered` — it never receives forces back.
- Why: preserves the pendulum-period validation (DEC established in Hito 0) — the load's trajectory must remain exactly what the tests verified, not whatever a general-purpose rigid-body solver produces.
- Consequences: on structure/floor contact the load is logged as a collision/violation but does not physically stop, bounce, or go slack (KI-004 residual). A real contact response is future work once it can be added without perturbing the validated free-swing math.
- Risks: none identified for this hito's scope (detection only).
- Reversal trigger: a scenario that specifically requires the load to rest on a surface (e.g. "set down" needing the cable to visibly slacken).
- Files/tests affected: `core/load_body.gd`, `core/world_builder.gd` (columns array), `slice_overhead/main.gd`.

## DEC-010 — Objectives, tutorial guidance, access state machine and collision math are pure logic, unit-tested without a scene
- Date: 2026-07-27
- Status: accepted
- Context: Hito 1 adds several new gameplay systems (pickup/deliver scoring, contextual tutorial text, approach/climb state machine, collision math). Coupling all of their verification to the heavy, timing-sensitive scene selftest would make the suite slower and more fragile than necessary.
- Evidence: `tests/module_tests.gd` tests 8-12 (objectives x2, tutorial_guide, machine_access, load_body math) all pass without instancing `main.tscn`.
- Options considered: test everything through the full scene driver; split pure state/logic into `RefCounted`/static-function modules with their own direct unit tests, reserving the scene driver for genuine integration (does the player actually walk, does the camera actually differ, does pressing a real key actually flip real state).
- Decision: the split. `core/objectives.gd`, `core/machine_access.gd`, `core/tutorial_guide.gd` are all `RefCounted`/static, taking plain values in and returning plain values out — no autoload or scene-tree dependency.
- Why: faster, more robust tests; a scoring-logic bug surfaces in milliseconds with a precise synthetic case instead of requiring a multi-thousand-tick scene replay to reach the same code path.
- Consequences: the scene selftest's new checks (`player_spawns_on_foot`, `player_blocked_by_column`, `cabin_entry_works`, `camera_modes_distinct`, `cabin_exit_works`) are deliberately kept to integration-only concerns — things that genuinely require the real `CharacterBody3D`, `Area3D` and `Camera3D`.
- Risks: none identified.
- Reversal trigger: none expected; this is the same two-tier pattern DEC-004 already established.
- Files/tests affected: `src/simulator/tests/module_tests.gd`, `src/simulator/tests/selftest_driver.gd`.

## DEC-011 — CameraDirector: HOME resolves to CABIN/WALK automatically; Tab cycles the other three views; C resets whichever view is active
- Date: 2026-07-27
- Status: accepted
- Context: the user asked for five distinct camera views (cabin/first-person, orbit, hook, top-down) plus the pre-existing orbit-drag-and-reset behaviour from Hito 0, which assumed the orbit camera was the ever-present default.
- Evidence: `core/camera_director.gd`; `tests/selftest_driver.gd` Phase 7/7b.
- Options considered: five independent, always-selectable modes with no special-casing; a "HOME" mode that automatically shows CABIN when in the cabin and WALK when on foot, with Tab cycling the three "away" views (ORBIT/HOOK/TOPDOWN) and C returning/resetting.
- Decision: the HOME-resolves-automatically design.
- Why: the operator's "default" view should always match their physical situation (in the cabin vs on the factory floor) without a manual step; the three away-views are for inspection/training/replay use, which is what Tab is for.
- Consequences: `cam_reset` (C) now means "reset whatever view is currently active" (orbit angles reset if in ORBIT; jump to HOME otherwise) rather than always meaning "reset the orbit camera" — Hito 0's camera test now presses `camera_cycle` (Tab) once before the orbit-drag sequence to enter ORBIT mode explicitly.
- Risks: none identified.
- Reversal trigger: none expected.
- Files/tests affected: `core/camera_director.gd`, `slice_overhead/main.gd`, `tests/selftest_driver.gd`.

## DEC-012 — Test-driven input actions must press and release on different ticks
- Date: 2026-07-27
- Status: accepted
- Context: a new selftest check (`cabin_entry_works`) initially failed — the player walked to the ladder correctly but never climbed in. Root cause: the new approach-phase code pressed and released the `interact` action within the same driver call.
- Evidence: `main.gd`'s discrete-action edge detector (`_edge()`) runs once per physics frame, and (per the node tree order established in Hito 0) `main._physics_process` runs *before* `selftest_driver._physics_process` within the same frame. A press-then-release in one driver call is therefore invisible to `main` — it never observes a frame where the action reads "just pressed". Hito 0's existing schedule always held actions across two consecutive ticks (e.g. `inspect_1` pressed at tick 80, released at tick 81); the new approach code broke that pattern.
- Options considered: press-and-release in the same call (broken, as found); explicit two-tick hold, matching the established pattern.
- Decision: any test-driven discrete action must be pressed on tick N and released on tick N+1 (or later), never both within the same driver call. `selftest_driver.gd` now tracks `_interact_press_pt` to enforce this for the dynamically-timed cabin-entry press.
- Why: this is a correctness property of the whole test harness, not a one-off fix — worth recording so a future added check doesn't repeat it.
- Consequences: none beyond the fix itself.
- Risks: none identified.
- Reversal trigger: none expected.
- Files/tests affected: `src/simulator/tests/selftest_driver.gd`.

## DEC-013 — Hito 1 ships gameplay/systems only; textures and a second machine are explicitly out of scope
- Date: 2026-07-27
- Status: accepted
- Context: the user's request covered a large surface (first-person player, cabin access, five cameras, real collision, readable telemetry, objectives, tutorial, texturing, and additional crane types) but also explicitly asked for "un hito por sesión, verificado y guardado" and to avoid another runaway-cost session.
- Evidence: user's own prioritisation in this conversation: experience-first over variety-first, one milestone per session.
- Options considered: attempt everything in one pass; scope this session strictly to the player/cabin/camera/collision/HUD/objective/tutorial systems on the existing overhead crane, deferring textures (H2) and additional machines (H3+).
- Decision: scoped to Hito 1 as listed. Textures/HDRI sky (Poly Haven CC0, pre-approved by the user) and a second machine are the next two milestones, each its own session.
- Why: matches the user's own stated cost-control preference; a large, uncommitted change is also the riskiest thing to leave unverified.
- Consequences: KI-006 (visuals still placeholder) is an explicit, accepted scope boundary, not an oversight.
- Risks: none identified.
- Reversal trigger: user asks to combine milestones in a future session.
- Files/tests affected: none (process decision).
