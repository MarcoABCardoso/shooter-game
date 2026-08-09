extends SceneTree

const MobileControlsScript := preload("res://scripts/ui/mobile_controls.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var controls := MobileControlsScript.new()
	controls.size = Vector2(1280, 720)
	root.add_child(controls)
	await process_frame
	controls.set_controls_active(true)

	var latest := {"movement": Vector2.ZERO, "aim": Vector2.ZERO}
	controls.input_changed.connect(func(movement: Vector2, aim: Vector2) -> void:
		latest["movement"] = movement
		latest["aim"] = aim
	)
	var counters := {"ability": 0}
	controls.ability_requested.connect(func() -> void: counters["ability"] += 1)

	_touch(controls, 0, Vector2(240, 550), true)
	assert((latest["movement"] as Vector2).x > 0.7, "Left stick should produce rightward movement")
	_touch(controls, 1, Vector2(1140, 450), true)
	assert((latest["aim"] as Vector2).y < -0.7, "Right stick should produce upward aim")
	_touch(controls, 2, Vector2(1168, 355), true)
	assert(int(counters["ability"]) == 1, "Ability button should request the active skill once")
	_touch(controls, 0, Vector2(240, 550), false)
	assert(latest["movement"] == Vector2.ZERO, "Releasing the left stick should stop movement")
	controls.set_controls_active(false)
	assert(latest["aim"] == Vector2.ZERO, "Hiding controls should release active touch input")
	print("MOBILE_CONTROLS_OK touch sticks, ability, and input reset validated")
	quit(0)


func _touch(controls: Control, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	controls._input(event)
