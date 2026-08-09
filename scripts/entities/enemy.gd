class_name NeonEnemy
extends CharacterBody2D

signal destroyed(enemy: NeonEnemy, kind: String, flux: int, resonance: int, world_position: Vector2)
signal fired(world_position: Vector2, direction: Vector2, damage: float, speed: float, spread_count: int)
signal attack_requested(pattern: String, world_position: Vector2, direction: Vector2, damage: float, speed: float)
signal module_broken(world_position: Vector2, remaining: int)

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
var dispersing := false
var disperse_direction := Vector2.ZERO
var boss_pattern_index := 0
var boss_state := "waiting"
var boss_timer := 1.2
var boss_locked_direction := Vector2.RIGHT
var boss_locked_target := Vector2.ZERO
var boss_direction_locked := false
var boss_exposed := false
var boss_modules := 3
var knockback_velocity := Vector2.ZERO


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
	if dispersing:
		velocity = velocity.move_toward(disperse_direction * 430.0, delta * 520.0)
		move_and_slide()
		modulate.a = maxf(0.0, modulate.a - delta * 0.7)
		if not GameBalance.ARENA.grow(90.0).has_point(global_position):
			queue_free()
		queue_redraw()
		return
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
			_update_boss(delta, direction)
		_:
			velocity = direction * speed
	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, delta * 420.0)
	move_and_slide()
	if kind == "boss":
		var boss_bounds := GameBalance.ARENA.grow(-radius)
		global_position.x = clampf(global_position.x, boss_bounds.position.x, boss_bounds.end.x)
		global_position.y = clampf(global_position.y, boss_bounds.position.y, boss_bounds.end.y)
	shoot_timer -= delta
	if shoot_timer <= 0.0 and kind == "gunner":
		shoot_timer += shoot_interval
		fired.emit(global_position, direction, 8.0, 260.0, 1)
	queue_redraw()


func begin_disperse() -> void:
	if kind == "boss":
		return
	dispersing = true
	active = false
	collision_layer = 0
	var from_center := global_position - GameBalance.ARENA.get_center()
	disperse_direction = from_center.normalized() if from_center.length_squared() > 1.0 else Vector2.from_angle(randf() * TAU)
	velocity = disperse_direction * 90.0


func _update_boss(delta: float, direction: Vector2) -> void:
	boss_timer -= delta
	match boss_state:
		"waiting":
			velocity = (direction + direction.rotated(PI * 0.5) * sin(phase * 0.7) * 0.5).normalized() * speed
			if boss_timer <= 0.0:
				_start_boss_pattern()
		"telegraph":
			velocity = velocity.move_toward(Vector2.ZERO, delta * 180.0)
			if not boss_direction_locked:
				boss_locked_direction = direction
				boss_locked_target = target.global_position
				if boss_timer <= 0.46:
					boss_direction_locked = true
			if boss_timer <= 0.0:
				_execute_boss_pattern()
		"charge":
			velocity = boss_locked_direction * 560.0
			if boss_timer <= 0.0:
				_begin_boss_recovery(1.25)
		"recovery":
			velocity = velocity.move_toward(Vector2.ZERO, delta * 420.0)
			if boss_timer <= 0.0:
				boss_exposed = false
				boss_state = "waiting"
				boss_timer = maxf(0.7, 1.3 - (3 - boss_modules) * 0.18)


func _start_boss_pattern() -> void:
	boss_state = "telegraph"
	boss_timer = 1.35
	boss_direction_locked = false
	boss_exposed = false


func _execute_boss_pattern() -> void:
	var pattern := boss_pattern_index % 3
	boss_pattern_index += 1
	if pattern == 0:
		attack_requested.emit("target_lock", global_position, boss_locked_direction, 14.0, 540.0)
		_begin_boss_recovery(1.05)
	elif pattern == 1:
		attack_requested.emit("firewall", global_position, boss_locked_direction, 10.0, 205.0)
		_begin_boss_recovery(1.2)
	else:
		boss_state = "charge"
		boss_timer = 0.62


func _begin_boss_recovery(duration: float) -> void:
	boss_state = "recovery"
	boss_timer = duration
	boss_exposed = true


func take_damage(amount: float, source_weapon: String) -> float:
	if not active:
		return 0.0
	var applied := amount
	if kind == "boss" and not boss_exposed:
		# Wide-area systems still strip armor, but focused fire gets the cleanest
		# payoff during the white-core recovery window.
		applied *= 0.48 if source_weapon in ["orbit", "arc", "nova"] else 0.30
	var dealt := minf(health, applied)
	health -= applied
	last_weapon = source_weapon
	if kind == "boss" and health > 0.0:
		var expected_modules := clampi(int(ceil(health / max_health * 3.0)), 0, 3)
		while boss_modules > expected_modules:
			boss_modules -= 1
			module_broken.emit(global_position, boss_modules)
	if health <= 0.0:
		active = false
		collision_layer = 0
		destroyed.emit(self, kind, flux_reward, resonance_reward, global_position)
		queue_free()
	else:
		queue_redraw()
	return dealt


func apply_knockback(origin: Vector2, amount: float) -> void:
	if not active or amount <= 0.0:
		return
	var direction := global_position - origin
	if direction.length_squared() <= 0.001:
		return
	var resistance := 0.18 if kind == "boss" else 1.0
	knockback_velocity += direction.normalized() * amount * resistance


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
			_draw_boss(c)
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


func _draw_boss(c: Color) -> void:
	var core_radius := 31.0
	_shape(_regular_polygon(6, core_radius, phase * 0.12), c)
	for i in 3:
		var angle := phase * 0.18 + TAU * i / 3.0
		var socket := Vector2.from_angle(angle) * 63.0
		var live := i < boss_modules
		var module_color := c if live else Color(c, 0.18)
		if boss_state == "telegraph" and i == boss_pattern_index % 3:
			module_color = Color.WHITE
		draw_line(Vector2.from_angle(angle) * 25.0, socket, Color(module_color, 0.72), 6.0 if live else 2.0)
		draw_circle(socket, 22.0, Color(module_color, 0.06))
		var points: PackedVector2Array
		if i == 0:
			points = _regular_polygon(3, 20.0, angle)
		elif i == 1:
			points = _regular_polygon(4, 18.0, angle + PI * 0.25)
		else:
			points = _regular_polygon(4, 21.0, angle)
		for p in points.size():
			points[p] += socket
		_shape(points, module_color)
	var core_color := Color.WHITE if boss_exposed else c
	draw_arc(Vector2.ZERO, core_radius * 0.68, -phase, TAU - phase, 32, Color(core_color, 0.95), 3.0)
	draw_circle(Vector2.ZERO, 8.0 + sin(phase * 4.0) * 2.0, core_color)
	if boss_state == "telegraph":
		var local_direction := boss_locked_direction.rotated(-facing_angle)
		var endpoint := (boss_locked_target - global_position).rotated(-facing_angle)
		match boss_pattern_index % 3:
			0:
				draw_dashed_line(Vector2.ZERO, endpoint, Color(Color.WHITE, 0.72), 2.0, 12.0)
				draw_arc(endpoint, 18.0 + boss_timer * 6.0, 0.0, TAU, 24, Color.WHITE, 2.0)
			1:
				var gap_angle := local_direction.angle()
				draw_arc(Vector2.ZERO, 92.0, gap_angle + 0.42, gap_angle + TAU - 0.42, 44, Color(GamePalette.YELLOW, 0.78), 4.0)
				draw_line(local_direction * 78.0, local_direction * 126.0, Color(GamePalette.GREEN, 0.82), 8.0)
			2:
				var side := local_direction.rotated(PI * 0.5) * 25.0
				draw_line(side, side + local_direction * 310.0, Color(RED, 0.5), 4.0)
				draw_line(-side, -side + local_direction * 310.0, Color(RED, 0.5), 4.0)
				draw_dashed_line(Vector2.ZERO, local_direction * 310.0, Color.WHITE, 2.0, 14.0)
	if boss_state == "charge":
		draw_line(Vector2.ZERO, boss_locked_direction.rotated(-facing_angle) * 180.0, Color(RED, 0.5), 8.0)
