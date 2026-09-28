extends Node2D

const Draw := preload("res://scripts/game/neon_draw.gd")

var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	Draw.draw_arcade_bg(self, t, SaveManager.current_theme())
