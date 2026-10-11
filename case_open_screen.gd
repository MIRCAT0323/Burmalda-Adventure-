class_name CaseOpenScreen
extends Control
## Экран открытия кейса в стиле КС: картинка кейса, список «Содержит один из следующих»,
## кнопка «Открыть» -> рулетка прокручивается, замедляется и останавливается на выпавшем предмете.
## Настройки рулетки — константы ниже.

signal closed

const TILE_W := 160.0        # ширина плитки в рулетке
const TILE_H := 160.0
const GAP := 8.0             # расстояние между плитками
const COUNT := 70            # сколько плиток в ленте
const WIN_INDEX := 58        # на какой плитке останавливается лента
const SPIN_TIME := 6.5       # длительность прокрутки, секунды

var _case: Dictionary = {}
var _panel: Control
var _case_img: Control
var _roulette: Control
var _strip: Control
var _info: Label
var _open_btn: Button
var _close_btn: Button
var _spinning := false
var _closing := false
var _last_tick := -1
var _tick_cooldown := 0.0


func setup(c: Dictionary) -> void:
	_case = c


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(1120, 0)
	center.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)

	# ---- заголовок: слева монеты ----
	var top := HBoxContainer.new()
	box.add_child(top)
	var left := HBoxContainer.new()
	left.custom_minimum_size = Vector2(CoinCounter.MAX_W, 0)
	left.add_child(CoinCounter.new())
	top.add_child(left)
	var title := UIStyle.make_heading(GameSettings.t("unlock_case").to_upper(), 44)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var right := Control.new()
	right.custom_minimum_size = Vector2(CoinCounter.MAX_W, 0)
	top.add_child(right)

	var sub := Label.new()
	sub.text = GameData.loc(_case["name"])
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 32)
	sub.add_theme_color_override("font_color", UIStyle.AMBER_LIGHT)
	box.add_child(sub)

	# ---- сцена: сначала картинка кейса, при открытии — рулетка ----
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 190)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(stage)

	var case_tex := GameData.tex("res://assets/cases/%s.png" % str(_case["id"]))
	if case_tex != null:
		var tr := TextureRect.new()
		tr.texture = case_tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_case_img = tr
	else:
		var q := Label.new()
		q.text = "?"
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.add_theme_font_size_override("font_size", 100)
		_case_img = q
	_case_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_case_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_case_img)

	_build_roulette_frame(stage)

	# ---- что внутри ----
	var contains := Label.new()
	contains.text = GameSettings.t("contains")
	contains.add_theme_font_size_override("font_size", 22)
	contains.add_theme_color_override("font_color", Color(0.8, 0.72, 0.55, 0.85))
	box.add_child(contains)

	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	box.add_child(flow)
	for d in _case["drops"]:
		var item := GameData.item_by_id(str(d["id"]))
		if not item.is_empty():
			flow.add_child(_make_tile(item, 108.0, 108.0, 12))

	# ---- строка: цена / результат ----
	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.custom_minimum_size = Vector2(0, 40)
	_info.add_theme_font_size_override("font_size", 28)
	box.add_child(_info)
	_show_price()

	# ---- кнопки ----
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 16)
	box.add_child(btns)
	_open_btn = UIStyle.make_button(GameSettings.t("open_case"), Vector2(300, 66))
	_open_btn.pressed.connect(_on_open_pressed)
	btns.add_child(_open_btn)
	_close_btn = UIStyle.make_button(GameSettings.t("close"), Vector2(240, 66))
	_close_btn.pressed.connect(_try_close)
	btns.add_child(_close_btn)

	_animate_in()


func _show_price() -> void:
	var price := int(_case["price"])
	_info.text = GameSettings.t("free") if price <= 0 else "%d %s" % [price, GameSettings.t("coins")]
	_info.add_theme_color_override("font_color", Color("8fe083") if price <= 0 else UIStyle.CREAM)


# ================================================================ рулетка
func _build_roulette_frame(stage: Control) -> void:
	_roulette = Control.new()
	_roulette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_roulette.clip_contents = true
	_roulette.visible = false
	_roulette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_roulette)

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", UIStyle.flat_box(Color(0.05, 0.035, 0.025, 0.95), Color(0.46, 0.44, 0.50), 2, 6))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roulette.add_child(bg)

	_strip = Control.new()   # не контейнер: плитки ставятся вручную и не могут «раздуться»
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_roulette.add_child(_strip)

	# затемнение по краям ленты
	for side in 2:
		var g := Gradient.new()
		var dark := Color(0.05, 0.035, 0.025, 0.95)
		var clear := Color(0.05, 0.035, 0.025, 0.0)
		g.set_color(0, dark if side == 0 else clear)
		g.set_color(1, clear if side == 0 else dark)
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(1, 0)
		var fade := TextureRect.new()
		fade.texture = gt
		fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fade.stretch_mode = TextureRect.STRETCH_SCALE
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fade.anchor_top = 0.0
		fade.anchor_bottom = 1.0
		fade.anchor_left = 0.0 if side == 0 else 1.0
		fade.anchor_right = fade.anchor_left
		fade.offset_left = 0.0 if side == 0 else -150.0
		fade.offset_right = 150.0 if side == 0 else 0.0
		fade.offset_top = 0.0
		fade.offset_bottom = 0.0
		_roulette.add_child(fade)

	# центральная линия-указатель
	var line := ColorRect.new()
	line.color = UIStyle.AMBER_LIGHT
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.anchor_left = 0.5
	line.anchor_right = 0.5
	line.anchor_top = 0.0
	line.anchor_bottom = 1.0
	line.offset_left = -2.0
	line.offset_right = 2.0
	_roulette.add_child(line)


## Плитка предмета (картинка, название, полоска редкости). Размер строго фиксированный.
func _make_tile(item: Dictionary, w: float, h: float, font_size: int) -> Control:
	var t := ItemTile.new()
	t.setup(item, w, h, {"name": true, "name_font": font_size})
	return t


## Случайный предмет из дропа кейса (только для «массовки» в ленте).
func _random_drop_item() -> Dictionary:
	var total := 0.0
	for d in _case["drops"]:
		total += float(d["weight"])
	var roll := randf() * total
	for d in _case["drops"]:
		roll -= float(d["weight"])
		if roll < 0.0:
			return GameData.item_by_id(str(d["id"]))
	return GameData.item_by_id(str(_case["drops"][0]["id"]))


func _build_strip(winner: Dictionary) -> void:
	for c in _strip.get_children():
		_strip.remove_child(c)
		c.queue_free()
	for i in COUNT:
		var item := winner if i == WIN_INDEX else _random_drop_item()
		var tile := _make_tile(item, TILE_W, TILE_H, 16)
		tile.position = Vector2(float(i) * (TILE_W + GAP), 0.0)
		_strip.add_child(tile)
	_strip.size = Vector2(float(COUNT) * (TILE_W + GAP) - GAP, TILE_H)


## Тик при прохождении каждой плитки под центральной линией (звук assets/sounds/tick.wav).
func _process(delta: float) -> void:
	if not _spinning:
		return
	_tick_cooldown -= delta
	var idx := floori((_roulette.size.x / 2.0 - _strip.position.x) / (TILE_W + GAP))
	if idx != _last_tick:
		_last_tick = idx
		if _tick_cooldown <= 0.0:
			GameSettings.play_sfx("tick", -8.0)
			_tick_cooldown = 0.04


func _on_open_pressed() -> void:
	if _spinning or _closing:
		return
	if not GameData.can_afford(int(_case["price"])):
		UIStyle.notice(self, GameSettings.t("not_enough_coins"))
		return
	# предмет определяется сразу (цена списывается), лента лишь красиво «доезжает» до него
	var result := GameData.open_case(str(_case["id"]))
	if not bool(result.get("ok", false)):
		return
	_spinning = true
	_last_tick = -1
	GameSettings.play_sfx("case_open")   # звук открытия кейса
	_dim_buttons(true)
	_info.text = ""

	_build_strip(result["item"])
	_case_img.visible = false
	_roulette.visible = true
	_roulette.modulate.a = 0.0
	create_tween().tween_property(_roulette, "modulate:a", 1.0, 0.2)
	await get_tree().process_frame
	if not is_inside_tree():
		return

	var w := _roulette.size.x
	var y := maxf((_roulette.size.y - TILE_H) / 2.0, 0.0)
	_strip.position = Vector2(w / 2.0 - TILE_W / 2.0, y)
	var stop_offset := randf_range(-0.38, 0.38) * TILE_W   # остановка не строго по центру плитки, как в КС
	var target_x := w / 2.0 - (WIN_INDEX * (TILE_W + GAP) + TILE_W / 2.0 + stop_offset)
	var tw := create_tween()
	tw.tween_property(_strip, "position:x", target_x, SPIN_TIME).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not is_inside_tree():
		return
	_land(result)


func _land(result: Dictionary) -> void:
	var item: Dictionary = result["item"]
	var duplicate := bool(result["duplicate"])
	var refund := int(result["refund"])
	if refund > 0:
		GameData.add_coins(refund)   # дубликат: возвращается половина цены кейса
	# остальные плитки гаснут, выпавшая увеличивается
	for i in _strip.get_child_count():
		var t: Control = _strip.get_child(i)
		if i == WIN_INDEX:
			t.pivot_offset = t.size / 2.0
			create_tween().tween_property(t, "scale", Vector2(1.08, 1.08), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			create_tween().tween_property(t, "modulate", Color(0.45, 0.45, 0.45, 1.0), 0.4)

	GameSettings.play_sfx("item_drop")   # звук выпадения предмета
	var status := GameSettings.t("duplicate_item") if duplicate else GameSettings.t("new_item")
	_info.text = "%s - %s" % [GameData.loc(item["name"]), status]
	_info.add_theme_color_override("font_color", GameData.rarity_color(item).lerp(Color.WHITE, 0.35))
	_open_btn.text = GameSettings.t("open_again").to_upper()
	_spinning = false
	_dim_buttons(false)


func _dim_buttons(on: bool) -> void:
	var a := 0.45 if on else 1.0
	_open_btn.modulate.a = a
	_close_btn.modulate.a = a


# ================================================================ окно
func _animate_in() -> void:
	modulate.a = 0.0
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.95, 0.95)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _try_close() -> void:
	if _spinning or _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func():
		closed.emit()
		queue_free()
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_try_close()
		get_viewport().set_input_as_handled()
