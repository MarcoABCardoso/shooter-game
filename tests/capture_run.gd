extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game.start_operation("signal_breach")
	await process_frame
	game.session.elapsed = 92.0
	game.weapon_system.weapons["orbit"]["level"] = 2
	game.weapon_system.weapons["orbit"]["count"] = 4
	game.weapon_system.weapons["arc"]["level"] = 1
	game.weapon_system.weapons["nova"]["level"] = 1
	for kind in ["drone", "drone", "striker", "gunner", "tank"]:
		game.spawn_enemy(kind, kind == "gunner")
	for i in 90:
		await process_frame
	quit(0)
