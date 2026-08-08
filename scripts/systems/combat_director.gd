class_name CombatDirector
extends Node

signal damage_dealt(weapon: String, amount: float, world_position: Vector2)
signal enemy_defeated(kind: String)
signal xp_collected(amount: int)
signal flux_collected(amount: int)
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
	enemy.global_position = _random_edge_position()
	enemy.add_to_group("enemies")
	enemy.add_to_group("run_entities")
	enemy.destroyed.connect(_on_enemy_destroyed)
	enemy.fired.connect(_on_enemy_fired)
	get_parent().add_child(enemy)


func spawn_projectile(origin: Vector2, direction: Vector2, damage: float, speed: float, friendly: bool, weapon: String, pierce: int = 0, radius: float = 4.0) -> void:
	var projectile: NeonProjectile = ProjectileScene.new()
	projectile.friendly = friendly
	projectile.weapon = weapon
	projectile.damage = damage
	projectile.velocity = direction.normalized() * speed
	projectile.pierce = pierce
	projectile.radius = radius
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


func _on_enemy_destroyed(_enemy: NeonEnemy, kind: String, flux: int, xp: int, world_position: Vector2) -> void:
	enemy_defeated.emit(kind)
	_spawn_pickup(world_position, "xp", xp)
	var fortune := 1.0 + profile.bonus("fortune")
	if rng.randf() < minf(0.88, 0.35 * fortune) or kind == "boss":
		var offset := Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-8.0, 8.0))
		_spawn_pickup(world_position + offset, "flux", maxi(1, int(round(flux * session.combo))))
	if rng.randf() < 0.018 * fortune:
		_spawn_pickup(world_position, "repair", 12)
	spawn_burst(world_position, GamePalette.MAGENTA if kind != "boss" else GamePalette.ORANGE, 70.0 if kind == "boss" else 26.0, 14 if kind == "boss" else 7)
	if kind == "boss":
		banner_requested.emit("OVERSEER ERASED // +%d FLUX CACHE" % flux, GamePalette.YELLOW)
		shake_requested.emit(11.0)


func _spawn_pickup(world_position: Vector2, kind: String, amount: int) -> void:
	var pickup: NeonPickup = PickupScene.new()
	pickup.kind = kind
	pickup.amount = amount
	pickup.target = player
	pickup.global_position = world_position
	pickup.velocity = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(25.0, 90.0)
	pickup.add_to_group("run_entities")
	pickup.collected.connect(_on_pickup_collected)
	get_parent().add_child(pickup)


func _on_pickup_collected(kind: String, amount: int, _world_position: Vector2) -> void:
	match kind:
		"xp": xp_collected.emit(amount)
		"flux":
			flux_collected.emit(amount)
			tone_requested.emit(760.0, 0.035, 0.08, 260.0)
		"repair":
			repair_collected.emit(float(amount))
			banner_requested.emit("HULL RESTORED", GamePalette.GREEN)


func _random_edge_position() -> Vector2:
	match rng.randi_range(0, 3):
		0: return Vector2(rng.randf_range(arena.position.x, arena.end.x), arena.position.y + 8.0)
		1: return Vector2(rng.randf_range(arena.position.x, arena.end.x), arena.end.y - 8.0)
		2: return Vector2(arena.position.x + 8.0, rng.randf_range(arena.position.y, arena.end.y))
	return Vector2(arena.end.x - 8.0, rng.randf_range(arena.position.y, arena.end.y))
