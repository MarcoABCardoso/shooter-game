class_name BehaviorProfile
extends RefCounted

const MOVEMENT_WINDOW := 8.0
const FOCUS_WINDOW := 7.0
const CLOSE_DISTANCE := 100.0
const DISTANT_DISTANCE := 460.0

var anchored_roaming := 0.0
var close_distant := 0.0
var focus_spread := 0.0
var combat_time := 0.0
var damage_events := 0
var target_pressure: Dictionary = {}


func reset() -> void:
	anchored_roaming = 0.0
	close_distant = 0.0
	focus_spread = 0.0
	combat_time = 0.0
	damage_events = 0
	target_pressure.clear()


func tick(delta: float, player_velocity: Vector2, player_speed: float, enemy_count: int) -> void:
	_decay_target_pressure(delta)
	if enemy_count <= 0 or player_speed <= 0.0:
		return
	combat_time += delta
	var speed_ratio := clampf(player_velocity.length() / player_speed, 0.0, 1.0)
	var movement_sample := remap(clampf(speed_ratio, 0.12, 0.80), 0.12, 0.80, -1.0, 1.0)
	var alpha := 1.0 - exp(-delta / MOVEMENT_WINDOW)
	anchored_roaming = lerpf(anchored_roaming, movement_sample, alpha)


func record_damage(target_id: int, distance: float, amount: float) -> void:
	if amount <= 0.0:
		return
	damage_events += 1
	var event_weight := clampf(sqrt(amount) / 3.0, 0.35, 2.5)
	var range_sample := remap(clampf(distance, CLOSE_DISTANCE, DISTANT_DISTANCE), CLOSE_DISTANCE, DISTANT_DISTANCE, -1.0, 1.0)
	var alpha := 1.0 - exp(-event_weight / 8.0)
	close_distant = lerpf(close_distant, range_sample, alpha)
	if target_id > 0:
		target_pressure[target_id] = float(target_pressure.get(target_id, 0.0)) + event_weight
		_update_focus_score(alpha)


func corner_id() -> String:
	return "%s_%s_%s" % [
		"roaming" if anchored_roaming > 0.0 else "anchored",
		"distant" if close_distant >= 0.0 else "close",
		"spread" if focus_spread > 0.0 else "focus",
	]


func display_profile() -> String:
	return "%s / %s / %s" % [
		_axis_term(anchored_roaming, "ANCHORED", "ROAMING"),
		_axis_term(close_distant, "CLOSE", "DISTANT"),
		_axis_term(focus_spread, "FOCUS", "SPREAD"),
	]


func values() -> Array[float]:
	return [anchored_roaming, close_distant, focus_spread]


func _decay_target_pressure(delta: float) -> void:
	if target_pressure.is_empty():
		return
	var decay := exp(-delta / FOCUS_WINDOW)
	for target_id: Variant in target_pressure.keys():
		target_pressure[target_id] = float(target_pressure[target_id]) * decay
		if float(target_pressure[target_id]) < 0.025:
			target_pressure.erase(target_id)
	if not target_pressure.is_empty():
		_update_focus_score(1.0 - exp(-delta / 1.4))


func _update_focus_score(alpha: float) -> void:
	var total := 0.0
	var strongest := 0.0
	for pressure: Variant in target_pressure.values():
		var value := float(pressure)
		total += value
		strongest = maxf(strongest, value)
	if total <= 0.0:
		return
	var concentration := strongest / total
	var spread_sample := clampf(1.0 - 2.0 * concentration, -1.0, 1.0)
	focus_spread = lerpf(focus_spread, spread_sample, clampf(alpha, 0.0, 1.0))


func _axis_term(value: float, negative: String, positive: String) -> String:
	if absf(value) < 0.12:
		return "BALANCED"
	return positive if value > 0.0 else negative
