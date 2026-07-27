extends Node3D
## CameraDirector — five viewpoints on one Camera3D, switched by mode.
## HOME resolves to CABIN or WALK automatically depending on whether the
## player is currently in the crane cabin. Tab cycles the "away" views
## (orbit / hook / top-down); C returns to HOME and resets the orbit rig.

enum Mode { HOME, ORBIT, HOOK, TOPDOWN }

const CAM_YAW_DEFAULT := 210.0
const CAM_PITCH_DEFAULT := 18.0
const CAM_DIST_DEFAULT := 15.0

var camera: Camera3D
var mode: int = Mode.HOME

var orbit_yaw := 0.0
var orbit_pitch := 0.0
var orbit_dist := 0.0

var player: Node3D           # PlayerController
var rig: RefCounted          # CraneRig
var sim: RefCounted          # CableLoadSim
var in_cabin_getter: Callable


func _ready() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 8.0, -10.0)
	add_child(camera)
	camera.current = true
	reset_orbit()


func reset_orbit() -> void:
	orbit_yaw = deg_to_rad(CAM_YAW_DEFAULT)
	orbit_pitch = deg_to_rad(CAM_PITCH_DEFAULT)
	orbit_dist = CAM_DIST_DEFAULT


func cycle_mode() -> void:
	mode = (mode + 1) % 4


func go_home() -> void:
	mode = Mode.HOME
	reset_orbit()


func active_view_name() -> String:
	if mode == Mode.ORBIT:
		return "orbit"
	if mode == Mode.HOOK:
		return "hook"
	if mode == Mode.TOPDOWN:
		return "topdown"
	return "cabin" if in_cabin_getter.call() else "walk"


func update(delta: float) -> void:
	match mode:
		Mode.ORBIT:
			_update_orbit(delta)
		Mode.HOOK:
			_update_hook()
		Mode.TOPDOWN:
			_update_topdown()
		_:
			if in_cabin_getter.call():
				_update_cabin()
			else:
				_update_walk()


func _update_walk() -> void:
	camera.global_transform = player.eye_transform()


func _update_cabin() -> void:
	camera.global_transform = Transform3D(Basis(), AppSettings.CABIN_ANCHOR)
	var look_at_pos: Vector3 = sim.load_pos if sim != null else rig.support_point()
	camera.look_at(look_at_pos, Vector3.UP)


func _update_orbit(delta: float) -> void:
	orbit_yaw += Input.get_axis("cam_orbit_right", "cam_orbit_left") * 1.6 * delta
	orbit_pitch = clampf(
		orbit_pitch + Input.get_axis("cam_orbit_down", "cam_orbit_up") * 1.2 * delta,
		deg_to_rad(5.0), deg_to_rad(80.0))
	orbit_dist = clampf(
		orbit_dist + Input.get_axis("cam_zoom_in", "cam_zoom_out") * 8.0 * delta,
		5.0, 40.0)
	var pivot := Vector3(rig.bridge_x, 5.5, rig.trolley_z)
	var offset := Vector3(
		cos(orbit_yaw) * cos(orbit_pitch),
		sin(orbit_pitch),
		sin(orbit_yaw) * cos(orbit_pitch)) * orbit_dist
	camera.position = pivot + offset
	camera.look_at(pivot)


func _update_hook() -> void:
	var load: Vector3 = sim.load_pos
	var support: Vector3 = sim.support_pos
	camera.global_transform = Transform3D(Basis(), support + Vector3(1.5, 0.3, 1.5))
	camera.look_at(load, Vector3.UP)


func _update_topdown() -> void:
	var pivot := Vector3(rig.bridge_x, 0.0, rig.trolley_z)
	camera.global_transform = Transform3D(Basis(), pivot + Vector3(0.0, 42.0, 0.001))
	camera.look_at(pivot, Vector3.FORWARD)
