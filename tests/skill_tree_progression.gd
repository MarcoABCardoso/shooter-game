extends SceneTree


func _initialize() -> void:
	var profile := SaveProfile.new()
	profile.data["flux"] = 2000
	assert(not profile.skill_available("distant_power"), "Branches should require ranks in their parent node")
	assert(profile.buy_skill("core_damage"), "The root damage node should be immediately purchasable")
	assert(profile.buy_skill("core_damage"), "Nodes should support multiple ranks")
	assert(profile.skill_available("distant_power"), "Two root ranks should open the distant branch")
	assert(profile.buy_skill("distant_power"), "Unlocked branch ranks should cost Flux")
	assert(profile.buy_skill("distant_power"), "Branch nodes should also support multiple ranks")
	assert(is_equal_approx(profile.skill_effect("general_damage"), 0.08), "Root ranks should stack their general damage effect")
	assert(is_equal_approx(profile.skill_effect("distant_damage"), 0.16), "Branch ranks should stack their combat effect")
	assert(not profile.skill_available("impact_vector"), "Impact Vector should remain mastery- and prerequisite-gated")
	profile._apply_mastery_rewards({"pulse": 560.0})
	assert(profile.skill_available("impact_vector"), "Native Pulse mastery should satisfy the remaining gate")
	assert(profile.buy_skill("anchored_power") and profile.buy_skill("anchored_power"), "The stationary branch should accept two ranks")
	assert(not profile.skill_available("reinforced_core"), "Stage-gated skills should remain locked before their clear")
	profile.clear_stage_one()
	assert(profile.skill_available("reinforced_core"), "Stage clear should satisfy a graph gate")
	var flux_after_purchases := int(profile.data["flux"])
	var refunded := profile.respec_skills()
	assert(refunded == 2000 - flux_after_purchases, "Free respec should refund every Flux spent on skills")
	assert(profile.skill_rank("core_damage") == 0 and profile.skill_rank("distant_power") == 0, "Respec should clear the entire graph")
	assert(int(profile.data["flux"]) == 2000, "Respec should be lossless")
	print("SKILL_TREE_OK ranked nodes, prerequisites, effects, Flux spending, and free respec validated")
	quit(0)
