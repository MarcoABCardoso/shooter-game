class_name SpawnDirector
extends Node

signal spawn_requested(kind: String, elite: bool)
signal boss_arrival_requested
signal banner_requested(text: String, color: Color)
signal shake_requested(amount: float)

enum EncounterState { COMBAT, BOSS_INTRO, BOSS_ACTIVE }

var session: RunSession
var rng := RandomNumberGenerator.new()
var spawn_timer := 0.0
var next_elite := GameBalance.ELITE_INTERVAL
var encounter_state := EncounterState.COMBAT
var intro_timer := 0.0


func _ready() -> void:
	rng.randomize()


func configure(run_session: RunSession) -> void:
	session = run_session
	spawn_timer = 0.5
	next_elite = GameBalance.ELITE_INTERVAL
	encounter_state = EncounterState.COMBAT
	intro_timer = 0.0


func tick(delta: float) -> void:
	if session == null:
		return
	if encounter_state == EncounterState.BOSS_INTRO:
		intro_timer -= delta
		if intro_timer <= 0.0:
			encounter_state = EncounterState.BOSS_ACTIVE
			spawn_requested.emit("boss", false)
			banner_requested.emit("OVERSEER ARRAY // ENGAGED", GamePalette.MAGENTA)
		return
	if encounter_state == EncounterState.BOSS_ACTIVE:
		return
	if session.elapsed >= GameBalance.STAGE_1_DURATION:
		encounter_state = EncounterState.BOSS_INTRO
		intro_timer = GameBalance.BOSS_INTRO_DURATION
		boss_arrival_requested.emit()
		banner_requested.emit("WARNING // SIGNAL EVACUATION", GamePalette.MAGENTA)
		shake_requested.emit(8.0)
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer += GameBalance.spawn_interval(session.elapsed)
		for i in GameBalance.spawn_count(session.elapsed):
			spawn_requested.emit(EnemyCatalog.choose_standard(session.elapsed, rng.randf()), false)
	if session.elapsed >= next_elite:
		next_elite += GameBalance.ELITE_INTERVAL
		spawn_requested.emit("tank" if session.elapsed > 100.0 else "gunner", true)
		banner_requested.emit("ELITE SIGNATURE", GamePalette.ORANGE)
