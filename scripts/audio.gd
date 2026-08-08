class_name NeonAudio
extends Node

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback


func _ready() -> void:
	player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.35
	player.stream = stream
	player.volume_db = -15.0
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback


func tone(frequency: float, duration: float, volume: float = 0.18, slide: float = 0.0) -> void:
	if playback == null:
		return
	var frames := mini(int(22050.0 * duration), playback.get_frames_available())
	for i in frames:
		var t := float(i) / 22050.0
		var envelope := pow(1.0 - float(i) / maxf(1.0, frames), 2.0)
		var phase := TAU * (frequency * t + slide * t * t * 0.5)
		var sample := sin(phase) * volume * envelope
		playback.push_frame(Vector2(sample, sample))
