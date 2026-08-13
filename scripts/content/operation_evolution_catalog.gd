class_name OperationEvolutionCatalog
extends RefCounted

const BREAKPOINTS := {2: 1, 5: 2}

const ORDER: Array[String] = [
	"bastion_array", "scatter_array",
	"gravity_well", "phase_mooring", "overrun_choke", "escape_velocity",
	"razor_orbit", "aegis_orbit",
	"crosscut", "pursuit_edge", "null_lattice", "sanctuary_ring",
	"storm_chain", "execution_arc",
	"stormfront", "feedback_loop", "hunter_lock", "core_lance",
	"gravity_nova", "purge_nova",
	"event_horizon", "compression_cycle", "sanctuary_wave", "annihilation_ring",
]

static var DEFINITIONS := {
	"bastion_array": _definition("pulse", "BASTION ARRAY", 1, "sentinel", "", "SENTINEL", "Hold position to charge damage, range, and knockback. Repositioning spends charge by distance moved.", "GRAVITY WELL or PHASE MOORING"),
	"scatter_array": _definition("pulse", "SCATTER ARRAY", 1, "harrier", "", "HARRIER", "Convert Pulse into a five-shot close-range spread. Moving increases damage and cycling speed.", "OVERRUN CHOKE or ESCAPE VELOCITY"),
	"gravity_well": _definition("pulse", "GRAVITY WELL", 2, "sentinel", "bastion_array", "SENTINEL", "Deepen a full anchor charge with greater range and violent knockback.", "COMPLETE"),
	"phase_mooring": _definition("pulse", "PHASE MOORING", 2, "sentinel", "bastion_array", "SENTINEL", "Active movement preserves anchor charge, enabling emergency relocation without rebuilding it.", "COMPLETE", 1),
	"overrun_choke": _definition("pulse", "OVERRUN CHOKE", 2, "harrier", "scatter_array", "HARRIER", "Fire seven wider pellets at even shorter range for dangerous close passes.", "COMPLETE"),
	"escape_velocity": _definition("pulse", "ESCAPE VELOCITY", 2, "harrier", "scatter_array", "HARRIER", "Movement sharply accelerates the Scatter Array's firing cycle.", "COMPLETE", 1),

	"razor_orbit": _definition("orbit", "RAZOR ORBIT", 1, "interceptor", "", "INTERCEPTOR", "Add a third fast, tight blade. Movement drives contact damage higher.", "CROSSCUT or PURSUIT EDGE"),
	"aegis_orbit": _definition("orbit", "AEGIS ORBIT", 1, "aegis", "", "AEGIS", "Widen the orbit into a slower screen that erases hostile projectiles it touches.", "NULL LATTICE or SANCTUARY RING"),
	"crosscut": _definition("orbit", "CROSSCUT", 2, "interceptor", "razor_orbit", "INTERCEPTOR", "Add two opposing blades for denser close passes.", "COMPLETE"),
	"pursuit_edge": _definition("orbit", "PURSUIT EDGE", 2, "interceptor", "razor_orbit", "INTERCEPTOR", "Moving expands and accelerates the blade ring, rewarding committed pursuit.", "COMPLETE", 1),
	"null_lattice": _definition("orbit", "NULL LATTICE", 2, "aegis", "aegis_orbit", "AEGIS", "Broaden each blade's projectile interception field.", "COMPLETE"),
	"sanctuary_ring": _definition("orbit", "SANCTUARY RING", 2, "aegis", "aegis_orbit", "AEGIS", "The defensive ring reaches farther and restores one shield charge after sustained interception.", "COMPLETE", 1),

	"storm_chain": _definition("arc", "STORM CHAIN", 1, "conduit", "", "CONDUIT", "Trade single-hit force for five reliable jumps through packed enemies.", "STORMFRONT or FEEDBACK LOOP"),
	"execution_arc": _definition("arc", "EXECUTION ARC", 1, "executioner", "", "EXECUTIONER", "Collapse the chain into a long-range strike with a large exposed-core payoff.", "HUNTER LOCK or CORE LANCE"),
	"stormfront": _definition("arc", "STORMFRONT", 2, "conduit", "storm_chain", "CONDUIT", "Extend the storm to seven targets and a wider jump radius.", "COMPLETE"),
	"feedback_loop": _definition("arc", "FEEDBACK LOOP", 2, "conduit", "storm_chain", "CONDUIT", "Each successful jump strengthens the next, making dense formations the ideal target.", "COMPLETE", 1),
	"hunter_lock": _definition("arc", "HUNTER LOCK", 2, "executioner", "execution_arc", "EXECUTIONER", "Ranged Threats mode cycles the execution strike faster.", "COMPLETE"),
	"core_lance": _definition("arc", "CORE LANCE", 2, "executioner", "execution_arc", "EXECUTIONER", "Further amplify damage during boss recovery windows.", "COMPLETE", 1),

	"gravity_nova": _definition("nova", "GRAVITY NOVA", 1, "singularity", "", "SINGULARITY", "Pull nearby enemies into the blast before it detonates, setting up concentrated follow-through.", "EVENT HORIZON or COMPRESSION CYCLE"),
	"purge_nova": _definition("nova", "PURGE NOVA", 1, "purifier", "", "PURIFIER", "Trade damage for a wider, faster wave that clears hostile fire beyond its damage ring.", "SANCTUARY WAVE or ANNIHILATION RING"),
	"event_horizon": _definition("nova", "EVENT HORIZON", 2, "singularity", "gravity_nova", "SINGULARITY", "Increase pull reach and force so distant formations collapse into the blast.", "COMPLETE"),
	"compression_cycle": _definition("nova", "COMPRESSION CYCLE", 2, "singularity", "gravity_nova", "SINGULARITY", "Shorten the interval after a gravity pull connects with several enemies.", "COMPLETE", 1),
	"sanctuary_wave": _definition("nova", "SANCTUARY WAVE", 2, "purifier", "purge_nova", "PURIFIER", "Clearing a dense projectile wave restores one shield charge.", "COMPLETE"),
	"annihilation_ring": _definition("nova", "ANNIHILATION RING", 2, "purifier", "purge_nova", "PURIFIER", "Concentrate damage at the edge of the wave where aggressive spacing is most dangerous.", "COMPLETE", 1),
}

const AUTOMATIC_GROWTH := {
	"pulse": {"damage": 1.10, "interval": 0.96},
	"orbit": {"damage": 1.10, "speed": 1.04},
	"arc": {"damage": 1.10, "interval": 0.96},
	"nova": {"damage": 1.10, "interval": 0.96, "radius": 1.02},
}


static func _definition(weapon: String, name: String, tier: int, branch: String, requires: String, build: String, description: String, future: String, mastery: int = 0) -> Dictionary:
	return {"weapon": weapon, "name": name, "tier": tier, "branch": branch, "requires": requires, "build": build, "description": description, "future": future, "mastery": mastery}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})


static func tier_for_level(level: int) -> int:
	return int(BREAKPOINTS.get(level, 0))


static func choices_for(tier: int, selected: Array[String], weapon: String = "pulse", mastery_level: int = 0) -> Array[String]:
	var choices: Array[String] = []
	for id: String in ORDER:
		var spec := definition(id)
		if String(spec["weapon"]) != weapon or int(spec["tier"]) != tier or int(spec.get("mastery", 0)) > mastery_level:
			continue
		var requirement := String(spec["requires"])
		if requirement.is_empty() or selected.has(requirement):
			choices.append(id)
	return choices


static func build_name(selected: Array[String]) -> String:
	for id: String in selected:
		var spec := definition(id)
		if int(spec.get("tier", 0)) == 1:
			return String(spec.get("build", ""))
	return ""


static func apply_automatic_growth(weapons: Dictionary, levels: int) -> void:
	for _level in levels:
		for weapon: String in AUTOMATIC_GROWTH:
			if not weapons.has(weapon) or int(weapons[weapon]["level"]) <= 0:
				continue
			for field: String in AUTOMATIC_GROWTH[weapon]:
				weapons[weapon][field] = float(weapons[weapon][field]) * float(AUTOMATIC_GROWTH[weapon][field])


static func apply(id: String, weapons: Dictionary) -> bool:
	var definition := definition(id)
	if definition.is_empty():
		return false
	var weapon := String(definition["weapon"])
	if not weapons.has(weapon) or int(weapons[weapon].get("level", 0)) <= 0:
		return false
	var spec: Dictionary = weapons[weapon]
	match id:
		"bastion_array": spec.merge({"evolution": "bastion", "anchor_damage": 0.35, "anchor_range": 105.0, "anchor_knockback": 55.0, "anchor_charge_time": 2.6, "anchor_drain_distance": 180.0}, true)
		"scatter_array": spec.merge({"evolution": "scatter", "damage": float(spec["damage"]) * 0.32, "interval": float(spec["interval"]) * 1.18, "count": 5, "spread": 0.17, "range": 155.0}, true)
		"gravity_well": spec.merge({"anchor_damage": 0.55, "anchor_range": 145.0, "anchor_knockback": 95.0}, true)
		"phase_mooring": spec.merge({"anchor_damage": 0.45, "preserve_anchor_on_dash": true}, true)
		"overrun_choke": spec.merge({"count": 7, "spread": 0.21, "range": 135.0}, true)
		"escape_velocity": spec["moving_interval_multiplier"] = 0.52
		"razor_orbit": spec.merge({"evolution": "razor", "count": 3, "speed": 2.25, "radius": 64.0, "moving_damage": 0.28}, true)
		"aegis_orbit": spec.merge({"evolution": "aegis", "damage": float(spec["damage"]) * 0.82, "speed": 1.45, "radius": 94.0, "intercept_radius": 18.0}, true)
		"crosscut": spec["count"] = int(spec["count"]) + 2
		"pursuit_edge": spec.merge({"moving_radius": 34.0, "moving_speed": 1.35}, true)
		"null_lattice": spec["intercept_radius"] = 34.0
		"sanctuary_ring": spec.merge({"radius": 116.0, "intercept_radius": 26.0, "intercept_shield": 12}, true)
		"storm_chain": spec.merge({"evolution": "storm", "damage": float(spec["damage"]) * 0.62, "chains": 5, "range": 275.0, "chain_falloff": 0.90}, true)
		"execution_arc": spec.merge({"evolution": "execution", "damage": float(spec["damage"]) * 1.75, "chains": 1, "range": 365.0, "exposed_multiplier": 1.45}, true)
		"stormfront": spec.merge({"chains": 7, "range": 315.0}, true)
		"feedback_loop": spec.merge({"chain_falloff": 1.12}, true)
		"hunter_lock": spec["ranged_interval_multiplier"] = 0.68
		"core_lance": spec["exposed_multiplier"] = 1.90
		"gravity_nova": spec.merge({"evolution": "gravity", "damage": float(spec["damage"]) * 0.84, "radius": 220.0, "pull_radius": 280.0, "pull_strength": 520.0}, true)
		"purge_nova": spec.merge({"evolution": "purge", "damage": float(spec["damage"]) * 0.68, "interval": float(spec["interval"]) * 0.76, "radius": 225.0, "clear_radius": 330.0}, true)
		"event_horizon": spec.merge({"pull_radius": 390.0, "pull_strength": 880.0}, true)
		"compression_cycle": spec["cluster_interval_multiplier"] = 0.58
		"sanctuary_wave": spec["projectile_shield_threshold"] = 8
		"annihilation_ring": spec.merge({"edge_damage": 0.85, "edge_width": 48.0}, true)
		_: return false
	return true
