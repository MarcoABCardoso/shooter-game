extends SceneTree

const MetaUpgradeData := preload("res://scripts/content/meta_upgrade_catalog.gd")


func _initialize() -> void:
	_validate_enemies()
	_validate_weapons()
	_validate_upgrades()
	print("CATALOG_OK enemy, weapon, run-upgrade, and meta-upgrade contracts validated")
	quit(0)


func _validate_enemies() -> void:
	var required := ["health", "speed", "contact_damage", "flux", "xp", "radius", "shoot_interval"]
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


func _validate_upgrades() -> void:
	var loadout := WeaponCatalog.fresh_loadout()
	for id: String in loadout:
		loadout[id]["level"] = 1
	var choices := UpgradeCatalog.available(10, loadout)
	var ids := {}
	for choice: Dictionary in choices:
		for field in ["id", "icon", "name", "description"]:
			assert(choice.has(field), "Run upgrade is missing %s" % field)
		assert(not ids.has(choice["id"]), "Duplicate run upgrade id: %s" % choice["id"])
		ids[choice["id"]] = true
	assert(SaveProfile.UPGRADE_MAX == MetaUpgradeData.MAX_RANK, "Profile and catalog max ranks must match")
	for definition: Dictionary in MetaUpgradeData.DEFINITIONS:
		var id := String(definition["id"])
		assert(SaveProfile.DEFAULT_DATA["upgrades"].has(id), "Save defaults missing permanent upgrade: %s" % id)
		assert(float(definition["bonus_per_rank"]) > 0.0, "Permanent upgrade bonus must be positive")
