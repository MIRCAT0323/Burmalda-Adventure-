class_name Fighter
extends Node2D
## Боец на арене: картинка, полоска здоровья, покачивание при ходьбе, разворот влево/вправо,
## «выпады» (удар / укус). Точка (0,0) — стопы бойца; картинка стоит на ней и растёт вверх.

var body: Node2D
var sprite: Sprite2D
var natural_dir := 1        # куда смотрит исходная картинка: +1 вправо (герой), -1 влево (враги)
var height := 300.0
var max_hp := 100
var hp := 100
var fighter_name := ""
var bar_color := Color("4aa843")
var walking := false
var dead := false
var facing := 1             # куда боец смотрит сейчас в мире (+1 вправо, -1 влево)
var fx_x := 0.0             # смещение вперёд/назад (выпад)
var fx_rot := 0.0           # наклон (замах, выпад)
var jump_y := 0.0           # высота прыжка над землёй (px, вверх)

var _k := 1.0               # масштаб картинки под нужную высоту
var _flip := 1.0            # текущий разворот (плавно от -1 до 1)
var _flip_target := 1.0
var _phase := 0.0           # фаза покачивания при ходьбе
var _t := 0.0
var _pose_tween: Tween
var _flash_tween: Tween
var _font: Font


func setup(tex: Texture2D, h: float, natural: int, hp_max: int, display_name: String, color: Color) -> void:
	height = h
	natural_dir = natural
	facing = natural
	_flip = 1.0
	_flip_target = 1.0
	max_hp = hp_max
	hp = hp_max
	fighter_name = display_name
	bar_color = color
	body = Node2D.new()
	add_child(body)
	sprite = Sprite2D.new()
	sprite.centered = false
	body.add_child(sprite)
	set_texture(tex)
	_font = load(UIStyle.FONT_PATH) if ResourceLoader.exists(UIStyle.FONT_PATH) else ThemeDB.fallback_font
	queue_redraw()


## Меняет картинку (например, на «удар»), высота остаётся прежней.
func set_texture(tex: Texture2D) -> void:
	if tex == null:
		return
	sprite.texture = tex
	_k = height / float(tex.get_height())
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())   # стопы по центру внизу


## Повернуть бойца: dir = +1 вправо, -1 влево. Картинка плавно «переворачивается».
func face(dir: int) -> void:
	if dir == 0:
		return
	facing = dir
	_flip_target = float(dir * natural_dir)


func _process(delta: float) -> void:
	if body == null:
		return
	_t += delta
	_flip = move_toward(_flip, _flip_target, delta * 12.0)
	var sway := 0.0
	var bob := 0.0
	var breathe := 1.0
	if dead:
		pass
	elif walking:
		_phase += delta * 12.0
		sway = sin(_phase) * 0.05                 # качается из стороны в сторону
		bob = -absf(sin(_phase)) * height * 0.03            # и подпрыгивает на шагах (высота подскока зависит от роста бойца)
	else:
		_phase = 0.0
		breathe = 1.0 + sin(_t * 2.2) * 0.012     # лёгкое «дыхание» на месте
	body.rotation = lerp_angle(body.rotation, sway + fx_rot, minf(1.0, delta * 20.0)) if not dead else fx_rot
	body.position = Vector2(fx_x, bob - jump_y)
	sprite.scale = Vector2(_flip * _k, _k * breathe)


## Плавно прийти в позу: смещение вперёд (в сторону взгляда) и наклон; dir берётся из facing.
func pose(forward_px: float, lean: float, duration: float, trans := Tween.TRANS_SINE) -> Tween:
	if _pose_tween != null and _pose_tween.is_valid():
		_pose_tween.kill()
	_pose_tween = create_tween().set_parallel(true).set_trans(trans).set_ease(Tween.EASE_OUT)
	_pose_tween.tween_property(self, "fx_x", forward_px * facing, duration)
	_pose_tween.tween_property(self, "fx_rot", lean * facing, duration)
	return _pose_tween


## Быстрый выпад вперёд и возврат (удар).
func lunge(forward_px: float, duration: float) -> void:
	if _pose_tween != null and _pose_tween.is_valid():
		_pose_tween.kill()
	_pose_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_pose_tween.tween_property(self, "fx_x", forward_px * facing, duration * 0.4).set_ease(Tween.EASE_OUT)
	_pose_tween.tween_property(self, "fx_x", 0.0, duration * 0.6).set_ease(Tween.EASE_IN_OUT)
	_pose_tween.parallel().tween_property(self, "fx_rot", 0.0, duration)


func take_hit(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	queue_redraw()
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	body.modulate = Color(1.0, 0.35, 0.35)
	_flash_tween = create_tween()
	_flash_tween.tween_property(body, "modulate", Color.WHITE, 0.25)


## Подсветка (например, замах перед укусом).
func tint(c: Color, duration := 0.15) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(body, "modulate", c, duration)


## Падение: боец заваливается назад (от направления взгляда).
func fall(fade := true) -> void:
	dead = true
	walking = false
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	pose(-50.0, -1.3, 0.55, Tween.TRANS_QUAD)
	if fade:
		create_tween().tween_property(body, "modulate:a", 0.0, 0.7).set_delay(0.45)


func world_center() -> Vector2:
	return global_position + Vector2(0.0, -height * 0.55)


func _draw() -> void:
	# тень под ногами
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, height * 0.28, Color(0, 0, 0, 0.38))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
