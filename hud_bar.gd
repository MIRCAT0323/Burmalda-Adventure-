class_name HudBar
extends Control
## Полоска здоровья: скруглённая («таблетка») с тёмно-оранжевой обводкой и тенью, внутри — плоская
## заливка без бликов, белый «хп / макс. хп» по центру. «Хвост» урона белый, догоняет заливку с задержкой.
## Обычный вид — герой в углу экрана; compact — уменьшенная полоска над головой врага.
## mirror — заполняется справа налево.

const W := 440.0
const H := 76.0
const FRAME_COLOR := Color("b35f12")   # тёмно-оранжевая обводка
const TRAIL_COLOR := Color(1.0, 1.0, 1.0, 0.92)

var fighter: Fighter
var mirror := false
var compact := false
var bar_w := W
var bar_h_total := H
var _fill := 0.0
var _trail := 0.0
var _trail_wait := 0.0
var _last_hp := 0
var _shake := 0.0
var _font: Font

var _bar_y := 36.0
var _bar_h := 32.0
var _border := 4.0
var _name_size := 28
var _hp_size := 22


func setup(f: Fighter, is_mirror: bool, is_compact := false) -> void:
	fighter = f
	mirror = is_mirror
	compact = is_compact
	if compact:
		bar_w = 150.0
		bar_h_total = 44.0
		_bar_y = 22.0
		_bar_h = 20.0
		_border = 3.0
		_name_size = 18
		_hp_size = 14
	_fill = float(f.hp)
	_trail = float(f.hp)
	_last_hp = f.hp
	custom_minimum_size = Vector2(bar_w, bar_h_total)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load(UIStyle.FONT_PATH) if ResourceLoader.exists(UIStyle.FONT_PATH) else ThemeDB.fallback_font


func _process(delta: float) -> void:
	if fighter == null:
		return
	if compact:
		visible = not fighter.dead           # над павшим врагом полоска не нужна
	var mx := float(maxi(fighter.max_hp, 1))
	if fighter.hp < _last_hp:
		_shake = 0.25
		_trail_wait = 0.5
	_last_hp = fighter.hp
	_fill = move_toward(_fill, float(fighter.hp), mx * delta * 3.0)
	if _trail > _fill:
		_trail_wait -= delta
		if _trail_wait <= 0.0:
			_trail = move_toward(_trail, _fill, mx * delta * 0.6)
	else:
		_trail = _fill
	_shake = maxf(_shake - delta, 0.0)
	queue_redraw()


func _fill_color(frac: float) -> Color:
	var base := fighter.bar_color
	if not compact and not mirror and frac < 0.3:
		return base.lerp(Color("c23b2e"), clampf((0.3 - frac) / 0.2, 0.0, 1.0))   # у героя краснеет в конце
	return base


func _txt(text: String, pos: Vector2, width: float, align: int, fsize: int, color: Color) -> void:
	draw_string_outline(_font, pos, text, align, width, fsize, 8 if not compact else 6, Color(0.06, 0.03, 0.02))
	draw_string(_font, pos, text, align, width, fsize, color)


func _draw() -> void:
	if fighter == null or _font == null:
		return
	var w := bar_w
	var off := Vector2.ZERO
	if _shake > 0.0:
		off = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * (4.0 if not compact else 2.0) * (_shake / 0.25)
	draw_set_transform(off, 0.0, Vector2.ONE)

	var mx := float(maxi(fighter.max_hp, 1))
	var real_frac := clampf(float(fighter.hp) / mx, 0.0, 1.0)

	# --- имя ---
	if compact:
		_txt(fighter.fighter_name, Vector2(0, 15), w, HORIZONTAL_ALIGNMENT_CENTER, _name_size, UIStyle.CREAM)
	else:
		var name_align := HORIZONTAL_ALIGNMENT_RIGHT if mirror else HORIZONTAL_ALIGNMENT_LEFT
		_txt(fighter.fighter_name, Vector2(14, 27), w - 28, name_align, _name_size, UIStyle.CREAM)

	# --- скруглённая рамка с тёмно-оранжевой обводкой; заливка идёт сразу под обводкой ---
	var frame := Rect2(0, _bar_y, w, _bar_h)
	var r_out := int(_bar_h / 2.0)
	var r_in := maxi(r_out - int(_border), 1)
	draw_style_box(UIStyle.flat_box(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 0, r_out), Rect2(frame.position + Vector2(0, 3), frame.size))   # тень
	draw_style_box(UIStyle.flat_box(Color(0.16, 0.08, 0.07), FRAME_COLOR, int(_border), r_out), frame)
	var inner := frame.grow(-_border)

	# --- «хвост» урона и заливка: плоский цвет, без бликов ---
	_draw_segment(inner, clampf(_trail / mx, 0.0, 1.0), TRAIL_COLOR, r_in)
	var frac := clampf(_fill / mx, 0.0, 1.0)
	if frac > 0.0:
		var c := _fill_color(real_frac)
		_draw_segment(inner, frac, c, r_in)          # одна целая «таблетка» — верх и низ закруглены одинаково
		# нижняя часть чуть темнее: тот же контур «таблетки», обрезанный по линии (без отдельных прямоугольников)
		var fw := inner.size.x * frac
		if fw >= 2.0:
			var fx := inner.position.x + (inner.size.x - fw if mirror else 0.0)
			var pill := _pill_points(Rect2(fx, inner.position.y, fw, inner.size.y), float(r_in))
			var low := _clip_below(pill, inner.position.y + inner.size.y * 0.66)
			if low.size() >= 3:
				draw_colored_polygon(low, c.darkened(0.22))
	# обводка поверх заливки: края заливки не выглядывают и всё выглядит ровно
	var ring := UIStyle.flat_box(Color(0, 0, 0, 0), FRAME_COLOR, int(_border), r_out)
	ring.draw_center = false
	draw_style_box(ring, frame)

	# --- «хп / макс. хп» белым по центру полоски ---
	_txt("%d / %d" % [fighter.hp, fighter.max_hp], Vector2(0, _bar_y + _bar_h * 0.5 + _hp_size * 0.36), w, HORIZONTAL_ALIGNMENT_CENTER, _hp_size, Color.WHITE)


## Закрашивает долю frac дорожки rect (слева направо или справа налево для mirror).
## full_w — полная ширина дорожки, если rect уже по ширине не совпадает (для верхней части заливки).
func _draw_segment(rect: Rect2, frac: float, color: Color, radius: int, full_w := -1.0) -> void:
	var fw := (full_w if full_w > 0.0 else rect.size.x) * frac
	if fw < 1.0:
		return
	var x := rect.position.x + (rect.size.x - fw if mirror else 0.0)
	draw_style_box(UIStyle.flat_box(color, Color(0, 0, 0, 0), 0, radius), Rect2(x, rect.position.y, fw, rect.size.y))


## Точки контура скруглённого прямоугольника (радиус не больше половины высоты и ширины).
func _pill_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) / 2.0)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(rect.position.x + r, rect.position.y + r), PI],
		[Vector2(rect.end.x - r, rect.position.y + r), PI * 1.5],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5],
	]
	for corner in corners:
		for i in 13:
			var a: float = corner[1] + (PI * 0.5) * float(i) / 12.0
			pts.append(corner[0] + Vector2(cos(a), sin(a)) * r)
	return pts


## Оставляет только часть многоугольника ниже линии y (отсечение по одной границе).
func _clip_below(pts: PackedVector2Array, y: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var a_in := a.y >= y
		var b_in := b.y >= y
		if a_in:
			out.append(a)
		if a_in != b_in:
			out.append(a.lerp(b, (y - a.y) / (b.y - a.y)))
	return out
