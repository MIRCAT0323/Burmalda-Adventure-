extends Node
## Автозагрузка (имя: GameSettings).
## Играет музыку во всех сценах, хранит настройки и тексты на двух языках.

const MUSIC_PATH := "res://assets/music.mp3"   # ТВОЯ МУЗЫКА (.ogg или .mp3)
const SFX_DIR := "res://assets/sounds/"      # ЗВУКИ: case_open, tick, item_drop
const SAVE_PATH := "user://settings.cfg"
const NAME_MAX := 25

const TEXTS := {
	"ru": {
		"title": "BURMALDA ADVENTURE",
		"play": "Играть",
		"settings": "Настройки",
		"achievements": "Достижения",
		"quit": "Выйти",
		"music": "Громкость музыки",
		"sfx": "Громкость звуков",
		"change_name": "Сменить имя",
		"name_placeholder": "Введите имя героя",
		"enter_name": "Как вас зовут?",
		"next": "Далее",
		"language": "Язык",
		"back": "Назад",
		"welcome": "Добро пожаловать, %s",
		"default_name": "Герой",
		"saved": "Имя сохранено",
		"choose_character": "Выберите героя",
		"shop": "Магазинность",
		"inventory": "Инвентарность",
		"soon": "Скоро",
		"location_soon": "Локация скоро откроется",
		"close": "Закрыть",
		"stat_level": "Lvl",
		"stat_damage": "Урон",
		"stat_hp": "ХП",
		"tab_pets": "Питомцы",
		"tab_weapons": "Оружие",
		"tab_armor": "Броня",
		"tab_abilities": "Способности",
		"tab_artifacts": "Артефакты",
		"search_item": "Поиск предмета...",
		"nothing_found": "Ничего не найдено",
		"slot_helmet": "Шлем",
		"slot_chest": "Нагрудник",
		"slot_legs": "Штаны",
		"slot_boots": "Ботинки",
		"slot_weapon": "Оружие",
		"slot_ability": "Способность",
		"slot_pet": "Питомец",
		"slot_artifact": "Артефакт",
		"coins": "Монеты",
		"free": "Бесплатно",
		"open_case": "Открыть",
		"inside_case": "Что внутри",
		"not_enough_coins": "Не хватает монет",
		"you_got": "Вам выпало!",
		"new_item": "Новый предмет!",
		"duplicate_item": "Дубликат!",
		"take": "Забрать",
		"unlock_case": "Открытие кейса",
		"contains": "Содержит один из следующих:",
		"open_again": "Открыть ещё",
		"inventory_empty": "Инвентарность пуста",
		"reset_progress": "Сброс прогресса",
		"reset_title": "Сбросить прогресс?",
		"reset_text": "Будут сброшены все данные: имя, язык, громкость, достижения, выбранный герой, предметы и монеты. Игра начнётся заново с выбора персонажа. Это нельзя отменить.",
		"reset_yes": "Да, сбросить",
		"cancel": "Отмена",
		"ach_done": "Достижение выполнено",
		"ach_unlocked": "Получено",
		"ach_locked": "Не получено",
		"level": "Уровень",
		"stars_total": "Звёзды",
		"level_locked": "Сначала пройдите предыдущий уровень",
		"level_done": "Уровень %d пройден!",
		"play_test": "Пройти на %d из 3 звёзд",
		"play_test_hint": "Боёв пока нет — это тестовое прохождение.",
		"best_result": "Лучший результат",
		"attack": "Удар",
		"controls_hint": "A / D — ходьба,  Пробел — прыжок,  ЛКМ — удар,  Esc — пауза",
		"fight_started": "Бой начался!",
		"pause": "Пауза",
		"resume": "Продолжить",
		"time_up": "Время вышло",
		"victory": "Победа!",
		"defeat": "Поражение",
		"retry": "Заново",
		"to_map": "К карте",
		"next_level": "Следующий уровень",
		"reward": "Награда: +%d монет",
		"bonus_mult": "Бонус за звёзды: ×%s",
	},
	"en": {
		"title": "BURMALDA ADVENTURE",
		"play": "Play",
		"settings": "Settings",
		"achievements": "Achievements",
		"quit": "Quit",
		"music": "Music volume",
		"sfx": "Sound volume",
		"change_name": "Change name",
		"name_placeholder": "Enter hero name",
		"enter_name": "What is your name?",
		"next": "Next",
		"language": "Language",
		"back": "Back",
		"welcome": "Welcome, %s",
		"default_name": "Hero",
		"saved": "Name saved",
		"choose_character": "Choose your hero",
		"shop": "Shop",
		"inventory": "Inventory",
		"soon": "Coming soon",
		"location_soon": "Location opens soon",
		"close": "Close",
		"stat_level": "Lvl",
		"stat_damage": "Damage",
		"stat_hp": "HP",
		"tab_pets": "Pets",
		"tab_weapons": "Weapons",
		"tab_armor": "Armor",
		"tab_abilities": "Abilities",
		"tab_artifacts": "Artifacts",
		"search_item": "Search item...",
		"nothing_found": "Nothing found",
		"slot_helmet": "Helmet",
		"slot_chest": "Chestplate",
		"slot_legs": "Pants",
		"slot_boots": "Boots",
		"slot_weapon": "Weapon",
		"slot_ability": "Ability",
		"slot_pet": "Pet",
		"slot_artifact": "Artifact",
		"coins": "Coins",
		"free": "Free",
		"open_case": "Open",
		"inside_case": "What's inside",
		"not_enough_coins": "Not enough coins",
		"you_got": "You got!",
		"new_item": "New item!",
		"duplicate_item": "Duplicate!",
		"take": "Claim",
		"unlock_case": "Open case",
		"contains": "Contains one of the following:",
		"open_again": "Open again",
		"inventory_empty": "Inventory is empty",
		"reset_progress": "Reset progress",
		"reset_title": "Reset progress?",
		"reset_text": "Everything will be reset: name, language, volume, achievements, selected hero, items and coins. The game will start over from hero selection. This cannot be undone.",
		"reset_yes": "Yes, reset",
		"cancel": "Cancel",
		"ach_done": "Achievement unlocked",
		"ach_unlocked": "Unlocked",
		"ach_locked": "Locked",
		"level": "Level",
		"stars_total": "Stars",
		"level_locked": "Complete the previous level first",
		"level_done": "Level %d complete!",
		"play_test": "Finish with %d of 3 stars",
		"play_test_hint": "No battles yet - this is a test completion.",
		"best_result": "Best result",
		"attack": "Attack",
		"controls_hint": "A / D - move,  Space - jump,  LMB - attack,  Esc - pause",
		"fight_started": "Fight started!",
		"pause": "Pause",
		"resume": "Resume",
		"time_up": "Time's up",
		"victory": "Victory!",
		"defeat": "Defeat",
		"retry": "Retry",
		"to_map": "To map",
		"next_level": "Next level",
		"reward": "Reward: +%d coins",
		"bonus_mult": "Star bonus: x%s",
	},
}

const DEFAULT_VOLUME := 1.0
var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME
var player_name: String = ""
var language: String = "ru"

var _player: AudioStreamPlayer
var _current_music := ""
var _music_pos := {}   # путь -> позиция, чтобы трек продолжался, а не начинался заново


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	load_settings()
	apply_settings()
	set_music("")


## Включает музыку по пути (например музыку локации). Пустая строка или
## отсутствующий файл — основная музыка игры (продолжается с того места, где её прервали).
func set_music(path: String) -> void:
	var target := path if path != "" and ResourceLoader.exists(path) else MUSIC_PATH
	if target == _current_music:
		return
	if _current_music != "" and _player.playing:
		_music_pos[_current_music] = _player.get_playback_position()
	_current_music = target
	if not ResourceLoader.exists(target):
		_player.stop()
		return
	var stream = load(target)
	if "loop" in stream:
		stream.loop = true
	_player.stream = stream
	_player.play(float(_music_pos.get(target, 0.0)))


## Перевод по ключу на текущий язык.
func t(key: String) -> String:
	return TEXTS[language].get(key, key)


## Имя героя (если не задано, подставляется стандартное).
func display_name() -> String:
	var n := player_name.strip_edges()
	return n if n != "" else t("default_name")


## Короткий звук из assets/sounds/<имя>.mp3 (или .ogg / .wav). Громкость идёт от ползунка громкости.
## Если файла нет, ничего не играет.
func play_sfx(sfx_name: String, volume_db := 0.0) -> void:
	for ext in ["wav", "ogg", "mp3"]:
		var path := "%s%s.%s" % [SFX_DIR, sfx_name, ext]
		if ResourceLoader.exists(path):
			var p := AudioStreamPlayer.new()
			p.stream = load(path)
			p.volume_db = linear_to_db(maxf(sfx_volume, 0.0001)) + volume_db
			add_child(p)
			p.finished.connect(p.queue_free)
			p.play()
			return


func apply_settings() -> void:
	_player.volume_db = linear_to_db(maxf(music_volume, 0.0001))


## Полный сброс настроек: громкости, имя и язык возвращаются к начальным.
func reset_all() -> void:
	music_volume = DEFAULT_VOLUME
	sfx_volume = DEFAULT_VOLUME
	player_name = ""
	language = "ru"
	apply_settings()
	save_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("player", "name", player_name.strip_edges())
	cfg.set_value("player", "language", language)
	cfg.save(SAVE_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	player_name = str(cfg.get_value("player", "name", player_name)).substr(0, NAME_MAX)
	language = cfg.get_value("player", "language", language)
	if not TEXTS.has(language):
		language = "ru"
