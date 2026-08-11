class_name SpawnDirector
extends Node

const EncounterCatalog := preload("res://scripts/content/encounter_catalog.gd")

signal spawn_requested(kind: String, elite: bool)
signal swarm_evacuation_requested
signal encounter_completed
signal boss_started
signal banner_requested(text: String, color: Color)
signal shake_requested(amount: float)

enum EncounterState { COMBAT, ENCOUNTER_OUTRO, BOSS_INTRO, BOSS_ACTIVE, COMPLETE }

var session: RunSession
var encounter_id := EncounterCatalog.ORDER[0]
var encounter_spec: Dictionary = EncounterCatalog.definition(EncounterCatalog.ORDER[0])
var rng := RandomNumberGenerator.new()
var spawn_timer := 0.0
var next_elite := INF
var encounter_state := EncounterState.COMBAT
var intro_timer := 0.0
var objective_driven := false


func _ready() -> void:
	rng.randomize()


func configure(run_session: RunSession, selected_encounter: String, mission: Dictionary = {}) -> void:
	session = run_session
	encounter_id = selected_encounter if EncounterCatalog.ORDER.has(selected_encounter) else EncounterCatalog.ORDER[0]
	encounter_spec = EncounterCatalog.definition(encounter_id).duplicate(true)
	if mission.has("duration"):
		encounter_spec["duration"] = float(mission["duration"])
	spawn_timer = 0.5
	var elite_interval := float(encounter_spec["elite_interval"])
	next_elite = elite_interval if elite_interval > 0.0 else INF
	encounter_state = EncounterState.COMBAT
	intro_timer = 0.0
	objective_driven = String(mission.get("lifecycle", "assault")) in ["signal_defense", "relay_breach"]


func tick(delta: float) -> void:
	if session == null:
		return
	if encounter_state in [EncounterState.ENCOUNTER_OUTRO, EncounterState.BOSS_INTRO]:
		intro_timer -= delta
		if intro_timer <= 0.0:
			if encounter_state == EncounterState.BOSS_INTRO:
				encounter_state = EncounterState.BOSS_ACTIVE
				boss_started.emit()
				spawn_requested.emit("boss", false)
				banner_requested.emit("OVERSEER ENGAGED", GamePalette.MAGENTA)
			else:
				encounter_state = EncounterState.COMPLETE
				encounter_completed.emit()
		return
	if encounter_state in [EncounterState.BOSS_ACTIVE, EncounterState.COMPLETE]:
		return
	if not objective_driven and session.encounter_elapsed() >= float(encounter_spec["duration"]):
		encounter_state = EncounterState.BOSS_INTRO if bool(encounter_spec["boss"]) else EncounterState.ENCOUNTER_OUTRO
		intro_timer = GameBalance.BOSS_INTRO_DURATION
		swarm_evacuation_requested.emit()
		banner_requested.emit("OVERSEER APPROACHING" if bool(encounter_spec["boss"]) else "HOSTILES RETREATING", GamePalette.MAGENTA if bool(encounter_spec["boss"]) else GamePalette.GREEN)
		shake_requested.emit(8.0)
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer += GameBalance.spawn_interval(encounter_id, session.encounter_elapsed())
		for i in GameBalance.spawn_count(encounter_id, session.encounter_elapsed()):
			spawn_requested.emit(EncounterCatalog.choose_standard(encounter_id, session.encounter_elapsed(), rng.randf()), false)
	if session.encounter_elapsed() >= next_elite:
		next_elite += float(encounter_spec["elite_interval"])
		spawn_requested.emit(EncounterCatalog.choose_elite(encounter_id, session.encounter_elapsed()), true)
		banner_requested.emit("ELITE SIGNATURE", GamePalette.ORANGE)
