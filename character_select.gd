extends Control
## Выбор героя (показывается, пока герой не выбран).

const MENU_SCENE := "res://main_menu.tscn"
const MAP_SCENE := "res://world_map.tscn"
const CIRCLE_SIZE := 180.0

var _busy := false


func _ready() -> void:
	theme = UIStyle.make_theme()
	UIStyle.add_background(self)
	UIStyle.add_embers(self)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 30)
	center.add_child(column)

	var title := UIStyle.make_heading(GameSettings.t("choose_character").to_upper(), 58)
	column.add_child(title)
	column.add_child(UIStyle.make_divider())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)

	var i := 0
	for ch in GameData.CHARACTERS:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 14)
		row.add_child(box)

		var slot := CircleSlot.new()
		slot.setup(GameData.tex(str(ch["image"])), CIRCLE_SIZE, str(i + 1))
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.pressed.connect(_choose.bind(i))
		box.add_child(slot)

		var name_label := Label.new()
		name_label.text = str(ch["name"])
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 26)
		name_label.add_theme_color_override("font_color", UIStyle.CREAM)
		name_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 1.0))
		name_label.add_theme_constant_override("outline_size", 7)
		box.add_child(name_label)

		UIStyle.appear(box, 0.25 + 0.09 * i, 0.5)
		i += 1

	# кнопка «Назад» сверху слева
	var back := UIStyle.make_button(GameSettings.t("back"), Vector2(180, 60), true)
	back.pressed.connect(_on_back)
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)


func _choose(index: int) -> void:
	if _busy:
		return
	_busy = true
	GameData.select_character(index)
	Transition.go(MAP_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()


func _on_back() -> void:
	if _busy:
		return
	_busy = true
	Transition.go(MENU_SCENE)
