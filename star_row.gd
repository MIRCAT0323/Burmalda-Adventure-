class_name StarRow
extends Control
## Ряд из трёх звёзд (закрашены первые `stars`). Рисуется кодом, картинки не нужны.

const GOLD := Color("ffc93c")
const GOLD_EDGE := Color("8a5418")
const EMPTY := Color(0.16, 0.12, 0.10, 0.9)
const EMPTY_EDGE := Color(0.42, 0.36, 0.32, 1.0)
## Свои картинки звёзд: assets/ui/star_full.png (заработана) и star_empty.png (пустая).
## Если файла нет, звезда рисуется кодом.
const STAR_FULL := "res://assets/ui/star_full.png"
const STAR_EMPTY := "res://assets/ui/star_empty.png"

static var _tex_full: Texture2D
static var _tex_empty: Texture2D
static var _tex_loaded := false

var stars := 0:
	set(v):
		stars = v
		queue_redraw()
var star_radius := 14.0
var gap := 8.0


func setup(count: int, radius: float, spacing := 8.0) -> void:
	star_radius = radius
	gap = spacing
	custom_minimum_size = Vector2((2.0 * radius + spacing) * GameData.MAX_STARS - spacing, 2.0 * radius)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars = count


func _draw() -> void:
	draw_row(self, Vector2(size.x / 2.0, size.y / 2.0), stars, star_radius, gap)


## Рисует три звезды на любом CanvasItem; center — середина ряда.
static func draw_row(canvas: CanvasItem, center: Vector2, filled: int, radius: float, spacing: float) -> void:
	var step := 2.0 * radius + spacing
	for i in GameData.MAX_STARS:
		var c := center + Vector2((i - 1) * step, 0.0)
		var on := i < filled
		draw_star(canvas, c, radius, GOLD if on else EMPTY, GOLD_EDGE if on else EMPTY_EDGE)


static func _load_textures() -> void:
	if _tex_loaded:
		return
	_tex_loaded = true
	if ResourceLoader.exists(STAR_FULL):
		_tex_full = load(STAR_FULL)
	if ResourceLoader.exists(STAR_EMPTY):
		_tex_empty = load(STAR_EMPTY)


static func draw_star(canvas: CanvasItem, c: Vector2, r: float, fill: Color, edge: Color) -> void:
	_load_textures()
	var on := fill == GOLD
	var tex := _tex_full if on else _tex_empty
	if tex != null:
		canvas.draw_texture_rect(tex, Rect2(c - Vector2(r, r) * 1.15, Vector2(r, r) * 2.3), false)
		return
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + TAU * float(i) / 10.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	canvas.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	canvas.draw_polyline(closed, edge, 2.0, true)
