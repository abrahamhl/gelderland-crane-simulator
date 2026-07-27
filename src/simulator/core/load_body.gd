extends Area3D
## LoadBody — the collision surface for the suspended load. Position always
## FOLLOWS cable_load_sim's math (the sim keeps authority over the physics);
## this node exists only to detect contact against the player and structure,
## per .claude/rules/simulation-physics.md: "separate physical collision
## volumes from safety/near-miss volumes." The push/violation math is exposed
## as static pure functions so it is unit-testable without a scene.

signal player_hit(push_velocity: Vector3)
signal structure_hit(kind: String)

const LOAD_SIZE := Vector3(1.2, 0.9, 1.2)

var hits_count := 0
var violations_count := 0
var _last_player_contact_frame := -1


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = LOAD_SIZE
	shape.shape = box
	add_child(shape)
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func sync_to_sim(load_pos: Vector3) -> void:
	global_position = load_pos + Vector3(0.0, -0.5, 0.0)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		hits_count += 1
		violations_count += 1
		var away := (body.global_position - global_position)
		away.y = 0.0
		if away.length() < 0.01:
			away = Vector3.FORWARD
		emit_signal("player_hit", compute_push_velocity(away.normalized()))


## Any contact between a suspended load and a person is a safety violation
## regardless of speed — standard lifting-safety doctrine ("never work under
## a suspended load"), not an energy threshold.
static func is_dangerous_impact(_load_vel: Vector3, _load_mass: float) -> bool:
	return true


## Push imparted to a struck player: outward horizontal shove, small vertical
## lift for game feel. Clamped so a slow-swinging load doesn't fling the
## player unrealistically.
static func compute_push_velocity(away_dir: Vector3) -> Vector3:
	var d := away_dir
	d.y = 0.0
	if d.length() < 0.001:
		d = Vector3.FORWARD
	d = d.normalized()
	return d * 3.0 + Vector3(0.0, 1.5, 0.0)


static func aabb_overlap(pos_a: Vector3, size_a: Vector3, pos_b: Vector3, size_b: Vector3) -> bool:
	var half_a := size_a * 0.5
	var half_b := size_b * 0.5
	return absf(pos_a.x - pos_b.x) <= (half_a.x + half_b.x) \
		and absf(pos_a.y - pos_b.y) <= (half_a.y + half_b.y) \
		and absf(pos_a.z - pos_b.z) <= (half_a.z + half_b.z)


## Load resting/crashing on the hall floor (floor top at y=0).
static func check_floor_contact(load_pos: Vector3) -> bool:
	return (load_pos.y - LOAD_SIZE.y * 0.5) <= 0.0


## Load swung into a column. `columns` is the Array of {pos, size} produced
## by WorldBuilder.
static func check_column_contact(load_pos: Vector3, columns: Array) -> bool:
	for c in columns:
		if aabb_overlap(load_pos, LOAD_SIZE, c.pos, c.size):
			return true
	return false
