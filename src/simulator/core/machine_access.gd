extends RefCounted
## MachineAccess — pure state machine for approach/climb/cabin/exit. No scene
## dependency: fed a player position each frame, returns state for main.gd to
## route input and drive the camera. Kept as plain logic so it is unit
## testable (see tests/module_tests.gd) without instancing the 3D scene.

enum State { OUTSIDE, IN_ZONE, CLIMBING_UP, IN_CABIN, CLIMBING_DOWN }

var state: int = State.OUTSIDE
var _climb_t := 0.0
var _climb_duration := 1.0
var _climbing_up := true


func reset() -> void:
	state = State.OUTSIDE
	_climb_t = 0.0


## player_pos: world position of the player's feet. Returns nothing; call
## state after. duration_s: how long a climb (up or down) takes.
func update(delta: float, player_pos: Vector3, access_point: Vector3,
		access_radius: float, duration_s: float) -> void:
	match state:
		State.OUTSIDE, State.IN_ZONE:
			var flat_dist := Vector2(player_pos.x - access_point.x,
				player_pos.z - access_point.z).length()
			state = State.IN_ZONE if flat_dist <= access_radius else State.OUTSIDE
		State.CLIMBING_UP, State.CLIMBING_DOWN:
			_climb_t += delta
			if _climb_t >= _climb_duration:
				state = State.IN_CABIN if _climbing_up else State.OUTSIDE
		State.IN_CABIN:
			pass
	_climb_duration = duration_s


## Returns true if the interact/exit press actually changed state.
func try_interact() -> bool:
	if state == State.IN_ZONE:
		state = State.CLIMBING_UP
		_climbing_up = true
		_climb_t = 0.0
		return true
	return false


func try_exit() -> bool:
	if state == State.IN_CABIN:
		state = State.CLIMBING_DOWN
		_climbing_up = false
		_climb_t = 0.0
		return true
	return false


func is_in_cabin() -> bool:
	return state == State.IN_CABIN


func is_climbing() -> bool:
	return state == State.CLIMBING_UP or state == State.CLIMBING_DOWN


## 0..1 progress through the current climb; 0 when not climbing.
func climb_progress() -> float:
	if not is_climbing() or _climb_duration <= 0.0:
		return 0.0
	return clampf(_climb_t / _climb_duration, 0.0, 1.0)


func climbing_up() -> bool:
	return _climbing_up


func state_name() -> String:
	match state:
		State.OUTSIDE: return "outside"
		State.IN_ZONE: return "in_zone"
		State.CLIMBING_UP: return "climbing_up"
		State.IN_CABIN: return "in_cabin"
		State.CLIMBING_DOWN: return "climbing_down"
		_: return "?"
