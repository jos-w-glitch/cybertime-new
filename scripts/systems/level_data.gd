extends Node

const Catalog := preload("res://scripts/systems/world_catalog.gd")
const STAGE_TIME := 30.0
const START_HEARTS := 5
const SAFE_ZONE_BORDER := 25.0
const GRACE_SECONDS := 1.5
const MUSIC_FADE_SECONDS := 5.0
const ORANGE_CONFIRM_MS := 2200.0
const SLIDER_ZONE := 70.0

const COLORS := {
	"bg": Color(10 / 255.0, 10 / 255.0, 18 / 255.0),
	"grid": Color(25 / 255.0, 20 / 255.0, 45 / 255.0),
	"text": Color(0.0, 1.0, 200 / 255.0),
	"gray": Color(60 / 255.0, 60 / 255.0, 75 / 255.0),
	"blue": Color(0.0, 180 / 255.0, 1.0),
	"red": Color(1.0, 0.0, 100 / 255.0),
	"orange": Color(1.0, 140 / 255.0, 0.0),
	"green": Color(50 / 255.0, 1.0, 100 / 255.0),
	"gold": Color(1.0, 210 / 255.0, 60 / 255.0),
	"purple": Color(180 / 255.0, 80 / 255.0, 1.0),
	"magenta": Color(1.0, 0.1, 0.65),
	"cyan": Color(0.0, 1.0, 200 / 255.0),
}

const SHOP_BACKGROUNDS := [
	{"id": "cyber", "name": "CYBER GRID", "price": 0, "bg": Color(10 / 255.0, 10 / 255.0, 18 / 255.0), "grid": Color(25 / 255.0, 20 / 255.0, 45 / 255.0), "accent": Color(0, 1.0, 200 / 255.0)},
	{"id": "matrix", "name": "MATRIX", "price": 350, "bg": Color(4 / 255.0, 12 / 255.0, 6 / 255.0), "grid": Color(10 / 255.0, 40 / 255.0, 15 / 255.0), "accent": Color(50 / 255.0, 1.0, 100 / 255.0)},
	{"id": "sunset", "name": "SUNSET", "price": 550, "bg": Color(28 / 255.0, 8 / 255.0, 32 / 255.0), "grid": Color(80 / 255.0, 30 / 255.0, 60 / 255.0), "accent": Color(1.0, 120 / 255.0, 40 / 255.0)},
	{"id": "space", "name": "DEEP SPACE", "price": 800, "bg": Color(5 / 255.0, 5 / 255.0, 20 / 255.0), "grid": Color(30 / 255.0, 30 / 255.0, 80 / 255.0), "accent": Color(120 / 255.0, 140 / 255.0, 1.0)},
	{"id": "retro", "name": "RETRO WAVE", "price": 1200, "bg": Color(15 / 255.0, 5 / 255.0, 35 / 255.0), "grid": Color(100 / 255.0, 20 / 255.0, 120 / 255.0), "accent": Color(1.0, 0, 180 / 255.0)},
	{"id": "custom", "name": "CUSTOM UPLOAD", "price": 10000, "custom": true, "bg": Color(8 / 255.0, 8 / 255.0, 12 / 255.0), "grid": Color(40 / 255.0, 40 / 255.0, 55 / 255.0), "accent": Color(1.0, 210 / 255.0, 60 / 255.0)},
]

var worlds: Array[Dictionary] = []
var levels: Array[Dictionary] = []


func _ready() -> void:
	worlds = Catalog.worlds()
	levels = []
	levels.append_array(Catalog.world1_levels())
	levels.append_array(Catalog.world2_levels())


func get_world(world_id: int) -> Dictionary:
	for world in worlds:
		if int(world.id) == world_id:
			return world
	return {}


func get_level(level_id: int) -> Dictionary:
	for level in levels:
		if int(level.id) == level_id:
			return level
	return {}


func levels_for_world(world_id: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for level in levels:
		if int(level.world) == world_id:
			out.append(level)
	return out


func is_world_unlocked(_world_id: int, _cleared: Array) -> bool:
	return true


func is_unlocked(level_id: int, _cleared: Array) -> bool:
	return not get_level(level_id).is_empty()


func next_level_id(level_id: int) -> int:
	var level := get_level(level_id)
	if level.is_empty():
		return -1
	var stages := levels_for_world(int(level.world))
	for i in stages.size():
		if int(stages[i].id) == level_id and i + 1 < stages.size():
			return int(stages[i + 1].id)
	return -1


func resolve_music(level: Dictionary) -> String:
	var primary := str(level.get("music", ""))
	if primary != "" and ResourceLoader.exists(primary):
		return primary
	var fallback_id := int(level.get("music_fallback", level.get("id", 1)))
	var world := int(level.get("world", 1))
	if world == 2:
		var w2 := "res://assets/music/world2/%d.mp3" % clampi(fallback_id, 1, 7)
		if ResourceLoader.exists(w2):
			return w2
	var fallback := "res://assets/music/%d.mp3" % clampi(fallback_id, 1, 12)
	if ResourceLoader.exists(fallback):
		return fallback
	return "res://assets/music/menu.mp3"


func arena_theme(level: Dictionary, shop_theme: Dictionary) -> Dictionary:
	if str(shop_theme.get("id", "")) == "custom" and shop_theme.get("image") != null:
		return shop_theme
	var world := get_world(int(level.get("world", 1)))
	if world.is_empty() or not world.has("arena"):
		return shop_theme
	var arena: Dictionary = world.arena
	return {
		"bg": arena.get("bg", shop_theme.get("bg", COLORS.bg)),
		"grid": arena.get("grid", shop_theme.get("grid", COLORS.grid)),
		"accent": arena.get("accent", shop_theme.get("accent", COLORS.text)),
	}


func xp_for_level(player_level: int) -> int:
	return int(floor(100.0 * pow(float(player_level), 1.5)))
