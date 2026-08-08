class_name SaveProfile
extends RefCounted

const SAVE_PATH := "user://neon_requiem_save.json"
const SAVE_VERSION := 4
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
	"upgrades": {
		"damage": 0,
		"hull": 0,
		"thrusters": 0,
		"magnet": 0,
		"fortune": 0,
	},
	"mastery_xp": {
		"pulse": 0.0,
		"orbit": 0.0,
		"arc": 0.0,
		"nova": 0.0,
	},
	"mastery_allocations": {
		"pulse": 0,
		"orbit": 0,
		"arc": 0,
		"nova": 0,
	},
	"discovered": {
		"pulse": true,
		"orbit": false,
		"arc": false,
		"nova": false,
		"dash": true,
		"anchored_close_focus": false,
		"anchored_close_spread": false,
		"anchored_distant_focus": false,
		"anchored_distant_spread": false,
		"roaming_close_focus": false,
		"roaming_close_spread": false,
		"roaming_distant_focus": false,
		"roaming_distant_spread": false,
	},
}

var data: Dictionary = DEFAULT_DATA.duplicate(true)


func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_profile()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var previous_version := int(parsed.get("version", 0))
		_merge_known(data, parsed)
		data["version"] = SAVE_VERSION
		_repair_mastery_allocations(previous_version < 3)
		_repair_discovery()
		if previous_version < SAVE_VERSION:
			save_profile()


func save_profile() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))


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


func mastery_level(weapon: String) -> int:
	var xp := float(data["mastery_xp"].get(weapon, 0.0))
	return mini(MASTERY_MAX, int(floor(sqrt(xp / 140.0))))


func allocated_mastery(weapon: String) -> int:
	return int(data["mastery_allocations"].get(weapon, 0))


func mastery_allocation_cap(weapon: String) -> int:
	return mastery_level(weapon) * 2


func unallocated_mastery() -> int:
	var earned := 0
	var allocated := 0
	for weapon: String in data["mastery_xp"]:
		earned += mastery_level(weapon)
		allocated += allocated_mastery(weapon)
	return maxi(0, earned - allocated)


func can_adjust_mastery_allocation(weapon: String, delta: int) -> bool:
	if not data["mastery_allocations"].has(weapon) or absi(delta) != 1:
		return false
	var current := allocated_mastery(weapon)
	if delta < 0 and current <= 0:
		return false
	if delta > 0 and (unallocated_mastery() <= 0 or current >= mastery_allocation_cap(weapon)):
		return false
	return true


func adjust_mastery_allocation(weapon: String, delta: int) -> bool:
	if not can_adjust_mastery_allocation(weapon, delta):
		return false
	var current := allocated_mastery(weapon)
	data["mastery_allocations"][weapon] = current + delta
	save_profile()
	return true


func mastery_bonus(weapon: String) -> float:
	return float(allocated_mastery(weapon)) * MASTERY_BONUS_PER_POINT


func mastery_progress(weapon: String) -> float:
	var level := mastery_level(weapon)
	if level >= MASTERY_MAX:
		return 1.0
	var xp := float(data["mastery_xp"].get(weapon, 0.0))
	var floor_xp := 140.0 * level * level
	var next_xp := 140.0 * (level + 1) * (level + 1)
	return clampf((xp - floor_xp) / (next_xp - floor_xp), 0.0, 1.0)


func bank_run(flux: int, elapsed: float, level: int, kills: int, mastery: Dictionary) -> void:
	data["flux"] = int(data["flux"]) + flux
	data["best_time"] = maxf(float(data["best_time"]), elapsed)
	data["best_level"] = maxi(int(data["best_level"]), level)
	data["total_kills"] = int(data["total_kills"]) + kills
	data["runs"] = int(data["runs"]) + 1
	_apply_mastery_rewards(mastery)
	save_profile()


func _apply_mastery_rewards(mastery: Dictionary) -> void:
	for weapon: String in mastery:
		if data["mastery_xp"].has(weapon):
			var previous_level := mastery_level(weapon)
			data["mastery_xp"][weapon] = float(data["mastery_xp"][weapon]) + float(mastery[weapon])
			var ranks_gained := mastery_level(weapon) - previous_level
			if ranks_gained > 0:
				# New mastery defaults to the weapon that earned it. Players can
				# redistribute it later from the Callibrations screen.
				data["mastery_allocations"][weapon] = allocated_mastery(weapon) + ranks_gained
	_repair_mastery_allocations(false)


func _merge_known(target: Dictionary, source: Dictionary) -> void:
	for key: Variant in target.keys():
		if not source.has(key):
			continue
		if target[key] is Dictionary and source[key] is Dictionary:
			_merge_known(target[key], source[key])
		else:
			target[key] = source[key]


func _repair_discovery() -> void:
	data["discovered"]["pulse"] = true
	data["discovered"]["dash"] = true
	for weapon_id in ["orbit", "arc", "nova"]:
		if float(data["mastery_xp"].get(weapon_id, 0.0)) > 0.0:
			data["discovered"][weapon_id] = true


func _repair_mastery_allocations(initialize_from_mastery: bool) -> void:
	if initialize_from_mastery:
		for weapon: String in data["mastery_allocations"]:
			data["mastery_allocations"][weapon] = mastery_level(weapon)
	else:
		for weapon: String in data["mastery_allocations"]:
			data["mastery_allocations"][weapon] = clampi(allocated_mastery(weapon), 0, mastery_allocation_cap(weapon))
	var earned_total := 0
	var allocated_total := 0
	for weapon: String in data["mastery_allocations"]:
		earned_total += mastery_level(weapon)
		allocated_total += allocated_mastery(weapon)
	var overflow := allocated_total - earned_total
	if overflow <= 0:
		return
	var weapons: Array = data["mastery_allocations"].keys()
	weapons.reverse()
	for weapon: String in weapons:
		var reduction := mini(overflow, allocated_mastery(weapon))
		data["mastery_allocations"][weapon] = allocated_mastery(weapon) - reduction
		overflow -= reduction
		if overflow <= 0:
			break
