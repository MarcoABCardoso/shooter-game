class_name MetaUpgradeCatalog
extends RefCounted

const MAX_RANK := 10
const DEFINITIONS: Array[Dictionary] = [
	{"id":"damage", "name":"AMPLIFIER", "description":"+6% all weapon damage / rank", "bonus_per_rank":0.06},
	{"id":"hull", "name":"HULL PLATING", "description":"+12 maximum hull / rank", "bonus_per_rank":12.0},
	{"id":"thrusters", "name":"VECTOR THRUSTERS", "description":"+3.5% movement speed / rank", "bonus_per_rank":0.035},
	{"id":"magnet", "name":"GRAVITY LENS", "description":"+14 repair collection range / rank", "bonus_per_rank":14.0},
	{"id":"fortune", "name":"FLUX SYNCHRONIZER", "description":"+5% Flux earned / rank", "bonus_per_rank":0.05},
]


static func definition(id: String) -> Dictionary:
	for item: Dictionary in DEFINITIONS:
		if item["id"] == id:
			return item
	assert(false, "Unknown permanent upgrade id: %s" % id)
	return {}


static func cost_for_rank(rank: int) -> int:
	return int(round(18.0 * pow(1.7, rank)))


static func bonus(id: String, rank: int) -> float:
	return float(definition(id)["bonus_per_rank"]) * rank
