extends Node
## Loc — trilingual (English / Español / Nederlands) string table for the HUD.
## Project language policy: English professional terminology
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
	"controls_walk": ["WASD move · Shift run · Space jump · Mouse look\nE pick up pendant · F1 help · Esc mouse",
		"WASD moverse · Shift correr · Espacio saltar · Ratón mirar\nE coger el mando · F1 ayuda · Esc ratón", ""],
	"controls_cabin": ["W/S bridge · A/D trolley · Q/E hoist up/down · Shift fine\nV wind · R reset · Tab camera · F put down pendant · 1-3 inspection",
		"W/S puente · A/D carro · Q/E izar/bajar · Shift modo fino\nV viento · R reset · Tab cámara · F soltar el mando · 1-3 inspección", ""],

	# --- access / player ------------------------------------------------
	# This overhead crane is pendant-operated from the factory floor — there
	# is no cabin and nothing to climb (DEC-014).
	"prompt_approach": ["Walk to the control station (marked) and press E to pick up the pendant",
		"Camina hasta el punto de control (marcado) y pulsa E para coger el mando",
		"Loop naar het bedieningspunt en druk op E om de afstandsbediening op te pakken"],
	"prompt_in_zone": ["Press E to pick up the pendant control",
		"Pulsa E para coger el mando a distancia",
		"Druk op E om de afstandsbediening op te pakken"],
	"prompt_exit": ["Press F to put down the pendant", "Pulsa F para soltar el mando",
		"Druk op F om de afstandsbediening neer te leggen"],
	"access_label": ["CONTROL STATION", "PUNTO DE CONTROL (bedieningspunt)", ""],

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
	"obj_delivered": ["Delivered! Press R to reset or F to put down the pendant",
		"¡Entregado! Pulsa R para reiniciar o F para soltar el mando",
		"Afgeleverd! Druk op R om te resetten of F om de afstandsbediening neer te leggen"],
	"score_time": ["Time", "Tiempo", "Tijd"],
	"score_swing": ["Max swing", "Balanceo máx.", "Max slingering"],
	"score_hits": ["Collisions", "Colisiones", "Botsingen"],
	"score_violations": ["Safety violations", "Infracciones de seguridad", "Veiligheidsovertredingen"],
	"score_near_miss": ["Near misses", "Casi-accidentes", "Bijna-ongevallen"],

	# --- safety / collisions ----------------------------------------------
	"danger_load": ["!! LOAD CONTACT — NEVER STAND UNDER A SUSPENDED LOAD",
		"!! CONTACTO CON LA CARGA — NUNCA TE SITÚES BAJO UNA CARGA SUSPENDIDA",
		"!! LAST CONTACT — NOOIT ONDER EEN HANGENDE LAST STAAN"],
	"caution_near": ["CAUTION — stay clear of the suspended load's operating radius",
		"PRECAUCIÓN — mantente fuera del radio de la carga suspendida",
		"WAARSCHUWING — blijf uit de buurt van de hangende last"],
	"impact_floor": ["Load struck the floor", "La carga golpeó el suelo",
		"Last raakte de vloer"],
	"impact_column": ["Load struck a column", "La carga golpeó una columna",
		"Last raakte een kolom"],

	# --- camera -------------------------------------------------------------
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
