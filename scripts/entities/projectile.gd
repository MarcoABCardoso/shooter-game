class_name NeonProjectile
extends Area2D

signal damage_dealt(weapon: String, amount: float, world_position: Vector2, target_id: int)

var velocity := Vector2.ZERO
var damage := 10.0
var lifetime := 4.0
var friendly := true
var weapon := "pulse"
var pierce := 0
var radius := 4.0
var color := Color("45f3ff")
var arena := Rect2(-100.0, -100.0, 1480.0, 920.0)
var hit_ids: Dictionary = {}
var launch_position := Vector2.ZERO
var distant_damage_bonus := 0.0
var distant_threshold := 280.0
var knockback := 0.0
var max_range := INF
var splash_damage_ratio := 0.0
var splash_radius := 72.0


func _ready() -> void:
	launch_position = global_position
	collision_layer = 4 if friendly else 8
	collision_mask = 2 if friendly else 1
	monitoring = true
	monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_collision_entered)
	area_entered.connect(_on_collision_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	rotation = velocity.angle()
	if lifetime <= 0.0 or not arena.has_point(global_position) or launch_position.distance_squared_to(global_position) >= max_range * max_range:
		queue_free()


func _on_collision_entered(body: Node) -> void:
	if hit_ids.has(body.get_instance_id()):
		return
	hit_ids[body.get_instance_id()] = true
	if friendly and body is NeonEnemy:
		var final_damage := damage
		if launch_position.distance_squared_to(global_position) >= distant_threshold * distant_threshold:
			final_damage *= 1.0 + distant_damage_bonus
		var dealt: float = body.take_damage(final_damage, weapon)
		if dealt > 0.0:
			body.apply_knockback(launch_position, knockback)
			damage_dealt.emit(weapon, dealt, global_position, body.get_instance_id())
			_apply_splash(body, final_damage)
	elif not friendly and body is NeonPlayer:
		body.take_damage(damage)
	else:
		return
	if pierce <= 0:
		queue_free()
	else:
		pierce -= 1


func _apply_splash(primary: NeonEnemy, primary_damage: float) -> void:
	if splash_damage_ratio <= 0.0 or splash_radius <= 0.0:
		return
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not (node is NeonEnemy) or node == primary or not is_instance_valid(node) or not node.active:
			continue
		var enemy := node as NeonEnemy
		var hit_radius: float = splash_radius + enemy.radius
		if enemy.global_position.distance_squared_to(global_position) > hit_radius * hit_radius:
			continue
		var dealt: float = enemy.take_damage(primary_damage * splash_damage_ratio, weapon)
		if dealt > 0.0:
			enemy.apply_knockback(global_position, knockback * 0.5)
			damage_dealt.emit(weapon, dealt, enemy.global_position, enemy.get_instance_id())


func reflect(new_direction: Vector2) -> void:
	friendly = true
	weapon = "parry"
	damage *= 2.0
	velocity = new_direction.normalized() * maxf(480.0, velocity.length() * 1.35)
	color = GamePalette.CYAN
	collision_layer = 4
	collision_mask = 2
	hit_ids.clear()
	remove_from_group("enemy_projectiles")
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(-8, 0), radius * 1.7, Color(color, 0.10))
	draw_line(Vector2(-13, 0), Vector2(2, 0), Color(color, 0.38), radius * 1.3, true)
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, maxf(1.0, radius * 0.35), Color.WHITE)
