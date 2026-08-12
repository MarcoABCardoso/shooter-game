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
	print("CATALOG_OK opening sector, encounters, rewards, sparse evolutions, loadout, skill tree, and mastery validated")
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
	assert(EncounterCatalog.ORDER.size() == 4, "The opening sector should own four encounter profiles")
	for id: String in EncounterCatalog.ORDER:
		var definition := EncounterCatalog.definition(id)
		for field: String in ["duration", "health_base", "health_growth", "spawn_base", "spawn_min", "spawn_pressure", "double_spawn_at", "elite_interval", "boss"]:
			assert(definition.has(field), "Encounter %s is missing %s" % [id, field])
		assert(float(definition["duration"]) > 0.0, "Encounter duration must be positive")
	assert(not bool(EncounterCatalog.definition("defense_swarm")["boss"]), "Signal Defense should remain a focused opener")
	assert(not bool(EncounterCatalog.definition("cache_pressure")["boss"]), "The optional cache should remain objective-driven")
	assert(not bool(EncounterCatalog.definition("relay_breach")["boss"]), "The relay mission should end through its objective")
	assert(bool(EncounterCatalog.definition("overseer_lock")["boss"]), "Overseer Lock should own the boss encounter")
	assert(EncounterCatalog.choose_standard("defense_swarm", 999.0, 0.0) == "drone", "Signal Defense should use its focused drone pressure")
	assert(EncounterCatalog.choose_standard("cache_pressure", 20.0, 0.0) == "gunner", "The exposed cache should introduce ranged pressure")
	assert(EncounterCatalog.choose_standard("relay_breach", 20.0, 0.0) == "striker", "The breach should use Strikers to pressure relay approaches")
	assert(EncounterCatalog.choose_standard("overseer_lock", 10.0, 0.0) == "gunner", "The finale should expose projectiles before the Overseer")
	assert(EncounterCatalog.choose_standard("overseer_lock", 10.0, 0.25) == "carrier", "The finale should mix in formation-splitting Carriers for build comparison")


func _validate_operations() -> void:
	assert(OperationCatalog.ORDER == ["signal_hold", "drift_cache", "relay_breach", "overseer_lock"], "Chapter 2 should expose the complete opening-sector route")
	var referenced_encounters: Array[String] = []
	for stage_id: String in OperationCatalog.ORDER:
		var stage := OperationCatalog.definition(stage_id)
		var mission := OperationCatalog.mission(stage_id)
		assert(stage.has("name") and stage.has("description") and stage.has("mission") and stage.has("prerequisites"), "Stage %s should own one focused mission and route requirements" % stage_id)
		assert(stage.has("required") and stage.has("route_position") and stage.has("first_clear_flux") and stage.has("first_clear_discoveries"), "Stage %s should expose its campaign role, route position, and first-clear reward" % stage_id)
		var route_position: Vector2 = stage["route_position"]
		assert(route_position.x > 0.0 and route_position.x < 1.0 and route_position.y > 0.0 and route_position.y < 1.0, "Stage %s should remain inside the route view" % stage_id)
		for prerequisite: String in stage["prerequisites"]:
			assert(OperationCatalog.DEFINITIONS.has(prerequisite), "Stage %s should reference an existing route prerequisite" % stage_id)
		assert(mission.has("id") and mission.has("name") and mission.has("rhythm") and mission.has("lifecycle") and mission.has("encounter_id"), "Stage missions should contain their lifecycle and encounter data")
		assert(mission.has("music"), "Every opening-sector mission should carry representative music")
		assert(not mission.has("speaker") and not mission.has("transmission"), "Mission dialogue should wait for a deliberate narrative treatment")
		assert(float(mission.get("time_limit", 0.0)) > 0.0, "Every mission should expose a content-defined anti-farming deadline")
		assert(EncounterCatalog.ORDER.has(String(mission["encounter_id"])), "Stage missions should reference an existing encounter profile")
		referenced_encounters.append(String(mission["encounter_id"]))
	assert(referenced_encounters == EncounterCatalog.ORDER, "Each encounter profile should belong to one sector stage")
	var hold := OperationCatalog.mission("signal_hold")
	var hold_objectives := hold["objectives"] as Array
	assert(String(hold["lifecycle"]) == "objective_sequence" and hold_objectives.size() == 3, "Signal Hold should progress through three sequential objectives")
	var total_hold_time := 0.0
	var previous_hold_position := Vector2.ZERO
	var previous_hold_arena := Rect2()
	for objective: Dictionary in hold_objectives:
		assert(String(objective["lifecycle"]) == "signal_defense" and objective.has("name"), "Signal Hold objectives should deepen one readable defense rhythm")
		assert(objective.has("arena_rect") and objective.has("objective_position") and objective.has("objective_radius") and objective.has("hold_duration") and objective.has("decay_rate"), "Every defense objective should own its chamber, field, and timing")
		var objective_arena: Rect2 = objective["arena_rect"]
		assert(objective_arena.has_point(objective["objective_position"]), "Every defense field should remain inside its objective chamber")
		if previous_hold_arena.has_area():
			assert(objective_arena.position.x > previous_hold_arena.end.x, "Sequential chambers should create meaningful forward travel")
		assert(objective["objective_position"] != previous_hold_position, "Sequential defense objectives should advance across the arena")
		previous_hold_position = objective["objective_position"]
		previous_hold_arena = objective_arena
		total_hold_time += float(objective["hold_duration"])
	assert(float(hold["time_limit"]) >= total_hold_time * 2.0, "The fresh-profile opener should leave generous travel and recovery time")
	assert(OperationCatalog.mission_arenas("signal_hold").size() == 3, "Signal Hold should expose three camera chambers")
	var breach := OperationCatalog.mission("relay_breach")
	var breach_objectives := breach["objectives"] as Array
	assert(String(breach["lifecycle"]) == "objective_sequence" and breach_objectives.size() == 3, "Relay Breach should reveal three relay groups sequentially")
	for objective: Dictionary in breach_objectives:
		assert(String(objective["lifecycle"]) == "relay_breach" and (objective["relay_positions"] as Array).size() == 2, "Each breach step should expose a readable relay pair")
		var objective_arena: Rect2 = objective["arena_rect"]
		for relay_position: Vector2 in objective["relay_positions"]:
			assert(objective_arena.has_point(relay_position), "Relay pairs should remain inside their active chamber")
	assert(String((breach_objectives[2]["reinforcements"] as Array)[0]["kind"]) == "carrier", "The final breach chamber should introduce a crowd-control build check")
	assert(String(OperationCatalog.mission("overseer_lock")["lifecycle"]) == "boss", "Overseer Lock should be a focused boss stage")
	assert(OperationCatalog.mission_arenas("overseer_lock") == [GameBalance.ARENA], "The boss should retain one constrained gauntlet arena")
	var cache := OperationCatalog.mission("drift_cache")
	var cache_objectives := cache["objectives"] as Array
	assert(String(cache["lifecycle"]) == "objective_sequence" and cache_objectives.size() == 2, "The optional cache should progress from approach to extraction")
	assert(cache_objectives[0]["objective_position"] != hold_objectives[0]["objective_position"], "The optional cache should recompose defense at a distinct arena position")
	var fresh_clears: Dictionary = SaveProfile.DEFAULT_DATA["stage_clears"].duplicate(true)
	assert(OperationCatalog.is_unlocked("signal_hold", fresh_clears), "Signal Hold should be the only entry stage")
	assert(not OperationCatalog.is_unlocked("drift_cache", fresh_clears) and not OperationCatalog.is_unlocked("relay_breach", fresh_clears), "Later routes should wait for the opener")
	fresh_clears["signal_hold"] = 1
	assert(OperationCatalog.is_unlocked("drift_cache", fresh_clears) and OperationCatalog.is_unlocked("relay_breach", fresh_clears), "The opener should reveal required and optional branches together")
	assert(not OperationCatalog.is_unlocked("overseer_lock", fresh_clears), "The boss should wait for the required breach")
	var signal_position: Vector2 = OperationCatalog.definition("signal_hold")["route_position"]
	var relay_position: Vector2 = OperationCatalog.definition("relay_breach")["route_position"]
	var boss_position: Vector2 = OperationCatalog.definition("overseer_lock")["route_position"]
	var cache_position: Vector2 = OperationCatalog.definition("drift_cache")["route_position"]
	assert(is_equal_approx(signal_position.y, relay_position.y) and is_equal_approx(relay_position.y, boss_position.y), "Required stages should form one visible route spine")
	assert(cache_position.y > relay_position.y and is_equal_approx(cache_position.x, relay_position.x), "Drift Cache should sit visibly off the required route")
	assert(OperationCatalog.first_clear_flux("drift_cache") >= SkillTreeCatalog.cost_for_rank("core_damage", 0), "The optional route should fund meaningful permanent growth")
	assert(OperationCatalog.first_clear_discoveries("drift_cache") == ["vector_parry"], "The optional cache should unlock a boss-relevant configuration")
	assert(OperationCatalog.retreat_flux("signal_hold", 101) == 75, "Retreat should recover 75% of earned Flux, rounded down")
	assert(OperationCatalog.defeat_flux("overseer_lock", 101) == 50, "Defeat should recover only half of earned Flux, rounded down")


func _validate_operation_evolutions() -> void:
	assert(OperationEvolutionCatalog.tier_for_level(2) == 1 and OperationEvolutionCatalog.tier_for_level(5) == 2, "Operation evolution breakpoints should remain sparse and separated")
	assert(OperationEvolutionCatalog.tier_for_level(3) == 0 and OperationEvolutionCatalog.tier_for_level(4) == 0, "Ordinary resonance levels should not interrupt combat")
	assert(OperationEvolutionCatalog.choices_for(1, []) == ["bastion_array", "scatter_array"], "The first transformation should choose between Bastion and Scatter behavior")
	assert(OperationEvolutionCatalog.choices_for(2, ["bastion_array"]) == ["gravity_well"], "A fresh Bastion should expose its standard follow-up")
	assert(OperationEvolutionCatalog.choices_for(2, ["bastion_array"], "pulse", 1) == ["gravity_well", "phase_mooring"], "Pulse mastery should reveal Phase Mooring as a revisitation choice")
	assert(OperationEvolutionCatalog.choices_for(1, [], "orbit") == ["razor_orbit", "aegis_orbit"], "Orbit should choose between pursuit and projectile-screen identities")
	assert(OperationEvolutionCatalog.choices_for(1, [], "arc") == ["storm_chain", "execution_arc"], "Arc should choose between formation clearing and priority execution")
	assert(OperationEvolutionCatalog.choices_for(1, [], "nova") == ["gravity_nova", "purge_nova"], "Nova should choose between setup and projectile-clearing identities")
	assert(OperationEvolutionCatalog.ORDER.size() == OperationEvolutionCatalog.DEFINITIONS.size(), "Every named transformation should be ordered exactly once")
	for id: String in OperationEvolutionCatalog.ORDER:
		var definition := OperationEvolutionCatalog.definition(id)
		for field: String in ["weapon", "name", "tier", "branch", "requires", "build", "description", "future", "mastery"]:
			assert(definition.has(field), "Evolution %s is missing %s" % [id, field])
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
	assert(not ["projectile_speed", "projectile_size"].has(SkillTreeCatalog.definition("threat_uplink")["effect"]), "The automatic-targeting tree should not restore imperceptible projectile axes")
	for removed_effect: String in ["projectile_speed", "projectile_size"]:
		for id: String in SkillTreeCatalog.ORDER:
			assert(String(SkillTreeCatalog.definition(id)["effect"]) != removed_effect, "Permanent nodes should replace dead %s bonuses" % removed_effect)


func _validate_library() -> void:
	assert(LibraryCatalog.ORDER.size() == LibraryCatalog.DEFINITIONS.size(), "Library order and definitions must match")
	for id: String in LibraryCatalog.ORDER:
		assert(SaveProfile.DEFAULT_DATA["discovered"].has(id), "Save discovery defaults are missing %s" % id)
		for field in ["kind", "name", "role", "mechanics", "plans", "acquisition", "clue"]:
			assert(LibraryCatalog.DEFINITIONS[id].has(field), "Library entry %s is missing %s" % [id, field])
	assert(SaveProfile.DEFAULT_DATA["equipped_ability"] == "dash" and SaveProfile.DEFAULT_DATA["equipped_weapons"] == ["pulse"], "A profile should begin with Pulse and Phase Dash")
	assert(not bool(SaveProfile.DEFAULT_DATA["discovered"]["vector_parry"]), "Vector Parry should begin as an optional-route reward")
	for stage_id: String in OperationCatalog.ORDER:
		assert(SaveProfile.DEFAULT_DATA["stage_clears"].has(stage_id), "Save defaults should track stage %s" % stage_id)
	assert(SaveProfile.new().unlocked_weapon_slots() == 1, "The stage prototype should expose one weapon slot")
	var profile := SaveProfile.new()
	var opening_rewards := profile.bank_run(10, 1.0, 1, 0, {}, "signal_hold")
	assert(bool(opening_rewards["first_clear"]) and int(profile.data["flux"]) == 70, "First clears should bank earned and catalog reward Flux")
	var repeat_rewards := profile.bank_run(0, 1.0, 1, 0, {}, "signal_hold")
	assert(not bool(repeat_rewards["first_clear"]) and int(profile.data["flux"]) == 70, "First-clear rewards should not repeat")
	profile.bank_run(0, 1.0, 1, 0, {}, "drift_cache")
	assert(profile.is_discovered("vector_parry"), "Clearing the optional cache should discover Vector Parry")
	profile.bank_run(0, 1.0, 1, 0, {}, "overseer_lock")
	for id: String in ["orbit", "arc", "nova", "gravity_tether"]:
		assert(profile.is_discovered(id), "The Chapter 3 comparison arsenal should unlock after the Overseer: %s" % id)
