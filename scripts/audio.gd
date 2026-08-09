class_name NeonAudio
extends Node

const MUSIC_FADE_SECONDS := 0.65
const MUSIC_VOLUME_DB := -8.0
const SILENT_VOLUME_DB := -60.0
const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_TRACKS := {
	&"title": preload("res://assets/audio/music/vector-eclipse/title-screen.ogg"),
	&"hangar": preload("res://assets/audio/music/vector-eclipse/hangar-drift.ogg"),
	&"combat": preload("res://assets/audio/music/vector-eclipse/prism-rain.ogg"),
}
const STINGER_TRACKS := {
	&"clear": preload("res://assets/audio/music/vector-eclipse/clear-signal.ogg"),
	&"defeat": preload("res://assets/audio/music/vector-eclipse/signal-lost.ogg"),
}

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var music_players: Array[AudioStreamPlayer] = []
var stinger_player: AudioStreamPlayer
var active_music_index := -1
var current_music := &""
var music_tween: Tween
var master_volume := 1.0


func _ready() -> void:
	_load_master_volume()
	_apply_master_volume()
	player = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.35
	player.stream = stream
	player.volume_db = -15.0
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	for index in 2:
		var music_player := AudioStreamPlayer.new()
		music_player.name = "MusicPlayer%d" % (index + 1)
		music_player.bus = &"Music"
		music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		music_player.volume_db = SILENT_VOLUME_DB
		add_child(music_player)
		music_players.append(music_player)
	stinger_player = AudioStreamPlayer.new()
	stinger_player.name = "StingerPlayer"
	stinger_player.bus = &"Music"
	stinger_player.volume_db = MUSIC_VOLUME_DB
	add_child(stinger_player)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	_save_master_volume()


func _apply_master_volume() -> void:
	var master_bus := AudioServer.get_bus_index(&"Master")
	if master_bus < 0:
		return
	AudioServer.set_bus_mute(master_bus, is_zero_approx(master_volume))
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.0001)))


func _load_master_volume() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		master_volume = clampf(float(settings.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)


func _save_master_volume() -> void:
	var settings := ConfigFile.new()
	settings.load(SETTINGS_PATH)
	settings.set_value("audio", "master_volume", master_volume)
	var error := settings.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Unable to save audio settings: %s" % error_string(error))


func play_music(track: StringName, fade_seconds: float = MUSIC_FADE_SECONDS) -> void:
	stinger_player.stop()
	if track == current_music and active_music_index >= 0 and music_players[active_music_index].playing:
		return
	var stream := MUSIC_TRACKS.get(track) as AudioStreamOggVorbis
	if stream == null:
		push_warning("Unknown music track: %s" % track)
		return
	stream.loop = true
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()
	_stop_inactive_music_players()
	var old_player: AudioStreamPlayer = null
	if active_music_index >= 0:
		old_player = music_players[active_music_index]
	var next_index := 0 if active_music_index != 0 else 1
	var next_player := music_players[next_index]
	next_player.stop()
	next_player.stream = stream
	next_player.volume_db = SILENT_VOLUME_DB
	next_player.play()
	active_music_index = next_index
	current_music = track
	if fade_seconds <= 0.0:
		next_player.volume_db = MUSIC_VOLUME_DB
		if old_player != null:
			old_player.stop()
		return
	music_tween = create_tween()
	music_tween.set_parallel(true)
	music_tween.tween_property(next_player, "volume_db", MUSIC_VOLUME_DB, fade_seconds)
	if old_player != null:
		music_tween.tween_property(old_player, "volume_db", SILENT_VOLUME_DB, fade_seconds)
	music_tween.finished.connect(_stop_inactive_music_players)


func play_stinger(track: StringName) -> void:
	var stream := STINGER_TRACKS.get(track) as AudioStreamOggVorbis
	if stream == null:
		push_warning("Unknown music stinger: %s" % track)
		return
	stream.loop = false
	stinger_player.stop()
	stinger_player.stream = stream
	stinger_player.play()


func stop_music(fade_seconds: float = MUSIC_FADE_SECONDS) -> void:
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()
	current_music = &""
	active_music_index = -1
	var has_playing_music := false
	for music_player in music_players:
		if music_player.playing:
			has_playing_music = true
			break
	if not has_playing_music:
		return
	if fade_seconds <= 0.0:
		_finish_stop_music()
		return
	music_tween = create_tween()
	music_tween.set_parallel(true)
	for music_player in music_players:
		if music_player.playing:
			music_tween.tween_property(music_player, "volume_db", SILENT_VOLUME_DB, fade_seconds)
	music_tween.finished.connect(_finish_stop_music)


func _stop_inactive_music_players() -> void:
	for index in music_players.size():
		if index != active_music_index:
			music_players[index].stop()


func _finish_stop_music() -> void:
	if not current_music.is_empty():
		return
	for music_player in music_players:
		music_player.stop()


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
