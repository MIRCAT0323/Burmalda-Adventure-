extends Control

const MENU_SCENE := "res://main_menu.tscn"

var _title: Label
var _music_label: Label
var _sfx_label: Label
var _name_label: Label
var _counter: Label
var _saved_label: Label
var _lang_label: Label
var _name_edit: LineEdit
var _check: TextureButton
var _back: Button
var _reset: Button
var _saved_tween: Tween


func _ready() -> void:
	theme = UIStyle.make_theme()
	UIStyle.add_background(self)
	UIStyle.add_embers(self)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	_title = UIStyle.make_heading("", 54)
	box.add_child(_title)
	box.add_child(UIStyle.make_divider())
	box.add_child(_gap(0))

	# ---- Громкость музыки ----
	_music_label = UIStyle.make_section_label("")
	box.add_child(_music_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)

	var slider := RPGSlider.new()
	slider.set_value(GameSettings.music_volume, false)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)

	var percent := Label.new()
	percent.custom_minimum_size.x = 70
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.text = "%d%%" % roundi(slider.get_value() * 100.0)
	row.add_child(percent)

	slider.value_changed.connect(func(v: float):
		GameSettings.music_volume = v
		GameSettings.apply_settings()
		percent.text = "%d%%" % roundi(v * 100.0)
	)
	box.add_child(_gap(2))

	# ---- Громкость звуков ----
	_sfx_label = UIStyle.make_section_label("")
	box.add_child(_sfx_label)

	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 18)
	box.add_child(sfx_row)

	var sfx_slider := RPGSlider.new()
	sfx_slider.set_value(GameSettings.sfx_volume, false)
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sfx_row.add_child(sfx_slider)

	var sfx_percent := Label.new()
	sfx_percent.custom_minimum_size.x = 70
	sfx_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sfx_percent.text = "%d%%" % roundi(sfx_slider.get_value() * 100.0)
	sfx_row.add_child(sfx_percent)

	sfx_slider.value_changed.connect(func(v: float):
		GameSettings.sfx_volume = v
		sfx_percent.text = "%d%%" % roundi(v * 100.0)
	)
	box.add_child(_gap(2))

	# ---- Сменить имя ----
	var name_head := HBoxContainer.new()
	box.add_child(name_head)
	_name_label = UIStyle.make_section_label("")
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_head.add_child(_name_label)
	_counter = Label.new()
	_counter.add_theme_color_override("font_color", Color("c9b08a"))
	_counter.add_theme_font_size_override("font_size", 22)
	name_head.add_child(_counter)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	box.add_child(name_row)

	_name_edit = LineEdit.new()
	_name_edit.max_length = GameSettings.NAME_MAX
	_name_edit.text = GameSettings.player_name
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_edit.add_theme_font_size_override("font_size", 28)
	_name_edit.text_changed.connect(_on_name_changed)
	_name_edit.text_submitted.connect(func(_t: String): _save_name())
	name_row.add_child(_name_edit)

	_check = TextureButton.new()
	_check.texture_normal = UIStyle.icon("check_normal.png")
	_check.texture_hover = UIStyle.icon("check_hover.png")
	_check.texture_pressed = UIStyle.icon("check_pressed.png")
	_check.texture_disabled = UIStyle.icon("check_disabled.png")
	_check.ignore_texture_size = true
	_check.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_check.custom_minimum_size = Vector2(54, 54)
	_check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_check.pressed.connect(_save_name)
	name_row.add_child(_check)

	_saved_label = Label.new()
	_saved_label.custom_minimum_size = Vector2(0, 20)
	_saved_label.add_theme_font_size_override("font_size", 22)
	_saved_label.add_theme_color_override("font_color", Color("9be08a"))
	_saved_label.modulate.a = 0.0
	box.add_child(_saved_label)

	_on_name_changed(_name_edit.text)

	# ---- Язык ----
	_lang_label = UIStyle.make_section_label("")
	box.add_child(_lang_label)

	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 14)
	box.add_child(lang_row)

	var group := ButtonGroup.new()
	var ru := UIStyle.make_button("Русский", Vector2(0, 62))
	var en := UIStyle.make_button("English", Vector2(0, 62))
	for b in [ru, en]:
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lang_row.add_child(b)
	var selected := UIStyle.selected_box()
	for b in [ru, en]:
		b.add_theme_stylebox_override("pressed", selected)
		b.add_theme_stylebox_override("hover_pressed", selected)
	ru.text = "РУССКИЙ"
	en.text = "ENGLISH"
	ru.icon = UIStyle.flag("ru")
	en.icon = UIStyle.flag("en")
	ru.set_pressed_no_signal(GameSettings.language == "ru")
	en.set_pressed_no_signal(GameSettings.language == "en")
	ru.pressed.connect(func(): _set_language("ru"))
	en.pressed.connect(func(): _set_language("en"))

	box.add_child(_gap(0))

	# ---- Назад и сброс прогресса ----
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	box.add_child(bottom)

	_back = UIStyle.make_button("", Vector2(0, 66), true)
	_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back.pressed.connect(_on_back)
	bottom.add_child(_back)

	_reset = UIStyle.make_button("", Vector2(0, 66))
	_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reset.add_theme_font_size_override("font_size", 26)
	_reset.add_theme_color_override("font_color", Color("ff9a86"))
	_reset.add_theme_color_override("font_hover_color", Color("ffb8a8"))
	_reset.pressed.connect(_on_reset_pressed)
	bottom.add_child(_reset)

	_refresh_texts()
	_animate_in(panel)


func _animate_in(panel: Control) -> void:
	panel.modulate.a = 0.0
	await get_tree().process_frame
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(0.94, 0.94)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _gap(h: int) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0, h)
	return g


# ---- имя ----
func _on_name_changed(new_text: String) -> void:
	_counter.text = "%d/%d" % [new_text.length(), GameSettings.NAME_MAX]
	# галочка активна, только когда есть что сохранять
	_check.disabled = new_text.strip_edges() == GameSettings.player_name.strip_edges()


func _save_name() -> void:
	var n := _name_edit.text.strip_edges().substr(0, GameSettings.NAME_MAX)
	_name_edit.text = n
	GameSettings.player_name = n
	GameSettings.save_settings()
	_name_edit.release_focus()
	_on_name_changed(n)
	_flash_saved()


func _flash_saved() -> void:
	_saved_label.text = GameSettings.t("saved")
	if _saved_tween != null and _saved_tween.is_valid():
		_saved_tween.kill()
	_saved_tween = create_tween()
	_saved_tween.tween_property(_saved_label, "modulate:a", 1.0, 0.2)
	_saved_tween.tween_interval(1.4)
	_saved_tween.tween_property(_saved_label, "modulate:a", 0.0, 0.5)


# ---- язык ----
func _set_language(code: String) -> void:
	GameSettings.language = code
	_refresh_texts()


func _refresh_texts() -> void:
	_title.text = GameSettings.t("settings").to_upper()
	_music_label.text = GameSettings.t("music")
	_sfx_label.text = GameSettings.t("sfx")
	_name_label.text = GameSettings.t("change_name")
	_lang_label.text = GameSettings.t("language")
	_name_edit.placeholder_text = GameSettings.t("name_placeholder")
	_back.text = GameSettings.t("back").to_upper()
	_reset.text = GameSettings.t("reset_progress").to_upper()
	if _saved_label.modulate.a > 0.0:
		_saved_label.text = GameSettings.t("saved")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()


# ---- сброс прогресса ----
func _on_reset_pressed() -> void:
	var d := ConfirmDialog.new()
	d.setup(GameSettings.t("reset_title"), GameSettings.t("reset_text"), GameSettings.t("reset_yes"), GameSettings.t("cancel"))
	d.confirmed.connect(_do_reset)
	add_child(d)


func _do_reset() -> void:
	GameData.reset_progress()          # герой, достижения, предметы, монеты
	GameSettings.reset_all()           # ник, язык, громкости
	Transition.go(MENU_SCENE)          # дальше «Играть» -> выбор персонажа


func _on_back() -> void:
	GameSettings.save_settings()
	Transition.go(MENU_SCENE)
