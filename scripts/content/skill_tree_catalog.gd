class_name SkillTreeCatalog
extends RefCounted

# Positions are normalized graph coordinates consumed by the hangar skill-tree view.
# Every rank repeats the node's effect value and uses the matching cost entry.
const ORDER: Array[String] = [
	"core_damage",
	"distant_power",
	"anchored_power",
	"arc_overload",
	"impact_vector",
	"orbit_overdrive",
	"reinforced_core",
	"nova_reactor",
]

const DEFINITIONS := {
	"core_damage": {
		"name": "AMPLIFIED CORE",
		"description": "+4% all weapon damage per rank.",
		"max_rank": 5,
		"costs": [40, 70, 110, 160, 220],
		"effect": "general_damage",
		"value": 0.04,
		"position": Vector2(0.5, 0.05),
	},
	"distant_power": {
		"name": "LONGSHOT ARRAY",
		"description": "+8% damage beyond 280 px per rank.",
		"max_rank": 3,
		"costs": [90, 140, 210],
		"effect": "distant_damage",
		"value": 0.08,
		"position": Vector2(0.22, 0.30),
		"requires": {"core_damage": 2},
	},
	"anchored_power": {
		"name": "SIEGE POSTURE",
		"description": "+7% damage after holding still for 2 seconds per rank.",
		"max_rank": 3,
		"costs": [90, 140, 210],
		"effect": "stationary_damage",
		"value": 0.07,
		"position": Vector2(0.78, 0.30),
		"requires": {"core_damage": 2},
	},
	"arc_overload": {
		"name": "ARC OVERLOAD",
		"description": "+10% Arc Lash damage per rank.",
		"max_rank": 2,
		"costs": [170, 260],
		"effect": "arc_damage",
		"value": 0.10,
		"position": Vector2(0.07, 0.60),
		"requires": {"distant_power": 2},
		"mastery": {"arc": 2},
	},
	"impact_vector": {
		"name": "IMPACT VECTOR",
		"description": "Weapon hits add 32 knockback per rank.",
		"max_rank": 2,
		"costs": [180, 280],
		"effect": "knockback",
		"value": 32.0,
		"position": Vector2(0.36, 0.60),
		"requires": {"distant_power": 2},
		"mastery": {"pulse": 2},
	},
	"orbit_overdrive": {
		"name": "ORBIT OVERDRIVE",
		"description": "+10% Orbit Blade damage per rank.",
		"max_rank": 2,
		"costs": [170, 260],
		"effect": "orbit_damage",
		"value": 0.10,
		"position": Vector2(0.64, 0.60),
		"requires": {"anchored_power": 2},
		"mastery": {"orbit": 2},
	},
	"reinforced_core": {
		"name": "REINFORCED CORE",
		"description": "+10 maximum hull per rank.",
		"max_rank": 3,
		"costs": [150, 230, 330],
		"effect": "hull",
		"value": 10.0,
		"position": Vector2(0.91, 0.60),
		"requires": {"anchored_power": 2},
		"stage": "stage_1",
	},
	"nova_reactor": {
		"name": "NOVA REACTOR",
		"description": "+12% Nova Burst damage per rank.",
		"max_rank": 2,
		"costs": [260, 400],
		"effect": "nova_damage",
		"value": 0.12,
		"position": Vector2(0.78, 0.88),
		"requires": {"reinforced_core": 2},
		"mastery": {"nova": 1},
		"stage": "stage_1",
	},
}


static func definition(id: String) -> Dictionary:
	return DEFINITIONS.get(id, {})


static func cost_for_rank(id: String, current_rank: int) -> int:
	var definition := definition(id)
	var costs: Array = definition.get("costs", [])
	if current_rank < 0 or current_rank >= costs.size():
		return 0
	return int(costs[current_rank])
