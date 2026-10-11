class_name InventoryPanel
extends Control
## Окно инвентаря: портрет героя, слоты экипировки (как в Майнкрафте, только картинки),
## вкладки быстрого поиска, строка поиска и карточки предметов.
## Карточки и слоты рисует ItemTile (item_tile.gd).

signal closed

const SLOT_SIZE := 94.0
const PORTRAIT_SIZE := 260.0   # квадратный портрет героя
const CARD_W := 128.0          # размер карточки предмета
const CARD_H := 172.0
const LEFT_SLOTS := ["helmet", "chest", "legs", "boots"]
const RIGHT_SLOTS := ["weapon", "ability", "pet", "artifact"]
const TAB_ORDER := ["pets", "weapons", "armor", "abilities", "artifacts"]

var _panel: Control
var _stat_level: Label
var _stat_damage: Label
var _stat_hp: Label
var _stat_chips := {}     # подпись -> плашка (для анимации при смене числа)
var _stat_last := {}      # подпись -> последний показанный текст
var _slot_tiles := {}     # слот -> ItemTile
var _search: LineEdit
var _grid: GridContainer
var _empty: Label
var _tab_buttons := {}    # вкладка -> Button
var _active_tab := ""
var _closing := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	center.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	# ---- заголовок и кнопка закрытия ----
	var top := HBoxContainer.new()
	box.add_child(top)
	var left := HBoxContainer.new()
	left.custom_minimum_size = Vector2(CoinCounter.MAX_W, 0)
	left.alignment = BoxContainer.ALIGNMENT_BEGIN
	left.add_child(CoinCounter.new())   # счётчик валюты
	top.add_child(left)
	var title := UIStyle.make_heading(GameSettings.t("inventory").to_upper(), 46)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var right_top := HBoxContainer.new()
	right_top.custom_minimum_size = Vector2(CoinCounter.MAX_W, 0)
	right_top.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(right_top)
	var close := UIStyle.make_button("X", Vector2(70, 56), true)
	close.pressed.connect(close_panel)
	right_top.add_child(close)
	box.add_child(UIStyle.make_divider())

	# ---- тело: слева герой, справа предметы ----
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 34)
	box.add_child(body)

	body.add_child(_build_hero_column())
	body.add_child(_build_items_column())

	_refresh_slots()
	_refresh_stats()
	_refresh_items()
	_animate_in()


# ================================================================ герой
func _build_hero_column() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)

	# Lvl / урон / хп над картинкой — три плашки
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(stats)
	_stat_level = _make_stat_chip(stats, UIStyle.AMBER_LIGHT)
	_stat_damage = _make_stat_chip(stats, Color("ff9a80"))
	_stat_hp = _make_stat_chip(stats, Color("a6e896"))

	var equip := HBoxContainer.new()
	equip.add_theme_constant_override("separation", 12)
	col.add_child(equip)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	for slot in LEFT_SLOTS:
		left.add_child(_make_slot(slot))
	equip.add_child(left)

	equip.add_child(_make_portrait())

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	for slot in RIGHT_SLOTS:
		right.add_child(_make_slot(slot))
	equip.add_child(right)
	return col


## Плашка с характеристикой: тёмная, с рамкой цвета характеристики.
func _make_stat_chip(parent: Control, color: Color) -> Label:
	var chip := PanelContainer.new()
	var sb := UIStyle.flat_box(Color(0.06, 0.04, 0.03, 0.94), color.darkened(0.45), 2, 12, 0)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	chip.add_theme_stylebox_override("panel", sb)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(chip)

	var l := Label.new()
	l.custom_minimum_size = Vector2(92, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 1.0))
	l.add_theme_constant_override("outline_size", 5)
	chip.add_child(l)
	_stat_chips[l] = chip
	return l


func _make_portrait() -> Control:
	# квадратный портрет в рамке + табличка с именем героя и ником
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(PORTRAIT_SIZE, SLOT_SIZE * 4.0 + 8.0 * 3.0)
	col.add_theme_constant_override("separation", 10)

	var ch := GameData.character()
	var frame := PortraitFrame.new()
	frame.setup(GameData.tex(str(ch.get("image", ""))), PORTRAIT_SIZE, str(ch.get("name", "?")).left(1))
	col.add_child(frame)

	var plate := PanelContainer.new()
	plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	plate.add_theme_stylebox_override("panel", _box(Color(0.06, 0.04, 0.03, 0.95), Color(0.79, 0.54, 0.18), 3, 8, 8))
	col.add_child(plate)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", 2)
	plate.add_child(names)
	var hero := Label.new()
	hero.text = str(ch.get("name", "?"))
	hero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero.add_theme_font_size_override("font_size", 28)
	hero.add_theme_color_override("font_color", UIStyle.AMBER_LIGHT)
	names.add_child(hero)
	var nick := Label.new()
	nick.text = GameSettings.display_name()
	nick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nick.clip_text = true
	nick.add_theme_font_size_override("font_size", 20)
	nick.add_theme_color_override("font_color", Color(0.8, 0.72, 0.55, 0.85))
	names.add_child(nick)
	return col


## Слот героя: показывает ТОЛЬКО картинку надетого предмета (у пустого слота бледная подпись).
func _make_slot(slot: String) -> Control:
	var tile := ItemTile.new()
	tile.setup({}, SLOT_SIZE, SLOT_SIZE, {"slot": true, "interactive": true, "empty_text": GameSettings.t("slot_" + slot)})
	tile.pressed.connect(func():
		if tile.item.is_empty():
			return
		GameData.unequip(slot)
		_refresh_slots()
		_refresh_stats()
		_refresh_items()
	)
	_slot_tiles[slot] = tile
	return tile


# ================================================================ предметы
func _build_items_column() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(560, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)

	_search = LineEdit.new()
	_search.placeholder_text = GameSettings.t("search_item")
	_search.clear_button_enabled = true
	_search.add_theme_font_size_override("font_size", 26)
	_search.text_changed.connect(func(_t: String): _refresh_items())
	col.add_child(_search)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	col.add_child(tabs)
	for key in TAB_ORDER:
		var b := UIStyle.make_tab_button(GameSettings.t("tab_" + key))
		b.add_theme_font_size_override("font_size", 17)
		b.toggled.connect(_on_tab_toggled.bind(key))
		tabs.add_child(b)
		_tab_buttons[key] = b

	# «доска» с карточками: тёмная вдавленная панель
	var board := PanelContainer.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_theme_stylebox_override("panel", UIStyle.flat_box(Color(0.045, 0.032, 0.024, 0.8), Color(0.40, 0.38, 0.43), 2, 10, 8))
	col.add_child(board)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 270)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board.add_child(scroll)

	var holder := VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(holder)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_child(_grid)

	_empty = Label.new()
	_empty.text = GameSettings.t("nothing_found")
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.add_theme_color_override("font_color", Color(0.8, 0.72, 0.55, 0.7))
	_empty.custom_minimum_size = Vector2(360, 220)
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.add_theme_font_size_override("font_size", 34)
	_empty.visible = false
	holder.add_child(_empty)
	return col


func _on_tab_toggled(on: bool, key: String) -> void:
	if on:
		_active_tab = key
		for k in _tab_buttons:
			if k != key:
				_tab_buttons[k].set_pressed_no_signal(false)
	elif _active_tab == key:
		_active_tab = ""
	_refresh_items()


func _refresh_items() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var q := _search.text.strip_edges().to_lower()
	var shown := 0
	for item in GameData.ITEMS:
		if not GameData.owns(str(item["id"])):
			continue
		if _active_tab != "" and not (str(item["slot"]) in GameData.TABS[_active_tab]):
			continue
		if q != "" and GameData.loc(item["name"]).to_lower().find(q) == -1:
			continue
		_grid.add_child(_make_item_card(item))
		shown += 1
	_empty.text = GameSettings.t("nothing_found") if GameData.has_any_items() else GameSettings.t("inventory_empty")
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.visible = shown == 0


## Карточка предмета: квадратная картинка по центру, название и характеристики подгоняются под ширину.
func _make_item_card(item: Dictionary) -> Control:
	var is_on: bool = GameData.equipped_id(str(item["slot"])) == str(item["id"])
	var tile := ItemTile.new()
	tile.setup(item, CARD_W, CARD_H, {"name": true, "stats": true, "interactive": true, "equipped": is_on, "name_font": 15})
	tile.pressed.connect(_on_item_pressed.bind(str(item["id"])))
	return tile


func _on_item_pressed(id: String) -> void:
	var item := GameData.item_by_id(id)
	if item.is_empty():
		return
	if GameData.equipped_id(str(item["slot"])) == id:
		GameData.unequip(str(item["slot"]))
	else:
		GameData.equip(id)
	_refresh_slots()
	_refresh_stats()
	_refresh_items()


# ================================================================ обновление
func _refresh_slots() -> void:
	for slot in GameData.SLOTS:
		var tile: ItemTile = _slot_tiles[slot]
		tile.set_item(GameData.equipped_item(slot))


func _refresh_stats() -> void:
	var st := GameData.get_stats()
	_set_stat(_stat_level, "%s %d" % [GameSettings.t("stat_level"), int(st["level"])])
	_set_stat(_stat_damage, "%s %d" % [GameSettings.t("stat_damage"), int(st["damage"])])
	_set_stat(_stat_hp, "%s %d" % [GameSettings.t("stat_hp"), int(st["hp"])])


## Меняет текст плашки; если число изменилось, плашка коротко «подпрыгивает».
func _set_stat(label: Label, text: String) -> void:
	var old = _stat_last.get(label, null)
	label.text = text
	_stat_last[label] = text
	if old != null and old != text:
		var chip: Control = _stat_chips[label]
		chip.pivot_offset = chip.size / 2.0
		var tw := chip.create_tween()
		tw.tween_property(chip, "scale", Vector2(1.14, 1.14), 0.09).set_trans(Tween.TRANS_SINE)
		tw.tween_property(chip, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ================================================================ оформление
func _box(bg: Color, border: Color, width: int, radius: int, margin: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


func _animate_in() -> void:
	modulate.a = 0.0
	await get_tree().process_frame
	await get_tree().process_frame     # даём окну спокойно построиться, потом плавно показываем
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func close_panel() -> void:
	if _closing:
		return
	_closing = true
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(_panel, "scale", Vector2(0.94, 0.94), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		closed.emit()
		queue_free()
	)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_panel()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()
