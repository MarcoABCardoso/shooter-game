class_name NeonBurst
extends Node2D

var color := Color("45f3ff")
var lifetime := 0.42
var age := 0.0
var size := 22.0
var spokes := 8


func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var t := age / lifetime
	for i in spokes:
		var direction := Vector2.from_angle(TAU * i / spokes + i * 0.37)
		draw_line(direction * size * t * 0.35, direction * size * (0.4 + t), Color(color, 1.0 - t), 2.0 * (1.0 - t), true)
	draw_circle(Vector2.ZERO, size * t, Color(color, (1.0 - t) * 0.08))
