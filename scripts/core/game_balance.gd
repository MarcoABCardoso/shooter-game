class_name GameBalance
extends RefCounted

const EncounterCatalog := preload("res://scripts/content/encounter_catalog.gd")

const ARENA := Rect2(54.0, 76.0, 1172.0, 590.0)
const MAX_ENEMIES := 190
const BOSS_INTRO_DURATION := 2.4
const MISSION_OUTRO_DURATION := 1.6
const GRAVITY_TETHER_FORCE := 620.0
const GRAVITY_TETHER_STOP_RADIUS := 34.0
const ENEMY_IMPULSE_DECELERATION := 420.0
const PHASE_DASH_DURATION := 0.36
const PHASE_DASH_COOLDOWN := 2.5
const PHASE_DASH_INVULNERABILITY := 0.46
const PHASE_DASH_SPEED_MULTIPLIER := 3.2
const PHASE_DASH_LANE_RADIUS := 46.0
const PHASE_DASH_LANE_DAMAGE := 12.0


static func enemy_difficulty(encounter_id: String, elapsed: float) -> float:
	var spec := EncounterCatalog.definition(encounter_id)
	return float(spec["health_base"]) * (1.0 + elapsed / float(spec["health_growth"]))


static func spawn_interval(encounter_id: String, elapsed: float) -> float:
	var spec := EncounterCatalog.definition(encounter_id)
	return maxf(float(spec["spawn_min"]), float(spec["spawn_base"]) / (1.0 + elapsed / float(spec["spawn_pressure"])))


static func spawn_count(encounter_id: String, elapsed: float) -> int:
	return 2 if elapsed >= float(EncounterCatalog.definition(encounter_id)["double_spawn_at"]) else 1
