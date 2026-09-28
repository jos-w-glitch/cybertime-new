extends Node

var display: Font
var jp: Font


func _ready() -> void:
	TranslationServer.set_locale("en")
	jp = SystemFont.new()
	jp.font_names = PackedStringArray(["Hiragino Sans", "Arial Unicode MS", "Apple SD Gothic Neo", "Noto Sans CJK JP"])
	var base: Font = load("res://assets/fonts/Cyberjunkies.ttf")
	if base:
		base.fallbacks = [jp]
		display = base
	else:
		display = jp


func get_font() -> Font:
	return display if display else jp
