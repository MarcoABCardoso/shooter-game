extends SceneTree

const MetaUpgradeData := preload("res://scripts/content/meta_upgrade_catalog.gd")


func _initialize() -> void:
	_validate_enemies()
	_validate_weapons()
	_validate_evolutions()
	_validate_library()
	print("CATALOG_OK enemy, weapon, behavior-evolution, library, and meta-upgrade contracts validated")
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
		assert(loadout[id].has("level"), "Weapon %s needs a level" % id)
		assert(loadout[id].has("damage"), "Weapon %s needs damage" % id)
	assert(loadout["pulse"].has("projectile_speed"), "Pulse needs a tunable projectile speed")


func _validate_evolutions() -> void:
	assert(EvolutionCatalog.DEFINITIONS.size() == 8, "Three behavior axes should define eight extreme profiles")
	for id: String in EvolutionCatalog.DEFINITIONS:
		var definition: Dictionary = EvolutionCatalog.DEFINITIONS[id]
		assert(id.count("_") == 2, "Evolution ids should encode all three axes")
		assert(definition.has("name"), "Evolution %s needs a name" % id)
		assert(definition.has("description"), "Evolution %s needs a description" % id)
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
