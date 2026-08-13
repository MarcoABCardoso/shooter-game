class_name SectorRouteView
extends Control

signal deploy_requested(id: String)

const OperationCatalog := preload("res://scripts/content/operation_catalog.gd")
const BUTTON_SIZE := Vector2(184.0, 54.0)

var profile: SaveProfile
var stage_buttons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_buttons()


func rebuild(current_profile: SaveProfile) -> void:
	profile = current_profile
	if stage_buttons.is_empty():
		_build_buttons()
	_layout_buttons()
	for stage_id: String in OperationCatalog.ORDER:
		var button := stage_buttons[stage_id] as Button
		var mission := OperationCatalog.mission(stage_id)
		var seconds := int(mission.get("time_limit", 0.0))
		button.text = "%s\n%02d:%02d" % [OperationCatalog.display_name(stage_id), seconds / 60, seconds % 60]
		button.disabled = not profile.is_stage_unlocked(stage_id)
		if profile.stage_clear_count(stage_id) > 0:
			button.modulate = GamePalette.GREEN
		elif profile.is_stage_unlocked(stage_id) and not bool(OperationCatalog.definition(stage_id).get("required", true)):
			button.modulate = GamePalette.YELLOW
		else:
			button.modulate = Color.WHITE
	queue_redraw()


func _draw() -> void:
	for stage_id: String in OperationCatalog.ORDER:
		var stage := OperationCatalog.definition(stage_id)
		for prerequisite: String in stage.get("prerequisites", []):
			var color := Color(GamePalette.CYAN, 0.14)
			var width := 3.0
			if profile != null and profile.stage_clear_count(stage_id) > 0:
				color = Color(GamePalette.GREEN, 0.78)
				width = 5.0
			elif profile != null and profile.is_stage_unlocked(stage_id):
				color = Color(GamePalette.YELLOW if not bool(stage.get("required", true)) else GamePalette.CYAN, 0.58)
				width = 4.0
			draw_line(_stage_center(prerequisite), _stage_center(stage_id), color, width, true)
			draw_circle(_stage_center(stage_id), 7.0, color)
	draw_circle(_stage_center(OperationCatalog.ORDER[0]), 7.0, Color(GamePalette.CYAN, 0.72))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not stage_buttons.is_empty():
		_layout_buttons()
		queue_redraw()


func _build_buttons() -> void:
	if not stage_buttons.is_empty():
		return
	for stage_id: String in OperationCatalog.ORDER:
		var button := UIFactory.button(OperationCatalog.display_name(stage_id), Vector2.ZERO, BUTTON_SIZE)
		button.name = "DeployButton_" + stage_id
		button.size = BUTTON_SIZE
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(deploy_requested.emit.bind(stage_id))
		add_child(button)
		stage_buttons[stage_id] = button
	_layout_buttons()


func _layout_buttons() -> void:
	for stage_id: String in OperationCatalog.ORDER:
		var button := stage_buttons[stage_id] as Button
		button.position = _stage_center(stage_id) - BUTTON_SIZE * 0.5


func _stage_center(stage_id: String) -> Vector2:
	var normalized: Vector2 = OperationCatalog.definition(stage_id).get("route_position", Vector2(0.5, 0.5))
	return Vector2(size.x * normalized.x, size.y * normalized.y)
