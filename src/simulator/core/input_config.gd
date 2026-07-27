extends Node
## InputConfig — registers the input map in code so actions exist headless and
## the project file needs no editor-authored [input] section.
##
## Several physical keys are intentionally bound to two actions (e.g. W drives
## both "move_forward" on foot and "bridge_fwd" in the cabin). Only one of the
## pair is ever read at a time — main.gd gates which set is active based on
## whether the player is on foot or in the crane cabin (see MachineAccess).

const ACTIONS := {
	# on-foot player movement
	"move_forward": [KEY_W],
	"move_back": [KEY_S],
	"move_left": [KEY_A],
	"move_right": [KEY_D],
	"jump": [KEY_SPACE],
	"interact": [KEY_E],           # also hoist_down in-cabin; contexts don't overlap
	"exit_cabin": [KEY_F],
	"toggle_mouse_capture": [KEY_ESCAPE],

	# crane cabin controls (unchanged from slice 001)
	"bridge_fwd": [KEY_W],
	"bridge_back": [KEY_S],
	"trolley_left": [KEY_A],
	"trolley_right": [KEY_D],
	"hoist_up": [KEY_Q],
	"hoist_down": [KEY_E],
	"fine_mode": [KEY_SHIFT],      # also sprint on foot
	"wind_toggle": [KEY_V],
	"sim_reset": [KEY_R],
	"cam_reset": [KEY_C],
	"camera_cycle": [KEY_TAB],
	"help_toggle": [KEY_F1],
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
