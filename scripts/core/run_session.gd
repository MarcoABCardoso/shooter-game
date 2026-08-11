class_name RunSession
extends RefCounted

signal level_gained(count: int)

var elapsed := 0.0
var mission_elapsed := 0.0
var level := 1
var resonance := 0
var resonance_needed := 25
var flux := 0
var kills := 0
var combo := 1.0
var combo_timer := 0.0
var operation_id := ""
var operation_evolutions: Array[String] = []
var pending_evolution_tiers: Array[int] = []
var automatic_growth_levels := 0
var mastery := {"pulse": 0.0, "orbit": 0.0, "arc": 0.0, "nova": 0.0, "dash": 0.0, "vector_parry": 0.0}


func reset() -> void:
	elapsed = 0.0
	mission_elapsed = 0.0
	level = 1
	resonance = 0
	resonance_needed = 25
	flux = 0
	kills = 0
	combo = 1.0
	combo_timer = 0.0
	operation_id = ""
	operation_evolutions.clear()
	pending_evolution_tiers.clear()
	automatic_growth_levels = 0
	mastery = {"pulse": 0.0, "orbit": 0.0, "arc": 0.0, "nova": 0.0, "dash": 0.0, "vector_parry": 0.0}


func tick(delta: float) -> void:
	elapsed += delta
	mission_elapsed += delta
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0:
		combo = move_toward(combo, 1.0, delta * 1.8)


func encounter_elapsed() -> float:
	return mission_elapsed if not operation_id.is_empty() else elapsed


func begin_operation(id: String) -> void:
	reset()
	operation_id = id
	mission_elapsed = 0.0


func queue_evolution_tier(tier: int) -> void:
	if tier > 0:
		pending_evolution_tiers.append(tier)


func pending_evolution_tier() -> int:
	return pending_evolution_tiers[0] if not pending_evolution_tiers.is_empty() else 0


func register_operation_evolution(id: String) -> bool:
	if operation_evolutions.has(id):
		return false
	operation_evolutions.append(id)
	if not pending_evolution_tiers.is_empty():
		pending_evolution_tiers.pop_front()
	return true


func has_operation_evolution(id: String) -> bool:
	return operation_evolutions.has(id)


func add_resonance(amount: int) -> void:
	resonance += amount
	var gained := 0
	while resonance >= resonance_needed:
		resonance -= resonance_needed
		level += 1
		resonance_needed = int(round(25.0 + pow(level, 1.32) * 11.0))
		gained += 1
	if gained > 0:
		level_gained.emit(gained)


func register_kill() -> void:
	kills += 1
	combo = minf(5.0, combo + 0.10)
	combo_timer = 2.5


func add_flux(amount: int) -> void:
	flux += amount


func record_damage(weapon: String, amount: float) -> void:
	if amount > 0.0 and mastery.has(weapon):
		mastery[weapon] = float(mastery[weapon]) + amount * 0.12


func record_mastery(item: String, amount: float) -> void:
	if amount > 0.0 and mastery.has(item):
		mastery[item] = float(mastery[item]) + amount
