extends Node3D
## Slice 001 — overhead-crane physics proof (prefab hall, Gelderland).
## Wires the existing deterministic modules (CraneRig, CableLoadSim, WindModel,
## Telemetry) into one playable scene: unpowered start with pre-use inspection,
## bilingual HUD, orbit camera, seeded wind, deterministic reset.
## Geometry is built procedurally so the whole slice is reviewable as code.

const CraneRigScript := preload("res://core/crane_rig.gd")
const CableLoadSimScript := preload("res://core/cable_load_sim.gd")
const WindModelScript := preload("res://core/wind_model.gd")
const TelemetryScript := preload("res://core/telemetry.gd")

const DT := 1.0 / 60.0
const SUBSTEPS := 2              # cable sim runs at 120 Hz inside the 60 Hz tick

const CAM_YAW_DEFAULT := 210.0   # degrees
const CAM_PITCH_DEFAULT := 18.0
const CAM_DIST_DEFAULT := 15.0

var rig: RefCounted
var sim: RefCounted
var wind_model: RefCounted
var telemetry: RefCounted

var wind_enabled := false
var applied_wind := Vector3.ZERO
var inspection := [false, false, false]
var elapsed_ticks := 0
var halted := false

var cam_yaw := 0.0
var cam_pitch := 0.0
var cam_dist := 0.0

var camera: Camera3D
var girder: MeshInstance3D
var truck_a: MeshInstance3D
var truck_b: MeshInstance3D
var trolley: MeshInstance3D
var cable_mesh: MeshInstance3D
var load_box: MeshInstance3D
var status_label: Label
var controls_label: Label

var _prev_action := {}


func _ready() -> void:
	_build_environment()
	_build_crane_visuals()
	_build_camera()
	_build_hud()
	_reset_all()
	if "--selftest" in OS.get_cmdline_user_args():
		var driver_script: GDScript = load("res://tests/selftest_driver.gd")
		add_child(driver_script.new())


func _physics_process(_delta: float) -> void:
	_handle_discrete_actions()
	if halted:
		return

	var cmd_bridge := Input.get_axis("bridge_back", "bridge_fwd")
	var cmd_trolley := Input.get_axis("trolley_left", "trolley_right")
	var cmd_hoist := Input.get_axis("hoist_up", "hoist_down")  # + = pay out
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


func _process(delta: float) -> void:
	_update_camera(delta)
	_sync_visuals()
	_update_hud()


# --- input -----------------------------------------------------------------

## Edge detector that works for both hardware keys and Input.action_press
## injected by the self-test, independent of node processing order.
func _edge(action: String) -> bool:
	var now := Input.is_action_pressed(action)
	var was: bool = _prev_action.get(action, false)
	_prev_action[action] = now
	return now and not was


func _handle_discrete_actions() -> void:
	for i in 3:
		if _edge("inspect_%d" % (i + 1)):
			inspection[i] = true
			if inspection.count(true) == 3 and not rig.powered:
				rig.powered = true
	if _edge("wind_toggle"):
		wind_enabled = not wind_enabled
	if _edge("lang_toggle"):
		Loc.cycle()
	if _edge("cam_reset"):
		_reset_camera()
	if _edge("sim_reset"):
		_reset_all()


# --- lifecycle -------------------------------------------------------------

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
	_reset_camera()


func _reset_camera() -> void:
	cam_yaw = deg_to_rad(CAM_YAW_DEFAULT)
	cam_pitch = deg_to_rad(CAM_PITCH_DEFAULT)
	cam_dist = CAM_DIST_DEFAULT
	_apply_camera()


# --- camera ----------------------------------------------------------------

func _update_camera(delta: float) -> void:
	cam_yaw += Input.get_axis("cam_orbit_right", "cam_orbit_left") * 1.6 * delta
	cam_pitch = clampf(
		cam_pitch + Input.get_axis("cam_orbit_down", "cam_orbit_up") * 1.2 * delta,
		deg_to_rad(5.0), deg_to_rad(80.0))
	cam_dist = clampf(
		cam_dist + Input.get_axis("cam_zoom_in", "cam_zoom_out") * 8.0 * delta,
		5.0, 40.0)
	_apply_camera()


func _apply_camera() -> void:
	if camera == null or rig == null:
		return
	var pivot := Vector3(rig.bridge_x, 5.5, rig.trolley_z)
	var offset := Vector3(
		cos(cam_yaw) * cos(cam_pitch),
		sin(cam_pitch),
		sin(cam_yaw) * cos(cam_pitch)) * cam_dist
	camera.position = pivot + offset
	camera.look_at(pivot)


# --- scene construction ----------------------------------------------------

func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	add_child(mi)
	return mi


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.15, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.82)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)

	var concrete := Color(0.32, 0.33, 0.35)
	var structure := Color(0.45, 0.47, 0.5)
	_box(Vector3(64.0, 0.2, 22.0), Vector3(30.0, -0.1, 9.0), concrete)  # floor
	_box(Vector3(64.0, 0.01, 0.12), Vector3(30.0, 0.006, 3.0),
		Color(0.85, 0.75, 0.2))  # walkway marking
	for xi in 8:
		var x := 2.0 + float(xi) * 8.0
		_box(Vector3(0.4, 8.7, 0.4), Vector3(x, 4.35, 0.75), structure)
		_box(Vector3(0.4, 8.7, 0.4), Vector3(x, 4.35, 17.25), structure)
	var rail := Color(0.55, 0.35, 0.2)
	_box(Vector3(60.0, 0.3, 0.3), Vector3(30.0, 8.85, 0.75), rail)   # runway
	_box(Vector3(60.0, 0.3, 0.3), Vector3(30.0, 8.85, 17.25), rail)  # runway


func _build_crane_visuals() -> void:
	var steel := Color(0.2, 0.45, 0.75)
	girder = _box(Vector3(0.5, 0.5, 18.0), Vector3(10.0, 9.25, 9.0), steel)
	truck_a = _box(Vector3(1.2, 0.35, 0.6), Vector3(10.0, 8.95, 0.75), steel)
	truck_b = _box(Vector3(1.2, 0.35, 0.6), Vector3(10.0, 8.95, 17.25), steel)
	trolley = _box(Vector3(0.9, 0.4, 0.9), Vector3(10.0, 8.9, 9.0),
		Color(0.85, 0.55, 0.1))
	load_box = _box(Vector3(1.2, 0.9, 1.2), Vector3(10.0, 3.5, 9.0),
		Color(0.75, 0.6, 0.15))

	cable_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.02
	cyl.height = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.1)
	cyl.material = mat
	cable_mesh.mesh = cyl
	add_child(cable_mesh)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 8.0, -10.0)  # placeholder; reset positions it
	add_child(camera)
	camera.current = true


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(8.0, 8.0)
	layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	margin.add_child(vbox)
	status_label = Label.new()
	controls_label = Label.new()
	controls_label.modulate = Color(1.0, 1.0, 1.0, 0.75)
	for l in [status_label, controls_label]:
		l.add_theme_font_size_override("font_size", 13)
		vbox.add_child(l)


# --- per-frame visuals and HUD --------------------------------------------

func _sync_visuals() -> void:
	if rig == null:
		return
	var bx: float = rig.bridge_x
	girder.position.x = bx
	truck_a.position.x = bx
	truck_b.position.x = bx
	trolley.position = Vector3(bx, 8.9, rig.trolley_z)
	var sup: Vector3 = sim.support_pos
	var lp: Vector3 = sim.load_pos
	load_box.position = lp + Vector3(0.0, -0.5, 0.0)
	_update_cable_visual(sup, lp)


func _update_cable_visual(a: Vector3, b: Vector3) -> void:
	var d := b - a
	var l := d.length()
	cable_mesh.visible = l > 0.01
	if not cable_mesh.visible:
		return
	var y := d / l
	var x := y.cross(Vector3.FORWARD)
	if x.length() < 0.01:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y)
	cable_mesh.global_transform = Transform3D(Basis(x, y * l, z), (a + b) * 0.5)


func _update_hud() -> void:
	if rig == null:
		return
	var lines := PackedStringArray()
	lines.append(Loc.t("title"))
	if halted:
		lines.append("!! " + Loc.t("fault"))
	var power_s: String = Loc.t("on") if rig.powered else Loc.t("off")
	var insp := PackedStringArray()
	for i in 3:
		insp.append("%d[%s]" % [i + 1, "x" if inspection[i] else " "])
	lines.append("%s: %s   %s: %s" % [Loc.t("power"), power_s,
		Loc.t("inspection"), " ".join(insp)])
	if not rig.powered:
		lines.append("-> %s: 1 %s, 2 %s, 3 %s" % [Loc.t("insp_hint"),
			Loc.t("insp_1"), Loc.t("insp_2"), Loc.t("insp_3")])
	lines.append("%s: %.2f m   %s: %.0f kg" % [Loc.t("cable"),
		rig.hoist_length, Loc.t("mass"), AppSettings.LOAD_MASS_KG])
	lines.append("%s: %.2f deg   %s: %.2f kN" % [Loc.t("swing"),
		rad_to_deg(sim.swing_angle_rad()), Loc.t("tension"),
		sim.tension / 1000.0])
	var wind_s: String
	if wind_enabled:
		wind_s = "%.1f m/s (%.1f, %.1f, %.1f)" % [applied_wind.length(),
			applied_wind.x, applied_wind.y, applied_wind.z]
	else:
		wind_s = Loc.t("off")
	lines.append("%s: %s" % [Loc.t("wind"), wind_s])
	lines.append("%s: %.2f m   %s: %.2f m" % [Loc.t("bridge"), rig.bridge_x,
		Loc.t("trolley"), rig.trolley_z])
	lines.append("%s: %.1f s   %d %s" % [Loc.t("time"), elapsed_ticks * DT,
		telemetry.count(), Loc.t("rows")])
	status_label.text = "\n".join(lines)
	controls_label.text = Loc.t("controls")


# --- accessors used by the self-test driver --------------------------------

func get_camera_transform() -> Transform3D:
	return camera.global_transform


func cable_visible() -> bool:
	return cable_mesh.visible


func cable_visual_length() -> float:
	return cable_mesh.basis.y.length()


func hud_status_text() -> String:
	return status_label.text
