extends SceneTree


func _initialize() -> void:
	call_deferred("_stage_capture")


func _stage_capture() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	await process_frame
	game.spawn_director.encounter_state = SpawnDirector.EncounterState.BOSS_ACTIVE
	game.spawn_enemy("boss")
	await process_frame
	for node: Node in get_nodes_in_group("enemies"):
		if node is NeonEnemy and node.kind == "boss":
			node.boss_state = "telegraph"
			node.boss_timer = 1.2
			node.boss_pattern_index = 0
			node.boss_locked_target = game.player.global_position
			node.boss_locked_direction = (game.player.global_position - node.global_position).normalized()
			break
	for _frame in 12:
		await process_frame
	quit(0)
