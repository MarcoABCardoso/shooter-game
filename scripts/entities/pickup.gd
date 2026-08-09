class_name NeonPickup
extends Area2D

signal collected(amount: int, world_position: Vector2)

var amount := 1
var target: NeonPlayer
var velocity := Vector2.ZERO
var age := 0.0
var collecting := false


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	age += delta
	rotation += delta * 2.5
	if is_instance_valid(target):
		if global_position.distance_squared_to(target.global_position) < target.pickup_radius * target.pickup_radius:
			collecting = true
		if collecting:
			velocity = velocity.move_toward((target.global_position - global_position).normalized() * 620.0, 1500.0 * delta)
	position += velocity * delta
	velocity *= pow(0.08, delta)
	modulate.a = 0.82 + sin(age * 5.0) * 0.18


func _on_body_entered(body: Node) -> void:
	if body is NeonPlayer:
		collected.emit(amount, global_position)
		queue_free()


func _draw() -> void:
	var c := Color("ff688e")
	draw_circle(Vector2.ZERO, 12.0, Color(c, 0.08))
	var points := PackedVector2Array([Vector2(0, -7), Vector2(6, 0), Vector2(0, 7), Vector2(-6, 0), Vector2(0, -7)])
	draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)]), Color(c, 0.25))
	draw_polyline(points, c, 2.0, true)
