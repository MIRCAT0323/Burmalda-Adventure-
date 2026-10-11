class_name UIStyle
extends RefCounted
## Стиль меню: деревянные доски с железной окантовкой, заклёпки, тёплый янтарный текст.
## Все картинки лежат в assets/ui/ — можно заменить на свои (с теми же именами).

const BG_PATH := "res://assets/background.png"   # ТВОЙ ФОН
const FONT_PATH := "res://assets/font.ttf"        # ТВОЙ ШРИФТ (нужна кириллица)
const UI_DIR := "res://assets/ui/"

const CREAM := Color("f6ead0")
const AMBER := Color("e0902a")
const AMBER_LIGHT := Color("ffc766")
const AMBER_DARK := Color("8a5418")
const INK := Color("4a2c12")
const INK_SOFT := Color("7a5430")


static func _tex(file: String) -> Texture2D:
    var p := UI_DIR + file
    if ResourceLoader.exists(p):
        return load(p)
    return null


static func icon(file: String) -> Texture2D:
    return _tex(file)


static func flag(code: String) -> Texture2D:
    return _tex("flag_%s.png" % code)


## Рамка выбранной кнопки (например, выбранный язык).
static func selected_box() -> StyleBoxTexture:
    return _tex_box("btn_selected.png", 28, 24, 10)


static func _tex_box(file: String, tex_margin: int, cm_h: int, cm_v: int) -> StyleBoxTexture:
    var sb := StyleBoxTexture.new()
    sb.texture = _tex(file)
    sb.texture_margin_left = tex_margin
    sb.texture_margin_right = tex_margin
    sb.texture_margin_top = tex_margin
    sb.texture_margin_bottom = tex_margin
    sb.content_margin_left = cm_h
    sb.content_margin_right = cm_h
    sb.content_margin_top = cm_v
    sb.content_margin_bottom = cm_v
    return sb


static func _field_box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.set_border_width_all(width)
    sb.set_corner_radius_all(6)
    sb.content_margin_left = 16
    sb.content_margin_right = 16
    sb.content_margin_top = 12
    sb.content_margin_bottom = 12
    return sb


static func make_theme() -> Theme:
    var t := Theme.new()
    t.default_font_size = 26
    if ResourceLoader.exists(FONT_PATH):
        t.default_font = load(FONT_PATH)

    # --- Кнопки (деревянные доски) ---
    t.set_stylebox("normal", "Button", _tex_box("btn_normal.png", 28, 24, 10))
    t.set_stylebox("hover", "Button", _tex_box("btn_hover.png", 28, 24, 10))
    t.set_stylebox("pressed", "Button", _tex_box("btn_pressed.png", 28, 24, 10))
    t.set_stylebox("hover_pressed", "Button", _tex_box("btn_pressed.png", 28, 24, 10))
    t.set_stylebox("focus", "Button", _tex_box("btn_hover.png", 28, 24, 10))
    # неактивная кнопка: та же деревянная доска, но полупрозрачная и притушенная
    var dis := _tex_box("btn_normal.png", 28, 24, 10)
    dis.modulate_color = Color(0.75, 0.68, 0.62, 0.5)
    t.set_stylebox("disabled", "Button", dis)
    t.set_color("font_disabled_color", "Button", Color(CREAM, 0.5))
    t.set_font_size("font_size", "Button", 30)
    t.set_color("font_color", "Button", CREAM)
    t.set_color("font_hover_color", "Button", Color("fff3d6"))
    t.set_color("font_focus_color", "Button", Color("fff3d6"))
    t.set_color("font_pressed_color", "Button", AMBER_LIGHT)
    t.set_color("font_hover_pressed_color", "Button", AMBER_LIGHT)
    t.set_color("font_outline_color", "Button", Color(0.10, 0.05, 0.02, 1.0))
    t.set_constant("outline_size", "Button", 6)
    t.set_constant("h_separation", "Button", 14)

    # --- Текст ---
    t.set_color("font_color", "Label", CREAM)
    t.set_color("font_outline_color", "Label", Color(0.08, 0.04, 0.02, 1.0))
    t.set_constant("outline_size", "Label", 4)

    # --- Поле ввода (тёмная вставка в дереве) ---
    t.set_stylebox("normal", "LineEdit", _field_box(Color(0.07, 0.045, 0.03, 0.92), Color(0.42, 0.40, 0.44, 1.0), 2))
    t.set_stylebox("focus", "LineEdit", _field_box(Color(0.09, 0.06, 0.04, 0.95), AMBER, 3))
    t.set_stylebox("read_only", "LineEdit", _field_box(Color(0.07, 0.045, 0.03, 0.92), Color(0.42, 0.40, 0.44, 1.0), 2))
    t.set_color("font_color", "LineEdit", CREAM)
    t.set_color("font_placeholder_color", "LineEdit", Color(0.80, 0.70, 0.50, 0.45))
    t.set_color("caret_color", "LineEdit", AMBER_LIGHT)
    t.set_color("selection_color", "LineEdit", Color(0.88, 0.56, 0.16, 0.45))

    # --- Деревянная панель ---
    t.set_stylebox("panel", "PanelContainer", _tex_box("panel.png", 56, 64, 56))

    # --- Полоса прокрутки (тёмная дорожка, янтарный ползунок) ---
    var track := flat_box(Color(0.04, 0.03, 0.022, 0.9), Color(0.30, 0.28, 0.32), 1, 6)
    track.content_margin_left = 6
    track.content_margin_right = 6
    t.set_stylebox("scroll", "VScrollBar", track)
    t.set_stylebox("grabber", "VScrollBar", flat_box(AMBER_DARK, AMBER, 1, 6))
    t.set_stylebox("grabber_highlight", "VScrollBar", flat_box(AMBER, AMBER_LIGHT, 1, 6))
    t.set_stylebox("grabber_pressed", "VScrollBar", flat_box(AMBER_LIGHT, Color("fff3d6"), 1, 6))

    # --- Всплывающие подсказки ---
    var tip := flat_box(Color(0.06, 0.04, 0.03, 0.97), AMBER, 2, 8, 8)
    tip.content_margin_left = 12
    tip.content_margin_right = 12
    t.set_stylebox("panel", "TooltipPanel", tip)
    t.set_color("font_color", "TooltipLabel", CREAM)
    t.set_font_size("font_size", "TooltipLabel", 20)
    t.set_constant("outline_size", "TooltipLabel", 0)
    return t


## Тёмная плоская рамка (слоты, карточки, счётчик монет).
static func flat_box(bg: Color, border: Color, width := 2, radius := 6, margin := 0) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.set_border_width_all(width)
    sb.set_corner_radius_all(radius)
    sb.set_content_margin_all(margin)
    return sb


## Картинка предмета (assets/items/<id>.png) или null.
static func item_texture(item_id: String) -> Texture2D:
    return GameData.tex("res://assets/items/%s.png" % item_id)


## plain = true — деревянная кнопка без заклёпок (btn_plain_*.png).
static func make_button(text: String, min_size := Vector2(420, 80), plain := false) -> Button:
    var b := Button.new()
    if plain:
        apply_plain_style(b)
    b.text = text.to_upper()
    b.custom_minimum_size = min_size
    attach_hover_fx(b)
    return b


## Заменяет рамки кнопки на деревянные без заклёпок.
static func apply_plain_style(b: Button) -> void:
    var dis := _tex_box("btn_plain_normal.png", 28, 24, 10)
    dis.modulate_color = Color(0.75, 0.68, 0.62, 0.5)
    b.add_theme_stylebox_override("disabled", dis)
    b.add_theme_stylebox_override("normal", _tex_box("btn_plain_normal.png", 28, 24, 10))
    b.add_theme_stylebox_override("hover", _tex_box("btn_plain_hover.png", 28, 24, 10))
    b.add_theme_stylebox_override("pressed", _tex_box("btn_plain_pressed.png", 28, 24, 10))
    b.add_theme_stylebox_override("hover_pressed", _tex_box("btn_plain_pressed.png", 28, 24, 10))
    b.add_theme_stylebox_override("focus", _tex_box("btn_plain_hover.png", 28, 24, 10))


## Полная анимация наведения: кнопка плавно увеличивается, вся целиком (рамка и дерево) становится
## ярче, вокруг загорается тёплое свечение. Для кнопок-картинок (TextureButton) — без свечения.
static func attach_hover_fx(b: BaseButton) -> void:
    if b.has_meta("hover_fx"):
        return
    b.set_meta("hover_fx", true)
    if b is Button:
        var glow := Panel.new()
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(1.0, 0.72, 0.25, 0.0)
        sb.set_corner_radius_all(14)
        sb.shadow_color = Color(1.0, 0.70, 0.22, 0.6)
        sb.shadow_size = 16
        glow.add_theme_stylebox_override("panel", sb)
        glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
        glow.show_behind_parent = true
        glow.modulate.a = 0.0
        b.add_child(glow)
        b.set_meta("hover_glow", glow)
    b.mouse_entered.connect(_hover_fx.bind(b, true))
    b.mouse_exited.connect(_hover_fx.bind(b, false))


static func _hover_fx(b: BaseButton, on: bool) -> void:
    if not is_instance_valid(b) or not b.is_inside_tree():
        return
    if on and b.disabled:
        return
    var old = b.get_meta("hover_tween", null)
    if old != null and old.is_valid():
        old.kill()
    b.pivot_offset = b.size / 2.0
    var tw := b.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    b.set_meta("hover_tween", tw)
    var s := 1.06 if on else 1.0
    tw.tween_property(b, "scale", Vector2(s, s), 0.16)
    tw.tween_property(b, "self_modulate", Color(1.22, 1.14, 1.04) if on else Color.WHITE, 0.16)
    var glow = b.get_meta("hover_glow", null)
    if glow != null and is_instance_valid(glow):
        tw.tween_property(glow, "modulate:a", 1.0 if on else 0.0, 0.2)


static func _scale_to(b: Control, s: float) -> void:
    var old = b.get_meta("scale_tween", null)
    if old != null and old.is_valid():
        old.kill()
    b.pivot_offset = b.size / 2.0
    var tw := b.create_tween()
    b.set_meta("scale_tween", tw)
    tw.tween_property(b, "scale", Vector2(s, s), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Плавное появление элемента (с задержкой).
static func appear(node: Control, delay := 0.0, duration := 0.5) -> void:
    node.modulate.a = 0.0
    var tw := node.create_tween()
    tw.tween_property(node, "modulate:a", 1.0, duration).set_delay(delay).set_trans(Tween.TRANS_SINE)


## Логотип игры (картинка assets/ui/logo.png). Если её нет, будет обычный текст.
static func make_logo(fallback_text: String, width := 840.0) -> Control:
    var tex := _tex("logo.png")
    if tex == null:
        var l := Label.new()
        l.text = fallback_text
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.add_theme_font_size_override("font_size", 84)
        l.add_theme_color_override("font_color", AMBER_LIGHT)
        l.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02, 1.0))
        l.add_theme_constant_override("outline_size", 14)
        return l
    var r := TextureRect.new()
    r.texture = tex
    r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    r.custom_minimum_size = Vector2(width, width * float(tex.get_height()) / float(tex.get_width()))
    r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    r.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return r


## Заголовок окна.
static func make_heading(text: String, size: int) -> Label:
    var l := Label.new()
    l.text = text
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color("fff1cf"))
    l.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.02, 1.0))
    l.add_theme_constant_override("outline_size", 10)
    l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
    l.add_theme_constant_override("shadow_offset_x", 3)
    l.add_theme_constant_override("shadow_offset_y", 4)
    return l


static func make_section_label(text: String) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_color_override("font_color", AMBER_LIGHT)
    l.add_theme_font_size_override("font_size", 26)
    return l


static func make_divider() -> TextureRect:
    var d := TextureRect.new()
    d.texture = _tex("divider.png")
    d.stretch_mode = TextureRect.STRETCH_KEEP
    d.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    d.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return d


static func _full_rect(c: Control) -> void:
    c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE


static func add_background(parent: Control) -> void:
    if ResourceLoader.exists(BG_PATH):
        var tex := TextureRect.new()
        tex.texture = load(BG_PATH)
        tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        _full_rect(tex)
        parent.add_child(tex)
    else:
        var rect := ColorRect.new()
        rect.color = Color("140e1c")
        _full_rect(rect)
        parent.add_child(rect)

    # затемнение по краям (виньетка)
    var vignette := TextureRect.new()
    vignette.texture = _tex("vignette.png")
    vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    vignette.stretch_mode = TextureRect.STRETCH_SCALE
    _full_rect(vignette)
    parent.add_child(vignette)


## Летящие вверх искры.
static func add_embers(parent: Control) -> void:
    var size := parent.get_viewport_rect().size
    var p := CPUParticles2D.new()
    p.amount = 55
    p.lifetime = 8.0
    p.preprocess = 8.0
    p.position = Vector2(size.x / 2.0, size.y + 10.0)
    p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    p.emission_rect_extents = Vector2(size.x / 2.0, 8.0)
    p.direction = Vector2(0, -1)
    p.spread = 28.0
    p.gravity = Vector2(0, -6)
    p.initial_velocity_min = 35.0
    p.initial_velocity_max = 110.0
    p.scale_amount_min = 1.5
    p.scale_amount_max = 4.0
    var g := Gradient.new()
    g.set_color(0, Color(1.0, 0.75, 0.3, 0.0))
    g.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
    g.add_point(0.2, Color(1.0, 0.65, 0.2, 0.9))
    p.color_ramp = g
    var mat := CanvasItemMaterial.new()
    mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    p.material = mat
    parent.add_child(p)


## Небольшая надпись внизу экрана, которая сама гаснет (например «Скоро»).
static func notice(parent: Control, text: String) -> void:
    var l := Label.new()
    l.text = text
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", 30)
    l.add_theme_color_override("font_color", AMBER_LIGHT)
    l.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 1.0))
    l.add_theme_constant_override("outline_size", 8)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    l.modulate.a = 0.0
    parent.add_child(l)
    l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 56)
    var tw := l.create_tween()
    tw.tween_property(l, "modulate:a", 1.0, 0.2)
    tw.tween_interval(1.3)
    tw.tween_property(l, "modulate:a", 0.0, 0.5)
    tw.tween_callback(l.queue_free)


## Узкая переключаемая вкладка (для инвентаря).
static func make_tab_button(text: String) -> Button:
    var b := Button.new()
    b.text = text
    b.toggle_mode = true
    b.custom_minimum_size = Vector2(0, 52)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 20)
    b.add_theme_constant_override("outline_size", 5)
    b.add_theme_stylebox_override("normal", _tex_box("btn_plain_normal.png", 28, 8, 8))
    b.add_theme_stylebox_override("hover", _tex_box("btn_plain_hover.png", 28, 8, 8))
    b.add_theme_stylebox_override("pressed", _tex_box("btn_plain_selected.png", 28, 8, 8))
    b.add_theme_stylebox_override("hover_pressed", _tex_box("btn_plain_selected.png", 28, 8, 8))
    b.add_theme_stylebox_override("focus", _tex_box("btn_plain_hover.png", 28, 8, 8))
    attach_hover_fx(b)
    return b


## Круглая деревянная кнопка без заклёпок (пауза, уровни): тень, тёмный контур, железное кольцо,
## дерево из той же картинки, что у обычных кнопок (wood_file: btn_normal / btn_hover / btn_pressed .png).
## ring — цвет кольца, wood_tint — затемнение дерева (для закрытых уровней).
static func draw_round_button(ci: CanvasItem, c: Vector2, r: float, wood_file := "btn_normal.png", ring := Color("6b6d78"), wood_tint := Color.WHITE) -> void:
    ci.draw_circle(c + Vector2(0, 3), r, Color(0, 0, 0, 0.32))      # лёгкая тень
    ci.draw_circle(c, r, ring.darkened(0.45))                        # внешний краешек — тёмный оттенок самого кольца, не чёрный
    ci.draw_circle(c, r - 1.5, ring)
    var pr := r - 4.5
    var tex := _tex(wood_file)
    if tex == null:
        ci.draw_circle(c, pr, Color("5a3216") * wood_tint)
    else:
        var pts := PackedVector2Array()
        var uvs := PackedVector2Array()
        var cols := PackedColorArray()
        var tw := float(tex.get_width())
        var th := float(tex.get_height())
        for i in 64:
            var d := Vector2.from_angle(TAU * float(i) / 64.0)
            pts.append(c + d * pr)
            uvs.append(Vector2(0.5 + d.x * pr / tw, 0.5 + d.y * pr / th * 0.6))   # по вертикали берём узкую полосу дерева: без тёмных краёв рамки сверху и снизу
            cols.append(wood_tint)
        ci.draw_polygon(pts, cols, uvs, tex)
    ci.draw_arc(c, pr, 0.0, TAU, 64, ring.darkened(0.4), 1.5, true)                  # тонкая линия между кольцом и деревом (поверх, без щелей)
    ci.draw_arc(c, r - 3.0, PI * 1.15, PI * 1.85, 24, Color(1, 1, 1, 0.2), 1.5, true)   # блик на кольце
