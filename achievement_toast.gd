extends CanvasLayer
## Автозагрузка (имя: AchievementToast).
## Показывает справа сверху плашку «Достижение выполнено» (как в Майнкрафте).

const UI := preload("res://ui_style.gd")   # без зависимости от кэша классов
const SHOW_TIME := 4.0
const TOP_Y := 24.0   # самый верх экрана справа

var _queue: Array = []
var _busy := false


func _ready() -> void:
    layer = 110
    process_mode = Node.PROCESS_MODE_ALWAYS
    GameData.achievement_unlocked.connect(_on_unlocked)


func _on_unlocked(id) -> void:
    _queue.append(str(id))
    if not _busy:
        _run()


func _run() -> void:
    _busy = true
    while not _queue.is_empty():
        await _show(str(_queue.pop_front()))
    _busy = false


func _show(id: String) -> void:
    await get_tree().create_timer(0.9).timeout   # даём сцене открыться
    var data: Dictionary = GameData.ACHIEVEMENTS.get(id, {})
    if data.is_empty():
        return

    var panel := PanelContainer.new()
    panel.theme = UI.make_theme()
    panel.position = Vector2(5000.0, TOP_Y)   # за экраном, пока не рассчитан размер
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.07, 0.05, 0.04, 0.97)
    sb.border_color = UI.AMBER
    sb.set_border_width_all(3)
    sb.set_corner_radius_all(6)
    sb.content_margin_left = 16
    sb.content_margin_right = 26
    sb.content_margin_top = 12
    sb.content_margin_bottom = 12
    sb.shadow_color = Color(0, 0, 0, 0.5)
    sb.shadow_size = 8
    panel.add_theme_stylebox_override("panel", sb)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 16)
    panel.add_child(row)

    var icon_tex := GameData.tex(str(data.get("icon", "")))
    if icon_tex != null:
        var icon := TextureRect.new()
        icon.texture = icon_tex
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.custom_minimum_size = Vector2(64, 64)
        row.add_child(icon)
    else:
        var box := ColorRect.new()
        box.color = UI.AMBER_DARK
        box.custom_minimum_size = Vector2(64, 64)
        row.add_child(box)

    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 2)
    col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(col)

    var head := Label.new()
    head.text = GameSettings.t("ach_done")
    head.add_theme_font_size_override("font_size", 22)
    head.add_theme_color_override("font_color", UI.AMBER_LIGHT)
    col.add_child(head)

    var title := Label.new()
    title.text = GameData.loc(data["title"])
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color.WHITE)
    col.add_child(title)

    add_child(panel)
    await get_tree().process_frame
    var vw := get_viewport().get_visible_rect().size.x
    var target_x := vw - panel.size.x - 24.0
    var hidden_x := vw + 20.0
    panel.position = Vector2(hidden_x, TOP_Y)

    var tw := create_tween()
    tw.tween_property(panel, "position:x", target_x, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tw.tween_interval(SHOW_TIME)
    tw.tween_property(panel, "position:x", hidden_x, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    await tw.finished
    panel.queue_free()
