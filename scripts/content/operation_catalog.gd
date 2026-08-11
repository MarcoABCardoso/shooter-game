class_name OperationCatalog
extends RefCounted

const ORDER: Array[String] = ["signal_hold", "relay_breach", "overseer_lock"]
const RETREAT_FLUX_RATIO := 0.75
const DEFEAT_FLUX_RATIO := 0.5

const DEFINITIONS := {
	"signal_hold": {
		"name": "SIGNAL HOLD",
		"description": "Hold a captured carrier long enough to pin its frequency.",
		"mission": {
			"id": "contact_line",
			"name": "HOLD THE SIGNAL",
			"rhythm": "SIGNAL DEFENSE",
			"lifecycle": "signal_defense",
			"encounter_id": "defense_swarm",
			"music": &"combat",
			"speaker": "SHIP INTELLIGENCE // VELA",
			"transmission": "Something is listening through the carrier.",
			"time_limit": 45.0,
			"objective_position": Vector2(640.0, 360.0),
			"objective_radius": 122.0,
			"hold_duration": 18.0,
			"decay_rate": 0.35,
		},
	},
	"relay_breach": {
		"name": "RELAY BREACH",
		"description": "Choose a route through a linked three-relay cage.",
		"mission": {
			"id": "relay_cage",
			"name": "BREAK THE CAGE",
			"rhythm": "BREACH",
			"lifecycle": "relay_breach",
			"encounter_id": "relay_breach",
			"music": &"breach",
			"speaker": "VELA",
			"transmission": "The cage is opening from the other side.",
			"time_limit": 80.0,
			"relay_positions": [Vector2(290.0, 238.0), Vector2(990.0, 238.0), Vector2(640.0, 548.0)],
		},
	},
	"overseer_lock": {
		"name": "OVERSEER LOCK",
		"description": "Read the Overseer's arrays and exploit its exposed core.",
		"mission": {
			"id": "overseer_lock",
			"name": "OVERSEER LOCK",
			"rhythm": "BOSS",
			"lifecycle": "boss",
			"encounter_id": "overseer_lock",
			"music": &"combat",
			"speaker": "VELA",
			"transmission": "Contact. Overseer-class.",
			"time_limit": 105.0,
		},
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})


static func display_name(id: String) -> String:
	return String(definition(id).get("name", "UNKNOWN STAGE"))


static func mission(id: String, index: int = 0) -> Dictionary:
	if index != 0:
		return {}
	return definition(id).get("mission", {})


static func retreat_flux(id: String, earned_flux: int) -> int:
	return maxi(0, int(floor(earned_flux * RETREAT_FLUX_RATIO))) if DEFINITIONS.has(id) else 0


static func defeat_flux(id: String, earned_flux: int) -> int:
	return maxi(0, int(floor(earned_flux * DEFEAT_FLUX_RATIO))) if DEFINITIONS.has(id) else 0


static func retreat_flux_percent(id: String) -> int:
	return int(round(RETREAT_FLUX_RATIO * 100.0)) if DEFINITIONS.has(id) else 0


static func defeat_flux_percent(id: String) -> int:
	return int(round(DEFEAT_FLUX_RATIO * 100.0)) if DEFINITIONS.has(id) else 0
