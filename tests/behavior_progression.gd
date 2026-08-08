extends SceneTree


func _initialize() -> void:
	_validate_anchored_distant_focus()
	_validate_roaming_close_spread()
	_validate_mutation_application()
	print("BEHAVIOR_OK continuous sampling, profile steering, and mutations validated")
	quit(0)


func _validate_anchored_distant_focus() -> void:
	var profile := BehaviorProfile.new()
	for _step in 600:
		profile.tick(0.016, Vector2.ZERO, 300.0, 3)
	for _hit in 20:
		profile.record_damage(101, 440.0, 15.0)
	assert(profile.anchored_roaming < -0.5, "Holding position should steer toward Anchored")
	assert(profile.close_distant > 0.5, "Long-range damage should steer toward Distant")
	assert(profile.focus_spread < -0.5, "Repeated damage to one target should steer toward Focus")
	assert(profile.corner_id() == "anchored_distant_focus", "Combined behavior should select Siege Needle")


func _validate_roaming_close_spread() -> void:
	var profile := BehaviorProfile.new()
	for _step in 600:
		profile.tick(0.016, Vector2(300.0, 0.0), 300.0, 5)
	for _round in 12:
		for target_id in range(1, 7):
			profile.record_damage(target_id, 70.0, 10.0)
	assert(profile.anchored_roaming > 0.5, "Sustained movement should steer toward Roaming")
	assert(profile.close_distant < -0.5, "Short-range damage should steer toward Close")
	assert(profile.focus_spread > 0.25, "Damage distributed across targets should steer toward Spread")
	assert(profile.corner_id() == "roaming_close_spread", "Combined behavior should select Comet Swarm")


func _validate_mutation_application() -> void:
	var loadout := WeaponCatalog.fresh_loadout()
	var player := NeonPlayer.new()
	player.configure({})
	var mutation := EvolutionCatalog.apply("roaming_close_spread", 1, loadout, player)
	assert(int(loadout["orbit"]["level"]) == 1, "Comet Swarm should unlock orbit blades at rank one")
	assert(int(loadout["nova"]["level"]) == 1, "Comet Swarm should unlock nova at rank one")
	assert(mutation["name"] == "COMET SWARM", "Mutation feedback should identify the applied evolution")
