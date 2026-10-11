class_name ConfirmDialog
extends Control
## Окно подтверждения («Да» / «Отмена») в стиле меню.
## Использование:
##   var d := ConfirmDialog.new()
##   d.setup("Заголовок", "Текст", "Да", "Отмена")
##   d.confirmed.connect(...)
##   add_child(d)

signal confirmed
signal cancelled

var _title := ""
var _text := ""
var _yes := ""
var _no := ""
var _panel: Control
var _closing := false


func setup(title: String, text: String, yes: String, no: String) -> void:
	_title = title
	_text = text
	_yes = yes
	_no = no


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(700, 0)
	center.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_panel.add_child(box)

	box.add_child(UIStyle.make_heading(_title.to_upper(), 44))
	box.add_child(UIStyle.make_divider())

	var msg := Label.new()
	msg.text = _text
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.custom_minimum_size = Vector2(560, 0)
	msg.add_theme_font_size_override("font_size", 26)
	box.add_child(msg)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var yes := UIStyle.make_button(_yes, Vector2(0, 72))
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.add_theme_font_size_override("font_size", 26)
	yes.add_theme_color_override("font_color", Color("ff9a86"))
	yes.add_theme_color_override("font_hover_color", Color("ffb8a8"))
	yes.pressed.connect(func(): _finish(true))
	row.add_child(yes)

	var no := UIStyle.make_button(_no, Vector2(0, 72))
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.add_theme_font_size_override("font_size", 26)
	no.pressed.connect(func(): _finish(false))
	row.add_child(no)

	_animate_in()


func _animate_in() -> void:
	modulate.a = 0.0
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.94, 0.94)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _finish(ok: bool) -> void:
	if _closing:
		return
	_closing = true
	if ok:
		confirmed.emit()
	else:
		cancelled.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_finish(false)
		get_viewport().set_input_as_handled()
