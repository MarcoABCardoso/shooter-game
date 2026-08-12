class_name ArenaView
extends Node2D

class ArenaBackground:
	extends Node2D

	var objective_visible := false
	var objective_position := Vector2.ZERO
	var objective_radius := 0.0
	var objective_progress := 0.0
	var objective_occupied := false
	var relay_positions: Array[Vector2] = []
	var remaining_relays: Array[int] = []
	var mission_arenas: Array[Rect2] = [GameBalance.ARENA]
	var active_arena := GameBalance.ARENA
	var travel_destination := Rect2()
	var traveling := false
	var completion_time := 0.0
	var completion_duration := 1.0

	func _draw() -> void:
		var world_bounds := _world_bounds()
		draw_rect(world_bounds, GamePalette.BACKGROUND, true)
		var star_count := maxi(80, int(world_bounds.size.x / 12.0))
		for i in star_count:
			var px := world_bounds.position.x + fmod(float(i * 137 + 31), world_bounds.size.x)
			var py := fmod(float(i * 83 + 47), 720.0)
			var brightness := 0.2 + 0.15 * sin(float(i))
			draw_circle(Vector2(px, py), 1.0, Color(GamePalette.CYAN, brightness))
		for index in mission_arenas.size():
			var arena := mission_arenas[index]
			draw_rect(arena, Color(0.015, 0.045, 0.095, 0.78), true)
			for x in range(int(arena.position.x), int(arena.end.x) + 1, 52):
				draw_line(Vector2(x, arena.position.y), Vector2(x, arena.end.y), Color(GamePalette.CYAN, 0.035), 1.0)
			for y in range(int(arena.position.y), int(arena.end.y) + 1, 52):
				draw_line(Vector2(arena.position.x, y), Vector2(arena.end.x, y), Color(GamePalette.CYAN, 0.035), 1.0)
			var border_color := GamePalette.GREEN if arena == active_arena and traveling else GamePalette.CYAN
			var border_alpha := 0.72 if arena == active_arena else 0.24
			draw_rect(arena, Color(border_color, border_alpha), false, 3.0 if arena == active_arena else 2.0)
			draw_rect(arena.grow(6.0), Color(border_color, 0.08 if arena == active_arena else 0.035), false, 5.0)
			if index < mission_arenas.size() - 1:
				_draw_corridor(arena, mission_arenas[index + 1])
		if objective_visible:
			var field_color := GamePalette.GREEN if objective_occupied else GamePalette.YELLOW
			draw_circle(objective_position, objective_radius, Color(field_color, 0.055))
			draw_arc(objective_position, objective_radius, 0.0, TAU, 64, Color(field_color, 0.65), 3.0, true)
			draw_arc(objective_position, objective_radius + 9.0, -PI * 0.5, -PI * 0.5 + TAU * objective_progress, 64, field_color, 6.0, true)
			draw_circle(objective_position, 9.0, Color(field_color, 0.16))
			draw_arc(objective_position, 15.0, 0.0, TAU, 24, field_color, 2.0, true)
			if completion_time > 0.0:
				var completion_ratio := completion_time / completion_duration
				var completion_radius := objective_radius + (1.0 - completion_ratio) * 74.0
				draw_circle(objective_position, objective_radius, Color(GamePalette.GREEN, 0.13 * completion_ratio))
				draw_arc(objective_position, completion_radius, 0.0, TAU, 64, Color(GamePalette.GREEN, 0.85 * completion_ratio), 7.0, true)
		if not relay_positions.is_empty():
			for index in relay_positions.size():
				var next_index := (index + 1) % relay_positions.size()
				draw_dashed_line(relay_positions[index], relay_positions[next_index], Color(GamePalette.MAGENTA, 0.28), 2.0, 14.0)
			for index in relay_positions.size():
				var intact := remaining_relays.has(index)
				var relay_color := GamePalette.ORANGE if intact else Color(GamePalette.GREEN, 0.26)
				draw_circle(relay_positions[index], 42.0, Color(relay_color, 0.045 if intact else 0.02))
				draw_arc(relay_positions[index], 42.0, 0.0, TAU, 32, Color(relay_color, 0.72), 3.0 if intact else 1.0, true)
				if completion_time > 0.0:
					var completion_ratio := completion_time / completion_duration
					var completion_radius := 42.0 + (1.0 - completion_ratio) * 56.0
					draw_arc(relay_positions[index], completion_radius, 0.0, TAU, 32, Color(GamePalette.GREEN, 0.82 * completion_ratio), 6.0, true)

	func _draw_corridor(from_arena: Rect2, to_arena: Rect2) -> void:
		var gap := to_arena.position.x - from_arena.end.x
		if gap <= 0.0:
			return
		var corridor := Rect2(from_arena.end.x, from_arena.get_center().y - 105.0, gap, 210.0)
		var is_open := traveling and to_arena == travel_destination
		var color := GamePalette.GREEN if is_open else GamePalette.CYAN
		draw_rect(corridor, Color(0.012, 0.035, 0.068, 0.92), true)
		draw_line(corridor.position, Vector2(corridor.end.x, corridor.position.y), Color(color, 0.35 if is_open else 0.14), 2.0)
		draw_line(Vector2(corridor.position.x, corridor.end.y), corridor.end, Color(color, 0.35 if is_open else 0.14), 2.0)
		var arrow_x := corridor.position.x + 90.0
		while arrow_x < corridor.end.x - 40.0:
			draw_line(Vector2(arrow_x - 18.0, corridor.get_center().y - 15.0), Vector2(arrow_x, corridor.get_center().y), Color(color, 0.26 if is_open else 0.09), 3.0)
			draw_line(Vector2(arrow_x, corridor.get_center().y), Vector2(arrow_x - 18.0, corridor.get_center().y + 15.0), Color(color, 0.26 if is_open else 0.09), 3.0)
			arrow_x += 120.0

	func _world_bounds() -> Rect2:
		if mission_arenas.is_empty():
			return Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
		var first := mission_arenas[0]
		var last := mission_arenas[mission_arenas.size() - 1]
		return Rect2(Vector2(first.position.x - 54.0, 0.0), Vector2(last.end.x - first.position.x + 108.0, 720.0))

var shake_strength := 0.0
var background: ArenaBackground
var camera: Camera2D

const TRAVEL_CAMERA_DEAD_ZONE := 90.0


func _ready() -> void:
	background = ArenaBackground.new()
	background.z_index = -10
	add_child(background)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)
	configure_mission([GameBalance.ARENA])


func _process(delta: float) -> void:
	if background.completion_time > 0.0:
		background.completion_time = maxf(0.0, background.completion_time - delta)
		background.queue_redraw()
	shake_strength = maxf(0.0, shake_strength - delta * 18.0)
	if shake_strength > 0.0:
		background.position = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		background.position = Vector2.ZERO


func shake(amount: float) -> void:
	shake_strength = maxf(shake_strength, amount)


func configure_mission(arenas: Array[Rect2]) -> void:
	background.mission_arenas = arenas.duplicate() if not arenas.is_empty() else [GameBalance.ARENA]
	background.active_arena = background.mission_arenas[0]
	background.travel_destination = Rect2()
	background.traveling = false
	background.completion_time = 0.0
	var first := background.mission_arenas[0]
	var last := background.mission_arenas[background.mission_arenas.size() - 1]
	camera.limit_left = int(first.position.x - 54.0)
	camera.limit_right = int(last.end.x + 54.0)
	camera.limit_top = 0
	camera.limit_bottom = 720
	camera.position = first.get_center()
	camera.reset_smoothing()
	background.queue_redraw()


func set_active_arena(arena: Rect2, is_traveling: bool = false) -> void:
	background.active_arena = arena
	background.travel_destination = arena if is_traveling else Rect2()
	background.traveling = is_traveling
	if not is_traveling:
		camera.position = arena.get_center()
	background.queue_redraw()


func follow_player(world_position: Vector2) -> void:
	if not background.traveling:
		return
	var horizontal_offset := world_position.x - camera.position.x
	if absf(horizontal_offset) > TRAVEL_CAMERA_DEAD_ZONE:
		camera.position.x = world_position.x - signf(horizontal_offset) * TRAVEL_CAMERA_DEAD_ZONE
	camera.position.y = 360.0


func animate_objective_completion(duration: float) -> void:
	background.completion_duration = maxf(0.1, duration)
	background.completion_time = background.completion_duration
	background.queue_redraw()


func show_signal_objective(world_position: Vector2, radius: float, progress: float, occupied: bool) -> void:
	background.objective_visible = true
	background.objective_position = world_position
	background.objective_radius = radius
	background.objective_progress = progress
	background.objective_occupied = occupied
	background.queue_redraw()


func hide_objective() -> void:
	background.objective_visible = false
	background.completion_time = 0.0
	background.relay_positions.clear()
	background.remaining_relays.clear()
	background.queue_redraw()


func show_relay_network(positions: Array[Vector2], remaining: Array[int]) -> void:
	background.objective_visible = false
	background.relay_positions = positions.duplicate()
	background.remaining_relays = remaining.duplicate()
	background.queue_redraw()
