extends Node
## Headless end-to-end proof driver for slice 001. Instantiated by main.gd only
## when the scene is launched with `-- --selftest [--out=ABS_DIR]`.
## Drives the real input actions tick-by-tick, asserts every success criterion,
## writes JSON results, exits 0 on full pass / 1 on any failure.

var main: Node3D
var tick := -1
var checks: Array = []
var out_dir := ""

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
			"Kabellengte" in hud and "Cable length" in hud and hud.length() > 40,
			"HUD %d chars, bilingual labels present" % hud.length())

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

	# Phase 7 — camera orbit + camera reset.
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

	if tick == 2540:
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
