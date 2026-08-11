extends SceneTree

const OperationCatalog := preload("res://scripts/content/operation_catalog.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	game.show_menu()
	game.ui.hangar_screen.find_child("DeployButton_signal_hold", true, false).emit_signal("pressed")
	await process_frame
	assert(game.state == game.GameState.RUNNING, "A selected stage should begin in combat")
	assert(game.session.operation_id == "signal_hold", "Stage selection should preserve the chosen content identity")
	assert(game.current_encounter_id == "defense_swarm", "Signal Hold should enter its defense encounter")
	assert(_contains_label(game.ui.hud, "STAGE — HOLD THE SIGNAL"), "The HUD should identify the focused stage instead of mission-chain progress")
	assert(_contains_label(game.ui.hud, "TIME 00:45"), "The HUD should show the mission deadline")
	game.session.flux = 123
	game.session.record_mastery("pulse", 12.0)

	_complete_current_stage(game)
	assert(game.state == game.GameState.STAGE_CLEAR, "Signal Hold should end and bank independently")
	assert(int(game.profile.data["flux"]) == 123, "A cleared stage should bank its Flux immediately")
	assert(float(game.profile.data["mastery_xp"]["pulse"]) == 12.0, "A cleared stage should bank earned mastery")

	game.show_menu()
	game.ui.hangar_screen.find_child("DeployButton_relay_breach", true, false).emit_signal("pressed")
	await process_frame
	assert(game.session.operation_id == "relay_breach" and game.current_encounter_id == "relay_breach", "Relay Breach should deploy independently from the hangar")
	assert(game.session.flux == 0 and game.session.level == 1 and game.session.operation_evolutions.is_empty(), "A new stage should reset run rewards and evolution commitments")
	assert(game.objective_director.lifecycle == "relay_breach" and game.objective_director.remaining_relays.size() == 3, "The Breach should begin with three objective targets")
	assert(game.arena_view.background.relay_positions.size() == 3, "The arena should render the linked relay rule")
	assert(game.audio.current_music == &"breach", "The Breach should have its own representative music")
	var relays: Array[NeonEnemy] = []
	for enemy: NeonEnemy in game.combat_director.enemies:
		if enemy.kind == "relay":
			relays.append(enemy)
	assert(relays.size() == 3, "The objective should request three fixed relay entities through CombatDirector")
	var relay_position := relays[0].global_position
	relays[0].apply_knockback(game.player.global_position, 999.0)
	relays[0]._physics_process(0.1)
	assert(relays[0].global_position.is_equal_approx(relay_position), "Relay objectives should remain fixed to their arena markers")
	game.combat_director.objective_target_defeated.emit(0)
	assert(game.objective_director.remaining_relays == [1, 2], "Objective target defeats should advance the relay network through the composition root")

	_complete_current_stage(game)
	assert(game.state == game.GameState.STAGE_CLEAR, "Relay Breach should clear without a continue/intermission step")

	game.show_menu()
	assert(game.profile.equip_ability("vector_parry"), "The hangar interval should permit build reconfiguration")
	game.ui.hangar_screen.find_child("DeployButton_overseer_lock", true, false).emit_signal("pressed")
	await process_frame
	assert(game.session.operation_id == "overseer_lock" and game.current_encounter_id == "overseer_lock", "Overseer Lock should deploy as its own stage")
	assert(game.player.ability_mode == "vector_parry", "The boss stage should use the newly optimized hangar loadout")
	_complete_current_stage(game)
	await process_frame
	assert(game.state == game.GameState.STAGE_CLEAR, "Defeating the Overseer should clear only its selected stage")

	game.start_operation("signal_hold")
	game.session.flux = 101
	game._retreat_operation()
	assert(game.state == game.GameState.GAME_OVER, "Retreat should end the active stage")
	assert(int(game.profile.data["flux"]) == 198, "Retreat should bank 75% of earned Flux, rounded down")

	game.start_operation("overseer_lock")
	game.session.flux = 9
	game._end_operation(false, true)
	assert(game.state == game.GameState.GAME_OVER, "Defeat should end the active stage")
	assert(int(game.profile.data["flux"]) == 202, "Defeat should bank only half of earned Flux")

	game.start_operation("signal_hold")
	var opening_mission := OperationCatalog.mission("signal_hold")
	game.session.mission_elapsed = float(opening_mission["time_limit"]) - 0.01
	game._physics_process(0.02)
	assert(game.state == game.GameState.GAME_OVER, "Exceeding a stage deadline should prevent farming")
	print("OPERATION_SPINE_OK separate stage selection, build reconfiguration, objectives, and rewards validated")
	quit(0)


func _complete_current_stage(game: Node) -> void:
	if game.objective_director.lifecycle == "signal_defense":
		game.player.global_position = game.objective_director.world_position
		game.session.tick(game.objective_director.hold_duration + 0.01)
		game.objective_director.tick(game.objective_director.hold_duration + 0.01)
		return
	if game.objective_director.lifecycle == "relay_breach":
		for relay_index in game.objective_director.remaining_relays.duplicate():
			game.objective_director.register_objective_target_defeated(relay_index)
		return
	var duration := float(game.spawn_director.encounter_spec["duration"])
	game.session.mission_elapsed = duration
	game.spawn_director.tick(0.01)
	game.spawn_director.tick(GameBalance.BOSS_INTRO_DURATION + 0.01)
	if bool(game.spawn_director.encounter_spec["boss"]):
		game._on_boss_defeated()


func _contains_label(root_node: Node, text_fragment: String) -> bool:
	for child: Node in root_node.find_children("*", "Label", true, false):
		if text_fragment in String(child.text):
			return true
	return false
