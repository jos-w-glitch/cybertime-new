class_name FlippedTarget
extends RefCounted

var position: Vector2
var radius: float
var color: Color
var vel: Vector2
var gravity := 0.7
var is_off_screen := false


func _init(pos: Vector2, p_radius: float, p_color: Color) -> void:
	position = pos
	radius = p_radius
	color = p_color
	var direction := -1.0 if randf() < 0.5 else 1.0
	vel = Vector2(direction * (4.0 + randf() * 4.0), -(14.0 + randf() * 6.0))


func update(delta: float) -> void:
	var step := delta * 60.0
	position.x += vel.x * step
	vel.y += gravity * step
	position.y += vel.y * step
	if position.y > 770.0:
		is_off_screen = true
