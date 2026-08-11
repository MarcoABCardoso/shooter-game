class_name EncounterCatalog
extends RefCounted

const ORDER: Array[String] = ["defense_swarm", "striker_assault", "gunner_assault"]

const DEFINITIONS := {
	"defense_swarm": {
		"duration": 55.0,
		"health_base": 0.68, "health_growth": 500.0,
		"spawn_base": 0.90, "spawn_min": 0.58, "spawn_pressure": 180.0,
		"double_spawn_at": INF, "elite_interval": 0.0, "boss": false,
	},
	"striker_assault": {
		"duration": 75.0,
		"health_base": 0.90, "health_growth": 500.0,
		"spawn_base": 0.90, "spawn_min": 0.58, "spawn_pressure": 220.0,
		"double_spawn_at": INF, "elite_interval": 0.0, "boss": false,
	},
	"gunner_assault": {
		"duration": 68.0,
		"health_base": 1.12, "health_growth": 220.0,
		"spawn_base": 0.75, "spawn_min": 0.36, "spawn_pressure": 150.0,
		"double_spawn_at": INF, "elite_interval": 38.0, "boss": false,
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, DEFINITIONS[ORDER[0]])


static func choose_standard(id: String, elapsed: float, roll: float) -> String:
	match id:
		"striker_assault":
			return "striker" if elapsed >= 12.0 and roll < 0.32 else "drone"
		"gunner_assault":
			if elapsed >= 28.0 and roll < 0.16:
				return "gunner"
			return "striker" if roll < 0.52 else "drone"
	return "drone"


static func choose_elite(id: String, elapsed: float) -> String:
	if id == "gunner_assault":
		return "gunner" if elapsed >= 52.0 else "striker"
	return "drone"
