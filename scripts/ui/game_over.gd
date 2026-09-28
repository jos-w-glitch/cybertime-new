extends Control

@onready var title: Label = $Center/VBox/Title
@onready var details: Label = $Center/VBox/Details
@onready var rewards: Label = $Center/VBox/Rewards
@onready var next_btn: Button = $Center/VBox/Next
@onready var retry_btn: Button = $Center/VBox/Retry
@onready var home_btn: Button = $Center/VBox/Home


func _ready() -> void:
	var font: Font = ArcadeFonts.get_font()
	var run: Dictionary = SaveManager.last_run
	var won: bool = bool(run.get("won", false))
	var level_id: int = int(run.get("level_id", 1))
	var infinite: bool = bool(run.get("infinite", false))

	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 56)
	if infinite:
		title.text = "RUN OVER"
		title.add_theme_color_override("font_color", LevelData.COLORS.gold)
	else:
		title.text = "STAGE CLEAR" if won else "WASTED"
		title.add_theme_color_override("font_color", LevelData.COLORS.green if won else LevelData.COLORS.red)

	for label: Label in [details, rewards]:
		label.add_theme_font_override("font", font)
		label.add_theme_color_override("font_color", LevelData.COLORS.text)

	if infinite:
		details.text = "Score %d  ·  Survived %ds  ·  Best %d" % [
			run.get("score", 0), int(run.get("survived", 0)), SaveManager.infinite_best_score()
		]
	else:
		details.text = "Score %d  ·  Peak combo x%d" % [run.get("score", 0), run.get("combo_peak", 0)]
	rewards.text = "+%d XP   +%d COINS" % [run.get("xp_gain", 0), run.get("coin_gain", 0)]

	for btn: Button in [next_btn, retry_btn, home_btn]:
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 24)

	next_btn.text = "NEXT"
	retry_btn.text = "RETRY"
	home_btn.text = "HOME"

	var next_id := LevelData.next_level_id(level_id)
	var has_next := (not infinite) and won and next_id > 0
	next_btn.visible = has_next
	next_btn.pressed.connect(func() -> void:
		SaveManager.play_mode = "story"
		SaveManager.selected_level = next_id
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")
	)
	retry_btn.pressed.connect(func() -> void:
		if infinite:
			var tracks := LevelData.levels_for_world(1)
			var idx := clampi(SaveManager.infinite_track_index, 0, maxi(0, tracks.size() - 1))
			SaveManager.begin_infinite(tracks[idx], SaveManager.infinite_preset_index)
		else:
			SaveManager.play_mode = "story"
			SaveManager.selected_level = level_id
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")
	)
	home_btn.pressed.connect(func() -> void:
		SaveManager.clear_play_mode()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	AudioManager.play_menu_music()
