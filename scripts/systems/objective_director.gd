class_name ObjectiveDirector
extends Node

signal mission_completed
signal objective_updated(world_position: Vector2, radius: float, progress: float, occupied: bool)
signal relay_network_updated(positions: Array[Vector2], remaining: Array[int])
signal objective_target_requested(kind: String, world_position: Vector2, objective_index: int)
signal objective_hidden
signal objective_completed(animation_duration: float)
signal mission_outro_started
signal combat_arena_changed(arena: Rect2)
signal travel_started(travel_bounds: Rect2, destination_arena: Rect2)
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
var objectives: Array[Dictionary] = []
var objective_index := -1
var objective_name := ""
var current_arena := Rect2()
var destination_arena := Rect2()
var pending_objective_index := -1
var traveling := false
var completing := false
var completion_timer := 0.0
var completion_next_index := -1
var relay_positions: Array[Vector2] = []
var remaining_relays: Array[int] = []

const OBJECTIVE_TRANSITION_DELAY := 0.8


func configure(mission: Dictionary, run_player: NeonPlayer) -> void:
	clear()
	player = run_player
	for value: Variant in mission.get("objectives", []):
		if value is Dictionary:
			objectives.append((value as Dictionary).duplicate(true))
	if objectives.is_empty() and String(mission.get("lifecycle", "assault")) in ["signal_defense", "relay_breach"]:
		objectives.append(mission.duplicate(true))
	if objectives.is_empty():
		lifecycle = String(mission.get("lifecycle", "assault"))
		return
	_start_objective(0)


func objective_label() -> String:
	var displayed_index := pending_objective_index if traveling else objective_index
	if objective_name.is_empty() or displayed_index < 0:
		return ""
	return "%d/%d  %s" % [displayed_index + 1, objectives.size(), objective_name]


func _start_objective(index: int) -> void:
	_reset_current_objective()
	objective_index = index
	pending_objective_index = -1
	traveling = false
	var objective := objectives[objective_index]
	objective_name = String(objective.get("name", "OBJECTIVE"))
	lifecycle = String(objective.get("lifecycle", "assault"))
	current_arena = objective.get("arena_rect", GameBalance.ARENA)
	combat_arena_changed.emit(current_arena)
	if lifecycle == "relay_breach":
		_configure_relay_breach(objective)
		banner_requested.emit(objective_label(), GamePalette.YELLOW)
		return
	if lifecycle != "signal_defense":
		return
	active = true
	world_position = objective.get("objective_position", GameBalance.ARENA.get_center())
	radius = float(objective.get("objective_radius", 120.0))
	hold_duration = maxf(1.0, float(objective.get("hold_duration", 18.0)))
	decay_rate = maxf(0.0, float(objective.get("decay_rate", 0.35)))
	objective_updated.emit(world_position, radius, 0.0, false)
	banner_requested.emit(objective_label(), GamePalette.YELLOW)


func tick(delta: float) -> void:
	if completing:
		completion_timer = maxf(0.0, completion_timer - delta)
		if completion_timer <= 0.0:
			_finish_objective_completion()
		return
	if traveling and is_instance_valid(player):
		if player.global_position.x >= destination_arena.position.x + 96.0:
			_start_objective(pending_objective_index)
		return
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
		_begin_objective_completion()


func register_objective_target_defeated(objective_index: int) -> void:
	if not active or lifecycle != "relay_breach" or not remaining_relays.has(objective_index):
		return
	remaining_relays.erase(objective_index)
	relay_network_updated.emit(relay_positions, remaining_relays)
	if remaining_relays.is_empty():
		active = false
		_begin_objective_completion()
	else:
		banner_requested.emit("RELAY DESTROYED - %d REMAIN" % remaining_relays.size(), GamePalette.ORANGE)


func clear() -> void:
	objectives.clear()
	objective_index = -1
	objective_name = ""
	current_arena = Rect2()
	destination_arena = Rect2()
	pending_objective_index = -1
	traveling = false
	completing = false
	completion_timer = 0.0
	completion_next_index = -1
	_reset_current_objective()
	objective_hidden.emit()


func _reset_current_objective() -> void:
	active = false
	lifecycle = ""
	progress = 0.0
	occupied = false
	announced_lock = false
	relay_positions.clear()
	remaining_relays.clear()


func _begin_objective_completion() -> void:
	completing = true
	completion_next_index = objective_index + 1
	var final_objective := completion_next_index >= objectives.size()
	completion_timer = GameBalance.MISSION_OUTRO_DURATION if final_objective else OBJECTIVE_TRANSITION_DELAY
	objective_completed.emit(completion_timer)
	if final_objective:
		mission_outro_started.emit()


func _finish_objective_completion() -> void:
	completing = false
	objective_hidden.emit()
	if completion_next_index >= objectives.size():
		objective_name = ""
		mission_completed.emit()
		return
	_begin_travel(completion_next_index)


func _begin_travel(next_index: int) -> void:
	_reset_current_objective()
	traveling = true
	pending_objective_index = next_index
	var next_objective := objectives[next_index]
	destination_arena = next_objective.get("arena_rect", current_arena)
	objective_name = String(next_objective.get("approach_name", "ADVANCE"))
	lifecycle = "travel"
	var travel_bounds := current_arena.merge(destination_arena)
	travel_started.emit(travel_bounds, destination_arena)
	banner_requested.emit(objective_label(), GamePalette.GREEN)


func _configure_relay_breach(mission: Dictionary) -> void:
	for value: Variant in mission.get("relay_positions", []):
		relay_positions.append(value as Vector2)
	for index in relay_positions.size():
		remaining_relays.append(index)
	active = not relay_positions.is_empty()
	relay_network_updated.emit(relay_positions, remaining_relays)
	for index in relay_positions.size():
		objective_target_requested.emit("relay", relay_positions[index], index)
	for value: Variant in mission.get("reinforcements", []):
		if value is Dictionary:
			var reinforcement := value as Dictionary
			objective_target_requested.emit(String(reinforcement.get("kind", "drone")), reinforcement.get("position", current_arena.get_center()), -1)
