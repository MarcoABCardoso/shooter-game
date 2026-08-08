class_name ArenaView
extends Node2D

var player: NeonPlayer
var combat_visible := false
var shake_strength := 0.0


func _process(delta: float) -> void:
	shake_strength = maxf(0.0, shake_strength - delta * 18.0)
	queue_redraw()


func shake(amount: float) -> void:
	shake_strength = maxf(shake_strength, amount)


func _draw() -> void:
	var offset := Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	draw_set_transform(offset)
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), GamePalette.BACKGROUND, true)
	for i in 80:
		var px := fmod(float(i * 137 + 31), 1280.0)
		var py := fmod(float(i * 83 + 47), 720.0)
		var pulse := 0.2 + 0.15 * sin(Time.get_ticks_msec() * 0.0015 + i)
		draw_circle(Vector2(px, py), 1.0, Color(GamePalette.CYAN, pulse))
	draw_rect(GameBalance.ARENA, Color(0.015, 0.045, 0.095, 0.78), true)
	for x in range(int(GameBalance.ARENA.position.x), int(GameBalance.ARENA.end.x) + 1, 52):
		draw_line(Vector2(x, GameBalance.ARENA.position.y), Vector2(x, GameBalance.ARENA.end.y), Color(GamePalette.CYAN, 0.035), 1.0)
	for y in range(int(GameBalance.ARENA.position.y), int(GameBalance.ARENA.end.y) + 1, 52):
		draw_line(Vector2(GameBalance.ARENA.position.x, y), Vector2(GameBalance.ARENA.end.x, y), Color(GamePalette.CYAN, 0.035), 1.0)
	draw_rect(GameBalance.ARENA, Color(GamePalette.CYAN, 0.38), false, 2.0)
	draw_rect(GameBalance.ARENA.grow(6.0), Color(GamePalette.CYAN, 0.06), false, 5.0)
	if combat_visible and is_instance_valid(player):
		var mouse := get_global_mouse_position()
		draw_arc(mouse, 10.0, 0.0, TAU, 16, Color(GamePalette.CYAN, 0.65), 1.5)
		draw_line(mouse - Vector2(15, 0), mouse - Vector2(6, 0), GamePalette.CYAN, 1.0)
		draw_line(mouse + Vector2(6, 0), mouse + Vector2(15, 0), GamePalette.CYAN, 1.0)
		draw_line(mouse - Vector2(0, 15), mouse - Vector2(0, 6), GamePalette.CYAN, 1.0)
		draw_line(mouse + Vector2(0, 6), mouse + Vector2(0, 15), GamePalette.CYAN, 1.0)
	draw_set_transform(Vector2.ZERO)
