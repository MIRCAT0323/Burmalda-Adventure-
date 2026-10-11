extends Control
## Бой уровня: герой слева (смотрит вправо), враг справа (смотрит влево).
## Враги и бои настраиваются в game_data.gd (ENEMIES, BATTLES).
## Управление: A/D — ходьба, Пробел — прыжок, ЛКМ — удар, Esc — пауза.
## Фон боя — поле "battle_bg" у локации в game_data.gd (assets/locations/<id>_battle_bg.png),
## "battle_ground" — на какой высоте картинки (0..1) находится земля, по которой ходят бойцы.

const LOCATION_SCENE := "res://location_map.tscn"
const BATTLE_SCENE := "res://battle_level.tscn"
const PLAYER_SPEED := 190.0
const PLAYER_HEIGHT := 150.0     # рост героя на экране (остановка на фоне ~125)
const ATTACK_REACH := 120.0      # на каком расстоянии удар достаёт врага
const ATTACK_COOLDOWN := 0.38      # пауза между ударами (сек) — чтобы нельзя было закликивать
const PUNCH_SHOW := 0.25         # сколько показывается картинка «удар»
const HIT_DELAY := 0.1           # когда в анимации удара наносится урон
const JUMP_SPEED := 640.0        # начальная скорость прыжка (≈85 px высоты)
const JUMP_COOLDOWN := 0.8       # прыгать можно раз в 0.8 секунды
const GRAVITY := 2400.0
const DODGE_HEIGHT := 35.0       # выше этого герой в прыжке уворачивается от укуса
const EDGE := 60.0
const TIME_LIMIT := 120.0        # время на бой в секундах (02:00); по истечении — поражение
const COUNTDOWN := 3.0           # отсчёт «3… 2… 1…» перед боем
const FIGHT_MUSIC := "res://assets/fight_music.mp3"   # музыка боя (поле "fight_music" у локации перекрывает)
const START_SFX := "fight_start"                        # звук «Бой начался!»: assets/sounds/fight_start.wav (.ogg / .mp3)

var _loc: Dictionary
var _loc_id := ""
var _level := 1
var _stats: Dictionary
var _player: Fighter
var _foes: Array = []            # все враги уровня (Foe)
var _tex_player: Texture2D
var _tex_punch: Texture2D
var _coins_base := 0             # монеты за убитых врагов (до бонуса за звёзды)
var _reward := 0                 # сколько монет выдано в конце боя
var _reward_mult := 1.0          # бонус за звёзды, который применили


## Один враг на арене: боец, его параметры, картинки и своё состояние атаки.
class Foe:
	var f: Fighter
	var def: Dictionary
	var tex: Texture2D
	var tex_bite: Texture2D
	var tex_bite_fx: Texture2D
	var state := "walk"          # walk / windup / recover
	var t := 0.0
	var cd := 0.6
	var killed := false
	var hit_half := 0.0          # добавка к дальности удара героя (большое тело)

var _state := "intro"            # intro / fight / over
var _intro_t := COUNTDOWN
var _time_left := TIME_LIMIT
var _shown_count := -1
var _ground_y := 620.0
var _atk_cd := 0.0
var _punch_t := 0.0
var _hit_t := -1.0
var _want_attack := false
var _jump_v := 0.0
var _jump_cd := 0.0
var _flash: ColorRect
var _big_label: Label
var _timer_label: Label
var _pause_menu: Control = null
var _result: Control = null
var _busy := false


func _ready() -> void:
	theme = UIStyle.make_theme()
	process_mode = Node.PROCESS_MODE_ALWAYS   # сам узел работает и на паузе (меню паузы, Esc)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # иначе корневой Control «съедает» клик и удар по ЛКМ не доходит
	_loc = GameData.LOCATIONS[GameData.current_location]
	_loc_id = str(_loc["id"])
	_level = GameData.current_level
	var enemy_ids: Array = GameData.battle_enemies(_loc_id, _level)
	if enemy_ids.is_empty():
		_leave.call_deferred()
		return
	_stats = GameData.get_stats()
	GameSettings.set_music(str(_loc.get("fight_music", FIGHT_MUSIC)))

	var size := get_viewport_rect().size
	_add_background(size)

	# --- герой ---
	var ch := GameData.character()
	if ch.is_empty():
		ch = GameData.CHARACTERS[0]
	_tex_player = GameData.tex(str(ch["image"]))
	_tex_punch = GameData.character_punch_tex()
	_player = Fighter.new()
	add_child(_player)
	_player.setup(_tex_player, PLAYER_HEIGHT, 1, int(_stats["hp"]), GameSettings.display_name(), Color("4aa843"))
	_player.position = Vector2(size.x * 0.2, _ground_y)
	_player.process_mode = Node.PROCESS_MODE_PAUSABLE

	# --- враги (по умолчанию смотрят влево) ---
	for i in enemy_ids.size():
		var def: Dictionary = GameData.ENEMIES.get(str(enemy_ids[i]), {})
		if def.is_empty():
			continue
		var foe := Foe.new()
		foe.def = def
		var eid := str(enemy_ids[i])
		var tinted := false
		foe.tex = GameData.tex("res://assets/NPC/%s_default.png" % eid)
		if foe.tex == null and def.has("fallback"):          # нет картинки — берём картинку другого врага
			foe.tex = GameData.tex("res://assets/NPC/%s_default.png" % str(def["fallback"]))
			tinted = true
		foe.tex_bite = _enemy_tex(eid, def, "bite")
		foe.tex_bite_fx = GameData.tex(str(def.get("bite_fx", "")))   # путь задан в ENEMIES (поле "bite_fx")
		if foe.tex_bite_fx == null:
			foe.tex_bite_fx = _enemy_tex(eid, def, "bite_fx")
		foe.f = Fighter.new()
		add_child(foe.f)
		foe.f.setup(foe.tex, float(def["height"]), -1, int(def["hp"]), GameData.loc(def["name"]), Color("d03a3a"))
		if tinted:
			foe.f.sprite.self_modulate = def.get("fallback_tint", Color.WHITE)
		var n := enemy_ids.size()
		var xf := 0.8 if n == 1 else lerpf(0.64, 0.9, float(i) / float(n - 1))
		foe.f.position = Vector2(size.x * xf, _ground_y)
		foe.f.process_mode = Node.PROCESS_MODE_PAUSABLE
		foe.cd = 0.6 + 0.4 * float(i)
		foe.hit_half = float(def.get("hit_half", 0.0))
		_foes.append(foe)
	if _foes.is_empty():
		_leave.call_deferred()
		return
	move_child(_player, get_child_count() - 1)   # герой рисуется поверх врагов; проходить сквозь друг друга можно
	GameData.unlock(str(_loc.get("enter_achievement", "")))   # «Попасть в Мурино» и т.п.

	_build_ui()


## Картинка врага: assets/NPC/<id>_<suffix>.png, а если нет — такая же у fallback-врага.
func _enemy_tex(eid: String, def: Dictionary, suffix: String) -> Texture2D:
	var t := GameData.tex("res://assets/NPC/%s_%s.png" % [eid, suffix])
	if t == null and def.has("fallback"):
		t = GameData.tex("res://assets/NPC/%s_%s.png" % [str(def["fallback"]), suffix])
	return t


func _exit_tree() -> void:
	get_tree().paused = false


# ---------------------------------------------------------------- сцена и интерфейс
func _add_background(size: Vector2) -> void:
	var tex := GameData.tex(str(_loc.get("battle_bg", "")))
	if tex == null:
		tex = GameData.tex(str(_loc.get("bg", "")))
	_ground_y = size.y * 0.86
	if tex == null:
		UIStyle.add_background(self)
		return
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	UIStyle._full_rect(bg)
	add_child(bg)
	# земля — фиксированная платформа на картинке: считаем, где она оказалась после растяжения
	var k := maxf(size.x / tex.get_width(), size.y / tex.get_height())
	var img_h := tex.get_height() * k
	_ground_y = (size.y - img_h) / 2.0 + img_h * float(_loc.get("battle_ground", 0.89))


func _build_ui() -> void:
	# красная вспышка при укусе
	_flash = ColorRect.new()
	_flash.color = Color(0.85, 0.05, 0.05, 1.0)
	_flash.modulate.a = 0.0
	UIStyle._full_rect(_flash)
	add_child(_flash)

	# таймер по центру сверху и название уровня под ним
	var head := VBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", -4)
	add_child(head)
	_timer_label = UIStyle.make_heading(_format_time(TIME_LIMIT), 64)
	head.add_child(_timer_label)
	var sub := Label.new()
	sub.text = "%s — %s %d" % [GameData.loc(_loc["name"]).to_upper(), GameSettings.t("level").to_upper(), _level]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	head.add_child(sub)
	head.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 10)

	# полоски здоровья в углах: герой слева, враг справа (якоря и отступы заданы явно)
	var hud_p := HudBar.new()
	hud_p.setup(_player, false)
	add_child(hud_p)
	hud_p.anchor_left = 0.0
	hud_p.anchor_right = 0.0
	hud_p.offset_left = 24.0
	hud_p.offset_right = 24.0 + HudBar.W
	hud_p.offset_top = 18.0
	hud_p.offset_bottom = 18.0 + HudBar.H
	# маленькая красивая полоска над головой каждого врага
	for foe in _foes:
		var hud_e := HudBar.new()
		hud_e.setup(foe.f, false, true)
		foe.f.add_child(hud_e)
		hud_e.position = Vector2(-hud_e.bar_w / 2.0, -foe.f.height - hud_e.bar_h_total - 6.0)

	_build_pause_button()

	_big_label = UIStyle.make_heading("", 130)
	_big_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_big_label.modulate.a = 0.0
	add_child(_big_label)
	_big_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_big_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_big_label.pivot_offset = get_viewport_rect().size / 2.0


## Круглая деревянная кнопка паузы в правом верхнем углу (см. pause_button.gd).
func _build_pause_button() -> void:
	var pause := PauseButton.new()
	pause.pressed.connect(_open_pause)
	pause.tooltip_text = GameSettings.t("pause")
	add_child(pause)
	pause.anchor_left = 1.0
	pause.anchor_right = 1.0
	pause.offset_left = -20.0 - PauseButton.D
	pause.offset_right = -20.0
	pause.offset_top = 20.0
	pause.offset_bottom = 20.0 + PauseButton.D


## Большая надпись по центру («3», «2», «1», «Бой начался!»): появляется с «хлопком» и гаснет.
func _show_big(text: String, hold: float) -> void:
	_big_label.text = text
	_big_label.scale = Vector2(1.6, 1.6)
	_big_label.modulate.a = 0.0
	var tw := _big_label.create_tween().set_parallel(true)
	tw.tween_property(_big_label, "modulate:a", 1.0, 0.15)
	tw.tween_property(_big_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(_big_label, "modulate:a", 0.0, 0.2).set_delay(hold)


func _format_time(t: float) -> String:
	var sec := int(ceil(maxf(t, 0.0)))
	return "%02d:%02d" % [sec / 60, sec % 60]


# ---------------------------------------------------------------- цикл боя
func _process(delta: float) -> void:
	if _player == null or get_tree().paused:
		return
	if _state == "intro":
		_intro_t -= delta
		var n := int(ceil(_intro_t))
		if n != _shown_count and n >= 1:
			_shown_count = n
			_show_big(str(n), 0.5)            # 3… 2… 1…
		if _intro_t <= 0.0:
			_state = "fight"
			_show_big(GameSettings.t("fight_started"), 0.8)
			GameSettings.play_sfx(START_SFX)
		_want_attack = false
		return
	if _state != "fight":
		_want_attack = false
		return
	_time_left -= delta
	_timer_label.text = _format_time(_time_left)
	if _time_left <= 10.0:
		_timer_label.add_theme_color_override("font_color", Color("ff5a4a"))
	if _time_left <= 0.0:
		_end(false, true)                     # время вышло — поражение
		return
	_update_player(delta)
	for foe in _foes:
		_update_enemy(foe, delta)
	_want_attack = false


func _axis() -> int:
	var left := Input.is_physical_key_pressed(KEY_A)
	var right := Input.is_physical_key_pressed(KEY_D)
	return int(right) - int(left)


func _update_player(delta: float) -> void:
	var size := get_viewport_rect().size
	var dir := _axis()
	_player.walking = dir != 0 and _player.jump_y <= 0.0
	_update_jump(delta)
	if dir != 0:
		_player.face(dir)
		_player.position.x = clampf(_player.position.x + dir * PLAYER_SPEED * delta, EDGE, size.x - EDGE)

	_atk_cd -= delta
	if _want_attack and _atk_cd <= 0.0:
		_player_attack()
	if _punch_t > 0.0:
		_punch_t -= delta
		if _punch_t <= 0.0:
			_player.set_texture(_tex_player)
	if _hit_t >= 0.0:
		_hit_t -= delta
		if _hit_t < 0.0:
			_player_hit_lands()


func _update_jump(delta: float) -> void:
	_jump_cd = maxf(_jump_cd - delta, 0.0)
	if _player.jump_y > 0.0 or _jump_v > 0.0:
		_jump_v -= GRAVITY * delta
		_player.jump_y += _jump_v * delta
		if _player.jump_y <= 0.0:
			_player.jump_y = 0.0
			_jump_v = 0.0
	elif Input.is_physical_key_pressed(KEY_SPACE) and _jump_cd <= 0.0:
		_jump_cd = JUMP_COOLDOWN
		_jump_v = JUMP_SPEED
		_player.jump_y = 0.01


## Ближайший живой враг в пределах dist (по горизонтали); facing_only — только впереди героя.
func _nearest_foe(dist: float, facing_only: bool) -> Foe:
	var best: Foe = null
	var best_d := INF
	for foe in _foes:
		if foe.f.dead:
			continue
		var to: float = foe.f.position.x - _player.position.x
		if absf(to) > dist + foe.hit_half:
			continue
		if facing_only and signf(to) != float(_player.facing):
			continue
		if absf(to) < best_d:
			best_d = absf(to)
			best = foe
	return best


func _player_attack() -> void:
	_atk_cd = ATTACK_COOLDOWN
	var target := _nearest_foe(ATTACK_REACH + 40.0, false)
	if target != null:
		_player.face(1 if target.f.position.x >= _player.position.x else -1)   # разворачивается к врагу
	if _tex_punch != null:
		_player.set_texture(_tex_punch)        # картинка «удар» выбранного героя
	_punch_t = PUNCH_SHOW
	_hit_t = HIT_DELAY
	_player.lunge(24.0, 0.28)


func _player_hit_lands() -> void:
	# удар задевает ВСЕХ живых врагов, которые в зоне удара перед героем
	var targets: Array = []
	for foe in _foes:
		if foe.f.dead:
			continue
		var to: float = foe.f.position.x - _player.position.x
		if absf(to) <= ATTACK_REACH + foe.hit_half and signf(to) == float(_player.facing):
			targets.append(foe)
	if targets.is_empty():
		GameSettings.play_sfx("swing")
		return
	var dmg := int(_stats["damage"])
	GameSettings.play_sfx("punch")
	for foe in targets:
		foe.f.take_hit(dmg)
		_float_text(foe.f.world_center() + Vector2(0, -60), "-%d" % dmg, Color("ff3b30"))
		foe.f.position.x = clampf(foe.f.position.x + _player.facing * 10.0, EDGE, get_viewport_rect().size.x - EDGE)
	for foe in targets:
		if foe.f.hp <= 0:
			_foe_killed(foe)


func _foe_killed(foe: Foe) -> void:
	if foe.killed:
		return
	foe.killed = true
	foe.f.walking = false
	_coins_base += int(foe.def.get("coins", 0))
	foe.f.fall(true)
	for o in _foes:
		if not o.killed:
			return
	_end(true)       # убиты все враги уровня


func _update_enemy(foe: Foe, delta: float) -> void:
	var e := foe.f
	if e.dead:
		return
	var size := get_viewport_rect().size
	var to := _player.position.x - e.position.x
	var dir := 1 if to >= 0.0 else -1
	var dist := absf(to)
	var bite_range := float(foe.def["bite_range"])
	match foe.state:
		"walk":
			e.face(dir)
			if dist > bite_range * 0.85:
				e.walking = true
				e.position.x = clampf(e.position.x + dir * float(foe.def["speed"]) * delta, EDGE, size.x - EDGE)
			else:
				e.walking = false
			foe.cd -= delta
			if foe.cd <= 0.0 and dist <= bite_range:
				_start_windup(foe)
		"windup":
			foe.t -= delta
			if foe.t <= 0.0:
				_bite(foe)
		"recover":
			foe.t -= delta
			if foe.t <= 0.0:
				foe.state = "walk"
				foe.cd = 0.15


func _start_windup(foe: Foe) -> void:
	foe.state = "windup"
	foe.t = float(foe.def["bite_windup"])
	foe.f.walking = false
	foe.f.pose(-18.0, -0.28, foe.t * 0.9)       # откидывается назад — готовится кусать
	foe.f.tint(Color(1.0, 0.75, 0.45), foe.t * 0.9)


func _bite(foe: Foe) -> void:
	foe.state = "recover"
	foe.t = float(foe.def["bite_cooldown"])
	if foe.tex_bite != null:
		foe.f.set_texture(foe.tex_bite)
	foe.f.pose(80.0, 0.2, 0.1, Tween.TRANS_QUAD)   # рывок вперёд
	foe.f.tint(Color.WHITE, 0.1)
	get_tree().create_timer(0.3, false).timeout.connect(_bite_end.bind(foe))
	# укус достаёт только если герой ещё рядом
	if absf(_player.position.x - foe.f.position.x) <= float(foe.def["bite_range"]) + 25.0 and not _player.dead and (bool(foe.def.get("undodgeable", false)) or _player.jump_y < DODGE_HEIGHT):
		var dmg := int(foe.def["damage"])
		_player.take_hit(dmg)
		var fx := BiteFx.new()
		fx.tex = foe.tex_bite_fx
		fx.position = _player.world_center()
		fx.scale = Vector2(0.55, 0.55) if foe.tex_bite_fx == null else Vector2.ONE
		add_child(fx)
		fx.play()
		_float_text(_player.world_center() + Vector2(0, -70), "-%d" % dmg, Color("ff3b30"))
		_flash.modulate.a = 0.35
		create_tween().tween_property(_flash, "modulate:a", 0.0, 0.35)
		GameSettings.play_sfx("bite")
		if _player.hp <= 0:
			_end(false)


func _bite_end(foe: Foe) -> void:
	if foe == null or not is_instance_valid(foe.f) or foe.f.dead:
		return
	if foe.tex_bite != null:
		foe.f.set_texture(foe.tex)
	foe.f.pose(0.0, 0.0, 0.25)


func _float_text(pos: Vector2, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.02))
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos - Vector2(30, 20)
	add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 70.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.35).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


# ---------------------------------------------------------------- конец боя
func _end(win: bool, time_up := false) -> void:
	if _state == "over":
		return
	_state = "over"
	_player.walking = false
	for foe in _foes:
		foe.f.walking = false
	if _punch_t > 0.0:
		_player.set_texture(_tex_player)
	var stars := 0
	if win:
		var frac := float(_player.hp) / float(maxi(_player.max_hp, 1))
		stars = 3 if frac >= 0.7 else (2 if frac >= 0.4 else 1)
		GameData.complete_level(_loc_id, _level, stars)
		_reward_mult = GameData.coin_multiplier(stars, _loc_id, _level)      # 1★ x1,25 · 2★ x1,5 · 3★ x2
		_reward = roundi(float(_coins_base) * _reward_mult)
		GameSettings.play_sfx("win")
	else:
		_player.fall(false)
		_reward = _coins_base                              # за поражение — монеты за убитых, без бонуса
		GameSettings.play_sfx("lose")
	if _reward > 0:
		GameData.add_coins(_reward)
	await get_tree().create_timer(1.0, false).timeout
	if is_inside_tree():
		_show_result(win, stars, time_up)


func _show_result(win: bool, stars: int, time_up := false) -> void:
	_result = Control.new()
	_result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_result)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(UIStyle.make_heading(GameSettings.t("victory" if win else ("time_up" if time_up else "defeat")).to_upper(), 56))
	box.add_child(UIStyle.make_divider())
	if win:
		var row := StarRow.new()
		row.setup(stars, 30.0, 12.0)
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(row)
	if _reward > 0:
		var reward := Label.new()
		reward.text = GameSettings.t("reward") % _reward
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward.add_theme_font_size_override("font_size", 34)
		reward.add_theme_color_override("font_color", StarRow.GOLD)
		box.add_child(reward)
		if win and _reward_mult > 1.0:
			var bonus := Label.new()
			var m := String.num(_reward_mult)
			bonus.text = GameSettings.t("bonus_mult") % (m.replace(".", ",") if GameSettings.language == "ru" else m)
			bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bonus.add_theme_font_size_override("font_size", 24)
			bonus.add_theme_color_override("font_color", UIStyle.AMBER_LIGHT)
			box.add_child(bonus)
	if win and _level < GameData.level_count(GameData.current_location) and GameData.has_battle(_loc_id, _level + 1):
		var nxt := UIStyle.make_button(GameSettings.t("next_level"), Vector2(480, 68))
		nxt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		nxt.pressed.connect(_next_level)
		box.add_child(nxt)
	var retry := UIStyle.make_button(GameSettings.t("retry"), Vector2(480, 68))
	retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry.pressed.connect(_retry)
	box.add_child(retry)
	var map := UIStyle.make_button(GameSettings.t("to_map"), Vector2(480, 68))
	map.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	map.pressed.connect(_leave)
	box.add_child(map)
	UIStyle.appear(_result, 0.0, 0.3)


func _retry() -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	Transition.go(BATTLE_SCENE)


func _next_level() -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	GameData.current_level = _level + 1
	Transition.go(BATTLE_SCENE)


func _leave() -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	Transition.go(LOCATION_SCENE)


# ---------------------------------------------------------------- пауза
func _open_pause() -> void:
	if _pause_menu != null or _state == "over" or _busy:
		return
	_want_attack = false
	get_tree().paused = true
	_pause_menu = Control.new()
	_pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_pause_menu)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_menu.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_menu.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	box.add_child(UIStyle.make_heading(GameSettings.t("pause").to_upper(), 56))
	box.add_child(UIStyle.make_divider())
	for entry in [["resume", _close_pause], ["retry", _retry], ["to_map", _leave]]:
		var b := UIStyle.make_button(GameSettings.t(entry[0]), Vector2(480, 68))
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(entry[1])
		box.add_child(b)


func _close_pause() -> void:
	if _pause_menu != null:
		_pause_menu.queue_free()
		_pause_menu = null
	_want_attack = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _pause_menu != null:
			_close_pause()
		elif _state == "over":
			_leave()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_want_attack = true
