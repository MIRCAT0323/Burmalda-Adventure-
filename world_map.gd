extends Control
## Карта мира: круглые локации, кнопка «Назад», «Магазин» и «Инвентарь».

const MENU_SCENE := "res://main_menu.tscn"
const LOCATION_SCENE := "res://location_map.tscn"
const MAP_PATH := "res://assets/map.png"
const NODE_W := 300.0
const CIRCLE := 115.0

var _layer: Control
var _path: MapPath
var _nodes: Array = []
var _inventory: Control = null
var _shop: Control = null
var _busy := false


func _ready() -> void:
    theme = UIStyle.make_theme()
    _add_background()

    _path = MapPath.new()
    UIStyle._full_rect(_path)
    add_child(_path)

    _layer = Control.new()
    UIStyle._full_rect(_layer)
    add_child(_layer)

    var i := 0
    for loc in GameData.LOCATIONS:
        var node := VBoxContainer.new()
        node.custom_minimum_size = Vector2(NODE_W, 0)
        node.mouse_filter = Control.MOUSE_FILTER_IGNORE
        node.add_theme_constant_override("separation", 6)
        _layer.add_child(node)
        _nodes.append(node)

        var slot := CircleSlot.new()
        slot.setup(GameData.tex(str(loc["image"])), CIRCLE, "?")
        slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        slot.pressed.connect(_on_location_pressed.bind(i))
        var is_locked := GameData.level_count(i) <= 0
        slot.locked = is_locked
        node.add_child(slot)

        var name_label := Label.new()
        name_label.text = GameData.loc(loc["name"])
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.add_theme_font_size_override("font_size", 30)
        name_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.74) if is_locked else UIStyle.CREAM)
        name_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 1.0))
        name_label.add_theme_constant_override("outline_size", 8)
        node.add_child(name_label)

        var lvl_label := Label.new()
        lvl_label.text = "" if is_locked else str(loc["levels"])
        lvl_label.visible = not is_locked
        lvl_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lvl_label.add_theme_font_size_override("font_size", 24)
        lvl_label.add_theme_color_override("font_color", Color(0.62, 0.62, 0.66) if is_locked else UIStyle.AMBER_LIGHT)
        lvl_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 1.0))
        lvl_label.add_theme_constant_override("outline_size", 7)
        node.add_child(lvl_label)

        UIStyle.appear(node, 0.35 + 0.15 * i, 0.55)
        i += 1

    _layer.resized.connect(_layout)
    _layout()

    # --- сверху слева: назад ---
    var back := UIStyle.make_button(GameSettings.t("back"), Vector2(170, 60), true)
    back.pressed.connect(_on_back)
    add_child(back)
    back.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)

    # --- сверху справа: магазин и инвентарь ---
    var right := HBoxContainer.new()
    right.add_theme_constant_override("separation", 12)
    add_child(right)
    var shop := UIStyle.make_button(GameSettings.t("shop"), Vector2(170, 60), true)
    shop.pressed.connect(_open_shop)
    right.add_child(shop)
    var inv := UIStyle.make_button(GameSettings.t("inventory"), Vector2(170, 60), true)
    inv.pressed.connect(_open_inventory)
    right.add_child(inv)
    right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)


func _add_background() -> void:
    var tex := GameData.tex(MAP_PATH)
    if tex == null:
        UIStyle.add_background(self)
        return
    var map := TextureRect.new()
    map.texture = tex
    map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    UIStyle._full_rect(map)
    add_child(map)
    var vignette := TextureRect.new()
    vignette.texture = GameData.tex("res://assets/ui/vignette.png")
    vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    vignette.stretch_mode = TextureRect.STRETCH_SCALE
    UIStyle._full_rect(vignette)
    add_child(vignette)


## Расставляет локации по их положению (pos в game_data.gd) и рисует дорогу.
func _layout() -> void:
    var s := _layer.size
    var fr := PackedVector2Array()
    for i in _nodes.size():
        var p: Vector2 = GameData.LOCATIONS[i]["pos"]
        _nodes[i].position = Vector2(s.x * p.x - NODE_W / 2.0, s.y * p.y - CIRCLE / 2.0)
        fr.append(p)
    _path.fractions = fr
    _path.queue_redraw()


func _on_location_pressed(index: int) -> void:
    if _busy or _overlay_open():
        return
    if GameData.level_count(index) <= 0:
        return   # локация закрыта: на ней серый круг с замком, без надписей
    _busy = true
    GameData.current_location = index
    Transition.go(LOCATION_SCENE)


func _open_inventory() -> void:
    if _overlay_open():
        return
    _inventory = InventoryPanel.new()
    add_child(_inventory)


func _open_shop() -> void:
    if _overlay_open():
        return
    _shop = ShopPanel.new()
    add_child(_shop)


func _overlay_open() -> bool:
    return (_inventory != null and is_instance_valid(_inventory)) or (_shop != null and is_instance_valid(_shop))


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        _on_back()


func _on_back() -> void:
    if _busy:
        return
    _busy = true
    Transition.go(MENU_SCENE)
