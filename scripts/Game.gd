## Game.gd - مدیریت اصلی گیم‌پلی
## کنترل مراحل، امتیاز، و منطق بازی
extends Control

# ═══════════════════════════════════════════════════════════════
# سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
signal word_submitted(word: String)
signal word_found(word: String, is_bonus: bool)
signal level_completed(stars: int)
signal game_paused
signal game_resumed

# ═══════════════════════════════════════════════════════════════
# ثابت‌ها
# ═══════════════════════════════════════════════════════════════
const STAR_THRESHOLDS: Dictionary = {
	"three": 0.5,  # 50% زمان باقی‌مانده
	"two": 0.25    # 25% زمان باقی‌مانده
}

# ═══════════════════════════════════════════════════════════════
# رفرنس‌های نودها
# ═══════════════════════════════════════════════════════════════
@onready var ui_animations: Node = $UIAnimations
@onready var background: ColorRect = $Background

# Top Bar
@onready var back_button: Button = $TopBar/MarginContainer/HBoxContainer/BackButton
@onready var level_label: Label = $TopBar/MarginContainer/HBoxContainer/LevelLabel
@onready var timer_label: Label = $TopBar/MarginContainer/HBoxContainer/TimerContainer/TimerLabel
@onready var coin_label: Label = $TopBar/MarginContainer/HBoxContainer/ScoreContainer/CoinLabel

# Game Content
@onready var word_grid: Control = $GameContent/WordGridContainer/WordGrid
@onready var letter_circle: Control = $GameContent/LetterCircleContainer/LetterCircle
@onready var current_word_label: Label = $GameContent/CurrentWordContainer/CurrentWordPanel/CurrentWordLabel
@onready var bonus_count_label: Label = $GameContent/BonusWordsContainer/BonusCount

# Hints
@onready var hint_letter_button: Button = $GameContent/HintsContainer/HintLetterButton
@onready var hint_word_button: Button = $GameContent/HintsContainer/HintWordButton
@onready var shuffle_button: Button = $GameContent/HintsContainer/ShuffleButton
@onready var bomb_button: Button = $GameContent/HintsContainer/BombButton

# Containers
@onready var connection_lines: Control = $ConnectionLines
@onready var particle_container: Control = $ParticleContainer

# Popups
@onready var level_complete_popup: Control = $LevelCompletePopup
@onready var pause_popup: Control = $PausePopup

# ═══════════════════════════════════════════════════════════════
# متغیرهای بازی
# ═══════════════════════════════════════════════════════════════
var current_level_id: int = 1
var current_level_data: Dictionary = {}
var target_words: Array[String] = []
var bonus_words: Array[String] = []
var found_words: Array[String] = []
var found_bonus_words: Array[String] = []
var current_word: String = ""
var selected_letters: Array[Control] = []

# تایمر و امتیاز
var time_limit: float = 180.0
var time_remaining: float = 180.0
var is_timer_running: bool = false
var score: int = 0

# وضعیت بازی
var is_game_active: bool = false
var is_paused: bool = false
var is_level_complete: bool = false

# شیدر
var _bg_time: float = 0.0

# ═══════════════════════════════════════════════════════════════
# توابع چرخه حیات
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	_connect_signals()
	_load_level(GameData.player_data["current_level"])
	_play_entrance_animation()
	
	# شروع موسیقی بازی
	AudioManager.play_music("game")

func _process(delta: float) -> void:
	# بروزرسانی شیدر
	_bg_time += delta
	if background.material:
		background.material.set_shader_parameter("time", _bg_time)
	
	# بروزرسانی تایمر
	if is_timer_running and not is_paused:
		time_remaining -= delta
		_update_timer_display()
		
		if time_remaining <= 0:
			time_remaining = 0
			_on_time_up()

func _input(event: InputEvent) -> void:
	# دکمه بازگشت اندروید
	if event.is_action_pressed("ui_cancel"):
		if is_level_complete:
			return
		if is_paused:
			_resume_game()
		else:
			_pause_game()

# ═══════════════════════════════════════════════════════════════
# اتصال سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
func _connect_signals() -> void:
	# دکمه‌های بالا
	back_button.pressed.connect(_on_back_pressed)
	
	# راهنماها
	hint_letter_button.pressed.connect(_on_hint_letter_pressed)
	hint_word_button.pressed.connect(_on_hint_word_pressed)
	shuffle_button.pressed.connect(_on_shuffle_pressed)
	bomb_button.pressed.connect(_on_bomb_pressed)
	
	# سیگنال‌های LetterCircle
	letter_circle.letter_selected.connect(_on_letter_selected)
	letter_circle.letter_deselected.connect(_on_letter_deselected)
	letter_circle.word_submitted.connect(_on_word_submitted)
	letter_circle.selection_cleared.connect(_on_selection_cleared)
	
	# پاپ‌آپ تکمیل مرحله
	$LevelCompletePopup/Panel/Content/ButtonsContainer/HomeButton.pressed.connect(_go_to_main_menu)
	$LevelCompletePopup/Panel/Content/ButtonsContainer/RetryButton.pressed.connect(_retry_level)
	$LevelCompletePopup/Panel/Content/ButtonsContainer/NextButton.pressed.connect(_next_level)
	
	# پاپ‌آپ توقف
	$PausePopup/Panel/Content/ResumeButton.pressed.connect(_resume_game)
	$PausePopup/Panel/Content/RestartButton.pressed.connect(_retry_level)
	$PausePopup/Panel/Content/HomeButton.pressed.connect(_go_to_main_menu)
	$PausePopup/Overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_resume_game()
	)

# ═══════════════════════════════════════════════════════════════
# بارگذاری مرحله
# ═══════════════════════════════════════════════════════════════
func _load_level(level_id: int) -> void:
	current_level_id = level_id
	
	# دریافت داده مرحله
	if level_id <= GameData.levels_data.size():
		current_level_data = GameData.levels_data[level_id - 1]
	else:
		current_level_data = _generate_random_level(level_id)
	
	# تنظیم داده‌ها
	var letters: String = current_level_data.get("letters", "سلام")
	target_words = Array(current_level_data.get("words", ["سلام"]), TYPE_STRING, "", null)
	bonus_words = Array(current_level_data.get("bonus_words", []), TYPE_STRING, "", null)
	
	time_limit = current_level_data.get("time_limit", 180.0)
	time_remaining = time_limit
	
	# ریست وضعیت
	found_words.clear()
	found_bonus_words.clear()
	current_word = ""
	selected_letters.clear()
	score = 0
	is_level_complete = false
	
	# بروزرسانی UI
	level_label.text = "مرحله %d" % level_id
	coin_label.text = str(GameData.get_coins())
	_update_timer_display()
	_update_bonus_display()
	
	# راه‌اندازی کامپوننت‌ها
	letter_circle.setup(letters)
	word_grid.setup(target_words)
	
	# شروع بازی
	is_game_active = true
	is_timer_running = true

func _generate_random_level(level_id: int) -> Dictionary:
	"""تولید مرحله تصادفی برای مراحل بعد از محتوای آماده"""
	# TODO: الگوریتم تولید مرحله
	return {
		"letters": "کلمات",
		"words": ["کلمات", "کلام", "مات"],
		"bonus_words": ["ملک"],
		"time_limit": 150.0
	}

# ═══════════════════════════════════════════════════════════════
# مدیریت انتخاب حروف
# ═══════════════════════════════════════════════════════════════
func _on_letter_selected(letter: String, letter_button: Control) -> void:
	if not is_game_active or is_paused:
		return
	
	current_word += letter
	selected_letters.append(letter_button)
	
	# بروزرسانی نمایش کلمه
	current_word_label.text = current_word
	
	# انیمیشن
	ui_animations.animate_letter_select(letter_button)
	AudioManager.play_letter_select()
	
	# رسم خط اتصال
	if selected_letters.size() > 1:
		var from_pos: Vector2 = selected_letters[-2].global_position + selected_letters[-2].size / 2
		var to_pos: Vector2 = letter_button.global_position + letter_button.size / 2
		# تبدیل به موقعیت محلی
		from_pos = connection_lines.get_global_transform().affine_inverse() * from_pos
		to_pos = connection_lines.get_global_transform().affine_inverse() * to_pos
		ui_animations.create_connection_line(from_pos, to_pos, connection_lines, Color(0.4, 0.7, 1.0, 0.8))
		AudioManager.play_letter_connect()

func _on_letter_deselected(letter: String, letter_button: Control) -> void:
	if not is_game_active:
		return
	
	# حذف آخرین حرف
	if current_word.length() > 0:
		current_word = current_word.substr(0, current_word.length() - 1)
	
	if selected_letters.size() > 0:
		selected_letters.pop_back()
	
	current_word_label.text = current_word
	ui_animations.animate_letter_deselect(letter_button)
	
	# حذف آخرین خط
	if connection_lines.get_child_count() > 0:
		var last_line: Node = connection_lines.get_child(-1)
		ui_animations.remove_connection_line(last_line)

func _on_selection_cleared() -> void:
	current_word = ""
	selected_letters.clear()
	current_word_label.text = ""
	
	# حذف همه خطوط
	for line in connection_lines.get_children():
		line.queue_free()

func _on_word_submitted(word: String) -> void:
	if not is_game_active or is_paused:
		_on_selection_cleared()
		return
	
	_check_word(word)
	_on_selection_cleared()
	letter_circle.clear_selection()

# ═══════════════════════════════════════════════════════════════
# بررسی کلمه
# ═══════════════════════════════════════════════════════════════
func _check_word(word: String) -> void:
	# بررسی کلمات تکراری
	if word in found_words or word in found_bonus_words:
		_on_word_duplicate(word)
		return
	
	# بررسی کلمات هدف
	if word in target_words:
		_on_word_correct(word, false)
		return
	
	# بررسی کلمات جایزه
	if word in bonus_words:
		_on_word_correct(word, true)
		return
	
	# بررسی در دیکشنری (کلمه جایزه ناشناخته)
	if GameData.is_valid_word(word) and word.length() >= 2:
		_on_word_correct(word, true)
		return
	
	# کلمه اشتباه
	_on_word_wrong(word)

func _on_word_correct(word: String, is_bonus: bool) -> void:
	AudioManager.play_correct()
	
	if is_bonus:
		found_bonus_words.append(word)
		score += word.length() * 15
		_update_bonus_display()
		_show_bonus_word_effect(word)
	else:
		found_words.append(word)
		score += word.length() * 10
		word_grid.reveal_word(word)
	
	# افزودن کلمه به آمار
	GameData.add_word_found()
	
	# بررسی تکمیل مرحله
	if found_words.size() >= target_words.size():
		_on_level_complete()

func _on_word_wrong(word: String) -> void:
	AudioManager.play_wrong()
	ui_animations.animate_word_wrong(selected_letters.duplicate())
	
	# لرزش نمایش کلمه
	var tween := create_tween()
	var original_pos: Vector2 = current_word_label.position
	for i in range(3):
		tween.tween_property(current_word_label, "position:x", original_pos.x + 10, 0.05)
		tween.tween_property(current_word_label, "position:x", original_pos.x - 10, 0.05)
	tween.tween_property(current_word_label, "position:x", original_pos.x, 0.05)

func _on_word_duplicate(word: String) -> void:
	AudioManager.play_sfx("pop")
	# افکت کلمه تکراری
	var tween := create_tween()
	tween.tween_property(current_word_label, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(current_word_label, "modulate", Color.WHITE, 0.2)

func _show_bonus_word_effect(word: String) -> void:
	"""نمایش افکت کلمه جایزه"""
	var popup := Label.new()
	popup.text = "+" + word + " 🎁"
	popup.add_theme_font_size_override("font_size", 36)
	popup.add_theme_color_override("font_color", Color.GOLD)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(size.x / 2 - 100, size.y / 2)
	particle_container.add_child(popup)
	
	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 150, 1.0)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.chain().tween_callback(popup.queue_free)

# ═══════════════════════════════════════════════════════════════
# تکمیل مرحله
# ═══════════════════════════════════════════════════════════════
func _on_level_complete() -> void:
	is_level_complete = true
	is_timer_running = false
	is_game_active = false
	
	AudioManager.play_complete()
	
	# محاسبه ستاره‌ها
	var stars: int = _calculate_stars()
	
	# محاسبه جوایز
	var time_bonus: int = int(time_remaining) * 2
	var bonus_word_reward: int = found_bonus_words.size() * 25
	var total_score: int = score + time_bonus + bonus_word_reward
	var coin_reward: int = 10 + (stars * 10) + (found_bonus_words.size() * 5)
	var xp_reward: int = stars * 50 + found_bonus_words.size() * 25
	
	# ذخیره پیشرفت
	GameData.complete_level(
		current_level_id,
		stars,
		time_limit - time_remaining,
		found_bonus_words
	)
	
	# نمایش پاپ‌آپ
	await get_tree().create_timer(0.5).timeout
	_show_level_complete_popup(stars, total_score, coin_reward, xp_reward)

func _calculate_stars() -> int:
	var time_ratio: float = time_remaining / time_limit
	
	if time_ratio >= STAR_THRESHOLDS["three"]:
		return 3
	elif time_ratio >= STAR_THRESHOLDS["two"]:
		return 2
	else:
		return 1

func _show_level_complete_popup(stars: int, total_score: int, coins: int, xp: int) -> void:
	# بروزرسانی محتوا
	$LevelCompletePopup/Panel/Content/ScoreLabel.text = "امتیاز: %d" % total_score
	$LevelCompletePopup/Panel/Content/TimeLabel.text = "زمان: %s" % _format_time(time_limit - time_remaining)
	$LevelCompletePopup/Panel/Content/BonusLabel.text = "کلمات جایزه: %d" % found_bonus_words.size()
	$LevelCompletePopup/Panel/Content/RewardContainer/CoinReward.text = "🪙 +%d" % coins
	$LevelCompletePopup/Panel/Content/RewardContainer/XPReward.text = "⭐ +%d XP" % xp
	
	# نمایش پاپ‌آپ
	level_complete_popup.visible = true
	level_complete_popup.modulate.a = 0
	
	var panel: Control = $LevelCompletePopup/Panel
	panel.scale = Vector2(0.5, 0.5)
	
	var tween := create_tween()
	tween.tween_property(level_complete_popup, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# انیمیشن ستاره‌ها
	await tween.finished
	_animate_stars(stars)
	
	# کانفتی
	if stars >= 2:
		ui_animations.animate_confetti(level_complete_popup, stars * 30)

func _animate_stars(count: int) -> void:
	var star_nodes: Array = [
		$LevelCompletePopup/Panel/Content/StarsContainer/Star1,
		$LevelCompletePopup/Panel/Content/StarsContainer/Star2,
		$LevelCompletePopup/Panel/Content/StarsContainer/Star3
	]
	
	for i in range(3):
		var star: Label = star_nodes[i]
		if i < count:
			star.modulate = Color.GOLD
			ui_animations.animate_star(star, i * 0.2)
			AudioManager.play_star()
		else:
			star.modulate = Color(0.3, 0.3, 0.3)

func _on_time_up() -> void:
	"""زمان تمام شد"""
	is_timer_running = false
	is_game_active = false
	
	AudioManager.play_wrong()
	
	# نمایش پاپ‌آپ زمان تمام
	# TODO: پاپ‌آپ مخصوص
	_show_level_complete_popup(0, score, 0, 0)

# ═══════════════════════════════════════════════════════════════
# راهنماها
# ═══════════════════════════════════════════════════════════════
func _on_hint_letter_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(hint_letter_button)
	
	if GameData.use_hint("show_letter"):
		_reveal_one_letter()
		AudioManager.play_sfx("hint")
	else:
		_show_not_enough_coins()

func _on_hint_word_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(hint_word_button)
	
	if GameData.use_hint("show_word"):
		_reveal_one_word()
		AudioManager.play_sfx("hint")
	else:
		_show_not_enough_coins()

func _on_shuffle_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(shuffle_button)
	
	if GameData.use_hint("shuffle"):
		letter_circle.shuffle_letters()
		AudioManager.play_sfx("shuffle")
	else:
		_show_not_enough_coins()

func _on_bomb_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(bomb_button)
	
	# TODO: پیاده‌سازی بمب
	pass

func _reveal_one_letter() -> void:
	"""نمایش یک حرف از یک کلمه پیدا نشده"""
	for word in target_words:
		if word not in found_words:
			word_grid.reveal_letter_in_word(word)
			break

func _reveal_one_word() -> void:
	"""نمایش کامل یک کلمه"""
	for word in target_words:
		if word not in found_words:
			found_words.append(word)
			word_grid.reveal_word(word)
			score += word.length() * 5  # امتیاز کمتر برای راهنما
			
			if found_words.size() >= target_words.size():
				_on_level_complete()
			break

func _show_not_enough_coins() -> void:
	"""نمایش پیام کمبود سکه"""
	# TODO: پاپ‌آپ خرید سکه
	var popup := Label.new()
	popup.text = "سکه کافی نیست! 🪙"
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_color", Color.RED)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = Vector2(size.x / 2 - 100, size.y / 2)
	particle_container.add_child(popup)
	
	var tween := popup.create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tween.tween_callback(popup.queue_free)

# ═══════════════════════════════════════════════════════════════
# توقف و ادامه
# ═══════════════════════════════════════════════════════════════
func _pause_game() -> void:
	is_paused = true
	game_paused.emit()
	
	pause_popup.visible = true
	pause_popup.modulate.a = 0
	
	var tween := create_tween()
	tween.tween_property(pause_popup, "modulate:a", 1.0, 0.2)

func _resume_game() -> void:
	is_paused = false
	game_resumed.emit()
	
	var tween := create_tween()
	tween.tween_property(pause_popup, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): pause_popup.visible = false)

func _on_back_pressed() -> void:
	AudioManager.play_click()
	if is_level_complete:
		_go_to_main_menu()
	else:
		_pause_game()

# ═══════════════════════════════════════════════════════════════
# ناوبری
# ═══════════════════════════════════════════════════════════════
func _go_to_main_menu() -> void:
	AudioManager.play_click()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))

func _retry_level() -> void:
	AudioManager.play_click()
	_load_level(current_level_id)
	
	pause_popup.visible = false
	level_complete_popup.visible = false

func _next_level() -> void:
	AudioManager.play_click()
	level_complete_popup.visible = false
	_load_level(current_level_id + 1)

# ═══════════════════════════════════════════════════════════════
# بروزرسانی UI
# ═══════════════════════════════════════════════════════════════
func _update_timer_display() -> void:
	timer_label.text = _format_time(time_remaining)
	
	# تغییر رنگ زمانی که کم است
	if time_remaining <= 30:
		timer_label.modulate = Color.RED
	elif time_remaining <= 60:
		timer_label.modulate = Color.ORANGE
	else:
		timer_label.modulate = Color.WHITE

func _update_bonus_display() -> void:
	bonus_count_label.text = "%d/%d" % [found_bonus_words.size(), bonus_words.size()]

func _format_time(seconds: float) -> String:
	var mins: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%d:%02d" % [mins, secs]

# ═══════════════════════════════════════════════════════════════
# انیمیشن‌ها
# ═══════════════════════════════════════════════════════════════
func _play_entrance_animation() -> void:
	modulate.a = 0
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# انیمیشن ورود اجزا
	word_grid.modulate.a = 0
	letter_circle.modulate.a = 0
	
	tween.tween_property(word_grid, "modulate:a", 1.0, 0.3).set_delay(0.2)
	tween.parallel().tween_property(letter_circle, "modulate:a", 1.0, 0.3).set_delay(0.3)
