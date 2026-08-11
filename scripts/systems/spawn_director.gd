class_name SpawnDirector
extends Node

const StageCatalog := preload("res://scripts/content/stage_catalog.gd")

signal spawn_requested(kind: String, elite: bool)
signal swarm_evacuation_requested
signal stage_completed
signal boss_started
signal banner_requested(text: String, color: Color)
signal shake_requested(amount: float)

enum EncounterState { COMBAT, STAGE_OUTRO, BOSS_INTRO, BOSS_ACTIVE, COMPLETE }

var session: RunSession
var stage_id := "stage_1"
var stage_spec: Dictionary = StageCatalog.definition("stage_1")
var rng := RandomNumberGenerator.new()
var spawn_timer := 0.0
var next_elite := INF
var encounter_state := EncounterState.COMBAT
var intro_timer := 0.0


func _ready() -> void:
	rng.randomize()


func configure(run_session: RunSession, selected_stage: String) -> void:
	session = run_session
	stage_id = selected_stage if StageCatalog.ORDER.has(selected_stage) else "stage_1"
	stage_spec = StageCatalog.definition(stage_id)
	spawn_timer = 0.5
	var elite_interval := float(stage_spec["elite_interval"])
	next_elite = elite_interval if elite_interval > 0.0 else INF
	encounter_state = EncounterState.COMBAT
	intro_timer = 0.0


func tick(delta: float) -> void:
	if session == null:
		return
	if encounter_state in [EncounterState.STAGE_OUTRO, EncounterState.BOSS_INTRO]:
		intro_timer -= delta
		if intro_timer <= 0.0:
			if encounter_state == EncounterState.BOSS_INTRO:
				encounter_state = EncounterState.BOSS_ACTIVE
				boss_started.emit()
				spawn_requested.emit("boss", false)
				banner_requested.emit("OVERSEER ENGAGED", GamePalette.MAGENTA)
			else:
				encounter_state = EncounterState.COMPLETE
				stage_completed.emit()
		return
	if encounter_state in [EncounterState.BOSS_ACTIVE, EncounterState.COMPLETE]:
		return
	if session.elapsed >= float(stage_spec["duration"]):
		encounter_state = EncounterState.BOSS_INTRO if bool(stage_spec["boss"]) else EncounterState.STAGE_OUTRO
		intro_timer = GameBalance.BOSS_INTRO_DURATION
		swarm_evacuation_requested.emit()
		banner_requested.emit("OVERSEER APPROACHING" if bool(stage_spec["boss"]) else "HOSTILES RETREATING", GamePalette.MAGENTA if bool(stage_spec["boss"]) else GamePalette.GREEN)
		shake_requested.emit(8.0)
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer += GameBalance.spawn_interval(stage_id, session.elapsed)
		for i in GameBalance.spawn_count(stage_id, session.elapsed):
			spawn_requested.emit(StageCatalog.choose_standard(stage_id, session.elapsed, rng.randf()), false)
	if session.elapsed >= next_elite:
		next_elite += float(stage_spec["elite_interval"])
		spawn_requested.emit(StageCatalog.choose_elite(stage_id, session.elapsed), true)
		banner_requested.emit("ELITE SIGNATURE", GamePalette.ORANGE)
