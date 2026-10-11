class_name LevelNode
extends Control
## Кружок уровня на карте локации: номер, звёзды, состояние (закрыт / доступен / текущий).

signal pressed

const R := 30.0
const W := 84.0
const H := 94.0

var level := 1
var stars := 0
var locked := true
var current := false   # следующий уровень, который нужно пройти (мягко пульсирует)
var _hover := false
var _pulse := 0.0
var _tween: Tween


func setup(lvl: int) -> void:
	level = lvl
	custom_minimum_size = Vector2(W, H)
	size = custom_minimum_size
	pivot_offset = Vector2(W / 2.0, R + 4.0)


func set_state(star_count: int, is_locked: bool, is_current: bool) -> void:
	stars = star_count
	locked = is_locked
	current = is_current
	mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND
	set_process(current)
	queue_redraw()


func _ready() -> void:
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))


func _center() -> Vector2:
	return Vector2(W / 2.0, R + 4.0)


func _has_point(point: Vector2) -> bool:
	return point.distance_to(_center()) <= R


func _process(delta: float) -> void:
	_pulse += delta * 3.0
	queue_redraw()


func _set_hover(on: bool) -> void:
	_hover = on
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var lit := on and not locked
	var s := 1.1 if lit else 1.0
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", Vector2(s, s), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "self_modulate", Color(1.2, 1.12, 1.03) if lit else Color.WHITE, 0.14)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _draw() -> void:
	var c := _center()
	if current:
		var glow := 0.18 + 0.14 * (0.5 + 0.5 * sin(_pulse))
		draw_circle(c, R + 10.0, Color(1.0, 0.72, 0.25, glow))
	elif _hover and not locked:
		draw_circle(c, R + 8.0, Color(1.0, 0.72, 0.25, 0.2))

	var ring := Color("6b6d78")          # железное кольцо (как у кнопки паузы)
	var tint := Color.WHITE
	var txt := UIStyle.CREAM
	if locked:
		ring = Color("3d3c42")
		tint = Color(0.42, 0.40, 0.40)
		txt = Color(0.62, 0.58, 0.55, 0.85)
	elif current:
		ring = UIStyle.AMBER_LIGHT
		txt = Color("fff3d6")
	UIStyle.draw_round_button(self, c, R, "btn_hover.png" if (_hover and not locked) else "btn_normal.png", ring, tint)

	var font := get_theme_default_font()
	var fs := 27 if level < 100 else 22
	var base := Vector2(0.0, c.y + fs * 0.35)
	draw_string_outline(font, base, str(level), HORIZONTAL_ALIGNMENT_CENTER, W, fs, 6, Color(0.06, 0.03, 0.02, 1.0))
	draw_string(font, base, str(level), HORIZONTAL_ALIGNMENT_CENTER, W, fs, txt)

	StarRow.draw_row(self, Vector2(W / 2.0, 2.0 * R + 19.0), stars, 9.0, 3.0)
