class_name Target
extends RefCounted

enum Kind { BALL, BOMB, ORANGE, PURPLE }

var kind: Kind = Kind.BALL
var radius: float = 26.0
var position := Vector2.ZERO
var is_active := false
var is_slider := false
var is_off_screen := false
var defused := false
var mobile_tap_count := 0
var hit_zone_x := 640.0
var activated_at := 0.0
var expires_at := 0.0
var bomb_expires := 0.0
var confirm_expires_at := 0.0
var hit_window_ms := 2800.0
var bomb_fuse := 5.0
var velocity := Vector2.ZERO
var path_from := Vector2.ZERO
var path_to := Vector2.ZERO
var move_angle := 0.0
var pulse_angle := 0.0
var has_entered_screen := false


static func create(level: Dictionary, as_slider: bool = false) -> Target:
	var t := Target.new()
	t.hit_window_ms = float(level.get("hit_window_ms", 2800.0))
	t.bomb_fuse = float(level.get("bomb_fuse", 5.0))
	var scale := 1.55 if SaveManager.mobile_mode else 1.35
	t.radius = (24.0 + float(randi() % 10)) * scale
	t.pulse_angle = randf() * TAU
	t.is_slider = as_slider
	t.kind = t._pick_kind(level, as_slider)
	t.hit_zone_x = 640.0
	if as_slider:
		t._setup_slider(level)
	else:
		t.position = Vector2(100.0 + randf() * 1080.0, 140.0 + randf() * 440.0)
	return t


func _setup_slider(level: Dictionary) -> void:
	var stage := int(level.id) % 12
	if stage == 0:
		stage = 12
	var speed := 5.0 + float(stage) * 0.4
	var dir := _slider_direction(int(level.get("world", 1)))
	var center := Vector2(220.0 + randf() * 840.0, 170.0 + randf() * 380.0)
	position = center - dir * 1000.0
	while not _is_fully_off_screen(position):
		position -= dir * 50.0
	velocity = dir * speed
	move_angle = dir.angle()
	path_from = position - dir * 200.0
	path_to = position + dir * 2600.0


func _slider_direction(world: int) -> Vector2:
	if world < 2:
		return Vector2.RIGHT if randf() < 0.5 else Vector2.LEFT
	var dirs := [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 0.35), Vector2(1, -0.35),
		Vector2(-1, 0.35), Vector2(-1, -0.35),
		Vector2(0.75, 0.65), Vector2(0.75, -0.65),
		Vector2(-0.75, 0.65), Vector2(-0.75, -0.65),
		Vector2(0.45, 0.9), Vector2(-0.45, 0.9),
		Vector2(0.45, -0.9), Vector2(-0.45, -0.9),
	]
	return dirs[randi() % dirs.size()].normalized()


func _pick_kind(level: Dictionary, as_slider: bool) -> Kind:
	if as_slider:
		if bool(level.get("slider_red", false)) and randf() < float(level.get("slider_red_chance", 0.0)):
			return Kind.BOMB
		return Kind.BALL
	if not bool(level.get("allow_red", false)) and not bool(level.get("allow_orange", false)) and not bool(level.get("allow_purple", false)):
		return Kind.BALL
	var roll := randf()
	var purple_c := float(level.get("purple_chance", 0.0))
	var orange_c := float(level.get("orange_chance", 0.0))
	var red_c := float(level.get("red_chance", 0.0))
	if bool(level.get("allow_purple", false)) and roll < purple_c:
		return Kind.PURPLE
	if bool(level.get("allow_orange", false)) and roll < purple_c + orange_c:
		return Kind.ORANGE
	if bool(level.get("allow_red", false)) and roll < purple_c + orange_c + red_c:
		return Kind.BOMB
	return Kind.BALL


func activate(now: float) -> void:
	is_active = true
	defused = false
	mobile_tap_count = 0
	is_off_screen = false
	has_entered_screen = false
	activated_at = now
	expires_at = now + hit_window_ms / 1000.0
	if kind == Kind.BOMB or kind == Kind.ORANGE:
		bomb_expires = now + bomb_fuse


func ms_left(now: float) -> float:
	if not is_active:
		return hit_window_ms
	if is_slider:
		return hit_window_ms
	return maxf(0.0, (expires_at - now) * 1000.0)


func bomb_seconds_left(now: float) -> float:
	if not is_bomb() or not is_active or defused:
		return bomb_fuse
	return maxf(0.0, bomb_expires - now)


func is_bomb() -> bool:
	return kind == Kind.BOMB or kind == Kind.ORANGE


func is_expired(now: float) -> bool:
	if not is_active:
		return false
	if is_slider:
		return false
	if kind == Kind.ORANGE and defused:
		return now >= confirm_expires_at
	if is_bomb() and not defused and bomb_seconds_left(now) <= 0.0:
		return true
	return ms_left(now) <= 0.0


func update(delta: float) -> void:
	if not is_slider or not is_active:
		return
	position += velocity * delta * 60.0
	if _is_inside_play_area(position):
		has_entered_screen = true
		return
	if has_entered_screen and _is_fully_off_screen(position):
		is_off_screen = true


func _is_inside_play_area(pos: Vector2) -> bool:
	return pos.x >= -radius and pos.x <= 1280.0 + radius and pos.y >= -radius and pos.y <= 720.0 + radius


func _is_fully_off_screen(pos: Vector2) -> bool:
	var pad := radius + 24.0
	return pos.x < -pad or pos.x > 1280.0 + pad or pos.y < -pad or pos.y > 720.0 + pad


func check_click(pos: Vector2) -> String:
	var pad := 34.0 if SaveManager.mobile_mode else 12.0
	if is_slider and SaveManager.mobile_mode:
		pad = 42.0
	var dist := position.distance_to(pos)
	if dist <= radius + pad:
		return "HIT"
	if dist <= radius + LevelData.SAFE_ZONE_BORDER + pad:
		return "SAFE_ZONE"
	return "MISS"


func main_color() -> Color:
	match kind:
		Kind.BOMB:
			return LevelData.COLORS.red
		Kind.ORANGE:
			return LevelData.COLORS.orange if not defused else LevelData.COLORS.green
		Kind.PURPLE:
			return LevelData.COLORS.purple
		_:
			return LevelData.COLORS.blue
