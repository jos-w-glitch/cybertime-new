extends Control

@onready var grid: GridContainer = $Margin/VBox/Grid
@onready var back_btn: Button = $Margin/VBox/Back
@onready var title: Label = $Margin/VBox/Title
@onready var yen_label: Label = $Margin/VBox/Yen


func _ready() -> void:
	var font: Font = ArcadeFonts.get_font()
	var world := LevelData.get_world(SaveManager.selected_world)
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", world.get("accent", LevelData.COLORS.text))
	title.text = str(world.get("name", "STAGES"))
	yen_label.add_theme_font_override("font", font)
	yen_label.add_theme_color_override("font_color", LevelData.COLORS.gold)
	yen_label.text = "%d COINS" % SaveManager.coins
	back_btn.add_theme_font_override("font", font)
	back_btn.text = "WORLDS"
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/world_select.tscn")
	)
	_build_buttons(font)
	AudioManager.play_menu_music()


func _build_buttons(font: Font) -> void:
	for child in grid.get_children():
		child.queue_free()
	var stages := LevelData.levels_for_world(SaveManager.selected_world)
	var index := 0
	for level in stages:
		index += 1
		var id: int = int(level.id)
		var unlocked := LevelData.is_unlocked(id, SaveManager.cleared_levels)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(280, 72)
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 18)
		var best := SaveManager.best_score(id)
		var clear_mark := " ✓" if SaveManager.is_level_cleared(id) else ""
		if unlocked:
			btn.text = "%d. %s%s\nBest %d" % [index, level.name, clear_mark, best]
			btn.pressed.connect(_play_level.bind(id))
		else:
			btn.text = "%d. LOCKED" % index
			btn.disabled = true
		grid.add_child(btn)


func _play_level(level_id: int) -> void:
	SaveManager.play_mode = "story"
	SaveManager.pending_level = {}
	SaveManager.selected_level = level_id
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")
