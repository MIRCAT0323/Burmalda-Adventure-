extends CanvasLayer
## Автозагрузка (имя: Transition). Плавное затемнение при смене сцен
## и при запуске игры.

const FADE_OUT := 0.30
const FADE_IN := 0.40

var _rect: ColorRect
var _busy := false


func _ready() -> void:
    layer = 100
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rect = ColorRect.new()
    _rect.color = Color(0.03, 0.02, 0.04, 1.0)
    _rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _rect.modulate.a = 1.0
    add_child(_rect)
    get_tree().node_added.connect(_on_node_added)
    # плавное появление при запуске игры
    await get_tree().process_frame
    await get_tree().process_frame
    create_tween().tween_property(_rect, "modulate:a", 0.0, FADE_IN + 0.3).set_trans(Tween.TRANS_SINE)


## Любая кнопка в игре (BaseButton), у которой нет своей анимации, получает плавное увеличение при наведении.
func _on_node_added(n: Node) -> void:
    if n is BaseButton:
        UIStyle.attach_hover_fx(n as BaseButton)


## Плавно перейти на другую сцену.
func go(path: String) -> void:
    if _busy:
        return
    _busy = true
    _rect.mouse_filter = Control.MOUSE_FILTER_STOP   # пока идёт переход, клики блокируются
    var tw := create_tween()
    tw.tween_property(_rect, "modulate:a", 1.0, FADE_OUT).set_trans(Tween.TRANS_SINE)
    await tw.finished
    get_tree().change_scene_to_file(path)
    await get_tree().process_frame
    await get_tree().process_frame
    var tw2 := create_tween()
    tw2.tween_property(_rect, "modulate:a", 0.0, FADE_IN).set_trans(Tween.TRANS_SINE)
    await tw2.finished
    _rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _busy = false


## Плавно закрыть игру.
func quit_game() -> void:
    if _busy:
        return
    _busy = true
    _rect.mouse_filter = Control.MOUSE_FILTER_STOP
    var tw := create_tween()
    tw.tween_property(_rect, "modulate:a", 1.0, FADE_OUT).set_trans(Tween.TRANS_SINE)
    await tw.finished
    get_tree().quit()
