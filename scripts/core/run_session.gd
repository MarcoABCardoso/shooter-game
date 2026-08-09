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
var mastery := {"pulse": 0.0, "orbit": 0.0, "arc": 0.0, "nova": 0.0, "dash": 0.0, "vector_parry": 0.0}
var weapon_upgrades := {
	"pulse": {"damage": 0, "fire_rate": 0, "projectile_speed": 0},
	"orbit": {"damage": 0, "blade_count": 0, "orbit_speed": 0},
	"arc": {"damage": 0, "fire_rate": 0, "chain_count": 0},
	"nova": {"damage": 0, "fire_rate": 0, "blast_radius": 0},
}


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
	mastery = {"pulse": 0.0, "orbit": 0.0, "arc": 0.0, "nova": 0.0, "dash": 0.0, "vector_parry": 0.0}
	weapon_upgrades = {
		"pulse": {"damage": 0, "fire_rate": 0, "projectile_speed": 0},
		"orbit": {"damage": 0, "blade_count": 0, "orbit_speed": 0},
		"arc": {"damage": 0, "fire_rate": 0, "chain_count": 0},
		"nova": {"damage": 0, "fire_rate": 0, "blast_radius": 0},
	}


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


func record_mastery(item: String, amount: float) -> void:
	if amount > 0.0 and mastery.has(item):
		mastery[item] = float(mastery[item]) + amount


func weapon_upgrade_rank(weapon: String, dimension: String) -> int:
	return int(weapon_upgrades.get(weapon, {}).get(dimension, 0))


func can_upgrade_weapon(weapon: String, dimension: String) -> bool:
	return weapon_upgrades.has(weapon) and weapon_upgrades[weapon].has(dimension) and weapon_upgrade_rank(weapon, dimension) < RunUpgradeCatalog.MAX_RANK


func register_weapon_upgrade(weapon: String, dimension: String) -> bool:
	if not can_upgrade_weapon(weapon, dimension):
		return false
	weapon_upgrades[weapon][dimension] = weapon_upgrade_rank(weapon, dimension) + 1
	return true
