class_name ArenaView
extends Node2D

class ArenaBackground:
	extends Node2D

	var objective_visible := false
	var objective_position := Vector2.ZERO
	var objective_radius := 0.0
	var objective_progress := 0.0
	var objective_occupied := false

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), GamePalette.BACKGROUND, true)
		for i in 80:
			var px := fmod(float(i * 137 + 31), 1280.0)
			var py := fmod(float(i * 83 + 47), 720.0)
			var brightness := 0.2 + 0.15 * sin(float(i))
			draw_circle(Vector2(px, py), 1.0, Color(GamePalette.CYAN, brightness))
		draw_rect(GameBalance.ARENA, Color(0.015, 0.045, 0.095, 0.78), true)
		for x in range(int(GameBalance.ARENA.position.x), int(GameBalance.ARENA.end.x) + 1, 52):
			draw_line(Vector2(x, GameBalance.ARENA.position.y), Vector2(x, GameBalance.ARENA.end.y), Color(GamePalette.CYAN, 0.035), 1.0)
		for y in range(int(GameBalance.ARENA.position.y), int(GameBalance.ARENA.end.y) + 1, 52):
			draw_line(Vector2(GameBalance.ARENA.position.x, y), Vector2(GameBalance.ARENA.end.x, y), Color(GamePalette.CYAN, 0.035), 1.0)
		draw_rect(GameBalance.ARENA, Color(GamePalette.CYAN, 0.38), false, 2.0)
		draw_rect(GameBalance.ARENA.grow(6.0), Color(GamePalette.CYAN, 0.06), false, 5.0)
		if objective_visible:
			var field_color := GamePalette.GREEN if objective_occupied else GamePalette.YELLOW
			draw_circle(objective_position, objective_radius, Color(field_color, 0.055))
			draw_arc(objective_position, objective_radius, 0.0, TAU, 64, Color(field_color, 0.65), 3.0, true)
			draw_arc(objective_position, objective_radius + 9.0, -PI * 0.5, -PI * 0.5 + TAU * objective_progress, 64, field_color, 6.0, true)
			draw_circle(objective_position, 9.0, Color(field_color, 0.16))
			draw_arc(objective_position, 15.0, 0.0, TAU, 24, field_color, 2.0, true)

var shake_strength := 0.0
var background: ArenaBackground


func _ready() -> void:
	background = ArenaBackground.new()
	background.z_index = -10
	add_child(background)


func _process(delta: float) -> void:
	shake_strength = maxf(0.0, shake_strength - delta * 18.0)
	if shake_strength > 0.0:
		background.position = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		background.position = Vector2.ZERO


func shake(amount: float) -> void:
	shake_strength = maxf(shake_strength, amount)


func show_signal_objective(world_position: Vector2, radius: float, progress: float, occupied: bool) -> void:
	background.objective_visible = true
	background.objective_position = world_position
	background.objective_radius = radius
	background.objective_progress = progress
	background.objective_occupied = occupied
	background.queue_redraw()


func hide_objective() -> void:
	background.objective_visible = false
	background.queue_redraw()
