class_name PauseButton
extends Control
## Круглая кнопка паузы (деревянная, без заклёпок) с двумя палочками.

signal pressed

const D := 54.0

var _hover := false
var _down := false
var _tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(D, D)
	size = Vector2(D, D)
	pivot_offset = Vector2(D, D) / 2.0
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))


func _has_point(point: Vector2) -> bool:
	return point.distance_to(Vector2(D, D) / 2.0) <= D / 2.0


func _set_hover(on: bool) -> void:
	_hover = on
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var sc := 1.07 if on else 1.0
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", Vector2(sc, sc), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "self_modulate", Color(1.2, 1.12, 1.03) if on else Color.WHITE, 0.14)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_down = event.pressed
		queue_redraw()
		if event.pressed:
			pressed.emit()
		accept_event()


func _draw() -> void:
	var c := Vector2(D, D) / 2.0
	var wood := "btn_pressed.png" if _down else ("btn_hover.png" if _hover else "btn_normal.png")
	UIStyle.draw_round_button(self, c, D / 2.0, wood)
	var bw := 6.0
	var bh := 20.0
	var gap := 6.0
	var o := Vector2(0, 1.0 if _down else 0.0)
	for x in [c.x - gap / 2.0 - bw, c.x + gap / 2.0]:
		var r := Rect2(Vector2(x, c.y - bh / 2.0) + o, Vector2(bw, bh))
		draw_rect(r.grow(1.5), Color(0.06, 0.03, 0.02))   # тёмный контур
		draw_rect(r, UIStyle.CREAM)
