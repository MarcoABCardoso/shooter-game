class_name NeonEnemy
extends CharacterBody2D

signal destroyed(enemy: NeonEnemy, kind: String, flux: int, resonance: int, world_position: Vector2)
signal fired(world_position: Vector2, direction: Vector2, damage: float, speed: float, spread_count: int)

const MAGENTA := Color("ff3bd4")
const ORANGE := Color("ff8a3d")
const RED := Color("ff365e")

var kind := "drone"
var target: NeonPlayer
var max_health := 20.0
var health := 20.0
var speed := 100.0
var contact_damage := 10.0
var flux_reward := 1
var resonance_reward := 5
var shoot_timer := 1.0
var shoot_interval := 2.0
var radius := 13.0
var active := true
var elite := false
var phase := 0.0
var last_weapon := "pulse"
var facing_direction := Vector2.RIGHT
var facing_angle := 0.0


func configure(enemy_kind: String, difficulty: float, is_elite: bool = false) -> void:
	kind = enemy_kind
	elite = is_elite
	var definition := EnemyCatalog.stats(kind)
	max_health = float(definition["health"])
	speed = float(definition["speed"])
	contact_damage = float(definition["contact_damage"])
	flux_reward = int(definition["flux"])
	resonance_reward = int(definition["resonance"])
	radius = float(definition["radius"])
	shoot_interval = float(definition["shoot_interval"])
	max_health *= difficulty
	health = max_health
	contact_damage *= 0.8 + difficulty * 0.2
	if elite:
		max_health *= 3.2
		health = max_health
		speed *= 1.15
		flux_reward *= 5
		resonance_reward *= 3
		radius *= 1.25


func _ready() -> void:
	collision_layer = 2
	# Enemies remain detectable by weapons, but contact damage is handled by the
	# combat director instead of solid-body collision response.
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	phase = randf() * TAU
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	phase += delta
	var offset := target.global_position - global_position
	var direction := facing_direction
	if offset.length_squared() > 0.001:
		direction = offset.normalized()
		facing_direction = direction
		facing_angle = direction.angle()
	match kind:
		"gunner":
			var desired := direction if offset.length() > 270.0 else -direction
			velocity = (desired + direction.rotated(PI * 0.5) * sin(phase * 1.7) * 0.45).normalized() * speed
		"boss":
			velocity = (direction + direction.rotated(PI * 0.5) * sin(phase * 0.8) * 0.65).normalized() * speed
		_:
			velocity = direction * speed
	move_and_slide()
	shoot_timer -= delta
	if shoot_timer <= 0.0 and kind in ["gunner", "boss"]:
		shoot_timer += shoot_interval
		var count := 7 if kind == "boss" else 1
		fired.emit(global_position, direction, 8.0 if kind == "gunner" else 11.0, 260.0 if kind == "gunner" else 215.0, count)
	queue_redraw()


func take_damage(amount: float, source_weapon: String) -> float:
	if not active:
		return 0.0
	var dealt := minf(health, amount)
	health -= amount
	last_weapon = source_weapon
	if health <= 0.0:
		active = false
		collision_layer = 0
		destroyed.emit(self, kind, flux_reward, resonance_reward, global_position)
		queue_free()
	else:
		queue_redraw()
	return dealt


func _draw() -> void:
	var c := ORANGE if elite else MAGENTA
	if kind == "boss": c = RED
	draw_set_transform(Vector2.ZERO, facing_angle)
	draw_circle(Vector2.ZERO, radius + 7.0, Color(c, 0.055))
	match kind:
		"drone":
			_shape(PackedVector2Array([Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0), Vector2(0, -radius)]), c)
		"striker":
			_shape(PackedVector2Array([Vector2(radius * 1.3, 0), Vector2(-radius, radius * 0.8), Vector2(-radius * 0.3, 0), Vector2(-radius, -radius * 0.8)]), c)
		"gunner":
			_shape(_regular_polygon(6, radius, phase * 0.15), c)
		"tank":
			_shape(_regular_polygon(4, radius, PI * 0.25), c)
			draw_rect(Rect2(-radius * 0.42, -radius * 0.42, radius * 0.84, radius * 0.84), Color(c, 0.22), true)
		"boss":
			_shape(_regular_polygon(8, radius, phase * 0.08), c)
			draw_arc(Vector2.ZERO, radius * 0.62, -phase, TAU - phase, 32, Color(c, 0.9), 3.0)
			draw_circle(Vector2.ZERO, 8.0 + sin(phase * 4.0) * 2.0, Color.WHITE)
	draw_circle(Vector2(radius * 0.72, 0.0), maxf(2.0, radius * 0.16), Color.WHITE)
	if elite:
		draw_arc(Vector2.ZERO, radius + 5.0, phase, phase + PI * 1.5, 20, Color(ORANGE, 0.8), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0)
	if health < max_health:
		draw_line(Vector2(-radius, -radius - 9), Vector2(radius, -radius - 9), Color(0.1, 0.1, 0.18), 3.0)
		draw_line(Vector2(-radius, -radius - 9), Vector2(-radius + radius * 2.0 * health / max_health, -radius - 9), c, 3.0)


func _shape(points: PackedVector2Array, c: Color) -> void:
	draw_colored_polygon(points, Color(c.darkened(0.78), 0.92))
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, c, 2.2, true)


func _regular_polygon(sides: int, size: float, angle_offset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		points.append(Vector2.from_angle(angle_offset + TAU * i / sides) * size)
	return points
