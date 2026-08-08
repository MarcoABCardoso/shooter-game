extends SceneTree


func _initialize() -> void:
	var profile := SaveProfile.new()
	profile._apply_mastery_rewards({"pulse": 560.0, "orbit": 560.0})

	assert(profile.mastery_level("pulse") == 2, "Fixture should grant two native Pulse ranks")
	assert(profile.allocated_mastery("pulse") == 2, "Native mastery should be allocated to its source by default")
	assert(profile.unallocated_mastery() == 0, "Default allocations should consume the earned pool")
	assert(profile.can_adjust_mastery_allocation("orbit", -1), "Mastery should be removable from a weapon")
	profile.data["mastery_allocations"]["orbit"] = 1
	assert(profile.unallocated_mastery() == 1, "Removed mastery should return to the shared pool")
	assert(profile.can_adjust_mastery_allocation("pulse", 1), "Shared mastery should be assignable to another weapon")
	profile.data["mastery_allocations"]["pulse"] = 3
	assert(profile.allocated_mastery("pulse") == 3, "Pulse should receive mastery earned by Orbit")
	assert(profile.can_adjust_mastery_allocation("orbit", -1), "The remaining Orbit rank should be removable")
	profile.data["mastery_allocations"]["orbit"] = 0
	assert(profile.can_adjust_mastery_allocation("pulse", 1), "Pulse should reach twice its native mastery")
	profile.data["mastery_allocations"]["pulse"] = 4
	assert(profile.allocated_mastery("pulse") == profile.mastery_allocation_cap("pulse"), "Effective mastery should cap at 2x native mastery")
	assert(not profile.can_adjust_mastery_allocation("pulse", 1), "The 2x cap should reject further allocation")
	assert(is_equal_approx(profile.mastery_bonus("pulse"), 0.1), "Damage bonus should use effective allocated mastery")
	print("CALLIBRATIONS_OK shared mastery allocation, source defaults, bonus, and 2x cap validated")
	quit(0)
