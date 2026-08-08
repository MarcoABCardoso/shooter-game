class_name GameBalance
extends RefCounted

const ARENA := Rect2(54.0, 76.0, 1172.0, 590.0)
const MAX_ENEMIES := 190
const ELITE_INTERVAL := 60.0
const BOSS_INTERVAL := 120.0
const BASE_SPAWN_INTERVAL := 0.82
const MIN_SPAWN_INTERVAL := 0.16
const SPAWN_PRESSURE_SECONDS := 105.0
const ENEMY_HEALTH_SCALE_SECONDS := 155.0


static func enemy_difficulty(elapsed: float) -> float:
	return 1.0 + elapsed / ENEMY_HEALTH_SCALE_SECONDS


static func spawn_interval(elapsed: float) -> float:
	return maxf(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL / (1.0 + elapsed / SPAWN_PRESSURE_SECONDS))


static func spawn_count(elapsed: float) -> int:
	return 1 + int(elapsed / 95.0)
