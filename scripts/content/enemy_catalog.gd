class_name EnemyCatalog
extends RefCounted

# Add balance-only enemy variants here. Add a matching vector shape in
# NeonEnemy._draw() only when the new variant needs a new silhouette.
const DEFINITIONS := {
	"drone": {
		"health": 19.0, "speed": 125.0, "contact_damage": 10.0,
		"flux": 1, "resonance": 5, "radius": 12.0, "shoot_interval": 0.0,
	},
	"striker": {
		"health": 31.0, "speed": 178.0, "contact_damage": 14.0,
		"flux": 2, "resonance": 8, "radius": 11.0, "shoot_interval": 0.0,
	},
	"gunner": {
		"health": 45.0, "speed": 78.0, "contact_damage": 9.0,
		"flux": 3, "resonance": 10, "radius": 15.0, "shoot_interval": 1.7,
	},
	"tank": {
		"health": 135.0, "speed": 52.0, "contact_damage": 22.0,
		"flux": 5, "resonance": 18, "radius": 23.0, "shoot_interval": 0.0,
	},
	"boss": {
		"health": 1250.0, "speed": 52.0, "contact_damage": 28.0,
		"flux": 45, "resonance": 150, "radius": 47.0, "shoot_interval": 0.72,
	},
}


static func stats(id: String) -> Dictionary:
	assert(DEFINITIONS.has(id), "Unknown enemy id: %s" % id)
	return DEFINITIONS[id].duplicate(true)


static func choose_standard(elapsed: float, roll: float) -> String:
	if elapsed > 80.0 and roll < 0.14:
		return "tank"
	if elapsed > 38.0 and roll < 0.36:
		return "gunner"
	if elapsed > 16.0 and roll < 0.58:
		return "striker"
	return "drone"
