extends Control

@onready var title: Label = $Center/VBox/Title
@onready var subtitle: Label = $Center/VBox/Subtitle
@onready var stats: Label = $Center/VBox/Stats
@onready var play_btn: Button = $Center/VBox/Play
@onready var infinite_btn: Button = $Center/VBox/Infinite
@onready var shop_btn: Button = $Center/VBox/Shop
@onready var how_btn: Button = $Center/VBox/HowTo
@onready var mobile_btn: Button = $Center/VBox/Mobile
@onready var fullscreen_btn: Button = $Fullscreen
@onready var home_btn: Button = $Home
@onready var how_panel: PanelContainer = $HowPanel

const SITE_HOME := "https://www.joseph-weiss.com/"


func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	_style_ui()
	_refresh_stats()
	_refresh_mobile_btn()
	_refresh_fullscreen_btn()
	_add_logo()
	_place_corner_btns()
	play_btn.pressed.connect(_on_play)
	infinite_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/infinite_select.tscn")
	)
	shop_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/shop.tscn")
	)
	how_btn.pressed.connect(func() -> void: how_panel.visible = not how_panel.visible)
	mobile_btn.pressed.connect(_toggle_mobile)
	fullscreen_btn.pressed.connect(_toggle_fullscreen)
	home_btn.pressed.connect(_go_home)
	$HowPanel/Margin/VBox/Close.pressed.connect(func() -> void: how_panel.visible = false)
	get_viewport().size_changed.connect(_place_corner_btns)
	AudioManager.play_menu_music()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _place_corner_btns() -> void:
	_place_corner_btn(home_btn, "HOME", true)
	_place_corner_btn(fullscreen_btn, "FULL", false)


func _place_corner_btn(btn: Button, label: String, left: bool) -> void:
	btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
	btn.text = label
	btn.top_level = true
	btn.size = Vector2(100, 40)
	btn.z_index = 100
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var x := 16.0 if left else maxf(16.0, get_viewport_rect().size.x - btn.size.x - 16.0)
	btn.position = Vector2(x, 16)
	move_child(btn, get_child_count() - 1)


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


func _toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.cybertimeToggleFullscreen && window.cybertimeToggleFullscreen()")
		_refresh_fullscreen_btn()
		return
	var win := get_window()
	if win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
	else:
		win.mode = Window.MODE_FULLSCREEN
	_refresh_fullscreen_btn()


func _refresh_fullscreen_btn() -> void:
	fullscreen_btn.text = "FULL"


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
	for corner: Button in [home_btn, fullscreen_btn]:
		corner.add_theme_font_override("font", font)
		corner.add_theme_font_size_override("font_size", 16)
		corner.add_theme_color_override("font_color", LevelData.COLORS.text)
