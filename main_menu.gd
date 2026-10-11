extends Control

const SETTINGS_SCENE := "res://settings.tscn"
const ACHIEVEMENTS_SCENE := "res://achievements.tscn"
const NAME_SCENE := "res://name_entry.tscn"
const CHARACTER_SCENE := "res://character_select.tscn"
const MAP_SCENE := "res://world_map.tscn"


func _ready() -> void:
	theme = UIStyle.make_theme()
	UIStyle.add_background(self)
	UIStyle.add_embers(self)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)

	var logo := UIStyle.make_logo(GameSettings.t("title"))
	column.add_child(logo)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	column.add_child(gap)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(buttons)

	var play := UIStyle.make_button(GameSettings.t("play"))
	var achievements := UIStyle.make_button(GameSettings.t("achievements"))
	var settings := UIStyle.make_button(GameSettings.t("settings"))
	var quit := UIStyle.make_button(GameSettings.t("quit"))
	for b in [play, achievements, settings, quit]:
		buttons.add_child(b)

	play.pressed.connect(_on_play)
	achievements.pressed.connect(_on_achievements)
	settings.pressed.connect(_on_settings)
	quit.pressed.connect(_on_quit)

	# плавное появление: логотип, затем кнопки по очереди
	UIStyle.appear(logo, 0.15, 0.8)
	var i := 0
	for b in [play, achievements, settings, quit]:
		UIStyle.appear(b, 0.5 + 0.1 * i, 0.5)
		i += 1


func _on_play() -> void:
	# первое нажатие «Играть» даёт достижение «Начать игру»
	GameData.unlock("start_game")
	# имя не задано (ни здесь, ни в настройках) -> ввод ника, потом выбор героя
	if GameSettings.player_name.strip_edges() == "":
		Transition.go(NAME_SCENE)
	# герой ещё не выбран -> выбор персонажа, иначе сразу карта мира
	elif GameData.has_character():
		Transition.go(MAP_SCENE)
	else:
		Transition.go(CHARACTER_SCENE)


func _on_achievements() -> void:
	Transition.go(ACHIEVEMENTS_SCENE)


func _on_settings() -> void:
	Transition.go(SETTINGS_SCENE)


func _on_quit() -> void:
	Transition.quit_game()
