## Loading.gd - صفحه لودینگ با انیمیشن
## مدیریت بارگذاری منابع و داده‌های بازی
extends Control

# ═══════════════════════════════════════════════════════════════
# ثابت‌ها
# ═══════════════════════════════════════════════════════════════
const NEXT_SCENE: String = "res://scenes/Main.tscn"
const MIN_LOADING_TIME: float = 2.0  # حداقل زمان نمایش لودینگ

# نکات راهنما
const TIPS: Array[String] = [
	"💡 نکته: حروف را با کشیدن انگشت به هم وصل کنید",
	"💡 نکته: کلمات مخفی امتیاز بیشتری دارند",
	"💡 نکته: هر روز وارد شوید و جایزه بگیرید",
	"💡 نکته: از راهنماها در مراحل سخت استفاده کنید",
	"💡 نکته: سرعت بیشتر = ستاره بیشتر",
	"💡 نکته: کلمات طولانی‌تر امتیاز بیشتری دارند",
	"💡 نکته: در حالت چالش روزانه شرکت کنید",
	"💡 نکته: تم‌های مختلف را امتحان کنید"
]

# ═══════════════════════════════════════════════════════════════
# رفرنس‌های نودها
# ═══════════════════════════════════════════════════════════════
@onready var progress_bar: ProgressBar = $Content/LoadingContainer/ProgressContainer/ProgressBar
@onready var status_label: Label = $Content/LoadingContainer/StatusLabel
@onready var tip_label: Label = $Content/TipLabel
@onready var title_label: Label = $Content/Title
@onready var loading_dots: HBoxContainer = $Content/LoadingContainer/LoadingAnimation
@onready var logo: TextureRect = $Content/LogoContainer/Logo

# ═══════════════════════════════════════════════════════════════
# متغیرها
# ═══════════════════════════════════════════════════════════════
var _loading_stages: Array[Dictionary] = []
var _current_stage: int = 0
var _start_time: float = 0.0
var _is_loading_complete: bool = false
var _dots_tween: Tween
var _tip_tween: Tween

# ═══════════════════════════════════════════════════════════════
# توابع چرخه حیات
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	_start_time = Time.get_unix_time_from_system()
	
	# تنظیم مراحل بارگذاری
	_setup_loading_stages()
	
	# شروع انیمیشن‌ها
	_start_entrance_animation()
	_start_dots_animation()
	_start_tip_rotation()
	
	# شروع بارگذاری
	_load_next_stage()

func _setup_loading_stages() -> void:
	"""تنظیم مراحل بارگذاری"""
	_loading_stages = [
		{"name": "بارگذاری داده‌های ذخیره شده...", "weight": 0.15, "action": "_load_save_data"},
		{"name": "بارگذاری دیکشنری فارسی...", "weight": 0.35, "action": "_load_dictionary"},
		{"name": "بارگذاری مراحل بازی...", "weight": 0.20, "action": "_load_levels"},
		{"name": "بارگذاری منابع گرافیکی...", "weight": 0.15, "action": "_preload_resources"},
		{"name": "آماده‌سازی نهایی...", "weight": 0.15, "action": "_finalize_loading"}
	]

# ═══════════════════════════════════════════════════════════════
# انیمیشن‌های ورودی
# ═══════════════════════════════════════════════════════════════
func _start_entrance_animation() -> void:
	"""انیمیشن ورود عناصر"""
	# مخفی کردن اولیه
	title_label.modulate.a = 0
	title_label.position.y += 30
	
	if logo:
		logo.modulate.a = 0
		logo.scale = Vector2(0.5, 0.5)
	
	progress_bar.modulate.a = 0
	status_label.modulate.a = 0
	tip_label.modulate.a = 0
	
	# انیمیشن لوگو
	var tween := create_tween()
	tween.set_parallel(true)
	
	if logo:
		tween.tween_property(logo, "modulate:a", 1.0, 0.5).set_delay(0.2)
		tween.tween_property(logo, "scale", Vector2.ONE, 0.5)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
	
	# انیمیشن عنوان
	tween.tween_property(title_label, "modulate:a", 1.0, 0.5).set_delay(0.4)
	tween.tween_property(title_label, "position:y", title_label.position.y - 30, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.4)
	
	# انیمیشن پروگرس بار
	tween.tween_property(progress_bar, "modulate:a", 1.0, 0.3).set_delay(0.6)
	tween.tween_property(status_label, "modulate:a", 1.0, 0.3).set_delay(0.7)
	tween.tween_property(tip_label, "modulate:a", 1.0, 0.3).set_delay(0.8)

func _start_dots_animation() -> void:
	"""انیمیشن نقطه‌های لودینگ"""
	_dots_tween = create_tween()
	_dots_tween.set_loops()
	
	for i in range(loading_dots.get_child_count()):
		var dot: Panel = loading_dots.get_child(i)
		_dots_tween.tween_property(dot, "modulate:a", 0.3, 0.3).set_delay(i * 0.15)
		_dots_tween.tween_property(dot, "modulate:a", 1.0, 0.3)

func _start_tip_rotation() -> void:
	"""چرخش نکات راهنما"""
	tip_label.text = TIPS[randi() % TIPS.size()]
	
	_tip_tween = create_tween()
	_tip_tween.set_loops()
	_tip_tween.tween_interval(4.0)
	_tip_tween.tween_callback(_change_tip)

func _change_tip() -> void:
	"""تغییر نکته راهنما با انیمیشن"""
	var tween := create_tween()
	tween.tween_property(tip_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): tip_label.text = TIPS[randi() % TIPS.size()])
	tween.tween_property(tip_label, "modulate:a", 1.0, 0.3)

# ═══════════════════════════════════════════════════════════════
# مدیریت بارگذاری
# ═══════════════════════════════════════════════════════════════
func _load_next_stage() -> void:
	"""بارگذاری مرحله بعدی"""
	if _current_stage >= _loading_stages.size():
		_on_loading_complete()
		return
	
	var stage: Dictionary = _loading_stages[_current_stage]
	status_label.text = stage["name"]
	
	# اجرای اکشن بارگذاری
	await call(stage["action"])
	
	# بروزرسانی پروگرس بار
	var progress: float = 0.0
	for i in range(_current_stage + 1):
		progress += _loading_stages[i]["weight"]
	
	_animate_progress(progress)
	
	_current_stage += 1
	
	# کمی تاخیر برای نمایش بهتر
	await get_tree().create_timer(0.2).timeout
	
	_load_next_stage()

func _animate_progress(target: float) -> void:
	"""انیمیشن پروگرس بار"""
	var tween := create_tween()
	tween.tween_property(progress_bar, "value", target, 0.3)\
		.set_trans(Tween.TRANS_SINE)

# ═══════════════════════════════════════════════════════════════
# اکشن‌های بارگذاری
# ═══════════════════════════════════════════════════════════════
func _load_save_data() -> void:
	"""بارگذاری داده‌های ذخیره شده"""
	SaveManager.load_game()
	await get_tree().create_timer(0.3).timeout

func _load_dictionary() -> void:
	"""بارگذاری دیکشنری فارسی"""
	var file_path: String = "res://assets/data/persian_words.json"
	
	if ResourceLoader.exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()
			
			var json := JSON.new()
			if json.parse(json_string) == OK:
				GameData.load_dictionary(json.data)
	else:
		# ایجاد دیکشنری پیش‌فرض
		_create_default_dictionary()
	
	await get_tree().create_timer(0.3).timeout

func _create_default_dictionary() -> void:
	"""ایجاد دیکشنری پیش‌فرض"""
	var default_words: Dictionary = {
		# کلمات 2 حرفی
		"اب": {"meaning": "آب"},
		"با": {"meaning": "با"},
		"به": {"meaning": "به"},
		"تا": {"meaning": "تا"},
		"سر": {"meaning": "سر"},
		"دل": {"meaning": "دل"},
		"گل": {"meaning": "گل"},
		"شب": {"meaning": "شب"},
		"من": {"meaning": "من"},
		"تو": {"meaning": "تو"},
		
		# کلمات 3 حرفی
		"آسمان": {"meaning": "آسمان"},
		"ایران": {"meaning": "ایران"},
		"کتاب": {"meaning": "کتاب"},
		"سلام": {"meaning": "سلام"},
		"دوست": {"meaning": "دوست"},
		"عشق": {"meaning": "عشق"},
		"زندگی": {"meaning": "زندگی"},
		"خانه": {"meaning": "خانه"},
		"مادر": {"meaning": "مادر"},
		"پدر": {"meaning": "پدر"},
		"باران": {"meaning": "باران"},
		"خورشید": {"meaning": "خورشید"},
		"ستاره": {"meaning": "ستاره"},
		"دریا": {"meaning": "دریا"},
		"کوه": {"meaning": "کوه"},
		"جنگل": {"meaning": "جنگل"},
		"شهر": {"meaning": "شهر"},
		"روستا": {"meaning": "روستا"},
		"باغ": {"meaning": "باغ"},
		"درخت": {"meaning": "درخت"},
		"پرنده": {"meaning": "پرنده"},
		"ماهی": {"meaning": "ماهی"},
		"گربه": {"meaning": "گربه"},
		"سگ": {"meaning": "سگ"},
		"اسب": {"meaning": "اسب"},
		"شیر": {"meaning": "شیر"},
		"پلنگ": {"meaning": "پلنگ"},
		"عقاب": {"meaning": "عقاب"},
		"قلب": {"meaning": "قلب"},
		"چشم": {"meaning": "چشم"},
		"دست": {"meaning": "دست"},
		"پا": {"meaning": "پا"},
		"سیب": {"meaning": "سیب"},
		"انار": {"meaning": "انار"},
		"انگور": {"meaning": "انگور"},
		"هلو": {"meaning": "هلو"},
		"گیلاس": {"meaning": "گیلاس"},
		"نان": {"meaning": "نان"},
		"آب": {"meaning": "آب"},
		"شیر": {"meaning": "شیر"},
		"عسل": {"meaning": "عسل"},
		"نمک": {"meaning": "نمک"},
		"قند": {"meaning": "قند"},
		"چای": {"meaning": "چای"},
		"قهوه": {"meaning": "قهوه"},
		
		# کلمات ترکیبی
		"گلاب": {"meaning": "گلاب"},
		"آفتاب": {"meaning": "آفتاب"},
		"مهتاب": {"meaning": "مهتاب"},
		"شبنم": {"meaning": "شبنم"},
		"بهار": {"meaning": "بهار"},
		"تابستان": {"meaning": "تابستان"},
		"پاییز": {"meaning": "پاییز"},
		"زمستان": {"meaning": "زمستان"},
		
		# و صدها کلمه دیگر...
	}
	
	GameData.load_dictionary(default_words)

func _load_levels() -> void:
	"""بارگذاری مراحل بازی"""
	var file_path: String = "res://resources/levels/levels_data.json"
	
	if ResourceLoader.exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_string: String = file.get_as_text()
			file.close()
			
			var json := JSON.new()
			if json.parse(json_string) == OK:
				GameData.levels_data = json.data
	else:
		_generate_default_levels()
	
	await get_tree().create_timer(0.3).timeout

func _generate_default_levels() -> void:
	"""ایجاد مراحل پیش‌فرض"""
	var levels: Array[Dictionary] = []
	
	# 50 مرحله اولیه
	var level_configs: Array[Dictionary] = [
		# مراحل آسان (1-10)
		{"letters": "سلام", "words": ["سلام", "سال", "لام"], "bonus": ["ماس"]},
		{"letters": "کتاب", "words": ["کتاب", "تاب", "آب"], "bonus": ["کاب"]},
		{"letters": "خانه", "words": ["خانه", "خان", "نه"], "bonus": []},
		{"letters": "دوست", "words": ["دوست", "دو", "تو"], "bonus": ["سود"]},
		{"letters": "مادر", "words": ["مادر", "مار", "دار"], "bonus": ["آرم"]},
		{"letters": "پدر", "words": ["پدر", "در", "پر"], "bonus": []},
		{"letters": "باران", "words": ["باران", "باران", "بار", "ران"], "bonus": ["نار", "آبان"]},
		{"letters": "ستاره", "words": ["ستاره", "ستار", "تار", "سر"], "bonus": ["راست"]},
		{"letters": "خورشید", "words": ["خورشید", "خور", "شید"], "bonus": ["درخش"]},
		{"letters": "دریا", "words": ["دریا", "دار", "یار"], "bonus": ["ایراد"]},
		
		# مراحل متوسط (11-30)
		{"letters": "زندگی", "words": ["زندگی", "زند", "گند"], "bonus": ["نیزد"]},
		{"letters": "آزادی", "words": ["آزادی", "آزاد", "یاد"], "bonus": []},
		{"letters": "امید", "words": ["امید", "مید", "دام"], "bonus": ["یاد"]},
		{"letters": "شادی", "words": ["شادی", "شاد", "یاد"], "bonus": []},
		{"letters": "سبز", "words": ["سبز", "بز"], "bonus": []},
		# ادامه مراحل...
	]
	
	for i in range(level_configs.size()):
		var config: Dictionary = level_configs[i]
		levels.append({
			"id": i + 1,
			"letters": config["letters"],
			"words": config["words"],
			"bonus_words": config.get("bonus", []),
			"difficulty": _get_difficulty_for_level(i + 1),
			"time_limit": _get_time_limit_for_level(i + 1),
			"star_thresholds": _get_star_thresholds_for_level(i + 1)
		})
	
	# تولید مراحل بیشتر به صورت خودکار
	for i in range(level_configs.size(), 500):
		levels.append(_generate_level(i + 1))
	
	GameData.levels_data = levels

func _get_difficulty_for_level(level: int) -> String:
	if level <= 10: return "easy"
	elif level <= 30: return "medium"
	elif level <= 100: return "hard"
	else: return "expert"

func _get_time_limit_for_level(level: int) -> int:
	if level <= 10: return 180
	elif level <= 30: return 150
	elif level <= 100: return 120
	else: return 90

func _get_star_thresholds_for_level(level: int) -> Dictionary:
	var base_time: int = _get_time_limit_for_level(level)
	return {
		"three_stars": base_time * 0.5,
		"two_stars": base_time * 0.75
	}

func _generate_level(level_id: int) -> Dictionary:
	"""تولید خودکار مرحله"""
	var difficulty: String = _get_difficulty_for_level(level_id)
	var letter_count: int
	var word_count: int
	
	match difficulty:
		"easy":
			letter_count = randi_range(4, 5)
			word_count = randi_range(3, 4)
		"medium":
			letter_count = randi_range(5, 6)
			word_count = randi_range(4, 6)
		"hard":
			letter_count = randi_range(6, 7)
			word_count = randi_range(5, 8)
		"expert":
			letter_count = randi_range(7, 8)
			word_count = randi_range(6, 10)
	
	# در نسخه واقعی، کلمات از دیکشنری انتخاب می‌شوند
	return {
		"id": level_id,
		"letters": "مثال",  # جایگزین با الگوریتم واقعی
		"words": ["کلمه"],
		"bonus_words": [],
		"difficulty": difficulty,
		"time_limit": _get_time_limit_for_level(level_id),
		"star_thresholds": _get_star_thresholds_for_level(level_id)
	}

func _preload_resources() -> void:
	"""پیش‌بارگذاری منابع گرافیکی"""
	# لیست منابع برای پیش‌بارگذاری
	var resources_to_load: Array[String] = [
		"res://scenes/Main.tscn",
		"res://scenes/Game.tscn",
		"res://scenes/LevelSelect.tscn",
		"res://scenes/components/LetterCircle.tscn",
		"res://scenes/components/WordGrid.tscn"
	]
	
	for resource_path in resources_to_load:
		if ResourceLoader.exists(resource_path):
			ResourceLoader.load_threaded_request(resource_path)
	
	await get_tree().create_timer(0.3).timeout

func _finalize_loading() -> void:
	"""آماده‌سازی نهایی"""
	# اعمال تنظیمات صدا
	AudioManager.apply_settings()
	
	# بررسی جایزه روزانه
	if GameData.can_claim_daily_reward():
		# نشان دادن در منوی اصلی
		pass
	
	await get_tree().create_timer(0.2).timeout

# ═══════════════════════════════════════════════════════════════
# تکمیل بارگذاری
# ═══════════════════════════════════════════════════════════════
func _on_loading_complete() -> void:
	"""بارگذاری کامل شد"""
	_is_loading_complete = true
	status_label.text = "آماده!"
	
	# اطمینان از حداقل زمان نمایش
	var elapsed: float = Time.get_unix_time_from_system() - _start_time
	if elapsed < MIN_LOADING_TIME:
		await get_tree().create_timer(MIN_LOADING_TIME - elapsed).timeout
	
	# انیمیشن خروج
	_play_exit_animation()

func _play_exit_animation() -> void:
	"""انیمیشن خروج از صفحه لودینگ"""
	if _dots_tween:
		_dots_tween.kill()
	if _tip_tween:
		_tip_tween.kill()
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Fade out همه عناصر
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# Scale down لوگو
	if logo:
		tween.tween_property(logo, "scale", Vector2(0.8, 0.8), 0.5)
	
	tween.chain().tween_callback(_go_to_main_menu)

func _go_to_main_menu() -> void:
	"""رفتن به منوی اصلی"""
	get_tree().change_scene_to_file(NEXT_SCENE)
