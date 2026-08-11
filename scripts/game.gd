extends Node2D

# Composition root: owns lifecycle and wires independent systems together.
# Gameplay rules, content, rendering, and widgets live in their own modules.

enum GameState { MENU, RUNNING, PAUSED, GAME_OVER, LEVEL_UP, CREDITS, INTERMISSION, OPERATION_CLEAR }

const PlayerScene := preload("res://scripts/entities/player.gd")
const AudioScene := preload("res://scripts/audio.gd")
const ObjectiveDirectorScene := preload("res://scripts/systems/objective_director.gd")
const OperationCatalog := preload("res://scripts/content/operation_catalog.gd")
const OperationEvolutionCatalog := preload("res://scripts/content/operation_evolution_catalog.gd")
const HUD_UPDATE_INTERVAL := 0.1

var state := GameState.MENU
var profile := SaveProfile.new()
var session := RunSession.new()
var player: NeonPlayer
var current_encounter_id := ""

var audio: NeonAudio
var arena_view: ArenaView
var spawn_director: SpawnDirector
var combat_director: CombatDirector
var objective_director
var weapon_system: WeaponSystem
var ui: GameUI
var hud_update_timer := 0.0

func _ready() -> void:
	_build_modules()
	_connect_modules()
	show_title()
	get_viewport().get_window().min_size = Vector2i(960, 540)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if state == GameState.RUNNING:
			pause_game()
		elif state == GameState.PAUSED:
			resume_game()
	if state == GameState.RUNNING and not session.operation_id.is_empty() and Input.is_action_just_pressed("cycle_target"):
		var mode_name := weapon_system.cycle_target_mode()
		ui.show_banner("TARGET MODE — " + mode_name, GamePalette.YELLOW)
		ui.update_hud(session, weapon_system.weapons, _current_encounter_label(), mode_name)


func _physics_process(delta: float) -> void:
	if state == GameState.RUNNING:
		session.tick(delta)
		spawn_director.tick(delta)
		weapon_system.tick(delta)
		combat_director.tick_contacts(delta)
		objective_director.tick(delta)
		hud_update_timer -= delta
		if hud_update_timer <= 0.0:
			hud_update_timer += HUD_UPDATE_INTERVAL
			ui.update_hud(session, weapon_system.weapons, _current_encounter_label(), weapon_system.target_mode_name())


func _build_modules() -> void:
	arena_view = ArenaView.new()
	add_child(arena_view)
	weapon_system = WeaponSystem.new()
	add_child(weapon_system)
	spawn_director = SpawnDirector.new()
	add_child(spawn_director)
	combat_director = CombatDirector.new()
	add_child(combat_director)
	objective_director = ObjectiveDirectorScene.new()
	add_child(objective_director)
	audio = AudioScene.new()
	add_child(audio)
	ui = GameUI.new()
	add_child(ui)


func _connect_modules() -> void:
	session.level_gained.connect(_on_level_gained)
	spawn_director.spawn_requested.connect(combat_director.spawn_enemy)
	spawn_director.swarm_evacuation_requested.connect(combat_director.begin_swarm_evacuation)
	spawn_director.encounter_completed.connect(_complete_operation_mission)
	spawn_director.boss_started.connect(_on_boss_started)
	spawn_director.banner_requested.connect(ui.show_banner)
	spawn_director.shake_requested.connect(arena_view.shake)
	weapon_system.projectile_requested.connect(combat_director.spawn_projectile)
	weapon_system.damage_dealt.connect(_on_damage_dealt)
	weapon_system.burst_requested.connect(combat_director.spawn_burst)
	weapon_system.shake_requested.connect(arena_view.shake)
	weapon_system.tone_requested.connect(audio.tone)
	combat_director.damage_dealt.connect(_on_damage_dealt)
	combat_director.enemy_defeated.connect(_on_enemy_defeated)
	combat_director.boss_defeated.connect(_on_boss_defeated)
	combat_director.resonance_gained.connect(add_resonance)
	combat_director.flux_gained.connect(session.add_flux)
	combat_director.repair_collected.connect(_repair_player)
	combat_director.banner_requested.connect(ui.show_banner)
	combat_director.shake_requested.connect(arena_view.shake)
	combat_director.tone_requested.connect(audio.tone)
	objective_director.mission_completed.connect(_complete_operation_mission)
	objective_director.objective_updated.connect(arena_view.show_signal_objective)
	objective_director.objective_hidden.connect(arena_view.hide_objective)
	objective_director.banner_requested.connect(ui.show_banner)
	ui.new_game_requested.connect(_show_new_game_slots)
	ui.load_game_requested.connect(_show_load_game_slots)
	ui.options_requested.connect(ui.show_options)
	ui.master_volume_changed.connect(audio.set_master_volume)
	ui.set_master_volume(audio.master_volume)
	ui.title_requested.connect(show_title)
	ui.slot_selected.connect(_select_save_slot)
	ui.deploy_requested.connect(_deploy_operation)
	ui.resume_requested.connect(resume_game)
	ui.retry_requested.connect(_retry_current_deployment)
	ui.menu_requested.connect(show_menu)
	ui.reset_requested.connect(_reset_profile)
	ui.library_requested.connect(_show_library)
	ui.loadout_requested.connect(show_loadout)
	ui.skills_requested.connect(show_skill_tree)
	ui.credits_finished.connect(_on_credits_finished)
	ui.weapon_selected.connect(_on_weapon_selected)
	ui.ability_selected.connect(_on_ability_selected)
	ui.skill_purchase_requested.connect(_buy_skill)
	ui.skills_respec_requested.connect(_respec_skills)
	ui.operation_evolution_requested.connect(_on_operation_evolution_selected)
	ui.mobile_input_changed.connect(_on_mobile_input_changed)
	ui.mobile_ability_requested.connect(_on_mobile_ability_requested)
	ui.mobile_pause_requested.connect(_on_mobile_pause_requested)
	ui.continue_operation_requested.connect(_continue_operation)
	ui.retreat_operation_requested.connect(_retreat_operation)


func _spawn_player() -> void:
	player = PlayerScene.new()
	player.add_to_group("run_entities")
	player.global_position = GameBalance.ARENA.get_center()
	player.arena = GameBalance.ARENA.grow(-18.0)
	player.died.connect(_on_player_died)
	player.health_changed.connect(ui.set_health)
	player.dash_changed.connect(ui.set_dash)
	player.parry_requested.connect(combat_director.parry_projectiles)
	player.active_skill_used.connect(session.record_mastery)
	player.configure({
		"damage": profile.skill_effect("general_damage"),
		"hull": profile.skill_effect("hull"),
		"shield": profile.skill_effect("shield"),
		"ability_cooldown": profile.skill_effect("ability_cooldown"),
		"ability": profile.equipped_ability(),
		"ability_mastery": profile.mastery_level(profile.equipped_ability()),
	})
	player.set_mobile_controls_enabled(ui.mobile_controls_available)
	add_child(player)


func show_menu() -> void:
	_set_run_entities_paused(false)
	state = GameState.MENU
	_clear_run()
	ui.show_menu(profile)
	audio.play_music(&"hangar")


func show_title() -> void:
	_set_run_entities_paused(false)
	state = GameState.MENU
	_clear_run()
	profile = SaveProfile.new()
	ui.show_title()
	audio.play_music(&"title")


func show_credits() -> void:
	if state != GameState.MENU:
		return
	_set_run_entities_paused(false)
	state = GameState.CREDITS
	_clear_run()
	ui.show_credits()
	audio.play_music(&"credits")


func _on_credits_finished() -> void:
	if state == GameState.CREDITS:
		show_menu()


func _show_new_game_slots() -> void:
	if state == GameState.MENU:
		ui.show_save_slots(true, SaveProfile.slot_summaries())


func _show_load_game_slots() -> void:
	if state == GameState.MENU:
		ui.show_save_slots(false, SaveProfile.slot_summaries())


func _select_save_slot(slot: int, create_new: bool) -> void:
	if state != GameState.MENU:
		return
	var selected := SaveProfile.new()
	var ready := selected.create_slot(slot) if create_new else selected.load_slot(slot)
	if not ready:
		ui.show_save_slots(create_new, SaveProfile.slot_summaries())
		return
	profile = selected
	show_menu()


func show_loadout() -> void:
	if state == GameState.MENU:
		ui.show_loadout(profile)


func show_skill_tree() -> void:
	if state == GameState.MENU:
		ui.show_skill_tree(profile)


func _deploy_operation() -> void:
	if state == GameState.MENU:
		start_operation(OperationCatalog.ORDER[0])


func start_operation(id: String) -> void:
	if not OperationCatalog.ORDER.has(id):
		return
	_set_run_entities_paused(false)
	_clear_run()
	session.begin_operation(id)
	_spawn_player()
	weapon_system.configure(player, profile, session, combat_director.enemies)
	_start_current_operation_mission()


func _start_current_operation_mission() -> void:
	var mission := OperationCatalog.mission(session.operation_id, session.mission_index)
	if mission.is_empty():
		return
	current_encounter_id = String(mission["encounter_id"])
	_clear_mission_entities()
	player.global_position = GameBalance.ARENA.get_center()
	combat_director.configure(player, profile, session, current_encounter_id)
	spawn_director.configure(session, current_encounter_id, mission)
	objective_director.configure(mission, player)
	state = GameState.RUNNING
	_set_combat_active(true)
	ui.show_run()
	ui.set_ability(profile.equipped_ability())
	ui.show_banner(_current_encounter_label(), GamePalette.CYAN)
	hud_update_timer = HUD_UPDATE_INTERVAL
	ui.update_hud(session, weapon_system.weapons, _current_encounter_label(), weapon_system.target_mode_name())
	audio.play_music(&"combat")
	audio.tone(220.0, 0.18, 0.2, 600.0)
	if not session.pending_evolution_tiers.is_empty():
		call_deferred("_open_next_operation_evolution")


func pause_game() -> void:
	state = GameState.PAUSED
	_set_combat_active(false)
	ui.show_operation_pause()


func resume_game() -> void:
	state = GameState.RUNNING
	_set_combat_active(true)
	ui.show_run()


func _on_player_died() -> void:
	# Player death can be emitted from an Area2D body_entered callback. Defer the
	# run teardown so collision objects are disabled after physics query flushing.
	call_deferred("_end_operation", false, true)


func _set_combat_active(value: bool) -> void:
	_set_run_entities_paused(not value)
	if is_instance_valid(player):
		player.active = value
		if not value:
			player.clear_mobile_input()
	weapon_system.active = value


func _set_run_entities_paused(value: bool) -> void:
	for node: Node in get_tree().get_nodes_in_group("run_entities"):
		if is_instance_valid(node):
			node.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT


func _on_enemy_defeated(_kind: String) -> void:
	session.register_kill()


func _on_boss_defeated() -> void:
	call_deferred("_complete_operation_mission")


func _on_boss_started() -> void:
	if state == GameState.RUNNING:
		audio.play_music(&"boss")


func _complete_operation_mission() -> void:
	if state not in [GameState.RUNNING, GameState.LEVEL_UP]:
		return
	session.complete_mission()
	_set_combat_active(false)
	player.heal(player.max_health)
	objective_director.clear()
	_clear_mission_entities()
	var missions := OperationCatalog.missions(session.operation_id)
	if session.completed_missions >= missions.size():
		_end_operation(true, false)
		return
	state = GameState.INTERMISSION
	var completed := OperationCatalog.mission(session.operation_id, session.mission_index)
	ui.show_operation_intermission(session.operation_id, session, completed, missions.size())
	audio.stop_music()
	audio.play_stinger(&"clear")


func _continue_operation() -> void:
	if state != GameState.INTERMISSION:
		return
	session.begin_next_mission()
	_start_current_operation_mission()


func _retreat_operation() -> void:
	if session.operation_id.is_empty() or state not in [GameState.RUNNING, GameState.PAUSED, GameState.INTERMISSION, GameState.LEVEL_UP]:
		return
	_end_operation(false, false)


func _end_operation(completed: bool, defeated: bool) -> void:
	if state in [GameState.GAME_OVER, GameState.OPERATION_CLEAR]:
		return
	state = GameState.OPERATION_CLEAR if completed else GameState.GAME_OVER
	_set_combat_active(false)
	var banked_flux := session.flux
	if not completed:
		banked_flux = OperationCatalog.defeat_flux(session.operation_id, session.flux) if defeated else OperationCatalog.retreat_flux(session.operation_id, session.flux)
	profile.bank_run(banked_flux, session.elapsed, session.level, session.kills, session.mastery)
	ui.show_operation_end(session.operation_id, session, banked_flux, completed, defeated)
	audio.stop_music()
	if defeated:
		audio.play_stinger(&"defeat")
	elif completed:
		audio.play_stinger(&"clear")


func _retry_current_deployment() -> void:
	start_operation(session.operation_id if OperationCatalog.ORDER.has(session.operation_id) else OperationCatalog.ORDER[0])


func _current_encounter_label() -> String:
	var mission := OperationCatalog.mission(session.operation_id, session.mission_index)
	return "MISSION %d/%d — %s" % [session.mission_index + 1, OperationCatalog.missions(session.operation_id).size(), String(mission.get("name", "UNKNOWN"))]


func _on_ability_selected(id: String) -> void:
	if state == GameState.MENU and profile.equip_ability(id):
		ui.show_loadout(profile)


func _on_damage_dealt(weapon: String, amount: float, world_position: Vector2, _target_id: int) -> void:
	session.record_damage(weapon, amount)
	if weapon == "parry":
		session.record_damage("vector_parry", amount)
	if amount > 0.0 and randf() < 0.12:
		combat_director.spawn_burst(world_position, GamePalette.CYAN if weapon == "pulse" else GamePalette.GREEN, 12.0, 4)


func _repair_player(amount: float) -> void:
	if is_instance_valid(player):
		player.heal(amount)


func add_resonance(amount: int) -> void:
	session.add_resonance(amount)


func _on_level_gained(count: int) -> void:
	if state != GameState.RUNNING:
		return
	weapon_system.apply_operation_growth(count)
	for gained_level in range(session.level - count + 1, session.level + 1):
		var tier := OperationEvolutionCatalog.tier_for_level(gained_level)
		if tier > 0:
			session.queue_evolution_tier(tier)
	call_deferred("_open_next_operation_evolution")


func _open_next_operation_evolution() -> void:
	if state not in [GameState.RUNNING, GameState.LEVEL_UP]:
		return
	var tier := session.pending_evolution_tier()
	if tier <= 0:
		state = GameState.RUNNING
		_set_combat_active(true)
		ui.show_run()
		ui.show_banner("RESONANCE LEVEL %02d — AUTOMATIC POWER +10%%" % session.level, GamePalette.GREEN)
		return
	var choices := OperationEvolutionCatalog.choices_for(tier, session.operation_evolutions)
	if choices.is_empty():
		session.pending_evolution_tiers.pop_front()
		_open_next_operation_evolution()
		return
	state = GameState.LEVEL_UP
	_set_combat_active(false)
	ui.show_operation_evolution(session, choices)
	audio.tone(430.0 + tier * 70.0, 0.18, 0.2, 1000.0)


func _on_operation_evolution_selected(id: String) -> void:
	if state != GameState.LEVEL_UP or session.operation_id.is_empty():
		return
	if not weapon_system.apply_operation_evolution(id):
		return
	if not session.pending_evolution_tiers.is_empty():
		_open_next_operation_evolution()
		return
	state = GameState.RUNNING
	_set_combat_active(true)
	ui.show_run()
	ui.show_banner(String(OperationEvolutionCatalog.definition(id)["name"]) + " ONLINE", GamePalette.GREEN)


func _on_mobile_input_changed(movement: Vector2) -> void:
	if is_instance_valid(player):
		player.set_mobile_input(movement)


func _on_mobile_ability_requested() -> void:
	if state == GameState.RUNNING and is_instance_valid(player):
		player.request_mobile_ability()


func _on_mobile_pause_requested() -> void:
	if state == GameState.RUNNING:
		pause_game()


func _on_weapon_selected(id: String) -> void:
	if state == GameState.MENU and profile.equip_weapon(id):
		audio.tone(520.0, 0.06, 0.1, 180.0)
		ui.show_loadout(profile)


func _buy_skill(id: String) -> void:
	if state == GameState.MENU and profile.buy_skill(id):
		audio.tone(460.0, 0.1, 0.15, 620.0)
		ui.show_skill_tree(profile)


func _respec_skills() -> void:
	if state != GameState.MENU:
		return
	var refunded := profile.respec_skills()
	if refunded > 0:
		audio.tone(260.0, 0.12, 0.12, -180.0)
	ui.show_skill_tree(profile)


func _show_library() -> void:
	if state == GameState.MENU:
		ui.show_library(profile)


func _reset_profile() -> void:
	profile.reset()
	show_menu()


func spawn_enemy(kind: String, elite: bool = false) -> void:
	combat_director.spawn_enemy(kind, elite)


func _fire_nova() -> void:
	weapon_system.fire_nova()


func _clear_run() -> void:
	weapon_system.active = false
	if is_instance_valid(objective_director):
		objective_director.clear()
	for node: Node in get_tree().get_nodes_in_group("run_entities"):
		if is_instance_valid(node):
			node.queue_free()
	player = null


func _clear_mission_entities() -> void:
	for node: Node in get_tree().get_nodes_in_group("run_entities"):
		if is_instance_valid(node) and node != player:
			node.queue_free()
