class_name LibraryCatalog
extends RefCounted

const ORDER: Array[String] = ["pulse", "orbit", "arc", "nova", "dash", "vector_parry"]

const DEFINITIONS := {
	"pulse": {
		"kind": "WEAPON", "name": "PULSE CANNON", "role": "Automatic precision fire",
		"mechanics": "Automatically tracks and fires at the nearest enemy within 190 px. Mastery permanently improves its damage.",
		"acquisition": "Standard issue. Selectable in the hangar from the beginning.", "clue": "Standard hangar inventory.",
	},
	"orbit": {
		"kind": "WEAPON", "name": "ORBIT BLADES", "role": "Close-range contact defense",
		"mechanics": "Two blades circle the ship and repeatedly damage enemies they touch.",
		"acquisition": "Clear Stage 1, then select it in the hangar.", "clue": "Stabilize the Stage 1 signal.",
	},
	"arc": {
		"kind": "WEAPON", "name": "ARC LASH", "role": "Automatic chain lightning",
		"mechanics": "Strikes a nearby enemy, then chains through additional targets.",
		"acquisition": "Reserved for a future signal route.", "clue": "Await a future signal route.",
	},
	"nova": {
		"kind": "WEAPON", "name": "NOVA BURST", "role": "Periodic radial clear",
		"mechanics": "Detonates around the ship, damaging nearby enemies and clearing hostile projectiles.",
		"acquisition": "Reserved for a future signal route.", "clue": "Await a future signal route.",
	},
	"dash": {
		"kind": "ACTIVE SKILL", "name": "PHASE DASH", "role": "Burst movement and evasion",
		"mechanics": "Press Space while moving to surge in that direction. Mastery shortens recharge.",
		"acquisition": "Standard issue. Selectable in the active-skill loadout.", "clue": "Standard hangar inventory.",
	},
	"vector_parry": {
		"kind": "ACTIVE SKILL", "name": "VECTOR PARRY", "role": "Radial defense and counterfire",
		"mechanics": "Press Space to return nearby hostile projectiles in every direction. Mastery shortens recharge.",
		"acquisition": "Defeat the Stage 5 Overseer, then select it in the hangar.", "clue": "Erase the Stage 5 Overseer.",
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})
