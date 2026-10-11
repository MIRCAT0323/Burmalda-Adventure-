class_name ItemTile
extends Control
## Плитка предмета. Целиком рисуется кодом: без контейнеров и без автопереноса текста,
## поэтому её размер ВСЕГДА ровно такой, какой задан в setup().
## (Раньше плитки рулетки иногда «раздувались» по высоте из-за автопереноса текста,
## и картинки уезжали вниз за рамку. Теперь так не бывает.)
##
## Используется в рулетке, в списке «Что внутри», в магазине и в инвентаре.
##
## setup(item, ширина, высота, настройки). Настройки (все необязательные):
##   "name": true         - показывать название (шрифт подбирается под ширину, до 2 строк)
##   "stats": true        - показывать плашки урона и ХП
##   "interactive": true  - подсветка при наведении, сигнал pressed по клику
##   "equipped": true     - значок «надето» и янтарная рамка
##   "slot": true         - слот героя: ТОЛЬКО картинка предмета, без текста
##   "empty_text": "Шлем" - бледная подпись у пустого слота
##   "name_font": 16      - максимальный размер шрифта названия

signal pressed

const PAD := 7.0
const STRIPE := 5.0
const CHIP_H := 22.0

var item: Dictionary = {}
var show_name := true
var show_stats := false
var interactive := false
var slot_mode := false
var equipped := false
var empty_text := ""
var name_font_max := 16

var hover_t := 0.0:
    set(v):
        hover_t = v
        queue_redraw()

var _tex: Texture2D
var _hover_tween: Tween
var _scale_tween: Tween
var _sb := StyleBoxFlat.new()
var _chip_sb := StyleBoxFlat.new()

static var _glow_cache := {}


func setup(it: Dictionary, w: float, h: float, opts := {}) -> void:
    show_name = bool(opts.get("name", true))
    show_stats = bool(opts.get("stats", false))
    interactive = bool(opts.get("interactive", false))
    slot_mode = bool(opts.get("slot", false))
    equipped = bool(opts.get("equipped", false))
    empty_text = str(opts.get("empty_text", ""))
    name_font_max = int(opts.get("name_font", 16))
    custom_minimum_size = Vector2(w, h)
    size = Vector2(w, h)
    pivot_offset = size / 2.0
    mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_PASS
    if interactive:
        mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    set_item(it)


func _ready() -> void:
    resized.connect(func(): pivot_offset = size / 2.0)
    mouse_entered.connect(_on_hover.bind(true))
    mouse_exited.connect(_on_hover.bind(false))


## Меняет предмет в плитке (нужно слотам героя).
func set_item(it: Dictionary) -> void:
    item = it
    _tex = null
    if not item.is_empty():
        _tex = UIStyle.item_texture(str(item["id"]))
    if item.is_empty():
        tooltip_text = ""
    else:
        var s := GameData.stats_text(item)
        var n := GameData.loc(item["name"])
        tooltip_text = n if s == "" else "%s\n%s" % [n, s]
    queue_redraw()


func set_equipped(on: bool) -> void:
    equipped = on
    queue_redraw()


# ================================================================ ввод
func _on_hover(on: bool) -> void:
    if not interactive:
        return
    if _hover_tween != null and _hover_tween.is_valid():
        _hover_tween.kill()
    _hover_tween = create_tween()
    _hover_tween.tween_property(self, "hover_t", 1.0 if on else 0.0, 0.14).set_trans(Tween.TRANS_SINE)


func _gui_input(event: InputEvent) -> void:
    if not interactive:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        pressed.emit()
        accept_event()


# ================================================================ рисование
func _draw() -> void:
    var w := size.x
    var h := size.y
    var has := not item.is_empty()
    var rc: Color = GameData.rarity_color(item) if has else Color(0.46, 0.44, 0.50)

    # ---- фон и рамка ----
    var bg: Color
    var border: Color
    var bw := 2
    if slot_mode:
        bg = Color(0.075, 0.052, 0.04, 0.96).lerp(Color(0.13, 0.09, 0.06, 0.98), hover_t)
        border = rc if has else Color(0.40, 0.38, 0.43)
        if has:
            bw = 3
    else:
        bg = Color(0.13, 0.095, 0.07).lerp(Color(0.21, 0.145, 0.09), hover_t)
        border = rc
        bw = 3
    if equipped:
        border = UIStyle.AMBER
        bw = 3
    border = border.lerp(UIStyle.AMBER_LIGHT, hover_t * 0.9)
    _sb.bg_color = bg
    _sb.border_color = border
    _sb.set_border_width_all(bw)
    _sb.set_corner_radius_all(7)
    if slot_mode:
        _sb.shadow_size = 0
    else:
        _sb.shadow_color = Color(0, 0, 0, 0.4)
        _sb.shadow_size = 5
        _sb.shadow_offset = Vector2(0, 3)
    draw_style_box(_sb, Rect2(Vector2.ZERO, size))

    # ---- раскладка ----
    var name_h := 0.0
    if show_name and has and not slot_mode:
        name_h = float(name_font_max) * 2.3
    var stats_h := (CHIP_H + 4.0) if (show_stats and has and not slot_mode) else 0.0
    var bottom := 0.0 if slot_mode else 6.0
    var top := (PAD + 2.0) if slot_mode else PAD
    var side: float
    if slot_mode:
        side = minf(w, h) - 2.0 * top
    else:
        var gaps := (4.0 if name_h > 0.0 else 0.0) + (4.0 if stats_h > 0.0 else 0.0)
        side = minf(w - 2.0 * PAD, h - top - name_h - stats_h - bottom - gaps)
    side = maxf(side, 8.0)
    var img_x := (w - side) / 2.0
    var img_y := top
    if slot_mode or (name_h == 0.0 and stats_h == 0.0):
        img_y = (h - bottom - side) / 2.0     # картинка строго по центру
    var lift := -2.0 * hover_t
    var img_rect := Rect2(img_x, img_y + lift, side, side)

    # ---- подсветка редкости и картинка ----
    if has:
        draw_texture_rect(glow_texture(rc), img_rect.grow(side * 0.14), false, Color(1, 1, 1, 0.65 + 0.35 * hover_t))
        if _tex != null:
            _draw_fitted(_tex, img_rect.grow(-side * 0.04))
        else:
            _draw_centered_text(GameData.loc(item["name"]).left(1), img_rect, int(side * 0.5), Color(1, 1, 1, 0.35), true)
    elif slot_mode and empty_text != "":
        _draw_fitted_text(empty_text, Rect2(4, 4, w - 8, h - 8), 15, 8, 2, Color(0.72, 0.66, 0.54, 0.5), false)

    # ---- название ----
    var cursor_y := img_y + side + 4.0
    if name_h > 0.0:
        var col := UIStyle.AMBER_LIGHT if equipped else UIStyle.CREAM
        _draw_fitted_text(GameData.loc(item["name"]), Rect2(3, cursor_y, w - 6, name_h), name_font_max, 8, 2, col, true)
        cursor_y += name_h + 4.0

    # ---- плашки урона / здоровья ----
    if stats_h > 0.0:
        _draw_chips(cursor_y)

    # ---- значок «надето» ----
    if equipped and not slot_mode:
        var c := Vector2(w - 17.0, 17.0)
        draw_circle(c + Vector2(0, 1.5), 12.0, Color(0, 0, 0, 0.5))
        draw_circle(c, 11.5, Color(0.07, 0.04, 0.02))
        draw_circle(c, 9.5, UIStyle.AMBER)
        draw_polyline(PackedVector2Array([c + Vector2(-4.5, 0.5), c + Vector2(-1.2, 3.8), c + Vector2(4.8, -3.2)]), Color(0.1, 0.05, 0.02), 2.6, true)


func _draw_fitted(tex: Texture2D, box: Rect2) -> void:
    var tw := float(tex.get_width())
    var th := float(tex.get_height())
    if tw <= 0.0 or th <= 0.0:
        return
    var s := minf(box.size.x / tw, box.size.y / th)
    var sz := Vector2(tw, th) * s
    draw_texture_rect(tex, Rect2(box.position + (box.size - sz) / 2.0, sz), false)


func _draw_chips(y: float) -> void:
    var parts: Array = []
    if int(item.get("damage", 0)) > 0:
        parts.append({"t": "+%d %s" % [int(item["damage"]), GameSettings.t("stat_damage")],
            "fg": Color("ffa088"), "bg": Color(0.30, 0.10, 0.08), "bd": Color("a6483a")})
    if int(item.get("hp", 0)) > 0:
        parts.append({"t": "+%d %s" % [int(item["hp"]), GameSettings.t("stat_hp")],
            "fg": Color("a6e896"), "bg": Color(0.09, 0.22, 0.09), "bd": Color("3f8a38")})
    if parts.is_empty():
        return
    var n := parts.size()
    var gap := 4.0
    var x0 := PAD - 1.0
    var cw := (size.x - 2.0 * x0 - gap * float(n - 1)) / float(n)
    for i in n:
        var p: Dictionary = parts[i]
        var rect := Rect2(x0 + float(i) * (cw + gap), y, cw, CHIP_H)
        _chip_sb.bg_color = p["bg"]
        _chip_sb.border_color = p["bd"]
        _chip_sb.set_border_width_all(1)
        _chip_sb.set_corner_radius_all(6)
        draw_style_box(_chip_sb, rect)
        _draw_fitted_text(str(p["t"]), rect.grow(-3.0), 15, 8, 1, p["fg"], false)


# ================================================================ текст
func _font() -> Font:
    var f := get_theme_default_font()
    return f if f != null else ThemeDB.fallback_font


## Разбивает слова на строки не шире max_w. Если какое-то слово не влезает, возвращает [].
func _wrap(words: PackedStringArray, font: Font, fs: int, max_w: float) -> Array:
    var lines: Array = []
    var cur := ""
    for wd in words:
        if font.get_string_size(wd, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
            return []
        var trial := wd if cur == "" else cur + " " + wd
        if font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= max_w:
            cur = trial
        else:
            lines.append(cur)
            cur = wd
    if cur != "":
        lines.append(cur)
    return lines


## Подбирает самый крупный шрифт, при котором текст помещается в ширину и в max_lines строк.
func _fit(text: String, max_w: float, max_size: int, min_size: int, max_lines: int) -> Dictionary:
    var font := _font()
    var words := text.split(" ", false)
    for fs in range(max_size, min_size - 1, -1):
        var lines := _wrap(words, font, fs, max_w)
        if not lines.is_empty() and lines.size() <= max_lines:
            return {"size": fs, "lines": lines}
    # крайний случай: длинное слово ужимаем ещё сильнее, чтобы оно точно влезло
    for fs in range(min_size - 1, 5, -1):
        if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= max_w:
            return {"size": fs, "lines": [text]}
    return {"size": 6, "lines": [text]}


## Рисует текст в прямоугольнике по центру, подбирая размер шрифта.
func _draw_fitted_text(text: String, box: Rect2, max_size: int, min_size: int, max_lines: int, color: Color, outline: bool) -> void:
    var font := _font()
    var margin := 4.0 if outline else 0.0
    var fit := _fit(text, box.size.x - margin, max_size, min_size, max_lines)
    var fs: int = fit["size"]
    var lines: Array = fit["lines"]
    var line_h := font.get_height(fs)
    var total_h := line_h * float(lines.size())
    var y := box.position.y + (box.size.y - total_h) / 2.0 + font.get_ascent(fs)
    for ln in lines:
        var lw := font.get_string_size(str(ln), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
        var pos := Vector2(box.position.x + (box.size.x - lw) / 2.0, y)
        if outline:
            draw_string_outline(font, pos, str(ln), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.06, 0.03, 0.01, 0.95))
        draw_string(font, pos, str(ln), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
        y += line_h


func _draw_centered_text(text: String, box: Rect2, fs: int, color: Color, outline: bool) -> void:
    _draw_fitted_text(text, box, fs, 8, 1, color, outline)


# ================================================================ подсветка
## Мягкое круглое свечение цвета редкости (кэшируется).
static func glow_texture(c: Color) -> Texture2D:
    var key := c.to_html()
    if _glow_cache.has(key):
        return _glow_cache[key]
    var g := Gradient.new()
    g.set_color(0, Color(c, 0.55))
    g.set_color(1, Color(c, 0.0))
    var gt := GradientTexture2D.new()
    gt.gradient = g
    gt.fill = GradientTexture2D.FILL_RADIAL
    gt.fill_from = Vector2(0.5, 0.5)
    gt.fill_to = Vector2(1.0, 0.5)
    gt.width = 128
    gt.height = 128
    _glow_cache[key] = gt
    return gt
