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
	assert(game.ui.start_screen.visible, "Game should boot to the start screen")
	assert(not game.ui.upgrade_screen.visible, "Upgrade screen should be separate from the start screen")
	game.show_upgrades()
	await process_frame
	assert(game.ui.upgrade_screen.visible, "Upgrade screen should open independently")
	assert(not game.ui.start_screen.visible, "Start screen should hide behind upgrades")
	game.show_menu()
	game.show_callibrations()
	await process_frame
	assert(game.ui.callibrations_screen.visible, "Callibrations should open independently")
	assert(game.ui.callibrations_screen.find_child("CallibrationRow_pulse", true, false) != null, "Callibrations should render weapon allocation rows")
	game.show_menu()
	game._show_library()
	await process_frame
	assert(game.ui.overlay.visible, "Arsenal library should open from the hangar")
	assert(game.ui.overlay.find_child("LibraryEntry_pulse", true, false) != null, "Library should render weapon entries")
	assert(game.ui.overlay.find_child("LibraryEntry_dash", true, false) != null, "Library should render ability entries")
	assert(game.ui.overlay.find_child("LibraryEntry_vector_parry", true, false) != null, "Library should render the Stage 1 reward")
	assert(game.ui.overlay.find_child("LibraryEntry_roaming_distant_focus", true, false) != null, "Library should render in-run evolution entries")
	game.show_menu()
	game.start_run()
	await process_frame
	assert(game.state == 1, "Deploy should start a run")
	assert(is_instance_valid(game.player), "Player should spawn")
	assert(game.player.health > 0.0, "Player should have hull")
	assert(game.player.ability_mode == game.profile.equipped_ability(), "Deployment should use the equipped ability")
	game.spawn_enemy("drone", false)
	await physics_frame
	assert(get_nodes_in_group("enemies").size() >= 1, "Director should spawn enemies")
	var spawned_enemy: NeonEnemy = get_nodes_in_group("enemies")[0]
	assert(game.player.collision_mask == 8, "Player movement should only collide with hostile projectiles")
	assert(spawned_enemy.collision_mask == 0, "Enemies should not physically pin the player")
	spawned_enemy.global_position = game.player.global_position - Vector2(100.0, 0.0)
	await physics_frame
	assert(spawned_enemy.facing_direction.dot(Vector2.RIGHT) > 0.99, "Enemies should face the player's center")
	game.pause_game()
	assert(game.state == 2, "Pause should enter paused state")
	assert(spawned_enemy.process_mode == Node.PROCESS_MODE_DISABLED, "Pause should freeze all run entities")
	game.resume_game()
	assert(spawned_enemy.process_mode == Node.PROCESS_MODE_INHERIT, "Resume should restore entity processing")
	var resonance_before_kill: int = game.session.resonance
	var flux_before_kill: int = game.session.flux
	game.combat_director.spawn_projectile(spawned_enemy.global_position - Vector2(24.0, 0.0), Vector2.RIGHT, 99999.0, 500.0, true, "pulse")
	for _frame in 10:
		await physics_frame
		if not is_instance_valid(spawned_enemy):
			break
	await process_frame
	assert(not is_instance_valid(spawned_enemy), "Projectile should destroy the test enemy through a physics callback")
	assert(game.session.resonance == resonance_before_kill + 5, "Kills should grant resonance immediately")
	assert(game.session.flux > flux_before_kill, "Kills should grant Flux immediately")
	game.add_resonance(game.session.resonance_needed - game.session.resonance)
	await process_frame
	assert(game.run_level >= 2, "Resonance should increase run level")
	assert(game.state == 1, "Evolution should not interrupt combat")
	assert(not game.session.evolutions.is_empty(), "Combat behavior should produce an automatic evolution")
	assert(game.profile.is_discovered(game.session.last_evolution), "Triggered evolutions should be decoded in the Library")
	game._fire_nova()
	await process_frame
	var run_player: NeonPlayer = game.player
	run_player.invulnerable = 0.0
	game.combat_director.spawn_projectile(run_player.global_position - Vector2(24.0, 0.0), Vector2.RIGHT, 99999.0, 500.0, false, "enemy")
	for _frame in 10:
		await physics_frame
		if game.state == 3:
			break
	await process_frame
	assert(game.state == 3, "Projectile death should end the run after the physics callback")
	assert(run_player.process_mode == Node.PROCESS_MODE_DISABLED, "Deferred run teardown should freeze collision objects safely")
	print("SMOKE_OK menu, run, direct rewards, deferred physics teardown, behavior evolution, and weapons initialized")
	quit(0)
