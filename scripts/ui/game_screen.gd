extends Control

@onready var arena: Node2D = $Arena
@onready var overlay: Control = $Overlay


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if SaveManager.play_mode == "infinite" and not SaveManager.pending_level.is_empty():
		arena.setup_level(SaveManager.pending_level)
	else:
		SaveManager.play_mode = "story"
		arena.setup(SaveManager.selected_level)
	arena.run_finished.connect(_on_finished)
	overlay.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_finished(_won: bool) -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.stop_music()
		if SaveManager.play_mode == "infinite":
			get_tree().change_scene_to_file("res://scenes/ui/infinite_select.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
