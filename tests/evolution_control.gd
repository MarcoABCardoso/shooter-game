extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	game.start_operation("signal_breach")
	await process_frame
	assert(game.objective_director.active and game.spawn_director.objective_driven, "Signal Breach should open with objective-driven Signal Defense")
	assert(game.arena_view.background.objective_visible, "Signal Defense should render a readable arena field")
	game.player.global_position = game.objective_director.world_position + Vector2(game.objective_director.radius + 20.0, 0.0)
	game.objective_director.tick(1.0)
	assert(game.objective_director.progress == 0.0, "Signal progress should not build while the player kites outside the field")
	game.player.global_position = game.objective_director.world_position
	game.objective_director.tick(1.0)
	assert(game.objective_director.progress > 0.0, "Holding the field should advance Signal Defense")
	assert(InputMap.has_action("cycle_target"), "Keyboard controls should register a target-mode cycle action")
	var base_damage := float(game.weapon_system.weapons["pulse"]["damage"])
	var base_speed := float(game.weapon_system.weapons["pulse"]["projectile_speed"])
	game.add_resonance(game.session.resonance_needed)
	await process_frame
	await process_frame
	assert(game.state == game.GameState.LEVEL_UP, "The first sparse breakpoint should pause for a transformation")
	assert(float(game.weapon_system.weapons["pulse"]["damage"]) > base_damage, "Resonance should apply automatic baseline growth before the choice")
	assert(float(game.weapon_system.weapons["pulse"]["projectile_speed"]) == base_speed, "Automatic operation growth should not inflate projectile speed")
	assert(game.ui.overlay.find_child("EvolutionChoice_bastion_array", true, false) != null, "The visible tree should offer the Sentinel branch")
	assert(game.ui.overlay.find_child("EvolutionChoice_scatter_array", true, false) != null, "The visible tree should offer the kiting Scatter branch")

	game._on_operation_evolution_selected("bastion_array")
	assert(game.state == game.GameState.RUNNING and game.session.has_operation_evolution("bastion_array"), "Committing Bastion should resume the operation")
	game.player.stationary_time = 0.0
	var uncharged_damage: float = game.weapon_system._scaled_damage("pulse", 10.0)
	var uncharged_range: float = game.weapon_system.pulse_range()
	game.player.stationary_time = 10.0
	assert(game.weapon_system._scaled_damage("pulse", 10.0) > uncharged_damage, "Holding position should charge Bastion damage")
	assert(game.weapon_system.pulse_range() > uncharged_range and game.weapon_system.pulse_knockback() > 0.0, "Holding position should charge Bastion range and knockback")

	game.spawn_enemy("drone", false)
	game.spawn_enemy("gunner", false)
	await process_frame
	var drone: NeonEnemy
	var gunner: NeonEnemy
	for enemy: NeonEnemy in game.combat_director.enemies:
		if enemy.kind == "gunner":
			gunner = enemy
		else:
			drone = enemy
	drone.global_position = game.player.global_position + Vector2(60.0, 0.0)
	gunner.global_position = game.player.global_position + Vector2(130.0, 0.0)
	var excluded: Array[int] = []
	assert(game.weapon_system.select_target(game.player.global_position, 200.0, excluded) == drone, "Nearest mode should prefer the closer Drone")
	assert(game.weapon_system.cycle_target_mode() == "RANGED THREATS", "One cycle should select ranged-threat priority")
	assert(game.weapon_system.select_target(game.player.global_position, 200.0, excluded) == gunner, "Ranged mode should prioritize a Gunner over a closer Drone")
	drone.health = gunner.health + 100.0
	assert(game.weapon_system.cycle_target_mode() == "HIGHEST HEALTH", "A second cycle should select highest-health priority")
	assert(game.weapon_system.select_target(game.player.global_position, 200.0, excluded) == drone, "Highest Health mode should ignore enemy family and select the toughest target")

	game.add_resonance(game.session.resonance_needed - game.session.resonance)
	await process_frame
	await process_frame
	assert(game.state == game.GameState.RUNNING and game.session.level == 3, "A non-breakpoint level should grow automatically without a prompt")
	game.add_resonance(game.session.resonance_needed - game.session.resonance)
	await process_frame
	await process_frame
	assert(game.state == game.GameState.LEVEL_UP, "The second visible breakpoint should pause combat")
	assert(game.ui.overlay.find_child("EvolutionChoice_gravity_well", true, false) != null, "Bastion should reveal Gravity Well")
	assert(game.ui.overlay.find_child("EvolutionChoice_phase_mooring", true, false) != null, "Bastion should reveal the Phase Dash interaction")
	assert(game.ui.overlay.find_child("EvolutionChoice_overrun_choke", true, false) == null, "The committed branch should hide incompatible Scatter follow-ups")
	game._on_operation_evolution_selected("phase_mooring")
	assert(game.player.preserve_stationary_on_dash, "Phase Mooring should make Phase Dash preserve Sentinel charge")

	game.start_operation("signal_breach")
	await process_frame
	game.add_resonance(game.session.resonance_needed)
	await process_frame
	await process_frame
	game._on_operation_evolution_selected("scatter_array")
	assert(int(game.weapon_system.weapons["pulse"]["count"]) == 5 and game.weapon_system.pulse_range() < 190.0, "Scatter should become a close-range five-shot weapon")
	game.player.velocity = Vector2.ZERO
	var still_interval: float = game.weapon_system.pulse_interval()
	var still_damage: float = game.weapon_system._scaled_damage("pulse", 10.0)
	game.player.velocity = Vector2(120.0, 0.0)
	assert(game.weapon_system.pulse_interval() < still_interval, "Moving should accelerate the Scatter firing cycle")
	assert(game.weapon_system._scaled_damage("pulse", 10.0) > still_damage, "Moving should increase Scatter damage")

	print("EVOLUTION_CONTROL_OK Signal Defense, automatic growth, two positioning builds, visible paths, and target modes validated")
	quit(0)
