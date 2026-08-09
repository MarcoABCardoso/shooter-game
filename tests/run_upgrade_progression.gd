extends SceneTree


func _initialize() -> void:
	var session := RunSession.new()
	var loadout := WeaponCatalog.fresh_loadout(["pulse", "arc"])
	var base_damage := float(loadout["pulse"]["damage"])
	for rank in RunUpgradeCatalog.MAX_RANK:
		assert(session.can_upgrade_weapon("pulse", "damage"), "Pulse damage should accept rank %d" % (rank + 1))
		assert(RunUpgradeCatalog.apply("pulse", "damage", loadout), "Catalog application should succeed")
		assert(session.register_weapon_upgrade("pulse", "damage"), "Session rank registration should succeed")
	assert(session.weapon_upgrade_rank("pulse", "damage") == RunUpgradeCatalog.MAX_RANK, "Run dimensions should stop at the shared cap")
	assert(not session.can_upgrade_weapon("pulse", "damage"), "A capped dimension should reject another rank")
	assert(float(loadout["pulse"]["damage"]) > base_damage, "Repeated damage choices should stack")
	assert(session.weapon_upgrade_rank("arc", "damage") == 0, "Choosing Pulse must not improve another equipped weapon")
	session.reset()
	assert(session.weapon_upgrade_rank("pulse", "damage") == 0, "Run evolution should reset between deployments")
	print("RUN_UPGRADES_OK deterministic choices, per-weapon ownership, stacking, cap, and run reset validated")
	quit(0)
