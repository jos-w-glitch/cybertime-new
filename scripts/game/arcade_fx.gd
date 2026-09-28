class_name ArcadeFx
extends RefCounted

var sparks: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var shake := 0.0
var flash := 0.0
var flash_color := Color.WHITE
var time := 0.0


func update(delta: float) -> void:
	time += delta
	shake = maxf(0.0, shake - delta * 8.0)
	flash = maxf(0.0, flash - delta * 1.2)
	var keep_s: Array[Dictionary] = []
	for s in sparks:
		s.life -= delta
		s.pos += s.vel * delta
		s.vel *= 0.92
		if s.life > 0.0:
			keep_s.append(s)
	sparks = keep_s
	var keep_r: Array[Dictionary] = []
	for r in rings:
		r.life -= delta
		r.radius += r.speed * delta
		if r.life > 0.0:
			keep_r.append(r)
	rings = keep_r


func burst(pos: Vector2, color: Color, count: int = 14) -> void:
	for i in count:
		var ang := randf() * TAU
		var spd := 80.0 + randf() * 220.0
		sparks.append({
			"pos": pos,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"life": 0.25 + randf() * 0.45,
			"max": 0.7,
			"color": color,
			"size": 2.0 + randf() * 3.5,
		})
	rings.append({
		"pos": pos,
		"radius": 8.0,
		"speed": 180.0 + randf() * 80.0,
		"life": 0.35,
		"max": 0.35,
		"color": color,
	})


func boom(pos: Vector2) -> void:
	burst(pos, LevelData.COLORS.red, 28)
	burst(pos, LevelData.COLORS.gold, 12)
	shake = 1.0
	flash = 1.0
	flash_color = LevelData.COLORS.red


func hit(pos: Vector2, color: Color, combo: int) -> void:
	burst(pos, color, 10 + mini(combo, 12))
	if combo >= 5:
		shake = maxf(shake, 0.25)
	if combo >= 10:
		flash = maxf(flash, 0.35)
		flash_color = color


func miss(pos: Vector2) -> void:
	burst(pos, LevelData.COLORS.red, 8)
	shake = maxf(shake, 0.3)
	flash = 1.0
	flash_color = LevelData.COLORS.red


func damage_flash() -> void:
	flash = 1.0
	flash_color = LevelData.COLORS.red
	shake = maxf(shake, 0.35)


func offset() -> Vector2:
	if shake <= 0.0:
		return Vector2.ZERO
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 6.0


func draw(canvas: CanvasItem) -> void:
	for r in rings:
		var a := clampf(r.life / r.max, 0.0, 1.0)
		canvas.draw_arc(r.pos, r.radius, 0, TAU, 48, Color(r.color, a * 0.7), 2.0)
	for s in sparks:
		var a := clampf(s.life / s.max, 0.0, 1.0)
		canvas.draw_circle(s.pos, s.size * a, Color(s.color, a))


func draw_damage_overlay(canvas: CanvasItem) -> void:
	if flash <= 0.0:
		return
	canvas.draw_rect(Rect2(0, 0, 1280, 720), Color(flash_color, flash * 0.38))
