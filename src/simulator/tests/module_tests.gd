extends SceneTree
## Deterministic physics-module tests for slice 001 (no scene, no autoloads).
## Run:  godot --headless --path src/simulator --script res://tests/module_tests.gd -- --out=ABS_DIR
## Exits 0 on full pass / 1 on any failure; writes MODULE_TEST_RESULTS.json.

const CableLoadSimScript := preload("res://core/cable_load_sim.gd")
const WindModelScript := preload("res://core/wind_model.gd")
const TelemetryScript := preload("res://core/telemetry.gd")

const DT := 1.0 / 120.0

var results: Array = []


func _initialize() -> void:
	_test_period_scaling()
	_test_seeded_determinism_and_wind_difference()
	_test_zero_wind_determinism()
	_test_wind_lateral_displacement()
	_test_nan_stress()

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
