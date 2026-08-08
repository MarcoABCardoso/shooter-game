extends SceneTree


func _initialize() -> void:
	call_deferred("_stage_capture")


func _stage_capture() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	await process_frame
	game.elapsed = 92.0
	game.weapons["orbit"]["level"] = 2
	game.weapons["orbit"]["count"] = 4
	game.weapons["arc"]["level"] = 1
	game.weapons["nova"]["level"] = 1
	for kind in ["drone", "drone", "striker", "gunner", "tank"]:
		game.spawn_enemy(kind, kind == "gunner")
	for i in 90:
		await process_frame
	quit(0)
