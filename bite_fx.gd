class_name BiteFx
extends Node2D
## Эффект укуса на герое. Если задана картинка (assets/NPC/<id>_bite_fx.png) — показывается она
## (с «хлопком» и затуханием), иначе рисуются две челюсти с клыками, которые схлопываются.

const IMG_HEIGHT := 190.0   # высота картинки укуса на экране (px)

var tex: Texture2D = null
var t := 0.0:
	set(v):
		t = v
		queue_redraw()


func play() -> void:
	var tw := create_tween()
	tw.tween_property(self, "t", 1.0, 0.38)
	tw.tween_callback(queue_free)


func _draw() -> void:
	if tex != null:
		var k := IMG_HEIGHT / float(tex.get_height())
		var pop := 1.0 + 0.35 * (1.0 - clampf(t * 5.0, 0.0, 1.0))   # быстрый «хлопок» в начале
		var a := 1.0 - maxf(0.0, t - 0.6) / 0.4
		var sz := Vector2(tex.get_width(), tex.get_height()) * k * pop
		draw_texture_rect(tex, Rect2(-sz / 2.0, sz), false, Color(1, 1, 1, a))
		return
	var gap := lerpf(78.0, 4.0, clampf(t * 1.7, 0.0, 1.0))
	var alpha := 1.0 - maxf(0.0, t - 0.6) / 0.4
	var cream := Color(1.0, 0.97, 0.88, alpha)
	var edge := Color(0.12, 0.05, 0.04, alpha)
	var gum := Color(0.62, 0.12, 0.16, alpha)
	var half := gap / 2.0
	# десны
	draw_rect(Rect2(-64.0, -half - 16.0, 128.0, 16.0), gum)
	draw_rect(Rect2(-64.0, half, 128.0, 16.0), gum)
	for i in 5:
		var x := -48.0 + 24.0 * i
		var up := PackedVector2Array([Vector2(x - 10.0, -half), Vector2(x + 10.0, -half), Vector2(x, -half + 34.0)])
		var down := PackedVector2Array([Vector2(x - 10.0, half), Vector2(x + 10.0, half), Vector2(x, half - 34.0)])
		draw_colored_polygon(up, cream)
		draw_colored_polygon(down, cream)
		draw_polyline(PackedVector2Array([up[0], up[2], up[1]]), edge, 2.0, true)
		draw_polyline(PackedVector2Array([down[0], down[2], down[1]]), edge, 2.0, true)
