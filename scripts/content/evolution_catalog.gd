class_name EvolutionCatalog
extends RefCounted

const DEFINITIONS := {
	"anchored_close_focus": {"name": "REACTOR FANG", "description": "A dense close-range orbit hardens around held ground."},
	"anchored_close_spread": {"name": "NOVA MINEFIELD", "description": "Wide pulses turn defended territory into a blast zone."},
	"anchored_distant_focus": {"name": "SIEGE NEEDLE", "description": "Patient long-range fire condenses into piercing precision."},
	"anchored_distant_spread": {"name": "PRISM BATTERY", "description": "A fixed firing platform divides its signal across the field."},
	"roaming_close_focus": {"name": "RAZOR PURSUIT", "description": "High-speed pursuit sharpens a compact orbiting edge."},
	"roaming_close_spread": {"name": "COMET SWARM", "description": "Movement sheds blades and blasts through clustered threats."},
	"roaming_distant_focus": {"name": "RAILWING", "description": "Repositioning feeds a faster long-range precision cannon."},
	"roaming_distant_spread": {"name": "STORM CHASER", "description": "A mobile arc network reaches across scattered targets."},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, DEFINITIONS["anchored_distant_focus"])


static func apply(id: String, rank: int, weapons: Dictionary, player: NeonPlayer) -> Dictionary:
	var evolved_weapons: Array[String] = []
	match id:
		"anchored_close_focus":
			evolved_weapons = ["orbit"]
			weapons["orbit"]["damage"] *= 1.24
			weapons["orbit"]["radius"] = maxf(48.0, float(weapons["orbit"]["radius"]) - 3.0)
			player.max_health += 5.0
			player.heal(5.0)
		"anchored_close_spread":
			evolved_weapons = ["nova"]
			weapons["nova"]["damage"] *= 1.15
			weapons["nova"]["radius"] += 14.0
			weapons["nova"]["interval"] *= 0.94
		"anchored_distant_focus":
			evolved_weapons = ["pulse"]
			weapons["pulse"]["damage"] *= 1.20
			weapons["pulse"]["projectile_speed"] *= 1.08
			if rank % 2 == 1:
				weapons["pulse"]["pierce"] = int(weapons["pulse"]["pierce"]) + 1
		"anchored_distant_spread":
			evolved_weapons = ["pulse", "arc"]
			weapons["pulse"]["count"] = mini(7, int(weapons["pulse"]["count"]) + 1)
			weapons["arc"]["chains"] = mini(9, int(weapons["arc"]["chains"]) + 1)
		"roaming_close_focus":
			evolved_weapons = ["orbit"]
			weapons["orbit"]["damage"] *= 1.20
			weapons["orbit"]["speed"] *= 1.10
			player.speed *= 1.035
		"roaming_close_spread":
			evolved_weapons = ["orbit", "nova"]
			weapons["orbit"]["count"] = mini(8, int(weapons["orbit"]["count"]) + 1)
			weapons["nova"]["radius"] += 9.0
			player.speed *= 1.025
		"roaming_distant_focus":
			evolved_weapons = ["pulse"]
			weapons["pulse"]["damage"] *= 1.09
			weapons["pulse"]["interval"] *= 0.86
			weapons["pulse"]["projectile_speed"] *= 1.10
			player.speed *= 1.025
		"roaming_distant_spread":
			evolved_weapons = ["arc"]
			weapons["arc"]["interval"] *= 0.84
			weapons["arc"]["range"] += 18.0
			if rank % 2 == 0:
				weapons["arc"]["chains"] = mini(9, int(weapons["arc"]["chains"]) + 1)
			player.speed *= 1.025
	for weapon_id: String in evolved_weapons:
		weapons[weapon_id]["level"] = maxi(1, int(weapons[weapon_id]["level"]) + 1)
	var result := definition(id).duplicate(true)
	result["id"] = id
	result["rank"] = rank
	return result
