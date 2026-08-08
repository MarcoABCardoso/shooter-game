class_name WeaponSystem
extends Node2D

signal projectile_requested(origin: Vector2, direction: Vector2, damage: float, speed: float, friendly: bool, weapon: String, pierce: int, radius: float)
signal damage_dealt(weapon: String, amount: float, world_position: Vector2, target_id: int)
signal burst_requested(world_position: Vector2, color: Color, size: float, spokes: int)
signal shake_requested(amount: float)
signal tone_requested(frequency: float, duration: float, volume: float, slide: float)

var player: NeonPlayer
var profile: SaveProfile
var session: RunSession
var weapons: Dictionary = WeaponCatalog.fresh_loadout()
var timers := {"pulse": 0.0, "arc": 0.0, "nova": 0.0}
var orbit_hit_time := {}
var arc_visuals: Array[Dictionary] = []
var nova_visual := 0.0
var active := false


func configure(run_player: NeonPlayer, save_profile: SaveProfile, run_session: RunSession) -> void:
	player = run_player
	profile = save_profile
	session = run_session
	weapons = WeaponCatalog.fresh_loadout()
	timers = {"pulse": 0.1, "arc": 0.0, "nova": 0.0}
	orbit_hit_time.clear()
	arc_visuals.clear()
	nova_visual = 0.0
	active = true


func tick(delta: float) -> void:
	_update_visuals(delta)
	if not active or not is_instance_valid(player):
		return
	timers["pulse"] -= delta
	if timers["pulse"] <= 0.0:
		timers["pulse"] += float(weapons["pulse"]["interval"])
		fire_pulse()
	if int(weapons["orbit"]["level"]) > 0:
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
	queue_redraw()


func on_evolution_applied() -> void:
	if int(weapons["arc"]["level"]) > 0 and float(timers["arc"]) <= 0.0:
		timers["arc"] = 0.2
	if int(weapons["nova"]["level"]) > 0 and float(timers["nova"]) <= 0.0:
		timers["nova"] = 1.0


func fire_pulse() -> void:
	var spec: Dictionary = weapons["pulse"]
	var count := int(spec["count"])
	for i in count:
		var offset := (float(i) - float(count - 1) * 0.5) * 0.13
		projectile_requested.emit(player.global_position + player.aim_direction * 24.0, player.aim_direction.rotated(offset), _scaled_damage("pulse", float(spec["damage"])), float(spec["projectile_speed"]), true, "pulse", int(spec["pierce"]), 4.0)
	tone_requested.emit(520.0, 0.025, 0.06, 900.0)


func fire_arc() -> void:
	var spec: Dictionary = weapons["arc"]
	var current := player.global_position
	var hit: Array[int] = []
	var points: Array[Vector2] = [current]
	for chain in int(spec["chains"]):
		var target := _nearest_enemy(current, float(spec["range"]), hit)
		if target == null:
			break
		hit.append(target.get_instance_id())
		current = target.global_position
		points.append(current)
		var dealt := target.take_damage(_scaled_damage("arc", float(spec["damage"])) * pow(0.83, chain), "arc")
		damage_dealt.emit("arc", dealt, current, target.get_instance_id())
	if points.size() > 1:
		arc_visuals.append({"points": points, "life": 0.16})
		tone_requested.emit(180.0, 0.09, 0.12, 1500.0)


func fire_nova() -> void:
	if not is_instance_valid(player):
		return
	var spec: Dictionary = weapons["nova"]
	var radius := float(spec["radius"])
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is NeonEnemy and is_instance_valid(node) and node.global_position.distance_to(player.global_position) <= radius + node.radius:
			var dealt: float = node.take_damage(_scaled_damage("nova", float(spec["damage"])), "nova")
			damage_dealt.emit("nova", dealt, node.global_position, node.get_instance_id())
	for bullet: Node in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(bullet) and bullet.global_position.distance_to(player.global_position) <= radius:
			bullet.queue_free()
	nova_visual = 0.42
	shake_requested.emit(5.0)
	burst_requested.emit(player.global_position, GamePalette.GREEN, radius * 0.7, 18)
	tone_requested.emit(90.0, 0.22, 0.25, 600.0)


func _update_orbits() -> void:
	var spec: Dictionary = weapons["orbit"]
	var count := int(spec["count"])
	for i in count:
		var angle := session.elapsed * float(spec["speed"]) + TAU * i / count
		var blade_position := player.global_position + Vector2.from_angle(angle) * float(spec["radius"])
		for node: Node in get_tree().get_nodes_in_group("enemies"):
			if node is NeonEnemy and is_instance_valid(node) and node.active and node.global_position.distance_to(blade_position) < node.radius + 12.0:
				var key := node.get_instance_id()
				if session.elapsed >= float(orbit_hit_time.get(key, 0.0)):
					orbit_hit_time[key] = session.elapsed + 0.34
					var dealt: float = node.take_damage(_scaled_damage("orbit", float(spec["damage"])), "orbit")
					damage_dealt.emit("orbit", dealt, blade_position, node.get_instance_id())


func _scaled_damage(weapon: String, base: float) -> float:
	return base * player.damage_multiplier * (1.0 + profile.mastery_bonus(weapon))


func _nearest_enemy(from: Vector2, max_distance: float, excluded: Array[int]) -> NeonEnemy:
	var best: NeonEnemy = null
	var best_distance := max_distance
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is NeonEnemy and is_instance_valid(node) and node.active and not excluded.has(node.get_instance_id()):
			var distance := from.distance_to(node.global_position)
			if distance < best_distance:
				best_distance = distance
				best = node
	return best


func _update_visuals(delta: float) -> void:
	nova_visual = maxf(0.0, nova_visual - delta)
	for visual: Dictionary in arc_visuals:
		visual["life"] = float(visual["life"]) - delta
	for i in range(arc_visuals.size() - 1, -1, -1):
		if float(arc_visuals[i]["life"]) <= 0.0:
			arc_visuals.remove_at(i)


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
