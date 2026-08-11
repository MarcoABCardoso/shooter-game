class_name SkillTreeView
extends Control

signal purchase_requested(id: String)

const NODE_SIZE := Vector2(74, 74)
const GRAPH_MARGIN := Vector2(76, 48)
const NODE_ICONS := {
	"core_damage": "✦",
	"distant_power": "◎",
	"anchored_power": "▣",
	"pulse_acceleration": "➤",
	"salvage_protocol": "◆",
	"impact_vector": "↗",
	"surrounded_power": "◉",
	"projectile_matrix": "●",
	"reinforced_core": "◇",
	"arc_overload": "↟",
	"orbit_overdrive": "◌",
	"splash_payload": "✹",
	"reactive_shield": "◈",
	"nova_reactor": "✦",
	"siege_posture_2": "▣",
	"volatile_radius": "◍",
	"emergency_cycle": "↻",
}

var profile: SaveProfile
var node_centers: Dictionary = {}
var node_buttons: Dictionary = {}
var selected_id := ""
var detail_layer: Control


func rebuild(save_profile: SaveProfile) -> void:
	profile = save_profile
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	node_centers.clear()
	node_buttons.clear()
	detail_layer = null
	for id: String in SkillTreeCatalog.ORDER:
		if _node_visible(id):
			_build_node(id)
	if not selected_id.is_empty() and SkillTreeCatalog.DEFINITIONS.has(selected_id) and _node_visible(selected_id):
		_build_detail_popup(selected_id)
	else:
		selected_id = ""
	queue_redraw()


func _build_node(id: String) -> void:
	var definition := SkillTreeCatalog.definition(id)
	var graph_position: Vector2 = definition["position"]
	var graph_span := size - GRAPH_MARGIN * 2.0
	var center := GRAPH_MARGIN + Vector2(graph_position.x * graph_span.x, graph_position.y * graph_span.y)
	var rank := profile.skill_rank(id)
	var max_rank := int(definition["max_rank"])
	var button := Button.new()
	button.name = "SkillNode_" + id
	button.text = String(NODE_ICONS.get(id, "◆"))
	button.position = center - NODE_SIZE * 0.5
	button.size = NODE_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.tooltip_text = "%s — %s" % [definition["name"], _node_status(id)]
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", _node_color(id))
	button.add_theme_color_override("font_hover_color", GamePalette.WHITE)
	button.add_theme_color_override("font_pressed_color", GamePalette.WHITE)
	button.add_theme_stylebox_override("normal", _node_style(id, false))
	button.add_theme_stylebox_override("hover", _node_style(id, true))
	button.add_theme_stylebox_override("pressed", _node_style(id, true))
	button.add_theme_stylebox_override("focus", _focus_style(id))
	button.pressed.connect(_open_detail.bind(id))
	add_child(button)
	node_centers[id] = center
	node_buttons[id] = button
	button.set_meta("rank", rank)
	button.set_meta("max_rank", max_rank)


func _draw() -> void:
	if profile == null:
		return
	for id: String in SkillTreeCatalog.ORDER:
		if not node_centers.has(id):
			continue
		var requirements: Dictionary = SkillTreeCatalog.definition(id).get("requires", {})
		for parent_id: String in requirements:
			if not node_centers.has(parent_id):
				continue
			var active := profile.skill_rank(parent_id) >= int(requirements[parent_id])
			var color := Color(GamePalette.GREEN, 0.76) if active else Color(GamePalette.CYAN, 0.16)
			var from: Vector2 = node_centers[parent_id]
			var to: Vector2 = node_centers[id]
			draw_line(from, to, Color(GamePalette.BACKGROUND, 0.9), 9.0, true)
			draw_line(from, to, color, 3.0, true)
	for id: String in SkillTreeCatalog.ORDER:
		if not node_centers.has(id):
			continue
		_draw_rank_pips(id)


func _draw_rank_pips(id: String) -> void:
	var definition := SkillTreeCatalog.definition(id)
	var rank := profile.skill_rank(id)
	var max_rank := int(definition["max_rank"])
	var center: Vector2 = node_centers[id]
	var spacing := 10.0
	var start_x := center.x - (max_rank - 1) * spacing * 0.5
	for index in max_rank:
		var pip_color := _node_color(id) if index < rank else Color(GamePalette.CYAN, 0.2)
		draw_circle(Vector2(start_x + index * spacing, center.y + 47.0), 3.0, pip_color, true)


func _open_detail(id: String) -> void:
	selected_id = id
	if is_instance_valid(detail_layer):
		remove_child(detail_layer)
		detail_layer.queue_free()
	_build_detail_popup(id)
	queue_redraw()


func _close_detail() -> void:
	selected_id = ""
	if is_instance_valid(detail_layer):
		remove_child(detail_layer)
		detail_layer.queue_free()
	detail_layer = null
	queue_redraw()


func _build_detail_popup(id: String) -> void:
	var definition := SkillTreeCatalog.definition(id)
	var rank := profile.skill_rank(id)
	var max_rank := int(definition["max_rank"])
	detail_layer = Control.new()
	detail_layer.name = "SkillDetailLayer"
	detail_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_layer.z_index = 20
	add_child(detail_layer)

	var dismiss := Button.new()
	dismiss.name = "SkillDetailDismiss"
	dismiss.flat = true
	dismiss.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dismiss.add_theme_stylebox_override("normal", _flat_style(Color(0.005, 0.015, 0.04, 0.88)))
	dismiss.add_theme_stylebox_override("hover", _flat_style(Color(0.005, 0.015, 0.04, 0.9)))
	dismiss.add_theme_stylebox_override("pressed", _flat_style(Color(0.005, 0.015, 0.04, 0.92)))
	dismiss.pressed.connect(_close_detail)
	detail_layer.add_child(dismiss)

	var panel_size := Vector2(586, 390)
	var panel := UIFactory.panel((size - panel_size) * 0.5, panel_size, Color(_node_color(id), 0.78))
	panel.name = "SkillDetailPopup"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_layer.add_child(panel)

	var eyebrow := UIFactory.label(_node_status(id), 10, Color(_node_color(id), 0.72))
	eyebrow.position = Vector2(30, 22)
	eyebrow.size = Vector2(460, 20)
	panel.add_child(eyebrow)

	var title := UIFactory.label(String(definition["name"]), 25, _node_color(id))
	title.position = Vector2(28, 42)
	title.size = Vector2(475, 38)
	panel.add_child(title)

	var close := UIFactory.button("×", Vector2(522, 18), Vector2(42, 42))
	close.name = "SkillDetailClose"
	close.tooltip_text = "Close skill details"
	close.pressed.connect(_close_detail)
	panel.add_child(close)

	var rank_caption := UIFactory.label("RANK %02d OF %02d" % [rank, max_rank], 14, GamePalette.YELLOW)
	rank_caption.position = Vector2(30, 88)
	rank_caption.size = Vector2(180, 24)
	panel.add_child(rank_caption)

	var pips := UIFactory.label(_rank_bar(rank, max_rank), 17, _node_color(id))
	pips.position = Vector2(384, 85)
	pips.size = Vector2(150, 28)
	pips.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(pips)

	var divider := ColorRect.new()
	divider.position = Vector2(30, 120)
	divider.size = Vector2(526, 2)
	divider.color = Color(_node_color(id), 0.24)
	panel.add_child(divider)

	var effect_title := UIFactory.label("EFFECT PER RANK", 10, Color(GamePalette.CYAN, 0.58))
	effect_title.position = Vector2(30, 139)
	panel.add_child(effect_title)
	var effect := UIFactory.label(String(definition["description"]), 16, GamePalette.WHITE)
	effect.position = Vector2(30, 158)
	effect.size = Vector2(526, 50)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(effect)

	var current_title := UIFactory.label("TOTAL EFFECT", 10, Color(GamePalette.GREEN, 0.58))
	current_title.position = Vector2(30, 218)
	panel.add_child(current_title)
	var current := UIFactory.label(_total_effect_text(id, rank), 15, GamePalette.GREEN)
	current.position = Vector2(30, 237)
	current.size = Vector2(240, 26)
	panel.add_child(current)

	var gate_title := UIFactory.label("ACCESS", 10, Color(GamePalette.MAGENTA, 0.62))
	gate_title.position = Vector2(286, 218)
	panel.add_child(gate_title)
	var gate := UIFactory.label(_requirement_text(id), 12, Color(GamePalette.CYAN, 0.82))
	gate.position = Vector2(286, 237)
	gate.size = Vector2(270, 48)
	gate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(gate)

	var upgrade_text := _upgrade_button_text(id, rank, max_rank)
	var upgrade := UIFactory.button(upgrade_text, Vector2(30, 307), Vector2(526, 58))
	upgrade.name = "SkillUpgradeButton"
	upgrade.disabled = not _can_purchase(id)
	upgrade.add_theme_font_size_override("font_size", 15)
	upgrade.pressed.connect(purchase_requested.emit.bind(id))
	panel.add_child(upgrade)


func _node_status(id: String) -> String:
	var definition := SkillTreeCatalog.definition(id)
	var rank := profile.skill_rank(id)
	if rank >= int(definition["max_rank"]):
		return "MAXIMUM RANK"
	if rank > 0:
		return "ACTIVE"
	if profile.skill_available(id):
		return "AVAILABLE"
	return "LOCKED"


func _node_visible(id: String) -> bool:
	return SkillTreeCatalog.DEFINITIONS.has(id)


func _node_color(id: String) -> Color:
	var status := _node_status(id)
	if status == "MAXIMUM RANK":
		return GamePalette.YELLOW
	if status == "ACTIVE":
		return GamePalette.GREEN
	if status == "AVAILABLE":
		return GamePalette.CYAN
	return Color(GamePalette.MAGENTA, 0.58)


func _node_style(id: String, hovered: bool) -> StyleBoxFlat:
	var color := _node_color(id)
	var background := Color(GamePalette.INK, 0.98)
	if hovered:
		background = Color(color, 0.18)
	elif profile.skill_rank(id) > 0:
		background = Color(color, 0.1)
	var style := UIFactory.style(background, Color(color, 0.95 if hovered else 0.62), 3, 37)
	style.shadow_color = Color(color, 0.24 if hovered else 0.12)
	style.shadow_size = 16 if hovered else 10
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _focus_style(id: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(_node_color(id), 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(41)
	style.expand_margin_left = 5
	style.expand_margin_right = 5
	style.expand_margin_top = 5
	style.expand_margin_bottom = 5
	return style


func _flat_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style


func _can_purchase(id: String) -> bool:
	return profile.skill_available(id) and int(profile.data["flux"]) >= profile.skill_cost(id)


func _upgrade_button_text(id: String, rank: int, max_rank: int) -> String:
	if rank >= max_rank:
		return "MAXIMUM RANK"
	if not profile.skill_available(id):
		return "LOCKED\nREQUIREMENTS NOT MET"
	var cost := profile.skill_cost(id)
	if int(profile.data["flux"]) < cost:
		return "INSUFFICIENT FLUX\n%d REQUIRED" % cost
	return "UPGRADE TO RANK %02d\n%d FLUX" % [rank + 1, cost]


func _requirement_text(id: String) -> String:
	var definition := SkillTreeCatalog.definition(id)
	var requirements: Array[String] = []
	var nodes: Dictionary = definition.get("requires", {})
	for node_id: String in nodes:
		if profile.skill_rank(node_id) < int(nodes[node_id]):
			requirements.append("%s RANK %d" % [String(SkillTreeCatalog.definition(node_id)["name"]), int(nodes[node_id])])
	var mastery: Dictionary = definition.get("mastery", {})
	for item: String in mastery:
		if profile.mastery_level(item) < int(mastery[item]):
			requirements.append("%s MASTERY %d" % [item.to_upper(), int(mastery[item])])
	return "ALL REQUIREMENTS MET" if requirements.is_empty() else "\n".join(requirements)


func _rank_bar(rank: int, max_rank: int) -> String:
	var segments: Array[String] = []
	for index in max_rank:
		segments.append("●" if index < rank else "○")
	return " ".join(segments)


func _total_effect_text(id: String, rank: int) -> String:
	var definition := SkillTreeCatalog.definition(id)
	var value := float(definition.get("value", 0.0)) * rank
	var effect := String(definition.get("effect", ""))
	if effect in ["knockback", "hull", "shield"]:
		var labels := {"knockback": "KNOCKBACK", "hull": "MAXIMUM HULL", "shield": "SHIELD CHARGES"}
		return "+%d %s" % [int(value), String(labels[effect])]
	return "+%d%% %s" % [int(roundf(value * 100.0)), effect.replace("_", " ").to_upper()]
