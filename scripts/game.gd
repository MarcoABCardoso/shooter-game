extends Node2D

# Composition root: owns lifecycle and wires independent systems together.
# Gameplay rules, content, rendering, and widgets live in their own modules.

enum GameState { MENU, RUNNING, PAUSED, GAME_OVER, STAGE_CLEAR, LEVEL_UP, CREDITS }

const PlayerScene := preload("res://scripts/entities/player.gd")
const AudioScene := preload("res://scripts/audio.gd")
const StageCatalog := preload("res://scripts/content/stage_catalog.gd")
const HUD_UPDATE_INTERVAL := 0.1

var state := GameState.MENU
var profile := SaveProfile.new()
var session := RunSession.new()
var player: NeonPlayer
var selected_stage := "stage_1"

var audio: NeonAudio
var arena_view: ArenaView
var spawn_director: SpawnDirector
var combat_director: CombatDirector
var weapon_system: WeaponSystem
var ui: GameUI
var hud_update_timer := 0.0

# Read-only compatibility views are useful for the console and test harness.
var elapsed: float:
	get: return session.elapsed
	set(value): session.elapsed = value
var run_level: int:
	get: return session.level
var weapons: Dictionary:
	get: return weapon_system.weapons


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


func _physics_process(delta: float) -> void:
	if state == GameState.RUNNING:
		session.tick(delta)
		spawn_director.tick(delta)
		weapon_system.tick(delta)
		combat_director.tick_contacts(delta)
		hud_update_timer -= delta
		if hud_update_timer <= 0.0:
			hud_update_timer += HUD_UPDATE_INTERVAL
			ui.update_hud(session, weapon_system.weapons, selected_stage)


func _build_modules() -> void:
	arena_view = ArenaView.new()
	add_child(arena_view)
	weapon_system = WeaponSystem.new()
	add_child(weapon_system)
	spawn_director = SpawnDirector.new()
	add_child(spawn_director)
	combat_director = CombatDirector.new()
	add_child(combat_director)
	audio = AudioScene.new()
	add_child(audio)
	ui = GameUI.new()
	add_child(ui)


func _connect_modules() -> void:
	session.level_gained.connect(_on_level_gained)
	spawn_director.spawn_requested.connect(combat_director.spawn_enemy)
	spawn_director.swarm_evacuation_requested.connect(combat_director.begin_swarm_evacuation)
	spawn_director.stage_completed.connect(_complete_stage)
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
	ui.new_game_requested.connect(_show_new_game_slots)
	ui.load_game_requested.connect(_show_load_game_slots)
	ui.options_requested.connect(ui.show_options)
	ui.master_volume_changed.connect(audio.set_master_volume)
	ui.set_master_volume(audio.master_volume)
	ui.title_requested.connect(show_title)
	ui.slot_selected.connect(_select_save_slot)
	ui.deploy_requested.connect(show_stage_select)
	ui.stage_selected.connect(_on_stage_selected)
	ui.resume_requested.connect(resume_game)
	ui.abandon_requested.connect(_abandon_run)
	ui.retry_requested.connect(start_run)
	ui.menu_requested.connect(show_menu)
	ui.reset_requested.connect(_reset_profile)
	ui.library_requested.connect(_show_library)
	ui.loadout_requested.connect(show_loadout)
	ui.skills_requested.connect(show_skill_tree)
	ui.credits_requested.connect(show_credits)
	ui.credits_finished.connect(_on_credits_finished)
	ui.weapon_selected.connect(_on_weapon_selected)
	ui.ability_selected.connect(_on_ability_selected)
	ui.skill_purchase_requested.connect(_buy_skill)
	ui.skills_respec_requested.connect(_respec_skills)
	ui.run_upgrade_requested.connect(_on_run_upgrade_selected)
	ui.mobile_input_changed.connect(_on_mobile_input_changed)
	ui.mobile_ability_requested.connect(_on_mobile_ability_requested)
	ui.mobile_pause_requested.connect(_on_mobile_pause_requested)


func start_run() -> void:
	if not profile.stage_unlocked(selected_stage):
		selected_stage = "stage_1"
	_set_run_entities_paused(false)
	_clear_run()
	session.reset()
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
	combat_director.configure(player, profile, session, selected_stage)
	weapon_system.configure(player, profile, session, combat_director.enemies)
	spawn_director.configure(session, selected_stage)
	player.active = true
	state = GameState.RUNNING
	ui.show_run()
	ui.set_ability(profile.equipped_ability())
	ui.show_banner("%s // SIGNAL ACQUIRED" % StageCatalog.display_name(selected_stage), GamePalette.CYAN)
	hud_update_timer = HUD_UPDATE_INTERVAL
	ui.update_hud(session, weapon_system.weapons, selected_stage)
	audio.play_music(&"stage_5" if selected_stage == "stage_5" else &"combat")
	audio.tone(220.0, 0.18, 0.2, 600.0)


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
	if state != GameState.MENU and state != GameState.STAGE_CLEAR:
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


func show_stage_select() -> void:
	if state == GameState.MENU:
		ui.show_stage_select(profile)


func _on_stage_selected(id: String) -> void:
	if state != GameState.MENU or not profile.stage_unlocked(id):
		return
	selected_stage = id
	start_run()


func pause_game() -> void:
	state = GameState.PAUSED
	_set_combat_active(false)
	ui.show_pause()


func resume_game() -> void:
	state = GameState.RUNNING
	_set_combat_active(true)
	ui.show_run()


func _abandon_run() -> void:
	_end_run(false)


func _on_player_died() -> void:
	# Player death can be emitted from an Area2D body_entered callback. Defer the
	# run teardown so collision objects are disabled after physics query flushing.
	call_deferred("_end_run", true)


func _end_run(defeated: bool) -> void:
	if state == GameState.GAME_OVER:
		return
	state = GameState.GAME_OVER
	_set_combat_active(false)
	profile.bank_run(session.flux, session.elapsed, session.level, session.kills, session.mastery)
	ui.show_run_end(defeated, session)
	audio.stop_music()
	if defeated:
		audio.play_stinger(&"defeat")


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
	call_deferred("_complete_stage")


func _on_boss_started() -> void:
	if state == GameState.RUNNING and selected_stage == "stage_5":
		audio.play_music(&"boss")


func _complete_stage() -> void:
	if state not in [GameState.RUNNING, GameState.LEVEL_UP]:
		return
	session.pending_levels = 0
	state = GameState.STAGE_CLEAR
	_set_combat_active(false)
	var first_clear := profile.clear_stage(selected_stage)
	var first_clear_bonus := session.flux if first_clear else 0
	profile.bank_run(session.flux + first_clear_bonus, session.elapsed, session.level, session.kills, session.mastery)
	if selected_stage == "stage_5":
		show_credits()
		return
	ui.show_stage_clear(selected_stage, session, first_clear, first_clear_bonus)
	audio.stop_music()
	audio.play_stinger(&"clear")


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


func _on_level_gained(_count: int) -> void:
	if state != GameState.RUNNING:
		return
	# Resonance may be awarded from a projectile collision callback. Defer UI and
	# process-mode changes until physics has finished flushing the query.
	call_deferred("_open_next_run_upgrade")


func _open_next_run_upgrade() -> void:
	if state not in [GameState.RUNNING, GameState.LEVEL_UP]:
		return
	if session.pending_levels <= 0:
		_resume_after_run_upgrade()
		return
	if not weapon_system.has_available_run_upgrade():
		session.pending_levels = 0
		_resume_after_run_upgrade()
		ui.show_banner("ALL WEAPON DIMENSIONS CAPPED", GamePalette.YELLOW)
		return
	state = GameState.LEVEL_UP
	_set_combat_active(false)
	ui.show_run_upgrade(session, weapon_system.weapons)
	audio.tone(360.0 + session.level * 8.0, 0.14, 0.18, 900.0)


func _on_run_upgrade_selected(weapon: String, dimension: String) -> void:
	if state != GameState.LEVEL_UP or not weapon_system.apply_run_upgrade(weapon, dimension):
		return
	session.pending_levels = maxi(0, session.pending_levels - 1)
	if session.pending_levels > 0:
		_open_next_run_upgrade()
	else:
		_resume_after_run_upgrade()


func _on_mobile_input_changed(movement: Vector2) -> void:
	if is_instance_valid(player):
		player.set_mobile_input(movement)


func _on_mobile_ability_requested() -> void:
	if state == GameState.RUNNING and is_instance_valid(player):
		player.request_mobile_ability()


func _on_mobile_pause_requested() -> void:
	if state == GameState.RUNNING:
		pause_game()


func _resume_after_run_upgrade() -> void:
	state = GameState.RUNNING
	_set_combat_active(true)
	ui.show_run()
	ui.show_banner("SIGNAL LEVEL %02d // BUILD UPDATED" % session.level, GamePalette.GREEN)


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
	for node: Node in get_tree().get_nodes_in_group("run_entities"):
		if is_instance_valid(node):
			node.queue_free()
	player = null
