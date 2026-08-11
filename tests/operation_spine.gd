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
	game.ui.hangar_screen.find_child("DeployButton", true, false).emit_signal("pressed")
	await process_frame
	assert(game.state == game.GameState.RUNNING, "An operation should begin in combat")
	assert(game.session.operation_id == "signal_breach" and game.session.mission_index == 0, "Operation state should begin at the first mission")
	assert(game.current_encounter_id == "defense_swarm", "Deploy should enter Signal Breach's operation-owned defense encounter")
	assert(_contains_label(game.ui.hud, "MISSION 1/3"), "The HUD should identify operation mission progress")
	game.session.flux = 123
	game.session.record_mastery("pulse", 12.0)
	game.player.health = 70.0

	_complete_current_mission(game)
	assert(game.state == game.GameState.INTERMISSION, "The first mission should lead to an intermission")
	assert(not game.arena_view.background.objective_visible, "The Signal Defense field should clear during intermission")
	assert(game.session.completed_missions == 1, "The operation should record completed missions")
	assert(int(game.profile.data["flux"]) == 0, "Operation rewards should stay at risk during intermissions")
	assert(_contains_label(game.ui.overlay, "75% of earned Flux"), "The intermission should explain the safer retreat recovery")
	game._continue_operation()
	assert(game.state == game.GameState.RUNNING and game.session.mission_index == 1, "Continue should start the next connected mission")
	assert(game.current_encounter_id == "striker_assault" and game.session.mission_elapsed == 0.0, "The second mission should reset only the mission clock")
	assert(game.session.flux == 123 and game.session.elapsed > 0.0, "Operation rewards and total time should carry between missions")
	assert(game.player.health == game.player.max_health, "Intermissions should fully repair hull")

	_complete_current_mission(game)
	game._continue_operation()
	assert(game.session.mission_index == 2 and game.current_encounter_id == "gunner_assault", "The final mission should expose Gunners for targeting comparisons")
	_complete_current_mission(game)
	assert(game.state == game.GameState.OPERATION_CLEAR, "Completing all three missions should clear the operation")
	assert(game.session.completed_missions == 3, "All connected missions should be reflected in the final result")
	assert(int(game.profile.data["flux"]) == 123, "A completed operation should bank all earned Flux")
	assert(float(game.profile.data["mastery_xp"]["pulse"]) == 12.0, "A completed operation should bank earned mastery")

	game.start_operation("signal_breach")
	game.session.flux = 101
	_complete_current_mission(game)
	game._retreat_operation()
	assert(game.state == game.GameState.GAME_OVER, "Retreat should end the active operation")
	assert(int(game.profile.data["flux"]) == 198, "Retreat should bank 75% of earned Flux, rounded down")

	game.start_operation("signal_breach")
	game.session.flux = 9
	game._end_operation(false, true)
	assert(game.state == game.GameState.GAME_OVER, "Defeat should end the active operation")
	assert(int(game.profile.data["flux"]) == 202, "Defeat should bank only half of earned Flux")
	print("OPERATION_SPINE_OK connected missions, intermissions, retained state, and partial recovery validated")
	quit(0)


func _complete_current_mission(game: Node) -> void:
	if game.objective_director.active:
		game.player.global_position = game.objective_director.world_position
		game.session.tick(game.objective_director.hold_duration + 0.01)
		game.objective_director.tick(game.objective_director.hold_duration + 0.01)
		return
	var duration := float(game.spawn_director.encounter_spec["duration"])
	game.session.mission_elapsed = duration
	game.spawn_director.tick(0.01)
	game.spawn_director.tick(GameBalance.BOSS_INTRO_DURATION + 0.01)


func _contains_label(root_node: Node, text_fragment: String) -> bool:
	for child: Node in root_node.find_children("*", "Label", true, false):
		if text_fragment in String(child.text):
			return true
	return false
