extends SceneTree
## Deterministic physics-module tests for slice 001 (no scene, no autoloads).
## Run:  godot --headless --path src/simulator --script res://tests/module_tests.gd -- --out=ABS_DIR
## Exits 0 on full pass / 1 on any failure; writes MODULE_TEST_RESULTS.json.

const CableLoadSimScript := preload("res://core/cable_load_sim.gd")
const WindModelScript := preload("res://core/wind_model.gd")
const TelemetryScript := preload("res://core/telemetry.gd")
const ObjectivesScript := preload("res://core/objectives.gd")
const TutorialGuideScript := preload("res://core/tutorial_guide.gd")
const MachineAccessScript := preload("res://core/machine_access.gd")
const LoadBodyScript := preload("res://core/load_body.gd")

const DT := 1.0 / 120.0

var results: Array = []


func _initialize() -> void:
	_test_period_scaling()
	_test_seeded_determinism_and_wind_difference()
	_test_zero_wind_determinism()
	_test_wind_lateral_displacement()
	_test_nan_stress()

	# Hito 1 additions — pure logic, no scene required (see DECISIONS.md DEC-010).
	_test_objectives_pickup_and_delivery()
	_test_objectives_swing_failure()
	_test_tutorial_guide_steps()
	_test_machine_access_state_machine()
	_test_load_body_collision_math()

	var all_ok := true
	for r in results:
		if not r.ok:
			all_ok = false
	var summary := {
		"suite": "slice001_module_tests",
		"date": "2026-07-17",
		"godot": Engine.get_version_info().string,
		"total": results.size(),
		"passed": results.filter(func(r): return r.ok).size(),
		"all_ok": all_ok,
		"tests": results,
	}
	var out_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	if out_dir != "":
		var f := FileAccess.open(out_dir.path_join("MODULE_TEST_RESULTS.json"),
			FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(summary, "  "))
			f.close()
	print("[MODULE_TESTS] %d/%d passed -> %s"
		% [summary.passed, summary.total, "PASS" if all_ok else "FAIL"])
	quit(0 if all_ok else 1)


func _record(id: String, ok: bool, detail: String) -> void:
	results.append({"id": id, "ok": ok, "detail": detail})
	print("[MODULE_TESTS] %s %s -- %s" % ["[OK]  " if ok else "[FAIL]", id, detail])


## Small-angle pendulum, no drag: measured period via zero crossings.
func _measure_period(length: float) -> float:
	var sim = CableLoadSimScript.new()
	sim.setup(Vector3.ZERO, length, 500.0, 0.0, 0.0, DT)
	sim.displace_angle(deg_to_rad(5.0))
	var crossings := PackedFloat64Array()
	var prev_x: float = sim.load_pos.x
	var steps := int(round(40.0 / DT))
	for i in steps:
		sim.step(Vector3.ZERO, Vector3.ZERO)
		var x: float = sim.load_pos.x
		if (prev_x < 0.0) != (x < 0.0):
			var frac := prev_x / (prev_x - x)
			crossings.append((float(i) + frac) * DT)
		prev_x = x
	if crossings.size() < 4:
		return -1.0
	return 2.0 * (crossings[-1] - crossings[0]) / float(crossings.size() - 1)


func _test_period_scaling() -> void:
	var t4 := _measure_period(4.0)
	var t8 := _measure_period(8.0)
	var ideal4 := TAU * sqrt(4.0 / 9.80665)
	var ratio := t8 / t4
	_record("longer_cable_longer_period", t8 > t4 and t4 > 0.0,
		"T(4m)=%.4f s, T(8m)=%.4f s" % [t4, t8])
	_record("period_matches_theory",
		absf(t4 / ideal4 - 1.0) < 0.02 and absf(ratio / sqrt(2.0) - 1.0) < 0.02,
		"T(4m) vs 2*PI*sqrt(L/g)=%.4f s (err %.2f%%); T8/T4=%.4f vs sqrt(2) (err %.2f%%)"
		% [ideal4, absf(t4 / ideal4 - 1.0) * 100.0,
			ratio, absf(ratio / sqrt(2.0) - 1.0) * 100.0])


## Scripted 20 s run: moving support, hoisting cable, optional seeded wind.
func _scripted_hash(seed_value: int, with_wind: bool) -> String:
	var sim = CableLoadSimScript.new()
	sim.setup(Vector3(10.0, 9.0, 9.0), 5.0, 500.0, 2.0, 1.2, DT)
	var wm = WindModelScript.new()
	wm.setup(seed_value, 90.0, 6.0, 2.0, 3.0)
	var tel = TelemetryScript.new()
	var steps := int(round(20.0 / DT))
	for i in steps:
		wm.step(DT)
		var w: Vector3 = wm.wind() if with_wind else Vector3.ZERO
		var t := float(i) * DT
		var sup := Vector3(10.0 + minf(t, 5.0) * 0.4, 9.0,
			9.0 + sin(t * 0.5) * 1.5)
		sim.cable_length = 5.0 - minf(t * 0.1, 2.0)
		sim.step(sup, w)
		tel.record(t, sim.load_pos, sim.support_pos, sim.tension,
			rad_to_deg(sim.swing_angle_rad()), w)
	return tel.state_hash()


func _test_seeded_determinism_and_wind_difference() -> void:
	var a := _scripted_hash(12345, true)
	var b := _scripted_hash(12345, true)
	var c := _scripted_hash(12345, false)
	_record("seeded_run_deterministic", a == b and a != "",
		"hash A=%s, hash B=%s" % [a, b])
	_record("wind_changes_trajectory", a != c,
		"wind hash=%s vs no-wind hash=%s" % [a, c])


func _test_zero_wind_determinism() -> void:
	var a := _scripted_hash(1, false)
	var b := _scripted_hash(999, false)  # seed must not matter with wind off
	_record("zero_wind_deterministic", a == b,
		"no-wind hashes across different seeds: %s vs %s" % [a, b])


## Steady wind (sigma=0) toward +X must push the hanging load laterally.
func _test_wind_lateral_displacement() -> void:
	var offsets := []
	for windy in [false, true]:
		var sim = CableLoadSimScript.new()
		sim.setup(Vector3.ZERO, 6.0, 500.0, 2.0, 1.2, DT)
		var wm = WindModelScript.new()
		wm.setup(1, 0.0, 8.0, 0.0, 3.0)
		var steps := int(round(30.0 / DT))
		var acc := 0.0
		var n := 0
		for i in steps:
			wm.step(DT)
			sim.step(Vector3.ZERO, wm.wind() if windy else Vector3.ZERO)
			if i >= steps / 2:
				acc += sim.load_pos.x
				n += 1
		offsets.append(acc / float(n))
	_record("wind_causes_lateral_displacement",
		absf(offsets[0]) < 1e-6 and offsets[1] > 0.05,
		"mean x offset: %.6f m (no wind) vs %.4f m (8 m/s wind +X)"
		% [offsets[0], offsets[1]])


## Aggressive support motion + hoist sweep + strong gusts: state stays finite.
func _test_nan_stress() -> void:
	var sim = CableLoadSimScript.new()
	sim.setup(Vector3.ZERO, 8.0, 300.0, 2.5, 1.3, DT)
	var wm = WindModelScript.new()
	wm.setup(999, 45.0, 15.0, 5.0, 1.5)
	var steps := int(round(30.0 / DT))
	var violations := 0
	for i in steps:
		var t := float(i) * DT
		wm.step(DT)
		var sup := Vector3(sin(t * TAU * 1.0) * 2.0, sin(t * 3.1) * 0.5,
			cos(t * TAU * 0.7) * 2.0)
		sim.cable_length = 8.0 - 6.8 * absf(sin(t * 0.3))
		sim.step(sup, wm.wind())
		if not (sim.load_pos.is_finite() and sim.load_vel.is_finite()
				and is_finite(sim.tension)):
			violations += 1
	_record("no_nan_or_infinity_under_stress", violations == 0,
		"%d non-finite observations over %d steps (slack/shock + gusts + hoist sweep)"
		% [violations, steps])


func _sc001_test_scenario() -> Dictionary:
	return {
		"pickup": {"x": 0.0, "z": 0.0, "radius": 1.0},
		"dropoff": {"x": 10.0, "z": 0.0, "radius": 1.0},
		"pickup_height_tolerance_m": 1.0,
		"dwell_time_s": 1.0,
		"max_swing_deg_for_success": 2.0,
	}


## Load stays away -> NOT_STARTED; sits over pickup -> CARRYING; sits over
## drop-off -> DELIVERED, with a clean pass (no collisions, swing in budget).
func _test_objectives_pickup_and_delivery() -> void:
	var obj = ObjectivesScript.new()
	obj.load_scenario(_sc001_test_scenario())
	var dt := 1.0 / 60.0
	for i in 30:
		obj.update(dt, 5.0, 5.0, 5.0, 0.0, 0, 0)
	var phase0 := obj.phase_name()
	for i in 90:
		obj.update(dt, 0.0, 0.0, 0.5, 0.0, 0, 0)
	var phase1 := obj.phase_name()
	for i in 90:
		obj.update(dt, 10.0, 0.0, 0.5, 0.5, 0, 0)
	var phase2 := obj.phase_name()
	var sc: Dictionary = obj.score()
	_record("objectives_pickup_then_delivery",
		phase0 == "not_started" and phase1 == "carrying" and phase2 == "delivered" and sc.passed,
		"phases: %s -> %s -> %s, score.passed=%s (max_swing=%.2f)"
		% [phase0, phase1, phase2, sc.passed, sc.max_swing_deg])


## Same route, but swing exceeds the 2 deg budget while carrying: delivered,
## yet marked as a failed lift.
func _test_objectives_swing_failure() -> void:
	var obj = ObjectivesScript.new()
	obj.load_scenario(_sc001_test_scenario())
	var dt := 1.0 / 60.0
	for i in 90:
		obj.update(dt, 0.0, 0.0, 0.5, 0.0, 0, 0)
	for i in 90:
		obj.update(dt, 10.0, 0.0, 0.5, 5.0, 0, 0)
	var sc: Dictionary = obj.score()
	_record("objectives_fails_on_excess_swing",
		obj.phase_name() == "delivered" and not sc.passed,
		"delivered=%s passed=%s max_swing=%.2f (limit 2.0)"
		% [obj.phase_name() == "delivered", sc.passed, sc.max_swing_deg])


## Every gate the player can be stuck behind has an explicit instruction —
## this is the direct fix for "no sé qué hacer" (no hidden 1-2-3 rule).
func _test_tutorial_guide_steps() -> void:
	var cases := [
		[{"access_state": "outside"}, "prompt_approach"],
		[{"access_state": "in_zone"}, "prompt_in_zone"],
		[{"access_state": "climbing_up"}, "prompt_climbing"],
		[{"access_state": "climbing_down"}, "prompt_climbing"],
		[{"access_state": "in_cabin", "powered": false}, "insp_hint"],
		[{"access_state": "in_cabin", "powered": true, "objective_phase": "not_started"}, "obj_not_started"],
		[{"access_state": "in_cabin", "powered": true, "objective_phase": "carrying"}, "obj_carrying"],
		[{"access_state": "in_cabin", "powered": true, "objective_phase": "delivered"}, "obj_delivered"],
	]
	var all_ok := true
	var detail := ""
	for c in cases:
		var got: String = TutorialGuideScript.get_step_id(c[0])
		if got != c[1]:
			all_ok = false
			detail += "state=%s expected=%s got=%s; " % [c[0], c[1], got]
	_record("tutorial_guide_covers_all_states", all_ok,
		detail if not all_ok else "%d/%d state cases correct" % [cases.size(), cases.size()])


## Approach -> interact -> climb -> in cabin -> exit -> climb down -> outside,
## driven purely by position + delta, no scene.
func _test_machine_access_state_machine() -> void:
	var access = MachineAccessScript.new()
	var dt := 1.0 / 60.0
	var access_point := Vector3(2.0, 0.0, 0.75)
	var radius := 1.6
	var duration := 2.5

	access.update(dt, Vector3(20.0, 0.0, 20.0), access_point, radius, duration)
	var s0 := access.state_name()
	access.update(dt, access_point, access_point, radius, duration)
	var s1 := access.state_name()
	var interacted := access.try_interact()
	var s2 := access.state_name()
	var steps := int(ceil(duration / dt)) + 2
	for i in steps:
		access.update(dt, access_point, access_point, radius, duration)
	var s3 := access.state_name()
	var exited := access.try_exit()
	var s4 := access.state_name()
	for i in steps:
		access.update(dt, access_point, access_point, radius, duration)
	# Climb-down finishes mid-loop and correctly re-detects "still standing at
	# the ladder foot" as IN_ZONE — step away before reading the final state.
	access.update(dt, Vector3(20.0, 0.0, 20.0), access_point, radius, duration)
	var s5 := access.state_name()

	_record("machine_access_full_cycle",
		s0 == "outside" and s1 == "in_zone" and interacted and s2 == "climbing_up"
			and s3 == "in_cabin" and exited and s4 == "climbing_down" and s5 == "outside",
		("outside(%s) -> in_zone(%s) -> interact=%s -> climbing_up(%s) -> in_cabin(%s) "
			+ "-> exit=%s -> climbing_down(%s) -> outside(%s)")
			% [s0, s1, interacted, s2, s3, exited, s4, s5])


## Pure collision math: any load-person contact is a violation (lifting-safety
## doctrine, not an energy threshold); AABB overlap; floor/column contact.
func _test_load_body_collision_math() -> void:
	var danger: bool = LoadBodyScript.is_dangerous_impact(Vector3(0.1, 0.0, 0.0), 500.0)
	var push: Vector3 = LoadBodyScript.compute_push_velocity(Vector3(1.0, 0.0, 0.0))
	var overlap_yes: bool = LoadBodyScript.aabb_overlap(
		Vector3.ZERO, Vector3(1, 1, 1), Vector3(0.4, 0, 0), Vector3(1, 1, 1))
	var overlap_no: bool = LoadBodyScript.aabb_overlap(
		Vector3.ZERO, Vector3(1, 1, 1), Vector3(5, 0, 0), Vector3(1, 1, 1))
	var floor_hit: bool = LoadBodyScript.check_floor_contact(Vector3(0, 0.3, 0))
	var floor_clear: bool = LoadBodyScript.check_floor_contact(Vector3(0, 5.0, 0))
	var columns := [{"pos": Vector3(2, 4.35, 0.75), "size": Vector3(0.4, 8.7, 0.4)}]
	var col_hit: bool = LoadBodyScript.check_column_contact(Vector3(2, 4.0, 0.75), columns)
	var col_clear: bool = LoadBodyScript.check_column_contact(Vector3(20, 4.0, 0.75), columns)
	_record("load_body_collision_math",
		danger and push.length() > 0.0 and overlap_yes and not overlap_no
			and floor_hit and not floor_clear and col_hit and not col_clear,
		"danger=%s push_len=%.2f overlap(yes/no)=%s/%s floor(hit/clear)=%s/%s column(hit/clear)=%s/%s"
		% [danger, push.length(), overlap_yes, overlap_no, floor_hit, floor_clear, col_hit, col_clear])
