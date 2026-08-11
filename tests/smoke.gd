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
	assert(game.ui.title_screen.find_child("TitleCreditsPreviewButton", true, false) == null, "The main menu should not expose credits")
	game.ui.show_options()
	assert(game.ui.options_screen.visible, "Options should open independently")
	assert(game.ui.options_screen.find_child("MasterVolumeSlider", true, false) != null, "Options should expose master volume")
	assert(_contains_label(game.ui.options_screen, "WASD OR ARROW KEYS"), "Controls should live on the options screen")
	game.ui.show_save_slots(true, [
		{"slot": 1, "exists": false, "best_time": 0.0, "best_level": 1, "runs": 0, "flux": 0},
		{"slot": 2, "exists": false, "best_time": 0.0, "best_level": 1, "runs": 0, "flux": 0},
		{"slot": 3, "exists": false, "best_time": 0.0, "best_level": 1, "runs": 0, "flux": 0},
	])
	await process_frame
	assert(game.ui.save_slot_screen.find_child("SaveSlot3Button", true, false) != null, "New Game should offer three save slots")
	game.show_menu()
	assert(game.ui.hangar_screen.visible, "Selecting a profile should open the hangar")
	assert(game.ui.hangar_screen.find_child("UpgradesButton", true, false) == null, "The removed Augments feature must not remain in the hangar")
	assert(game.ui.hangar_screen.find_child("ResetProfileButton", true, false) != null, "Profile reset should remain available after Augments removal")
	assert(game.ui.hangar_screen.find_child("CreditsButton", true, false) == null, "The hangar should not retain a campaign-stage credits gate")
	game.show_credits()
	await process_frame
	assert(game.state == game.GameState.CREDITS and game.ui.credits_screen.visible, "The credits sequence should open for validation")
	assert(game.audio.current_music == &"credits", "The credits should play Zero Hour")
	var credits_view = game.ui.credits_screen
	assert(is_equal_approx(credits_view.CYCLE_DURATION * credits_view.ROLES.size() + credits_view.FINALE_DURATION, credits_view.CREDITS_TRACK_DURATION), "Cards and finale should exactly span Zero Hour")
	var credits_stream: AudioStreamOggVorbis = game.audio.MUSIC_TRACKS[&"credits"]
	assert(absf(credits_stream.get_length() - credits_view.CREDITS_TRACK_DURATION) < 0.01, "The credits timeline should match the actual Zero Hour asset")
	assert(not credits_stream.loop, "Zero Hour should finish instead of looping under the final card")
	assert(credits_view.ENEMY_SEQUENCE.size() == credits_view.ROLES.size(), "Every role should select its own pursuer variant")
	for enemy_index in credits_view.ENEMY_SEQUENCE.size() - 1:
		assert(credits_view.ENEMY_SEQUENCE[enemy_index] != credits_view.ENEMY_SEQUENCE[enemy_index + 1], "Consecutive cards should never repeat a pursuer")
	assert(credits_view._enemy_x_for_cycle(0.0) < 0.0, "Each pursuer should begin outside the left edge")
	credits_view.role_index = 0
	var boost_endpoint: float = credits_view._player_x_for_cycle(1.0)
	credits_view.role_index = 1
	assert(is_equal_approx(boost_endpoint, credits_view._player_x_for_cycle(0.0)), "The player should return from a boost without snapping between cards")
	credits_view.role_index = credits_view.ROLES.size() - 1
	credits_view.cycle_elapsed = credits_view.CYCLE_DURATION - 0.01
	credits_view._process(0.02)
	assert(credits_view.finale_active, "The final role should lead into the thank-you card")
	assert(not credits_view.names_label.visible, "The thank-you finale should have no pursuer credit block")
	game.ui.credits_screen.exit_requested.emit()
	await process_frame
	assert(game.ui.hangar_screen.visible, "Leaving the credits should return to the hangar")
	assert(game.ui.hangar_screen.find_child("DeployButton_signal_hold", true, false) != null, "The hangar should expose Signal Hold as its own stage")
	assert(game.ui.hangar_screen.find_child("DeployButton_relay_breach", true, false) != null, "The hangar should expose Relay Breach as its own stage")
	assert(game.ui.hangar_screen.find_child("DeployButton_overseer_lock", true, false) != null, "The hangar should expose Overseer Lock as its own stage")
	game.ui.hangar_screen.find_child("DeployButton_signal_hold", true, false).emit_signal("pressed")
	await process_frame
	assert(game.state == game.GameState.RUNNING and game.session.operation_id == "signal_hold", "Stage selection should deploy the chosen objective directly")
	assert(game.current_encounter_id == "defense_swarm", "Signal Hold should begin with its defense encounter")
	game.show_menu()
	game.show_loadout()
	await process_frame
	assert(game.ui.loadout_screen.visible, "Loadout should open independently")
	assert(game.ui.loadout_screen.find_child("LoadoutRow_pulse", true, false) != null, "Loadout should render weapon rows")
	assert(game.profile.is_discovered("pulse") and not game.profile.is_discovered("orbit") and not game.profile.is_discovered("arc") and not game.profile.is_discovered("nova"), "Only Pulse Cannon should be available initially")
	assert(game.profile.is_discovered("vector_parry"), "Vector Parry should be available as the third Chapter 1 configuration")
	assert(not game.ui.loadout_screen.find_child("AbilitySelect_vector_parry", true, false).disabled, "The loadout should allow selecting Vector Parry")
	game.ui.loadout_screen.find_child("AbilitySelect_vector_parry", true, false).emit_signal("pressed")
	assert(game.profile.equipped_ability() == "vector_parry", "The third configuration should be selectable before deployment")
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
	assert(game.ui.overlay.find_child("LibraryEntry_vector_parry", true, false) != null, "Library should render locked future equipment")
	game.show_menu()
	game.start_operation("signal_hold")
	await process_frame
	assert(game.state == 1, "Deploy should start a run")
	assert(is_instance_valid(game.player), "Player should spawn")
	assert(game.player.ability_mode == game.profile.equipped_ability(), "Deployment should use the equipped ability")
	game.player.set_mobile_controls_enabled(true)
	game.player.set_mobile_input(Vector2.UP)
	game.player._physics_process(1.0 / 60.0)
	assert(game.player.facing_direction.y < 0.0 and game.player.facing_direction.x > 0.0, "Movement should begin rotating the ship without snapping to the new direction")
	for _turn_frame in 60:
		game.player._physics_process(1.0 / 60.0)
	assert(game.player.facing_direction.dot(Vector2.UP) > 0.99, "The ship should smoothly settle on its movement direction")
	game.player.clear_mobile_input()
	game.player.set_mobile_controls_enabled(false)
	game.spawn_enemy("drone", false)
	await physics_frame
	assert(get_nodes_in_group("enemies").size() >= 1, "Director should spawn enemies")
	var spawned_enemy: NeonEnemy = get_nodes_in_group("enemies")[0]
	spawned_enemy.global_position = game.player.global_position - Vector2(500.0, 0.0)
	assert(not game.weapon_system.fire_pulse(), "Pulse Cannon should not acquire targets beyond its maximum range")
	spawned_enemy.global_position = game.player.global_position - Vector2(100.0, 0.0)
	var facing_before_fire: Vector2 = game.player.facing_direction
	assert(game.weapon_system.fire_pulse(), "Pulse Cannon should fire when an enemy is available")
	assert(game.player.facing_direction.is_equal_approx(facing_before_fire), "Automatic targeting must not rotate the player's ship")
	await physics_frame
	assert(spawned_enemy.facing_direction.dot(Vector2.RIGHT) > 0.99, "Enemies should face the player's center")
	game.spawn_enemy("gunner", false)
	await process_frame
	var gunner: NeonEnemy = null
	for enemy: NeonEnemy in game.combat_director.enemies:
		if is_instance_valid(enemy) and enemy.kind == "gunner":
			gunner = enemy
			break
	assert(gunner != null, "The test should spawn a gunner")
	gunner.global_position = game.player.global_position + Vector2(100.0, 0.0)
	var toward_player: Vector2 = (game.player.global_position - gunner.global_position).normalized()
	gunner._physics_process(1.0 / 60.0)
	assert(gunner.velocity.dot(toward_player) > 0.0, "Gunners should advance instead of retreating at close range")
	gunner.queue_free()
	await process_frame
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
	var pulse_damage_before := float(game.weapon_system.weapons["pulse"]["damage"])
	game.add_resonance(game.session.resonance_needed - game.session.resonance)
	await process_frame
	assert(game.session.level >= 2, "Resonance should increase run level")
	assert(game.state == game.GameState.LEVEL_UP, "The first sparse breakpoint should pause for a behavioral transformation")
	assert(game.ui.overlay.find_child("EvolutionChoice_bastion_array", true, false) != null, "The choice should expose the positioning-focused Bastion branch")
	assert(game.ui.overlay.find_child("EvolutionChoice_scatter_array", true, false) != null, "The choice should expose the kiting-focused Scatter branch")
	game._on_operation_evolution_selected("bastion_array")
	assert(game.state == game.GameState.RUNNING, "Choosing a stage evolution should resume combat")
	assert(float(game.weapon_system.weapons["pulse"]["damage"]) > pulse_damage_before, "Automatic level growth should raise Pulse damage")
	assert(game.session.has_operation_evolution("bastion_array"), "The run should track the selected behavioral branch")
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
	print("SMOKE_OK stage selection, sparse evolution, rewards, and combat flow validated")
	quit(0)


func _contains_label(root_node: Node, text_fragment: String) -> bool:
	for child: Node in root_node.find_children("*", "Label", true, false):
		if text_fragment in String(child.text):
			return true
	return false
