## LevelManager.gd - مدیریت مراحل بازی
## بارگذاری، ذخیره و تولید مراحل
extends Node
class_name LevelManager

# ═══════════════════════════════════════════════════════════════
# سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
signal levels_loaded
signal level_generated(level_data: Dictionary)

# ═══════════════════════════════════════════════════════════════
# ثابت‌ها
# ═══════════════════════════════════════════════════════════════
const LEVELS_FILE_PATH: String = "res://resources/levels/levels_data.json"
const USER_LEVELS_PATH: String = "user://custom_levels.json"
const TOTAL_LEVELS: int = 500

# ═══════════════════════════════════════════════════════════════
# متغیرها
# ═══════════════════════════════════════════════════════════════
var levels: Array[Dictionary] = []
var custom_levels: Array[Dictionary] = []
var daily_challenge: Dictionary = {}

# ═══════════════════════════════════════════════════════════════
# بارگذاری مراحل
# ═══════════════════════════════════════════════════════════════
func load_levels() -> void:
	"""بارگذاری تمام مراحل"""
	levels.clear()
	
	# بارگذاری مراحل آماده
	if ResourceLoader.exists(LEVELS_FILE_PATH):
		var file := FileAccess.open(LEVELS_FILE_PATH, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				for level_data in json.data:
					levels.append(level_data)
			file.close()
	
	# تولید مراحل اضافی در صورت نیاز
	while levels.size() < TOTAL_LEVELS:
		var new_level := _generate_level(levels.size() + 1)
		levels.append(new_level)
	
	# بارگذاری مراحل کاربر
	_load_custom_levels()
	
	levels_loaded.emit()

func _generate_level(level_id: int) -> Dictionary:
	"""تولید یک مرحله جدید"""
	var difficulty: String = _get_difficulty_for_level(level_id)
	var level_data: Dictionary = WordValidator.generate_level_data(difficulty, level_id)
	
	if level_data.is_empty():
		# مرحله پیش‌فرض در صورت خطا
		level_data = {
			"id": level_id,
			"letters": "کلمات",
			"words": ["کلمات", "کلام", "مات", "کل"],
			"bonus_words": ["ملک"],
			"difficulty": difficulty,
			"time_limit": 180,
			"star_thresholds": {"three_stars": 90, "two_stars": 135}
		}
	
	level_generated.emit(level_data)
	return level_data

func _get_difficulty_for_level(level_id: int) -> String:
	"""تعیین سختی بر اساس شماره مرحله"""
	if level_id <= 20:
		return "easy"
	elif level_id <= 80:
		return "medium"
	elif level_id <= 200:
		return "hard"
	else:
		return "expert"

# ═══════════════════════════════════════════════════════════════
# دریافت مرحله
# ═══════════════════════════════════════════════════════════════
func get_level(level_id: int) -> Dictionary:
	"""دریافت داده یک مرحله"""
	if level_id <= 0:
		return {}
	
	if level_id <= levels.size():
		return levels[level_id - 1]
	
	# تولید در صورت نیاز
	while levels.size() < level_id:
		var new_level := _generate_level(levels.size() + 1)
		levels.append(new_level)
	
	return levels[level_id - 1]

func get_levels_range(start: int, end: int) -> Array[Dictionary]:
	"""دریافت محدوده‌ای از مراحل"""
	var result: Array[Dictionary] = []
	
	for i in range(start, end + 1):
		var level := get_level(i)
		if not level.is_empty():
			result.append(level)
	
	return result

# ═══════════════════════════════════════════════════════════════
# چالش روزانه
# ═══════════════════════════════════════════════════════════════
func get_daily_challenge() -> Dictionary:
	"""دریافت چالش روزانه"""
	var today: String = Time.get_date_string_from_system()
	
	if daily_challenge.get("date", "") != today:
		_generate_daily_challenge()
	
	return daily_challenge

func _generate_daily_challenge() -> void:
	"""تولید چالش روزانه"""
	var today: String = Time.get_date_string_from_system()
	
	# استفاده از تاریخ به عنوان seed
	var seed_value: int = today.hash()
	seed(seed_value)
	
	daily_challenge = WordValidator.generate_level_data("hard", 0)
	daily_challenge["date"] = today
	daily_challenge["is_daily"] = true
	daily_challenge["rewards"] = {
		"coins": 200,
		"diamonds": 10,
		"xp": 300
	}

func is_daily_challenge_completed() -> bool:
	"""بررسی تکمیل چالش روزانه"""
	var today: String = Time.get_date_string_from_system()
	return GameData.player_data.get("last_daily_complete", "") == today

func complete_daily_challenge(stars: int) -> Dictionary:
	"""تکمیل چالش روزانه"""
	if is_daily_challenge_completed():
		return {}
	
	var rewards: Dictionary = daily_challenge.get("rewards", {})
	
	GameData.add_coins(rewards.get("coins", 0) * stars)
	GameData.add_diamonds(rewards.get("diamonds", 0))
	GameData.add_xp(rewards.get("xp", 0) * stars)
	
	GameData.player_data["last_daily_complete"] = Time.get_date_string_from_system()
	SaveManager.save_game()
	
	return rewards

# ═══════════════════════════════════════════════════════════════
# مراحل کاربر
# ═══════════════════════════════════════════════════════════════
func _load_custom_levels() -> void:
	"""بارگذاری مراحل ساخته شده توسط کاربر"""
	custom_levels.clear()
	
	if FileAccess.file_exists(USER_LEVELS_PATH):
		var file := FileAccess.open(USER_LEVELS_PATH, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				for level_data in json.data:
					custom_levels.append(level_data)
			file.close()

func save_custom_level(level_data: Dictionary) -> bool:
	"""ذخیره مرحله کاربر"""
	level_data["id"] = custom_levels.size() + 1
	level_data["created_at"] = Time.get_unix_time_from_system()
	level_data["is_custom"] = true
	
	custom_levels.append(level_data)
	
	var file := FileAccess.open(USER_LEVELS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(custom_levels))
		file.close()
		return true
	
	return false

func get_custom_levels() -> Array[Dictionary]:
	"""دریافت مراحل کاربر"""
	var result: Array[Dictionary] = []
	for level in custom_levels:
		result.append(level)
	return result

func delete_custom_level(level_id: int) -> bool:
	"""حذف مرحله کاربر"""
	for i in range(custom_levels.size()):
		if custom_levels[i]["id"] == level_id:
			custom_levels.remove_at(i)
			
			var file := FileAccess.open(USER_LEVELS_PATH, FileAccess.WRITE)
			if file:
				file.store_string(JSON.stringify(custom_levels))
				file.close()
				return true
			break
	
	return false

# ═══════════════════════════════════════════════════════════════
# آمار مراحل
# ═══════════════════════════════════════════════════════════════
func get_chapter_progress(chapter: int) -> Dictionary:
	"""دریافت پیشرفت یک فصل"""
	var start_level: int = (chapter - 1) * 50 + 1
	var end_level: int = chapter * 50
	
	var completed: int = 0
	var total_stars: int = 0
	
	for level_id in range(start_level, end_level + 1):
		if GameData.completed_levels.has(level_id):
			completed += 1
			total_stars += GameData.completed_levels[level_id].get("stars", 0)
	
	return {
		"completed": completed,
		"total": 50,
		"stars": total_stars,
		"max_stars": 150,
		"progress": float(completed) / 50.0
	}

func get_total_progress() -> Dictionary:
	"""دریافت پیشرفت کل"""
	var completed: int = GameData.completed_levels.size()
	var total_stars: int = 0
	
	for level_id in GameData.completed_levels:
		total_stars += GameData.completed_levels[level_id].get("stars", 0)
	
	return {
		"completed": completed,
		"total": TOTAL_LEVELS,
		"stars": total_stars,
		"max_stars": TOTAL_LEVELS * 3,
		"progress": float(completed) / float(TOTAL_LEVELS)
	}
