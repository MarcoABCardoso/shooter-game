class_name OperationEvolutionCatalog
extends RefCounted

const BREAKPOINTS := {2: 1, 4: 2}

const ORDER: Array[String] = [
	"bastion_array",
	"scatter_array",
	"gravity_well",
	"phase_mooring",
	"overrun_choke",
	"escape_velocity",
]

const DEFINITIONS := {
	"bastion_array": {
		"name": "BASTION ARRAY",
		"tier": 1,
		"branch": "bastion",
		"requires": "",
		"description": "Hold position to charge damage, range, and knockback. Normal movement resets the charge.",
		"future": "GRAVITY WELL or PHASE MOORING",
	},
	"scatter_array": {
		"name": "SCATTER ARRAY",
		"tier": 1,
		"branch": "scatter",
		"requires": "",
		"description": "Convert Pulse into a five-shot close-range spread. Moving increases damage and cycling speed.",
		"future": "OVERRUN CHOKE or ESCAPE VELOCITY",
	},
	"gravity_well": {
		"name": "GRAVITY WELL",
		"tier": 2,
		"branch": "bastion",
		"requires": "bastion_array",
		"description": "Deepen a full anchor charge with greater range and violent knockback.",
		"future": "END OF PROTOTYPE PATH",
	},
	"phase_mooring": {
		"name": "PHASE MOORING",
		"tier": 2,
		"branch": "bastion",
		"requires": "bastion_array",
		"description": "Phase Dash preserves anchor charge, enabling emergency relocation without rebuilding it.",
		"future": "END OF PROTOTYPE PATH",
	},
	"overrun_choke": {
		"name": "OVERRUN CHOKE",
		"tier": 2,
		"branch": "scatter",
		"requires": "scatter_array",
		"description": "Fire seven wider pellets at even shorter range for dangerous close passes.",
		"future": "END OF PROTOTYPE PATH",
	},
	"escape_velocity": {
		"name": "ESCAPE VELOCITY",
		"tier": 2,
		"branch": "scatter",
		"requires": "scatter_array",
		"description": "Movement sharply accelerates the Scatter Array's firing cycle.",
		"future": "END OF PROTOTYPE PATH",
	},
}

const AUTOMATIC_GROWTH := {
	"pulse": {"damage": 1.10, "interval": 0.96},
	"orbit": {"damage": 1.10, "speed": 1.04},
	"arc": {"damage": 1.10, "interval": 0.96},
	"nova": {"damage": 1.10, "interval": 0.96, "radius": 1.02},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})


static func tier_for_level(level: int) -> int:
	return int(BREAKPOINTS.get(level, 0))


static func choices_for(tier: int, selected: Array[String]) -> Array[String]:
	var choices: Array[String] = []
	for id: String in ORDER:
		var spec := definition(id)
		if int(spec["tier"]) != tier:
			continue
		var requirement := String(spec["requires"])
		if requirement.is_empty() or selected.has(requirement):
			choices.append(id)
	return choices


static func apply_automatic_growth(weapons: Dictionary, levels: int) -> void:
	for _level in levels:
		for weapon: String in AUTOMATIC_GROWTH:
			if not weapons.has(weapon) or int(weapons[weapon]["level"]) <= 0:
				continue
			for field: String in AUTOMATIC_GROWTH[weapon]:
				weapons[weapon][field] = float(weapons[weapon][field]) * float(AUTOMATIC_GROWTH[weapon][field])


static func apply(id: String, weapons: Dictionary) -> bool:
	if not DEFINITIONS.has(id) or not weapons.has("pulse"):
		return false
	var pulse: Dictionary = weapons["pulse"]
	match id:
		"bastion_array":
			pulse["evolution"] = "bastion"
			pulse["anchor_damage"] = 0.35
			pulse["anchor_range"] = 105.0
			pulse["anchor_knockback"] = 55.0
			pulse["anchor_charge_time"] = 2.6
		"scatter_array":
			pulse["evolution"] = "scatter"
			pulse["damage"] = float(pulse["damage"]) * 0.55
			pulse["interval"] = float(pulse["interval"]) * 1.10
			pulse["count"] = 5
			pulse["spread"] = 0.17
			pulse["range"] = 155.0
		"gravity_well":
			pulse["anchor_damage"] = 0.55
			pulse["anchor_range"] = 145.0
			pulse["anchor_knockback"] = 95.0
		"phase_mooring":
			pulse["anchor_damage"] = 0.45
			pulse["preserve_anchor_on_dash"] = true
		"overrun_choke":
			pulse["count"] = 7
			pulse["spread"] = 0.21
			pulse["range"] = 135.0
		"escape_velocity":
			pulse["moving_interval_multiplier"] = 0.52
		_: return false
	return true
