extends SceneTree

const MetaUpgradeData := preload("res://scripts/content/meta_upgrade_catalog.gd")


func _initialize() -> void:
	_validate_enemies()
	_validate_weapons()
	_validate_run_upgrades()
	_validate_skill_tree()
	_validate_library()
	print("CATALOG_OK enemies, loadout, deterministic run upgrades, skill tree, mastery, and augments validated")
	quit(0)


func _validate_enemies() -> void:
	var required := ["health", "speed", "contact_damage", "flux", "resonance", "radius", "shoot_interval"]
	for id: String in EnemyCatalog.DEFINITIONS:
		var definition: Dictionary = EnemyCatalog.DEFINITIONS[id]
		for field: String in required:
			assert(definition.has(field), "Enemy %s is missing %s" % [id, field])
		assert(float(definition["health"]) > 0.0, "Enemy health must be positive")
		assert(float(definition["radius"]) > 0.0, "Enemy radius must be positive")


func _validate_weapons() -> void:
	var loadout := WeaponCatalog.fresh_loadout()
	assert(loadout.keys().size() == WeaponCatalog.ORDER.size(), "Weapon order and definitions must match")
	for id: String in WeaponCatalog.ORDER:
		assert(loadout.has(id), "Missing weapon definition: %s" % id)
		assert(SaveProfile.DEFAULT_DATA["mastery_xp"].has(id), "Save mastery defaults are missing %s" % id)
		assert(loadout[id].has("level"), "Weapon %s needs a level" % id)
		assert(loadout[id].has("damage"), "Weapon %s needs damage" % id)
	assert(loadout["pulse"].has("projectile_speed"), "Pulse needs a tunable projectile speed")


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
	for id: String in SkillTreeCatalog.ORDER:
		var definition := SkillTreeCatalog.definition(id)
		assert(SaveProfile.DEFAULT_DATA["skill_ranks"].has(id), "Save defaults are missing skill %s" % id)
		for field in ["name", "description", "max_rank", "costs", "effect", "value", "position"]:
			assert(definition.has(field), "Skill %s is missing %s" % [id, field])
		assert(int(definition["max_rank"]) == definition["costs"].size(), "Skill %s needs one cost per rank" % id)
		var requirements: Dictionary = definition.get("requires", {})
		for prerequisite: String in requirements:
			assert(SkillTreeCatalog.DEFINITIONS.has(prerequisite), "Skill %s references missing prerequisite %s" % [id, prerequisite])
	assert(SaveProfile.UPGRADE_MAX == MetaUpgradeData.MAX_RANK, "Profile and catalog max ranks must match")
	for definition: Dictionary in MetaUpgradeData.DEFINITIONS:
		var id := String(definition["id"])
		assert(SaveProfile.DEFAULT_DATA["upgrades"].has(id), "Save defaults missing permanent upgrade: %s" % id)
		assert(float(definition["bonus_per_rank"]) > 0.0, "Permanent upgrade bonus must be positive")


func _validate_library() -> void:
	assert(LibraryCatalog.ORDER.size() == LibraryCatalog.DEFINITIONS.size(), "Library order and definitions must match")
	for id: String in LibraryCatalog.ORDER:
		assert(LibraryCatalog.DEFINITIONS.has(id), "Library is missing %s" % id)
		assert(SaveProfile.DEFAULT_DATA["discovered"].has(id), "Save discovery defaults are missing %s" % id)
		for field in ["kind", "name", "role", "mechanics", "acquisition", "clue"]:
			assert(LibraryCatalog.DEFINITIONS[id].has(field), "Library entry %s is missing %s" % [id, field])
	assert(SaveProfile.DEFAULT_DATA["equipped_ability"] == "dash", "Phase Dash should remain the default ability")
	assert(SaveProfile.DEFAULT_DATA["equipped_weapons"] == ["pulse"], "The profile should begin with one equipped weapon")
	assert(SaveProfile.DEFAULT_DATA["discovered"]["orbit"] and SaveProfile.DEFAULT_DATA["discovered"]["arc"], "Three weapons should be available from the beginning")
	assert(not SaveProfile.DEFAULT_DATA["discovered"]["nova"], "Nova should begin progression-locked")
	assert(not SaveProfile.DEFAULT_DATA["discovered"]["vector_parry"], "Vector Parry should begin locked")
