class_name StageGraphView
extends Control

signal stage_selected(id: String)

const StageCatalog := preload("res://scripts/content/stage_catalog.gd")
const NODE_SIZE := Vector2(138.0, 62.0)
const NODE_POSITIONS := {
	"stage_1": Vector2(180.0, 105.0),
	"stage_2": Vector2(760.0, 250.0),
	"stage_3": Vector2(180.0, 395.0),
	"stage_4": Vector2(315.0, 250.0),
	"stage_5": Vector2(515.0, 250.0),
}
const EDGES: Array[Array] = [
	["stage_1", "stage_2"],
	["stage_2", "stage_3"],
	["stage_3", "stage_4"],
	["stage_4", "stage_1"],
	["stage_4", "stage_5"],
	["stage_5", "stage_2"],
]

var unlocked: Array[String] = []
var cleared: Array[String] = []
var hovered_stage := ""
var pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	process_mode = Node.PROCESS_MODE_ALWAYS
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	pulse = fmod(pulse + delta, TAU)
	queue_redraw()


func rebuild(profile: SaveProfile) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	unlocked.clear()
	cleared.clear()
	hovered_stage = ""
	for id: String in StageCatalog.ORDER:
		if not profile.stage_unlocked(id):
			continue
		unlocked.append(id)
		if profile.stage_cleared(id):
			cleared.append(id)
		_add_stage_node(id)
	queue_redraw()


func _add_stage_node(id: String) -> void:
	var button := Button.new()
	button.name = "StageSelect_" + id
	button.text = "STAGE %d" % StageCatalog.number(id)
	button.position = _node_center(id) - NODE_SIZE * 0.5
	button.size = NODE_SIZE
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", GamePalette.GREEN if cleared.has(id) else GamePalette.CYAN)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GamePalette.YELLOW)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.pressed.connect(stage_selected.emit.bind(id))
	button.mouse_entered.connect(_set_hovered.bind(id))
	button.mouse_exited.connect(_clear_hovered.bind(id))
	add_child(button)


func _set_hovered(id: String) -> void:
	hovered_stage = id
	queue_redraw()


func _clear_hovered(id: String) -> void:
	if hovered_stage == id:
		hovered_stage = ""
		queue_redraw()


func _node_center(id: String) -> Vector2:
	return NODE_POSITIONS.get(id, size * 0.5)


func _draw() -> void:
	_draw_signal_field()
	for edge: Array in EDGES:
		var from_id := String(edge[0])
		var to_id := String(edge[1])
		if not unlocked.has(from_id) or not unlocked.has(to_id):
			continue
		var from := _node_center(from_id)
		var to := _node_center(to_id)
		var complete := cleared.has(from_id) and cleared.has(to_id)
		var color := GamePalette.GREEN if complete else GamePalette.CYAN
		draw_line(from, to, Color(color, 0.08), 13.0, true)
		draw_line(from, to, Color(color, 0.62), 2.5, true)
		_draw_edge_ticks(from, to, color)
	for id: String in unlocked:
		_draw_stage_node(id)


func _draw_signal_field() -> void:
	for i in 18:
		var point := Vector2(fmod(float(i * 173 + 47), maxf(1.0, size.x)), fmod(float(i * 97 + 31), maxf(1.0, size.y)))
		draw_circle(point, 1.5, Color(GamePalette.CYAN, 0.16 + 0.06 * sin(pulse + i)))
	var center := Vector2(470.0, 250.0)
	draw_arc(center, 225.0, -0.55, 0.55, 40, Color(GamePalette.CYAN, 0.055), 1.0)
	draw_arc(center, 165.0, PI - 0.72, PI + 0.72, 32, Color(GamePalette.GREEN, 0.05), 1.0)


func _draw_edge_ticks(from: Vector2, to: Vector2, color: Color) -> void:
	var direction := (to - from).normalized()
	var normal := direction.rotated(PI * 0.5)
	for ratio in [0.25, 0.5, 0.75]:
		var point: Vector2 = from.lerp(to, ratio)
		draw_line(point - normal * 5.0, point + normal * 5.0, Color(color, 0.46), 1.5, true)


func _draw_stage_node(id: String) -> void:
	var center := _node_center(id)
	var is_cleared := cleared.has(id)
	var is_hovered := hovered_stage == id
	var color := GamePalette.GREEN if is_cleared else GamePalette.CYAN
	var glow := 0.15 + (sin(pulse * 2.2) + 1.0) * 0.055
	if is_hovered:
		color = Color.WHITE
		glow = 0.30
	var outer := PackedVector2Array([
		center + Vector2(0.0, -42.0),
		center + Vector2(82.0, 0.0),
		center + Vector2(0.0, 42.0),
		center + Vector2(-82.0, 0.0),
	])
	var inner := PackedVector2Array([
		center + Vector2(0.0, -32.0),
		center + Vector2(70.0, 0.0),
		center + Vector2(0.0, 32.0),
		center + Vector2(-70.0, 0.0),
		center + Vector2(0.0, -32.0),
	])
	draw_colored_polygon(outer, Color(color, glow * 0.35))
	draw_polyline(inner, Color(color, 0.92), 2.5, true)
	draw_circle(center, 5.0, Color(color, 0.48))
