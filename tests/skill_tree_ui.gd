extends SceneTree


func _initialize() -> void:
	call_deferred("_validate_skill_tree_ui")


func _validate_skill_tree_ui() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.profile.data["flux"] = 500
	game.profile.data["stage_clears"]["signal_hold"] = 1
	game.show_skill_tree()
	await process_frame

	var graph: SkillTreeView = game.ui.skill_tree_view
	assert(graph.get_node_or_null("SkillNode_core_damage") != null, "The root module should render")
	assert(graph.get_node_or_null("SkillNode_impact_vector") != null, "Mastery-gated modules should remain visible as progression milestones")
	assert(graph.get_node_or_null("SkillNode_arc_conduction") != null, "The full behavior-first prerequisite graph should remain visible")
	assert(graph.get_node_or_null("SkillDetailLayer") == null, "Details should stay hidden until a module is selected")
	var root_module := graph.get_node("SkillNode_core_damage") as Button
	root_module.pressed.emit()
	await process_frame

	var popup := graph.get_node_or_null("SkillDetailLayer/SkillDetailPopup")
	assert(popup != null, "Selecting a module should open its detail popup")
	var upgrade := popup.get_node_or_null("SkillUpgradeButton") as Button
	assert(upgrade != null and not upgrade.disabled, "An affordable available skill should expose its upgrade option")
	assert(upgrade.text.contains("RANK 01"), "The upgrade option should describe the next rank")
	var flux_before := int(game.profile.data["flux"])
	upgrade.pressed.emit()
	await process_frame
	await process_frame
	assert(game.profile.skill_rank("core_damage") == 1, "The popup upgrade action should purchase the selected rank")
	assert(int(game.profile.data["flux"]) < flux_before, "The popup upgrade action should spend Flux")
	popup = graph.get_node("SkillDetailLayer/SkillDetailPopup")
	upgrade = popup.get_node("SkillUpgradeButton") as Button
	assert(upgrade.text.contains("RANK 02"), "The open popup should refresh after a purchase")

	graph._close_detail()
	var locked_module := graph.get_node("SkillNode_impact_vector") as Button
	locked_module.pressed.emit()
	await process_frame
	popup = graph.get_node("SkillDetailLayer/SkillDetailPopup")
	upgrade = popup.get_node("SkillUpgradeButton") as Button
	assert(upgrade.disabled and upgrade.text.begins_with("LOCKED"), "Locked modules should explain that upgrades are unavailable")
	print("SKILL_TREE_UI_OK details popup, upgrade action, and locked state validated")
	quit(0)
