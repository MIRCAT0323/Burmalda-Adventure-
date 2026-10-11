class_name RPGSlider
extends Control
## Простой ползунок громкости: тёмная полоса, золотая заливка и узкий маркер.
## Двигается плавно, на 100% заливка доходит до самого края.

signal value_changed(value: float)

const PAD := 8.0
const BAR_H := 14.0

var _value: float = 0.5
var _shown: float = 0.5   # то, что нарисовано (плавно догоняет _value)
var _dragging := false


func _init() -> void:
    custom_minimum_size = Vector2(0, 36)
    focus_mode = Control.FOCUS_ALL
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    set_process(false)


func get_value() -> float:
    return _value


func set_value(v: float, emit := true) -> void:
    v = clampf(v, 0.0, 1.0)
    if v == _value:
        return
    _value = v
    if emit:
        value_changed.emit(_value)
        set_process(true)
    else:
        _shown = v
        queue_redraw()


func _process(delta: float) -> void:
    _shown = lerpf(_shown, _value, 1.0 - exp(-18.0 * delta))
    if absf(_shown - _value) < 0.0005:
        _shown = _value
        set_process(false)
    queue_redraw()


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _dragging = event.pressed
        if _dragging:
            _set_from_x(event.position.x)
    elif event is InputEventMouseMotion and _dragging:
        _set_from_x(event.position.x)
    elif event.is_action_pressed("ui_left"):
        set_value(_value - 0.05)
        accept_event()
    elif event.is_action_pressed("ui_right"):
        set_value(_value + 0.05)
        accept_event()


func _set_from_x(x: float) -> void:
    var span := maxf(size.x - 2.0 * PAD, 1.0)
    set_value((x - PAD) / span)


func _draw() -> void:
    var cy := size.y / 2.0
    var left := PAD
    var right := size.x - PAD
    var bar := Rect2(left, cy - BAR_H / 2.0, right - left, BAR_H)

    # полоса
    var track := StyleBoxFlat.new()
    track.bg_color = Color(0.07, 0.045, 0.03, 1.0)
    track.border_color = Color(0.50, 0.48, 0.52, 1.0)
    track.set_border_width_all(2)
    track.set_corner_radius_all(5)
    draw_style_box(track, bar)

    # заливка
    var fw := (right - left) * _shown
    if fw > 1.0:
        var fill := StyleBoxFlat.new()
        fill.bg_color = UIStyle.AMBER
        fill.set_corner_radius_all(5)
        draw_style_box(fill, Rect2(left, bar.position.y, fw, BAR_H))

    # узкий маркер
    var hx := left + fw
    var handle := StyleBoxFlat.new()
    handle.bg_color = UIStyle.CREAM
    handle.border_color = Color(0.10, 0.05, 0.02, 1.0)
    handle.set_border_width_all(2)
    handle.set_corner_radius_all(3)
    draw_style_box(handle, Rect2(hx - 4.0, cy - 14.0, 8.0, 28.0))
