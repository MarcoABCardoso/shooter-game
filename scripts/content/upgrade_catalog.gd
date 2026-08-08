class_name UpgradeCatalog
extends RefCounted

const BASE_CHOICES: Array[Dictionary] = [
	{"id":"pulse_damage", "icon":"◇", "name":"OVERCHARGE", "description":"Pulse damage +28%"},
	{"id":"pulse_rate", "icon":"»", "name":"ACCELERATOR", "description":"Pulse fire rate +18%"},
	{"id":"pulse_count", "icon":"⋔", "name":"FORKED SIGNAL", "description":"Pulse gains +1 projectile"},
	{"id":"pulse_pierce", "icon":"→", "name":"PHASE ROUND", "description":"Pulse pierces +1 target"},
	{"id":"hull", "icon":"⬡", "name":"HULL MATRIX", "description":"Max hull +20 and repair 20"},
	{"id":"speed", "icon":"△", "name":"VECTOR DRIVE", "description":"Movement speed +10%"},
	{"id":"magnet", "icon":"⌁", "name":"GRAVITY WELL", "description":"Pickup radius +35"},
]

static func available(run_level: int, weapons: Dictionary) -> Array[Dictionary]:
	var pool: Array[Dictionary] = BASE_CHOICES.duplicate(true)
	if int(weapons["orbit"]["level"]) == 0:
		pool.append(_choice("unlock_orbit", "◉", "ORBIT BLADES", "Unlock rotating contact blades"))
	else:
		pool.append(_choice("orbit_damage", "◉", "SHARPEN ORBIT", "Orbit damage +35%"))
		pool.append(_choice("orbit_count", "⊙", "EXTRA SATELLITE", "Add one orbit blade"))
	if run_level >= 4:
		if int(weapons["arc"]["level"]) == 0:
			pool.append(_choice("unlock_arc", "ϟ", "ARC LASH", "Unlock chaining lightning"))
		else:
			pool.append(_choice("arc_chain", "ϟ", "ARC BRANCH", "Arc gains +1 chain"))
			pool.append(_choice("arc_rate", "ϟ", "ION LOOP", "Arc cooldown -18%"))
	if run_level >= 7:
		if int(weapons["nova"]["level"]) == 0:
			pool.append(_choice("unlock_nova", "✦", "NOVA BURST", "Unlock periodic blast and bullet clear"))
		else:
			pool.append(_choice("nova_power", "✦", "SUPERNOVA", "Nova damage and radius +20%"))
			pool.append(_choice("nova_rate", "✦", "COLLAPSE LOOP", "Nova cooldown -18%"))
	return pool


static func apply(id: String, weapons: Dictionary, player: NeonPlayer) -> void:
	match id:
		"pulse_damage": weapons["pulse"]["damage"] *= 1.28; weapons["pulse"]["level"] += 1
		"pulse_rate": weapons["pulse"]["interval"] *= 0.82; weapons["pulse"]["level"] += 1
		"pulse_count": weapons["pulse"]["count"] = mini(7, int(weapons["pulse"]["count"]) + 1); weapons["pulse"]["level"] += 1
		"pulse_pierce": weapons["pulse"]["pierce"] = int(weapons["pulse"]["pierce"]) + 1; weapons["pulse"]["level"] += 1
		"hull": player.max_health += 20.0; player.heal(20.0)
		"speed": player.speed *= 1.10
		"magnet": player.pickup_radius += 35.0
		"unlock_orbit": weapons["orbit"]["level"] = 1
		"orbit_damage": weapons["orbit"]["damage"] *= 1.35; weapons["orbit"]["level"] += 1
		"orbit_count": weapons["orbit"]["count"] = mini(8, int(weapons["orbit"]["count"]) + 1); weapons["orbit"]["level"] += 1
		"unlock_arc": weapons["arc"]["level"] = 1
		"arc_chain": weapons["arc"]["chains"] = int(weapons["arc"]["chains"]) + 1; weapons["arc"]["level"] += 1
		"arc_rate": weapons["arc"]["interval"] *= 0.82; weapons["arc"]["level"] += 1
		"unlock_nova": weapons["nova"]["level"] = 1
		"nova_power": weapons["nova"]["damage"] *= 1.20; weapons["nova"]["radius"] *= 1.12; weapons["nova"]["level"] += 1
		"nova_rate": weapons["nova"]["interval"] *= 0.82; weapons["nova"]["level"] += 1


static func _choice(id: String, icon: String, display_name: String, description: String) -> Dictionary:
	return {"id": id, "icon": icon, "name": display_name, "description": description}
