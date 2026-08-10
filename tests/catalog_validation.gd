extends SceneTree

const StageCatalog := preload("res://scripts/content/stage_catalog.gd")


func _initialize() -> void:
	_validate_enemies()
	_validate_stages()
	_validate_weapons()
	_validate_run_upgrades()
	_validate_skill_tree()
	_validate_library()
	print("CATALOG_OK stages, enemies, loadout, deterministic run upgrades, expanded skill tree, and mastery validated")
	quit(0)


func _validate_enemies() -> void:
	var required := ["health", "speed", "contact_damage", "flux", "resonance", "radius", "shoot_interval"]
	for id: String in EnemyCatalog.DEFINITIONS:
		var definition: Dictionary = EnemyCatalog.DEFINITIONS[id]
		for field: String in required:
			assert(definition.has(field), "Enemy %s is missing %s" % [id, field])
		assert(float(definition["health"]) > 0.0, "Enemy health must be positive")
		assert(float(definition["radius"]) > 0.0, "Enemy radius must be positive")


func _validate_stages() -> void:
	assert(StageCatalog.ORDER.size() == 5, "The campaign should expose five selectable stages")
	for id: String in StageCatalog.ORDER:
		var definition := StageCatalog.definition(id)
		for field: String in ["number", "name", "duration", "description", "health_base", "health_growth", "spawn_base", "spawn_min", "spawn_pressure", "double_spawn_at", "elite_interval", "boss"]:
			assert(definition.has(field), "Stage %s is missing %s" % [id, field])
		assert(float(definition["duration"]) > 0.0, "Stage duration must be positive")
		assert(SaveProfile.DEFAULT_DATA["stages_cleared"].has(id), "Save defaults are missing %s" % id)
	assert(StageCatalog.choose_standard("stage_1", 999.0, 0.0) == "drone", "Stage 1 should contain drones only")
	assert(StageCatalog.choose_standard("stage_2", 20.0, 0.0) == "striker", "Stage 2 should introduce strikers")
	assert(float(StageCatalog.definition("stage_2")["elite_interval"]) == 0.0, "Elites should remain absent from Stage 2")
	assert(float(StageCatalog.definition("stage_3")["elite_interval"]) > 0.0, "Stage 3 should introduce elites")
	assert(not bool(StageCatalog.definition("stage_4")["boss"]) and bool(StageCatalog.definition("stage_5")["boss"]), "The boss should be reserved for Stage 5")


func _validate_weapons() -> void:
	var loadout := WeaponCatalog.fresh_loadout()
	assert(loadout.keys().size() == WeaponCatalog.ORDER.size(), "Weapon order and definitions must match")
	for id: String in WeaponCatalog.ORDER:
		assert(loadout.has(id), "Missing weapon definition: %s" % id)
		assert(SaveProfile.DEFAULT_DATA["mastery_xp"].has(id), "Save mastery defaults are missing %s" % id)
		assert(loadout[id].has("level"), "Weapon %s needs a level" % id)
		assert(loadout[id].has("damage"), "Weapon %s needs damage" % id)
	assert(loadout["pulse"].has("projectile_speed"), "Pulse needs a tunable projectile speed")
	assert(float(loadout["pulse"]["range"]) == 190.0, "Pulse should use its intentionally short auto-aim range")
	var drone_health := float(EnemyCatalog.DEFINITIONS["drone"]["health"])
	var stage_one_end_health := drone_health * GameBalance.enemy_difficulty("stage_1", float(StageCatalog.definition("stage_1")["duration"]))
	var stage_two_start_health := drone_health * GameBalance.enemy_difficulty("stage_2", 0.0)
	assert(float(loadout["pulse"]["damage"]) * 3.0 < stage_one_end_health, "Stage 1 Drones should survive three base Pulse hits after the weapon nerf")
	assert(float(loadout["pulse"]["damage"]) * 4.0 >= stage_one_end_health, "Stage 1 Drones should fall to four base Pulse hits")
	assert(float(loadout["pulse"]["damage"]) < stage_two_start_health, "Stage 2 Drones should require multiple base Pulse hits")


func _validate_run_upgrades() -> void:
	for weapon: String in WeaponCatalog.ORDER:
		var choices: Array = RunUpgradeCatalog.choices_for(weapon)
		assert(choices.size() == 3, "Weapon %s should expose exactly three deterministic dimensions" % weapon)
		for dimension: String in choices:
			var definition := RunUpgradeCatalog.definition(weapon, dimension)
			assert(definition.has("name") and definition.has("description"), "Run upgrade %s/%s needs player-facing copy" % [weapon, dimension])
	var loadout := WeaponCatalog.fresh_loadout(["pulse", "orbit", "arc", "nova"])
	for weapon: String in WeaponCatalog.ORDER:
		for dimension: String in RunUpgradeCatalog.choices_for(weapon):
			assert(RunUpgradeCatalog.apply(weapon, dimension, loadout), "Run upgrade %s/%s must mutate its weapon" % [weapon, dimension])


func _validate_skill_tree() -> void:
	assert(SkillTreeCatalog.ORDER.size() == SkillTreeCatalog.DEFINITIONS.size(), "Skill order and definitions must match")
	assert(SkillTreeCatalog.ORDER.size() >= 16, "The skill graph should provide a substantial permanent progression path")
	var staged_nodes := 0
	for id: String in SkillTreeCatalog.ORDER:
		var definition := SkillTreeCatalog.definition(id)
		assert(SaveProfile.DEFAULT_DATA["skill_ranks"].has(id), "Save defaults are missing skill %s" % id)
		for field in ["name", "description", "max_rank", "costs", "effect", "value", "position"]:
			assert(definition.has(field), "Skill %s is missing %s" % [id, field])
		assert(int(definition["max_rank"]) == definition["costs"].size(), "Skill %s needs one cost per rank" % id)
		var requirements: Dictionary = definition.get("requires", {})
		for prerequisite: String in requirements:
			assert(SkillTreeCatalog.DEFINITIONS.has(prerequisite), "Skill %s references missing prerequisite %s" % [id, prerequisite])
		var stage := String(definition.get("stage", ""))
		if not stage.is_empty():
			staged_nodes += 1
			assert(StageCatalog.ORDER.has(stage), "Skill %s references missing stage %s" % [id, stage])
	assert(staged_nodes >= 8, "The expanded tree should use stage gates across multiple tiers")
	assert(not SaveProfile.DEFAULT_DATA.has("upgrades"), "Permanent augments should no longer be stored in profiles")
	assert(SaveProfile._legacy_augment_refund({"damage": 2}) == 49, "Removed augment ranks should be refunded during save migration")


func _validate_library() -> void:
	assert(LibraryCatalog.ORDER.size() == LibraryCatalog.DEFINITIONS.size(), "Library order and definitions must match")
	for id: String in LibraryCatalog.ORDER:
		assert(LibraryCatalog.DEFINITIONS.has(id), "Library is missing %s" % id)
		assert(SaveProfile.DEFAULT_DATA["discovered"].has(id), "Save discovery defaults are missing %s" % id)
		for field in ["kind", "name", "role", "mechanics", "acquisition", "clue"]:
			assert(LibraryCatalog.DEFINITIONS[id].has(field), "Library entry %s is missing %s" % [id, field])
	assert(SaveProfile.DEFAULT_DATA["equipped_ability"] == "dash", "Phase Dash should remain the default ability")
	assert(SaveProfile.DEFAULT_DATA["equipped_weapons"] == ["pulse"], "The profile should begin with one equipped weapon")
	assert(not SaveProfile.DEFAULT_DATA["discovered"]["orbit"] and not SaveProfile.DEFAULT_DATA["discovered"]["arc"], "Only Pulse Cannon should be available from the beginning")
	assert(not SaveProfile.DEFAULT_DATA["discovered"]["nova"], "Nova should begin progression-locked")
	assert(not SaveProfile.DEFAULT_DATA["discovered"]["vector_parry"], "Vector Parry should begin locked")
