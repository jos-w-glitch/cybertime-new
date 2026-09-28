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
var _hit_sfx: AudioStreamWAV
var _miss_sfx: AudioStreamWAV
var _defuse_sfx: AudioStreamWAV


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	sfx_player.bus = "Master"
	add_child(music_player)
	add_child(sfx_player)
	_hit_sfx = _make_tone(880.0, 0.06)
	_miss_sfx = _make_tone(120.0, 0.12)
	_defuse_sfx = _make_tone(440.0, 0.08)


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
	# Same path for every world — load MP3 and play from the start.
	beat_callback = on_beat
	_beat_interval = 60.0 / maxf(1.0, float(level.bpm))
	_beat_accum = 0.0
	_beating = true
	_play_stream(LevelData.resolve_music(level), true)


func set_music_fade(seconds_left: float, fade_span: float) -> void:
	var t := clampf(seconds_left / fade_span, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume * t)


func stop_music() -> void:
	_beating = false
	beat_callback = Callable()
	_current_music_path = ""
	music_player.stop()


func play_hit() -> void:
	_play_sfx(_hit_sfx)


func play_miss() -> void:
	_play_sfx(_miss_sfx)


func play_defuse() -> void:
	_play_sfx(_defuse_sfx)


func _play_stream(path: String, loop: bool) -> void:
	if path == "" or not ResourceLoader.exists(path):
		# Fall back exactly like World 1 would via LevelData, then menu.
		if path != "res://assets/music/menu.mp3" and ResourceLoader.exists("res://assets/music/menu.mp3"):
			_play_stream("res://assets/music/menu.mp3", true)
		return
	if _current_music_path == path and music_player.playing and music_player.stream != null:
		music_player.volume_db = linear_to_db(music_volume)
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = loop
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume)
	_current_music_path = path
	music_player.play(0.0)


func _play_sfx(stream: AudioStreamWAV) -> void:
	if stream == null:
		return
	sfx_player.stop()
	sfx_player.stream = stream
	sfx_player.volume_db = linear_to_db(sfx_volume)
	sfx_player.play(0.0)


func _make_tone(hz: float, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := maxi(1, int(duration * rate))
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var env := 1.0 - float(i) / float(frames)
		var sample := int(sin(TAU * hz * float(i) / float(rate)) * 0.22 * env * 32767.0)
		data.encode_s16(i * 2, clampi(sample, -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream
