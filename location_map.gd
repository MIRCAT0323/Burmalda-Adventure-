extends Control
## Карта локации: уровни по порядку (змейкой), звёзды 1-3, последовательное открытие.
## Какая локация открыта — берётся из GameData.current_location (см. LOCATIONS в game_data.gd).
## Свой фон (поле "bg") и своя музыка (поле "music") — если файлов нет, берутся фон и музыка меню.

const MAP_SCENE := "res://world_map.tscn"
const BATTLE_SCENE := "res://battle_level.tscn"
const COLUMNS := 10

var _loc: Dictionary
var _loc_id := ""
var _count := 0
var _layer: Control
var _path: MapPath
var _nodes: Array = []
var _stars_label: Label
var _popup: Control = null
var _busy := false


func _ready() -> void:
	theme = UIStyle.make_theme()
	_loc = GameData.LOCATIONS[GameData.current_location]
	_loc_id = str(_loc["id"])
	_count = GameData.level_count(GameData.current_location)

	GameSettings.set_music(str(_loc.get("music", "")))
	_add_background()

	_path = MapPath.new()
	_path.smooth = true
	UIStyle._full_rect(_path)
	add_child(_path)

	_layer = Control.new()
	UIStyle._full_rect(_layer)
	add_child(_layer)

	for i in _count:
		var n := LevelNode.new()
		n.setup(i + 1)
		n.pressed.connect(_on_level_pressed.bind(i + 1))
		_layer.add_child(n)
		_nodes.append(n)
		UIStyle.appear(n, 0.2 + 0.015 * i, 0.4)

	_layer.resized.connect(_layout)
	_layout()
	_refresh()

	# заголовок и счётчик звёзд
	var head := VBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 0)
	add_child(head)
	head.add_child(UIStyle.make_heading(GameData.loc(_loc["name"]).to_upper(), 54))
	_stars_label = Label.new()
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars_label.add_theme_font_size_override("font_size", 26)
	_stars_label.add_theme_color_override("font_color", StarRow.GOLD)
	head.add_child(_stars_label)
	_update_stars_label()
	head.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 14)

	var back := UIStyle.make_button(GameSettings.t("back"), Vector2(170, 60), true)
	back.pressed.connect(_on_back)
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)


func _exit_tree() -> void:
	# при любом уходе с карты локации возвращается основная музыка
	GameSettings.set_music("")


func _add_background() -> void:
	var tex := GameData.tex(str(_loc.get("bg", "")))
	if tex == null:
		UIStyle.add_background(self)
		return
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	UIStyle._full_rect(bg)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.18)
	UIStyle._full_rect(shade)
	add_child(shade)
	var vignette := TextureRect.new()
	vignette.texture = GameData.tex(UIStyle.UI_DIR + "vignette.png")
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	UIStyle._full_rect(vignette)
	add_child(vignette)


## Положение уровня i (0-based): извилистая дорожка. Ряды идут змейкой (чётные слева направо,
## нечётные справа налево), внутри ряда путь «гуляет» вверх-вниз по волне, у каждого уровня небольшой
## случайный (но всегда одинаковый) сдвиг. Между уровнями дорога рисуется плавной кривой (см. MapPath).
func _fraction(i: int) -> Vector2:
	var row := i / COLUMNS
	var col := i % COLUMNS
	if row % 2 == 1:
		col = COLUMNS - 1 - col
	var rows := int(ceil(float(_count) / COLUMNS))
	var xf := 0.08 + 0.84 * float(col) / float(COLUMNS - 1)
	var base_y := 0.27 + (0.57 / maxf(float(rows - 1), 1.0)) * row if rows > 1 else 0.5
	# волна зависит от места по горизонтали (ряды не наезжают друг на друга), у рядов чуть разные изгибы
	var wave := sin(xf * 6.0) * 0.035 + sin(xf * 2.3 + float(row) * 0.9) * 0.012
	var jx := (_hash(i * 2) - 0.5) * 0.02
	var jy := (_hash(i * 2 + 1) - 0.5) * 0.024
	return Vector2(xf + jx, base_y + wave + jy)


## Детерминированное «случайное» число 0..1 по номеру (чтобы дорога каждый раз выглядела одинаково).
func _hash(n: int) -> float:
	return fposmod(sin(float(n) * 12.9898 + 78.233) * 43758.5453, 1.0)


func _layout() -> void:
	var s := _layer.size
	var fr := PackedVector2Array()
	for i in _nodes.size():
		var f := _fraction(i)
		_nodes[i].position = Vector2(s.x * f.x - LevelNode.W / 2.0, s.y * f.y - LevelNode.R - 4.0)
		fr.append(f)
	_path.fractions = fr
	_path.queue_redraw()


## Обновляет вид всех уровней по сохранённому прогрессу.
func _refresh() -> void:
	var current_found := false
	for i in _nodes.size():
		var lvl := i + 1
		var st := GameData.get_stars(_loc_id, lvl)
		var open := GameData.is_level_unlocked(_loc_id, lvl)
		var is_current := open and st == 0 and not current_found
		if is_current:
			current_found = true
		_nodes[i].set_state(st, not open, is_current)


func _update_stars_label() -> void:
	_stars_label.text = "%s: %d / %d" % [GameSettings.t("stars_total"), GameData.total_stars(_loc_id), _count * GameData.MAX_STARS]


func _on_level_pressed(level: int) -> void:
	if _popup != null and is_instance_valid(_popup):
		return
	if not GameData.is_level_unlocked(_loc_id, level):
		UIStyle.notice(self, GameSettings.t("level_locked"))
		return
	if GameData.has_battle(_loc_id, level):
		_busy = true
		GameData.current_level = level
		Transition.go(BATTLE_SCENE)
		return
	_open_popup(level)


# ---------------------------------------------------------------- окно уровня
func _open_popup(level: int) -> void:
	_popup = Control.new()
	_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_popup)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_close_popup())
	_popup.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	box.add_child(UIStyle.make_heading("%s %d" % [GameSettings.t("level").to_upper(), level], 46))
	box.add_child(UIStyle.make_divider())

	var best := StarRow.new()
	best.setup(GameData.get_stars(_loc_id, level), 22.0, 10.0)
	best.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(best)

	var hint := Label.new()
	hint.text = GameSettings.t("play_test_hint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", UIStyle.AMBER_LIGHT)
	box.add_child(hint)

	for n in range(1, GameData.MAX_STARS + 1):
		var b := UIStyle.make_button(GameSettings.t("play_test") % n, Vector2(520, 64))
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(_finish_level.bind(level, n))
		box.add_child(b)

	var close := UIStyle.make_button(GameSettings.t("close"), Vector2(520, 64))
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_popup)
	box.add_child(close)

	_popup.modulate.a = 0.0
	_popup.create_tween().tween_property(_popup, "modulate:a", 1.0, 0.15)


func _finish_level(level: int, stars: int) -> void:
	GameData.complete_level(_loc_id, level, stars)
	_close_popup()
	_refresh()
	_update_stars_label()
	UIStyle.notice(self, GameSettings.t("level_done") % level)


func _close_popup() -> void:
	if _popup != null and is_instance_valid(_popup):
		_popup.queue_free()
	_popup = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _popup != null and is_instance_valid(_popup):
			_close_popup()
		else:
			_on_back()


func _on_back() -> void:
	if _busy:
		return
	_busy = true
	Transition.go(MAP_SCENE)
