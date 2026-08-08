class_name RunSession
extends RefCounted

signal level_gained(count: int)

var elapsed := 0.0
var level := 1
var resonance := 0
var resonance_needed := 25
var flux := 0
var kills := 0
var combo := 1.0
var combo_timer := 0.0
var pending_levels := 0
var mastery := {"pulse": 0.0, "orbit": 0.0, "arc": 0.0, "nova": 0.0}
var behavior := BehaviorProfile.new()
var evolutions: Dictionary = {}
var last_evolution := ""


func reset() -> void:
	elapsed = 0.0
	level = 1
	resonance = 0
	resonance_needed = 25
	flux = 0
	kills = 0
	combo = 1.0
	combo_timer = 0.0
	pending_levels = 0
	mastery = {"pulse": 0.0, "orbit": 0.0, "arc": 0.0, "nova": 0.0}
	behavior.reset()
	evolutions.clear()
	last_evolution = ""


func tick(delta: float) -> void:
	elapsed += delta
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0:
		combo = move_toward(combo, 1.0, delta * 1.8)


func add_resonance(amount: int) -> void:
	resonance += amount
	var gained := 0
	while resonance >= resonance_needed:
		resonance -= resonance_needed
		level += 1
		resonance_needed = int(round(25.0 + pow(level, 1.32) * 11.0))
		pending_levels += 1
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


func register_evolution(id: String) -> int:
	var rank := int(evolutions.get(id, 0)) + 1
	evolutions[id] = rank
	last_evolution = id
	return rank
