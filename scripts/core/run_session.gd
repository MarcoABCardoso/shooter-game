class_name RunSession
extends RefCounted

signal level_gained(count: int)

var elapsed := 0.0
var level := 1
var xp := 0
var xp_needed := 25
var flux := 0
var kills := 0
var combo := 1.0
var combo_timer := 0.0
var pending_levels := 0
var mastery := {"pulse": 0.0, "orbit": 0.0, "arc": 0.0, "nova": 0.0}


func reset() -> void:
	elapsed = 0.0
	level = 1
	xp = 0
	xp_needed = 25
	flux = 0
	kills = 0
	combo = 1.0
	combo_timer = 0.0
	pending_levels = 0
	mastery = {"pulse": 0.0, "orbit": 0.0, "arc": 0.0, "nova": 0.0}


func tick(delta: float) -> void:
	elapsed += delta
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0:
		combo = move_toward(combo, 1.0, delta * 1.8)


func add_xp(amount: int) -> void:
	xp += amount
	var gained := 0
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = int(round(25.0 + pow(level, 1.32) * 11.0))
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
