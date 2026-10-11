extends Control
## Ввод ника при первом нажатии «Играть» (если имя ещё не задано, в том числе в настройках).
## Дальше — выбор героя (если он не выбран) или карта мира.

const MENU_SCENE := "res://main_menu.tscn"
const CHARACTER_SCENE := "res://character_select.tscn"
const MAP_SCENE := "res://world_map.tscn"

var _edit: LineEdit
var _next: Button
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
	panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	box.add_child(UIStyle.make_heading(GameSettings.t("enter_name").to_upper(), 48))
	box.add_child(UIStyle.make_divider())

	_edit = LineEdit.new()
	_edit.max_length = GameSettings.NAME_MAX
	_edit.placeholder_text = GameSettings.t("name_placeholder")
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.custom_minimum_size = Vector2(0, 70)
	_edit.add_theme_font_size_override("font_size", 32)
	_edit.text_changed.connect(_on_text_changed)
	_edit.text_submitted.connect(func(_t: String): _confirm())
	box.add_child(_edit)

	_next = UIStyle.make_button(GameSettings.t("next"), Vector2(0, 70))
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next.custom_minimum_size = Vector2(360, 70)
	_next.disabled = true
	_next.pressed.connect(_confirm)
	box.add_child(_next)

	var back := UIStyle.make_button(GameSettings.t("back"), Vector2(180, 60), true)
	back.pressed.connect(_on_back)
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)

	UIStyle.appear(panel, 0.1, 0.45)
	_edit.grab_focus.call_deferred()


func _on_text_changed(t: String) -> void:
	_next.disabled = t.strip_edges() == ""


func _confirm() -> void:
	var n := _edit.text.strip_edges()
	if _busy or n == "":
		return
	_busy = true
	GameSettings.player_name = n.substr(0, GameSettings.NAME_MAX)
	GameSettings.save_settings()
	Transition.go(MAP_SCENE if GameData.has_character() else CHARACTER_SCENE)


func _on_back() -> void:
	if _busy:
		return
	_busy = true
	Transition.go(MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
