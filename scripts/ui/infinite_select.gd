extends Control

const Catalog := preload("res://scripts/systems/infinite_catalog.gd")

@onready var title: Label = $Margin/VBox/Title
@onready var yen_label: Label = $Margin/VBox/Yen
@onready var track_label: Label = $Margin/VBox/TrackLabel
@onready var mech_label: Label = $Margin/VBox/MechLabel
@onready var best_label: Label = $Margin/VBox/Best
@onready var track_dropdown: OptionButton = $Margin/VBox/TrackDropdown
@onready var mech_dropdown: OptionButton = $Margin/VBox/MechDropdown
@onready var start_btn: Button = $Margin/VBox/Start
@onready var back_btn: Button = $Margin/VBox/Back

var _tracks: Array[Dictionary] = []


func _ready() -> void:
	_tracks = LevelData.levels_for_world(1)
	var font: Font = ArcadeFonts.get_font()
	_style(font)
	_fill_dropdowns()
	track_dropdown.item_selected.connect(_on_track_selected)
	mech_dropdown.item_selected.connect(_on_mech_selected)
	start_btn.pressed.connect(_start)
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	_refresh_labels()
	AudioManager.play_menu_music()


func _style(font: Font) -> void:
	for node: Control in [title, yen_label, track_label, mech_label, best_label]:
		node.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", LevelData.COLORS.text)
	title.text = "INFINITE MODE"
	yen_label.add_theme_color_override("font_color", LevelData.COLORS.gold)
	track_label.text = "TRACK"
	mech_label.text = "MECHANICS"
	for btn: BaseButton in [track_dropdown, mech_dropdown, start_btn, back_btn]:
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 24)
	start_btn.text = "START RUN"
	back_btn.text = "BACK"


func _fill_dropdowns() -> void:
	track_dropdown.clear()
	for i in _tracks.size():
		var track: Dictionary = _tracks[i]
		track_dropdown.add_item("%d. %s" % [i + 1, track.name], i)
	var track_idx := clampi(SaveManager.infinite_track_index, 0, maxi(0, _tracks.size() - 1))
	track_dropdown.select(track_idx)

	mech_dropdown.clear()
	for i in Catalog.PRESETS.size():
		mech_dropdown.add_item(str(Catalog.PRESETS[i].name), i)
	var mech_idx := clampi(SaveManager.infinite_preset_index, 0, Catalog.PRESETS.size() - 1)
	mech_dropdown.select(mech_idx)


func _on_track_selected(index: int) -> void:
	SaveManager.infinite_track_index = index
	_refresh_labels()


func _on_mech_selected(index: int) -> void:
	SaveManager.infinite_preset_index = index
	_refresh_labels()


func _refresh_labels() -> void:
	yen_label.text = "%d COINS" % SaveManager.coins
	best_label.text = "BEST: %d" % SaveManager.infinite_best_score()
	best_label.add_theme_color_override("font_color", LevelData.COLORS.gold)


func _start() -> void:
	if _tracks.is_empty():
		return
	var track_idx := track_dropdown.selected
	var mech_idx := mech_dropdown.selected
	SaveManager.infinite_track_index = track_idx
	SaveManager.infinite_preset_index = mech_idx
	SaveManager.begin_infinite(_tracks[track_idx], mech_idx)
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")
