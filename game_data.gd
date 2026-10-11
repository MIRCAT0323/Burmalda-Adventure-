extends Node
## Автозагрузка (имя: GameData).
## Тут ВСЁ про содержимое игры: персонажи, локации, предметы, достижения.
## Картинки меняются путями ниже (или просто заменой файлов в assets/ с теми же именами).

signal achievement_unlocked(id)
signal coins_changed

const SAVE_PATH := "user://progress.cfg"

# Базовые параметры героя (для теста)
const BASE_LEVEL := 1
const BASE_DAMAGE := 0
const BASE_HP := 100

# ---------------------------------------------------------------- ПЕРСОНАЖИ
# Картинки: assets/characters/char_1.png ... char_5.png
const CHARACTERS := [
	{"name": "Панкость", "image": "res://assets/characters/char_1.png"},
	{"name": "Артур", "image": "res://assets/characters/char_2.png"},
	{"name": "Меллстройность", "image": "res://assets/characters/char_3.png"},
	{"name": "Складочность", "image": "res://assets/characters/char_4.png"},
	{"name": "Мама Птица", "image": "res://assets/characters/char_5.png"},
]

# ---------------------------------------------------------------- ЛОКАЦИИ КАРТЫ
# image — картинка в круге; pos — положение на карте (0..1 по ширине и высоте экрана).
# Если есть "level_count" — локация открывается (сцена location_map.tscn) и содержит столько уровней.
# bg — фон карты локации, music — музыка локации (вся музыка лежит прямо в assets/) (если файла нет, берутся фон и музыка меню).
const LOCATIONS := [
	{
		"id": "murino",
		"level_count": 50,
		"bg": "res://assets/locations/murino_bg.png",
		"battle_bg": "res://assets/locations/murino_battle_bg.png",   # фон боя (замени файл на свой)
		"battle_ground": 0.95,   # на какой высоте картинки (0..1 сверху) земля (асфальт), где стоят бойцы
		"fight_music": "res://assets/fight_music.mp3",   # музыка боя (замени файл на свой; нет файла — музыка меню)
		"music": "res://assets/murino_music.mp3",
		"name": {"ru": "Мурино", "en": "Murino"},
		"levels": "1 - 50 Lvl",
		"enter_achievement": "enter_murino",   # достижение за первый бой в этой локации
		"image": "res://assets/locations/murino.png",
		"pos": Vector2(0.13, 0.76),
	},
	{
		"name": {"ru": "Село Молочное", "en": "Molochnoe Village"},
		"levels": "50 - 100 Lvl",
		"image": "res://assets/locations/molochnoe.png",
		"pos": Vector2(0.48, 0.55),
	},
	{
		"name": {"ru": "Мытищи", "en": "Mytishchi"},
		"levels": "100 - 150 Lvl",
		"image": "res://assets/locations/mytishchi.png",
		"pos": Vector2(0.90, 0.395),
	},
]

# ---------------------------------------------------------------- ВРАГИ И БОИ
# Картинка врага: assets/NPC/<id>_default.png (враг по умолчанию смотрит ВЛЕВО).
# Если есть assets/NPC/<id>_bite.png — она показывается у врага в момент укуса.
# Эффект укуса на герое: assets/NPC/<id>_bite_fx.png (замени на свою картинку; нет файла — рисуются челюсти).
# coins — сколько монет за убийство (умножается бонусом за звёзды, см. STAR_COIN_MULT).
# fallback / fallback_tint — если картинки врага нет, берётся картинка другого врага (с оттенком).
# height — высота врага на экране (px), speed — скорость ходьбы, bite_* — параметры укуса.
const ENEMIES := {
	"fog": {
		"name": {"ru": "Фог", "en": "Fog"},
		"hp": 50, "damage": 5, "speed": 90.0, "height": 150.0,
		"bite_range": 90.0,       # на каком расстоянии Фог начинает кусать (и достаёт укусом)
		"bite_windup": 0.45,      # замах перед укусом (за это время можно отойти)
		"bite_cooldown": 0.9,     # пауза после укуса
		"coins": 10,              # монет за убийство
		"bite_fx": "res://assets/NPC/fog_bite_fx.png",   # картинка укуса на герое (общая для всех Фогов)
	},
	# Злой Фог: картинка assets/NPC/fog_angry_default.png (+ _bite.png, _bite_fx.png, как у Фога)
	"fog_angry": {
		"name": {"ru": "Злой Фог", "en": "Angry Fog"},
		"hp": 100, "damage": 10, "speed": 70.0, "height": 150.0,
		"bite_range": 90.0,
		"bite_windup": 0.32,      # быстрее замах (у Фога 0.45)
		"bite_cooldown": 0.6,     # и короче пауза (у Фога 0.9) — атакует чаще
		"coins": 20,              # монет за убийство Злого Фога
		"bite_fx": "res://assets/NPC/fog_bite_fx.png",
		"fallback": "fog", "fallback_tint": Color(1.0, 0.55, 0.5),
	},
	# Большой Фог: картинка fog_default.png, увеличенная вдвое. От укуса не увернуться прыжком, атакует медленно.
	"fog_big": {
		"name": {"ru": "Большой Фог", "en": "Big Fog"},
		"hp": 250, "damage": 25, "speed": 45.0, "height": 300.0,
		"bite_range": 170.0,
		"bite_windup": 0.9,       # долгий замах (у Фога 0.45)
		"bite_cooldown": 1.8,     # и долгая пауза (у Фога 0.9) — бьёт редко
		"undodgeable": true,      # прыжком не увернуться
		"hit_half": 120.0,        # хитбокс: на столько дальше достаёт удар героя (из-за большого тела); у остальных 0
		"coins": 40,              # монет за убийство
		"bite_fx": "res://assets/NPC/fog_bite_fx.png",
		"fallback": "fog", "fallback_tint": Color.WHITE,   # картинки fog_big_*.png нет — берутся картинки Фога
	},
}
# Какие уровни — бои: ключ "локация:уровень" -> враг. Остальные уровни пока тестовые.
# "enemy" — один враг, "enemies" — список врагов (выходят на арену одновременно).
const BATTLES := {
	"murino:1": {"enemy": "fog"},
	"murino:2": {"enemies": ["fog", "fog_angry"]},
	# можно задать уровню свои множители за звёзды: "star_mult": {1: 1.5, 2: 2.0, 3: 3.0} (иначе общие STAR_COIN_MULT)
	"murino:3": {"enemies": ["fog_big"]},
}
# Бонус к монетам за звёзды прохождения уровня: 1 звезда x1,25, 2 звезды x1,5, 3 звезды x2.
const STAR_COIN_MULT := {1: 1.25, 2: 1.5, 3: 2.0}
var _tex_cache: Dictionary = {}
var current_level: int = 1   # уровень, который сейчас открыт в бою

# ---------------------------------------------------------------- ДОСТИЖЕНИЯ
# icon — картинка достижения (assets/icons/).
const ACHIEVEMENTS := {
	"start_game": {
		"icon": "res://assets/icons/ach_start.png",
		"title": {"ru": "Начало", "en": "Start the game"},
		"desc": {"ru": "Нажми «Играть» в главном меню", "en": "Press Play in the main menu"},
	},
	"enter_murino": {
		"icon": "res://assets/icons/ach_murino.png",
		"title": {"ru": "Муринский Боец", "en": "Get to Murino"},
		"desc": {"ru": "Впервые сразиться в Мурино", "en": "Fight in Murino for the first time"},
	},
}

# ---------------------------------------------------------------- ПРЕДМЕТЫ
# Предметы выдаются ТОЛЬКО из кейсов (см. CASES ниже).
# slot: helmet / chest / legs / boots / weapon / ability / pet / artifact
# Картинка предмета: assets/items/<id>.png  (просто замени файл с тем же именем)
const SLOTS := ["helmet", "chest", "legs", "boots", "weapon", "ability", "pet", "artifact"]
const TABS := {
	"pets": ["pet"],
	"weapons": ["weapon"],
	"armor": ["helmet", "chest", "legs", "boots"],
	"abilities": ["ability"],
	"artifacts": ["artifact"],
}
# Кулаки — оружие по умолчанию: всегда есть у героя и надеты в начале игры (+5 урона).
# Их можно снять в инвентаре — тогда урон героя 0.
const DEFAULT_WEAPON := "fists"
const ITEMS := [
	{"id": "fists", "slot": "weapon", "rarity": "common", "name": {"ru": "Кулаки", "en": "Fists"}, "damage": 5, "hp": 0},
	{"id": "hatness", "slot": "helmet", "rarity": "rare", "name": {"ru": "Шляпность", "en": "Hatness"}, "damage": 0, "hp": 10},
	{"id": "chick", "slot": "pet", "rarity": "rare", "name": {"ru": "Птенец", "en": "Chick"}, "damage": 5, "hp": 5},
	{"id": "chem_armor", "slot": "chest", "rarity": "rare", "name": {"ru": "Стендофферность", "en": "ChemDefence"}, "damage": 5, "hp": 5},
	{"id": "hat_boots", "slot": "boots", "rarity": "common", "name": {"ru": "ШляпоХоды", "en": "HatWalkers"}, "damage": 0, "hp": 5},
	{"id": "burmalda_salad", "slot": "artifact", "rarity": "epic", "name": {"ru": "Салатик Бурмалдатик", "en": "Burmaldatik Salad"}, "damage": 5, "hp": 15},
	{"id": "chekunec", "slot": "pet", "rarity": "epic", "name": {"ru": "Чекунец", "en": "Chekunets"}, "damage": 10, "hp": 10},
	{"id": "rabbit_burmalda", "slot": "pet", "rarity": "epic", "name": {"ru": "Зайчик Бурмалдайчик", "en": "Burmaldaichik Bunny"}, "damage": 5, "hp": 15},
	{"id": "kotost", "slot": "pet", "rarity": "legendary", "name": {"ru": "Котость", "en": "Catness"}, "damage": 20, "hp": 15},
	{"id": "plaksik", "slot": "pet", "rarity": "rare", "name": {"ru": "Плаксик", "en": "Crybaby"}, "damage": 0, "hp": 10},
	{"id": "artur_hat", "slot": "helmet", "rarity": "legendary", "name": {"ru": "Шляпа Артура", "en": "Arthur's Hat"}, "damage":15, "hp": 20},
	{"id": "barhat_tyagi", "slot": "boots", "rarity": "epic", "name": {"ru": "Бархатные Тяги", "en": "Velvet Treads"}, "damage": 5, "hp": 15},
	{"id": "chechevich_soup", "slot": "artifact", "rarity": "epic", "name": {"ru": "Чечевичный Суп", "en": "Lentil Soup"}, "damage": 10, "hp": 10},
	{"id": "chekushka", "slot": "artifact", "rarity": "legendary", "name": {"ru": "Чекушка", "en": "Chekushka"}, "damage": 15, "hp": 20},
	{"id": "chemodan", "slot": "artifact", "rarity": "rare", "name": {"ru": "Чемодан", "en": "Lentil Soup"}, "damage": 10, "hp": 5},
	{"id": "totem_hamam", "slot": "artifact", "rarity": "epic", "name": {"ru": "Тотем - Хамам", "en": "Totem Hamam"}, "damage": 10, "hp": 20},
]

# Редкость предмета (цвет полоски в рулетке, как в КС): поле "rarity" у предмета.
const RARITY_COLORS := {
	"common": Color("b0c3d9"),
	"uncommon": Color("5e98d9"),
	"rare": Color("4b69ff"),
	"epic": Color("8847ff"),
	"legendary": Color("d32ce6"),
	"mythic": Color("eb4b4b"),
	"gold": Color("ffd700"),
}

# ---------------------------------------------------------------- КЕЙСЫ
# Как добавить свой предмет в кейс:
#  1) добавь строку в ITEMS выше (уникальный id, slot, rarity, name, damage, hp);
#  2) положи картинку assets/items/<id>.png;
#  3) добавь {"id": "<id>", "weight": N} в "drops" нужного кейса (больше вес — чаще выпадает).
# image — картинка кейса: assets/cases/<id>.png
# price — цена в монетах (0 = бесплатно)
# drops — что может выпасть: id предмета и вес (чем больше вес, тем чаще выпадает)
const CASES := [
	{
		"id": "mell_case",
		"name": {"ru": "МеллБокс", "en": "MellBox"},
		"price": 50,
		"drops": [
			{"id": "hat_boots", "weight": 45},
			{"id": "hatness", "weight": 30},
			{"id": "chem_armor", "weight": 30},
			{"id": "barhat_tyagi", "weight": 25},
			{"id": "artur_hat", "weight": 15},
		],
	},
	{
		"id": "fogo_case",
		"name": {"ru": "ФогоБокс", "en": "FogoBox"},
		"price": 80,
		"drops": [
			{"id": "chick", "weight": 40},
			{"id": "plaksik", "weight": 40},
			{"id": "rabbit_burmalda", "weight": 25},
			{"id": "chekunec", "weight": 15},
			{"id": "kotost", "weight": 10},
		],
	},
	{
		"id": "burmal_case",
		"name": {"ru": "БурмалБокс", "en": "BurmalBox"},
		"price": 150,
		"drops": [
			{"id": "chemodan", "weight": 50},
			{"id": "burmalda_salad", "weight": 35},
			{"id": "chechevich_soup", "weight": 35},
			{"id": "totem_hamam", "weight": 20},
			{"id": "chekushka", "weight": 10},
		],
	},
]

# ---------------------------------------------------------------- СОСТОЯНИЕ
var character_index: int = -1
var unlocked: Dictionary = {}   # id достижения -> true
var equipped: Dictionary = {}   # слот -> id предмета
var owned: Dictionary = {}      # id предмета -> сколько штук выпало
var coins: int = 0              # валюта
var level_stars: Dictionary = {}   # "локация:уровень" -> звёзды (1..3), лучший результат
var current_location: int = 0      # индекс открытой локации в LOCATIONS
const MAX_STARS := 3


func _ready() -> void:
	load_progress()
	_preload_textures.call_deferred()


## Текст на текущем языке из словаря {"ru": ..., "en": ...}.
func loc(d: Dictionary) -> String:
	return str(d.get(GameSettings.language, d.get("ru", "")))


## Загружает картинку, если файл есть (иначе null).
func tex(path: String) -> Texture2D:
	if path == "":
		return null
	if _tex_cache.has(path):
		return _tex_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var t: Texture2D = null
	# если картинку уже запросили в фоне — забираем её (при необходимости дожидаемся), иначе грузим сразу
	if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		t = ResourceLoader.load_threaded_get(path) as Texture2D
	else:
		t = load(path) as Texture2D
	_tex_cache[path] = t
	return t


## Заранее (в фоне) грузит большие картинки предметов и кейсов, чтобы окна магазина и инвентаря
## открывались без подлагов.
func _preload_textures() -> void:
	var paths: Array = []
	for it in ITEMS:
		paths.append("res://assets/items/%s.png" % str(it["id"]))
	for c in CASES:
		paths.append("res://assets/cases/%s.png" % str(c["id"]))
	for ch in CHARACTERS:
		paths.append(str(ch["image"]))
	for p in paths:
		if ResourceLoader.exists(p) and not _tex_cache.has(p):
			ResourceLoader.load_threaded_request(p)


# ---- персонаж ----
func has_character() -> bool:
	return character_index >= 0 and character_index < CHARACTERS.size()


func select_character(i: int) -> void:
	character_index = clampi(i, 0, CHARACTERS.size() - 1)
	save_progress()


func character() -> Dictionary:
	if has_character():
		return CHARACTERS[character_index]
	return {}


# ---- достижения ----
func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


## Выдаёт достижение. Возвращает true, если оно получено только что.
func unlock(id: String) -> bool:
	if unlocked.has(id) or not ACHIEVEMENTS.has(id):
		return false
	unlocked[id] = true
	save_progress()
	achievement_unlocked.emit(id)
	return true


# ---- предметы ----
func item_by_id(id: String) -> Dictionary:
	for item in ITEMS:
		if item["id"] == id:
			return item
	return {}


func equip(id: String) -> void:
	var item := item_by_id(id)
	if item.is_empty() or not owns(id):
		return
	equipped[item["slot"]] = id
	save_progress()


func unequip(slot: String) -> void:
	equipped.erase(slot)
	save_progress()


## id надетого предмета в слоте ("" — слот пуст).
func equipped_id(slot: String) -> String:
	return str(equipped.get(slot, ""))


func equipped_item(slot: String) -> Dictionary:
	return item_by_id(equipped_id(slot))


func rarity_color(item: Dictionary) -> Color:
	return RARITY_COLORS.get(str(item.get("rarity", "common")), RARITY_COLORS["common"])


func owns(id: String) -> bool:
	return id == DEFAULT_WEAPON or int(owned.get(id, 0)) > 0


func owned_count(id: String) -> int:
	return int(owned.get(id, 0))


func has_any_items() -> bool:
	return not owned.is_empty()


# ---- валюта ----
func add_coins(n: int) -> void:
	coins = maxi(coins + n, 0)
	save_progress()
	coins_changed.emit()


func can_afford(n: int) -> bool:
	return coins >= n


# ---- бои ----
func has_battle(loc_id: String, level: int) -> bool:
	return BATTLES.has("%s:%d" % [loc_id, level])


func battle(loc_id: String, level: int) -> Dictionary:
	return BATTLES.get("%s:%d" % [loc_id, level], {})


## Список id врагов уровня (пустой — боя нет).
func battle_enemies(loc_id: String, level: int) -> Array:
	var cfg := battle(loc_id, level)
	if cfg.has("enemies"):
		return cfg["enemies"]
	if cfg.has("enemy"):
		return [cfg["enemy"]]
	return []


## Множитель монет за звёзды (0 звёзд — x1).
func coin_multiplier(stars: int, loc_id := "", level := 0) -> float:
	var own = battle(loc_id, level).get("star_mult", null)
	if own is Dictionary:
		return float(own.get(stars, 1.0))
	return float(STAR_COIN_MULT.get(stars, 1.0))


## Картинка героя в момент удара: char_N.png -> char_N_punch.png (если нет — обычная).
func character_punch_tex() -> Texture2D:
	var ch := character()
	if ch.is_empty():
		return null
	var path := str(ch["image"]).trim_suffix(".png") + "_punch.png"
	var t := tex(path)
	return t if t != null else tex(str(ch["image"]))


# ---- уровни локаций ----
func level_count(loc_index: int) -> int:
	if loc_index < 0 or loc_index >= LOCATIONS.size():
		return 0
	return int(LOCATIONS[loc_index].get("level_count", 0))


func _level_key(loc_id: String, level: int) -> String:
	return "%s:%d" % [loc_id, level]


func get_stars(loc_id: String, level: int) -> int:
	return int(level_stars.get(_level_key(loc_id, level), 0))


## Уровень открыт, если это первый уровень или предыдущий пройден (хотя бы 1 звезда).
func is_level_unlocked(loc_id: String, level: int) -> bool:
	return level == 1 or get_stars(loc_id, level - 1) > 0


## Записывает прохождение уровня. Хранится лучший результат.
func complete_level(loc_id: String, level: int, stars: int) -> void:
	stars = clampi(stars, 1, MAX_STARS)
	if stars > get_stars(loc_id, level):
		level_stars[_level_key(loc_id, level)] = stars
		save_progress()


func total_stars(loc_id: String) -> int:
	var n := 0
	for k in level_stars:
		if str(k).begins_with(loc_id + ":"):
			n += int(level_stars[k])
	return n


# ---- кейсы ----
func case_by_id(id: String) -> Dictionary:
	for c in CASES:
		if c["id"] == id:
			return c
	return {}


## Открывает кейс: списывает цену, выбирает предмет по весам и кладёт его в инвентарь.
## Если такой предмет уже есть — это дубликат: второй раз он не добавляется,
## а за него положена половина цены кейса (refund). Монеты возврата начисляет вызывающий
## через add_coins(refund), когда показывает результат (чтобы не спойлерить во время рулетки).
## Возвращает {"ok": bool, "item": Dictionary, "duplicate": bool, "refund": int}.
func open_case(id: String) -> Dictionary:
	var c := case_by_id(id)
	if c.is_empty() or not can_afford(int(c["price"])):
		return {"ok": false}
	var total := 0.0
	for d in c["drops"]:
		total += float(d["weight"])
	if total <= 0.0:
		return {"ok": false}
	var roll := randf() * total
	var won := str(c["drops"][0]["id"])
	for d in c["drops"]:
		roll -= float(d["weight"])
		if roll < 0.0:
			won = str(d["id"])
			break
	var item := item_by_id(won)
	if item.is_empty():
		return {"ok": false}
	var price := int(c["price"])
	coins = maxi(coins - price, 0)
	var duplicate := owns(won)
	if not duplicate:
		owned[won] = 1
	save_progress()
	coins_changed.emit()
	return {"ok": true, "item": item, "duplicate": duplicate, "refund": floori(float(price) / 2.0) if duplicate else 0}


## Полный сброс прогресса: герой, достижения, предметы, монеты (и сохранение на диске).
func reset_progress() -> void:
	character_index = -1
	unlocked.clear()
	equipped.clear()
	owned.clear()
	level_stars.clear()
	equipped["weapon"] = DEFAULT_WEAPON
	coins = 0
	save_progress()
	coins_changed.emit()


## Уровень, урон и здоровье героя с учётом надетого набора.
func get_stats() -> Dictionary:
	var dmg := BASE_DAMAGE
	var hp := BASE_HP
	for slot in SLOTS:
		var item := equipped_item(slot)
		if not item.is_empty():
			dmg += int(item["damage"])
			hp += int(item["hp"])
	return {"level": BASE_LEVEL, "damage": dmg, "hp": hp}


## Короткая строка бонусов предмета, например "+5 Урон".
func stats_text(item: Dictionary) -> String:
	var parts := PackedStringArray()
	if int(item["damage"]) > 0:
		parts.append("+%d %s" % [int(item["damage"]), GameSettings.t("stat_damage")])
	if int(item["hp"]) > 0:
		parts.append("+%d %s" % [int(item["hp"]), GameSettings.t("stat_hp")])
	return " ".join(parts)


# ---- сохранение ----
func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "character", character_index)
	cfg.set_value("progress", "unlocked", unlocked.keys())
	cfg.set_value("progress", "equipped", equipped)
	cfg.set_value("progress", "owned", owned)
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("progress", "level_stars", level_stars)
	cfg.set_value("progress", "weapon_init", true)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		equipped["weapon"] = DEFAULT_WEAPON   # новая игра: кулаки надеты
		return
	character_index = int(cfg.get_value("progress", "character", -1))
	for id in cfg.get_value("progress", "unlocked", []):
		unlocked[str(id)] = true
	var ls = cfg.get_value("progress", "level_stars", {})
	if ls is Dictionary:
		for k in ls:
			level_stars[str(k)] = clampi(int(ls[k]), 0, MAX_STARS)
	var eq = cfg.get_value("progress", "equipped", {})
	var ow = cfg.get_value("progress", "owned", {})
	if ow is Dictionary:
		for id in ow:
			if not item_by_id(str(id)).is_empty() and int(ow[id]) > 0:
				owned[str(id)] = int(ow[id])
	coins = maxi(int(cfg.get_value("progress", "coins", 0)), 0)
	if eq is Dictionary:
		# надетым может быть только то, что есть в инвентаре (старые тестовые предметы пропадают)
		for slot in eq:
			if owns(str(eq[slot])):
				equipped[str(slot)] = str(eq[slot])
	# старое сохранение (до появления кулаков): выдаём кулаки один раз
	if not bool(cfg.get_value("progress", "weapon_init", false)) and not equipped.has("weapon"):
		equipped["weapon"] = DEFAULT_WEAPON
