class_name CircleSlot
extends Control
## Круглый слот с обводкой под картинку (персонаж, локация).
## Картинка обрезается по кругу. Если картинки нет, рисуется заглушка.

signal pressed

var texture: Texture2D
var placeholder := "?"
var ring_color := Color("c98a2e")
var ring_hover := Color("ffd27a")
var locked := false:   # серый круг с замком (локация недоступна)
    set(v):
        locked = v
        material = _gray_material() if v else null   # закрытая локация: всё в сером
        if v and _lock_icon == null:
            # замок — отдельный узел, чтобы остаться цветным (без серого шейдера).
            # Своя картинка: assets/ui/lock.png (PNG с прозрачным фоном); нет файла — рисуется замок кодом.
            var lock_tex := UIStyle.icon("lock.png")
            if lock_tex != null:
                var tr := TextureRect.new()
                tr.texture = lock_tex
                tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
                tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                tr.anchor_left = 0.2
                tr.anchor_right = 0.8
                tr.anchor_top = 0.2
                tr.anchor_bottom = 0.8
                tr.offset_left = 0.0
                tr.offset_right = 0.0
                tr.offset_top = 0.0
                tr.offset_bottom = 0.0
                tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
                _lock_icon = tr
            else:
                _lock_icon = Control.new()
                _lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
                _lock_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
                _lock_icon.draw.connect(_draw_lock.bind(_lock_icon))
            add_child(_lock_icon)
        elif not v and _lock_icon != null:
            _lock_icon.queue_free()
            _lock_icon = null
        queue_redraw()
var _lock_icon: Control = null
var _hover := false
var _tween: Tween


func setup(tex: Texture2D, diameter: float, placeholder_text := "?") -> void:
    texture = tex
    placeholder = placeholder_text
    custom_minimum_size = Vector2(diameter, diameter)
    size = custom_minimum_size
    pivot_offset = size / 2.0
    queue_redraw()


## Материал: перевод в тёмно-серые тона (картинка, круг и обводка становятся серыми).
static func _gray_material() -> ShaderMaterial:
    var sh := Shader.new()
    sh.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec4 c = texture(TEXTURE, UV) * COLOR;\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114)) * 0.62;\n\tCOLOR = vec4(vec3(g), c.a);\n}\n"
    var m := ShaderMaterial.new()
    m.shader = sh
    return m


## Замок по центру: корпус, дужка и замочная скважина.
func _draw_lock(ci: Control) -> void:
    var c := ci.size / 2.0
    var r := minf(ci.size.x, ci.size.y) / 2.0
    var u := r * 0.30                       # базовая единица размера
    var body := Rect2(c.x - u * 0.9, c.y - u * 0.1, u * 1.8, u * 1.45)
    var steel := Color(0.80, 0.80, 0.84)
    var dark := Color(0.06, 0.05, 0.05)
    ci.draw_circle(c + Vector2(0, u * 0.6), u * 1.7, Color(0, 0, 0, 0.35))                      # затемнение под замком
    ci.draw_arc(Vector2(c.x, c.y - u * 0.1), u * 0.58, PI, TAU, 24, dark, u * 0.5, true)         # дужка: контур
    ci.draw_arc(Vector2(c.x, c.y - u * 0.1), u * 0.58, PI, TAU, 24, steel, u * 0.3, true)        # дужка
    ci.draw_rect(Rect2(c.x - u * 0.88, c.y - u * 0.1, u * 0.3, u * 0.35), steel)                 # левая стойка дужки
    ci.draw_rect(Rect2(c.x + u * 0.58, c.y - u * 0.1, u * 0.3, u * 0.35), steel)                 # правая стойка
    ci.draw_rect(body.grow(u * 0.1), dark)                                                       # корпус: контур
    ci.draw_rect(body, Color(0.86, 0.68, 0.30))                                                  # корпус
    ci.draw_rect(Rect2(body.position, Vector2(body.size.x, body.size.y * 0.35)), Color(1, 1, 1, 0.14))
    ci.draw_circle(Vector2(c.x, c.y + u * 0.5), u * 0.22, dark)                                  # скважина
    ci.draw_rect(Rect2(c.x - u * 0.08, c.y + u * 0.5, u * 0.16, u * 0.5), dark)


func _ready() -> void:
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    resized.connect(func(): pivot_offset = size / 2.0)
    mouse_entered.connect(_set_hover.bind(true))
    mouse_exited.connect(_set_hover.bind(false))


func _has_point(point: Vector2) -> bool:
    return point.distance_to(size / 2.0) <= minf(size.x, size.y) / 2.0


func _set_hover(on: bool) -> void:
    _hover = on
    if _tween != null and _tween.is_valid():
        _tween.kill()
    _tween = create_tween()
    var s := 1.07 if on else 1.0
    _tween.tween_property(self, "scale", Vector2(s, s), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    queue_redraw()


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pressed.emit()
        accept_event()


func _draw() -> void:
    var c := size / 2.0
    var r := minf(size.x, size.y) / 2.0
    draw_circle(c + Vector2(0, 6), r, Color(0, 0, 0, 0.45))
    if _hover and not locked:
        draw_circle(c, r + 9.0, Color(1.0, 0.72, 0.25, 0.20))
    draw_circle(c, r, Color(0.07, 0.045, 0.03))
    var ir := r - 6.0      # внутренний край обводки
    var pr := r - 3.0      # картинка идёт под обводку, без чёрных щелей
    draw_circle(c, ir, Color(0.11, 0.08, 0.06))
    if texture != null:
        var half := Vector2(0.5, 0.5)   # вся картинка растягивается на весь круг
        var pts := PackedVector2Array()
        var uvs := PackedVector2Array()
        var cols := PackedColorArray()
        var n := 128
        for i in n:
            var a := TAU * float(i) / float(n)
            var d := Vector2(cos(a), sin(a))
            pts.append(c + d * pr)
            uvs.append(Vector2(0.5, 0.5) + d * half)
            cols.append(Color.WHITE)
        draw_polygon(pts, cols, uvs, texture)
    else:
        var font := get_theme_default_font()
        var fs := int(r * 0.9)
        draw_string(font, Vector2(0.0, c.y + fs * 0.33), placeholder, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(1, 1, 1, 0.35))
    if locked:
        draw_circle(c, pr, Color(0.0, 0.0, 0.0, 0.18))   # чуть темнее картинки
    draw_arc(c, r - 3.0, 0.0, TAU, 96, ring_hover if (_hover and not locked) else ring_color, 6.0, true)


