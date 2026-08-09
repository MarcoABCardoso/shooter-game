class_name CombatDirector
extends Node

signal damage_dealt(weapon: String, amount: float, world_position: Vector2, target_id: int)
signal enemy_defeated(kind: String)
signal boss_defeated
signal resonance_gained(amount: int)
signal flux_gained(amount: int)
signal repair_collected(amount: float)
signal banner_requested(text: String, color: Color)
signal shake_requested(amount: float)
signal tone_requested(frequency: float, duration: float, volume: float, slide: float)

const EnemyScene := preload("res://scripts/entities/enemy.gd")
const ProjectileScene := preload("res://scripts/entities/projectile.gd")
const PickupScene := preload("res://scripts/entities/pickup.gd")
const BurstScene := preload("res://scripts/entities/burst.gd")

var player: NeonPlayer
var profile: SaveProfile
var session: RunSession
var arena := GameBalance.ARENA
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func configure(run_player: NeonPlayer, save_profile: SaveProfile, run_session: RunSession) -> void:
	player = run_player
	profile = save_profile
	session = run_session


func tick_contacts() -> void:
	if not is_instance_valid(player):
		return
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is NeonEnemy and is_instance_valid(node) and node.active and node.global_position.distance_to(player.global_position) < node.radius + 14.0:
			if player.take_damage(node.contact_damage):
				shake_requested.emit(7.0)
				spawn_burst(player.global_position, GamePalette.MAGENTA, 35.0, 10)
				tone_requested.emit(90.0, 0.12, 0.22, -200.0)


func spawn_enemy(kind: String, elite: bool) -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= GameBalance.MAX_ENEMIES or not is_instance_valid(player):
		return
	var enemy: NeonEnemy = EnemyScene.new()
	enemy.configure(kind, GameBalance.enemy_difficulty(session.elapsed), elite)
	enemy.target = player
	enemy.global_position = Vector2(arena.get_center().x, arena.position.y + 112.0) if kind == "boss" else _random_edge_position()
	enemy.add_to_group("enemies")
	enemy.add_to_group("run_entities")
	enemy.destroyed.connect(_on_enemy_destroyed)
	enemy.fired.connect(_on_enemy_fired)
	enemy.attack_requested.connect(_on_enemy_attack_requested)
	enemy.module_broken.connect(_on_boss_module_broken)
	get_parent().add_child(enemy)


func begin_boss_arrival() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is NeonEnemy and is_instance_valid(node):
			node.begin_disperse()
	for bullet: Node in get_tree().get_nodes_in_group("enemy_projectiles"):
		if is_instance_valid(bullet):
			bullet.queue_free()
	spawn_burst(arena.get_center(), GamePalette.MAGENTA, 150.0, 24)


func parry_projectiles(origin: Vector2, facing: Vector2) -> void:
	var reflected := 0
	for node: Node in get_tree().get_nodes_in_group("enemy_projectiles"):
		if not (node is NeonProjectile) or not is_instance_valid(node):
			continue
		var offset: Vector2 = node.global_position - origin
		if offset.length() > 105.0 or offset.normalized().dot(facing) < 0.18:
			continue
		var target_enemy := _nearest_enemy_to(node.global_position)
		var return_direction := facing
		if target_enemy != null:
			return_direction = (target_enemy.global_position - node.global_position).normalized()
		node.reflect(return_direction)
		reflected += 1
	if reflected > 0:
		banner_requested.emit("VECTOR PARRY // %d RETURNED" % reflected, GamePalette.CYAN)
		shake_requested.emit(4.0)
		tone_requested.emit(760.0, 0.1, 0.18, 900.0)
	else:
		tone_requested.emit(240.0, 0.05, 0.08, -120.0)


func spawn_projectile(origin: Vector2, direction: Vector2, damage: float, speed: float, friendly: bool, weapon: String, pierce: int = 0, radius: float = 4.0, distant_bonus: float = 0.0, knockback: float = 0.0) -> void:
	var projectile: NeonProjectile = ProjectileScene.new()
	projectile.friendly = friendly
	projectile.weapon = weapon
	projectile.damage = damage
	projectile.velocity = direction.normalized() * speed
	projectile.pierce = pierce
	projectile.radius = radius
	projectile.distant_damage_bonus = distant_bonus
	projectile.knockback = knockback
	projectile.color = GamePalette.CYAN if friendly else GamePalette.MAGENTA
	projectile.global_position = origin
	projectile.arena = arena.grow(100.0)
	projectile.add_to_group("run_entities")
	if not friendly:
		projectile.add_to_group("enemy_projectiles")
	projectile.damage_dealt.connect(damage_dealt.emit)
	get_parent().add_child(projectile)


func spawn_burst(world_position: Vector2, color: Color, size: float, spokes: int) -> void:
	var burst: NeonBurst = BurstScene.new()
	burst.global_position = world_position
	burst.color = color
	burst.size = size
	burst.spokes = spokes
	burst.add_to_group("run_entities")
	get_parent().add_child(burst)


func _on_enemy_fired(origin: Vector2, direction: Vector2, damage: float, speed: float, spread_count: int) -> void:
	if spread_count == 1:
		spawn_projectile(origin, direction, damage, speed, false, "enemy", 0, 5.0)
	else:
		for i in spread_count:
			var angle := TAU * i / spread_count + session.elapsed * 0.45
			spawn_projectile(origin, Vector2.from_angle(angle), damage, speed, false, "enemy", 0, 5.5)
	tone_requested.emit(120.0, 0.035, 0.035, 0.0)


func _on_enemy_attack_requested(pattern: String, origin: Vector2, direction: Vector2, damage: float, speed: float) -> void:
	if pattern == "target_lock":
		for i in 5:
			var offset := (float(i) - 2.0) * 0.075
			spawn_projectile(origin, direction.rotated(offset), damage, speed, false, "enemy", 0, 6.0)
	elif pattern == "firewall":
		# The gap faces the player when the wall launches, so reading the boss is
		# safer than continuing a habitual orbit around the arena.
		for i in 24:
			var bullet_direction := Vector2.from_angle(TAU * i / 24.0)
			if absf(wrapf(bullet_direction.angle() - direction.angle(), -PI, PI)) < 0.42:
				continue
			spawn_projectile(origin, bullet_direction, damage, speed, false, "enemy", 0, 5.5)
	shake_requested.emit(5.0)
	tone_requested.emit(105.0, 0.16, 0.16, 420.0)


func _on_boss_module_broken(world_position: Vector2, remaining: int) -> void:
	spawn_burst(world_position, GamePalette.ORANGE, 105.0, 18)
	banner_requested.emit("ARRAY MODULE SEVERED // %d REMAIN" % remaining, GamePalette.ORANGE)
	shake_requested.emit(9.0)


func _on_enemy_destroyed(_enemy: NeonEnemy, kind: String, flux: int, resonance: int, world_position: Vector2) -> void:
	enemy_defeated.emit(kind)
	resonance_gained.emit(resonance)
	var fortune_bonus := profile.bonus("fortune")
	var awarded_flux := maxi(1, int(round(flux * session.combo * (1.0 + fortune_bonus))))
	flux_gained.emit(awarded_flux)
	if rng.randf() < 0.018 * (1.0 + fortune_bonus):
		_spawn_repair(world_position, 12)
	spawn_burst(world_position, GamePalette.MAGENTA if kind != "boss" else GamePalette.ORANGE, 70.0 if kind == "boss" else 26.0, 14 if kind == "boss" else 7)
	if kind == "boss":
		boss_defeated.emit()
		banner_requested.emit("OVERSEER ERASED // +%d FLUX" % awarded_flux, GamePalette.YELLOW)
		shake_requested.emit(11.0)


func _spawn_repair(world_position: Vector2, amount: int) -> void:
	var pickup: NeonPickup = PickupScene.new()
	pickup.amount = amount
	pickup.target = player
	pickup.global_position = world_position
	pickup.velocity = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(25.0, 90.0)
	pickup.add_to_group("run_entities")
	pickup.collected.connect(_on_repair_collected)
	# Enemy destruction can originate inside an Area2D body_entered callback.
	# Wait until the physics server finishes flushing that query before the new
	# Area2D enters the tree and enables its collision monitoring.
	call_deferred("_attach_pickup", pickup)


func _attach_pickup(pickup: NeonPickup) -> void:
	if not is_instance_valid(pickup):
		return
	if not is_instance_valid(player) or not player.is_inside_tree() or not player.active:
		pickup.free()
		return
	get_parent().add_child(pickup)


func _on_repair_collected(amount: int, _world_position: Vector2) -> void:
	repair_collected.emit(float(amount))
	banner_requested.emit("HULL RESTORED", GamePalette.GREEN)


func _random_edge_position() -> Vector2:
	match rng.randi_range(0, 3):
		0: return Vector2(rng.randf_range(arena.position.x, arena.end.x), arena.position.y + 8.0)
		1: return Vector2(rng.randf_range(arena.position.x, arena.end.x), arena.end.y - 8.0)
		2: return Vector2(arena.position.x + 8.0, rng.randf_range(arena.position.y, arena.end.y))
	return Vector2(arena.end.x - 8.0, rng.randf_range(arena.position.y, arena.end.y))


func _nearest_enemy_to(origin: Vector2) -> NeonEnemy:
	var nearest: NeonEnemy = null
	var distance := INF
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node is NeonEnemy and is_instance_valid(node) and node.active:
			var candidate := origin.distance_to(node.global_position)
			if candidate < distance:
				distance = candidate
				nearest = node
	return nearest
