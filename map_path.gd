class_name MapPath
extends Control
## Пунктирная дорога между локациями на карте мира.

var fractions := PackedVector2Array()
var color := Color("e0902a")
var shadow := Color(0.08, 0.04, 0.02, 0.85)
var smooth := false          # true — дорога идёт плавной кривой через все точки (карта локации)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if smooth and fractions.size() >= 2:
		var pts := _curve_points()
		_dashed_polyline(pts, shadow, 11.0, 14.0, 12.0)
		_dashed_polyline(pts, color, 6.0, 14.0, 12.0)
		return
	for i in range(fractions.size() - 1):
		var a := fractions[i] * size
		var b := fractions[i + 1] * size
		draw_dashed_line(a, b, shadow, 11.0, 18.0)
		draw_dashed_line(a, b, color, 6.0, 18.0)


## Точки гладкой кривой (Catmull-Rom) через все уровни по порядку.
func _curve_points() -> PackedVector2Array:
	var p := PackedVector2Array()
	for f in fractions:
		p.append(f * size)
	var out := PackedVector2Array()
	var n := p.size()
	for i in range(n - 1):
		var p0 := p[maxi(i - 1, 0)]
		var p1 := p[i]
		var p2 := p[i + 1]
		var p3 := p[mini(i + 2, n - 1)]
		for k in 12:
			out.append(p1.cubic_interpolate(p2, p0, p3, float(k) / 12.0))
	out.append(p[n - 1])
	return out


## Пунктир вдоль ломаной (draw_dashed_line умеет только прямые).
func _dashed_polyline(pts: PackedVector2Array, col: Color, width: float, dash: float, gap: float) -> void:
	var drawing := true
	var left := dash
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		var pos := 0.0
		while pos < seg:
			var step := minf(left, seg - pos)
			if drawing:
				draw_line(a.lerp(b, pos / seg), a.lerp(b, (pos + step) / seg), col, width, true)
			pos += step
			left -= step
			if left <= 0.001:
				drawing = not drawing
				left = dash if drawing else gap
