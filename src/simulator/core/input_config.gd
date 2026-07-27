extends Node
## InputConfig — registers the input map in code so actions exist headless and
## the project file needs no editor-authored [input] section.

const ACTIONS := {
	"bridge_fwd": [KEY_W],
	"bridge_back": [KEY_S],
	"trolley_left": [KEY_A],
	"trolley_right": [KEY_D],
	"hoist_up": [KEY_Q],
	"hoist_down": [KEY_E],
	"fine_mode": [KEY_SHIFT],
	"wind_toggle": [KEY_V],
	"sim_reset": [KEY_R],
	"cam_reset": [KEY_C],
	"lang_toggle": [KEY_L],
	"inspect_1": [KEY_1],
	"inspect_2": [KEY_2],
	"inspect_3": [KEY_3],
	"cam_orbit_left": [KEY_LEFT],
	"cam_orbit_right": [KEY_RIGHT],
	"cam_orbit_up": [KEY_UP],
	"cam_orbit_down": [KEY_DOWN],
	"cam_zoom_in": [KEY_EQUAL],
	"cam_zoom_out": [KEY_MINUS],
}


func _enter_tree() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
