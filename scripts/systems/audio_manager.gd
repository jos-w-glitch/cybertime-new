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
var _sfx_stop_token := 0


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
	_play_stream("res://assets/music/menu.mp3", true, 0.0, music_volume)


func prepare_level_music(level: Dictionary) -> void:
	# Decode/start the track during the start-orb screen so phones aren't silent
	# (or stuck on beep SFX) for the first seconds of a run.
	_beating = false
	beat_callback = Callable()
	var path := LevelData.resolve_music(level)
	_play_stream(path, true, 0.0, 0.0001)


func start_level_music(level: Dictionary, on_beat: Callable) -> void:
	beat_callback = on_beat
	_beat_interval = 60.0 / float(level.bpm)
	_beat_accum = 0.0
	_beating = true
	var path := LevelData.resolve_music(level)
	if _current_music_path == path and music_player.stream != null:
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play(0.0)
		return
	_play_stream(path, true, 0.0, music_volume)


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


func _play_stream(path: String, loop: bool, from_pos: float, linear_vol: float) -> void:
	if path == "" or not ResourceLoader.exists(path):
		push_warning("CyberTime: missing music %s" % path)
		return
	if _current_music_path == path and music_player.playing and music_player.stream != null:
		music_player.volume_db = linear_to_db(linear_vol)
		if from_pos >= 0.0:
			music_player.seek(from_pos)
		return
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("CyberTime: failed to load music %s" % path)
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = linear_to_db(linear_vol)
	_current_music_path = path
	music_player.play(maxf(0.0, from_pos))


func _beep(hz: float, duration: float) -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.1
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
	_sfx_stop_token += 1
	var token := _sfx_stop_token
	get_tree().create_timer(duration + 0.03).timeout.connect(func() -> void:
		if token != _sfx_stop_token:
			return
		if sfx_player.stream is AudioStreamGenerator:
			sfx_player.stop()
	)
