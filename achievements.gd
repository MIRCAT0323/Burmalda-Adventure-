extends Control
## Экран «Достижения».

const MENU_SCENE := "res://main_menu.tscn"

var _busy := false


func _ready() -> void:
	theme = UIStyle.make_theme()
	UIStyle.add_background(self)
	UIStyle.add_embers(self)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	box.add_child(UIStyle.make_heading(GameSettings.t("achievements").to_upper(), 54))
	box.add_child(UIStyle.make_divider())

	for id in GameData.ACHIEVEMENTS:
		box.add_child(_make_row(str(id)))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	box.add_child(gap)

	var back := UIStyle.make_button(GameSettings.t("back"), Vector2(420, 80), true)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_on_back)
	box.add_child(back)

	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)


func _make_row(id: String) -> Control:
	var data: Dictionary = GameData.ACHIEVEMENTS[id]
	var got := GameData.is_unlocked(id)

	var row := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.045, 0.03, 0.85)
	sb.border_color = UIStyle.AMBER if got else Color(0.40, 0.38, 0.42)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	row.add_theme_stylebox_override("panel", sb)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	row.add_child(h)

	var icon := TextureRect.new()
	icon.texture = GameData.tex(str(data.get("icon", "")))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(72, 72)
	icon.modulate = Color.WHITE if got else Color(0.35, 0.35, 0.38, 0.9)
	h.add_child(icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 2)
	h.add_child(col)

	var title := Label.new()
	title.text = GameData.loc(data["title"])
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", UIStyle.AMBER_LIGHT if got else Color(0.62, 0.60, 0.58))
	col.add_child(title)

	var desc := Label.new()
	desc.text = GameData.loc(data["desc"])
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62, 0.9))
	col.add_child(desc)

	var status := Label.new()
	status.text = GameSettings.t("ach_unlocked") if got else GameSettings.t("ach_locked")
	status.add_theme_font_size_override("font_size", 22)
	status.add_theme_color_override("font_color", Color("9be08a") if got else Color(0.62, 0.60, 0.58))
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(status)
	return row


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()


func _on_back() -> void:
	if _busy:
		return
	_busy = true
	Transition.go(MENU_SCENE)
