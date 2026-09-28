extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var beat_callback: Callable = Callable()
var _beat_accum := 0.0
var _beat_interval := 0.0
var _beating := false
var _current_music_path := ""
var music_volume := 0.55
var sfx_volume := 0.7


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	sfx_player.bus = "Master"
	add_child(music_player)
	add_child(sfx_player)


func _process(delta: float) -> void:
	if not _beating:
		return
	_beat_accum += delta
	while _beat_accum >= _beat_interval:
		_beat_accum -= _beat_interval
		if beat_callback.is_valid():
			beat_callback.call()


func play_menu_music() -> void:
	_beating = false
	beat_callback = Callable()
	_play_stream("res://assets/music/menu.mp3", true)


func start_level_music(level: Dictionary, on_beat: Callable) -> void:
	beat_callback = on_beat
	_beat_interval = 60.0 / float(level.bpm)
	_beat_accum = 0.0
	_beating = true
	var path := LevelData.resolve_music(level)
	var start_at := float(level.get("music_start", -1.0))
	_play_stream(path, true, start_at)


func set_music_fade(seconds_left: float, fade_span: float) -> void:
	var t := clampf(seconds_left / fade_span, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume * t)


func stop_music() -> void:
	_beating = false
	beat_callback = Callable()
	_current_music_path = ""
	music_player.stop()


func play_hit() -> void:
	_beep(880.0, 0.06)


func play_miss() -> void:
	_beep(120.0, 0.12)


func play_defuse() -> void:
	_beep(440.0, 0.08)


func _play_stream(path: String, loop: bool, start_at: float = 0.0) -> void:
	if not ResourceLoader.exists(path):
		return
	if _current_music_path == path and music_player.playing:
		music_player.volume_db = linear_to_db(music_volume)
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume)
	_current_music_path = path
	var from_pos := _resolve_start_position(path, stream, start_at)
	music_player.play(from_pos)


func _resolve_start_position(path: String, stream: AudioStream, start_at: float) -> float:
	if start_at >= 0.0:
		return start_at
	# Full YouTube-rip World 2 tracks often have ~15s of lead-in silence.
	# Trimmed/web tracks are short and should start immediately.
	if "world2" in path and stream.get_length() > 90.0:
		return 15.0
	return 0.0


func _beep(hz: float, duration: float) -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	sfx_player.stream = gen
	sfx_player.volume_db = linear_to_db(sfx_volume)
	sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := int(duration * gen.mix_rate)
	for i in frames:
		var t := float(i) / gen.mix_rate
		var sample := sin(TAU * hz * t) * 0.25 * (1.0 - float(i) / float(frames))
		playback.push_frame(Vector2(sample, sample))
