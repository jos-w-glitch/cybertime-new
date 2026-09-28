extends Control

@onready var title: Label = $Center/VBox/Title
@onready var subtitle: Label = $Center/VBox/Subtitle
@onready var stats: Label = $Center/VBox/Stats
@onready var play_btn: Button = $Center/VBox/Play
@onready var infinite_btn: Button = $Center/VBox/Infinite
@onready var shop_btn: Button = $Center/VBox/Shop
@onready var how_btn: Button = $Center/VBox/HowTo
@onready var mobile_btn: Button = $Center/VBox/Mobile
@onready var home_btn: Button = $Home
@onready var how_panel: PanelContainer = $HowPanel

const SITE_HOME := "https://www.joseph-weiss.com/"


func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	_style_ui()
	_refresh_stats()
	_refresh_mobile_btn()
	_add_logo()
	_place_home_btn()
	play_btn.pressed.connect(_on_play)
	infinite_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/infinite_select.tscn")
	)
	shop_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")
	)
	how_btn.pressed.connect(func() -> void: how_panel.visible = not how_panel.visible)
	mobile_btn.pressed.connect(_toggle_mobile)
	home_btn.pressed.connect(_go_home)
	$HowPanel/Margin/VBox/Close.pressed.connect(func() -> void: how_panel.visible = false)
	AudioManager.play_menu_music()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _place_home_btn() -> void:
	home_btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	home_btn.text = "HOME"
	home_btn.top_level = true
	home_btn.position = Vector2(16, 16)
	home_btn.size = Vector2(100, 40)
	home_btn.z_index = 100
	home_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	move_child(home_btn, get_child_count() - 1)


func _go_home() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href='/'")
		return
	OS.shell_open(SITE_HOME)


func _toggle_mobile() -> void:
	SaveManager.set_mobile_mode(not SaveManager.mobile_mode)
	_refresh_mobile_btn()


func _refresh_mobile_btn() -> void:
	mobile_btn.text = "MOBILE: ON" if SaveManager.mobile_mode else "MOBILE: OFF"


func _add_logo() -> void:
	var tex := _load_logo_texture()
	if tex == null:
		return
	var logo := TextureRect.new()
	logo.texture = tex
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(180, 90)
	$Center/VBox.add_child(logo)
	$Center/VBox.move_child(logo, 0)


func _load_logo_texture() -> Texture2D:
	const PATH := "res://assets/ui/logo.png"
	if ResourceLoader.exists(PATH):
		var loaded: Variant = load(PATH)
		if loaded is Texture2D:
			return loaded
	var img := Image.new()
	if img.load(PATH) != OK:
		return null
	return ImageTexture.create_from_image(img)


func _refresh_stats() -> void:
	stats.text = "LV %d  ·  %d XP  ·  %d COINS" % [
		SaveManager.player_level(), SaveManager.xp, SaveManager.coins
	]


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/world_select.tscn")


func _style_ui() -> void:
	var font: Font = ArcadeFonts.get_font()
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", LevelData.COLORS.text)
	subtitle.add_theme_font_override("font", font)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", LevelData.COLORS.gray)
	subtitle.text = "HIT ON THE BEAT"
	stats.add_theme_font_override("font", font)
	stats.add_theme_color_override("font_color", LevelData.COLORS.gold)
	for btn: Button in [play_btn, infinite_btn, shop_btn, how_btn, mobile_btn, $HowPanel/Margin/VBox/Close]:
		btn.add_theme_font_override("font", font)
		btn.add_theme_font_size_override("font_size", 28)
	home_btn.add_theme_font_override("font", font)
	home_btn.add_theme_font_size_override("font_size", 16)
	home_btn.add_theme_color_override("font_color", LevelData.COLORS.text)
