extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := SaveProfile.new()
	profile.data["skill_ranks"]["threat_uplink"] = 1
	profile.data["skill_ranks"]["breach_rounds"] = 1
	profile.data["skill_ranks"]["splash_payload"] = 1
	profile.data["skill_ranks"]["volatile_radius"] = 1
	profile.data["skill_ranks"]["reactive_shield"] = 2
	profile.data["skill_ranks"]["emergency_cycle"] = 1

	var player := NeonPlayer.new()
	root.add_child(player)
	player.configure({
		"shield": profile.skill_effect("shield"),
		"ability_cooldown": profile.skill_effect("ability_cooldown"),
	})
	player.active = true
	var health_before := player.health
	assert(player.take_damage(20.0), "A shielded hit should still register as a combat impact")
	assert(player.health == health_before and player.shield_charges == 1, "Reactive Shield should absorb damage and consume one charge")
	player.active = false
	player._physics_process(8.1)
	assert(player.shield_charges == 2, "A shield charge should return after the undamaged recharge delay")
	assert(player.ability_cooldown < 1.25, "Emergency Cycle should shorten active-skill recharge")

	var enemy := NeonEnemy.new()
	enemy.configure("drone", 1.0)
	enemy.global_position = player.global_position + Vector2(100.0, 0.0)
	root.add_child(enemy)
	var weapon_system := WeaponSystem.new()
	root.add_child(weapon_system)
	weapon_system.configure(player, profile, RunSession.new(), [enemy])
	var projectile_specs: Array[Dictionary] = []
	weapon_system.projectile_requested.connect(func(_origin, _direction, _damage, speed, _friendly, _weapon, pierce, radius, _distant_bonus, _knockback, max_range, splash_damage, splash_radius):
		projectile_specs.append({"speed": speed, "pierce": pierce, "radius": radius, "max_range": max_range, "splash_damage": splash_damage, "splash_radius": splash_radius})
	)
	weapon_system.cycle_target_mode()
	assert(weapon_system.fire_pulse(), "Pulse should fire at an enemy inside its targeting range")
	assert(projectile_specs.size() == 1, "The base Pulse Cannon should emit one projectile")
	var spec := projectile_specs[0]
	assert(float(spec["speed"]) == float(WeaponCatalog.DEFAULTS["pulse"]["projectile_speed"]) and float(spec["radius"]) == 4.0, "Removed speed and size nodes should not survive in runtime wiring")
	assert(int(spec["pierce"]) == 1, "Breach Rounds should cross a visible multi-target threshold")
	assert(float(spec["max_range"]) == float(WeaponCatalog.DEFAULTS["pulse"]["range"]) + 55.0, "Threat Uplink should extend tactical reach only in Ranged Threats mode")
	assert(float(spec["splash_damage"]) > 0.0 and float(spec["splash_radius"]) > 72.0, "Splash branches should configure damage and radius")

	print("SKILL_EFFECT_RUNTIME_OK shield, recharge, threat reach, pierce, and splash wiring validated")
	quit(0)
