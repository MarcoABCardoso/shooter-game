class_name LibraryCatalog
extends RefCounted

const ORDER: Array[String] = ["pulse", "orbit", "arc", "nova", "dash", "vector_parry"]

const DEFINITIONS := {
	"pulse": {
		"kind": "WEAPON", "name": "PULSE CANNON", "role": "Automatic precision fire",
		"mechanics": "Automatically fires precise shots at the nearest enemy in range. Mastery increases damage.",
		"acquisition": "Standard hangar equipment", "clue": "Standard hangar equipment.",
	},
	"orbit": {
		"kind": "WEAPON", "name": "ORBIT BLADES", "role": "Close-range contact defense",
		"mechanics": "Two blades circle the ship and repeatedly damage enemies they touch.",
		"acquisition": "Future operation reward", "clue": "Decode a future weapon signal.",
	},
	"arc": {
		"kind": "WEAPON", "name": "ARC LASH", "role": "Automatic chain lightning",
		"mechanics": "Strikes a nearby enemy, then chains through additional targets.",
		"acquisition": "Not yet obtainable", "clue": "A future signal route may reveal it.",
	},
	"nova": {
		"kind": "WEAPON", "name": "NOVA BURST", "role": "Periodic radial clear",
		"mechanics": "Detonates around the ship, damaging nearby enemies and clearing hostile projectiles.",
		"acquisition": "Not yet obtainable", "clue": "A future signal route may reveal it.",
	},
	"dash": {
		"kind": "ACTIVE SKILL", "name": "PHASE DASH", "role": "Burst movement and evasion",
		"mechanics": "Surge in your movement direction and briefly phase through damage. Mastery shortens recharge.",
		"acquisition": "Standard hangar equipment", "clue": "Standard hangar equipment.",
	},
	"vector_parry": {
		"kind": "ACTIVE SKILL", "name": "VECTOR PARRY", "role": "Radial defense and counterfire",
		"mechanics": "Return nearby hostile projectiles as counterfire. Mastery shortens recharge.",
		"acquisition": "Future operation reward", "clue": "Decode a future ability signal.",
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})
