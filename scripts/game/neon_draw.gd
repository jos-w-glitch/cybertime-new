class_name NeonDraw
extends RefCounted


static func draw_arcade_bg(canvas: CanvasItem, t: float, theme: Dictionary) -> void:
	var image: Variant = theme.get("image", null)
	if image is Texture2D:
		canvas.draw_texture_rect(image, Rect2(0, 0, 1280, 720), false)
		canvas.draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.35))
		var accent: Color = theme.get("accent", LevelData.COLORS.gold)
		var y := fmod(t * 40.0, 720.0)
		canvas.draw_line(Vector2(0, y), Vector2(1280, y), Color(accent, 0.12), 2.0)
		return
	var bg: Color = theme.get("bg", LevelData.COLORS.bg)
	var grid: Color = theme.get("grid", LevelData.COLORS.grid)
	draw_grid(canvas, bg, grid)
	var accent2: Color = theme.get("accent", LevelData.COLORS.text)
	var scan := fmod(t * 40.0, 720.0)
	canvas.draw_line(Vector2(0, scan), Vector2(1280, scan), Color(accent2, 0.08), 2.0)


static func draw_hex_world_fx(canvas: CanvasItem, t: float, theme: Dictionary) -> void:
	var accent: Color = theme.get("accent", LevelData.COLORS.gold)
	var pulse := 0.35 + 0.25 * sin(t * 2.2)
	canvas.draw_rect(Rect2(0, 0, 1280, 18), Color(accent, pulse * 0.55))
	canvas.draw_rect(Rect2(0, 702, 1280, 18), Color(accent, pulse * 0.55))
	for i in 6:
		var x := 120.0 + i * 180.0 + sin(t + i) * 8.0
		canvas.draw_line(Vector2(x, 0), Vector2(x + 40, 720), Color(accent, 0.04), 2.0)


static func draw_grid(canvas: CanvasItem, bg: Color, grid: Color) -> void:
	canvas.draw_rect(Rect2(0, 0, 1280, 720), bg)
	for x in range(0, 1281, 40):
		canvas.draw_line(Vector2(x, 0), Vector2(x, 720), grid, 1.0)
	for y in range(0, 721, 40):
		canvas.draw_line(Vector2(0, y), Vector2(1280, y), grid, 1.0)


static func draw_target(canvas: CanvasItem, t: Target, now: float, font: Font) -> void:
	if t.is_slider:
		draw_slider_path(canvas, t)

	if not t.is_active:
		if t.is_slider:
			return
		canvas.draw_circle(t.position, t.radius, Color(0.14, 0.14, 0.18))
		canvas.draw_arc(t.position, t.radius, 0, TAU, 48, LevelData.COLORS.gray, 2.0)
		return

	var color := t.main_color()
	var urgency := 0.0 if t.is_slider else (1.0 - t.ms_left(now) / t.hit_window_ms)
	t.pulse_angle += 0.12
	var pulse := sin(t.pulse_angle) * (2.0 + urgency * 3.0)
	var r := t.radius + pulse

	canvas.draw_circle(t.position, r + 10.0, Color(color, 0.18))
	canvas.draw_circle(t.position, r, color)
	canvas.draw_arc(t.position, r + 6.0, 0, TAU, 48, Color(color, 0.7), 3.0)

	if not t.is_slider:
		var life := t.ms_left(now) / t.hit_window_ms
		var ring: Color = LevelData.COLORS.red if life < 0.3 else LevelData.COLORS.text
		canvas.draw_arc(t.position, r + 12.0, -PI / 2.0, -PI / 2.0 + TAU * life, 48, ring, 3.0)

	if t.is_bomb() and not t.defused and not t.is_slider:
		text(canvas, font, "%.1f" % t.bomb_seconds_left(now), t.position + Vector2(0, 6), 18, Color(0.1, 0.05, 0.05), true)
	elif t.kind == Target.Kind.ORANGE and t.defused:
		text(canvas, font, "GO", t.position + Vector2(0, 6), 18, Color(0.05, 0.15, 0.05), true)


static func draw_slider_path(canvas: CanvasItem, t: Target) -> void:
	var color := t.main_color() if t.is_active else LevelData.COLORS.gray
	var alpha := 0.55 if t.is_active else 0.4
	canvas.draw_line(t.path_from, t.path_to, Color(color, alpha * 0.35), 10.0)
	canvas.draw_line(t.path_from, t.path_to, Color(color, alpha), 3.0)
	if not t.is_active:
		var mid := (t.path_from + t.path_to) * 0.5
		canvas.draw_circle(mid, t.radius * 0.55, Color(color, 0.25))
		canvas.draw_arc(mid, t.radius * 0.55, 0, TAU, 32, Color(color, 0.55), 2.0)


static func draw_flipped(canvas: CanvasItem, pt: FlippedTarget) -> void:
	canvas.draw_arc(pt.position, pt.radius + 4.0, 0, TAU, 32, pt.color, 2.0)
	canvas.draw_circle(pt.position, maxf(2.0, pt.radius - 2.0), Color.WHITE)


static func draw_hud(
	canvas: CanvasItem, font: Font, score: int, combo: int, hearts: int,
	time_left: float, started: bool, level: Dictionary, coins: int
) -> void:
	var infinite := bool(level.get("infinite", false))
	text(canvas, font, "SCORE: %d" % score, Vector2(20, 40), 36, LevelData.COLORS.text)
	text(canvas, font, "COINS: %d" % coins, Vector2(20, 160), 22, LevelData.COLORS.gold)
	if not started:
		if infinite:
			text(canvas, font, "SURVIVE", Vector2(980, 40), 36, LevelData.COLORS.gold)
		else:
			text(canvas, font, "TIME: %ds" % int(LevelData.STAGE_TIME), Vector2(980, 40), 36, LevelData.COLORS.gold)
	else:
		var combo_c: Color = LevelData.COLORS.green if combo >= 3 else LevelData.COLORS.text
		text(canvas, font, "COMBO: x%d" % combo, Vector2(520, 40), 36, combo_c)
		if infinite:
			text(canvas, font, "LIVE: %ds" % int(time_left), Vector2(980, 40), 36, LevelData.COLORS.gold)
		else:
			var time_c: Color = LevelData.COLORS.red if time_left <= 10.0 else LevelData.COLORS.text
			text(canvas, font, "TIME: %ds" % ceili(time_left), Vector2(980, 40), 36, time_c)
	text(canvas, font, "%s  BPM %d" % [level.name, level.bpm], Vector2(20, 78), 20, LevelData.COLORS.text)
	for i in LevelData.START_HEARTS:
		var filled := i < hearts
		var c: Color = LevelData.COLORS.red if filled else Color(LevelData.COLORS.gray, 0.45)
		draw_heart(canvas, Vector2(40 + i * 36, 114), 14.0, c)


static func draw_heart(canvas: CanvasItem, pos: Vector2, size: float, color: Color) -> void:
	canvas.draw_circle(pos + Vector2(-size * 0.35, -size * 0.22), size * 0.42, color)
	canvas.draw_circle(pos + Vector2(size * 0.35, -size * 0.22), size * 0.42, color)
	var tip := PackedVector2Array([
		pos + Vector2(-size * 0.74, -size * 0.08),
		pos + Vector2(size * 0.74, -size * 0.08),
		pos + Vector2(0.0, size * 0.82),
	])
	canvas.draw_colored_polygon(tip, color)
	if color.a > 0.5:
		canvas.draw_circle(pos + Vector2(-size * 0.28, -size * 0.28), size * 0.14, Color(1, 1, 1, 0.35))


static func draw_ready(canvas: CanvasItem, font: Font, level: Dictionary) -> void:
	text(canvas, font, "HIT THE ORB TO START", Vector2(640, 260), 28, LevelData.COLORS.gold, true)
	text(canvas, font, str(level.hint), Vector2(640, 470), 20, LevelData.COLORS.text, true)
	if SaveManager.mobile_mode:
		text(canvas, font, "TAP blue  ·  RED 2 taps  ·  ORANGE 3 taps", Vector2(640, 510), 16, LevelData.COLORS.gray, true)
	else:
		text(canvas, font, "LMB/Z blue  ·  RMB/X red  ·  orange = right then left", Vector2(640, 510), 16, LevelData.COLORS.gray, true)


static func text(
	canvas: CanvasItem, font: Font, value: String, pos: Vector2, size: int, color: Color, centered := false
) -> void:
	if font == null:
		return
	var offset := Vector2.ZERO
	if centered:
		var m := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		offset = Vector2(-m.x * 0.5, 0)
	canvas.draw_string(font, pos + offset, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
