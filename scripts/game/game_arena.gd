extends Node2D

signal run_finished(won: bool)

const Draw := preload("res://scripts/game/neon_draw.gd")
const Infinite := preload("res://scripts/systems/infinite_catalog.gd")

var level: Dictionary = {}
var base_level: Dictionary = {}
var current: Target
var next_target: Target
var start_target: Target
var floating_texts: Array[FloatingText] = []
var flipped: Array[FlippedTarget] = []

var started := false
var running := true
var is_infinite := false
var score := 0
var combo := 0
var combo_peak := 0
var hearts := LevelData.START_HEARTS
var time_left := LevelData.STAGE_TIME
var time_elapsed := 0.0
var stage_end_at := 0.0
var run_started_at := 0.0
var grace_until := 0.0
var beat_count := 0
var font: Font
var fx := ArcadeFx.new()
var anim_t := 0.0
var _ignore_mouse_until_ms := 0


func setup(level_id: int) -> void:
	var data := LevelData.get_level(level_id)
	if data.is_empty():
		push_warning("CyberTime: missing level %d" % level_id)
		return
	setup_level(data)


func setup_level(level_data: Dictionary) -> void:
	base_level = level_data.duplicate(true)
	level = base_level.duplicate(true)
	is_infinite = bool(level.get("infinite", false))
	SaveManager.selected_world = int(level.get("world", 1))
	hearts = LevelData.START_HEARTS
	score = 0
	combo = 0
	combo_peak = 0
	beat_count = 0
	started = false
	running = true
	time_elapsed = 0.0
	time_left = LevelData.STAGE_TIME
	current = Target.create(_active_level(), false)
	next_target = Target.create(_active_level(), _should_slider())
	start_target = _make_start_orb()
	font = ArcadeFonts.get_font()
	AudioManager.prepare_level_music(level)


func _ready() -> void:
	if not level.is_empty():
		return
	if SaveManager.play_mode == "infinite" and not SaveManager.pending_level.is_empty():
		setup_level(SaveManager.pending_level)
	elif SaveManager.selected_level > 0:
		setup(SaveManager.selected_level)


func _process(delta: float) -> void:
	if not running:
		return
	anim_t += delta
	fx.update(delta)
	queue_redraw()
	if not started:
		start_target.update(delta)
		return
	var now := Time.get_ticks_msec() / 1000.0
	var end_reason := _update_run(now, delta)
	if end_reason != "":
		_finish(end_reason == "time")


func _input(event: InputEvent) -> void:
	if not running:
		return
	if event is InputEventScreenTouch and event.pressed:
		# Phones also synthesize a mouse click; ignore that twin event.
		_ignore_mouse_until_ms = Time.get_ticks_msec() + 400
		_handle_click(_tap_action(), _touch_pos(event.position))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		if Time.get_ticks_msec() < _ignore_mouse_until_ms:
			get_viewport().set_input_as_handled()
			return
		var action := _action_from_mouse(event.button_index)
		if action == "":
			return
		_handle_click(action, _mouse_pos(event))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if SaveManager.mobile_mode:
			return
		var action := _resolve_action(event)
		if action == "":
			return
		_handle_click(action, get_global_mouse_position())
		get_viewport().set_input_as_handled()


func begin_game() -> void:
	if started:
		return
	started = true
	var now := Time.get_ticks_msec() / 1000.0
	run_started_at = now
	grace_until = now + LevelData.GRACE_SECONDS
	stage_end_at = now + LevelData.STAGE_TIME
	current.activate(now)
	AudioManager.start_level_music(level, Callable(self, "_on_beat"))


func _on_beat() -> void:
	if not running or not started:
		return
	beat_count += 1
	var now := Time.get_ticks_msec() / 1000.0
	if not current.is_active:
		current.activate(now)
		return
	if beat_count % 4 == 0:
		next_target = Target.create(_active_level(), _should_slider())


func _update_run(now: float, delta: float) -> String:
	if is_infinite:
		time_elapsed = maxf(0.0, now - run_started_at)
		time_left = time_elapsed
		level = _active_level()
	else:
		time_left = maxf(0.0, stage_end_at - now)
		if time_left <= LevelData.MUSIC_FADE_SECONDS:
			AudioManager.set_music_fade(time_left, LevelData.MUSIC_FADE_SECONDS)
		if time_left <= 0.0:
			return "time"
	if hearts <= 0:
		return "hearts"
	current.update(delta)
	if current.is_off_screen or (now > grace_until and current.is_expired(now)):
		_fail_boom()
		return "exploded"
	_update_fx(delta)
	return ""


func _update_fx(delta: float) -> void:
	var keep_ft: Array[FloatingText] = []
	for ft in floating_texts:
		ft.update(delta)
		if ft.is_done:
			if ft.value != 0:
				score += ft.value
		else:
			keep_ft.append(ft)
	floating_texts = keep_ft
	var keep_flip: Array[FlippedTarget] = []
	for pt in flipped:
		pt.update(delta)
		if not pt.is_off_screen:
			keep_flip.append(pt)
	flipped = keep_flip


func _handle_click(action: String, pos: Vector2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if not started:
		if _try_start_click(action, pos):
			begin_game()
		return
	var result := current.check_click(pos)
	if result == "MISS":
		_register_miss(pos)
		return
	if result == "SAFE_ZONE":
		return
	if SaveManager.mobile_mode:
		_handle_mobile_tap(now)
		return
	match current.kind:
		Target.Kind.ORANGE:
			_handle_orange(action, now)
		Target.Kind.PURPLE:
			_handle_purple(action, now)
		_:
			_resolve_hit(action, now)


func _handle_mobile_tap(now: float) -> void:
	match current.kind:
		Target.Kind.BALL:
			_bump_combo()
			_float("+%d" % combo, current.position, LevelData.COLORS.green, combo)
			fx.hit(current.position, LevelData.COLORS.blue, combo)
			AudioManager.play_hit()
			_advance(LevelData.COLORS.blue, now)
		Target.Kind.BOMB:
			current.mobile_tap_count += 1
			if current.mobile_tap_count < 2:
				_float("%d/2" % current.mobile_tap_count, current.position + Vector2(0, -20), LevelData.COLORS.text)
				AudioManager.play_defuse()
				return
			_bump_combo()
			_float("+%d" % combo, current.position, LevelData.COLORS.green, combo)
			fx.hit(current.position, LevelData.COLORS.red, combo)
			AudioManager.play_hit()
			_advance(LevelData.COLORS.red, now)
		Target.Kind.ORANGE:
			current.mobile_tap_count += 1
			if current.mobile_tap_count == 1:
				_float("1/3", current.position + Vector2(0, -20), LevelData.COLORS.text)
				AudioManager.play_defuse()
				return
			if current.mobile_tap_count == 2:
				current.defused = true
				current.confirm_expires_at = now + LevelData.ORANGE_CONFIRM_MS / 1000.0
				_float("2/3", current.position + Vector2(0, -20), LevelData.COLORS.text)
				AudioManager.play_defuse()
				return
			_bump_combo()
			var points := combo + 2
			_float("+%d" % points, current.position, LevelData.COLORS.green, points)
			fx.hit(current.position, LevelData.COLORS.orange, combo)
			AudioManager.play_hit()
			_advance(LevelData.COLORS.orange, now)
		Target.Kind.PURPLE:
			current.mobile_tap_count += 1
			if current.mobile_tap_count < 2:
				_float("%d/2" % current.mobile_tap_count, current.position + Vector2(0, -20), LevelData.COLORS.purple)
				AudioManager.play_defuse()
				return
			_bump_combo()
			var pts := combo + 1
			_float("+%d" % pts, current.position, LevelData.COLORS.green, pts)
			fx.hit(current.position, LevelData.COLORS.purple, combo)
			AudioManager.play_hit()
			_advance(LevelData.COLORS.purple, now)


func _try_start_click(action: String, pos: Vector2) -> bool:
	if start_target.check_click(pos) != "HIT":
		return false
	if SaveManager.mobile_mode:
		return _try_start_mobile()
	match start_target.kind:
		Target.Kind.BALL:
			return action == "ball"
		Target.Kind.BOMB:
			return action == "bomb"
		Target.Kind.ORANGE:
			if not start_target.defused:
				if action != "bomb":
					return false
				start_target.defused = true
				AudioManager.play_defuse()
				return false
			return action == "ball"
		Target.Kind.PURPLE:
			return action == "purple"
	return false


func _try_start_mobile() -> bool:
	match start_target.kind:
		Target.Kind.BALL:
			return true
		Target.Kind.BOMB:
			start_target.mobile_tap_count += 1
			if start_target.mobile_tap_count < 2:
				AudioManager.play_defuse()
				return false
			return true
		Target.Kind.ORANGE:
			start_target.mobile_tap_count += 1
			if start_target.mobile_tap_count < 3:
				if start_target.mobile_tap_count == 2:
					start_target.defused = true
				AudioManager.play_defuse()
				return false
			return true
		Target.Kind.PURPLE:
			start_target.mobile_tap_count += 1
			if start_target.mobile_tap_count < 2:
				AudioManager.play_defuse()
				return false
			return true
	return false


func _handle_orange(action: String, now: float) -> void:
	if not current.defused:
		if action != "bomb":
			_wrong_hit()
			return
		current.defused = true
		current.confirm_expires_at = now + LevelData.ORANGE_CONFIRM_MS / 1000.0
		_float("CLICK!", current.position + Vector2(0, -20), LevelData.COLORS.green)
		fx.burst(current.position, LevelData.COLORS.orange, 8)
		AudioManager.play_defuse()
		return
	if action != "ball":
		_wrong_hit()
		return
	_bump_combo()
	var points := combo + 2
	_float("+%d" % points, current.position, LevelData.COLORS.green, points)
	fx.hit(current.position, LevelData.COLORS.orange, combo)
	AudioManager.play_hit()
	_advance(LevelData.COLORS.orange, now)


func _handle_purple(action: String, now: float) -> void:
	if action != "purple":
		_wrong_hit()
		return
	_bump_combo()
	var points := combo + 1
	_float("+%d" % points, current.position, LevelData.COLORS.green, points)
	fx.hit(current.position, LevelData.COLORS.purple, combo)
	AudioManager.play_hit()
	_advance(LevelData.COLORS.purple, now)


func _resolve_hit(action: String, now: float) -> void:
	var needs_ball := current.kind == Target.Kind.BALL
	var correct := (needs_ball and action == "ball") or (not needs_ball and action == "bomb")
	if not correct:
		_wrong_hit()
		return
	_bump_combo()
	var color: Color = LevelData.COLORS.blue if needs_ball else LevelData.COLORS.red
	_float("+%d" % combo, current.position, LevelData.COLORS.green, combo)
	fx.hit(current.position, color, combo)
	AudioManager.play_hit()
	_advance(color, now)


func _wrong_hit() -> void:
	current.defused = false
	current.mobile_tap_count = 0
	combo = 0
	_float("-1", current.position, LevelData.COLORS.red, -1)
	fx.miss(current.position)
	AudioManager.play_miss()


func _register_miss(pos: Vector2) -> void:
	combo = 0
	hearts -= 1
	_float("-1", pos, LevelData.COLORS.red, 0, true)
	fx.miss(pos)
	fx.damage_flash()
	AudioManager.play_miss()


func _fail_boom() -> void:
	hearts = 0
	combo = 0
	_float("BOOM!", current.position + Vector2(0, -24), LevelData.COLORS.red)
	fx.boom(current.position)
	fx.damage_flash()
	AudioManager.play_miss()


func _advance(color: Color, now: float) -> void:
	flipped.append(FlippedTarget.new(current.position, current.radius, color))
	current = next_target
	current.activate(now)
	next_target = Target.create(_active_level(), _should_slider())


func _bump_combo() -> void:
	combo += 1
	combo_peak = maxi(combo_peak, combo)


func _float(text: String, pos: Vector2, color: Color, value: int = 0, show_heart: bool = false) -> void:
	floating_texts.append(FloatingText.new(text, pos, color, value, show_heart))


func _finish(won: bool) -> void:
	running = false
	AudioManager.stop_music()
	var effective_won := false if is_infinite else won
	SaveManager.apply_run_rewards(score, combo_peak, int(level.get("id", 0)), effective_won)
	if is_infinite:
		SaveManager.last_run["survived"] = time_elapsed
		SaveManager.last_run["infinite"] = true
		SaveManager.save()
	run_finished.emit(effective_won)


func _active_level() -> Dictionary:
	if is_infinite:
		return Infinite.ramp(base_level, time_elapsed)
	return level


func _should_slider() -> bool:
	var cfg := _active_level()
	return cfg.sliders and randf() < float(cfg.slider_chance)


func _make_start_orb() -> Target:
	var t := Target.create(_active_level(), false)
	t.position = Vector2(640, 360)
	t.radius = 58.0 if SaveManager.mobile_mode else 48.0
	if level.allow_orange:
		t.kind = Target.Kind.ORANGE
	elif level.allow_red:
		t.kind = Target.Kind.BOMB
	else:
		t.kind = Target.Kind.BALL
	t.is_active = true
	return t


func _action_from_mouse(button_index: int) -> String:
	if SaveManager.mobile_mode:
		if button_index == MOUSE_BUTTON_LEFT:
			return "ball"
		return ""
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "ball"
		MOUSE_BUTTON_RIGHT:
			return "bomb"
		MOUSE_BUTTON_MIDDLE:
			return "purple"
	return ""


func _tap_action() -> String:
	return "ball"


func _touch_pos(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos


func _mouse_pos(event: InputEventMouseButton) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * event.position


func _resolve_action(event: InputEvent) -> String:
	if event.is_action_pressed("hit_ball"):
		return "ball"
	if event.is_action_pressed("hit_bomb"):
		return "bomb"
	if event.is_action_pressed("hit_purple"):
		return "purple"
	return ""


func _draw() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var theme := LevelData.arena_theme(level, SaveManager.current_theme())
	var shake := fx.offset()
	draw_set_transform(shake, 0.0, Vector2.ONE)
	Draw.draw_arcade_bg(self, anim_t, theme)
	if int(level.get("world", 1)) == 2:
		Draw.draw_hex_world_fx(self, anim_t, theme)
	if not started and start_target:
		Draw.draw_target(self, start_target, now, font)
		Draw.draw_ready(self, font, level)
	else:
		if next_target:
			Draw.draw_target(self, next_target, now, font)
		if current:
			Draw.draw_target(self, current, now, font)
	for pt in flipped:
		Draw.draw_flipped(self, pt)
	for ft in floating_texts:
		Draw.draw_floating(self, font, ft)
	fx.draw(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Draw.draw_hud(self, font, score, combo, hearts, time_left, started, level, SaveManager.coins)
	fx.draw_damage_overlay(self)
