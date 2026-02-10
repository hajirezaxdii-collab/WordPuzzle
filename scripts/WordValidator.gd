## WordValidator.gd - سیستم اعتبارسنجی کلمات فارسی
## بررسی صحت کلمات و تولید مراحل
extends RefCounted
class_name WordValidator

# ═══════════════════════════════════════════════════════════════
# ثابت‌ها
# ═══════════════════════════════════════════════════════════════
const MIN_WORD_LENGTH: int = 2
const MAX_WORD_LENGTH: int = 10

# حروف فارسی
const PERSIAN_LETTERS: String = "آابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهی"

# ═══════════════════════════════════════════════════════════════
# اعتبارسنجی
# ═══════════════════════════════════════════════════════════════
static func is_valid_word(word: String) -> bool:
	"""بررسی معتبر بودن کلمه"""
	# بررسی طول
	if word.length() < MIN_WORD_LENGTH or word.length() > MAX_WORD_LENGTH:
		return false
	
	# بررسی فارسی بودن
	if not is_persian_word(word):
		return false
	
	# بررسی در دیکشنری
	return GameData.is_valid_word(word)

static func is_persian_word(word: String) -> bool:
	"""بررسی فارسی بودن کلمه"""
	for character in word:
		if character not in PERSIAN_LETTERS:
			return false
	return true

static func can_make_word(word: String, available_letters: String) -> bool:
	"""بررسی امکان ساخت کلمه با حروف موجود"""
	var letters_copy: String = available_letters
	
	for character in word:
		var index: int = letters_copy.find(character)
		if index == -1:
			return false
		letters_copy = letters_copy.substr(0, index) + letters_copy.substr(index + 1)
	
	return true

# ═══════════════════════════════════════════════════════════════
# پیدا کردن کلمات ممکن
# ═══════════════════════════════════════════════════════════════
static func find_possible_words(letters: String, min_length: int = 2) -> Array[String]:
	"""پیدا کردن تمام کلمات ممکن با حروف داده شده"""
	var result: Array[String] = []
	
	# بررسی کلمات دیکشنری
	for word in GameData.persian_words.keys():
		if word.length() >= min_length and can_make_word(word, letters):
			result.append(word)
	
	# مرتب‌سازی بر اساس طول
	result.sort_custom(func(a, b): return a.length() > b.length())
	
	return result

static func find_words_by_length(letters: String, length: int) -> Array[String]:
	"""پیدا کردن کلمات با طول مشخص"""
	var words: Array = GameData.get_words_by_length(length)
	var result: Array[String] = []
	
	for word in words:
		if can_make_word(word, letters):
			result.append(word)
	
	return result

# ═══════════════════════════════════════════════════════════════
# تولید مرحله
# ═══════════════════════════════════════════════════════════════
static func generate_level_data(difficulty: String, level_id: int) -> Dictionary:
	"""تولید داده مرحله بر اساس سختی"""
	var config: Dictionary = _get_difficulty_config(difficulty)
	
	# انتخاب کلمه اصلی
	var main_word: String = _select_main_word(config.min_letters, config.max_letters)
	if main_word.is_empty():
		return {}
	
	# پیدا کردن کلمات ممکن
	var possible_words: Array[String] = find_possible_words(main_word, 2)
	
	if possible_words.size() < config.min_words:
		return generate_level_data(difficulty, level_id)  # تلاش مجدد
	
	# انتخاب کلمات هدف
	var target_words: Array[String] = []
	var bonus_words: Array[String] = []
	
	# اول کلمه اصلی
	target_words.append(main_word)
	possible_words.erase(main_word)
	
	# کلمات دیگر
	possible_words.shuffle()
	
	var target_count: int = mini(config.target_words - 1, possible_words.size())
	for i in range(target_count):
		target_words.append(possible_words[i])
	
	# کلمات جایزه
	var remaining: Array = possible_words.slice(target_count)
	var bonus_count: int = mini(config.bonus_words, remaining.size())
	for i in range(bonus_count):
		bonus_words.append(remaining[i])
	
	return {
		"id": level_id,
		"letters": main_word,
		"words": target_words,
		"bonus_words": bonus_words,
		"difficulty": difficulty,
		"time_limit": config.time_limit,
		"star_thresholds": {
			"three_stars": config.time_limit * 0.5,
			"two_stars": config.time_limit * 0.75
		}
	}

static func _get_difficulty_config(difficulty: String) -> Dictionary:
	"""دریافت تنظیمات سختی"""
	match difficulty:
		"easy":
			return {
				"min_letters": 4,
				"max_letters": 5,
				"min_words": 3,
				"target_words": 4,
				"bonus_words": 2,
				"time_limit": 180
			}
		"medium":
			return {
				"min_letters": 5,
				"max_letters": 6,
				"min_words": 4,
				"target_words": 6,
				"bonus_words": 3,
				"time_limit": 150
			}
		"hard":
			return {
				"min_letters": 6,
				"max_letters": 7,
				"min_words": 5,
				"target_words": 8,
				"bonus_words": 4,
				"time_limit": 120
			}
		"expert":
			return {
				"min_letters": 7,
				"max_letters": 8,
				"min_words": 6,
				"target_words": 10,
				"bonus_words": 5,
				"time_limit": 90
			}
		_:
			return _get_difficulty_config("easy")

static func _select_main_word(min_len: int, max_len: int) -> String:
	"""انتخاب کلمه اصلی"""
	var candidates: Array[String] = []
	
	for length in range(min_len, max_len + 1):
		var words: Array = GameData.get_words_by_length(length)
		for word in words:
			# بررسی تنوع حروف
			if _has_letter_variety(word):
				candidates.append(word)
	
	if candidates.is_empty():
		return ""
	
	return candidates[randi() % candidates.size()]

static func _has_letter_variety(word: String) -> bool:
	"""بررسی تنوع حروف"""
	var unique_letters: Dictionary = {}
	for letter in word:
		unique_letters[letter] = true
	
	# حداقل 60% حروف منحصر به فرد
	return float(unique_letters.size()) / float(word.length()) >= 0.6

# ═══════════════════════════════════════════════════════════════
# راهنماها
# ═══════════════════════════════════════════════════════════════
static func get_hint_letter(word: String, revealed_indices: Array) -> Dictionary:
	"""دریافت یک حرف راهنما"""
	for i in range(word.length()):
		if i not in revealed_indices:
			return {"index": i, "letter": word[i]}
	return {}

static func get_random_unfound_word(target_words: Array, found_words: Array) -> String:
	"""دریافت یک کلمه پیدا نشده تصادفی"""
	var unfound: Array[String] = []
	for word in target_words:
		if word not in found_words:
			unfound.append(word)
	
	if unfound.is_empty():
		return ""
	
	return unfound[randi() % unfound.size()]
