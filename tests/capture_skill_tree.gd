extends SceneTree


func _initialize() -> void:
	call_deferred("_stage_capture")


func _stage_capture() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.profile.data["flux"] = 850
	game.profile.data["skill_ranks"]["core_damage"] = 2
	game.profile.data["skill_ranks"]["distant_power"] = 1
	game.show_skill_tree()
	for _frame in 8:
		await process_frame
	var graph_image := root.get_texture().get_image()
	graph_image.save_png("res://builds/skill_tree_graph_capture.png")
	var root_module := game.ui.skill_tree_view.get_node("SkillNode_core_damage") as Button
	root_module.pressed.emit()
	for _frame in 8:
		await process_frame
	var image := root.get_texture().get_image()
	image.save_png("res://builds/skill_tree_capture.png")
	quit(0)
