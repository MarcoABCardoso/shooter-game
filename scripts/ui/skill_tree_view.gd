class_name SkillTreeView
extends Control

signal purchase_requested(id: String)

var profile: SaveProfile
var node_centers: Dictionary = {}


func rebuild(save_profile: SaveProfile) -> void:
	profile = save_profile
	for child: Node in get_children():
		child.queue_free()
	node_centers.clear()
	for id: String in SkillTreeCatalog.ORDER:
		var definition := SkillTreeCatalog.definition(id)
		var graph_position: Vector2 = definition["position"]
		var position_px := Vector2(8.0 + graph_position.x * 682.0, graph_position.y * 342.0)
		var button := UIFactory.button(_node_text(id), position_px, Vector2(178, 78))
		button.name = "SkillNode_" + id
		button.add_theme_font_size_override("font_size", 11)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not _can_purchase(id)
		button.tooltip_text = _requirement_text(id)
		button.pressed.connect(purchase_requested.emit.bind(id))
		add_child(button)
		node_centers[id] = position_px + Vector2(89, 39)
	queue_redraw()


func _draw() -> void:
	for id: String in SkillTreeCatalog.ORDER:
		if not node_centers.has(id):
			continue
		var requirements: Dictionary = SkillTreeCatalog.definition(id).get("requires", {})
		for parent_id: String in requirements:
			if not node_centers.has(parent_id):
				continue
			var active := profile != null and profile.skill_rank(parent_id) >= int(requirements[parent_id])
			var color := Color(GamePalette.GREEN, 0.72) if active else Color(GamePalette.CYAN, 0.20)
			draw_line(node_centers[parent_id], node_centers[id], color, 3.0, true)


func _node_text(id: String) -> String:
	var definition := SkillTreeCatalog.definition(id)
	var rank := profile.skill_rank(id)
	var max_rank := int(definition["max_rank"])
	var footer: String
	if rank >= max_rank:
		footer = "MAXED"
	elif profile.skill_available(id):
		footer = "◆ %d" % profile.skill_cost(id)
	else:
		footer = _requirement_text(id)
	return "%s\n%s\n%d/%d  //  %s" % [definition["name"], definition["description"], rank, max_rank, footer]


func _can_purchase(id: String) -> bool:
	return profile.skill_available(id) and int(profile.data["flux"]) >= profile.skill_cost(id)


func _requirement_text(id: String) -> String:
	var definition := SkillTreeCatalog.definition(id)
	var requirements: Array[String] = []
	var stage := String(definition.get("stage", ""))
	if not stage.is_empty() and not profile.stage_cleared(stage):
		requirements.append(stage.replace("_", " ").to_upper() + " CLEAR")
	var nodes: Dictionary = definition.get("requires", {})
	for node_id: String in nodes:
		if profile.skill_rank(node_id) < int(nodes[node_id]):
			requirements.append("%s %d" % [String(SkillTreeCatalog.definition(node_id)["name"]), int(nodes[node_id])])
	var mastery: Dictionary = definition.get("mastery", {})
	for item: String in mastery:
		if profile.mastery_level(item) < int(mastery[item]):
			requirements.append("%s M%d" % [item.to_upper(), int(mastery[item])])
	return "LOCKED: " + ", ".join(requirements) if not requirements.is_empty() else "AVAILABLE"
