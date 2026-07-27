# Changelog

## 0.4.0 — 2026-07-27 — Hito 1: "Entrar a la grúa"
First-person playable pass over the Hito-0 physics proof. The crane and its physics are unchanged; everything around them is new.

### Added
- First-person on-foot player with real collision (walk the hall, get blocked by columns/walls, can't walk through the crane structure).
- Climbable access to a fixed operator cabin: walk to the marked ladder, press E, a scripted 2.5 s climb, then full crane control.
- Five camera views: cabin (first-person, looks at the hook), on-foot first-person, orbit, hook-cam, top-down. `Tab` cycles, `C` resets the active one.
- Real load-vs-player collision: the load can push you if you stand under it, and it is always flagged as a safety violation, regardless of speed — that's the actual safety rule, not a game simplification.
- Load-vs-floor and load-vs-column contact detection (logged as collisions; no physical bounce/rest response yet).
- On-screen, always-visible tutorial instruction — no more silent "press 1-2-3" rule. Every gate (walk to the ladder, climb in, complete the inspection, do the lift) is explained on screen as it becomes relevant.
- First scenario, SC-001: move a 500 kg pallet from a marked yellow zone to a marked blue zone, keeping swing under 2° — with a live score (time, max swing, collisions, safety violations).
- Redesigned HUD: a needle-style swing gauge with green/amber/red zones, a tension bar, a wind compass, and a top-down minimap showing the crane, the pickup/drop-off zones and the player.
- **Spanish added to the interface.** The HUD was English/Dutch only; it is now English/Spanish by default (Dutch still available via the language key). This was the direct fix for a reported unreadable HUD.
- Double-click launchers (`START_SIMULATOR.bat`, `RUN_TESTS.bat`) — carried over from the previous session, verified again this session.

### Verification
- 12/12 pure-logic unit tests pass (objectives scoring, tutorial instructions, cabin access state machine, collision math).
- 21/21 end-to-end scene tests pass — the original 16 Hito-0 checks (pendulum physics, wind, determinism, HUD, camera) all still pass unchanged, plus 5 new ones covering the player, collision, cabin entry/exit and the camera modes.
- Clean headless import, clean windowed launch.

### Known limitations (see `logs/KNOWN_ISSUES.md`)
- Visuals are still flat-coloured placeholder geometry — no textures yet (planned for the next milestone).
- The operator cabin is fixed in place, not mounted on the moving bridge.
- Load-vs-structure contact is detected and scored but has no physical response (the load doesn't bounce or come to rest against what it hits).
- The visual appearance of the new HUD/gauges has not been visually inspected this session — only verified to run without error. Look at it before trusting the layout.

## 0.2.0
- Desktop-first V2 starter; legacy browser skills deactivated.
