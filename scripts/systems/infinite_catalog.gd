extends RefCounted
## Builds infinite-mode level configs and difficulty ramps.

const PRESETS := [
	{"name": "BLUE ONLY", "red": false, "orange": false, "sliders": false, "slider_red": false},
	{"name": "RED BOMBS", "red": true, "orange": false, "sliders": false, "slider_red": false},
	{"name": "ORANGE MIX", "red": true, "orange": true, "sliders": false, "slider_red": false},
	{"name": "SLIDERS", "red": false, "orange": false, "sliders": true, "slider_red": false},
	{"name": "RED SLIDERS", "red": true, "orange": false, "sliders": true, "slider_red": true},
	{"name": "FULL MIX", "red": true, "orange": true, "sliders": true, "slider_red": true},
]


static func create(source: Dictionary, preset_index: int) -> Dictionary:
	var preset: Dictionary = PRESETS[clampi(preset_index, 0, PRESETS.size() - 1)]
	var red := bool(preset.red)
	var orange := bool(preset.orange)
	var sliders := bool(preset.sliders)
	var slider_red := bool(preset.slider_red) and sliders
	return {
		"id": 0,
		"world": int(source.get("world", 1)),
		"name": "INFINITE — %s" % source.name,
		"bpm": int(source.bpm),
		"hit_window_ms": float(source.hit_window_ms),
		"bomb_fuse": float(source.bomb_fuse),
		"allow_red": red,
		"allow_orange": orange,
		"allow_purple": false,
		"sliders": sliders,
		"slider_red": slider_red,
		"red_chance": 0.3 if red else 0.0,
		"orange_chance": 0.28 if orange else 0.0,
		"purple_chance": 0.0,
		"slider_chance": 0.4 if sliders else 0.0,
		"slider_red_chance": 0.35 if slider_red else 0.0,
		"clear_xp": 0,
		"hint": "Survive as long as you can",
		"music": str(source.music),
		"music_fallback": int(source.get("music_fallback", source.id)),
		"infinite": true,
		"track_id": int(source.id),
		"preset_index": preset_index,
		"preset_name": str(preset.name),
	}


static func ramp(base: Dictionary, elapsed: float) -> Dictionary:
	var level := base.duplicate()
	level.hit_window_ms = maxf(700.0, float(base.hit_window_ms) - elapsed * 6.0)
	level.bomb_fuse = maxf(1.4, float(base.bomb_fuse) - elapsed * 0.015)
	level.bpm = int(mini(220, int(base.bpm) + int(elapsed / 15.0) * 4))
	if level.sliders:
		level.slider_chance = minf(0.7, float(base.slider_chance) + elapsed * 0.002)
	return level
