class_name PortraitFrame
extends Control
## Квадратная рамка для портрета героя: картинка обрезается по центру в квадрат
## (как в выборе героя), вокруг янтарная рамка с заклёпками.
## Цвета рамки — константы ниже.

const FRAME_OUTER := Color(0.05, 0.03, 0.02)
const FRAME_MAIN := Color("c98a2e")
const FRAME_LIGHT := Color("ffd27a")
const FRAME_DARK := Color("6b4210")
const RIVET := Color(0.62, 0.62, 0.68)

var texture: Texture2D
var placeholder := "?"


func setup(tex: Texture2D, side: float, placeholder_text := "?") -> void:
    texture = tex
    placeholder = placeholder_text
    custom_minimum_size = Vector2(side, side)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()


func _draw() -> void:
    var r := Rect2(Vector2.ZERO, size)
    draw_rect(Rect2(r.position + Vector2(0, 6), r.size), Color(0, 0, 0, 0.4))      # тень
    draw_rect(r, FRAME_OUTER)
    var inner := r.grow(-14.0)
    draw_rect(inner, Color(0.09, 0.065, 0.05))
    if texture != null:
        var tw := float(texture.get_width())
        var th := float(texture.get_height())
        var side := minf(tw, th)
        var src := Rect2((tw - side) / 2.0, (th - side) / 2.0, side, side)   # центральный квадрат
        draw_texture_rect_region(texture, inner, src)
    else:
        var font := get_theme_default_font()
        var fs := int(size.x * 0.4)
        draw_string(font, Vector2(0.0, size.y / 2.0 + fs * 0.33), placeholder, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(1, 1, 1, 0.35))
    # рамка: тёмная кромка, янтарная полоса, светлый блик, тёмная внутренняя линия
    draw_rect(r.grow(-1.0), FRAME_DARK, false, 2.0)
    draw_rect(r.grow(-6.0), FRAME_MAIN, false, 9.0)
    draw_rect(r.grow(-3.0), FRAME_LIGHT, false, 2.0)
    draw_rect(inner, Color(0, 0, 0, 0.7), false, 2.0)
    # заклёпки в углах
    for p in [Vector2(10, 10), Vector2(size.x - 10, 10), Vector2(10, size.y - 10), Vector2(size.x - 10, size.y - 10)]:
        draw_circle(p, 6.0, FRAME_OUTER)
        draw_circle(p, 4.5, RIVET)
        draw_circle(p + Vector2(-1.5, -1.5), 1.6, Color(1, 1, 1, 0.7))
