class_name LibraryCatalog
extends RefCounted

const WEAPON_ORDER: Array[String] = ["pulse", "orbit", "arc", "nova"]
const ABILITY_ORDER: Array[String] = ["dash", "vector_parry", "gravity_tether"]
const ORDER: Array[String] = WEAPON_ORDER + ABILITY_ORDER

const DEFINITIONS := {
	"pulse": {
		"kind": "WEAPON", "name": "PULSE CANNON", "role": "Automatic precision fire",
		"mechanics": "Automatically fires precise shots at the nearest enemy in range. Mastery increases damage.",
		"plans": "SENTINEL holds ground and stores force. HARRIER kites through close-range volleys.",
		"acquisition": "Standard hangar equipment", "clue": "Standard hangar equipment.",
	},
	"orbit": {
		"kind": "WEAPON", "name": "ORBIT BLADES", "role": "Close-range contact defense",
		"mechanics": "Two blades circle the ship and repeatedly damage enemies they touch.",
		"plans": "INTERCEPTOR hunts at contact range. AEGIS turns the orbit into a projectile screen.",
		"acquisition": "Overseer armory recovered", "clue": "The Overseer protects a close-defense weapon signal.",
	},
	"arc": {
		"kind": "WEAPON", "name": "ARC LASH", "role": "Automatic chain lightning",
		"mechanics": "Strikes a nearby enemy, then chains through additional targets.",
		"plans": "CONDUIT exploits dense formations. EXECUTIONER waits for priority targets and exposed cores.",
		"acquisition": "Overseer armory recovered", "clue": "A chained weapon signal is sealed inside the Overseer's armory.",
	},
	"nova": {
		"kind": "WEAPON", "name": "NOVA BURST", "role": "Periodic radial clear",
		"mechanics": "Detonates around the ship, damaging nearby enemies and clearing hostile projectiles.",
		"plans": "SINGULARITY gathers formations for follow-through. PURIFIER creates safe space under projectile pressure.",
		"acquisition": "Overseer armory recovered", "clue": "A radial weapon signal is sealed inside the Overseer's armory.",
	},
	"dash": {
		"kind": "ACTIVE SKILL", "name": "PHASE DASH", "role": "Burst movement and evasion",
		"mechanics": "Surge in your movement direction and briefly phase through damage. Mastery shortens recharge.",
		"plans": "Reposition through danger; Phase Mooring lets a Sentinel move without surrendering charge.",
		"acquisition": "Standard hangar equipment", "clue": "Standard hangar equipment.",
	},
	"vector_parry": {
		"kind": "ACTIVE SKILL", "name": "VECTOR PARRY", "role": "Radial defense and counterfire",
		"mechanics": "Return nearby hostile projectiles as counterfire. It is strongest against Gunner and Overseer patterns. Mastery shortens recharge.",
		"plans": "Invite readable projectile patterns, then convert defense into focused damage.",
		"acquisition": "Drift Cache recovered", "clue": "Counterfire telemetry survives in an optional cache.",
	},
	"gravity_tether": {
		"kind": "ACTIVE SKILL", "name": "GRAVITY TETHER", "role": "Formation setup without invulnerability",
		"mechanics": "Project a gravity point ahead of the ship that drags nearby enemies into a compact formation. Mastery shortens recharge.",
		"plans": "Prepare Arc chains, Nova detonations, Pulse splash, or an aggressive Orbit pass instead of escaping pressure.",
		"acquisition": "Overseer armory recovered", "clue": "A formation-control signal is sealed inside the Overseer's armory.",
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})
