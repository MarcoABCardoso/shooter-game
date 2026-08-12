extends SceneTree

const OperationEvolutionCatalog := preload("res://scripts/content/operation_evolution_catalog.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := SaveProfile.new()
	for id: String in LibraryCatalog.ORDER:
		profile.data["discovered"][id] = true
	for id: String in WeaponCatalog.ORDER:
		profile.data["mastery_xp"][id] = 140.0

	var player := NeonPlayer.new()
	root.add_child(player)
	player.configure({"ability": "gravity_tether"})
	player.global_position = Vector2(300.0, 300.0)
	var tether_requests: Array[Vector2] = []
	player.gravity_tether_requested.connect(func(world_position: Vector2) -> void: tether_requests.append(world_position))
	player.active = true
	player.set_mobile_controls_enabled(true)
	player.request_mobile_ability()
	player._physics_process(0.01)
	assert(tether_requests.size() == 1 and tether_requests[0].x > player.global_position.x, "Gravity Tether input should project a formation point ahead without requiring movement")
	player.active = false
	var session := RunSession.new()
	var enemies: Array[NeonEnemy] = []
	var weapon_system := WeaponSystem.new()
	root.add_child(weapon_system)

	profile.data["equipped_weapons"] = ["orbit"]
	weapon_system.configure(player, profile, session, enemies)
	assert(weapon_system.apply_operation_evolution("razor_orbit"), "Orbit should accept its Interceptor transformation")
	player.velocity = Vector2.ZERO
	var still_orbit_damage := weapon_system._scaled_damage("orbit", 10.0)
	player.velocity = Vector2(120.0, 0.0)
	assert(weapon_system._scaled_damage("orbit", 10.0) > still_orbit_damage, "Interceptor should reward active pursuit")
	assert(weapon_system.apply_operation_evolution("pursuit_edge") and weapon_system.orbit_radius() > 64.0, "Mastered Interceptor should expand while moving")

	profile.data["equipped_weapons"] = ["arc"]
	session = RunSession.new()
	weapon_system.configure(player, profile, session, enemies)
	assert(weapon_system.apply_operation_evolution("storm_chain"), "Arc should accept its Conduit transformation")
	assert(int(weapon_system.weapons["arc"]["chains"]) == 5, "Conduit should create a visible five-target chain")
	assert(weapon_system.apply_operation_evolution("feedback_loop"), "Arc mastery should reveal Feedback Loop")
	assert(float(weapon_system.weapons["arc"]["chain_falloff"]) > 1.0, "Feedback Loop should reward dense formations instead of duplicating damage ranks")

	profile.data["equipped_weapons"] = ["nova"]
	session = RunSession.new()
	weapon_system.configure(player, profile, session, enemies)
	assert(weapon_system.apply_operation_evolution("gravity_nova"), "Nova should accept its Singularity transformation")
	assert(float(weapon_system.weapons["nova"]["pull_radius"]) > float(weapon_system.weapons["nova"]["radius"]), "Singularity should set up enemies beyond the damage ring")
	assert(weapon_system.apply_operation_evolution("compression_cycle"), "Nova mastery should reveal Compression Cycle")

	var carrier := NeonEnemy.new()
	carrier.configure("carrier", 1.0)
	carrier.global_position = Vector2(500.0, 300.0)
	root.add_child(carrier)
	enemies.append(carrier)
	var combat := CombatDirector.new()
	root.add_child(combat)
	combat.configure(player, profile, session, "overseer_lock")
	combat.enemies.append(carrier)
	combat.gravity_tether(Vector2(400.0, 300.0))
	assert(carrier.knockback_velocity.x < 0.0, "Gravity Tether should pull a formation toward its projected setup point")
	assert(player.ability_cooldown > 3.0, "Gravity Tether should be a deliberate setup tool, not an interchangeable Dash cooldown")

	assert(OperationEvolutionCatalog.build_name(["bastion_array"]) == "SENTINEL", "Named builds should be available to HUD and Library presentation")
	assert(OperationEvolutionCatalog.build_name(["aegis_orbit"]) == "AEGIS", "Every weapon family should expose its named tactical identity")
	print("BUILD_BREADTH_OK named weapon plans, mastery follow-ups, formation pressure, and Gravity Tether validated")
	quit(0)
