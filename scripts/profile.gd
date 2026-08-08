class_name SaveProfile
extends RefCounted

const SAVE_PATH := "user://neon_requiem_save.json"
const SAVE_VERSION := 1
const UPGRADE_MAX := 10
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
		_merge_known(data, parsed)


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


func mastery_level(weapon: String) -> int:
	var xp := float(data["mastery_xp"].get(weapon, 0.0))
	return mini(20, int(floor(sqrt(xp / 140.0))))


func mastery_bonus(weapon: String) -> float:
	return float(mastery_level(weapon)) * 0.025


func mastery_progress(weapon: String) -> float:
	var level := mastery_level(weapon)
	if level >= 20:
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
	for weapon: String in mastery:
		if data["mastery_xp"].has(weapon):
			data["mastery_xp"][weapon] = float(data["mastery_xp"][weapon]) + float(mastery[weapon])
	save_profile()


func _merge_known(target: Dictionary, source: Dictionary) -> void:
	for key: Variant in target.keys():
		if not source.has(key):
			continue
		if target[key] is Dictionary and source[key] is Dictionary:
			_merge_known(target[key], source[key])
		else:
			target[key] = source[key]
