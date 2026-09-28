extends Node

const SAVE_PATH := "user://cybertime_save.json"
const CUSTOM_BG_PATH := "user://custom_background.png"

var coins: int = 100
var xp: int = 0
var high_scores: Dictionary = {}
var cleared_levels: Array = []
var selected_level: int = 1
var selected_world: int = 1
var play_mode: String = "story"
var pending_level: Dictionary = {}
var infinite_track_index: int = 0
var infinite_preset_index: int = 5
var infinite_high_score: int = 0
var last_run: Dictionary = {}
var owned_skins: Array = ["default"]
var owned_backgrounds: Array = ["cyber"]
var equipped_skin: String = "default"
var equipped_background: String = "cyber"
var mobile_mode: bool = false
var custom_bg_texture: Texture2D = null

var yen: int:
	get:
		return coins
	set(value):
		coins = value


func _ready() -> void:
	load_save()
	_load_custom_background()
	_auto_enable_mobile_if_needed()
	# Keep infinite coins for testing without wiping progress
	if coins < 999999:
		coins = 999999
	save()


func _auto_enable_mobile_if_needed() -> void:
	# Phones/tablets should use tap rules without hunting for the setting.
	if mobile_mode:
		return
	if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile"):
		mobile_mode = true
		save()


func player_level() -> int:
	var level := 1
	while xp >= LevelData.xp_for_level(level):
		level += 1
	return level


func is_level_cleared(level_id: int) -> bool:
	var id := int(level_id)
	for value in cleared_levels:
		if int(value) == id:
			return true
	return false


func best_score(level_id: int) -> int:
	return int(high_scores.get(str(level_id), 0))


func infinite_best_score() -> int:
	return infinite_high_score


func begin_infinite(source: Dictionary, preset_index: int) -> void:
	var Catalog := preload("res://scripts/systems/infinite_catalog.gd")
	play_mode = "infinite"
	pending_level = Catalog.create(source, preset_index)
	selected_level = 0
	selected_world = int(source.get("world", 1))
	save()


func clear_play_mode() -> void:
	play_mode = "story"
	pending_level = {}


func current_theme() -> Dictionary:
	for bg in LevelData.SHOP_BACKGROUNDS:
		if str(bg.id) != equipped_background:
			continue
		var theme: Dictionary = bg.duplicate()
		if str(bg.id) == "custom" and custom_bg_texture != null:
			theme["image"] = custom_bg_texture
		return theme
	return LevelData.SHOP_BACKGROUNDS[0]


func has_custom_background() -> bool:
	return custom_bg_texture != null


func set_custom_background_from_path(path: String) -> bool:
	var img := Image.new()
	if img.load(path) != OK:
		return false
	return _commit_custom_background(img)


func set_custom_background_from_bytes(bytes: PackedByteArray) -> bool:
	var img := Image.new()
	if img.load_png_from_buffer(bytes) != OK \
		and img.load_jpg_from_buffer(bytes) != OK \
		and img.load_webp_from_buffer(bytes) != OK:
		return false
	return _commit_custom_background(img)


func _commit_custom_background(img: Image) -> bool:
	img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	if img.save_png(CUSTOM_BG_PATH) != OK:
		return false
	custom_bg_texture = ImageTexture.create_from_image(img)
	if not owns_background("custom"):
		owned_backgrounds.append("custom")
	equipped_background = "custom"
	save()
	return true


func _load_custom_background() -> void:
	if not FileAccess.file_exists(CUSTOM_BG_PATH):
		custom_bg_texture = null
		return
	var img := Image.new()
	if img.load(CUSTOM_BG_PATH) != OK:
		custom_bg_texture = null
		return
	custom_bg_texture = ImageTexture.create_from_image(img)


func owns_background(id: String) -> bool:
	return owned_backgrounds.has(id)


func buy_background(id: String, price: int) -> bool:
	if owns_background(id):
		equipped_background = id
		save()
		return true
	if coins < price:
		return false
	coins -= price
	owned_backgrounds.append(id)
	equipped_background = id
	save()
	return true


func apply_run_rewards(score: int, combo_peak: int, level_id: int, won: bool) -> Dictionary:
	var xp_gain := score * 2 + combo_peak * 5
	var coin_gain := 0
	var id := int(level_id)
	var is_infinite := play_mode == "infinite" or bool(pending_level.get("infinite", false))
	if is_infinite:
		coin_gain = maxi(0, int(floor(float(score) / 8.0))) + 2
		xp_gain += int(floor(float(score) / 2.0))
		if score > infinite_high_score:
			infinite_high_score = score
	elif won:
		var level := LevelData.get_level(level_id)
		xp_gain += int(level.get("clear_xp", 0))
		coin_gain = int(floor(float(score) / 4.0)) + 3
		if not is_level_cleared(id):
			cleared_levels.append(id)
			coin_gain += 15
	else:
		coin_gain = maxi(0, int(floor(float(score) / 15.0)))

	xp += xp_gain
	coins += coin_gain
	if not is_infinite and score > best_score(id):
		high_scores[str(id)] = int(score)

	last_run = {
		"score": score,
		"combo_peak": combo_peak,
		"level_id": id,
		"won": won,
		"xp_gain": xp_gain,
		"coin_gain": coin_gain,
		"infinite": is_infinite,
		"survived": last_run.get("survived", 0.0),
	}
	save()
	return last_run


func save() -> void:
	_normalize_progress()
	var data := {
		"coins": coins,
		"xp": xp,
		"high_scores": high_scores,
		"cleared_levels": cleared_levels,
		"owned_skins": owned_skins,
		"owned_backgrounds": owned_backgrounds,
		"equipped_skin": equipped_skin,
		"equipped_background": equipped_background,
		"mobile_mode": mobile_mode,
		"infinite_high_score": infinite_high_score,
		"infinite_track_index": infinite_track_index,
		"infinite_preset_index": infinite_preset_index,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("CyberTime: could not save to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data))


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	coins = int(data.get("coins", data.get("yen", 100)))
	xp = int(data.get("xp", 0))
	high_scores = data.get("high_scores", {})
	cleared_levels = data.get("cleared_levels", [])
	owned_skins = data.get("owned_skins", ["default"])
	owned_backgrounds = data.get("owned_backgrounds", ["cyber"])
	equipped_skin = str(data.get("equipped_skin", "default"))
	equipped_background = str(data.get("equipped_background", "cyber"))
	mobile_mode = bool(data.get("mobile_mode", false))
	infinite_high_score = int(data.get("infinite_high_score", 0))
	infinite_track_index = int(data.get("infinite_track_index", 0))
	infinite_preset_index = int(data.get("infinite_preset_index", 5))
	if equipped_background == "neo_tokyo":
		equipped_background = "cyber"
	if owned_backgrounds.has("neo_tokyo") and not owned_backgrounds.has("cyber"):
		owned_backgrounds.append("cyber")
	_normalize_progress()


func _normalize_progress() -> void:
	# JSON turns ints into floats — that breaks Array.has(1) vs 1.0
	var unique: Dictionary = {}
	for value in cleared_levels:
		unique[int(value)] = true
	cleared_levels = unique.keys()
	cleared_levels.sort()
	var scores := {}
	for key in high_scores.keys():
		scores[str(int(str(key)))] = int(high_scores[key])
	high_scores = scores


func set_mobile_mode(enabled: bool) -> void:
	mobile_mode = enabled
	save()
