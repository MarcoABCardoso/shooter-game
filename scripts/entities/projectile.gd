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


func _ready() -> void:
	collision_layer = 4 if friendly else 8
	collision_mask = 2 if friendly else 1
	monitoring = true
	monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	rotation = velocity.angle()
	if lifetime <= 0.0 or not arena.has_point(global_position):
		queue_free()


func _on_body_entered(body: Node) -> void:
	if hit_ids.has(body.get_instance_id()):
		return
	hit_ids[body.get_instance_id()] = true
	if friendly and body is NeonEnemy:
		var dealt: float = body.take_damage(damage, weapon)
		if dealt > 0.0:
			damage_dealt.emit(weapon, dealt, global_position, body.get_instance_id())
	elif not friendly and body is NeonPlayer:
		body.take_damage(damage)
	else:
		return
	if pierce <= 0:
		queue_free()
	else:
		pierce -= 1


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
