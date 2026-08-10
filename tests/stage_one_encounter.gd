extends SceneTree

const StageCatalog := preload("res://scripts/content/stage_catalog.gd")


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
	game.session.flux = 17
	game.session.elapsed = float(StageCatalog.definition("stage_1")["duration"])
	game.spawn_director.tick(0.01)
	await process_frame
	assert(game.spawn_director.encounter_state == SpawnDirector.EncounterState.STAGE_OUTRO, "Stage 1 should end with a safe evacuation instead of a boss")
	assert(crowd.dispersing and not crowd.active, "The existing swarm should disperse harmlessly")
	game.spawn_director.tick(GameBalance.BOSS_INTRO_DURATION + 0.01)
	await process_frame
	assert(game.state == game.GameState.STAGE_CLEAR, "Surviving the Stage 1 drone formation should clear the stage")
	assert(game.profile.stage_cleared("stage_1") and game.profile.stage_unlocked("stage_2"), "Stage 1 should unlock Stage 2")
	assert(game.profile.is_discovered("orbit"), "Stage 1 should unlock Orbit Blades")
	assert(not game.profile.is_discovered("arc") and not game.profile.is_discovered("nova") and not game.profile.is_discovered("vector_parry"), "Stage 1 should grant no other equipment")
	assert(game.profile.unlocked_weapon_slots() == 1, "The second weapon slot should remain locked until Stage 5")
	assert(int(game.profile.data["flux"]) == 34, "A first clear should add bonus Flux equal to the run's enemy Flux")
	game.show_menu()
	game.show_stage_select()
	await process_frame
	var second_stage_button: Button = game.ui.stage_select_screen.find_child("StageSelect_stage_2", true, false)
	assert(second_stage_button != null and second_stage_button.text == "STAGE 2", "Clearing Stage 1 should reveal only the minimal Stage 2 node")
	game.show_menu()
	assert(game.profile.equip_weapon("orbit"), "Orbit Blades should be selectable after Stage 1")
	assert(game.profile.equipped_weapons() == ["orbit"], "A single-slot loadout should replace Pulse with Orbit Blades")

	for stage_id: String in ["stage_2", "stage_3", "stage_4"]:
		game.profile.clear_stage(stage_id)
	game.selected_stage = "stage_5"
	game.start_run()
	await process_frame
	game.spawn_enemy("drone")
	await process_frame
	var stage_five_crowd: NeonEnemy = get_nodes_in_group("enemies")[0]
	game.session.elapsed = float(StageCatalog.definition("stage_5")["duration"])
	game.spawn_director.tick(0.01)
	assert(game.spawn_director.encounter_state == SpawnDirector.EncounterState.BOSS_INTRO, "Only Stage 5 should start the boss entrance")
	assert(stage_five_crowd.dispersing and not stage_five_crowd.active, "The Stage 5 swarm should evacuate before the boss")
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
	game.combat_director.parry_projectiles(game.player.global_position)
	assert(hostile.friendly and hostile.weapon == "parry", "Vector Parry should return nearby projectiles as friendly counterfire")
	assert(not hostile.is_in_group("enemy_projectiles"), "Reflected shots should leave the hostile projectile group")
	boss.boss_exposed = true
	boss.take_damage(boss.health, "pulse")
	await process_frame
	await process_frame
	assert(game.state == game.GameState.STAGE_CLEAR, "Defeating the Overseer should complete Stage 5")
	assert(game.profile.stage_cleared("stage_5"), "The final stage should be recorded as cleared")
	assert(game.profile.is_discovered("vector_parry"), "Stage 5 should unlock Vector Parry")
	assert(game.profile.unlocked_weapon_slots() == 2, "Stage 5 should unlock the second weapon slot")
	assert(not game.profile.is_discovered("arc") and not game.profile.is_discovered("nova"), "The campaign should grant no additional weapons")
	game.show_menu()
	game._on_ability_selected("vector_parry")
	assert(game.profile.equipped_ability() == "vector_parry", "The reward should equip into the Space ability slot")
	assert(game.profile.equip_weapon("pulse"), "The Stage 5 slot should accept a second unlocked weapon")
	assert(game.profile.equipped_weapons() == ["orbit", "pulse"], "The final loadout should support Orbit and Pulse together")
	game.start_run()
	await process_frame
	game.add_resonance(game.session.resonance_needed)
	await process_frame
	await process_frame
	assert(game.ui.overlay.find_child("RunUpgrade_pulse_damage", true, false) != null, "Multi-weapon evolution should include Pulse choices")
	assert(game.ui.overlay.find_child("RunUpgrade_orbit_blade_count", true, false) != null, "Multi-weapon evolution should include Orbit choices")
	game._on_run_upgrade_selected("orbit", "blade_count")
	assert(game.session.weapon_upgrade_rank("orbit", "blade_count") == 1, "The player should choose which equipped weapon evolves")
	assert(game.session.weapon_upgrade_rank("pulse", "damage") == 0, "Improving Nova should leave Pulse unchanged")
	print("STAGE_ONE_OK sequential unlocks, first-clear Flux, sparse equipment rewards, and Stage 5 boss validated")
	quit(0)
