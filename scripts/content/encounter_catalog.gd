class_name EncounterCatalog
extends RefCounted

const ORDER: Array[String] = ["defense_swarm", "cache_pressure", "relay_breach", "overseer_lock"]

const DEFINITIONS := {
	"defense_swarm": {
		"duration": 55.0,
		"health_base": 0.68, "health_growth": 500.0,
		"spawn_base": 0.90, "spawn_min": 0.58, "spawn_pressure": 180.0,
		"double_spawn_at": INF, "elite_interval": 0.0, "boss": false,
	},
	"cache_pressure": {
		"duration": 70.0,
		"health_base": 0.82, "health_growth": 420.0,
		"spawn_base": 1.00, "spawn_min": 0.62, "spawn_pressure": 190.0,
		"double_spawn_at": INF, "elite_interval": 0.0, "boss": false,
	},
	"relay_breach": {
		"duration": 75.0,
		"health_base": 0.90, "health_growth": 500.0,
		"spawn_base": 1.05, "spawn_min": 0.62, "spawn_pressure": 220.0,
		"double_spawn_at": INF, "elite_interval": 0.0, "boss": false,
	},
	"overseer_lock": {
		"duration": 16.0,
		"health_base": 1.12, "health_growth": 220.0,
		"spawn_base": 1.05, "spawn_min": 0.72, "spawn_pressure": 150.0,
		"double_spawn_at": INF, "elite_interval": 0.0, "boss": true,
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, DEFINITIONS[ORDER[0]])


static func choose_standard(id: String, elapsed: float, roll: float) -> String:
	match id:
		"cache_pressure":
			if elapsed >= 18.0 and roll < 0.18:
				return "gunner"
			return "striker" if roll < 0.48 else "drone"
		"relay_breach":
			return "striker" if elapsed >= 12.0 and roll < 0.32 else "drone"
		"overseer_lock":
			if elapsed >= 9.0 and roll >= 0.22 and roll < 0.34:
				return "carrier"
			if elapsed >= 6.0 and roll < 0.22:
				return "gunner"
			return "striker" if roll < 0.60 else "drone"
	return "drone"


static func choose_elite(id: String, elapsed: float) -> String:
	if id == "overseer_lock":
		return "gunner" if elapsed >= 52.0 else "striker"
	return "drone"
