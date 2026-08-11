class_name ObjectiveDirector
extends Node

signal mission_completed
signal objective_updated(world_position: Vector2, radius: float, progress: float, occupied: bool)
signal objective_hidden
signal banner_requested(text: String, color: Color)

var player: NeonPlayer
var active := false
var world_position := Vector2.ZERO
var radius := 0.0
var progress := 0.0
var hold_duration := 1.0
var decay_rate := 0.0
var occupied := false
var announced_lock := false


func configure(mission: Dictionary, run_player: NeonPlayer) -> void:
	clear()
	player = run_player
	if String(mission.get("lifecycle", "assault")) != "signal_defense":
		return
	active = true
	world_position = mission.get("objective_position", GameBalance.ARENA.get_center())
	radius = float(mission.get("objective_radius", 120.0))
	hold_duration = maxf(1.0, float(mission.get("hold_duration", 18.0)))
	decay_rate = maxf(0.0, float(mission.get("decay_rate", 0.35)))
	objective_updated.emit(world_position, radius, 0.0, false)
	banner_requested.emit("ENTER THE SIGNAL FIELD", GamePalette.YELLOW)


func tick(delta: float) -> void:
	if not active or not is_instance_valid(player):
		return
	var was_occupied := occupied
	occupied = player.global_position.distance_squared_to(world_position) <= radius * radius
	if occupied:
		progress = minf(1.0, progress + delta / hold_duration)
	else:
		progress = maxf(0.0, progress - delta * decay_rate / hold_duration)
	if occupied != was_occupied:
		banner_requested.emit("SIGNAL LOCKED — HOLD POSITION" if occupied else "SIGNAL DECAYING", GamePalette.GREEN if occupied else GamePalette.ORANGE)
	objective_updated.emit(world_position, radius, progress, occupied)
	if progress >= 1.0 and not announced_lock:
		announced_lock = true
		active = false
		banner_requested.emit("SIGNAL STABILIZED", GamePalette.GREEN)
		mission_completed.emit()


func clear() -> void:
	active = false
	progress = 0.0
	occupied = false
	announced_lock = false
	objective_hidden.emit()
