class_name ObjectiveDirector
extends Node

signal mission_completed
signal objective_updated(world_position: Vector2, radius: float, progress: float, occupied: bool)
signal relay_network_updated(positions: Array[Vector2], remaining: Array[int])
signal objective_target_requested(kind: String, world_position: Vector2, objective_index: int)
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
var lifecycle := ""
var relay_positions: Array[Vector2] = []
var remaining_relays: Array[int] = []


func configure(mission: Dictionary, run_player: NeonPlayer) -> void:
	clear()
	player = run_player
	lifecycle = String(mission.get("lifecycle", "assault"))
	if lifecycle == "relay_breach":
		_configure_relay_breach(mission)
		return
	if lifecycle != "signal_defense":
		return
	active = true
	world_position = mission.get("objective_position", GameBalance.ARENA.get_center())
	radius = float(mission.get("objective_radius", 120.0))
	hold_duration = maxf(1.0, float(mission.get("hold_duration", 18.0)))
	decay_rate = maxf(0.0, float(mission.get("decay_rate", 0.35)))
	objective_updated.emit(world_position, radius, 0.0, false)
	banner_requested.emit("ENTER THE SIGNAL FIELD", GamePalette.YELLOW)


func tick(delta: float) -> void:
	if not active or lifecycle != "signal_defense" or not is_instance_valid(player):
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


func register_objective_target_defeated(objective_index: int) -> void:
	if not active or lifecycle != "relay_breach" or not remaining_relays.has(objective_index):
		return
	remaining_relays.erase(objective_index)
	relay_network_updated.emit(relay_positions, remaining_relays)
	if remaining_relays.is_empty():
		active = false
		banner_requested.emit("RELAY CAGE COLLAPSED", GamePalette.GREEN)
		mission_completed.emit()
	else:
		banner_requested.emit("RELAY DESTROYED - %d REMAIN" % remaining_relays.size(), GamePalette.ORANGE)


func clear() -> void:
	active = false
	lifecycle = ""
	progress = 0.0
	occupied = false
	announced_lock = false
	relay_positions.clear()
	remaining_relays.clear()
	objective_hidden.emit()


func _configure_relay_breach(mission: Dictionary) -> void:
	for value: Variant in mission.get("relay_positions", []):
		relay_positions.append(value as Vector2)
	for index in relay_positions.size():
		remaining_relays.append(index)
	active = not relay_positions.is_empty()
	relay_network_updated.emit(relay_positions, remaining_relays)
	for index in relay_positions.size():
		objective_target_requested.emit("relay", relay_positions[index], index)
	if active:
		banner_requested.emit("BREAK ALL SIGNAL RELAYS", GamePalette.YELLOW)
