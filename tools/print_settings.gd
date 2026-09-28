extends SceneTree

func _init() -> void:
	print("DATA_DIR=", OS.get_user_data_dir())
	print("EXEC=", OS.get_executable_path())
	var dir := DirAccess.open("user://")
	print("user open ok=", dir != null)
	# Print rendering settings
	print("method=", ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"))
	print("method.web=", ProjectSettings.get_setting("rendering/renderer/rendering_method.web", "?"))
	quit()
