extends Node2D

# Composition root: owns lifecycle and wires independent systems together.
# Gameplay rules, content, rendering, and widgets live in their own modules.

enum GameState { MENU, RUNNING, PAUSED, GAME_OVER }

const PlayerScene := preload("res://scripts/entities/player.gd")
const AudioScene := preload("res://scripts/audio.gd")

var state := GameState.MENU
var profile := SaveProfile.new()
var session := RunSession.new()
var player: NeonPlayer

var audio: NeonAudio
var arena_view: ArenaView
var spawn_director: SpawnDirector
var combat_director: CombatDirector
var weapon_system: WeaponSystem
var ui: GameUI

# Read-only compatibility views are useful for the console and test harness.
var elapsed: float:
	get: return session.elapsed
	set(value): session.elapsed = value
var run_level: int:
	get: return session.level
var weapons: Dictionary:
	get: return weapon_system.weapons


func _ready() -> void:
	profile.load_profile()
	_build_modules()
	_connect_modules()
	show_menu()
	get_viewport().get_window().min_size = Vector2i(960, 540)


func _process(delta: float) -> void:
	if state == GameState.RUNNING:
		session.tick(delta)
		spawn_director.tick(delta)
		weapon_system.tick(delta)
		combat_director.tick_contacts()
		if is_instance_valid(player):
			session.behavior.tick(delta, player.velocity, player.speed, get_tree().get_nodes_in_group("enemies").size())
		ui.update_hud(session, weapon_system.weapons)
	if Input.is_action_just_pressed("pause"):
		if state == GameState.RUNNING:
			pause_game()
		elif state == GameState.PAUSED:
			resume_game()


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
	spawn_director.banner_requested.connect(ui.show_banner)
	spawn_director.shake_requested.connect(arena_view.shake)
	weapon_system.projectile_requested.connect(combat_director.spawn_projectile)
	weapon_system.damage_dealt.connect(_on_damage_dealt)
	weapon_system.burst_requested.connect(combat_director.spawn_burst)
	weapon_system.shake_requested.connect(arena_view.shake)
	weapon_system.tone_requested.connect(audio.tone)
	combat_director.damage_dealt.connect(_on_damage_dealt)
	combat_director.enemy_defeated.connect(_on_enemy_defeated)
	combat_director.resonance_gained.connect(add_resonance)
	combat_director.flux_gained.connect(session.add_flux)
	combat_director.repair_collected.connect(_repair_player)
	combat_director.banner_requested.connect(ui.show_banner)
	combat_director.shake_requested.connect(arena_view.shake)
	combat_director.tone_requested.connect(audio.tone)
	ui.deploy_requested.connect(start_run)
	ui.resume_requested.connect(resume_game)
	ui.abandon_requested.connect(_abandon_run)
	ui.retry_requested.connect(start_run)
	ui.menu_requested.connect(show_menu)
	ui.reset_requested.connect(_reset_profile)
	ui.meta_upgrade_requested.connect(_buy_meta_upgrade)
	ui.mastery_allocation_requested.connect(_adjust_mastery_allocation)
	ui.library_requested.connect(_show_library)
	ui.upgrades_requested.connect(show_upgrades)
	ui.callibrations_requested.connect(show_callibrations)


func start_run() -> void:
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
	player.configure({
		"damage": profile.bonus("damage"),
		"hull": profile.bonus("hull"),
		"thrusters": profile.bonus("thrusters"),
		"magnet": profile.bonus("magnet"),
	})
	add_child(player)
	combat_director.configure(player, profile, session)
	weapon_system.configure(player, profile, session)
	spawn_director.configure(session)
	arena_view.player = player
	arena_view.combat_visible = true
	player.active = true
	state = GameState.RUNNING
	ui.show_run()
	ui.show_banner("SECTOR 01 // SIGNAL ACQUIRED", GamePalette.CYAN)
	ui.update_hud(session, weapon_system.weapons)
	audio.tone(220.0, 0.18, 0.2, 600.0)


func show_menu() -> void:
	_set_run_entities_paused(false)
	state = GameState.MENU
	_clear_run()
	arena_view.combat_visible = false
	ui.show_menu(profile)


func show_upgrades() -> void:
	if state == GameState.MENU:
		ui.show_upgrades(profile)


func show_callibrations() -> void:
	if state == GameState.MENU:
		ui.show_callibrations(profile)


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
	audio.tone(180.0, 0.4, 0.2, -120.0)


func _set_combat_active(value: bool) -> void:
	_set_run_entities_paused(not value)
	if is_instance_valid(player):
		player.active = value
	weapon_system.active = value


func _set_run_entities_paused(value: bool) -> void:
	for node: Node in get_tree().get_nodes_in_group("run_entities"):
		if is_instance_valid(node):
			node.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT


func _on_enemy_defeated(_kind: String) -> void:
	session.register_kill()


func _on_damage_dealt(weapon: String, amount: float, world_position: Vector2, target_id: int) -> void:
	session.record_damage(weapon, amount)
	if is_instance_valid(player):
		session.behavior.record_damage(target_id, player.global_position.distance_to(world_position), amount)
	if amount > 0.0 and randf() < 0.12:
		combat_director.spawn_burst(world_position, GamePalette.CYAN if weapon == "pulse" else GamePalette.GREEN, 12.0, 4)


func _repair_player(amount: float) -> void:
	if is_instance_valid(player):
		player.heal(amount)


func add_resonance(amount: int) -> void:
	session.add_resonance(amount)


func _on_level_gained(count: int) -> void:
	if state != GameState.RUNNING or not is_instance_valid(player):
		return
	for _index in count:
		var id := session.behavior.corner_id()
		var rank := session.register_evolution(id)
		var mutation := EvolutionCatalog.apply(id, rank, weapon_system.weapons, player)
		var active_weapons: Array[String] = []
		for weapon_id: String in WeaponCatalog.ORDER:
			if int(weapon_system.weapons[weapon_id]["level"]) > 0:
				active_weapons.append(weapon_id)
		active_weapons.append(id)
		profile.discover_entries(active_weapons)
		weapon_system.on_evolution_applied()
		session.pending_levels = maxi(0, session.pending_levels - 1)
		ui.show_evolution(mutation, session.behavior.display_profile())
		audio.tone(360.0 + rank * 18.0, 0.14, 0.18, 900.0)


func _buy_meta_upgrade(id: String) -> void:
	if profile.buy_upgrade(id):
		audio.tone(420.0, 0.1, 0.15, 500.0)
		ui.show_upgrades(profile)


func _adjust_mastery_allocation(id: String, delta: int) -> void:
	if state == GameState.MENU and profile.adjust_mastery_allocation(id, delta):
		audio.tone(460.0 if delta > 0 else 280.0, 0.06, 0.1, 220.0)
		ui.show_callibrations(profile)


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
	arena_view.player = null
