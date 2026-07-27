extends Node
## Loc — minimal bilingual (Nederlands / English) string table for the HUD.
## Modes: BOTH (default, "nl / en"), NL only, EN only. Cycle with the L key.

enum { LANG_BOTH, LANG_NL, LANG_EN }

var lang := LANG_BOTH

const S := {
	"title": ["Gelderland Operator Academy — bovenloopkraan bewijs",
		"Gelderland Operator Academy — overhead crane proof"],
	"power": ["Voeding", "Power"],
	"on": ["AAN", "ON"],
	"off": ["UIT", "OFF"],
	"inspection": ["Inspectie", "Inspection"],
	"insp_hint": ["Voltooi controle 1-3 voor gebruik", "Complete checks 1-3 before use"],
	"insp_1": ["Remmen & noodstop", "Brakes & e-stop"],
	"insp_2": ["Eindschakelaars", "Limit switches"],
	"insp_3": ["Haak & kabel", "Hook & cable"],
	"cable": ["Kabellengte", "Cable length"],
	"mass": ["Lastmassa", "Load mass"],
	"swing": ["Slingerhoek", "Swing angle"],
	"tension": ["Kabelspanning", "Cable tension"],
	"wind": ["Wind", "Wind"],
	"bridge": ["Brug X", "Bridge X"],
	"trolley": ["Loopkat Z", "Trolley Z"],
	"time": ["Tijd", "Time"],
	"rows": ["telemetrieregels", "telemetry rows"],
	"fault": ["FYSICAFOUT — simulatie gestopt, druk R",
		"PHYSICS FAULT — simulation halted, press R"],
	"controls": ["W/S brug · A/D loopkat · Q/E hijsen op/neer · Shift fijn\nV wind · R reset · C camera-reset · pijltjes/+/- camera · L taal · 1-3 inspectie",
		"W/S bridge · A/D trolley · Q/E hoist up/down · Shift fine\nV wind · R reset · C camera reset · arrows/+/- camera · L language · 1-3 inspection"],
}


func t(key: String) -> String:
	var e: Array = S.get(key, [])
	if e.is_empty():
		return key
	match lang:
		LANG_NL:
			return e[0]
		LANG_EN:
			return e[1]
		_:
			if e[0] == e[1]:
				return e[0]
			if "\n" in e[0]:
				return e[0] + "\n" + e[1]
			return "%s / %s" % [e[0], e[1]]


func cycle() -> void:
	lang = (lang + 1) % 3
