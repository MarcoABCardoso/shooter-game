class_name SaveProfile
extends RefCounted

const LEGACY_SAVE_PATH := "user://neon_requiem_save.json"
const SAVE_PATH := LEGACY_SAVE_PATH
const SAVE_SLOT_PATH := "user://neon_requiem_save_%d.json"
const SLOT_COUNT := 3
const SAVE_VERSION := 6
const UPGRADE_MAX := 10
const MASTERY_MAX := 20
const MASTERY_BONUS_PER_POINT := 0.025
const MetaUpgradeData := preload("res://scripts/content/meta_upgrade_catalog.gd")
const DEFAULT_DATA := {
	"version": SAVE_VERSION,
	"flux": 0,
	"best_time": 0.0,
	"best_level": 1,
	"total_kills": 0,
	"runs": 0,
	"stages_cleared": {"stage_1": false, "stage_2": false},
	"equipped_weapons": ["pulse"],
	"equipped_ability": "dash",
	"upgrades": {
		"damage": 0,
		"hull": 0,
		"thrusters": 0,
		"magnet": 0,
		"fortune": 0,
	},
	"skill_ranks": {
		"core_damage": 0,
		"distant_power": 0,
		"anchored_power": 0,
		"arc_overload": 0,
		"impact_vector": 0,
		"orbit_overdrive": 0,
		"reinforced_core": 0,
		"nova_reactor": 0,
	},
	"mastery_xp": {
		"pulse": 0.0,
		"orbit": 0.0,
		"arc": 0.0,
		"nova": 0.0,
		"dash": 0.0,
		"vector_parry": 0.0,
	},
	"discovered": {
		"pulse": true,
		"orbit": true,
		"arc": true,
		"nova": false,
		"dash": true,
		"vector_parry": false,
	},
}

var data: Dictionary = DEFAULT_DATA.duplicate(true)
var active_slot := 0


func load_profile() -> void:
	active_slot = 1
	if not load_slot(active_slot):
		reset()


func load_slot(slot: int) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		return false
	active_slot = slot
	data = DEFAULT_DATA.duplicate(true)
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		if slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
			path = LEGACY_SAVE_PATH
		else:
			return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var previous_version := int(parsed.get("version", 0))
	_merge_known(data, parsed)
	data["version"] = SAVE_VERSION
	_repair_profile(previous_version)
	if previous_version < SAVE_VERSION or path == LEGACY_SAVE_PATH:
		save_profile()
	return true


func create_slot(slot: int) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		return false
	active_slot = slot
	data = DEFAULT_DATA.duplicate(true)
	return save_profile()


static func slot_path(slot: int) -> String:
	return SAVE_SLOT_PATH % slot


static func slot_exists(slot: int) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		return false
	return FileAccess.file_exists(slot_path(slot)) or (slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH))


static func slot_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for slot in range(1, SLOT_COUNT + 1):
		var summary := {"slot": slot, "exists": slot_exists(slot), "best_time": 0.0, "best_level": 1, "runs": 0, "flux": 0}
		if bool(summary["exists"]):
			var path := slot_path(slot)
			if not FileAccess.file_exists(path) and slot == 1:
				path = LEGACY_SAVE_PATH
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				var parsed: Variant = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary:
					for key in ["best_time", "best_level", "runs", "flux"]:
						summary[key] = parsed.get(key, summary[key])
		summaries.append(summary)
	return summaries


func save_profile() -> bool:
	if active_slot < 1 or active_slot > SLOT_COUNT:
		return false
	var file := FileAccess.open(slot_path(active_slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func reset() -> void:
	data = DEFAULT_DATA.duplicate(true)
	save_profile()


func upgrade_level(id: String) -> int:
	return int(data["upgrades"].get(id, 0))


func upgrade_cost(id: String) -> int:
	return MetaUpgradeData.cost_for_rank(upgrade_level(id))


func buy_upgrade(id: String) -> bool:
	var level := upgrade_level(id)
	if level >= UPGRADE_MAX:
		return false
	var cost := upgrade_cost(id)
	if int(data["flux"]) < cost:
		return false
	data["flux"] = int(data["flux"]) - cost
	data["upgrades"][id] = level + 1
	save_profile()
	return true


func bonus(id: String) -> float:
	return MetaUpgradeData.bonus(id, upgrade_level(id))


func is_discovered(id: String) -> bool:
	return bool(data["discovered"].get(id, false))


func discover_entries(ids: Array[String]) -> bool:
	var changed := false
	for id: String in ids:
		if data["discovered"].has(id) and not bool(data["discovered"][id]):
			data["discovered"][id] = true
			changed = true
	if changed:
		save_profile()
	return changed


func stage_cleared(id: String) -> bool:
	return bool(data["stages_cleared"].get(id, false))


func clear_stage_one() -> bool:
	var first_clear := not stage_cleared("stage_1")
	data["stages_cleared"]["stage_1"] = true
	data["discovered"]["vector_parry"] = true
	data["discovered"]["nova"] = true
	save_profile()
	return first_clear


func unlocked_weapon_slots() -> int:
	if stage_cleared("stage_2"):
		return 3
	return 2 if stage_cleared("stage_1") else 1


func equipped_weapons() -> Array[String]:
	var result: Array[String] = []
	for value: Variant in data.get("equipped_weapons", ["pulse"]):
		var id := String(value)
		if WeaponCatalog.ORDER.has(id) and is_discovered(id) and not result.has(id):
			result.append(id)
	if result.is_empty():
		result.append("pulse")
	return result


func equip_weapon(id: String) -> bool:
	if not WeaponCatalog.ORDER.has(id) or not is_discovered(id):
		return false
	var equipped := equipped_weapons()
	if equipped.has(id):
		if equipped.size() <= 1:
			return false
		equipped.erase(id)
	elif equipped.size() < unlocked_weapon_slots():
		equipped.append(id)
	else:
		# Selecting a new weapon with a full bay replaces the oldest slot.
		equipped.pop_front()
		equipped.append(id)
	data["equipped_weapons"] = equipped
	save_profile()
	return true


func equipped_ability() -> String:
	var id := String(data.get("equipped_ability", "dash"))
	return id if is_discovered(id) else "dash"


func equip_ability(id: String) -> bool:
	if id not in ["dash", "vector_parry"] or not is_discovered(id):
		return false
	data["equipped_ability"] = id
	save_profile()
	return true


func mastery_level(item: String) -> int:
	var xp := float(data["mastery_xp"].get(item, 0.0))
	return mini(MASTERY_MAX, int(floor(sqrt(xp / 140.0))))


func mastery_bonus(item: String) -> float:
	return float(mastery_level(item)) * MASTERY_BONUS_PER_POINT


func mastery_progress(item: String) -> float:
	var level := mastery_level(item)
	if level >= MASTERY_MAX:
		return 1.0
	var xp := float(data["mastery_xp"].get(item, 0.0))
	var floor_xp := 140.0 * level * level
	var next_xp := 140.0 * (level + 1) * (level + 1)
	return clampf((xp - floor_xp) / (next_xp - floor_xp), 0.0, 1.0)


func skill_rank(id: String) -> int:
	return int(data["skill_ranks"].get(id, 0))


func skill_cost(id: String) -> int:
	return SkillTreeCatalog.cost_for_rank(id, skill_rank(id))


func skill_available(id: String) -> bool:
	var definition := SkillTreeCatalog.definition(id)
	if definition.is_empty() or skill_rank(id) >= int(definition["max_rank"]):
		return false
	var stage := String(definition.get("stage", ""))
	if not stage.is_empty() and not stage_cleared(stage):
		return false
	var prerequisites: Dictionary = definition.get("requires", {})
	for prerequisite: String in prerequisites:
		if skill_rank(prerequisite) < int(prerequisites[prerequisite]):
			return false
	var mastery_requirements: Dictionary = definition.get("mastery", {})
	for item: String in mastery_requirements:
		if mastery_level(item) < int(mastery_requirements[item]):
			return false
	return true


func buy_skill(id: String) -> bool:
	if not skill_available(id):
		return false
	var cost := skill_cost(id)
	if cost <= 0 or int(data["flux"]) < cost:
		return false
	data["flux"] = int(data["flux"]) - cost
	data["skill_ranks"][id] = skill_rank(id) + 1
	save_profile()
	return true


func respec_skills() -> int:
	var refund := 0
	for id: String in SkillTreeCatalog.ORDER:
		var rank := skill_rank(id)
		for purchased_rank in rank:
			refund += SkillTreeCatalog.cost_for_rank(id, purchased_rank)
		data["skill_ranks"][id] = 0
	data["flux"] = int(data["flux"]) + refund
	if refund > 0:
		save_profile()
	return refund


func skill_effect(effect: String) -> float:
	var total := 0.0
	for id: String in SkillTreeCatalog.ORDER:
		var definition := SkillTreeCatalog.definition(id)
		if String(definition.get("effect", "")) == effect:
			total += skill_rank(id) * float(definition.get("value", 0.0))
	return total


func bank_run(flux: int, elapsed: float, level: int, kills: int, mastery: Dictionary) -> void:
	data["flux"] = int(data["flux"]) + flux
	data["best_time"] = maxf(float(data["best_time"]), elapsed)
	data["best_level"] = maxi(int(data["best_level"]), level)
	data["total_kills"] = int(data["total_kills"]) + kills
	data["runs"] = int(data["runs"]) + 1
	_apply_mastery_rewards(mastery)
	save_profile()


func _apply_mastery_rewards(mastery: Dictionary) -> void:
	for item: String in mastery:
		if data["mastery_xp"].has(item):
			data["mastery_xp"][item] = float(data["mastery_xp"][item]) + float(mastery[item])


func _merge_known(target: Dictionary, source: Dictionary) -> void:
	for key: Variant in target.keys():
		if not source.has(key):
			continue
		if target[key] is Dictionary and source[key] is Dictionary:
			_merge_known(target[key], source[key])
		else:
			target[key] = source[key]


func _repair_profile(previous_version: int) -> void:
	data["discovered"]["pulse"] = true
	data["discovered"]["orbit"] = true
	data["discovered"]["arc"] = true
	data["discovered"]["dash"] = true
	if stage_cleared("stage_1"):
		data["discovered"]["nova"] = true
		data["discovered"]["vector_parry"] = true
	if previous_version < 6:
		data["equipped_weapons"] = ["pulse"]
	var repaired := equipped_weapons()
	while repaired.size() > unlocked_weapon_slots():
		repaired.pop_back()
	data["equipped_weapons"] = repaired
