class_name LibraryCatalog
extends RefCounted

const ORDER: Array[String] = ["pulse", "orbit", "arc", "nova", "dash"]

const DEFINITIONS := {
	"pulse": {
		"kind": "WEAPON",
		"name": "PULSE CANNON",
		"role": "Aimed precision fire",
		"mechanics": "Automatically fires along the mouse aim. Mutations can add damage, fire rate, projectiles, velocity, and piercing.",
		"acquisition": "Standard issue. Active at the start of every run.",
		"clue": "Already installed on the starting ship.",
	},
	"orbit": {
		"kind": "WEAPON",
		"name": "ORBIT BLADES",
		"role": "Close-range contact defense",
		"mechanics": "Blades circle the ship and repeatedly damage enemies they touch. Mutations add blades, speed, and impact damage.",
		"acquisition": "Evolves from Close profiles, especially Close + Focus or Close + Spread combat.",
		"clue": "Fight at CLOSE range when resonance rises.",
	},
	"arc": {
		"kind": "WEAPON",
		"name": "ARC LASH",
		"role": "Automatic chain lightning",
		"mechanics": "Strikes a nearby enemy, then chains through additional targets. Mutations improve reach, chain count, and cadence.",
		"acquisition": "Evolves from Distant + Spread profiles, whether Anchored or Roaming.",
		"clue": "Deal damage from DISTANT range and distribute it across targets.",
	},
	"nova": {
		"kind": "WEAPON",
		"name": "NOVA BURST",
		"role": "Periodic radial blast",
		"mechanics": "Detonates around the ship, damaging nearby enemies and clearing hostile projectiles. Mutations improve radius, damage, and cadence.",
		"acquisition": "Evolves from Close + Spread profiles. Roaming + Close + Spread can reveal it alongside Orbit Blades.",
		"clue": "Stay CLOSE while spreading damage across several targets.",
	},
	"dash": {
		"kind": "ABILITY",
		"name": "PHASE DASH",
		"role": "Burst movement and evasion",
		"mechanics": "Press Space while moving to surge in that direction. The ship is briefly invulnerable during the dash.",
		"acquisition": "Standard issue. Available from deployment with a short recharge.",
		"clue": "Already installed on the starting ship.",
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})
