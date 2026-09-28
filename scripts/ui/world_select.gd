extends Control

@onready var title: Label = $Margin/VBox/Title
@onready var yen_label: Label = $Margin/VBox/Yen
@onready var list: VBoxContainer = $Margin/VBox/List
@onready var back_btn: Button = $Margin/VBox/Back


func _ready() -> void:
	var font: Font = ArcadeFonts.get_font()
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", LevelData.COLORS.text)
	title.text = "SELECT WORLD"
	yen_label.add_theme_font_override("font", font)
	yen_label.add_theme_color_override("font_color", LevelData.COLORS.gold)
	yen_label.text = "%d COINS" % SaveManager.coins
	back_btn.add_theme_font_override("font", font)
	back_btn.text = "BACK"
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	_build_worlds(font)
	AudioManager.play_menu_music()


func _build_worlds(font: Font) -> void:
	for child in list.get_children():
		child.queue_free()
	for world in LevelData.worlds:
		var id: int = int(world.id)
		var unlocked := LevelData.is_world_unlocked(id, SaveManager.cleared_levels)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(520, 96)
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 26)
		if unlocked:
			btn.text = "WORLD %d — %s\n%s" % [id, world.name, world.tagline]
			btn.pressed.connect(_open_world.bind(id))
		else:
			btn.text = "WORLD %d — LOCKED\nClear World %d finale first" % [id, id - 1]
			btn.disabled = true
		list.add_child(btn)


func _open_world(world_id: int) -> void:
	SaveManager.selected_world = world_id
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
