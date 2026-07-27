extends Node
## Loc — trilingual (English / Español / Nederlands) string table for the HUD.
## Per 01_MASTER_PROMPT_V2.md #project mission: English professional terminology
## first, literal Spanish beside it, Dutch preserved in parentheses where useful.
## Modes: EN_ES (default, "English / Español"), EN, ES, NL. Cycle with L.
## Entries are [en, es, nl]. nl may be "" when no distinct term is useful.

enum { LANG_EN_ES, LANG_EN, LANG_ES, LANG_NL }

var lang := LANG_EN_ES

const S := {
	"title": ["Gelderland Operator Academy — overhead crane proof",
		"Gelderland Operator Academy — prueba de grúa puente",
		"Gelderland Operator Academy — bovenloopkraan bewijs"],
	"power": ["Power", "Corriente", "Voeding"],
	"on": ["ON", "ENCENDIDO", "AAN"],
	"off": ["OFF", "APAGADO", "UIT"],
	"inspection": ["Inspection", "Inspección", "Inspectie"],
	"insp_hint": ["Complete checks 1-3 before use",
		"Completa las comprobaciones 1-3 antes de usar la grúa", "Voltooi controle 1-3 voor gebruik"],
	"insp_1": ["Brakes & e-stop", "Frenos y parada de emergencia", "Remmen & noodstop"],
	"insp_2": ["Limit switches", "Finales de carrera", "Eindschakelaars"],
	"insp_3": ["Hook & cable", "Gancho y cable", "Haak & kabel"],
	"cable": ["Cable length", "Longitud de cable", "Kabellengte"],
	"mass": ["Load mass", "Masa de la carga", "Lastmassa"],
	"swing": ["Swing angle", "Ángulo de balanceo", "Slingerhoek"],
	"tension": ["Cable tension", "Tensión del cable", "Kabelspanning"],
	"wind": ["Wind", "Viento", "Wind"],
	"bridge": ["Bridge X", "Puente X", "Brug X"],
	"trolley": ["Trolley Z", "Carro Z", "Loopkat Z"],
	"time": ["Time", "Tiempo", "Tijd"],
	"rows": ["telemetry rows", "filas de telemetría", "telemetrieregels"],
	"fault": ["PHYSICS FAULT — simulation halted, press R",
		"FALLO DE FÍSICA — simulación detenida, pulsa R",
		"FYSICAFOUT — simulatie gestopt, druk R"],
	"controls_walk": ["WASD move · Shift run · Space jump · Mouse look\nE interact · F1 help · Esc mouse",
		"WASD moverse · Shift correr · Espacio saltar · Ratón mirar\nE interactuar · F1 ayuda · Esc ratón", ""],
	"controls_cabin": ["W/S bridge · A/D trolley · Q/E hoist up/down · Shift fine\nV wind · R reset · Tab camera · F exit cabin · 1-3 inspection",
		"W/S puente · A/D carro · Q/E izar/bajar · Shift modo fino\nV viento · R reset · Tab cámara · F salir de cabina · 1-3 inspección", ""],

	# --- access / player ------------------------------------------------
	"prompt_approach": ["Walk to the crane ladder (marked) and press E to climb",
		"Camina hasta la escalera de la grúa (marcada) y pulsa E para subir",
		"Loop naar de kraanladder en druk op E om te klimmen"],
	"prompt_in_zone": ["Press E to climb into the cabin",
		"Pulsa E para subir a la cabina", "Druk op E om de cabine in te klimmen"],
	"prompt_climbing": ["Climbing...", "Subiendo...", "Klimmen..."],
	"prompt_exit": ["Press F to climb down", "Pulsa F para bajar",
		"Druk op F om af te klimmen"],
	"access_label": ["CRANE ACCESS", "ACCESO A LA GRÚA (toegang kraan)", ""],

	# --- objectives -------------------------------------------------------
	"objective": ["Objective", "Objetivo", "Doel"],
	"zone_a": ["ZONE A — PICKUP", "ZONA A — RECOGIDA", "ZONE A — OPHALEN"],
	"zone_b": ["ZONE B — DROP-OFF", "ZONA B — ENTREGA", "ZONE B — AFLEVEREN"],
	"obj_not_started": ["Lower the hook over Zone A and pick up the load",
		"Baja el gancho sobre la Zona A y recoge la carga",
		"Laat de haak zakken boven Zone A en pak de last op"],
	"obj_carrying": ["Carry the load to Zone B — keep swing under control",
		"Lleva la carga a la Zona B — controla el balanceo",
		"Breng de last naar Zone B — houd de slingering onder controle"],
	"obj_delivered": ["Delivered! Press R to reset or F to climb down",
		"¡Entregado! Pulsa R para reiniciar o F para bajar",
		"Afgeleverd! Druk op R om te resetten of F om af te klimmen"],
	"score_time": ["Time", "Tiempo", "Tijd"],
	"score_swing": ["Max swing", "Balanceo máx.", "Max slingering"],
	"score_hits": ["Collisions", "Colisiones", "Botsingen"],
	"score_violations": ["Safety violations", "Infracciones de seguridad", "Veiligheidsovertredingen"],

	# --- safety / collisions ----------------------------------------------
	"danger_load": ["!! LOAD CONTACT — NEVER STAND UNDER A SUSPENDED LOAD",
		"!! CONTACTO CON LA CARGA — NUNCA TE SITÚES BAJO UNA CARGA SUSPENDIDA",
		"!! LAST CONTACT — NOOIT ONDER EEN HANGENDE LAST STAAN"],

	# --- camera -------------------------------------------------------------
	"cam_cabin": ["Cabin view", "Vista de cabina", "Cabinezicht"],
	"cam_walk": ["First person", "Primera persona", "Eerste persoon"],
	"cam_orbit": ["Orbit view", "Vista orbital", "Rondzicht"],
	"cam_hook": ["Hook camera", "Cámara de gancho", "Haakcamera"],
	"cam_topdown": ["Top-down view", "Vista cenital", "Bovenaanzicht"],

	"help_title": ["CONTROLS / HELP (F1 to close)",
		"CONTROLES / AYUDA (F1 para cerrar)", ""],
}


func t(key: String) -> String:
	var e: Array = S.get(key, [])
	if e.is_empty():
		return key
	match lang:
		LANG_EN:
			return e[0]
		LANG_ES:
			return e[1] if e[1] != "" else e[0]
		LANG_NL:
			return e[2] if e.size() > 2 and e[2] != "" else e[0]
		_:
			if e[0] == e[1]:
				return e[0]
			if "\n" in e[0]:
				return e[0] + "\n" + e[1]
			return "%s / %s" % [e[0], e[1]]


func cycle() -> void:
	lang = (lang + 1) % 4


func lang_name() -> String:
	match lang:
		LANG_EN: return "EN"
		LANG_ES: return "ES"
		LANG_NL: return "NL"
		_: return "EN/ES"
