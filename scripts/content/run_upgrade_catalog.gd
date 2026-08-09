class_name RunUpgradeCatalog
extends RefCounted

const MAX_RANK := 5

# Choices are deliberately exhaustive and stable. Resonance never rolls a
# subset: the player sees every non-capped dimension for every equipped weapon.
const ORDER := {
	"pulse": ["damage", "fire_rate", "projectile_speed"],
	"orbit": ["damage", "blade_count", "orbit_speed"],
	"arc": ["damage", "fire_rate", "chain_count"],
	"nova": ["damage", "fire_rate", "blast_radius"],
}

const DEFINITIONS := {
	"pulse": {
		"damage": {"name": "AMPLITUDE", "description": "+15% damage"},
		"fire_rate": {"name": "CYCLER", "description": "+11% fire rate"},
		"projectile_speed": {"name": "ACCELERATOR", "description": "+12% projectile speed"},
	},
	"orbit": {
		"damage": {"name": "EDGE", "description": "+15% damage"},
		"blade_count": {"name": "REPLICATION", "description": "+1 orbiting blade"},
		"orbit_speed": {"name": "GYRO", "description": "+12% orbit speed"},
	},
	"arc": {
		"damage": {"name": "VOLTAGE", "description": "+15% damage"},
		"fire_rate": {"name": "CAPACITOR", "description": "+11% fire rate"},
		"chain_count": {"name": "CONDUCTION", "description": "+1 chain"},
	},
	"nova": {
		"damage": {"name": "YIELD", "description": "+15% damage"},
		"fire_rate": {"name": "COOLANT", "description": "+11% fire rate"},
		"blast_radius": {"name": "EXPANSION", "description": "+12% blast radius"},
	},
}


static func choices_for(weapon: String) -> Array:
	return ORDER.get(weapon, [])


static func definition(weapon: String, dimension: String) -> Dictionary:
	return DEFINITIONS.get(weapon, {}).get(dimension, {})


static func apply(weapon: String, dimension: String, weapons: Dictionary) -> bool:
	if not weapons.has(weapon) or not definition(weapon, dimension):
		return false
	var spec: Dictionary = weapons[weapon]
	match dimension:
		"damage": spec["damage"] = float(spec["damage"]) * 1.15
		"fire_rate": spec["interval"] = float(spec["interval"]) * 0.90
		"projectile_speed": spec["projectile_speed"] = float(spec["projectile_speed"]) * 1.12
		"blade_count": spec["count"] = int(spec["count"]) + 1
		"orbit_speed": spec["speed"] = float(spec["speed"]) * 1.12
		"chain_count": spec["chains"] = int(spec["chains"]) + 1
		"blast_radius": spec["radius"] = float(spec["radius"]) * 1.12
		_: return false
	return true
