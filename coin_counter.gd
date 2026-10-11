class_name CoinCounter
extends PanelContainer
## Счётчик валюты: иконка монеты + число. Обновляется сам при любом изменении монет.
## Табличка растёт вместе с суммой: каждый порядок числа добавляет +50% к размеру
##   0..9 монет = x1,  10..99 = x1.5,  100..999 = x2,  1000..9999 = x2.5 и так далее,
## но не больше MAX_W x MAX_H — чтобы она никогда не перекрывала заголовок и соседние элементы.
## Иконка монеты: assets/ui/coin.png

const COIN_PATH := "res://assets/ui/coin.png"
const MAX_W := 300.0       # предел ширины таблички (px)
const MAX_H := 90.0        # предел высоты таблички (px)
const STEP := 0.5          # на сколько растёт размер за каждый порядок числа
const BASE_FONT := 30
const BASE_ICON := 38.0
const BASE_PAD := 6.0
const BASE_GAP := 8.0
const BORDER := 2

var _row: HBoxContainer
var _icon: TextureRect
var _label: Label
var _box: StyleBoxFlat


func _ready() -> void:
    _box = UIStyle.flat_box(Color(0.07, 0.045, 0.03, 0.92), Color(0.46, 0.44, 0.50), BORDER, 8, int(BASE_PAD))
    add_theme_stylebox_override("panel", _box)
    size_flags_vertical = Control.SIZE_SHRINK_CENTER
    tooltip_text = GameSettings.t("coins")

    _row = HBoxContainer.new()
    _row.add_theme_constant_override("separation", int(BASE_GAP))
    _row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_row)

    var tex := GameData.tex(COIN_PATH)
    if tex != null:
        _icon = TextureRect.new()
        _icon.texture = tex
        _icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        _icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        _icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        _icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _row.add_child(_icon)

    _label = Label.new()
    _label.add_theme_color_override("font_color", UIStyle.AMBER_LIGHT)
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _row.add_child(_label)

    GameData.coins_changed.connect(_update)
    _update()


## Во сколько раз табличка больше обычной при такой сумме (до ограничения по месту).
static func desired_scale(amount: int) -> float:
    return 1.0 + STEP * float(str(maxi(amount, 0)).length() - 1)


func _update() -> void:
    var text := str(GameData.coins)
    _label.text = text

    # размер таблички при масштабе 1 -> сколько вообще можно вырасти в отведённое место
    var font := get_theme_default_font()
    if font == null:
        font = ThemeDB.fallback_font
    var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BASE_FONT).x
    var content_h := maxf(BASE_ICON, font.get_height(BASE_FONT))
    var w1 := text_w + 2.0 * (BASE_PAD + BORDER)
    if _icon != null:
        w1 += BASE_ICON + BASE_GAP
    var h1 := content_h + 2.0 * (BASE_PAD + BORDER)
    w1 *= 1.08   # небольшой запас
    h1 *= 1.08

    var s := minf(desired_scale(GameData.coins), minf(MAX_W / w1, MAX_H / h1))
    s = maxf(s, 0.4)

    _label.add_theme_font_size_override("font_size", maxi(roundi(BASE_FONT * s), 8))
    _label.add_theme_constant_override("outline_size", maxi(roundi(4.0 * s), 1))
    if _icon != null:
        _icon.custom_minimum_size = Vector2(BASE_ICON * s, BASE_ICON * s)
    _row.add_theme_constant_override("separation", roundi(BASE_GAP * s))
    _box.set_content_margin_all(BASE_PAD * s)
    _box.set_corner_radius_all(roundi(8.0 * s))
    custom_minimum_size = Vector2.ZERO
    reset_size()
