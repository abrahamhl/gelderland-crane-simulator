extends Node3D
## WorldBuilder — procedural hall, crane visuals, ladder marker and scenario
## zone markers. Split out of main.gd so main.gd stays an orchestrator.
## Floor and columns get real StaticBody3D colliders so the on-foot player can
## walk the hall and be physically blocked by structure (KI-004 follow-up).

const FLOOR_HALF_X := 32.0   # matches the visual floor box (center 30, size 64)
const FLOOR_HALF_Z := 11.0   # matches the visual floor box (center 9, size 22)

var girder: MeshInstance3D
var truck_a: MeshInstance3D
var truck_b: MeshInstance3D
var trolley: MeshInstance3D
var cable_mesh: MeshInstance3D
var load_box: MeshInstance3D
var safety_ring: MeshInstance3D   # follows the load's XZ each frame (main.gd)
var columns: Array = []      # world-space AABB-ish {pos: Vector3, size: Vector3}


func build() -> void:
	_build_environment()
	_build_hall_and_columns()
	_build_boundary_walls()
	_build_crane_visuals()
	_build_safety_ring()
	_build_control_station()
	_build_zone_marker(AppSettings.PICKUP_ZONE, Loc.t("zone_a"))
	_build_zone_marker(AppSettings.DROPOFF_ZONE, Loc.t("zone_b"))


func _box(size: Vector3, pos: Vector3, color: Color, unshaded: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	add_child(mi)
	return mi


func _static_box(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.15, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.82)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.53, 0.58)
	env.fog_density = 0.006
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)


func _build_hall_and_columns() -> void:
	var concrete := Color(0.32, 0.33, 0.35)
	var structure := Color(0.45, 0.47, 0.5)
	_box(Vector3(64.0, 0.2, 22.0), Vector3(30.0, -0.1, 9.0), concrete)  # floor
	_static_box(Vector3(64.0, 0.2, 22.0), Vector3(30.0, -0.1, 9.0))
	_box(Vector3(64.0, 0.01, 0.12), Vector3(30.0, 0.006, 3.0),
		Color(0.85, 0.75, 0.2))  # walkway marking

	for xi in 8:
		var x := 2.0 + float(xi) * 8.0
		for z in [0.75, 17.25]:
			var pos := Vector3(x, 4.35, z)
			var size := Vector3(0.4, 8.7, 0.4)
			_box(size, pos, structure)
			_static_box(size, pos)
			columns.append({"pos": pos, "size": size})

	var rail := Color(0.55, 0.35, 0.2)
	_box(Vector3(60.0, 0.3, 0.3), Vector3(30.0, 8.85, 0.75), rail)   # runway
	_box(Vector3(60.0, 0.3, 0.3), Vector3(30.0, 8.85, 17.25), rail)  # runway


## Invisible walls at the floor edges: real gravity means an unbounded floor
## would let the player walk off into the void.
func _build_boundary_walls() -> void:
	var t := 0.5
	var h := 4.0
	_static_box(Vector3(t, h, FLOOR_HALF_Z * 2.0), Vector3(30.0 - FLOOR_HALF_X, h * 0.5, 9.0))
	_static_box(Vector3(t, h, FLOOR_HALF_Z * 2.0), Vector3(30.0 + FLOOR_HALF_X, h * 0.5, 9.0))
	_static_box(Vector3(FLOOR_HALF_X * 2.0, h, t), Vector3(30.0, h * 0.5, 9.0 - FLOOR_HALF_Z))
	_static_box(Vector3(FLOOR_HALF_X * 2.0, h, t), Vector3(30.0, h * 0.5, 9.0 + FLOOR_HALF_Z))


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


## Ground-level pendant control station: a post-mounted control box the
## operator walks up to and "picks up" (instant) — this crane has no cabin
## and nothing to climb (DEC-014). x=1.0 keeps it geometrically outside the
## bridge's reach (bridge_limits.x = 2.0), so it is a provably safe spot.
func _build_control_station() -> void:
	var base: Vector3 = AppSettings.ACCESS_POINT
	var post_color := Color(0.35, 0.37, 0.4)
	var box_color := Color(0.9, 0.6, 0.05)
	_box(Vector3(0.12, 1.1, 0.12), base + Vector3(0.0, 0.55, 0.0), post_color)
	_box(Vector3(0.35, 0.45, 0.18), base + Vector3(0.0, 1.15, 0.1), box_color)
	# a couple of raised buttons for visual clarity
	_box(Vector3(0.08, 0.05, 0.05), base + Vector3(-0.08, 1.28, 0.2), Color(0.2, 0.8, 0.2))
	_box(Vector3(0.08, 0.05, 0.05), base + Vector3(0.08, 1.28, 0.2), Color(0.85, 0.15, 0.15))

	var label := Label3D.new()
	label.text = Loc.t("access_label")
	label.position = base + Vector3(0.0, 1.9, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.modulate = box_color
	label.outline_size = 6
	add_child(label)

	# floor decal marking the pickup radius
	var access_mat := Color(0.9, 0.5, 0.05, 0.5)
	var plane := PlaneMesh.new()
	plane.size = Vector2(AppSettings.ACCESS_RADIUS_M, AppSettings.ACCESS_RADIUS_M) * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = access_mat
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.mesh.material = mat
	mi.position = base + Vector3(0.0, 0.02, 0.0)
	add_child(mi)


## Translucent red disc on the floor that follows the load's XZ each frame
## (main.gd), marking the near-miss/caution radius — larger than the load's
## exact physical collision box, per .claude/rules/simulation-physics.md.
func _build_safety_ring() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(AppSettings.LOAD_SAFETY_RADIUS_M, AppSettings.LOAD_SAFETY_RADIUS_M) * 2.0
	safety_ring = MeshInstance3D.new()
	safety_ring.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.2, 0.2, 0.18)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	safety_ring.mesh.material = mat
	add_child(safety_ring)


## Flat coloured disk on the floor + a thin vertical beam, so origin/destination
## are unmistakable from across the hall (fixes "no sé hacia dónde está mapeado").
func _build_zone_marker(zone: Dictionary, label_text: String) -> void:
	var pos := Vector3(zone.x, 0.03, zone.z)
	var plane := PlaneMesh.new()
	plane.size = Vector2(zone.radius, zone.radius) * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = zone.color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.mesh.material = mat
	mi.position = pos
	add_child(mi)

	var beam := _box(Vector3(0.04, 9.0, 0.04), pos + Vector3(0.0, 4.5, 0.0),
		Color(zone.color.r, zone.color.g, zone.color.b, 0.35), true)
	beam.mesh.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var label := Label3D.new()
	label.text = label_text
	label.position = pos + Vector3(0.0, 2.2, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	label.modulate = zone.color
	label.outline_size = 6
	add_child(label)
