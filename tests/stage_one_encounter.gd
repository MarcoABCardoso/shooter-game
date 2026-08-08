extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://main.tscn") as PackedScene
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_run()
	await process_frame
	game.spawn_enemy("drone")
	await physics_frame
	var crowd: NeonEnemy = get_nodes_in_group("enemies")[0]
	game.session.elapsed = GameBalance.STAGE_1_DURATION
	game.spawn_director.tick(0.01)
	await process_frame
	assert(game.spawn_director.encounter_state == SpawnDirector.EncounterState.BOSS_INTRO, "Stage timer should start the boss entrance")
	assert(crowd.dispersing and not crowd.active, "The existing swarm should disperse harmlessly")
	game.spawn_director.tick(GameBalance.BOSS_INTRO_DURATION + 0.01)
	await process_frame
	var boss: NeonEnemy = null
	for node: Node in get_nodes_in_group("enemies"):
		if node is NeonEnemy and node.kind == "boss":
			boss = node
	assert(boss != null, "The Overseer Array should enter after the evacuation")
	assert(boss.boss_modules == 3, "The Overseer should begin with three connected modules")
	game.combat_director.spawn_projectile(game.player.global_position + Vector2(40.0, 0.0), Vector2.LEFT, 10.0, 180.0, false, "enemy")
	await process_frame
	var hostile: NeonProjectile = get_nodes_in_group("enemy_projectiles")[0]
	game.combat_director.parry_projectiles(game.player.global_position, Vector2.RIGHT)
	assert(hostile.friendly and hostile.weapon == "parry", "Vector Parry should return projectiles as friendly counterfire")
	assert(not hostile.is_in_group("enemy_projectiles"), "Reflected shots should leave the hostile projectile group")
	boss.boss_exposed = true
	boss.take_damage(boss.health, "pulse")
	await process_frame
	await process_frame
	assert(game.state == game.GameState.STAGE_CLEAR, "Defeating the Overseer should complete Stage 1")
	assert(game.profile.is_discovered("vector_parry"), "Stage clear should decode Vector Parry")
	game._on_ability_selected("vector_parry")
	assert(game.profile.equipped_ability() == "vector_parry", "The reward should equip into the Space ability slot")
	print("STAGE_ONE_OK evacuation, modular boss, stage clear, and reward selection validated")
	quit(0)
