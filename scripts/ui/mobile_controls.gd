class_name MobileControls
extends Control

signal input_changed(movement: Vector2, aim: Vector2)
signal ability_requested
signal pause_requested

const BASE_RADIUS := 72.0
const KNOB_RADIUS := 34.0
const KNOB_TRAVEL := 42.0
const STICK_RANGE := 72.0
const ABILITY_RADIUS := 55.0
const PAUSE_RADIUS := 38.0
const DEADZONE := 0.12

var movement := Vector2.ZERO
var aim := Vector2.ZERO
var move_touch := -1
var aim_touch := -1
var ability_touch := -1
var pause_touch := -1
var ability_held := false


static func should_be_available() -> bool:
	if OS.has_feature("mobile"):
		return true
	# Web exports do not inherit the native "mobile" feature tag. A coarse,
	# touch-capable pointer is the useful distinction for browser controls.
	if OS.has_feature("web"):
		var expression := "navigator.maxTouchPoints > 0 && window.matchMedia('(pointer: coarse)').matches"
		return bool(JavaScriptBridge.eval(expression))
	return false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(queue_redraw)
	queue_redraw()


func set_controls_active(value: bool) -> void:
	visible = value
	if not value:
		_reset_input()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if event.position.distance_to(_pause_center()) <= PAUSE_RADIUS and pause_touch < 0:
			pause_touch = event.index
			pause_requested.emit()
		elif event.position.distance_to(_ability_center()) <= ABILITY_RADIUS * 1.25 and ability_touch < 0:
			ability_touch = event.index
			ability_held = true
			ability_requested.emit()
		elif event.position.x < size.x * 0.5:
			if move_touch < 0:
				move_touch = event.index
				movement = _stick_value(event.position, _move_center())
				_emit_input()
		elif aim_touch < 0:
			aim_touch = event.index
			aim = _stick_value(event.position, _aim_center())
			_emit_input()
	else:
		if event.index == move_touch:
			move_touch = -1
			movement = Vector2.ZERO
			_emit_input()
		elif event.index == aim_touch:
			aim_touch = -1
			aim = Vector2.ZERO
			_emit_input()
		elif event.index == ability_touch:
			ability_touch = -1
			ability_held = false
		elif event.index == pause_touch:
			pause_touch = -1
	queue_redraw()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == move_touch:
		movement = _stick_value(event.position, _move_center())
		_emit_input()
	elif event.index == aim_touch:
		aim = _stick_value(event.position, _aim_center())
		_emit_input()
	queue_redraw()


func _stick_value(position: Vector2, center: Vector2) -> Vector2:
	var offset := position - center
	var value := offset / STICK_RANGE
	if value.length() < DEADZONE:
		return Vector2.ZERO
	return value.limit_length(1.0)


func _emit_input() -> void:
	input_changed.emit(movement, aim)


func _reset_input() -> void:
	var had_input := movement != Vector2.ZERO or aim != Vector2.ZERO
	movement = Vector2.ZERO
	aim = Vector2.ZERO
	move_touch = -1
	aim_touch = -1
	ability_touch = -1
	pause_touch = -1
	ability_held = false
	if had_input:
		_emit_input()
	queue_redraw()


func _on_visibility_changed() -> void:
	if not visible:
		_reset_input()


func _move_center() -> Vector2:
	return Vector2(140.0, size.y - 170.0)


func _aim_center() -> Vector2:
	return Vector2(size.x - 140.0, size.y - 170.0)


func _ability_center() -> Vector2:
	return Vector2(size.x - 112.0, size.y - 365.0)


func _pause_center() -> Vector2:
	return Vector2(size.x - 52.0, 42.0)


func _draw() -> void:
	_draw_stick(_move_center(), movement, GamePalette.CYAN, false)
	_draw_stick(_aim_center(), aim, GamePalette.GREEN, true)
	_draw_ability_button()
	_draw_pause_button()


func _draw_stick(center: Vector2, value: Vector2, color: Color, crosshair: bool) -> void:
	draw_circle(center, BASE_RADIUS, Color(GamePalette.INK, 0.58))
	draw_arc(center, BASE_RADIUS, 0.0, TAU, 48, Color(color, 0.55), 3.0, true)
	draw_arc(center, BASE_RADIUS - 12.0, 0.0, TAU, 48, Color(color, 0.16), 2.0, true)
	var knob_center := center + value * KNOB_TRAVEL
	draw_circle(knob_center, KNOB_RADIUS, Color(color, 0.22))
	draw_arc(knob_center, KNOB_RADIUS, 0.0, TAU, 32, Color(color, 0.86), 3.0, true)
	if crosshair:
		draw_circle(knob_center, 7.0, Color(color, 0.24))
		draw_line(knob_center - Vector2(17, 0), knob_center - Vector2(9, 0), color, 2.0)
		draw_line(knob_center + Vector2(9, 0), knob_center + Vector2(17, 0), color, 2.0)
		draw_line(knob_center - Vector2(0, 17), knob_center - Vector2(0, 9), color, 2.0)
		draw_line(knob_center + Vector2(0, 9), knob_center + Vector2(0, 17), color, 2.0)
	else:
		draw_line(knob_center - Vector2(15, 0), knob_center + Vector2(15, 0), color, 2.0)
		draw_line(knob_center - Vector2(0, 15), knob_center + Vector2(0, 15), color, 2.0)


func _draw_ability_button() -> void:
	var center := _ability_center()
	var color := Color.WHITE if ability_held else GamePalette.MAGENTA
	draw_circle(center, ABILITY_RADIUS, Color(GamePalette.INK, 0.62))
	draw_circle(center, ABILITY_RADIUS - 8.0, Color(color, 0.16 if not ability_held else 0.32))
	draw_arc(center, ABILITY_RADIUS, 0.0, TAU, 40, Color(color, 0.88), 3.0, true)
	var bolt := PackedVector2Array([
		center + Vector2(7, -29), center + Vector2(-17, 3),
		center + Vector2(-3, 3), center + Vector2(-10, 29),
		center + Vector2(20, -8), center + Vector2(5, -8),
	])
	draw_colored_polygon(bolt, Color(color, 0.85))


func _draw_pause_button() -> void:
	var center := _pause_center()
	draw_circle(center, PAUSE_RADIUS, Color(GamePalette.INK, 0.72))
	draw_arc(center, PAUSE_RADIUS, 0.0, TAU, 32, Color(GamePalette.CYAN, 0.66), 2.0, true)
	draw_rect(Rect2(center + Vector2(-11, -14), Vector2(7, 28)), Color(GamePalette.CYAN, 0.9))
	draw_rect(Rect2(center + Vector2(4, -14), Vector2(7, 28)), Color(GamePalette.CYAN, 0.9))
