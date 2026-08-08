class_name SpawnDirector
extends Node

signal spawn_requested(kind: String, elite: bool)
signal banner_requested(text: String, color: Color)
signal shake_requested(amount: float)

var session: RunSession
var rng := RandomNumberGenerator.new()
var spawn_timer := 0.0
var next_elite := GameBalance.ELITE_INTERVAL
var next_boss := GameBalance.BOSS_INTERVAL


func _ready() -> void:
	rng.randomize()


func configure(run_session: RunSession) -> void:
	session = run_session
	spawn_timer = 0.5
	next_elite = GameBalance.ELITE_INTERVAL
	next_boss = GameBalance.BOSS_INTERVAL


func tick(delta: float) -> void:
	if session == null:
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
	if session.elapsed >= next_boss:
		next_boss += GameBalance.BOSS_INTERVAL
		spawn_requested.emit("boss", false)
		banner_requested.emit("WARNING // OVERSEER INBOUND", GamePalette.MAGENTA)
		shake_requested.emit(8.0)
