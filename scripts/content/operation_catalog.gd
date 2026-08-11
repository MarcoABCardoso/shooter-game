class_name OperationCatalog
extends RefCounted

const ORDER: Array[String] = ["signal_breach"]

const DEFINITIONS := {
	"signal_breach": {
		"name": "SIGNAL BREACH",
		"description": "Three connected missions that escalate from holding ground to breaking a gunner screen.",
		"retreat_flux_ratio": 0.75,
		"defeat_flux_ratio": 0.5,
		"missions": [
			{
				"id": "contact_line",
				"name": "HOLD THE SIGNAL",
				"rhythm": "SIGNAL DEFENSE",
				"lifecycle": "signal_defense",
				"encounter_id": "defense_swarm",
				"objective_position": Vector2(640.0, 360.0),
				"objective_radius": 122.0,
				"hold_duration": 18.0,
				"decay_rate": 0.35,
			},
			{
				"id": "striker_screen",
				"name": "STRIKER SCREEN",
				"rhythm": "ASSAULT",
				"lifecycle": "assault",
				"encounter_id": "striker_assault",
			},
			{
				"id": "elite_lock",
				"name": "GUNNER LOCK",
				"rhythm": "ASSAULT",
				"lifecycle": "assault",
				"encounter_id": "gunner_assault",
			},
		],
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})


static func display_name(id: String) -> String:
	return String(definition(id).get("name", "UNKNOWN OPERATION"))


static func missions(id: String) -> Array:
	return definition(id).get("missions", [])


static func mission(id: String, index: int) -> Dictionary:
	var operation_missions := missions(id)
	if index < 0 or index >= operation_missions.size():
		return {}
	return operation_missions[index]


static func retreat_flux(id: String, earned_flux: int) -> int:
	var ratio := float(definition(id).get("retreat_flux_ratio", 0.0))
	return maxi(0, int(floor(earned_flux * ratio)))


static func defeat_flux(id: String, earned_flux: int) -> int:
	var ratio := float(definition(id).get("defeat_flux_ratio", 0.0))
	return maxi(0, int(floor(earned_flux * ratio)))


static func retreat_flux_percent(id: String) -> int:
	return int(round(float(definition(id).get("retreat_flux_ratio", 0.0)) * 100.0))


static func defeat_flux_percent(id: String) -> int:
	return int(round(float(definition(id).get("defeat_flux_ratio", 0.0)) * 100.0))
