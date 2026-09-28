class_name FloatingText
extends RefCounted

var text: String
var position: Vector2
var color: Color
var value: int
var speed := 5.0
var is_done := false
var target := Vector2(40, 30)


func _init(p_text: String, pos: Vector2, p_color: Color, p_value: int = 0) -> void:
	text = p_text
	position = pos
	color = p_color
	value = p_value


func update(delta: float) -> void:
	var dir := target - position
	var dist := dir.length()
	if dist <= 15.0:
		is_done = true
		return
	position += dir.normalized() * speed * delta * 60.0
	speed += 0.25 * delta * 60.0
