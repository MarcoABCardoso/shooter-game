class_name LibraryCatalog
extends RefCounted

const WEAPON_ORDER: Array[String] = ["pulse", "orbit", "arc", "nova"]
const ABILITY_ORDER: Array[String] = ["dash", "vector_parry", "gravity_tether"]
const ORDER: Array[String] = WEAPON_ORDER + ABILITY_ORDER

const DEFINITIONS := {
	"pulse": {
		"kind": "WEAPON", "name": "PULSE CANNON", "role": "Automatic precision fire",
		"mechanics": "Automatically fires precise shots. Repeated volleys into the same target build Focus for up to +36% damage; switching targets resets it.",
		"plans": "SENTINEL holds ground and stores force. HARRIER kites through close-range volleys.",
		"acquisition": "Standard hangar equipment", "clue": "Standard hangar equipment.",
	},
	"orbit": {
		"kind": "WEAPON", "name": "ORBIT BLADES", "role": "Close-range contact defense",
		"mechanics": "Two blades circle the ship and repeatedly damage enemies they touch.",
		"plans": "INTERCEPTOR hunts at contact range. AEGIS turns the orbit into a projectile screen.",
		"acquisition": "Standard hangar equipment", "clue": "Standard hangar equipment.",
	},
	"arc": {
		"kind": "WEAPON", "name": "ARC LASH", "role": "Automatic chain lightning",
		"mechanics": "Strikes a nearby enemy, then chains through additional targets.",
		"plans": "CONDUIT exploits dense formations. EXECUTIONER waits for priority targets and exposed cores.",
		"acquisition": "Standard hangar equipment", "clue": "Standard hangar equipment.",
	},
	"nova": {
		"kind": "WEAPON", "name": "NOVA BURST", "role": "Periodic radial clear",
		"mechanics": "Detonates around the ship, damaging nearby enemies and clearing hostile projectiles.",
		"plans": "SINGULARITY gathers formations for follow-through. PURIFIER creates safe space under projectile pressure.",
		"acquisition": "Overseer armory recovered", "clue": "A radial weapon signal is sealed inside the Overseer's armory.",
	},
	"dash": {
		"kind": "ACTIVE SKILL", "name": "PHASE DASH", "role": "Burst movement and evasion",
		"mechanics": "Commit to a long surge through damage and cut a low-damage phase lane that erases hostile fire along the route. Mastery shortens its deliberate recharge.",
		"plans": "Cut through a dangerous formation or escape across its fire; Phase Mooring lets a Sentinel move without surrendering charge.",
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
		"mechanics": "Project a gravity point ahead of the ship that drags enemies from the forward field into a compact formation. It never pulls threats through the ship from behind.",
		"plans": "Prepare Arc chains, Nova detonations, Pulse splash, or an aggressive Orbit pass instead of escaping pressure.",
		"acquisition": "Standard hangar equipment", "clue": "Standard hangar equipment.",
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})
