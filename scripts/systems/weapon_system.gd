class_name WeaponSystem
extends Node2D

const OperationEvolutionCatalog := preload("res://scripts/content/operation_evolution_catalog.gd")

signal projectile_requested(origin: Vector2, direction: Vector2, damage: float, speed: float, friendly: bool, weapon: String, pierce: int, radius: float, distant_bonus: float, knockback: float, max_range: float, splash_damage: float, splash_radius: float)
signal damage_dealt(weapon: String, amount: float, world_position: Vector2, target_id: int)
signal burst_requested(world_position: Vector2, color: Color, size: float, spokes: int)
signal shake_requested(amount: float)
signal tone_requested(frequency: float, duration: float, volume: float, slide: float)

const ORBIT_CHECK_INTERVAL := 1.0 / 30.0
const VISUAL_UPDATE_INTERVAL := 1.0 / 30.0
const TARGET_MODES: Array[String] = ["nearest", "ranged", "high_health"]
const TARGET_MODE_NAMES := {
	"nearest": "NEAREST",
	"ranged": "RANGED THREATS",
	"high_health": "HIGHEST HEALTH",
}

var player: NeonPlayer
var profile: SaveProfile
var session: RunSession
var enemies: Array[NeonEnemy] = []
var weapons: Dictionary = WeaponCatalog.fresh_loadout()
var timers := {"pulse": 0.0, "arc": 0.0, "nova": 0.0}
var orbit_hit_time := {}
var arc_visuals: Array[Dictionary] = []
var nova_visual := 0.0
var active := false
var orbit_check_timer := 0.0
var visual_update_timer := 0.0
var target_mode_index := 0


func configure(run_player: NeonPlayer, save_profile: SaveProfile, run_session: RunSession, tracked_enemies: Array[NeonEnemy]) -> void:
	player = run_player
	profile = save_profile
	session = run_session
	enemies = tracked_enemies
	weapons = WeaponCatalog.fresh_loadout(profile.equipped_weapons())
	timers = {"pulse": 0.1, "arc": 0.1, "nova": 1.0}
	orbit_hit_time.clear()
	arc_visuals.clear()
	nova_visual = 0.0
	orbit_check_timer = 0.0
	visual_update_timer = 0.0
	target_mode_index = 0
	active = true


func apply_operation_growth(levels: int) -> void:
	OperationEvolutionCatalog.apply_automatic_growth(weapons, levels)
	session.automatic_growth_levels += levels


func apply_operation_evolution(id: String) -> bool:
	var definition := OperationEvolutionCatalog.definition(id)
	if definition.is_empty():
		return false
	var tier := int(definition["tier"])
	if not OperationEvolutionCatalog.choices_for(tier, session.operation_evolutions).has(id):
		return false
	if not OperationEvolutionCatalog.apply(id, weapons):
		return false
	if not session.register_operation_evolution(id):
		return false
	if bool(weapons["pulse"].get("preserve_anchor_on_dash", false)):
		player.set_preserve_stationary_on_dash(true)
	queue_redraw()
	return true


func cycle_target_mode() -> String:
	target_mode_index = (target_mode_index + 1) % TARGET_MODES.size()
	return target_mode_name()


func target_mode() -> String:
	return TARGET_MODES[target_mode_index]


func target_mode_name() -> String:
	return String(TARGET_MODE_NAMES[target_mode()])


func tick(delta: float) -> void:
	var transient_visuals_were_active := not arc_visuals.is_empty() or nova_visual > 0.0
	_update_visuals(delta)
	if not active or not is_instance_valid(player):
		return
	if int(weapons["pulse"]["level"]) > 0:
		timers["pulse"] -= delta
		if timers["pulse"] <= 0.0:
			if fire_pulse():
				timers["pulse"] += pulse_interval()
			else:
				timers["pulse"] = 0.0
	if int(weapons["orbit"]["level"]) > 0:
		orbit_check_timer -= delta
		if orbit_check_timer <= 0.0:
			orbit_check_timer += ORBIT_CHECK_INTERVAL
			_update_orbits()
	if int(weapons["arc"]["level"]) > 0:
		timers["arc"] -= delta
		if timers["arc"] <= 0.0:
			timers["arc"] += float(weapons["arc"]["interval"])
			fire_arc()
	if int(weapons["nova"]["level"]) > 0:
		timers["nova"] -= delta
		if timers["nova"] <= 0.0:
			timers["nova"] += float(weapons["nova"]["interval"])
			fire_nova()
	visual_update_timer -= delta
	if visual_update_timer <= 0.0 and (_has_dynamic_visuals() or transient_visuals_were_active):
		visual_update_timer += VISUAL_UPDATE_INTERVAL
		queue_redraw()


func fire_pulse() -> bool:
	var spec: Dictionary = weapons["pulse"]
	var target := select_target(player.global_position, pulse_range(), [])
	if target == null:
		return false
	var fire_direction := _direction_to(target)
	var count := int(spec["count"])
	var projectile_speed := float(spec["projectile_speed"]) * (1.0 + profile.skill_effect("projectile_speed"))
	var projectile_radius := 4.0 * (1.0 + profile.skill_effect("projectile_size"))
	var splash_damage := profile.skill_effect("splash_damage")
	var splash_radius := 72.0 * (1.0 + profile.skill_effect("splash_radius"))
	for i in count:
		var offset := (float(i) - float(count - 1) * 0.5) * float(spec.get("spread", 0.13))
		projectile_requested.emit(player.global_position + fire_direction * 24.0, fire_direction.rotated(offset), _scaled_damage("pulse", float(spec["damage"])), projectile_speed, true, "pulse", int(spec["pierce"]), projectile_radius, profile.skill_effect("distant_damage"), pulse_knockback(), pulse_range(), splash_damage, splash_radius)
	tone_requested.emit(520.0, 0.025, 0.06, 900.0)
	return true


func fire_arc() -> void:
	var spec: Dictionary = weapons["arc"]
	var current := player.global_position
	var hit: Array[int] = []
	var points: Array[Vector2] = [current]
	for chain in int(spec["chains"]):
		var target := select_target(current, float(spec["range"]), hit)
		if target == null:
			break
		hit.append(target.get_instance_id())
		current = target.global_position
		points.append(current)
		var dealt := target.take_damage(_scaled_damage("arc", float(spec["damage"]), target.global_position) * pow(0.83, chain), "arc")
		target.apply_knockback(player.global_position, profile.skill_effect("knockback"))
		damage_dealt.emit("arc", dealt, current, target.get_instance_id())
	if points.size() > 1:
		arc_visuals.append({"points": points, "life": 0.16})
		tone_requested.emit(180.0, 0.09, 0.12, 1500.0)


func fire_nova() -> void:
	if not is_instance_valid(player):
		return
	var spec: Dictionary = weapons["nova"]
	var radius := float(spec["radius"])
	for enemy: NeonEnemy in enemies:
		if not is_instance_valid(enemy) or not enemy.active:
			continue
		var hit_radius := radius + enemy.radius
		if enemy.global_position.distance_squared_to(player.global_position) <= hit_radius * hit_radius:
			var dealt: float = enemy.take_damage(_scaled_damage("nova", float(spec["damage"]), enemy.global_position), "nova")
			enemy.apply_knockback(player.global_position, profile.skill_effect("knockback"))
			damage_dealt.emit("nova", dealt, enemy.global_position, enemy.get_instance_id())
	for bullet: Node in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(bullet) and bullet.global_position.distance_squared_to(player.global_position) <= radius * radius:
			bullet.queue_free()
	nova_visual = 0.42
	queue_redraw()
	shake_requested.emit(5.0)
	burst_requested.emit(player.global_position, GamePalette.GREEN, radius * 0.7, 18)
	tone_requested.emit(90.0, 0.22, 0.25, 600.0)


func _update_orbits() -> void:
	var spec: Dictionary = weapons["orbit"]
	var count := int(spec["count"])
	for i in count:
		var angle := session.elapsed * float(spec["speed"]) + TAU * i / count
		var blade_position := player.global_position + Vector2.from_angle(angle) * float(spec["radius"])
		for enemy: NeonEnemy in enemies:
			if is_instance_valid(enemy) and enemy.active:
				var hit_radius := enemy.radius + 12.0
				if enemy.global_position.distance_squared_to(blade_position) >= hit_radius * hit_radius:
					continue
				var key := enemy.get_instance_id()
				if session.elapsed >= float(orbit_hit_time.get(key, 0.0)):
					orbit_hit_time[key] = session.elapsed + 0.34
					var dealt: float = enemy.take_damage(_scaled_damage("orbit", float(spec["damage"]), enemy.global_position), "orbit")
					enemy.apply_knockback(player.global_position, profile.skill_effect("knockback"))
					damage_dealt.emit("orbit", dealt, blade_position, enemy.get_instance_id())


func _scaled_damage(weapon: String, base: float, target_position := Vector2.INF) -> float:
	var multiplier := player.damage_multiplier * (1.0 + profile.mastery_bonus(weapon))
	multiplier *= 1.0 + profile.skill_effect(weapon + "_damage")
	if player.stationary_time >= 2.0:
		multiplier *= 1.0 + profile.skill_effect("stationary_damage")
	if _nearby_enemy_count(player.global_position, 220.0) >= 3:
		multiplier *= 1.0 + profile.skill_effect("surrounded_damage")
	if target_position != Vector2.INF and player.global_position.distance_squared_to(target_position) >= 280.0 * 280.0:
		multiplier *= 1.0 + profile.skill_effect("distant_damage")
	if weapon == "pulse":
		var evolution := String(weapons["pulse"].get("evolution", ""))
		if evolution == "bastion":
			multiplier *= 1.0 + anchor_charge_ratio() * float(weapons["pulse"].get("anchor_damage", 0.0))
		elif evolution == "scatter":
			multiplier *= 1.15 if player.velocity.length() >= 40.0 else 0.72
	return base * multiplier


func pulse_interval() -> float:
	var interval := float(weapons["pulse"]["interval"])
	if String(weapons["pulse"].get("evolution", "")) == "scatter":
		var moving_multiplier := float(weapons["pulse"].get("moving_interval_multiplier", 0.72))
		interval *= moving_multiplier if player.velocity.length() >= 40.0 else 1.28
	return interval


func pulse_range() -> float:
	var result := float(weapons["pulse"]["range"])
	if String(weapons["pulse"].get("evolution", "")) == "bastion":
		result += anchor_charge_ratio() * float(weapons["pulse"].get("anchor_range", 0.0))
	return result


func pulse_knockback() -> float:
	var result := profile.skill_effect("knockback")
	if String(weapons["pulse"].get("evolution", "")) == "bastion":
		result += anchor_charge_ratio() * float(weapons["pulse"].get("anchor_knockback", 0.0))
	return result


func anchor_charge_ratio() -> float:
	if String(weapons["pulse"].get("evolution", "")) != "bastion":
		return 0.0
	return clampf(player.stationary_time / float(weapons["pulse"].get("anchor_charge_time", 2.6)), 0.0, 1.0)


func select_target(from: Vector2, max_distance: float, excluded: Array[int]) -> NeonEnemy:
	var best: NeonEnemy = null
	var best_distance_squared := max_distance * max_distance
	var best_priority := 2
	var best_health := -INF
	for enemy: NeonEnemy in enemies:
		if not is_instance_valid(enemy) or not enemy.active or excluded.has(enemy.get_instance_id()):
			continue
		var distance_squared := from.distance_squared_to(enemy.global_position)
		if distance_squared > max_distance * max_distance:
			continue
		match target_mode():
			"ranged":
				var priority := 0 if enemy.kind in ["gunner", "tank", "boss"] else 1
				if priority < best_priority or (priority == best_priority and distance_squared < best_distance_squared):
					best_priority = priority
					best_distance_squared = distance_squared
					best = enemy
			"high_health":
				if enemy.health > best_health or (is_equal_approx(enemy.health, best_health) and distance_squared < best_distance_squared):
					best_health = enemy.health
					best_distance_squared = distance_squared
					best = enemy
			_:
				if distance_squared < best_distance_squared:
					best_distance_squared = distance_squared
					best = enemy
	return best


func _nearby_enemy_count(from: Vector2, radius: float) -> int:
	var count := 0
	var radius_squared := radius * radius
	for enemy: NeonEnemy in enemies:
		if is_instance_valid(enemy) and enemy.active and from.distance_squared_to(enemy.global_position) <= radius_squared:
			count += 1
	return count


func _direction_to(target: NeonEnemy) -> Vector2:
	var offset := target.global_position - player.global_position
	return player.facing_direction if offset.length_squared() <= 0.001 else offset.normalized()


func _update_visuals(delta: float) -> void:
	nova_visual = maxf(0.0, nova_visual - delta)
	for visual: Dictionary in arc_visuals:
		visual["life"] = float(visual["life"]) - delta
	for i in range(arc_visuals.size() - 1, -1, -1):
		if float(arc_visuals[i]["life"]) <= 0.0:
			arc_visuals.remove_at(i)


func _has_dynamic_visuals() -> bool:
	return int(weapons["orbit"]["level"]) > 0 or not arc_visuals.is_empty() or nova_visual > 0.0 or not String(weapons["pulse"].get("evolution", "")).is_empty()


func _draw() -> void:
	if not active or not is_instance_valid(player):
		return
	var orbit: Dictionary = weapons["orbit"]
	if int(orbit["level"]) > 0:
		var count := int(orbit["count"])
		draw_arc(player.global_position, float(orbit["radius"]), 0, TAU, 48, Color(GamePalette.GREEN, 0.08), 1.0)
		for i in count:
			var angle := session.elapsed * float(orbit["speed"]) + TAU * i / count
			var point := player.global_position + Vector2.from_angle(angle) * float(orbit["radius"])
			draw_circle(point, 15.0, Color(GamePalette.GREEN, 0.08))
			var blade := PackedVector2Array([point + Vector2.from_angle(angle) * 13.0, point + Vector2.from_angle(angle + 2.2) * 8.0, point + Vector2.from_angle(angle - 2.2) * 8.0, point + Vector2.from_angle(angle) * 13.0])
			draw_polyline(blade, GamePalette.GREEN, 2.2, true)
	for visual: Dictionary in arc_visuals:
		var points: Array = visual["points"]
		for i in points.size() - 1:
			var midpoint: Vector2 = (points[i] + points[i + 1]) * 0.5 + Vector2(randf_range(-9, 9), randf_range(-9, 9))
			draw_polyline(PackedVector2Array([points[i], midpoint, points[i + 1]]), Color(GamePalette.GREEN, float(visual["life"]) / 0.16), 3.0, true)
	if nova_visual > 0.0:
		var progress := 1.0 - nova_visual / 0.42
		draw_arc(player.global_position, float(weapons["nova"]["radius"]) * progress, 0, TAU, 64, Color(GamePalette.GREEN, nova_visual / 0.42), 5.0)
	var pulse_evolution := String(weapons["pulse"].get("evolution", ""))
	if pulse_evolution == "bastion":
		var charge := anchor_charge_ratio()
		draw_arc(player.global_position, 34.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 36, Color(GamePalette.CYAN, 0.45 + charge * 0.5), 3.0, true)
		if charge >= 1.0:
			draw_arc(player.global_position, pulse_range(), 0.0, TAU, 64, Color(GamePalette.CYAN, 0.07), 2.0, true)
	elif pulse_evolution == "scatter":
		var motion_color := GamePalette.GREEN if player.velocity.length() >= 40.0 else Color(GamePalette.YELLOW, 0.55)
		for offset in [-0.30, 0.0, 0.30]:
			draw_line(player.global_position + Vector2.from_angle(player.facing_direction.angle() + offset) * 28.0, player.global_position + Vector2.from_angle(player.facing_direction.angle() + offset) * 48.0, motion_color, 2.0, true)
