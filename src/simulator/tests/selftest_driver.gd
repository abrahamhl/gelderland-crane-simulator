extends Node
## Headless end-to-end proof driver for slice 001. Instantiated by main.gd only
## when the scene is launched with `-- --selftest [--out=ABS_DIR]`.
## Drives the real input actions tick-by-tick, asserts every success criterion,
## writes JSON results, exits 0 on full pass / 1 on any failure.
##
## Structure: a condition-driven APPROACH pre-phase (walk to the pendant
## control station, collision-probe a column, pick up the pendant — instant,
## DEC-014, no climb) runs on `pre_tick`, using dynamic steering rather than a
## fixed schedule since real-world walk time depends on physics. Once the
## player is controlling the crane, `tick` starts at 0 and everything below
## is the ORIGINAL Hito-0 fixed-tick schedule, unchanged except: the
## bilingual HUD check (now EN/ES by default, not EN/NL — DEC-005) and the
## camera phase (Tab into ORBIT first, since HOME now always means first-
## person — DEC-011/DEC-014). A pendant-putdown check is appended after the
## original finish point.

var main: Node3D
var tick := -1
var checks: Array = []
var out_dir := ""

var pre_tick := -1
var started_controlling := false
const APPROACH_COLUMN_Z := 0.75  # column at world x=10 the spawn point walks straight into
var _collision_sample_a := Vector3.INF
var _collision_sample_b := Vector3.INF
var _collision_checked := false
var _pre_finish_ticks := 0
var _interact_press_pt := -1


func _phase_approach(pt: int) -> void:
	if pt == 0:
		_check("player_spawns_on_foot", not main.is_controlling(),
			"controlling=%s at spawn" % main.is_controlling())

	# Sub-phase A (pt < 420): walk straight into the column at x=10 the spawn
	# sits in front of — proves real CharacterBody3D collision, not just a
	# math check. Sub-phase B (pt >= 420): closed-loop steer toward the
	# ladder's access point and climb in. Column contact (spawn is at x=10,
	# same as the column) happens ~5.8s (~346 ticks) into a straight walk at
	# 2.2 m/s from z=14 to the column face at z~0.95; both samples are taken
	# well after that so a real block reads as "no further motion", not as
	# "still approaching".
	if pt < 600:
		Input.action_press("move_forward")
		if pt == 500:
			_collision_sample_a = main.player.global_position
		if pt == 560:
			_collision_sample_b = main.player.global_position
			var moved := _collision_sample_a.distance_to(_collision_sample_b)
			_check("player_blocked_by_column",
				moved < 0.05 and main.player.global_position.z > APPROACH_COLUMN_Z,
				"drift over 60 ticks while pressing forward into the column: %.4f m (pos.z=%.2f)"
				% [moved, main.player.global_position.z])
			_collision_checked = true
		return
	if pt == 600:
		Input.action_release("move_forward")

	if not main.access.is_controlling():
		var to_access: Vector3 = AppSettings.ACCESS_POINT - main.player.global_position
		if to_access.z < -0.15:
			Input.action_press("move_forward"); Input.action_release("move_back")
		elif to_access.z > 0.15:
			Input.action_press("move_back"); Input.action_release("move_forward")
		else:
			Input.action_release("move_forward"); Input.action_release("move_back")
		if to_access.x < -0.15:
			Input.action_press("move_left"); Input.action_release("move_right")
		elif to_access.x > 0.15:
			Input.action_press("move_right"); Input.action_release("move_left")
		else:
			Input.action_release("move_left"); Input.action_release("move_right")
		Input.action_press("fine_mode")
		# Press/release must land on DIFFERENT ticks: main.gd's edge detector
		# runs once per frame, before this driver's own frame — a press and
		# release in the same call is invisible to it (see DECISIONS.md
		# DEC-012, the same one-tick-held pattern already used below for
		# inspect_1/2/3, bridge_fwd, etc). Picking up the pendant is instant
		# (DEC-014) — no climb to wait through.
		if main.access.state_name() == "in_zone" and _interact_press_pt < 0:
			Input.action_release("move_forward")
			Input.action_release("move_back")
			Input.action_release("move_left")
			Input.action_release("move_right")
			Input.action_release("fine_mode")
			_press("interact")
			_interact_press_pt = pt
		elif _interact_press_pt >= 0 and pt == _interact_press_pt + 1:
			_release("interact")

	if main.is_controlling():
		_check("pendant_pickup_works", true,
			"picked up the pendant after %d approach ticks (%.1f s)" % [pt, pt / 60.0])
		return

	if pt > 1400:
		_check("pendant_pickup_works", false,
			"did not pick up the pendant within %d approach ticks" % pt)
		# Force progress so the rest of the suite can still run and report.
		main.access.state = main.access.State.CONTROLLING

var bridge_x0 := 0.0
var trolley_z0 := 0.0
var hoist0 := 0.0
var hoist_extended := 0.0
var max_swing_deg := 0.0
var pre_wind_sum := 0.0
var pre_wind_n := 0
var wind_sum := 0.0
var wind_n := 0
var wind_max_mag := 0.0
var tel_rows_560 := 0
var cam_default: Transform3D
var cam_orbited := false
var cam_hook_xf: Transform3D
var cam_topdown_xf: Transform3D
var cam_home_xf: Transform3D
var nan_violations := 0

var seg_base := -1
var seg_pass := 0
var snap_a := {}
var snap_b := {}


func _ready() -> void:
	main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	print("[SELFTEST] start (out=%s)" % out_dir)


func _check(id: String, ok: bool, detail: String) -> void:
	checks.append({"id": id, "ok": ok, "detail": detail})
	print("[SELFTEST] %s %s -- %s" % ["[OK]  " if ok else "[FAIL]", id, detail])


func _press(a: String) -> void:
	Input.action_press(a)


func _release(a: String) -> void:
	Input.action_release(a)


func _physics_process(_delta: float) -> void:
	if not started_controlling:
		pre_tick += 1
		_phase_approach(pre_tick)
		if main.is_controlling():
			started_controlling = true
		return

	tick += 1

	if not (main.sim.load_pos.is_finite() and main.sim.load_vel.is_finite()
			and is_finite(main.sim.tension)):
		nan_violations += 1

	# Phase 1 — unpowered start, inspection gates movement.
	if tick == 0:
		bridge_x0 = main.rig.bridge_x
		_check("unpowered_start", main.rig.powered == false,
			"rig.powered=%s at first tick" % main.rig.powered)
	if tick == 5:
		_press("bridge_fwd")
	if tick == 75:
		_release("bridge_fwd")
		_check("no_motion_before_inspection",
			absf(main.rig.bridge_x - bridge_x0) < 1e-9,
			"bridge_x %.9f vs %.9f after 70 ticks of input while unpowered"
			% [main.rig.bridge_x, bridge_x0])
	if tick == 80: _press("inspect_1")
	if tick == 81: _release("inspect_1")
	if tick == 84: _press("inspect_2")
	if tick == 85: _release("inspect_2")
	if tick == 88: _press("inspect_3")
	if tick == 89: _release("inspect_3")
	if tick == 95:
		_check("inspection_enables_power", main.rig.powered == true,
			"powered=%s after checks 1-3" % main.rig.powered)

	# Phase 2 — bridge responds.
	if tick == 100:
		_press("bridge_fwd")
	if tick == 220:
		_release("bridge_fwd")
	if tick == 226:
		_check("bridge_responds", main.rig.bridge_x > bridge_x0 + 0.5,
			"bridge_x %.3f -> %.3f" % [bridge_x0, main.rig.bridge_x])
		trolley_z0 = main.rig.trolley_z

	# Phase 3 — trolley responds.
	if tick == 230:
		_press("trolley_right")
	if tick == 350:
		_release("trolley_right")
	if tick == 356:
		_check("trolley_responds", main.rig.trolley_z > trolley_z0 + 0.4,
			"trolley_z %.3f -> %.3f" % [trolley_z0, main.rig.trolley_z])
		hoist0 = main.rig.hoist_length

	# Phase 4 — hoist changes cable length both ways.
	if tick == 360:
		_press("hoist_down")
	if tick == 480:
		_release("hoist_down")
	if tick == 535:  # accel-limited drive coasts ~47 ticks after release; settle first
		hoist_extended = main.rig.hoist_length
		_check("hoist_extends", hoist_extended > hoist0 + 0.3,
			"cable %.3f m -> %.3f m" % [hoist0, hoist_extended])
	if tick == 540:
		_press("hoist_up")
	if tick == 660:
		_release("hoist_up")
	if tick == 715:
		_check("hoist_retracts", main.rig.hoist_length < hoist_extended - 0.15,
			"cable %.3f m -> %.3f m" % [hoist_extended, main.rig.hoist_length])

	# Phase 5 — free swing, telemetry growth, cable visual, HUD.
	if tick == 720:
		tel_rows_560 = main.telemetry.count()
	if tick >= 720 and tick < 960:
		max_swing_deg = maxf(max_swing_deg, rad_to_deg(main.sim.swing_angle_rad()))
		pre_wind_sum += main.sim.load_pos.z - main.sim.support_pos.z
		pre_wind_n += 1
	if tick == 960:
		_check("load_swings", max_swing_deg > 0.5,
			"max swing %.2f deg during coast window" % max_swing_deg)
		var rows: int = main.telemetry.count()
		_check("telemetry_updates", rows - tel_rows_560 == 240,
			"rows %d -> %d over 240 ticks" % [tel_rows_560, rows])
		var clen: float = main.cable_visual_length()
		var expect: float = (main.sim.load_pos - main.sim.support_pos).length()
		_check("cable_visible_matches",
			main.cable_visible() and absf(clen - expect) < 0.05,
			"cable visual %.3f m vs sim %.3f m" % [clen, expect])
		var hud: String = main.hud_status_text()
		_check("hud_populated_bilingual",
			"Cable length" in hud and "Longitud de cable" in hud and hud.length() > 40,
			"HUD %d chars, EN/ES bilingual labels present (default pair per DEC-011)"
			% hud.length())

	# Phase 6 — wind changes behaviour.
	if tick == 970: _press("wind_toggle")
	if tick == 971: _release("wind_toggle")
	if tick >= 1060 and tick < 1660:
		wind_sum += main.sim.load_pos.z - main.sim.support_pos.z
		wind_n += 1
		wind_max_mag = maxf(wind_max_mag, main.applied_wind.length())
	if tick == 1660:
		_check("wind_applied", main.wind_enabled and wind_max_mag > 1.0,
			"enabled=%s, peak applied wind %.2f m/s"
			% [main.wind_enabled, wind_max_mag])
		var mean_pre := pre_wind_sum / float(pre_wind_n)
		var mean_wind := wind_sum / float(wind_n)
		_check("wind_changes_behaviour", mean_wind - mean_pre > 0.02,
			"mean lateral offset %.4f m (no wind) -> %.4f m (wind toward +Z)"
			% [mean_pre, mean_wind])

	# Phase 7 — camera modes + orbit + camera reset. HOME is always
	# first-person now (DEC-014 removed the cabin), so Tab into ORBIT before
	# exercising the orbit-drag + reset behaviour that Hito 0 tested bare.
	if tick == 1670: _press("camera_cycle")   # HOME -> ORBIT
	if tick == 1671: _release("camera_cycle")
	if tick == 1678:
		cam_default = main.get_camera_transform()
	if tick == 1680:
		_press("cam_orbit_left")
	if tick == 1710:
		_release("cam_orbit_left")
	if tick == 1712:
		cam_orbited = not main.get_camera_transform().is_equal_approx(cam_default)
	if tick == 1713: _press("cam_reset")
	if tick == 1714: _release("cam_reset")
	if tick == 1720:
		_check("camera_reset",
			cam_orbited and main.get_camera_transform().is_equal_approx(cam_default),
			"orbited=%s, transform restored=%s" % [cam_orbited,
			main.get_camera_transform().is_equal_approx(cam_default)])

	# Phase 7b — the other three views (ORBIT -> HOOK -> TOPDOWN -> HOME) must
	# each be a genuinely different camera transform. HOME here is the
	# operator's first-person view standing at the pendant station.
	if tick == 1723: _press("camera_cycle")   # ORBIT -> HOOK
	if tick == 1724: _release("camera_cycle")
	if tick == 1726: cam_hook_xf = main.get_camera_transform()
	if tick == 1728: _press("camera_cycle")   # HOOK -> TOPDOWN
	if tick == 1729: _release("camera_cycle")
	if tick == 1731: cam_topdown_xf = main.get_camera_transform()
	if tick == 1733: _press("camera_cycle")   # TOPDOWN -> HOME (first-person)
	if tick == 1734: _release("camera_cycle")
	if tick == 1736:
		cam_home_xf = main.get_camera_transform()
		_check("camera_modes_distinct",
			not cam_hook_xf.is_equal_approx(cam_topdown_xf)
				and not cam_topdown_xf.is_equal_approx(cam_home_xf)
				and not cam_hook_xf.is_equal_approx(cam_home_xf)
				and not cam_home_xf.is_equal_approx(cam_default),
			"hook=%s topdown=%s home/first-person=%s orbit_default=%s (all distinct)"
			% [cam_hook_xf.origin, cam_topdown_xf.origin, cam_home_xf.origin,
				cam_default.origin])

	# Phase 8 — reset determinism: two identical scripted segments must match.
	if tick == 1760:
		_press("sim_reset")
	if tick == 1761:
		_release("sim_reset")
	if tick == 1762:
		seg_base = tick
	if tick == 2150:
		_press("sim_reset")
	if tick == 2151:
		_release("sim_reset")
	if tick == 2152:
		seg_base = tick
	if seg_base > 0 and tick >= seg_base:
		_run_segment(tick - seg_base)

	# Phase 9 — putting the pendant down must hand control back to the
	# on-foot player. This is instant (DEC-014), unlike Hito 1's climb-down.
	if tick == 2545: _press("exit_cabin")
	if tick == 2546: _release("exit_cabin")
	if tick == 2550:
		_check("pendant_putdown_works", not main.is_controlling(),
			"controlling=%s, %d ticks after pressing F" % [main.is_controlling(), 2550 - 2545])

	if tick == 2720:
		_finish()


## Fixed input schedule replayed identically after each reset.
func _run_segment(st: int) -> void:
	if st == 10: _press("inspect_1")
	if st == 11: _release("inspect_1")
	if st == 12: _press("inspect_2")
	if st == 13: _release("inspect_2")
	if st == 14: _press("inspect_3")
	if st == 15: _release("inspect_3")
	if st == 30: _press("bridge_fwd")
	if st == 120: _release("bridge_fwd")
	if st == 130: _press("hoist_down")
	if st == 190: _release("hoist_down")
	if st == 200: _press("wind_toggle")
	if st == 201: _release("wind_toggle")
	if st == 380:
		var snap := {
			"hash": main.telemetry.state_hash(),
			"bridge_x": main.rig.bridge_x,
			"load": main.sim.load_pos,
			"ticks": main.elapsed_ticks,
		}
		if seg_pass == 0:
			snap_a = snap
			seg_pass = 1
			seg_base = -1
		else:
			snap_b = snap
			seg_base = -1
			_check("reset_deterministic",
				snap_a.hash == snap_b.hash
					and snap_a.bridge_x == snap_b.bridge_x
					and snap_a.load == snap_b.load
					and snap_a.ticks == snap_b.ticks,
				"pass A hash %s (%d ticks) vs pass B hash %s (%d ticks)"
				% [snap_a.hash, snap_a.ticks, snap_b.hash, snap_b.ticks])


func _finish() -> void:
	_check("no_nan_or_infinity", nan_violations == 0 and not main.halted,
		"%d non-finite observations, halted=%s" % [nan_violations, main.halted])
	var all_ok := true
	for c in checks:
		if not c.ok:
			all_ok = false
	var summary := {
		"suite": "slice001_scene_selftest",
		"date": "2026-07-17",
		"godot": Engine.get_version_info().string,
		"total": checks.size(),
		"passed": checks.filter(func(c): return c.ok).size(),
		"all_ok": all_ok,
		"checks": checks,
	}
	if out_dir != "":
		var f := FileAccess.open(out_dir.path_join("SELFTEST_RESULTS.json"),
			FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(summary, "  "))
			f.close()
	print("[SELFTEST] %d/%d checks passed -> %s"
		% [summary.passed, summary.total, "PASS" if all_ok else "FAIL"])
	get_tree().quit(0 if all_ok else 1)
