extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://main.tscn") as PackedScene
	assert(packed != null, "Main scene must load")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	assert(game.state == 0, "Game should boot to menu")
	game.start_run()
	await process_frame
	assert(game.state == 1, "Deploy should start a run")
	assert(is_instance_valid(game.player), "Player should spawn")
	assert(game.player.health > 0.0, "Player should have hull")
	game.spawn_enemy("drone", false)
	await physics_frame
	assert(get_nodes_in_group("enemies").size() >= 1, "Director should spawn enemies")
	var spawned_enemy: Node = get_nodes_in_group("enemies")[0]
	game.pause_game()
	assert(game.state == 3, "Pause should enter paused state")
	assert(spawned_enemy.process_mode == Node.PROCESS_MODE_DISABLED, "Pause should freeze all run entities")
	game.resume_game()
	assert(spawned_enemy.process_mode == Node.PROCESS_MODE_INHERIT, "Resume should restore entity processing")
	game.add_xp(28)
	await process_frame
	assert(game.run_level >= 2, "XP should increase run level")
	assert(game.state == 2, "Level-up should open an upgrade choice")
	while game.state == 2:
		game._select_upgrade("pulse_damage")
		await process_frame
	assert(game.state == 1, "Selecting upgrades should resume play")
	game._fire_nova()
	await process_frame
	print("SMOKE_OK menu, run, spawn, progression, and weapon systems initialized")
	quit(0)
