extends SceneTree

const EncounterCatalog := preload("res://scripts/content/encounter_catalog.gd")
const OperationCatalog := preload("res://scripts/content/operation_catalog.gd")
const OperationEvolutionCatalog := preload("res://scripts/content/operation_evolution_catalog.gd")


func _initialize() -> void:
	_validate_enemies()
	_validate_encounters()
	_validate_operations()
	_validate_operation_evolutions()
	_validate_weapons()
	_validate_skill_tree()
	_validate_library()
	print("CATALOG_OK operation encounters, sparse evolutions, enemies, loadout, skill tree, and mastery validated")
	quit(0)


func _validate_enemies() -> void:
	var required := ["health", "speed", "contact_damage", "flux", "resonance", "radius", "shoot_interval"]
	for id: String in EnemyCatalog.DEFINITIONS:
		var definition: Dictionary = EnemyCatalog.DEFINITIONS[id]
		for field: String in required:
			assert(definition.has(field), "Enemy %s is missing %s" % [id, field])
		assert(float(definition["health"]) > 0.0, "Enemy health must be positive")
		assert(float(definition["radius"]) > 0.0, "Enemy radius must be positive")


func _validate_encounters() -> void:
	assert(EncounterCatalog.ORDER.size() == 3, "Signal Breach should own three encounter profiles")
	for id: String in EncounterCatalog.ORDER:
		var definition := EncounterCatalog.definition(id)
		for field: String in ["duration", "health_base", "health_growth", "spawn_base", "spawn_min", "spawn_pressure", "double_spawn_at", "elite_interval", "boss"]:
			assert(definition.has(field), "Encounter %s is missing %s" % [id, field])
		assert(float(definition["duration"]) > 0.0, "Encounter duration must be positive")
		assert(not bool(definition["boss"]), "The current operation slice should not inherit a campaign boss")
	assert(EncounterCatalog.choose_standard("defense_swarm", 999.0, 0.0) == "drone", "Signal Defense should use its focused drone pressure")
	assert(EncounterCatalog.choose_standard("striker_assault", 20.0, 0.0) == "striker", "The second mission should introduce Strikers")
	assert(EncounterCatalog.choose_standard("gunner_assault", 30.0, 0.0) == "gunner", "The finale should introduce Gunners")


func _validate_operations() -> void:
	assert(OperationCatalog.ORDER == ["signal_breach"], "Chapter 1 should expose one representative operation")
	var missions := OperationCatalog.missions("signal_breach")
	assert(missions.size() == 3, "The representative operation should contain three missions")
	var mission_ids: Array[String] = []
	var referenced_encounters: Array[String] = []
	for mission: Dictionary in missions:
		assert(mission.has("id") and mission.has("name") and mission.has("rhythm") and mission.has("lifecycle") and mission.has("encounter_id"), "Operation missions should contain their lifecycle and encounter data")
		assert(not mission_ids.has(String(mission["id"])), "Operation mission IDs should be unique")
		assert(EncounterCatalog.ORDER.has(String(mission["encounter_id"])), "Operation missions should reference an existing encounter profile")
		mission_ids.append(String(mission["id"]))
		referenced_encounters.append(String(mission["encounter_id"]))
	assert(referenced_encounters == EncounterCatalog.ORDER, "Encounter profiles should exist only for missions consumed by Signal Breach")
	assert(String(missions[0]["lifecycle"]) == "signal_defense", "The operation should open with the distinct Signal Defense rhythm")
	assert(OperationCatalog.retreat_flux("signal_breach", 101) == 75, "Retreat should recover 75% of earned Flux, rounded down")
	assert(OperationCatalog.defeat_flux("signal_breach", 101) == 50, "Defeat should recover only half of earned Flux, rounded down")


func _validate_operation_evolutions() -> void:
	assert(OperationEvolutionCatalog.tier_for_level(2) == 1 and OperationEvolutionCatalog.tier_for_level(4) == 2, "Operation evolution breakpoints should remain sparse and visible")
	assert(OperationEvolutionCatalog.tier_for_level(3) == 0, "Ordinary resonance levels should not interrupt combat")
	assert(OperationEvolutionCatalog.choices_for(1, []) == ["bastion_array", "scatter_array"], "The first transformation should choose between Bastion and Scatter behavior")
	assert(OperationEvolutionCatalog.choices_for(2, ["bastion_array"]) == ["gravity_well", "phase_mooring"], "Bastion should expose only its visible follow-up choices")
	assert(OperationEvolutionCatalog.choices_for(2, ["scatter_array"]) == ["overrun_choke", "escape_velocity"], "Scatter should expose only its visible follow-up choices")
	var loadout := WeaponCatalog.fresh_loadout(["pulse"])
	var projectile_speed := float(loadout["pulse"]["projectile_speed"])
	OperationEvolutionCatalog.apply_automatic_growth(loadout, 1)
	assert(float(loadout["pulse"]["damage"]) > 5.0 and float(loadout["pulse"]["interval"]) < 0.34, "Automatic growth should raise baseline Pulse output")
	assert(float(loadout["pulse"]["projectile_speed"]) == projectile_speed, "Projectile speed should not return as a generic growth axis")


func _validate_weapons() -> void:
	var loadout := WeaponCatalog.fresh_loadout()
	assert(loadout.keys().size() == WeaponCatalog.ORDER.size(), "Weapon order and definitions must match")
	for id: String in WeaponCatalog.ORDER:
		assert(loadout.has(id), "Missing weapon definition: %s" % id)
		assert(SaveProfile.DEFAULT_DATA["mastery_xp"].has(id), "Save mastery defaults are missing %s" % id)
		assert(loadout[id].has("level") and loadout[id].has("damage"), "Weapon %s needs level and damage values" % id)
	assert(float(loadout["pulse"]["damage"]) == 5.0 and float(loadout["pulse"]["range"]) == 190.0, "Pulse should keep its short-range baseline")
	var drone_health := float(EnemyCatalog.DEFINITIONS["drone"]["health"])
	var defense_end_health := drone_health * GameBalance.enemy_difficulty("defense_swarm", float(EncounterCatalog.definition("defense_swarm")["duration"]))
	assert(float(loadout["pulse"]["damage"]) * 2.0 < defense_end_health and float(loadout["pulse"]["damage"]) * 3.0 >= defense_end_health, "Defense Drones should fall to three base Pulse hits")


func _validate_skill_tree() -> void:
	assert(SkillTreeCatalog.ORDER.size() == SkillTreeCatalog.DEFINITIONS.size(), "Skill order and definitions must match")
	for id: String in SkillTreeCatalog.ORDER:
		var definition := SkillTreeCatalog.definition(id)
		assert(SaveProfile.DEFAULT_DATA["skill_ranks"].has(id), "Save defaults are missing skill %s" % id)
		for field in ["name", "description", "max_rank", "costs", "effect", "value", "position"]:
			assert(definition.has(field), "Skill %s is missing %s" % [id, field])
		assert(int(definition["max_rank"]) == definition["costs"].size(), "Skill %s needs one cost per rank" % id)
		for prerequisite: String in definition.get("requires", {}):
			assert(SkillTreeCatalog.DEFINITIONS.has(prerequisite), "Skill %s references missing prerequisite %s" % [id, prerequisite])


func _validate_library() -> void:
	assert(LibraryCatalog.ORDER.size() == LibraryCatalog.DEFINITIONS.size(), "Library order and definitions must match")
	for id: String in LibraryCatalog.ORDER:
		assert(SaveProfile.DEFAULT_DATA["discovered"].has(id), "Save discovery defaults are missing %s" % id)
		for field in ["kind", "name", "role", "mechanics", "acquisition", "clue"]:
			assert(LibraryCatalog.DEFINITIONS[id].has(field), "Library entry %s is missing %s" % [id, field])
	assert(SaveProfile.DEFAULT_DATA["equipped_ability"] == "dash" and SaveProfile.DEFAULT_DATA["equipped_weapons"] == ["pulse"], "A profile should begin with Pulse and Phase Dash")
	assert(SaveProfile.new().unlocked_weapon_slots() == 1, "The operation prototype should expose one weapon slot")
