class_name StageCatalog
extends RefCounted

const ORDER: Array[String] = ["stage_1", "stage_2", "stage_3", "stage_4", "stage_5"]

const DEFINITIONS := {
	"stage_1": {
		"number": 1, "name": "FIRST CONTACT", "duration": 55.0,
		"description": "A light drone formation guards the first signal.",
		"health_base": 0.68, "health_growth": 500.0,
		"spawn_base": 0.90, "spawn_min": 0.58, "spawn_pressure": 180.0,
		"double_spawn_at": INF, "elite_interval": 0.0, "boss": false,
	},
	"stage_2": {
		"number": 2, "name": "INTERCEPT", "duration": 75.0,
		"description": "Fast Strikers join the drone formation.",
		"health_base": 0.90, "health_growth": 500.0,
		"spawn_base": 0.90, "spawn_min": 0.58, "spawn_pressure": 220.0,
		"double_spawn_at": INF, "elite_interval": 0.0, "boss": false,
	},
	"stage_3": {
		"number": 3, "name": "ASCENDANCY", "duration": 90.0,
		"description": "Elite signatures reinforce the advancing formation.",
		"health_base": 1.00, "health_growth": 260.0,
		"spawn_base": 0.82, "spawn_min": 0.46, "spawn_pressure": 180.0,
		"double_spawn_at": INF, "elite_interval": 42.0, "boss": false,
	},
	"stage_4": {
		"number": 4, "name": "CROSSFIRE", "duration": 105.0,
		"description": "Gunners reinforce the formation while elites compress the arena.",
		"health_base": 1.12, "health_growth": 220.0,
		"spawn_base": 0.75, "spawn_min": 0.36, "spawn_pressure": 150.0,
		"double_spawn_at": 90.0, "elite_interval": 38.0, "boss": false,
	},
	"stage_5": {
		"number": 5, "name": "OVERSEER", "duration": 120.0,
		"description": "The full hostile roster protects the Overseer Array.",
		"health_base": 1.24, "health_growth": 190.0,
		"spawn_base": 0.68, "spawn_min": 0.28, "spawn_pressure": 125.0,
		"double_spawn_at": 78.0, "elite_interval": 34.0, "boss": true,
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, DEFINITIONS["stage_1"])


static func number(id: String) -> int:
	return int(definition(id)["number"])


static func display_name(id: String) -> String:
	var spec := definition(id)
	return "STAGE %d — %s" % [int(spec["number"]), String(spec["name"])]


static func choose_standard(id: String, elapsed: float, roll: float) -> String:
	match id:
		"stage_2":
			return "striker" if elapsed >= 12.0 and roll < 0.32 else "drone"
		"stage_3":
			return "striker" if roll < 0.42 else "drone"
		"stage_4":
			if elapsed >= 28.0 and roll < 0.16:
				return "gunner"
			return "striker" if roll < 0.52 else "drone"
		"stage_5":
			if elapsed >= 72.0 and roll < 0.12:
				return "tank"
			if elapsed >= 24.0 and roll < 0.30:
				return "gunner"
			return "striker" if roll < 0.62 else "drone"
	return "drone"


static func choose_elite(id: String, elapsed: float) -> String:
	match id:
		"stage_3":
			return "striker"
		"stage_4":
			return "gunner" if elapsed >= 70.0 else "striker"
		"stage_5":
			return "tank" if elapsed >= 90.0 else "gunner"
	return "drone"
