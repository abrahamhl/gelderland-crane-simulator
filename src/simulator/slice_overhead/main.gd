extends Node3D
## Slice 001 — overhead-crane playable proof (prefab hall, Gelderland).
## Orchestrator: world geometry, on-foot player, crane cabin access, camera
## director, HUD/tutorial and the SC-001 pickup/drop-off objective are all
## composed here from separate, mostly-unit-testable modules. The four
## original physics modules (CraneRig, CableLoadSim, WindModel, Telemetry)
## are wired in unchanged — see DECISIONS.md DEC-005..DEC-009 for the H1
## design choices (fixed cabin, always-advancing wind, R resets the machine
## not the operator's position, etc).

const CraneRigScript := preload("res://core/crane_rig.gd")
const CableLoadSimScript := preload("res://core/cable_load_sim.gd")
const WindModelScript := preload("res://core/wind_model.gd")
const TelemetryScript := preload("res://core/telemetry.gd")
const PlayerControllerScript := preload("res://core/player_controller.gd")
const CameraDirectorScript := preload("res://core/camera_director.gd")
const WorldBuilderScript := preload("res://core/world_builder.gd")
const MachineAccessScript := preload("res://core/machine_access.gd")
const LoadBodyScript := preload("res://core/load_body.gd")
const ObjectivesScript := preload("res://core/objectives.gd")
const TutorialGuideScript := preload("res://core/tutorial_guide.gd")
const HudScript := preload("res://core/hud.gd")

const SCENARIO_PATH := "res://scenarios/SC-001_palet_500kg.json"
const LADDER_BOTTOM := Vector3(2.35, 0.3, 1.3)
const LADDER_TOP := Vector3(2.0, 8.7, 1.8)

const DT := 1.0 / 60.0
const SUBSTEPS := 2              # cable sim runs at 120 Hz inside the 60 Hz tick

var rig: RefCounted
var sim: RefCounted
var wind_model: RefCounted
var telemetry: RefCounted

var wind_enabled := false
var applied_wind := Vector3.ZERO
var inspection := [false, false, false]
var elapsed_ticks := 0
var halted := false

var world: Node3D
var player: CharacterBody3D
var cam: Node3D
var access: RefCounted
var load_body: Area3D
var objectives: RefCounted
var hud: CanvasLayer
var scenario: Dictionary

var _prev_action := {}
var _prev_floor_contact := false
var _prev_column_contact := false
var _tick_collisions := 0
var _tick_violations := 0


func _ready() -> void:
	world = WorldBuilderScript.new()
	add_child(world)

	access = MachineAccessScript.new()
	objectives = ObjectivesScript.new()
	scenario = ObjectivesScript.load_from_file(SCENARIO_PATH)
	if not scenario.is_empty():
		scenario.pickup = AppSettings.PICKUP_ZONE
		scenario.dropoff = AppSettings.DROPOFF_ZONE
	objectives.load_scenario(scenario)

	world.build()

	player = PlayerControllerScript.new()
	player.add_to_group("player")
	player.position = AppSettings.PLAYER_SPAWN
	add_child(player)

	load_body = LoadBodyScript.new()
	add_child(load_body)
	load_body.player_hit.connect(_on_load_hit_player)

	cam = CameraDirectorScript.new()
	cam.player = player
	cam.in_cabin_getter = Callable(access, "is_in_cabin")
	add_child(cam)

	hud = HudScript.new()
	add_child(hud)
	hud.build()

	if not OS.get_cmdline_user_args().has("--selftest"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_reset_all()

	if "--selftest" in OS.get_cmdline_user_args():
		var driver_script: GDScript = load("res://tests/selftest_driver.gd")
		add_child(driver_script.new())


func _physics_process(_delta: float) -> void:
	access.update(DT, player.global_position, AppSettings.ACCESS_POINT,
		AppSettings.ACCESS_RADIUS_M, AppSettings.CLIMB_DURATION_S)
	_handle_discrete_actions()
	_drive_player_or_climb()

	if halted:
		return

	var cmd_bridge := 0.0
	var cmd_trolley := 0.0
	var cmd_hoist := 0.0
	if access.is_in_cabin():
		cmd_bridge = Input.get_axis("bridge_back", "bridge_fwd")
		cmd_trolley = Input.get_axis("trolley_left", "trolley_right")
		cmd_hoist = Input.get_axis("hoist_up", "hoist_down")
	rig.step(DT, cmd_bridge, cmd_trolley, cmd_hoist,
		Input.is_action_pressed("fine_mode"))
	sim.cable_length = rig.hoist_length

	# Wind sequence always advances so the seeded state at time t is the same
	# no matter when the operator toggles it; the toggle only gates application.
	wind_model.step(DT)
	applied_wind = wind_model.wind() if wind_enabled else Vector3.ZERO

	var target_support: Vector3 = rig.support_point()
	var prev_support: Vector3 = sim.support_pos
	for i in SUBSTEPS:
		var s := prev_support.lerp(target_support, float(i + 1) / float(SUBSTEPS))
		sim.step(s, applied_wind)

	if not (sim.load_pos.is_finite() and sim.load_vel.is_finite()
			and is_finite(sim.tension)):
		halted = true  # fail visibly; never continue corrupted state
		return

	elapsed_ticks += 1
	telemetry.record(elapsed_ticks * DT, sim.load_pos, sim.support_pos,
		sim.tension, rad_to_deg(sim.swing_angle_rad()), applied_wind)

	load_body.sync_to_sim(sim.load_pos)
	_check_structure_contacts()
	objectives.update(DT, sim.load_pos.x, sim.load_pos.z, _load_bottom_height(),
		rad_to_deg(sim.swing_angle_rad()), _tick_collisions, _tick_violations)
	_tick_collisions = 0
	_tick_violations = 0


func _process(delta: float) -> void:
	cam.rig = rig
	cam.sim = sim
	cam.update(delta)
	_sync_visuals()
	_update_hud(delta)


# --- per-frame visuals ------------------------------------------------------

func _sync_visuals() -> void:
	if rig == null:
		return
	var bx: float = rig.bridge_x
	world.girder.position.x = bx
	world.truck_a.position.x = bx
	world.truck_b.position.x = bx
	world.trolley.position = Vector3(bx, 8.9, rig.trolley_z)
	var sup: Vector3 = sim.support_pos
	var lp: Vector3 = sim.load_pos
	world.load_box.position = lp + Vector3(0.0, -0.5, 0.0)
	_update_cable_visual(sup, lp)


func _update_cable_visual(a: Vector3, b: Vector3) -> void:
	var d := b - a
	var l := d.length()
	world.cable_mesh.visible = l > 0.01
	if not world.cable_mesh.visible:
		return
	var y := d / l
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y)
	world.cable_mesh.global_transform = Transform3D(Basis(x, y * l, z), (a + b) * 0.5)


# --- input -------------------------------------------------------------

## Edge detector that works for both hardware keys and Input.action_press
## injected by the self-test, independent of node processing order.
func _edge(action: String) -> bool:
	var now := Input.is_action_pressed(action)
	var was: bool = _prev_action.get(action, false)
	_prev_action[action] = now
	return now and not was


func _handle_discrete_actions() -> void:
	if access.is_in_cabin():
		for i in 3:
			if _edge("inspect_%d" % (i + 1)):
				inspection[i] = true
				if inspection.count(true) == 3 and not rig.powered:
					rig.powered = true
	if _edge("wind_toggle"):
		wind_enabled = not wind_enabled
	if _edge("lang_toggle"):
		Loc.cycle()
	if _edge("camera_cycle"):
		cam.cycle_mode()
	if _edge("cam_reset"):
		if cam.mode == cam.Mode.ORBIT:
			cam.reset_orbit()
		else:
			cam.go_home()
	if _edge("help_toggle"):
		hud.toggle_help()
	if _edge("toggle_mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE \
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if _edge("interact") and access.state == access.State.IN_ZONE:
		access.try_interact()
	if _edge("exit_cabin") and access.is_in_cabin():
		access.try_exit()
	if _edge("sim_reset"):
		_reset_all()


func _drive_player_or_climb() -> void:
	if access.is_climbing():
		player.move_enabled = false
		var t: float = access.climb_progress()
		player.global_position = LADDER_BOTTOM.lerp(LADDER_TOP, t) if access.climbing_up() \
			else LADDER_TOP.lerp(LADDER_BOTTOM, t)
		player.velocity = Vector3.ZERO
		return
	if access.is_in_cabin():
		player.move_enabled = false
		player.global_position = LADDER_TOP
		player.velocity = Vector3.ZERO
		return
	player.move_enabled = true
	player.physics_step(DT)


# --- lifecycle -----------------------------------------------------------

## Resets the MACHINE (rig, cable, wind, telemetry, objective) — a training
## "retry". Does not move the operator: pressing R inside the cabin resets
## the lift, it does not eject you back onto the factory floor.
func _reset_all() -> void:
	rig = CraneRigScript.new()
	rig.hoist_length = AppSettings.START_CABLE_LEN_M
	rig.powered = false  # crane starts dead until the pre-use inspection passes
	sim = CableLoadSimScript.new()
	sim.setup(rig.support_point(), rig.hoist_length, AppSettings.LOAD_MASS_KG,
		AppSettings.LOAD_DRAG_AREA_M2, AppSettings.LOAD_DRAG_CD, DT / SUBSTEPS)
	wind_model = WindModelScript.new()
	wind_model.setup(AppSettings.WIND_SEED, AppSettings.WIND_DIR_DEG,
		AppSettings.WIND_SPEED_MS, AppSettings.WIND_GUST_SIGMA,
		AppSettings.WIND_GUST_TAU_S)
	telemetry = TelemetryScript.new()
	wind_enabled = false
	applied_wind = Vector3.ZERO
	inspection = [false, false, false]
	elapsed_ticks = 0
	halted = false
	_prev_floor_contact = false
	_prev_column_contact = false
	objectives.load_scenario(scenario)
	cam.reset_orbit()


# --- structure / player collision -----------------------------------------

func _load_bottom_height() -> float:
	return sim.load_pos.y - 0.95  # load_pos is the cable attachment point


func _check_structure_contacts() -> void:
	var floor_hit: bool = LoadBodyScript.check_floor_contact(sim.load_pos)
	var column_hit: bool = LoadBodyScript.check_column_contact(sim.load_pos, world.columns)
	if floor_hit and not _prev_floor_contact:
		_tick_collisions += 1
		_tick_violations += 1
		load_body.hits_count += 1
		load_body.violations_count += 1
	if column_hit and not _prev_column_contact:
		_tick_collisions += 1
		_tick_violations += 1
		load_body.hits_count += 1
		load_body.violations_count += 1
	_prev_floor_contact = floor_hit
	_prev_column_contact = column_hit


func _on_load_hit_player(push_velocity: Vector3) -> void:
	if access.is_in_cabin():
		return
	_tick_collisions += 1
	_tick_violations += 1
	player.velocity += push_velocity
	hud.flash_danger()


# --- HUD / tutorial --------------------------------------------------------

func _tutorial_text() -> String:
	var step_id := TutorialGuideScript.get_step_id({
		"access_state": access.state_name(),
		"powered": rig.powered,
		"objective_phase": objectives.phase_name(),
	})
	if step_id == "insp_hint":
		var missing := PackedStringArray()
		var keys := ["insp_1", "insp_2", "insp_3"]
		for i in 3:
			if not inspection[i]:
				missing.append("%d %s" % [i + 1, Loc.t(keys[i])])
		return "%s: %s" % [Loc.t("insp_hint"), ", ".join(missing)]
	return Loc.t(step_id)


## Picks a language field from a raw {en,es,nl} scenario dict, mirroring
## Loc.t()'s combination rule without needing the string to live in loc.gd.
func _scenario_text(field: Dictionary) -> String:
	if field.is_empty():
		return ""
	match Loc.lang:
		Loc.LANG_EN:
			return field.get("en", "")
		Loc.LANG_ES:
			return field.get("es", field.get("en", ""))
		Loc.LANG_NL:
			return field.get("nl", field.get("en", ""))
		_:
			return "%s / %s" % [field.get("en", ""), field.get("es", "")]


func _update_hud(delta: float) -> void:
	var ctx := {
		"halted": halted,
		"powered": rig.powered,
		"inspection": inspection,
		"cable_length": rig.hoist_length,
		"bridge_x": rig.bridge_x,
		"trolley_z": rig.trolley_z,
		"time_s": elapsed_ticks * DT,
		"telemetry_rows": telemetry.count(),
		"camera_view": cam.active_view_name(),
		"swing_deg": rad_to_deg(sim.swing_angle_rad()),
		"tension_n": sim.tension,
		"mass_kg": AppSettings.LOAD_MASS_KG,
		"wind": applied_wind,
		"wind_speed": applied_wind.length(),
		"pickup_zone": AppSettings.PICKUP_ZONE,
		"dropoff_zone": AppSettings.DROPOFF_ZONE,
		"in_cabin": access.is_in_cabin(),
		"player_xz": Vector2(player.global_position.x, player.global_position.z),
		"tutorial_text": _tutorial_text(),
		"objective_text": "%s\n%s" % [_scenario_text(scenario.get("title", {})),
			_obj_phase_text()],
		"score": objectives.score(),
	}
	hud.update(delta, ctx)


func _obj_phase_text() -> String:
	match objectives.phase_name():
		"carrying": return Loc.t("obj_carrying")
		"delivered": return Loc.t("obj_delivered")
		_: return Loc.t("obj_not_started")


# --- accessors used by the self-test driver --------------------------------

func is_in_cabin() -> bool:
	return access.is_in_cabin()


func get_camera_transform() -> Transform3D:
	return cam.camera.global_transform


func cable_visible() -> bool:
	return world.cable_mesh.visible


func cable_visual_length() -> float:
	return world.cable_mesh.basis.y.length()


func hud_status_text() -> String:
	return hud.status_label.text
