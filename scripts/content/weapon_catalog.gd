class_name WeaponCatalog
extends RefCounted

const ORDER: Array[String] = ["pulse", "orbit", "arc", "nova"]

const NAMES := {
	"pulse": "PULSE CANNON",
	"orbit": "ORBIT BLADES",
	"arc": "ARC LASH",
	"nova": "NOVA BURST",
}

# Runtime weapon dictionaries are copied from here at the start of each run.
# Systems consume named fields so tuning a weapon does not require scene edits.
const DEFAULTS := {
	"pulse": {"level": 1, "damage": 5.0, "interval": 0.34, "count": 1, "pierce": 0, "projectile_speed": 720.0, "range": 190.0},
	"orbit": {"level": 0, "damage": 10.0, "count": 2, "speed": 1.8, "radius": 72.0},
	"arc": {"level": 0, "damage": 25.0, "interval": 2.1, "chains": 2, "range": 245.0},
	"nova": {"level": 0, "damage": 38.0, "interval": 8.0, "radius": 175.0},
}


static func fresh_loadout(equipped: Array[String] = ["pulse"]) -> Dictionary:
	var loadout := DEFAULTS.duplicate(true)
	for id: String in ORDER:
		loadout[id]["level"] = 1 if equipped.has(id) else 0
	return loadout


static func display_name(id: String) -> String:
	return String(NAMES.get(id, id.to_upper()))
