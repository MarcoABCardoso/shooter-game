class_name NeonPlayer
extends CharacterBody2D

signal died
signal health_changed(current: float, maximum: float)
signal dash_changed(ratio: float)
signal parry_requested(world_position: Vector2, direction: Vector2)

const CYAN := Color("45f3ff")
const WHITE := Color("eaffff")

var arena := Rect2(54.0, 76.0, 1172.0, 590.0)
var active := false
var max_health := 100.0
var health := 100.0
var speed := 300.0
var damage_multiplier := 1.0
var pickup_radius := 110.0
var aim_direction := Vector2.RIGHT
var invulnerable := 0.0
var dash_cooldown := 0.0
var dash_duration := 0.0
var dash_direction := Vector2.ZERO
var hit_flash := 0.0
var ability_mode := "dash"
var parry_flash := 0.0


func _ready() -> void:
	collision_layer = 1
	# Contact damage is resolved by CombatDirector. Only hostile projectiles
	# participate in physical queries so enemies can never pin the ship.
	collision_mask = 8
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	add_child(shape)


func configure(meta_bonuses: Dictionary) -> void:
	max_health = 100.0 + float(meta_bonuses.get("hull", 0.0))
	health = max_health
	speed = 300.0 * (1.0 + float(meta_bonuses.get("thrusters", 0.0)))
	damage_multiplier = 1.0 + float(meta_bonuses.get("damage", 0.0))
	pickup_radius = 110.0 + float(meta_bonuses.get("magnet", 0.0))
	ability_mode = String(meta_bonuses.get("ability", "dash"))
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	dash_duration = maxf(0.0, dash_duration - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	parry_flash = maxf(0.0, parry_flash - delta)
	dash_changed.emit(1.0 - dash_cooldown / 1.25)
	if not active:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var mouse_delta := get_global_mouse_position() - global_position
	if mouse_delta.length_squared() > 16.0:
		aim_direction = mouse_delta.normalized()
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		if ability_mode == "vector_parry":
			dash_cooldown = 1.25
			parry_flash = 0.24
			invulnerable = maxf(invulnerable, 0.16)
			parry_requested.emit(global_position, aim_direction)
		elif input_vector != Vector2.ZERO:
			dash_direction = input_vector.normalized()
			dash_duration = 0.18
			dash_cooldown = 1.25
			invulnerable = 0.30
	if dash_duration > 0.0:
		velocity = dash_direction * speed * 3.2
	else:
		velocity = input_vector.normalized() * speed if input_vector.length() > 0.1 else Vector2.ZERO
	move_and_slide()
	global_position.x = clampf(global_position.x, arena.position.x, arena.end.x)
	global_position.y = clampf(global_position.y, arena.position.y, arena.end.y)
	queue_redraw()


func take_damage(amount: float) -> bool:
	if not active or invulnerable > 0.0:
		return false
	health = maxf(0.0, health - amount)
	invulnerable = 0.42
	hit_flash = 0.18
	health_changed.emit(health, max_health)
	if health <= 0.0:
		active = false
		died.emit()
	return true


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)


func _draw() -> void:
	var a := aim_direction.angle()
	var flicker := 0.35 + sin(Time.get_ticks_msec() * 0.018) * 0.1
	draw_set_transform(Vector2.ZERO, a)
	draw_circle(Vector2.ZERO, 24.0, Color(CYAN, 0.05))
	draw_circle(Vector2(-15.0, 0.0), 8.0 + dash_duration * 30.0, Color(CYAN, flicker))
	draw_polygon(PackedVector2Array([Vector2(21, 0), Vector2(-12, -14), Vector2(-5, 0), Vector2(-12, 14)]), PackedColorArray([Color("082a45")]))
	draw_polyline(PackedVector2Array([Vector2(21, 0), Vector2(-12, -14), Vector2(-5, 0), Vector2(-12, 14), Vector2(21, 0)]), WHITE if hit_flash > 0.0 else CYAN, 2.5, true)
	draw_line(Vector2(2, 0), Vector2(28, 0), Color(CYAN, 0.65), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0)
	if invulnerable > 0.0:
		draw_arc(Vector2.ZERO, 26.0, -PI * 0.8, PI * 0.8, 24, Color(CYAN, 0.55), 2.0)
	if parry_flash > 0.0:
		var shield_angle := aim_direction.angle()
		draw_arc(Vector2.ZERO, 52.0 + parry_flash * 45.0, shield_angle - 0.82, shield_angle + 0.82, 24, Color.WHITE, 5.0)
		draw_arc(Vector2.ZERO, 60.0, shield_angle - 0.72, shield_angle + 0.72, 20, Color(CYAN, parry_flash / 0.24), 2.0)
