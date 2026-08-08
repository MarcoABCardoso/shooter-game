class_name LibraryCatalog
extends RefCounted

const ORDER: Array[String] = [
	"pulse", "orbit", "arc", "nova", "dash",
	"anchored_close_focus", "anchored_close_spread", "anchored_distant_focus", "anchored_distant_spread",
	"roaming_close_focus", "roaming_close_spread", "roaming_distant_focus", "roaming_distant_spread",
]

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
	"anchored_close_focus": {
		"kind": "EVOLUTION",
		"name": "REACTOR FANG",
		"role": "ANCHORED // CLOSE // FOCUS",
		"mechanics": "Orbit gains +24% damage and tightens by 3 px. The ship gains +5 maximum hull and repairs 5 hull.",
		"acquisition": "Hold ground, fight nearby targets, and concentrate damage when resonance peaks.",
		"clue": "Combine ANCHORED movement, CLOSE range, and FOCUSED damage.",
	},
	"anchored_close_spread": {
		"kind": "EVOLUTION",
		"name": "NOVA MINEFIELD",
		"role": "ANCHORED // CLOSE // SPREAD",
		"mechanics": "Nova gains +15% damage, +14 px blast radius, and a 6% shorter firing interval.",
		"acquisition": "Hold ground near the swarm and spread damage across targets when resonance peaks.",
		"clue": "Combine ANCHORED movement, CLOSE range, and SPREAD damage.",
	},
	"anchored_distant_focus": {
		"kind": "EVOLUTION",
		"name": "SIEGE NEEDLE",
		"role": "ANCHORED // DISTANT // FOCUS",
		"mechanics": "Pulse gains +20% damage and +8% projectile speed. Odd ranks also add +1 piercing.",
		"acquisition": "Hold ground, attack from long range, and focus one target when resonance peaks.",
		"clue": "Combine ANCHORED movement, DISTANT range, and FOCUSED damage.",
	},
	"anchored_distant_spread": {
		"kind": "EVOLUTION",
		"name": "PRISM BATTERY",
		"role": "ANCHORED // DISTANT // SPREAD",
		"mechanics": "Pulse adds +1 projectile per volley and Arc adds +1 chain, up to their system limits.",
		"acquisition": "Hold ground, attack from long range, and distribute damage when resonance peaks.",
		"clue": "Combine ANCHORED movement, DISTANT range, and SPREAD damage.",
	},
	"roaming_close_focus": {
		"kind": "EVOLUTION",
		"name": "RAZOR PURSUIT",
		"role": "ROAMING // CLOSE // FOCUS",
		"mechanics": "Orbit gains +20% damage and +10% rotation speed. The ship gains +3.5% movement speed.",
		"acquisition": "Keep moving near enemies and concentrate damage when resonance peaks.",
		"clue": "Combine ROAMING movement, CLOSE range, and FOCUSED damage.",
	},
	"roaming_close_spread": {
		"kind": "EVOLUTION",
		"name": "COMET SWARM",
		"role": "ROAMING // CLOSE // SPREAD",
		"mechanics": "Orbit adds +1 blade, Nova gains +9 px radius, and the ship gains +2.5% movement speed.",
		"acquisition": "Keep moving through nearby groups and distribute damage when resonance peaks.",
		"clue": "Combine ROAMING movement, CLOSE range, and SPREAD damage.",
	},
	"roaming_distant_focus": {
		"kind": "EVOLUTION",
		"name": "RAILWING",
		"role": "ROAMING // DISTANT // FOCUS",
		"mechanics": "Pulse gains +9% damage, a 14% shorter firing interval, and +10% projectile speed. The ship gains +2.5% movement speed.",
		"acquisition": "Reposition at long range and concentrate damage when resonance peaks.",
		"clue": "Combine ROAMING movement, DISTANT range, and FOCUSED damage.",
	},
	"roaming_distant_spread": {
		"kind": "EVOLUTION",
		"name": "STORM CHASER",
		"role": "ROAMING // DISTANT // SPREAD",
		"mechanics": "Arc gains a 16% shorter firing interval and +18 px range; even ranks add +1 chain. The ship gains +2.5% movement speed.",
		"acquisition": "Keep moving at long range and distribute damage when resonance peaks.",
		"clue": "Combine ROAMING movement, DISTANT range, and SPREAD damage.",
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})
