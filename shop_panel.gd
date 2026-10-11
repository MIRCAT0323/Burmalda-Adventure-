class_name ShopPanel
extends Control
## Окно магазина: кейсы. Нажми «Открыть» — кейс трясётся и выдаёт предмет.
## Кейсы настраиваются в game_data.gd (CASES), картинки: assets/cases/<id кейса>.png

signal closed

var _panel: Control
var _row: HBoxContainer
var _screen: Control = null
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
    box.add_theme_constant_override("separation", 14)
    _panel.add_child(box)

    # ---- заголовок: слева монеты, по центру название, справа закрыть ----
    var top := HBoxContainer.new()
    box.add_child(top)

    var left := HBoxContainer.new()
    left.custom_minimum_size = Vector2(CoinCounter.MAX_W, 0)
    left.alignment = BoxContainer.ALIGNMENT_BEGIN
    left.add_child(CoinCounter.new())
    top.add_child(left)

    var title := UIStyle.make_heading(GameSettings.t("shop").to_upper(), 46)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)

    var right := HBoxContainer.new()
    right.custom_minimum_size = Vector2(CoinCounter.MAX_W, 0)
    right.alignment = BoxContainer.ALIGNMENT_END
    var close := UIStyle.make_button("X", Vector2(70, 56), true)
    close.pressed.connect(close_panel)
    right.add_child(close)
    top.add_child(right)
    box.add_child(UIStyle.make_divider())

    # ---- кейсы ----
    _row = HBoxContainer.new()
    _row.add_theme_constant_override("separation", 20)
    _row.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_child(_row)
    for c in GameData.CASES:
        _row.add_child(_make_case_card(c))

    _animate_in()


# ================================================================ карточка кейса
func _make_case_card(c: Dictionary) -> Control:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(330, 0)
    var sb_normal := UIStyle.flat_box(Color(0.055, 0.038, 0.028, 0.97), Color(0.58, 0.44, 0.22), 3, 14, 12)
    var sb_hover := UIStyle.flat_box(Color(0.08, 0.055, 0.038, 0.98), UIStyle.AMBER_LIGHT, 3, 14, 12)
    card.add_theme_stylebox_override("panel", sb_normal)
    card.resized.connect(func(): card.pivot_offset = card.size / 2.0)
    card.mouse_entered.connect(func(): _hover_card(card, sb_hover, 1.025))
    card.mouse_exited.connect(func(): _hover_card(card, sb_normal, 1.0))

    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    card.add_child(v)

    # название и разделитель
    var name_label := Label.new()
    name_label.text = GameData.loc(c["name"])
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 32)
    name_label.add_theme_color_override("font_color", UIStyle.AMBER_LIGHT)
    name_label.add_theme_constant_override("outline_size", 8)
    v.add_child(name_label)
    v.add_child(_small_divider())

    # картинка кейса на подсвеченной сцене (кейс слегка «парит»)
    var stage := Control.new()
    stage.custom_minimum_size = Vector2(0, 130)
    stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
    v.add_child(stage)

    var glow := TextureRect.new()
    glow.texture = ItemTile.glow_texture(UIStyle.AMBER)
    glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    glow.stretch_mode = TextureRect.STRETCH_SCALE
    glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    glow.modulate.a = 0.9
    stage.add_child(glow)

    var case_tex := GameData.tex("res://assets/cases/%s.png" % str(c["id"]))
    var img: Control
    if case_tex != null:
        var tr := TextureRect.new()
        tr.texture = case_tex
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        img = tr
    else:
        var l := Label.new()
        l.text = "?"
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        l.add_theme_font_size_override("font_size", 90)
        img = l
    img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    img.offset_left = 20.0
    img.offset_right = -20.0
    img.offset_top = 12.0
    img.offset_bottom = -12.0
    img.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stage.add_child(img)
    var bob := create_tween().bind_node(img).set_loops()
    bob.tween_method(func(d: float):
        img.offset_top = 12.0 + d
        img.offset_bottom = -12.0 + d
    , -5.0, 5.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    bob.tween_method(func(d: float):
        img.offset_top = 12.0 + d
        img.offset_bottom = -12.0 + d
    , 5.0, -5.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    # цена: плашка
    var price := int(c["price"])
    var price_row := HBoxContainer.new()
    price_row.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_child(price_row)
    price_row.add_child(_make_price_pill(price))

    # что внутри
    var inside := Label.new()
    inside.text = GameSettings.t("inside_case")
    inside.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inside.add_theme_font_size_override("font_size", 20)
    inside.add_theme_color_override("font_color", Color(0.85, 0.76, 0.58, 0.9))
    v.add_child(inside)

    var drops := HFlowContainer.new()
    drops.alignment = FlowContainer.ALIGNMENT_CENTER
    drops.add_theme_constant_override("h_separation", 6)
    drops.add_theme_constant_override("v_separation", 6)
    v.add_child(drops)
    for d in c["drops"]:
        var item := GameData.item_by_id(str(d["id"]))
        if not item.is_empty():
            drops.add_child(_make_mini_slot(item))

    var open := UIStyle.make_button(GameSettings.t("open_case"), Vector2(0, 60))
    open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    open.pressed.connect(_open_screen.bind(str(c["id"])))
    v.add_child(open)
    return card


func _hover_card(card: Control, sb: StyleBoxFlat, s: float) -> void:
    card.add_theme_stylebox_override("panel", sb)
    var old = card.get_meta("hover_tween", null)
    if old != null and old.is_valid():
        old.kill()
    var tw := card.create_tween()
    card.set_meta("hover_tween", tw)
    tw.tween_property(card, "scale", Vector2(s, s), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _small_divider() -> TextureRect:
    var d := TextureRect.new()
    d.texture = GameData.tex("res://assets/ui/divider.png")
    d.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    d.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    d.custom_minimum_size = Vector2(0, 22)
    d.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return d


## Плашка цены: «Бесплатно» зелёная, платная с иконкой монеты.
func _make_price_pill(price: int) -> Control:
    var free := price <= 0
    var pill := PanelContainer.new()
    var sb := UIStyle.flat_box(Color(0.08, 0.2, 0.08, 0.95) if free else Color(0.09, 0.065, 0.04, 0.95), Color("4aa843") if free else UIStyle.AMBER, 2, 16, 0)
    sb.content_margin_left = 22
    sb.content_margin_right = 22
    sb.content_margin_top = 5
    sb.content_margin_bottom = 5
    pill.add_theme_stylebox_override("panel", sb)
    pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    pill.add_child(row)
    if not free:
        var coin := GameData.tex("res://assets/ui/coin.png")
        if coin != null:
            var ic := TextureRect.new()
            ic.texture = coin
            ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            ic.custom_minimum_size = Vector2(30, 30)
            ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
            row.add_child(ic)
    var l := Label.new()
    l.text = GameSettings.t("free").to_upper() if free else str(price)
    l.add_theme_font_size_override("font_size", 28)
    l.add_theme_color_override("font_color", Color("a6e896") if free else UIStyle.AMBER_LIGHT)
    row.add_child(l)
    return pill


## Плитка предмета для списка «Что внутри» (с рамкой редкости, название в подсказке).
func _make_mini_slot(item: Dictionary) -> Control:
    var t := ItemTile.new()
    t.setup(item, 52.0, 52.0, {"name": false})
    return t


# ================================================================ экран кейса
func _open_screen(case_id: String) -> void:
    if _screen != null and is_instance_valid(_screen):
        return
    var c := GameData.case_by_id(case_id)
    if c.is_empty():
        return
    _screen = CaseOpenScreen.new()
    _screen.setup(c)
    add_child(_screen)


# ================================================================ окно
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
