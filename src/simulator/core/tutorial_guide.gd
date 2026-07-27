extends RefCounted
## TutorialGuide — pure state -> instruction mapping. No hidden rules: every
## gate the player must satisfy (approach, climb, inspection, objective) has
## an explicit on-screen instruction key here. hud.gd localizes the returned
## key via Loc.t(); tests/module_tests.gd exercises this with synthetic state
## dictionaries, no scene required.
##
## Expected `state` keys: access_state (String, MachineAccess.state_name()),
## powered (bool), objective_phase (String, Objectives.phase_name()).

static func get_step_id(state: Dictionary) -> String:
	var access_state: String = state.get("access_state", "outside")
	match access_state:
		"outside":
			return "prompt_approach"
		"in_zone":
			return "prompt_in_zone"
		"climbing_up", "climbing_down":
			return "prompt_climbing"
		"in_cabin":
			if not state.get("powered", false):
				return "insp_hint"
			match state.get("objective_phase", "not_started"):
				"carrying":
					return "obj_carrying"
				"delivered":
					return "obj_delivered"
				_:
					return "obj_not_started"
		_:
			return ""
