extends CanvasLayer
## HUD — game-style heads-up display: swing gauge, tension bar, wind compass,
## top-down minimap, objective panel, always-visible tutorial instruction,
## contextual controls, and an F1 help overlay. Everything routes through
## Loc.t() for EN/ES/NL (see loc.gd). Gauge geometry note: this session's
## verification is headless (no way to screenshot the rendered window from
## here) — the drawing MATH is straightforward and documented below, but
## actually looking at it requires the user to run the simulator.

class SwingGauge extends Control:
	var swing_deg := 0.0
	const MAX_DEG := 30.0
	const GREEN_DEG := 5.0
	const AMBER_DEG := 15.0

	func _ang(deg: float) -> float:
		return -PI / 2.0 + clampf(deg / MAX_DEG, 0.0, 1.0) * (PI / 2.0)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.42
		draw_arc(c, r, _ang(0.0), _ang(GREEN_DEG), 16, Color(0.2, 0.85, 0.3), 8.0)
		draw_arc(c, r, _ang(GREEN_DEG), _ang(AMBER_DEG), 16, Color(0.95, 0.75, 0.1), 8.0)
		draw_arc(c, r, _ang(AMBER_DEG), _ang(MAX_DEG), 16, Color(0.9, 0.2, 0.2), 8.0)
		var a := _ang(swing_deg)
		draw_line(c, c + Vector2(cos(a), sin(a)) * r, Color(1, 1, 1), 3.0)
		draw_circle(c, 5.0, Color(1, 1, 1))
		draw_string(ThemeDB.fallback_font, Vector2(4, size.y - 4), "%.1f°" % swing_deg,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))

	func set_swing(deg: float) -> void:
		swing_deg = deg
		queue_redraw()


class TensionBar extends Control:
	var frac := 0.0
	var tension_kn := 0.0

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w * 0.5, h), Color(0.2, 0.85, 0.3))
		draw_rect(Rect2(w * 0.5, 0, w * 0.25, h), Color(0.95, 0.75, 0.1))
		draw_rect(Rect2(w * 0.75, 0, w * 0.25, h), Color(0.9, 0.2, 0.2))
		var x := clampf(frac, 0.0, 1.0) * w
		draw_line(Vector2(x, -3), Vector2(x, h + 3), Color(1, 1, 1), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(4, h - 4), "%.2f kN" % tension_kn,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0))

	## reference_n: static tension at rated mass (mass * g). Bar spans 0..2x.
	func set_tension(tension_n: float, reference_n: float) -> void:
		tension_kn = tension_n / 1000.0
		frac = tension_n / maxf(reference_n * 2.0, 1.0)
		queue_redraw()


class WindCompass extends Control:
	var dir := Vector2.ZERO   # (world x, world z), unnormalized ok
	var speed := 0.0

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.42
		draw_arc(c, r, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
		if speed > 0.05:
			var d := dir.normalized()
			draw_line(c, c + Vector2(d.x, d.y) * r, Color(0.4, 0.8, 1.0), 4.0)
			draw_circle(c + Vector2(d.x, d.y) * r, 4.0, Color(0.4, 0.8, 1.0))
		draw_string(ThemeDB.fallback_font, Vector2(4, size.y - 4), "%.1f m/s" % speed,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))


class Minimap extends Control:
	var bridge_x := 10.0
	var trolley_z := 9.0
	var pickup: Dictionary = {}
	var dropoff: Dictionary = {}
	var player_pos = null   # Vector2 or null

	const WORLD_X0 := 0.0
	const WORLD_X1 := 62.0
	const WORLD_Z0 := -2.0
	const WORLD_Z1 := 20.0

	func _world_to_local(x: float, z: float) -> Vector2:
		var u := (x - WORLD_X0) / (WORLD_X1 - WORLD_X0)
		var v := (z - WORLD_Z0) / (WORLD_Z1 - WORLD_Z0)
		return Vector2(u * size.x, v * size.y)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.1, 0.12, 0.85))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.4), false, 2.0)
		if not pickup.is_empty():
			_draw_zone(pickup, Color(0.95, 0.85, 0.1))
		if not dropoff.is_empty():
			_draw_zone(dropoff, Color(0.15, 0.55, 0.95))
		var hook := _world_to_local(bridge_x, trolley_z)
		draw_circle(hook, 5.0, Color(0.85, 0.55, 0.1))
		if player_pos != null:
			var p := _world_to_local(player_pos.x, player_pos.y)
			draw_circle(p, 4.0, Color(1, 1, 1))

	func _draw_zone(zone: Dictionary, color: Color) -> void:
		var p := _world_to_local(zone.x, zone.z)
		var rad := float(zone.radius) / (WORLD_X1 - WORLD_X0) * size.x
		draw_circle(p, rad, Color(color.r, color.g, color.b, 0.5))
		draw_arc(p, rad, 0.0, TAU, 24, color, 2.0)


## Big game-style key cap: highlights the instant its bound action is held.
## Requested explicitly so the player can SEE which key does what and confirm
## a press registered, instead of reading small printed text.
class KeyCap extends Control:
	var label := ""
	var active := false

	func _draw() -> void:
		var bg := Color(0.95, 0.95, 1.0, 0.95) if active else Color(0.16, 0.16, 0.2, 0.85)
		var fg := Color(0.05, 0.05, 0.08) if active else Color(0.9, 0.9, 0.95)
		draw_rect(Rect2(Vector2.ZERO, size), bg)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.5), false, 2.0)
		var font := ThemeDB.fallback_font
		var fs := 18
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, (size - text_size) * 0.5 + Vector2(0.0, text_size.y * 0.7), label,
			HORIZONTAL_ALIGNMENT_CENTER, -1, fs, fg)

	func set_state(new_label: String, is_active: bool) -> void:
		if new_label != label or is_active != active:
			label = new_label
			active = is_active
			queue_redraw()


var swing_gauge: SwingGauge
var tension_bar: TensionBar
var wind_compass: WindCompass
var minimap: Minimap
var status_label: Label
var tutorial_panel: PanelContainer
var tutorial_label: Label
var objective_label: Label
var controls_label: Label
var help_panel: PanelContainer
var help_label: Label
var mass_label: Label
var danger_label: Label
var caution_label: Label
var impact_label: Label

var key_w: KeyCap
var key_a: KeyCap
var key_s: KeyCap
var key_d: KeyCap
var key_shift: KeyCap
var key_extra: KeyCap
var key_e: KeyCap

var help_visible := false
var _danger_timer := 0.0
var _caution_timer := 0.0
var _impact_timer := 0.0
var _impact_key := "impact_floor"


func build() -> void:
	layer = 1

	var top_left := PanelContainer.new()
	top_left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_left.position = Vector2(8, 8)
	add_child(top_left)
	var tl_box := VBoxContainer.new()
	top_left.add_child(tl_box)
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 14)
	tl_box.add_child(status_label)

	tutorial_panel = PanelContainer.new()
	tutorial_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tutorial_panel.position = Vector2(8, 140)
	var tut_style := StyleBoxFlat.new()
	tut_style.bg_color = Color(0.1, 0.35, 0.55, 0.85)
	tut_style.set_content_margin_all(10)
	tutorial_panel.add_theme_stylebox_override("panel", tut_style)
	add_child(tutorial_panel)
	tutorial_label = Label.new()
	tutorial_label.add_theme_font_size_override("font_size", 16)
	tutorial_label.custom_minimum_size = Vector2(480, 0)
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	tutorial_panel.add_child(tutorial_label)

	danger_label = Label.new()
	danger_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	danger_label.position = Vector2(-260, 60)
	danger_label.add_theme_font_size_override("font_size", 22)
	danger_label.modulate = Color(1, 0.2, 0.2)
	danger_label.visible = false
	add_child(danger_label)

	caution_label = Label.new()
	caution_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	caution_label.position = Vector2(-260, 90)
	caution_label.add_theme_font_size_override("font_size", 18)
	caution_label.modulate = Color(1, 0.75, 0.15)
	caution_label.visible = false
	add_child(caution_label)

	impact_label = Label.new()
	impact_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	impact_label.position = Vector2(-260, 118)
	impact_label.add_theme_font_size_override("font_size", 18)
	impact_label.modulate = Color(1, 0.85, 0.4)
	impact_label.visible = false
	add_child(impact_label)

	var top_right := PanelContainer.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.position = Vector2(-340, 8)
	add_child(top_right)
	var tr_box := VBoxContainer.new()
	top_right.add_child(tr_box)
	objective_label = Label.new()
	objective_label.add_theme_font_size_override("font_size", 14)
	objective_label.custom_minimum_size = Vector2(320, 0)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	tr_box.add_child(objective_label)

	var gauges := HBoxContainer.new()
	gauges.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	gauges.position = Vector2(8, -190)
	gauges.add_theme_constant_override("separation", 14)
	add_child(gauges)

	swing_gauge = SwingGauge.new()
	swing_gauge.custom_minimum_size = Vector2(110, 90)
	gauges.add_child(swing_gauge)

	tension_bar = TensionBar.new()
	tension_bar.custom_minimum_size = Vector2(160, 28)
	tension_bar.position.y = 30
	gauges.add_child(tension_bar)

	wind_compass = WindCompass.new()
	wind_compass.custom_minimum_size = Vector2(90, 90)
	gauges.add_child(wind_compass)

	mass_label = Label.new()
	mass_label.add_theme_font_size_override("font_size", 20)
	mass_label.position.y = 30
	gauges.add_child(mass_label)

	minimap = Minimap.new()
	minimap.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	minimap.position = Vector2(-220, -190)
	minimap.custom_minimum_size = Vector2(210, 180)
	add_child(minimap)

	controls_label = Label.new()
	controls_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls_label.position = Vector2(8, -34)
	controls_label.modulate = Color(1, 1, 1, 0.8)
	controls_label.add_theme_font_size_override("font_size", 13)
	add_child(controls_label)

	_build_key_overlay()

	help_panel = PanelContainer.new()
	help_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var help_style := StyleBoxFlat.new()
	help_style.bg_color = Color(0.05, 0.05, 0.07, 0.92)
	help_panel.add_theme_stylebox_override("panel", help_style)
	help_panel.visible = false
	add_child(help_panel)
	var help_box := VBoxContainer.new()
	help_box.set_anchors_preset(Control.PRESET_CENTER)
	help_panel.add_child(help_box)
	help_label = Label.new()
	help_label.add_theme_font_size_override("font_size", 18)
	help_box.add_child(help_label)


## Big WASD-style key cluster, bottom-centre, each cap lighting up the instant
## its bound action is held — requested explicitly so presses are visible.
func _build_key_overlay() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	root.position = Vector2(-177, -172)
	add_child(root)

	var cap := Vector2(48, 48)
	key_w = _make_key_cap(root, Vector2(52, 0), cap)
	key_a = _make_key_cap(root, Vector2(0, 52), cap)
	key_s = _make_key_cap(root, Vector2(52, 52), cap)
	key_d = _make_key_cap(root, Vector2(104, 52), cap)
	key_shift = _make_key_cap(root, Vector2(170, 26), Vector2(70, 48))
	key_extra = _make_key_cap(root, Vector2(250, 26), cap)
	key_e = _make_key_cap(root, Vector2(306, 26), cap)


func _make_key_cap(parent: Control, pos: Vector2, cap_size: Vector2) -> KeyCap:
	var k := KeyCap.new()
	k.position = pos
	k.size = cap_size
	parent.add_child(k)
	return k


func toggle_help() -> void:
	help_visible = not help_visible
	help_panel.visible = help_visible


func flash_danger() -> void:
	danger_label.visible = true
	_danger_timer = 1.5


## Caution is lighter than danger: near the load's safety radius but not
## actually touching it (see .claude/rules/simulation-physics.md).
func flash_caution() -> void:
	if not danger_label.visible:
		caution_label.visible = true
		_caution_timer = 0.6


## Structure hit (floor/column): a physical bounce already gives the visual
## feedback, this just names what happened. key: "impact_floor"|"impact_column".
func flash_impact(key: String) -> void:
	_impact_key = key
	impact_label.visible = true
	_impact_timer = 1.2


func update(delta: float, ctx: Dictionary) -> void:
	if _danger_timer > 0.0:
		_danger_timer -= delta
		if _danger_timer <= 0.0:
			danger_label.visible = false
	danger_label.text = "!! " + Loc.t("danger_load")

	if _caution_timer > 0.0:
		_caution_timer -= delta
		if _caution_timer <= 0.0:
			caution_label.visible = false
	caution_label.text = Loc.t("caution_near")

	if _impact_timer > 0.0:
		_impact_timer -= delta
		if _impact_timer <= 0.0:
			impact_label.visible = false
	impact_label.text = Loc.t(_impact_key)

	var lines := PackedStringArray()
	lines.append(Loc.t("title"))
	if ctx.get("halted", false):
		lines.append("!! " + Loc.t("fault"))
	var power_s: String = Loc.t("on") if ctx.powered else Loc.t("off")
	var insp: Array = ctx.inspection
	var insp_s := PackedStringArray()
	for i in 3:
		insp_s.append("%d[%s]" % [i + 1, "x" if insp[i] else " "])
	lines.append("%s: %s   %s: %s" % [Loc.t("power"), power_s,
		Loc.t("inspection"), " ".join(insp_s)])
	lines.append("%s: %.2f m   %s: %.2f m" % [Loc.t("cable"), ctx.cable_length,
		Loc.t("bridge"), ctx.bridge_x])
	lines.append("%s: %.2f m   %s: %.1f s" % [Loc.t("trolley"), ctx.trolley_z,
		Loc.t("time"), ctx.time_s])
	lines.append("%s: %d %s" % [Loc.t("rows"), ctx.telemetry_rows, Loc.t("rows")])
	lines.append("[%s] %s" % [Loc.lang_name(), Loc.t("cam_" + ctx.get("camera_view", "walk"))])
	status_label.text = "\n".join(lines)

	swing_gauge.set_swing(ctx.swing_deg)
	tension_bar.set_tension(ctx.tension_n, ctx.mass_kg * 9.80665)
	wind_compass.dir = Vector2(ctx.wind.x, ctx.wind.z)
	wind_compass.speed = ctx.wind_speed
	wind_compass.queue_redraw()
	mass_label.text = "%.0f kg\n%s" % [ctx.mass_kg, Loc.t("mass")]

	minimap.bridge_x = ctx.bridge_x
	minimap.trolley_z = ctx.trolley_z
	minimap.pickup = ctx.pickup_zone
	minimap.dropoff = ctx.dropoff_zone
	minimap.player_pos = ctx.get("player_xz", null)
	minimap.queue_redraw()

	tutorial_label.text = ctx.get("tutorial_text", "")

	var obj_lines := PackedStringArray()
	obj_lines.append(Loc.t("objective"))
	obj_lines.append(ctx.get("objective_text", ""))
	if ctx.has("score"):
		var sc: Dictionary = ctx.score
		obj_lines.append("%s: %.1fs   %s: %.1f°" % [Loc.t("score_time"), sc.time_s,
			Loc.t("score_swing"), sc.max_swing_deg])
		obj_lines.append("%s: %d   %s: %d" % [Loc.t("score_hits"), sc.collisions,
			Loc.t("score_violations"), sc.violations])
		obj_lines.append("%s: %d" % [Loc.t("score_near_miss"), sc.get("near_misses", 0)])
	objective_label.text = "\n".join(obj_lines)

	var controlling: bool = ctx.get("controlling", false)
	controls_label.text = Loc.t("controls_cabin") if controlling else Loc.t("controls_walk")
	help_label.text = Loc.t("help_title") + "\n\n" + Loc.t("controls_walk") + "\n\n" + Loc.t("controls_cabin")

	key_w.set_state("W", Input.is_action_pressed("bridge_fwd" if controlling else "move_forward"))
	key_a.set_state("A", Input.is_action_pressed("trolley_left" if controlling else "move_left"))
	key_s.set_state("S", Input.is_action_pressed("bridge_back" if controlling else "move_back"))
	key_d.set_state("D", Input.is_action_pressed("trolley_right" if controlling else "move_right"))
	key_shift.set_state("SHIFT", Input.is_action_pressed("fine_mode"))
	if controlling:
		key_extra.set_state("Q", Input.is_action_pressed("hoist_up"))
		key_e.set_state("E", Input.is_action_pressed("hoist_down"))
	else:
		key_extra.set_state("SPACE", Input.is_action_pressed("jump"))
		key_e.set_state("E", Input.is_action_pressed("interact"))
