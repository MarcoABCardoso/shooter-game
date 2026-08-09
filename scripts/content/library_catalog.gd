class_name LibraryCatalog
extends RefCounted

const ORDER: Array[String] = ["pulse", "orbit", "arc", "nova", "dash", "vector_parry"]

const DEFINITIONS := {
	"pulse": {
		"kind": "WEAPON", "name": "PULSE CANNON", "role": "Aimed precision fire",
		"mechanics": "Automatically fires along the mouse aim. Mastery permanently improves its damage.",
		"acquisition": "Standard issue. Selectable in the hangar from the beginning.", "clue": "Standard hangar inventory.",
	},
	"orbit": {
		"kind": "WEAPON", "name": "ORBIT BLADES", "role": "Close-range contact defense",
		"mechanics": "Two blades circle the ship and repeatedly damage enemies they touch.",
		"acquisition": "Standard issue. Selectable in the hangar from the beginning.", "clue": "Standard hangar inventory.",
	},
	"arc": {
		"kind": "WEAPON", "name": "ARC LASH", "role": "Automatic chain lightning",
		"mechanics": "Strikes a nearby enemy, then chains through additional targets.",
		"acquisition": "Standard issue. Selectable in the hangar from the beginning.", "clue": "Standard hangar inventory.",
	},
	"nova": {
		"kind": "WEAPON", "name": "NOVA BURST", "role": "Periodic radial clear",
		"mechanics": "Detonates around the ship, damaging nearby enemies and clearing hostile projectiles.",
		"acquisition": "Clear Stage 1, then equip it in an unlocked weapon slot.", "clue": "Defeat the Stage 1 Overseer.",
	},
	"dash": {
		"kind": "ACTIVE SKILL", "name": "PHASE DASH", "role": "Burst movement and evasion",
		"mechanics": "Press Space while moving to surge in that direction. Mastery shortens recharge.",
		"acquisition": "Standard issue. Selectable in the active-skill loadout.", "clue": "Standard hangar inventory.",
	},
	"vector_parry": {
		"kind": "ACTIVE SKILL", "name": "VECTOR PARRY", "role": "Directional defense and counterfire",
		"mechanics": "Press Space to return nearby hostile projectiles caught in a forward arc. Mastery shortens recharge.",
		"acquisition": "Clear Stage 1, then select it in the hangar active-skill slot.", "clue": "Defeat the Stage 1 Overseer.",
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})
