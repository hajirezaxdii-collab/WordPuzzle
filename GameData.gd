## GameData.gd - مدیریت داده‌های سراسری بازی
## این اسکریپت به صورت Autoload در کل بازی در دسترس است
extends Node

# ═══════════════════════════════════════════════════════════════
# سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
signal coins_changed(new_amount: int)
signal diamonds_changed(new_amount: int)
signal energy_changed(new_amount: int)
signal xp_changed(new_xp: int, new_level: int)
signal hint_used(hint_type: String)
signal level_completed(level_id: int, stars: int)
signal achievement_unlocked(achievement_id: String)
signal daily_reward_claimed(day: int, reward: Dictionary)

# ═══════════════════════════════════════════════════════════════
# ثابت‌ها
# ═══════════════════════════════════════════════════════════════
const MAX_ENERGY: int = 30
const ENERGY_RECOVERY_TIME: int = 180  # 3 دقیقه
const XP_PER_LEVEL: int = 1000
const MAX_LEVEL: int = 100

# هزینه راهنماها
const HINT_COSTS: Dictionary = {
	"show_letter": 50,
	"show_word": 150,
	"shuffle": 30,
	"bomb": 100
}

# جوایز روزانه
const DAILY_REWARDS: Array[Dictionary] = [
	{"coins": 100, "diamonds": 0, "energy": 5},
	{"coins": 150, "diamonds": 0, "energy": 5},
	{"coins": 200, "diamonds": 5, "energy": 10},
	{"coins": 250, "diamonds": 0, "energy": 5},
	{"coins": 300, "diamonds": 10, "energy": 10},
	{"coins": 400, "diamonds": 0, "energy": 15},
	{"coins": 500, "diamonds": 25, "energy": 30}
]

# ═══════════════════════════════════════════════════════════════
# داده‌های بازیکن
# ═══════════════════════════════════════════════════════════════
var player_data: Dictionary = {
	"name": "بازیکن",
	"coins": 500,
	"diamonds": 10,
	"energy": 30,
	"xp": 0,
	"level": 1,
	"current_level": 1,
	"max_unlocked_level": 1,
	"total_words_found": 0,
	"total_levels_completed": 0,
	"total_play_time": 0,
	"accuracy": 100.0,
	"hints_used": {"show_letter": 0, "show_word": 0, "shuffle": 0, "bomb": 0},
	"achievements": [],
	"selected_theme": "modern",
	"music_volume": 0.7,
	"sfx_volume": 1.0,
	"vibration_enabled": true,
	"notifications_enabled": true,
	"last_energy_update": 0,
	"daily_reward_day": 0,
	"last_daily_claim": "",
	"streak_days": 0
}

# داده‌های مراحل
var levels_data: Array[Dictionary] = []
var completed_levels: Dictionary = {}  # level_id: {stars, best_time, bonus_words}

# دیکشنری کلمات فارسی
var persian_words: Dictionary = {}
var word_list_by_length: Dictionary = {}  # length: [words]

# تنظیمات فعلی
var current_theme: String = "modern"
var is_music_enabled: bool = true
var is_sfx_enabled: bool = true

# ═══════════════════════════════════════════════════════════════
# توابع چرخه حیات
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	# بارگذاری داده‌ها در شروع
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	# بروزرسانی زمان بازی
	player_data["total_play_time"] += delta
	
	# بررسی ریکاوری انرژی
	_check_energy_recovery()

# ═══════════════════════════════════════════════════════════════
# مدیریت سکه و الماس
# ═══════════════════════════════════════════════════════════════
func add_coins(amount: int) -> void:
	player_data["coins"] += amount
	coins_changed.emit(player_data["coins"])
	SaveManager.save_game()

func spend_coins(amount: int) -> bool:
	if player_data["coins"] >= amount:
		player_data["coins"] -= amount
		coins_changed.emit(player_data["coins"])
		SaveManager.save_game()
		return true
	return false

func add_diamonds(amount: int) -> void:
	player_data["diamonds"] += amount
	diamonds_changed.emit(player_data["diamonds"])
	SaveManager.save_game()

func spend_diamonds(amount: int) -> bool:
	if player_data["diamonds"] >= amount:
		player_data["diamonds"] -= amount
		diamonds_changed.emit(player_data["diamonds"])
		SaveManager.save_game()
		return true
	return false

func get_coins() -> int:
	return player_data["coins"]

func get_diamonds() -> int:
	return player_data["diamonds"]

# ═══════════════════════════════════════════════════════════════
# مدیریت انرژی
# ═══════════════════════════════════════════════════════════════
func _check_energy_recovery() -> void:
	if player_data["energy"] >= MAX_ENERGY:
		player_data["last_energy_update"] = Time.get_unix_time_from_system()
		return
	
	var current_time: float = Time.get_unix_time_from_system()
	var elapsed: float = current_time - player_data["last_energy_update"]
	
	if elapsed >= ENERGY_RECOVERY_TIME:
		var recovered: int = int(elapsed / ENERGY_RECOVERY_TIME)
		var new_energy: int = mini(player_data["energy"] + recovered, MAX_ENERGY)
		
		if new_energy != player_data["energy"]:
			player_data["energy"] = new_energy
			player_data["last_energy_update"] = current_time
			energy_changed.emit(player_data["energy"])

func get_energy() -> int:
	return player_data["energy"]

func use_energy(amount: int = 1) -> bool:
	if player_data["energy"] >= amount:
		player_data["energy"] -= amount
		if player_data["energy"] == MAX_ENERGY - amount:
			player_data["last_energy_update"] = Time.get_unix_time_from_system()
		energy_changed.emit(player_data["energy"])
		SaveManager.save_game()
		return true
	return false

func add_energy(amount: int) -> void:
	player_data["energy"] = mini(player_data["energy"] + amount, MAX_ENERGY * 2)  # می‌تواند از MAX بیشتر شود
	energy_changed.emit(player_data["energy"])
	SaveManager.save_game()

func get_energy_recovery_time() -> int:
	if player_data["energy"] >= MAX_ENERGY:
		return 0
	var elapsed: float = Time.get_unix_time_from_system() - player_data["last_energy_update"]
	return maxi(0, ENERGY_RECOVERY_TIME - int(elapsed))

# ═══════════════════════════════════════════════════════════════
# مدیریت XP و لول
# ═══════════════════════════════════════════════════════════════
func add_xp(amount: int) -> void:
	player_data["xp"] += amount
	
	# بررسی لول‌آپ
	var xp_needed: int = get_xp_for_next_level()
	while player_data["xp"] >= xp_needed and player_data["level"] < MAX_LEVEL:
		player_data["xp"] -= xp_needed
		player_data["level"] += 1
		xp_needed = get_xp_for_next_level()
		_on_level_up()
	
	xp_changed.emit(player_data["xp"], player_data["level"])
	SaveManager.save_game()

func get_xp_for_next_level() -> int:
	return XP_PER_LEVEL + (player_data["level"] - 1) * 200

func get_xp_progress() -> float:
	return float(player_data["xp"]) / float(get_xp_for_next_level())

func _on_level_up() -> void:
	# جایزه لول‌آپ
	add_coins(player_data["level"] * 50)
	if player_data["level"] % 5 == 0:
		add_diamonds(10)
	add_energy(MAX_ENERGY)

# ═══════════════════════════════════════════════════════════════
# مدیریت راهنماها
# ═══════════════════════════════════════════════════════════════
func use_hint(hint_type: String) -> bool:
	var cost: int = HINT_COSTS.get(hint_type, 0)
	if spend_coins(cost):
		player_data["hints_used"][hint_type] += 1
		hint_used.emit(hint_type)
		return true
	return false

func get_hint_cost(hint_type: String) -> int:
	return HINT_COSTS.get(hint_type, 0)

# ═══════════════════════════════════════════════════════════════
# مدیریت مراحل
# ═══════════════════════════════════════════════════════════════
func complete_level(level_id: int, stars: int, time_taken: float, bonus_words: Array) -> void:
	var is_first_complete: bool = not completed_levels.has(level_id)
	
	# ذخیره بهترین نتیجه
	if is_first_complete or completed_levels[level_id]["stars"] < stars:
		completed_levels[level_id] = {
			"stars": stars,
			"best_time": time_taken,
			"bonus_words": bonus_words
		}
	
	# آپدیت آمار
	if is_first_complete:
		player_data["total_levels_completed"] += 1
		if level_id >= player_data["max_unlocked_level"]:
			player_data["max_unlocked_level"] = level_id + 1
	
	# جایزه
	var coin_reward: int = 10 + (stars * 5) + (bonus_words.size() * 10)
	add_coins(coin_reward)
	add_xp(stars * 50 + bonus_words.size() * 25)
	
	level_completed.emit(level_id, stars)
	SaveManager.save_game()

func is_level_unlocked(level_id: int) -> bool:
	return level_id <= player_data["max_unlocked_level"]

func get_level_stars(level_id: int) -> int:
	if completed_levels.has(level_id):
		return completed_levels[level_id]["stars"]
	return 0

# ═══════════════════════════════════════════════════════════════
# مدیریت جایزه روزانه
# ═══════════════════════════════════════════════════════════════
func can_claim_daily_reward() -> bool:
	var today: String = Time.get_date_string_from_system()
	return player_data["last_daily_claim"] != today

func claim_daily_reward() -> Dictionary:
	if not can_claim_daily_reward():
		return {}
	
	var today: String = Time.get_date_string_from_system()
	var yesterday: String = _get_yesterday_string()
	
	# بررسی streak
	if player_data["last_daily_claim"] == yesterday:
		player_data["streak_days"] += 1
		if player_data["streak_days"] > 7:
			player_data["streak_days"] = 1
	else:
		player_data["streak_days"] = 1
	
	player_data["daily_reward_day"] = player_data["streak_days"]
	player_data["last_daily_claim"] = today
	
	var reward: Dictionary = DAILY_REWARDS[player_data["streak_days"] - 1]
	
	add_coins(reward["coins"])
	add_diamonds(reward["diamonds"])
	add_energy(reward["energy"])
	
	daily_reward_claimed.emit(player_data["streak_days"], reward)
	SaveManager.save_game()
	
	return reward

func _get_yesterday_string() -> String:
	var unix_time: float = Time.get_unix_time_from_system() - 86400
	var date_dict: Dictionary = Time.get_date_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d" % [date_dict["year"], date_dict["month"], date_dict["day"]]

# ═══════════════════════════════════════════════════════════════
# مدیریت دیکشنری
# ═══════════════════════════════════════════════════════════════
func load_dictionary(data: Dictionary) -> void:
	persian_words = data
	word_list_by_length.clear()
	
	for word in persian_words.keys():
		var length: int = word.length()
		if not word_list_by_length.has(length):
			word_list_by_length[length] = []
		word_list_by_length[length].append(word)

func is_valid_word(word: String) -> bool:
	return persian_words.has(word)

func get_word_meaning(word: String) -> String:
	if persian_words.has(word):
		return persian_words[word].get("meaning", "")
	return ""

func get_words_by_length(length: int) -> Array:
	return word_list_by_length.get(length, [])

# ═══════════════════════════════════════════════════════════════
# مدیریت تنظیمات
# ═══════════════════════════════════════════════════════════════
func set_theme(theme_name: String) -> void:
	player_data["selected_theme"] = theme_name
	current_theme = theme_name
	SaveManager.save_game()

func set_music_volume(volume: float) -> void:
	player_data["music_volume"] = volume
	is_music_enabled = volume > 0
	SaveManager.save_game()

func set_sfx_volume(volume: float) -> void:
	player_data["sfx_volume"] = volume
	is_sfx_enabled = volume > 0
	SaveManager.save_game()

# ═══════════════════════════════════════════════════════════════
# آمار بازیکن
# ═══════════════════════════════════════════════════════════════
func add_word_found() -> void:
	player_data["total_words_found"] += 1

func update_accuracy(correct: int, total: int) -> void:
	if total > 0:
		player_data["accuracy"] = (player_data["accuracy"] + float(correct) / float(total) * 100) / 2

func get_stats() -> Dictionary:
	return {
		"total_words": player_data["total_words_found"],
		"total_levels": player_data["total_levels_completed"],
		"accuracy": player_data["accuracy"],
		"play_time": player_data["total_play_time"],
		"level": player_data["level"]
	}
