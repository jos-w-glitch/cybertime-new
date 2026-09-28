extends Control

@onready var title: Label = $Margin/VBox/Title
@onready var yen_label: Label = $Margin/VBox/Yen
@onready var backgrounds: VBoxContainer = $Margin/VBox/Scroll/Lists/Backgrounds
@onready var back_btn: Button = $Margin/VBox/Back

var _font: Font
var _file_dialog: FileDialog


func _ready() -> void:
	_font = ArcadeFonts.get_font()
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", LevelData.COLORS.text)
	title.text = "SHOP"
	yen_label.add_theme_font_override("font", _font)
	yen_label.add_theme_color_override("font_color", LevelData.COLORS.gold)
	back_btn.add_theme_font_override("font", _font)
	back_btn.text = "BACK"
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	_setup_file_dialog()
	_refresh()
	AudioManager.play_menu_music()


func _setup_file_dialog() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.title = "Choose Background Image"
	_file_dialog.filters = PackedStringArray([
		"*.png ; PNG Images",
		"*.jpg,*.jpeg ; JPEG Images",
		"*.webp ; WebP Images",
	])
	_file_dialog.use_native_dialog = true
	_file_dialog.file_selected.connect(_on_custom_file_selected)
	add_child(_file_dialog)


func _refresh() -> void:
	yen_label.text = "%d COINS" % SaveManager.coins
	_fill_backgrounds()


func _fill_backgrounds() -> void:
	for child in backgrounds.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = "BACKGROUNDS"
	header.add_theme_font_override("font", _font)
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", LevelData.COLORS.text)
	backgrounds.add_child(header)
	for item in LevelData.SHOP_BACKGROUNDS:
		_add_background_row(item)


func _add_background_row(item: Dictionary) -> void:
	var id := str(item.id)
	var owned: bool = SaveManager.owns_background(id)
	var equipped: bool = SaveManager.equipped_background == id
	var is_custom := bool(item.get("custom", false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	if is_custom and SaveManager.has_custom_background():
		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(56, 40)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview.texture = SaveManager.custom_bg_texture
		row.add_child(preview)
	elif item.has("accent"):
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(56, 40)
		swatch.color = item.accent
		row.add_child(swatch)
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(280, 48)
	btn.add_theme_font_override("font", _font)
	if is_custom:
		btn.text = _custom_button_text(owned, equipped)
		btn.pressed.connect(_on_custom_pressed.bind(int(item.price)))
	elif equipped:
		btn.text = "%s  — EQUIPPED" % item.name
		btn.pressed.connect(_buy.bind(id, int(item.price)))
	elif owned:
		btn.text = "%s  — SELECT" % item.name
		btn.pressed.connect(_buy.bind(id, int(item.price)))
	else:
		btn.text = "%s  — %d COINS" % [item.name, item.price]
		btn.pressed.connect(_buy.bind(id, int(item.price)))
	row.add_child(btn)
	if is_custom and owned:
		var upload := Button.new()
		upload.custom_minimum_size = Vector2(120, 48)
		upload.add_theme_font_override("font", _font)
		upload.text = "UPLOAD"
		upload.pressed.connect(_open_upload)
		row.add_child(upload)
	backgrounds.add_child(row)


func _custom_button_text(owned: bool, equipped: bool) -> String:
	if not owned:
		return "CUSTOM UPLOAD  — 10000 COINS"
	if not SaveManager.has_custom_background():
		return "CUSTOM UPLOAD  — UPLOAD IMAGE"
	if equipped:
		return "CUSTOM UPLOAD  — EQUIPPED"
	return "CUSTOM UPLOAD  — SELECT"


func _on_custom_pressed(price: int) -> void:
	if not SaveManager.owns_background("custom"):
		if not SaveManager.buy_background("custom", price):
			yen_label.text = "%d COINS — NOT ENOUGH" % SaveManager.coins
			return
		_refresh()
		_open_upload()
		return
	if not SaveManager.has_custom_background():
		_open_upload()
		return
	SaveManager.equipped_background = "custom"
	SaveManager.save()
	_refresh()


func _open_upload() -> void:
	_file_dialog.popup_centered_ratio(0.7)


func _on_custom_file_selected(path: String) -> void:
	if not SaveManager.set_custom_background_from_path(path):
		yen_label.text = "%d COINS — UPLOAD FAILED" % SaveManager.coins
		return
	yen_label.text = "%d COINS — CUSTOM SET" % SaveManager.coins
	_refresh()


func _buy(id: String, price: int) -> void:
	if not SaveManager.buy_background(id, price):
		yen_label.text = "%d COINS — NOT ENOUGH" % SaveManager.coins
		return
	_refresh()
