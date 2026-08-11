class_name NeonPlayer
extends CharacterBody2D

signal died
signal health_changed(current: float, maximum: float)
signal dash_changed(ratio: float)
signal parry_requested(world_position: Vector2)
signal active_skill_used(id: String, mastery_xp: float)

const CYAN := Color("45f3ff")
const WHITE := Color("eaffff")
const VISUAL_UPDATE_INTERVAL := 1.0 / 30.0
const HUD_SIGNAL_INTERVAL := 0.1
const FACING_TURN_SPEED := 8.0

var arena := Rect2(54.0, 76.0, 1172.0, 590.0)
var active := false
var max_health := 100.0
var health := 100.0
var speed := 300.0
var damage_multiplier := 1.0
var pickup_radius := 110.0
var facing_direction := Vector2.RIGHT
var desired_facing_direction := Vector2.RIGHT
var shield_capacity := 0
var shield_charges := 0
var shield_recharge_timer := 0.0
var invulnerable := 0.0
var dash_cooldown := 0.0
var dash_duration := 0.0
var dash_direction := Vector2.ZERO
var hit_flash := 0.0
var ability_mode := "dash"
var parry_flash := 0.0
var ability_cooldown := 1.25
var stationary_time := 0.0
var preserve_stationary_on_dash := false
var stationary_grace := 0.0
var mobile_controls_enabled := false
var mobile_movement := Vector2.ZERO
var mobile_ability_queued := false
var visual_update_timer := 0.0
var hud_signal_timer := 0.0


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
	speed = 300.0
	damage_multiplier = 1.0 + float(meta_bonuses.get("damage", 0.0))
	pickup_radius = 110.0
	shield_capacity = int(meta_bonuses.get("shield", 0.0))
	shield_charges = shield_capacity
	shield_recharge_timer = 0.0
	ability_mode = String(meta_bonuses.get("ability", "dash"))
	var cooldown_reduction := float(meta_bonuses.get("ability_mastery", 0.0)) * 0.015 + float(meta_bonuses.get("ability_cooldown", 0.0))
	ability_cooldown = 1.25 * (1.0 - minf(0.55, cooldown_reduction))
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	visual_update_timer -= delta
	hud_signal_timer -= delta
	invulnerable = maxf(0.0, invulnerable - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	dash_duration = maxf(0.0, dash_duration - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	parry_flash = maxf(0.0, parry_flash - delta)
	stationary_grace = maxf(0.0, stationary_grace - delta)
	if shield_charges < shield_capacity:
		shield_recharge_timer = maxf(0.0, shield_recharge_timer - delta)
		if shield_recharge_timer <= 0.0:
			shield_charges += 1
			shield_recharge_timer = 8.0 if shield_charges < shield_capacity else 0.0
	if hud_signal_timer <= 0.0:
		hud_signal_timer += HUD_SIGNAL_INTERVAL
		dash_changed.emit(1.0 - dash_cooldown / ability_cooldown)
	if not active:
		velocity = Vector2.ZERO
		_update_visual_if_due()
		return
	var input_vector := mobile_movement if mobile_controls_enabled else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length() <= 0.1 and dash_duration <= 0.0:
		stationary_time += delta
	elif preserve_stationary_on_dash and (dash_duration > 0.0 or stationary_grace > 0.0):
		pass
	else:
		stationary_time = 0.0
	if input_vector.length() > 0.1:
		desired_facing_direction = input_vector.normalized()
	var turn_weight := 1.0 - exp(-FACING_TURN_SPEED * delta)
	facing_direction = Vector2.from_angle(lerp_angle(facing_direction.angle(), desired_facing_direction.angle(), turn_weight))
	var ability_requested := Input.is_action_just_pressed("dash") or mobile_ability_queued
	mobile_ability_queued = false
	if ability_requested and dash_cooldown <= 0.0:
		if ability_mode == "vector_parry":
			dash_cooldown = ability_cooldown
			parry_flash = 0.24
			invulnerable = maxf(invulnerable, 0.16)
			parry_requested.emit(global_position)
			active_skill_used.emit("vector_parry", 18.0)
		elif input_vector != Vector2.ZERO:
			dash_direction = input_vector.normalized()
			dash_duration = 0.18
			if preserve_stationary_on_dash:
				stationary_grace = 0.32
			dash_cooldown = ability_cooldown
			invulnerable = 0.30
			active_skill_used.emit("dash", 18.0)
	if dash_duration > 0.0:
		velocity = dash_direction * speed * 3.2
	else:
		velocity = input_vector.normalized() * speed if input_vector.length() > 0.1 else Vector2.ZERO
	move_and_slide()
	global_position.x = clampf(global_position.x, arena.position.x, arena.end.x)
	global_position.y = clampf(global_position.y, arena.position.y, arena.end.y)
	_update_visual_if_due()


func _update_visual_if_due() -> void:
	if visual_update_timer > 0.0:
		return
	visual_update_timer += VISUAL_UPDATE_INTERVAL
	queue_redraw()


func set_mobile_controls_enabled(value: bool) -> void:
	mobile_controls_enabled = value
	if not value:
		mobile_movement = Vector2.ZERO
		mobile_ability_queued = false


func set_mobile_input(movement: Vector2) -> void:
	mobile_movement = movement.limit_length(1.0)


func clear_mobile_input() -> void:
	mobile_movement = Vector2.ZERO
	mobile_ability_queued = false


func request_mobile_ability() -> void:
	if mobile_controls_enabled:
		mobile_ability_queued = true


func set_preserve_stationary_on_dash(value: bool) -> void:
	preserve_stationary_on_dash = value


func take_damage(amount: float) -> bool:
	if not active or invulnerable > 0.0:
		return false
	shield_recharge_timer = 8.0
	if shield_charges > 0:
		shield_charges -= 1
		invulnerable = 0.42
		hit_flash = 0.18
		queue_redraw()
		return true
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
	var a := facing_direction.angle()
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
	if shield_charges > 0:
		for charge in shield_charges:
			var radius := 31.0 + charge * 5.0
			draw_arc(Vector2.ZERO, radius, -PI * 0.82, PI * 0.82, 28, Color(GamePalette.GREEN, 0.72), 2.0)
	if parry_flash > 0.0:
		draw_arc(Vector2.ZERO, 52.0 + parry_flash * 45.0, 0.0, TAU, 48, Color.WHITE, 5.0)
		draw_arc(Vector2.ZERO, 60.0, 0.0, TAU, 48, Color(CYAN, parry_flash / 0.24), 2.0)
