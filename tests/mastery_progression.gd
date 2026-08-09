extends SceneTree


func _initialize() -> void:
	var profile := SaveProfile.new()
	profile._apply_mastery_rewards({"pulse": 560.0, "orbit": 560.0, "dash": 560.0})
	assert(profile.mastery_level("pulse") == 2, "Fixture should grant two native Pulse ranks")
	assert(is_equal_approx(profile.mastery_bonus("pulse"), 0.05), "Mastery should improve only the item that earned it")
	assert(profile.mastery_level("arc") == 0, "Pulse mastery must not be routable into Arc")
	assert(profile.mastery_level("dash") == 2, "Active skills should own mastery progress")
	assert(is_equal_approx(profile.mastery_bonus("dash"), 0.05), "Active-skill mastery should use the shared rank curve")
	print("MASTERY_OK native weapon and active-skill mastery validated; allocation routing removed")
	quit(0)
