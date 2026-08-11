extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game._show_library()
	for _frame in 4:
		await process_frame
	quit(0)
