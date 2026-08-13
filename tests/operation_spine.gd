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
	assert(not game.profile.is_stage_unlocked("relay_breach"), "A fresh profile should begin at the opening route")
	assert(game.ui.hangar_screen.find_child("DeployButton_relay_breach", true, false).visible, "The hangar should keep its stage list stable")
	assert(game.ui.hangar_screen.find_child("DeployButton_relay_breach", true, false).disabled, "A disabled button should communicate that a stage is locked")
	assert(game.ui.hangar_screen.find_child("DeployButton_relay_breach", true, false).text == "RELAY BREACH\n03:30", "Stage buttons should contain only the name and overall mission deadline")
	var signal_button := game.ui.hangar_screen.find_child("DeployButton_signal_hold", true, false) as Button
	var relay_button := game.ui.hangar_screen.find_child("DeployButton_relay_breach", true, false) as Button
	var boss_button := game.ui.hangar_screen.find_child("DeployButton_overseer_lock", true, false) as Button
	var cache_button := game.ui.hangar_screen.find_child("DeployButton_drift_cache", true, false) as Button
	assert(is_equal_approx(signal_button.position.y, relay_button.position.y) and is_equal_approx(relay_button.position.y, boss_button.position.y), "Required stages should render as one route spine")
	assert(cache_button.position.y > relay_button.position.y, "The optional cache should render as a side branch")
	assert(game.ui.hangar_screen.find_child("LoadoutButton", true, false).visible, "The opening hangar should present the primary build choice before deployment")
	assert(not game.ui.hangar_screen.find_child("SkillTreeButton", true, false).visible, "The opening hangar should defer permanent progression while exposing equipment")
	assert(not _contains_label(game.ui.hangar_screen, "//"), "The opening hangar should use plain language instead of separator-heavy copy")
	game.ui.hangar_screen.find_child("DeployButton_signal_hold", true, false).emit_signal("pressed")
	await process_frame
	assert(game.state == game.GameState.RUNNING, "A selected stage should begin in combat")
	assert(game.session.operation_id == "signal_hold", "Stage selection should preserve the chosen content identity")
	assert(game.current_encounter_id == "defense_swarm", "Signal Hold should enter its defense encounter")
	assert(game.spawn_director.objective_driven == false and game.objective_director.objectives.is_empty(), "Signal Hold should teach survival without an objective director")
	assert(game.arena_view.background.mission_arenas == [GameBalance.ARENA] and game.arena_view.camera.limit_right <= 1280, "Signal Hold should keep the opening survival lesson inside one fixed arena")
	var locked_camera_x: float = game.arena_view.camera.position.x
	game.arena_view.follow_player(game.player.global_position + Vector2(280.0, 0.0))
	assert(is_equal_approx(game.arena_view.camera.position.x, locked_camera_x), "The survival camera should remain fixed")
	assert(_contains_label(game.ui.hud, "SIGNAL HOLD") and _contains_label(game.ui.hud, "01:00"), "The opener HUD should present only the stage and survival timer")
	assert(game.ui.hud.find_child("MissionTransmission", true, false) == null, "The HUD should not retain an unsupported floating dialogue line")
	assert(not _contains_label(game.ui.hud, "//"), "The combat HUD should avoid decorative double slashes")
	game.spawn_enemy("drone", false)
	var pressure_enemy: NeonEnemy = game.combat_director.enemies[game.combat_director.enemies.size() - 1]
	game.session.flux = 123
	game.session.record_mastery("pulse", 12.0)
	game.weapon_system.arc_visuals.append({"points": [Vector2.ZERO, Vector2.ONE], "life": 1.0})
	game.weapon_system.nova_visual = 1.0
	game.weapon_system.anchor_charge = 1.0
	game.player.dash_duration = 1.0
	game.player.parry_flash = 1.0

	_complete_current_stage(game)
	assert(game.state == game.GameState.STAGE_CLEAR, "Signal Hold should end and bank independently")
	assert(not game.weapon_system.visible and game.weapon_system.arc_visuals.is_empty() and game.weapon_system.nova_visual == 0.0 and game.weapon_system.anchor_charge == 0.0, "Stage completion should remove every weapon presentation before another loadout is configured")
	assert(game.player.dash_duration == 0.0 and game.player.parry_flash == 0.0, "Stage completion should clear transient player effects from the battlefield")
	assert(game.ui.overlay.find_child("ResultPrimaryButton", true, false) == null and game.ui.overlay.find_child("ResultHangarButton", true, false) != null, "A completed stage should offer only the normal return to hangar")
	assert(not _contains_label(game.ui.overlay, "MASTERY"), "Victory copy should stay compact instead of reporting persistence details")
	assert(not is_instance_valid(pressure_enemy) or pressure_enemy.dispersing, "Surviving the timer should evacuate remaining enemies before the end screen")
	assert(int(game.profile.data["flux"]) == 183, "The opening first clear should bank earned Flux plus its route reward")
	assert(float(game.profile.data["mastery_xp"]["pulse"]) == 12.0, "A cleared stage should bank earned mastery")
	assert(game.profile.stage_clear_count("signal_hold") == 1, "The profile should remember the opening clear")
	assert(game.profile.is_stage_unlocked("drift_cache") and game.profile.is_stage_unlocked("relay_breach"), "The opener should reveal required and optional routes")

	game.show_menu()
	assert(game.ui.hangar_screen.find_child("SkillTreeButton", true, false).visible, "The opener should reveal permanent build allocation")
	game.ui.hangar_screen.find_child("DeployButton_drift_cache", true, false).emit_signal("pressed")
	await process_frame
	assert(game.weapon_system.visible, "A new deployment should restore only the newly configured weapon presentation")
	assert(game.session.operation_id == "drift_cache" and game.current_encounter_id == "cache_pressure", "The optional cache should deploy its distinct encounter composition")
	assert(game.objective_director.world_position == OperationCatalog.mission("drift_cache")["objectives"][0]["objective_position"], "The optional defense should begin at its content-defined approach")
	_complete_current_stage(game)
	assert(int(game.profile.data["flux"]) == 283, "The optional first clear should provide enough Flux for meaningful power growth")
	assert(game.profile.is_discovered("vector_parry"), "The optional cache should unlock Vector Parry")
	assert(game.ui.overlay.find_child("UnlockReveal", true, false) != null, "A deterministic equipment reward should replace the generic result card with an unlock reveal")
	assert((game.ui.overlay.find_child("UnlockName", true, false) as Label).text == "VECTOR PARRY", "The optional reward reveal should name Vector Parry prominently")
	assert(not _contains_button(game.ui.overlay, "PLAY AGAIN"), "Equipment unlock completion should return through the hangar instead of offering an unusual replay shortcut")

	game.show_menu()
	game.ui.hangar_screen.find_child("DeployButton_relay_breach", true, false).emit_signal("pressed")
	await process_frame
	assert(game.session.operation_id == "relay_breach" and game.current_encounter_id == "relay_breach", "Relay Breach should deploy independently from the hangar")
	assert(game.session.flux == 0 and game.session.level == 1 and game.session.operation_evolutions.is_empty(), "A new stage should reset run rewards and evolution commitments")
	assert(game.objective_director.lifecycle == "relay_breach" and game.objective_director.remaining_relays.size() == 2, "The Breach should begin with one readable relay pair")
	assert(game.arena_view.background.relay_positions.size() == 2, "The arena should render only the active relay group")
	assert(game.objective_director.objective_label() == "1/3  BREAK THE OUTER LINK", "The breach should identify its current step")
	assert(game.audio.current_music == &"breach", "The Breach should have its own representative music")
	var relays: Array[NeonEnemy] = []
	for enemy: NeonEnemy in game.combat_director.enemies:
		if enemy.kind == "relay":
			relays.append(enemy)
	assert(relays.size() == 2, "The objective should request only the first relay pair through CombatDirector")
	var relay_position := relays[0].global_position
	relays[0].apply_knockback(game.player.global_position, 999.0)
	relays[0]._physics_process(0.1)
	assert(relays[0].global_position.is_equal_approx(relay_position), "Relay objectives should remain fixed to their arena markers")
	game.combat_director.objective_target_defeated.emit(0)
	assert(game.objective_director.remaining_relays == [1], "Objective target defeats should advance the active relay group through the composition root")
	game.combat_director.objective_target_defeated.emit(1)
	assert(game.objective_director.completing, "Completing a relay group should play its completion beat without ending the deployment")
	game.objective_director.tick(game.objective_director.OBJECTIVE_TRANSITION_DELAY + 0.01)
	assert(game.objective_director.traveling and game.objective_director.pending_objective_index == 1, "The completed relay animation should lead into forward travel")
	game.player.global_position = game.objective_director.destination_arena.position + Vector2(100.0, 284.0)
	game.objective_director.tick(0.01)
	assert(game.objective_director.objective_index == 1 and game.objective_director.remaining_relays == [0, 1], "Entering the next chamber should reveal the next relay pair")

	_complete_current_stage(game)
	assert(game.state == game.GameState.STAGE_CLEAR, "Relay Breach should clear without a continue/intermission step")
	assert(int(game.profile.data["flux"]) == 353 and game.profile.is_stage_unlocked("overseer_lock"), "The required breach should reward Flux and reveal the boss")

	game.show_menu()
	assert(game.profile.equip_ability("vector_parry"), "The hangar interval should permit build reconfiguration")
	game.ui.hangar_screen.find_child("DeployButton_overseer_lock", true, false).emit_signal("pressed")
	await process_frame
	assert(game.session.operation_id == "overseer_lock" and game.current_encounter_id == "overseer_lock", "Overseer Lock should deploy as its own stage")
	assert(game.player.ability_mode == "vector_parry", "The boss stage should use the newly optimized hangar loadout")
	_complete_current_stage(game)
	await process_frame
	assert(game.state == game.GameState.STAGE_CLEAR, "Defeating the Overseer should clear only its selected stage")
	assert(game.profile.sector_one_completed(), "Defeating the Overseer should secure the opening sector")
	assert(game.profile.is_discovered("nova"), "The sector clear should add the advanced Nova weapon")
	assert((game.ui.overlay.find_child("UnlockName", true, false) as Label).text == "NOVA BURST", "The sector reward should receive a prominent Nova unlock reveal")
	assert(int(game.profile.data["flux"]) == 473, "The boss first clear should bank its sector reward")

	game.start_operation("signal_hold")
	game.session.flux = 101
	game._retreat_operation()
	assert(game.state == game.GameState.GAME_OVER, "Retreat should end the active stage")
	assert(int(game.profile.data["flux"]) == 548, "Retreat should bank 75% of earned Flux, rounded down")

	game.start_operation("overseer_lock")
	game.session.flux = 9
	game._end_operation(false, true)
	assert(game.state == game.GameState.GAME_OVER, "Defeat should end the active stage")
	assert(int(game.profile.data["flux"]) == 552, "Defeat should bank only half of earned Flux")

	game.start_operation("relay_breach")
	var timed_mission := OperationCatalog.mission("relay_breach")
	game.session.mission_elapsed = float(timed_mission["time_limit"]) - 0.01
	game._physics_process(0.02)
	assert(game.state == game.GameState.GAME_OVER, "Exceeding a stage deadline should prevent farming")
	print("OPERATION_SPINE_OK opening-sector route, optional growth, build reconfiguration, objectives, and rewards validated")
	quit(0)


func _complete_current_stage(game: Node) -> void:
	while game.state in [game.GameState.RUNNING, game.GameState.LEVEL_UP] and not game.objective_director.objectives.is_empty():
		if game.objective_director.completing:
			game.objective_director.tick(maxf(game.objective_director.completion_timer, 0.01) + 0.01)
			continue
		if game.objective_director.traveling:
			game.player.global_position = game.objective_director.destination_arena.position + Vector2(100.0, 284.0)
			game.objective_director.tick(0.01)
			continue
		if game.objective_director.lifecycle == "signal_defense":
			game.player.global_position = game.objective_director.world_position
			game.session.tick(game.objective_director.hold_duration + 0.01)
			game.objective_director.tick(game.objective_director.hold_duration + 0.01)
			continue
		if game.objective_director.lifecycle == "relay_breach":
			for relay_index in game.objective_director.remaining_relays.duplicate():
				game.objective_director.register_objective_target_defeated(relay_index)
			continue
		break
	if game.state == game.GameState.STAGE_CLEAR:
		return
	var duration := float(game.spawn_director.encounter_spec["duration"])
	game.session.mission_elapsed = duration
	game.session.elapsed = duration
	game.spawn_director.tick(0.01)
	game.spawn_director.tick(GameBalance.BOSS_INTRO_DURATION + 0.01)
	if bool(game.spawn_director.encounter_spec["boss"]):
		game._on_boss_defeated()
		game._physics_process(GameBalance.MISSION_OUTRO_DURATION + 0.01)


func _contains_label(root_node: Node, text_fragment: String) -> bool:
	for child: Node in root_node.find_children("*", "Label", true, false):
		if text_fragment in String(child.text):
			return true
	return false


func _contains_button(root_node: Node, text_fragment: String) -> bool:
	for child: Node in root_node.find_children("*", "Button", true, false):
		if String((child as Button).text).contains(text_fragment):
			return true
	return false
