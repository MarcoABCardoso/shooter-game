class_name GameBalance
extends RefCounted

const StageCatalog := preload("res://scripts/content/stage_catalog.gd")

const ARENA := Rect2(54.0, 76.0, 1172.0, 590.0)
const MAX_ENEMIES := 190
const BOSS_INTRO_DURATION := 2.4


static func enemy_difficulty(stage_id: String, elapsed: float) -> float:
	var spec := StageCatalog.definition(stage_id)
	return float(spec["health_base"]) * (1.0 + elapsed / float(spec["health_growth"]))


static func spawn_interval(stage_id: String, elapsed: float) -> float:
	var spec := StageCatalog.definition(stage_id)
	return maxf(float(spec["spawn_min"]), float(spec["spawn_base"]) / (1.0 + elapsed / float(spec["spawn_pressure"])))


static func spawn_count(stage_id: String, elapsed: float) -> int:
	return 2 if elapsed >= float(StageCatalog.definition(stage_id)["double_spawn_at"]) else 1
