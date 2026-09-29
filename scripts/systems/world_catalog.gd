extends RefCounted


static func worlds() -> Array[Dictionary]:
	return [
		{
			"id": 1,
			"name": "CYBER GRID",
			"tagline": "Original neon stages",
			"last_level_id": 12,
			"accent": Color(0.0, 1.0, 0.78),
			"arena": {
				"bg": Color(10 / 255.0, 10 / 255.0, 18 / 255.0),
				"grid": Color(25 / 255.0, 20 / 255.0, 45 / 255.0),
				"accent": Color(0.0, 1.0, 0.78),
			},
		},
		{
			"id": 2,
			"name": "HEXCORE",
			"tagline": "Arcane-inspired undercity",
			"last_level_id": 19,
			"accent": Color(0.95, 0.72, 0.28),
			"arena": {
				"bg": Color(18 / 255.0, 10 / 255.0, 22 / 255.0),
				"grid": Color(48 / 255.0, 22 / 255.0, 58 / 255.0),
				"accent": Color(0.95, 0.72, 0.28),
			},
		},
	]


static func world1_levels() -> Array[Dictionary]:
	return [
		_lvl(1, 1, "NEON START", 72, 2800, 5.0, false, false, false, false, 0, 0, 0, 0, 60, "Blue balls only", 1),
		_lvl(2, 1, "WARM PULSE", 84, 2500, 4.5, false, false, false, false, 0, 0, 0, 0, 80, "Faster blues", 2),
		_lvl(3, 1, "RED ALERT", 96, 2200, 4.0, true, false, false, false, 0.25, 0, 0, 0, 95, "Right-click red bombs", 3),
		_lvl(4, 1, "PULSE DRIVE", 104, 2000, 3.8, true, false, false, false, 0.38, 0, 0, 0, 110, "More red bombs", 4),
		_lvl(5, 1, "ORANGE GLINT", 112, 1850, 3.5, true, true, false, false, 0.12, 0.25, 0, 0, 125, "Defuse then confirm", 5),
		_lvl(6, 1, "HYPER LOOP", 122, 1700, 3.2, true, true, false, false, 0.15, 0.35, 0, 0, 140, "Mixed bombs", 6),
		_lvl(7, 1, "OVERDRIVE", 128, 1550, 3.0, true, true, false, false, 0.2, 0.4, 0, 0, 155, "Faster mixed bombs", 7),
		_lvl(8, 1, "PRESSURE", 136, 1420, 2.9, true, true, false, false, 0.25, 0.45, 0, 0, 175, "Heavy orange pressure", 8),
		_lvl(9, 1, "SLIDE INTRO", 142, 1350, 2.8, false, false, true, false, 0, 0, 0.4, 0, 185, "Hit sliding targets anywhere", 9),
		_lvl(10, 1, "CHAOS CORE", 152, 1200, 2.6, false, false, true, false, 0, 0, 0.55, 0, 210, "Faster slides", 10),
		_lvl(11, 1, "RED SLIDE", 160, 1100, 2.4, false, false, true, true, 0, 0, 0.48, 0.3, 230, "Right-click red sliders", 11),
		_lvl(12, 1, "FINAL SYNC", 168, 900, 2.2, true, true, true, true, 0.15, 0.15, 0.55, 0.44, 280, "Everything", 12),
	]


static func world2_levels() -> Array[Dictionary]:
	# Original World 2 tracks in assets/music/world2/ (same play-from-0 start as World 1).
	return [
		_lvl(13, 2, "PILTOVER DAWN", 168, 900, 2.2, true, true, true, true, 0.15, 0.15, 0.55, 0.44, 300, "Upper: everything", 1),
		_lvl(14, 2, "BRIDGE LIGHTS", 172, 880, 2.15, true, true, true, true, 0.16, 0.16, 0.56, 0.44, 320, "Upper: everything", 2),
		_lvl(15, 2, "FIRELIGHT RUN", 176, 860, 2.1, true, true, true, true, 0.18, 0.18, 0.56, 0.45, 340, "Upper: everything", 3),
		_lvl(16, 2, "LANE RIOT", 180, 840, 2.05, true, true, true, true, 0.2, 0.2, 0.57, 0.45, 360, "Upper: everything", 4),
		_lvl(17, 2, "CHEM RAILS", 184, 820, 2.0, true, true, true, true, 0.22, 0.22, 0.58, 0.46, 380, "Upper: everything", 5),
		_lvl(18, 2, "SISTER SPARK", 188, 800, 1.95, true, true, true, true, 0.24, 0.24, 0.58, 0.46, 400, "Upper: everything", 6),
		_lvl(19, 2, "ENEMY PROTOCOL", 196, 760, 1.85, true, true, true, true, 0.28, 0.3, 0.62, 0.5, 450, "Upper finale", 7),
	]


static func _lvl(
	id: int, world: int, level_name: String, bpm: int, hit_ms: float, fuse: float,
	allow_red: bool, allow_orange: bool, sliders: bool, slider_red: bool,
	red_c: float, orange_c: float, slider_c: float, slider_red_c: float,
	clear_xp: int, hint: String, music_fallback: int
) -> Dictionary:
	var music := "res://assets/music/%d.mp3" % clampi(music_fallback, 1, 12)
	if world == 2:
		music = "res://assets/music/world2/%d.mp3" % clampi(music_fallback, 1, 7)
	return {
		"id": id,
		"world": world,
		"name": level_name,
		"bpm": bpm,
		"hit_window_ms": hit_ms,
		"bomb_fuse": fuse,
		"allow_red": allow_red,
		"allow_orange": allow_orange,
		"allow_purple": false,
		"sliders": sliders,
		"slider_red": slider_red,
		"red_chance": red_c,
		"orange_chance": orange_c,
		"purple_chance": 0.0,
		"slider_chance": slider_c,
		"slider_red_chance": slider_red_c,
		"clear_xp": clear_xp,
		"hint": hint,
		"music": music,
		"music_fallback": music_fallback,
	}
