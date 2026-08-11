class_name CreditsView
extends Control

signal finished
signal exit_requested

const CREDITS_TRACK_DURATION := 66.762267574
const FINALE_DURATION := 5.6
const CYCLE_DURATION := (CREDITS_TRACK_DURATION - FINALE_DURATION) / 6.0
const CHASE_START := 0.68
const RETURN_END := 0.22
const FINALE_BOOST_DURATION := 1.35
const PLAYER_CENTER_X := 915.0
const PLAYER_BOOST_X := 1215.0
const FINALE_EXIT_X := 1550.0
const ENEMY_START_X := -110.0
const ROLES: Array[String] = [
	"A GAME BY",
	"GAME DESIGN",
	"PROGRAMMING",
	"ART DIRECTION",
	"MUSIC DIRECTION",
	"QUALITY ASSURANCE",
]
const ATTRIBUTIONS: Array[String] = [
	"MarcoABCardoso",
	"MarcoABCardoso",
	"Honestly? Mostly vibecoded",
	"MarcoABCardoso",
	"MarcoABCardoso",
	"MarcoABCardoso",
]
const ENEMY_SEQUENCE: Array[String] = [
	"drone",
	"striker",
	"gunner",
	"tank",
	"boss",
	"elite_drone",
]

var role_label: Label
var names_label: Label
var cycle_elapsed := 0.0
var total_elapsed := 0.0
var role_index := 0
var running := false
var completion_emitted := false
var finale_active := false
var finale_elapsed := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	clip_contents = true

	var transmission := UIFactory.label("FINAL TRANSMISSION", 11, Color(GamePalette.CYAN, 0.58))
	transmission.position = Vector2(42, 30)
	transmission.size = Vector2(620, 24)
	add_child(transmission)

	var return_button := UIFactory.button("BACK TO HANGAR", Vector2(1050, 24), Vector2(190, 42))
	return_button.name = "CreditsReturnButton"
	return_button.pressed.connect(exit_requested.emit)
	add_child(return_button)

	role_label = UIFactory.label(ROLES[0], 38, GamePalette.CYAN)
	role_label.size = Vector2(720, 58)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(role_label)

	names_label = UIFactory.label(ATTRIBUTIONS[0], 25, Color.WHITE)
	names_label.size = Vector2(720, 118)
	names_label.add_theme_constant_override("line_spacing", 5)
	names_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(names_label)

	_update_role_text()


func start() -> void:
	cycle_elapsed = 0.0
	total_elapsed = 0.0
	role_index = 0
	running = true
	completion_emitted = false
	finale_active = false
	finale_elapsed = 0.0
	role_label.add_theme_font_size_override("font_size", 38)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	role_label.size = Vector2(720, 58)
	names_label.visible = true
	_update_role_text()
	_update_role_position()
	queue_redraw()


func stop() -> void:
	running = false


func _process(delta: float) -> void:
	if not running or not is_visible_in_tree():
		return
	total_elapsed += delta
	if finale_active:
		finale_elapsed += delta
		_update_finale_card()
		queue_redraw()
		if finale_elapsed >= FINALE_DURATION:
			_finish_credits()
		return
	cycle_elapsed += delta
	if cycle_elapsed >= CYCLE_DURATION:
		cycle_elapsed = fmod(cycle_elapsed, CYCLE_DURATION)
		role_index += 1
		if role_index >= ROLES.size():
			_start_finale()
			return
		_update_role_text()
	_update_role_position()
	queue_redraw()


func _update_role_text() -> void:
	role_label.text = ROLES[role_index]
	role_label.add_theme_color_override("font_color", GamePalette.GREEN if role_index % 3 == 2 else GamePalette.CYAN)
	names_label.text = ATTRIBUTIONS[role_index]


func _update_role_position() -> void:
	var progress := clampf(cycle_elapsed / CYCLE_DURATION, 0.0, 1.0)
	var x := 140.0
	if progress < 0.20:
		var entry := smoothstep(0.0, 1.0, progress / 0.20)
		# The opening card enters from the left; every subsequent role replaces it
		# from the right after the pursuer is thrown off-screen.
		x = lerpf(-720.0 if role_index == 0 else 1280.0, 140.0, entry)
	elif progress < CHASE_START:
		x = lerpf(140.0, 112.0, (progress - 0.20) / (CHASE_START - 0.20))
	else:
		var exit_progress := smoothstep(0.0, 1.0, (progress - CHASE_START) / (1.0 - CHASE_START))
		x = lerpf(112.0, -760.0, exit_progress)
	role_label.position = Vector2(x, 188)
	names_label.position = Vector2(x + 4.0, 258)
	var flash := 0.76 + absf(sin(total_elapsed * 9.0)) * 0.24
	role_label.modulate.a = flash
	names_label.modulate.a = 0.88 + absf(sin(total_elapsed * 4.5)) * 0.12


func _start_finale() -> void:
	finale_active = true
	finale_elapsed = 0.0
	role_label.text = "THANK YOU FOR PLAYING"
	role_label.add_theme_font_size_override("font_size", 48)
	role_label.add_theme_color_override("font_color", GamePalette.GREEN)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.position = Vector2(0, 280)
	role_label.size = Vector2(1280, 72)
	names_label.visible = false
	_update_finale_card()
	queue_redraw()


func _update_finale_card() -> void:
	role_label.position = Vector2(0, 280)
	if finale_elapsed < 1.4:
		role_label.modulate.a = 0.28 + absf(sin(finale_elapsed * 11.0)) * 0.72
	else:
		role_label.modulate.a = 1.0


func _finish_credits() -> void:
	running = false
	if not completion_emitted:
		completion_emitted = true
		finished.emit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GamePalette.BACKGROUND)
	if finale_active:
		_draw_starfield(1.0)
		_draw_finale()
		return
	var progress := clampf(cycle_elapsed / CYCLE_DURATION, 0.0, 1.0)
	_draw_starfield(progress)
	_draw_role_frame(progress)

	var player_x := _player_x_for_cycle(progress)
	var enemy_x := _enemy_x_for_cycle(progress)
	var boosting := progress >= CHASE_START
	var flight_y := size.y - 132.0
	_draw_enemy(Vector2(enemy_x, flight_y + 3.0), total_elapsed, ENEMY_SEQUENCE[role_index])
	_draw_player(Vector2(player_x, flight_y), boosting, progress)


func _player_x_for_cycle(progress: float) -> float:
	if role_index > 0 and progress < RETURN_END:
		return lerpf(PLAYER_BOOST_X, PLAYER_CENTER_X, smoothstep(0.0, 1.0, progress / RETURN_END))
	if progress >= CHASE_START:
		var escape := smoothstep(0.0, 1.0, (progress - CHASE_START) / (1.0 - CHASE_START))
		return lerpf(PLAYER_CENTER_X, PLAYER_BOOST_X, escape)
	return PLAYER_CENTER_X


func _enemy_x_for_cycle(progress: float) -> float:
	if progress >= CHASE_START:
		var escape := smoothstep(0.0, 1.0, (progress - CHASE_START) / (1.0 - CHASE_START))
		return lerpf(825.0, -170.0, escape)
	var chase_progress := smoothstep(0.0, 1.0, progress / CHASE_START)
	return lerpf(ENEMY_START_X, 825.0, chase_progress)


func _draw_finale() -> void:
	var card := Rect2(245, 224, 790, 206)
	draw_rect(card, Color(GamePalette.INK, 0.88), true)
	draw_rect(card, Color(GamePalette.GREEN, 0.58), false, 3.0)
	draw_line(Vector2(300, 255), Vector2(980, 255), Color(GamePalette.CYAN, 0.20), 2.0)
	draw_line(Vector2(300, 398), Vector2(980, 398), Color(GamePalette.CYAN, 0.20), 2.0)
	var boost_progress := smoothstep(0.0, 1.0, minf(1.0, finale_elapsed / FINALE_BOOST_DURATION))
	# Carry the full exhaust plume beyond the 1280px viewport, not just the hull.
	var player_x := lerpf(PLAYER_BOOST_X, FINALE_EXIT_X, boost_progress)
	_draw_player(Vector2(player_x, size.y - 132.0), true, 1.0)


func _draw_starfield(progress: float) -> void:
	var escape_speed := 4.0 if progress >= CHASE_START else 1.0
	for i in 34:
		var base_x := float((i * 197 + 61) % 1320)
		var x := fmod(base_x - total_elapsed * (18.0 + float(i % 5) * 8.0) * escape_speed + 1400.0, 1400.0) - 60.0
		var y := float((i * 83 + 37) % 620) + 35.0
		var length := (3.0 + float(i % 4) * 2.0) * escape_speed
		var color := GamePalette.GREEN if i % 7 == 0 else GamePalette.CYAN
		draw_line(Vector2(x, y), Vector2(x - length, y), Color(color, 0.12 + float(i % 3) * 0.04), 1.0)


func _draw_role_frame(progress: float) -> void:
	var frame_alpha := 0.13 + absf(sin(total_elapsed * 3.0)) * 0.07
	draw_line(Vector2(105, 174), Vector2(780, 174), Color(GamePalette.CYAN, frame_alpha), 2.0)
	draw_line(Vector2(105, 402), Vector2(650, 402), Color(GamePalette.GREEN, frame_alpha), 2.0)
	if progress >= CHASE_START:
		draw_line(Vector2(0, size.y - 82), Vector2(size.x, size.y - 82), Color(GamePalette.CYAN, 0.20), 2.0)


func _draw_player(origin: Vector2, boosting: bool, progress: float) -> void:
	var ship_scale := 1.75
	var flicker := 0.55 + sin(total_elapsed * 24.0) * 0.16
	var trail_length := 165.0 if boosting else 52.0
	trail_length *= 0.88 + absf(sin(total_elapsed * 17.0)) * 0.22
	draw_line(origin + Vector2(-18, 0), origin + Vector2(-trail_length, 0), Color(GamePalette.CYAN, flicker), 5.0 if boosting else 3.0)
	draw_line(origin + Vector2(-14, -8), origin + Vector2(-trail_length * 0.72, -8), Color(GamePalette.GREEN, flicker * 0.55), 2.0)
	draw_line(origin + Vector2(-14, 8), origin + Vector2(-trail_length * 0.72, 8), Color(GamePalette.GREEN, flicker * 0.55), 2.0)
	var ship := PackedVector2Array([
		origin + Vector2(24, 0) * ship_scale,
		origin + Vector2(-14, -15) * ship_scale,
		origin + Vector2(-6, 0) * ship_scale,
		origin + Vector2(-14, 15) * ship_scale,
	])
	draw_colored_polygon(ship, Color("082a45"))
	var outline := ship.duplicate()
	outline.append(ship[0])
	draw_polyline(outline, GamePalette.CYAN, 3.5, true)
	draw_line(origin + Vector2(3, 0), origin + Vector2(34, 0), Color(GamePalette.CYAN, 0.72), 3.0)
	if boosting:
		draw_arc(origin, 55.0 + sin(progress * PI) * 7.0, -2.35, 2.35, 28, Color(GamePalette.GREEN, 0.30), 2.0)


func _draw_enemy(origin: Vector2, phase: float, variant: String) -> void:
	var is_elite := variant.begins_with("elite_")
	var is_echo := variant.ends_with("_echo")
	var kind := variant.trim_prefix("elite_").trim_suffix("_echo")
	var radius := 28.0 + (4.0 if is_elite else 0.0) + (2.0 if is_echo else 0.0)
	var color := GamePalette.RED if kind == "boss" else (GamePalette.ORANGE if is_elite else GamePalette.MAGENTA)
	var points := PackedVector2Array()
	match kind:
		"striker":
			points = PackedVector2Array([
				origin + Vector2(radius * 1.35, 0),
				origin + Vector2(-radius, radius * 0.82),
				origin + Vector2(-radius * 0.30, 0),
				origin + Vector2(-radius, -radius * 0.82),
			])
		"gunner":
			points = _regular_enemy_polygon(origin, 6, radius, phase * 0.18)
		"tank":
			points = _regular_enemy_polygon(origin, 4, radius, PI * 0.25)
		"boss":
			points = _regular_enemy_polygon(origin, 6, radius * 1.18, phase * 0.12)
		_:
			points = PackedVector2Array([
				origin + Vector2(radius, 0),
				origin + Vector2(0, radius),
				origin + Vector2(-radius, 0),
				origin + Vector2(0, -radius),
			])
	draw_circle(origin, radius + 13.0, Color(color, 0.06))
	draw_colored_polygon(points, Color(color.darkened(0.78), 0.94))
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, color, 3.0, true)
	if kind == "tank":
		draw_rect(Rect2(origin - Vector2.ONE * radius * 0.38, Vector2.ONE * radius * 0.76), Color(color, 0.25), true)
	elif kind == "boss":
		for socket_index in 3:
			var socket_angle := phase * 0.35 + TAU * socket_index / 3.0
			var socket := origin + Vector2.from_angle(socket_angle) * (radius + 13.0)
			draw_line(origin, socket, Color(color, 0.56), 3.0)
			draw_circle(socket, 7.0, color)
	if is_elite:
		draw_arc(origin, radius + 9.0, phase * 1.8, phase * 1.8 + PI * 1.45, 20, Color(GamePalette.ORANGE, 0.82), 3.0)
	if is_echo:
		draw_arc(origin, radius + 14.0 + sin(phase * 5.0) * 2.0, 0.0, TAU, 28, Color(GamePalette.CYAN, 0.52), 2.0)
	draw_circle(origin, 6.0 + sin(phase * 7.0) * 1.5, Color.WHITE)


func _regular_enemy_polygon(origin: Vector2, sides: int, radius: float, angle_offset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		points.append(origin + Vector2.from_angle(angle_offset + TAU * index / sides) * radius)
	return points
