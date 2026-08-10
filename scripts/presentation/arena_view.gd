class_name ArenaView
extends Node2D

class ArenaBackground:
	extends Node2D

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
