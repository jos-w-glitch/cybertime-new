class_name TouchDropdown
extends VBoxContainer
## Phone-safe dropdown: a button + scrollable option list (no PopupMenu).

signal item_selected(index: int)
signal opened

var selected: int = 0
var _labels: PackedStringArray = PackedStringArray()
var _ids: Array[int] = []
var _open := false
var _font: Font
var _toggle: Button
var _list: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
	_font = ArcadeFonts.get_font()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	custom_minimum_size = Vector2(420, 56)
	add_theme_constant_override("separation", 6)
	_build_chrome()
	_refresh_toggle()
	close()


func clear() -> void:
	_labels = PackedStringArray()
	_ids.clear()
	selected = 0
	_rebuild_options()
	_refresh_toggle()


func add_item(label: String, id: int = -1) -> void:
	_labels.append(label)
	_ids.append(id if id >= 0 else _labels.size() - 1)
	_rebuild_options()
	_refresh_toggle()


func select(index: int) -> void:
	if _labels.is_empty():
		selected = 0
		_refresh_toggle()
		return
	selected = clampi(index, 0, _labels.size() - 1)
	_refresh_toggle()
	_highlight_options()


func get_item_id(index: int) -> int:
	if index < 0 or index >= _ids.size():
		return -1
	return _ids[index]


func is_open() -> bool:
	return _open


func close() -> void:
	_open = false
	if _scroll != null:
		_scroll.visible = false
	_refresh_toggle()


func set_dropdown_font(font: Font, size: int = 24) -> void:
	_font = font
	if _toggle == null:
		return
	_toggle.add_theme_font_override("font", font)
	_toggle.add_theme_font_size_override("font_size", size)
	for child in _list.get_children():
		if child is Button:
			child.add_theme_font_override("font", font)
			child.add_theme_font_size_override("font_size", size)


func _build_chrome() -> void:
	_toggle = Button.new()
	_toggle.custom_minimum_size = Vector2(420, 56)
	_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toggle.pressed.connect(_toggle_open)
	if _font != null:
		_toggle.add_theme_font_override("font", _font)
		_toggle.add_theme_font_size_override("font_size", 24)
	add_child(_toggle)

	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(420, 220)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.visible = false
	add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_list)


func _toggle_open() -> void:
	if _open:
		close()
	else:
		_open_list()


func _open_list() -> void:
	_open = true
	_scroll.visible = true
	_refresh_toggle()
	_highlight_options()
	opened.emit()


func _rebuild_options() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	for i in _labels.size():
		var btn := Button.new()
		btn.text = _labels[i]
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _font != null:
			btn.add_theme_font_override("font", _font)
			btn.add_theme_font_size_override("font_size", 22)
		var idx := i
		btn.pressed.connect(func() -> void: _pick(idx))
		_list.add_child(btn)


func _pick(index: int) -> void:
	select(index)
	close()
	item_selected.emit(selected)


func _refresh_toggle() -> void:
	if _toggle == null:
		return
	if _labels.is_empty():
		_toggle.text = "—"
		return
	var arrow := " ▲" if _open else " ▼"
	_toggle.text = _labels[selected] + arrow


func _highlight_options() -> void:
	if _list == null:
		return
	for i in _list.get_child_count():
		var btn := _list.get_child(i) as Button
		if btn == null:
			continue
		var on := i == selected
		btn.add_theme_color_override(
			"font_color",
			LevelData.COLORS.gold if on else LevelData.COLORS.text
		)
