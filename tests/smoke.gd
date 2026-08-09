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
	assert(game.ui.title_screen.visible, "Game should boot to the title screen")
	assert(not game.ui.hangar_screen.visible, "Hangar should remain hidden until a save is selected")
	assert(game.ui.title_screen.find_child("NewGameButton", true, false) != null, "Title screen should offer New Game")
	assert(game.ui.title_screen.find_child("LoadGameButton", true, false) != null, "Title screen should offer Load Game")
	assert(game.ui.title_screen.find_child("OptionsButton", true, false) != null, "Title screen should offer Options")
	game.ui.show_options()
	assert(game.ui.options_screen.visible, "Options should open independently")
	assert(_contains_label(game.ui.options_screen, "WASD / ARROW KEYS"), "Controls should live on the options screen")
	game.ui.show_save_slots(true, [
		{"slot": 1, "exists": false, "best_time": 0.0, "best_level": 1, "runs": 0, "flux": 0},
		{"slot": 2, "exists": false, "best_time": 0.0, "best_level": 1, "runs": 0, "flux": 0},
		{"slot": 3, "exists": false, "best_time": 0.0, "best_level": 1, "runs": 0, "flux": 0},
	])
	await process_frame
	assert(game.ui.save_slot_screen.find_child("SaveSlot3Button", true, false) != null, "New Game should offer three save slots")
	game.show_menu()
	assert(game.ui.hangar_screen.visible, "Selecting a profile should open the hangar")
	assert(not _contains_label(game.ui.hangar_screen, "NEON REQUIEM"), "Hangar should not repeat the game title")
	assert(not _contains_label(game.ui.hangar_screen, "WASD / ARROWS"), "Hangar should not display controls")
	assert(not game.ui.upgrade_screen.visible, "Upgrade screen should be separate from the start screen")
	game.show_upgrades()
	await process_frame
	assert(game.ui.upgrade_screen.visible, "Upgrade screen should open independently")
	assert(not game.ui.hangar_screen.visible, "Hangar should hide behind upgrades")
	game.show_menu()
	game.show_loadout()
	await process_frame
	assert(game.ui.loadout_screen.visible, "Loadout should open independently")
	assert(game.ui.loadout_screen.find_child("LoadoutRow_pulse", true, false) != null, "Loadout should render weapon rows")
	assert(game.profile.is_discovered("pulse") and game.profile.is_discovered("orbit") and game.profile.is_discovered("arc"), "Three weapons should be available initially")
	assert(game.profile.equipped_weapons() == ["pulse"], "A new profile should begin with one Pulse slot")
	game.show_menu()
	game.show_skill_tree()
	await process_frame
	assert(game.ui.skill_tree_screen.visible, "Skill tree should open from the hangar")
	assert(game.ui.skill_tree_screen.find_child("SkillNode_core_damage", true, false) != null, "Skill graph should render its root node")
	game.show_menu()
	game._show_library()
	await process_frame
	assert(game.ui.overlay.visible, "Arsenal library should open from the hangar")
	assert(game.ui.overlay.find_child("LibraryEntry_pulse", true, false) != null, "Library should render weapon entries")
	assert(game.ui.overlay.find_child("LibraryEntry_dash", true, false) != null, "Library should render ability entries")
	assert(game.ui.overlay.find_child("LibraryEntry_vector_parry", true, false) != null, "Library should render the Stage 1 reward")
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
	var pulse_damage_before := float(game.weapons["pulse"]["damage"])
	game.add_resonance(game.session.resonance_needed - game.session.resonance)
	await process_frame
	assert(game.run_level >= 2, "Resonance should increase run level")
	assert(game.state == game.GameState.LEVEL_UP, "A resonance level should pause for a deterministic weapon choice")
	assert(game.ui.overlay.find_child("RunUpgrade_pulse_damage", true, false) != null, "The choice should expose Pulse damage")
	assert(game.ui.overlay.find_child("RunUpgrade_pulse_fire_rate", true, false) != null, "The choice should expose Pulse fire rate")
	assert(game.ui.overlay.find_child("RunUpgrade_pulse_projectile_speed", true, false) != null, "The choice should expose Pulse projectile speed")
	game._on_run_upgrade_selected("pulse", "damage")
	assert(game.state == game.GameState.RUNNING, "Choosing an evolution should resume combat")
	assert(float(game.weapons["pulse"]["damage"]) > pulse_damage_before, "The chosen dimension should mutate only the run weapon")
	assert(game.session.weapon_upgrade_rank("pulse", "damage") == 1, "The run should track the selected capped rank")
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
	print("SMOKE_OK hangar build, deterministic resonance choice, run evolution, rewards, and combat flow validated")
	quit(0)


func _contains_label(root_node: Node, text_fragment: String) -> bool:
	for child: Node in root_node.find_children("*", "Label", true, false):
		if text_fragment in String(child.text):
			return true
	return false
