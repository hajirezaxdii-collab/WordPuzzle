## LevelSelect.gd - صفحه انتخاب مرحله
## نمایش و مدیریت مراحل بازی
extends Control

# ═══════════════════════════════════════════════════════════════
# ثابت‌ها
# ═══════════════════════════════════════════════════════════════
const LEVELS_PER_CHAPTER: int = 50
const LEVEL_BUTTON_SIZE: Vector2 = Vector2(110, 110)

# ═══════════════════════════════════════════════════════════════
# رفرنس‌ها
# ═══════════════════════════════════════════════════════════════
@onready var back_button: Button = $TopBar/BackButton
@onready var title_label: Label = $TopBar/Title
@onready var chapter_tabs: HBoxContainer = $ChapterTabs
@onready var levels_grid: GridContainer = $ScrollContainer/LevelsGrid
@onready var scroll_container: ScrollContainer = $ScrollContainer

# ═══════════════════════════════════════════════════════════════
# استایل‌ها
# ═══════════════════════════════════════════════════════════════
var style_locked: StyleBoxFlat
var style_unlocked: StyleBoxFlat
var style_completed: StyleBoxFlat
var style_current: StyleBoxFlat

# ═══════════════════════════════════════════════════════════════
# متغیرها
# ═══════════════════════════════════════════════════════════════
var current_chapter: int = 1
var level_buttons: Array[Control] = []

# ═══════════════════════════════════════════════════════════════
# توابع چرخه حیات
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	_create_styles()
	_connect_signals()
	_setup_chapter_tabs()
	_load_chapter(1)
	_play_entrance_animation()

func _create_styles() -> void:
	"""ایجاد استایل‌ها"""
	# قفل شده
	style_locked = StyleBoxFlat.new()
	style_locked.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style_locked.corner_radius_top_left = 15
	style_locked.corner_radius_top_right = 15
	style_locked.corner_radius_bottom_right = 15
	style_locked.corner_radius_bottom_left = 15
	
	# باز شده
	style_unlocked = StyleBoxFlat.new()
	style_unlocked.bg_color = Color(0.25, 0.35, 0.55, 0.95)
	style_unlocked.border_width_left = 3
	style_unlocked.border_width_top = 3
	style_unlocked.border_width_right = 3
	style_unlocked.border_width_bottom = 3
	style_unlocked.border_color = Color(0.4, 0.55, 0.8, 1)
	style_unlocked.corner_radius_top_left = 15
	style_unlocked.corner_radius_top_right = 15
	style_unlocked.corner_radius_bottom_right = 15
	style_unlocked.corner_radius_bottom_left = 15
	style_unlocked.shadow_color = Color(0, 0, 0, 0.3)
	style_unlocked.shadow_size = 4
	
	# تکمیل شده
	style_completed = StyleBoxFlat.new()
	style_completed.bg_color = Color(0.2, 0.45, 0.35, 0.95)
	style_completed.border_width_left = 3
	style_completed.border_width_top = 3
	style_completed.border_width_right = 3
	style_completed.border_width_bottom = 3
	style_completed.border_color = Color(0.35, 0.65, 0.5, 1)
	style_completed.corner_radius_top_left = 15
	style_completed.corner_radius_top_right = 15
	style_completed.corner_radius_bottom_right = 15
	style_completed.corner_radius_bottom_left = 15
	
	# مرحله فعلی
	style_current = StyleBoxFlat.new()
	style_current.bg_color = Color(0.5, 0.4, 0.2, 0.95)
	style_current.border_width_left = 4
	style_current.border_width_top = 4
	style_current.border_width_right = 4
	style_current.border_width_bottom = 4
	style_current.border_color = Color(0.8, 0.7, 0.3, 1)
	style_current.corner_radius_top_left = 15
	style_current.corner_radius_top_right = 15
	style_current.corner_radius_bottom_right = 15
	style_current.corner_radius_bottom_left = 15
	style_current.shadow_color = Color(0.6, 0.5, 0.2, 0.4)
	style_current.shadow_size = 8

func _connect_signals() -> void:
	back_button.pressed.connect(_on_back_pressed)

func _setup_chapter_tabs() -> void:
	"""راه‌اندازی تب‌های فصل"""
	var chapters: Array = chapter_tabs.get_children()
	for i in range(chapters.size()):
		var chapter_btn: Button = chapters[i]
		chapter_btn.pressed.connect(_on_chapter_selected.bind(i + 1))

# ═══════════════════════════════════════════════════════════════
# بارگذاری فصل
# ═══════════════════════════════════════════════════════════════
func _load_chapter(chapter: int) -> void:
	"""بارگذاری مراحل یک فصل"""
	current_chapter = chapter
	_clear_levels()
	
	var start_level: int = (chapter - 1) * LEVELS_PER_CHAPTER + 1
	var end_level: int = chapter * LEVELS_PER_CHAPTER
	
	for level_id in range(start_level, end_level + 1):
		var level_button := _create_level_button(level_id)
		levels_grid.add_child(level_button)
		level_buttons.append(level_button)
	
	# اسکرول به مرحله فعلی
	await get_tree().process_frame
	_scroll_to_current_level()
	
	# بروزرسانی تب‌ها
	_update_chapter_tabs()

func _clear_levels() -> void:
	"""پاک کردن مراحل"""
	for button in level_buttons:
		button.queue_free()
	level_buttons.clear()

func _create_level_button(level_id: int) -> Control:
	"""ایجاد دکمه مرحله"""
	var container := PanelContainer.new()
	container.custom_minimum_size = LEVEL_BUTTON_SIZE
	container.set_meta("level_id", level_id)
	
	var is_unlocked: bool = GameData.is_level_unlocked(level_id)
	var is_completed: bool = GameData.completed_levels.has(level_id)
	var is_current: bool = level_id == GameData.player_data["current_level"]
	var stars: int = GameData.get_level_stars(level_id)
	
	# تعیین استایل
	var style: StyleBoxFlat
	if is_current:
		style = style_current
	elif is_completed:
		style = style_completed
	elif is_unlocked:
		style = style_unlocked
	else:
		style = style_locked
	
	container.add_theme_stylebox_override("panel", style.duplicate())
	
	# محتوای داخلی
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 5)
	container.add_child(vbox)
	
	# شماره مرحله
	var number_label := Label.new()
	number_label.text = str(level_id)
	number_label.add_theme_font_size_override("font_size", 32)
	number_label.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.5, 0.5, 0.5))
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(number_label)
	
	# ستاره‌ها یا قفل
	var status_label := Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if not is_unlocked:
		status_label.text = "🔒"
		status_label.add_theme_font_size_override("font_size", 24)
	elif is_completed:
		status_label.text = "⭐".repeat(stars) + "☆".repeat(3 - stars)
		status_label.add_theme_font_size_override("font_size", 16)
		status_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		status_label.text = ""
	
	vbox.add_child(status_label)
	
	# رویداد کلیک
	if is_unlocked:
		container.gui_input.connect(_on_level_button_input.bind(level_id, container))
		container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	return container

func _on_level_button_input(event: InputEvent, level_id: int, button: Control) -> void:
	"""هندل کلیک روی مرحله"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_click()
		_animate_button_press(button)
		await get_tree().create_timer(0.2).timeout
		_start_level(level_id)

func _animate_button_press(button: Control) -> void:
	"""انیمیشن فشردن دکمه"""
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_level(level_id: int) -> void:
	"""شروع مرحله"""
	GameData.player_data["current_level"] = level_id
	
	# بررسی انرژی
	if GameData.get_energy() <= 0:
		_show_no_energy_popup()
		return
	
	# استفاده از انرژی
	GameData.use_energy(1)
	
	# رفتن به صفحه بازی
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Game.tscn"))

func _show_no_energy_popup() -> void:
	"""نمایش پاپ‌آپ کمبود انرژی"""
	# TODO: پیاده‌سازی پاپ‌آپ
	pass

# ═══════════════════════════════════════════════════════════════
# مدیریت فصل‌ها
# ═══════════════════════════════════════════════════════════════
func _on_chapter_selected(chapter: int) -> void:
	AudioManager.play_click()
	if chapter != current_chapter:
		_load_chapter(chapter)

func _update_chapter_tabs() -> void:
	"""بروزرسانی وضعیت تب‌ها"""
	var chapters: Array = chapter_tabs.get_children()
	for i in range(chapters.size()):
		var chapter_btn: Button = chapters[i]
		if i + 1 == current_chapter:
			chapter_btn.modulate = Color(1, 0.9, 0.5)
		else:
			chapter_btn.modulate = Color.WHITE

func _scroll_to_current_level() -> void:
	"""اسکرول به مرحله فعلی"""
	var current_level: int = GameData.player_data["current_level"]
	var chapter_start: int = (current_chapter - 1) * LEVELS_PER_CHAPTER + 1
	var chapter_end: int = current_chapter * LEVELS_PER_CHAPTER
	
	if current_level >= chapter_start and current_level <= chapter_end:
		var index: int = current_level - chapter_start
		if index < level_buttons.size():
			var button: Control = level_buttons[index]
			var target_scroll: float = button.position.y - scroll_container.size.y / 2
			scroll_container.scroll_vertical = int(max(0, target_scroll))

# ═══════════════════════════════════════════════════════════════
# ناوبری
# ═══════════════════════════════════════════════════════════════
func _on_back_pressed() -> void:
	AudioManager.play_click()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))

# ═══════════════════════════════════════════════════════════════
# انیمیشن‌ها
# ═══════════════════════════════════════════════════════════════
func _play_entrance_animation() -> void:
	"""انیمیشن ورود"""
	modulate.a = 0
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# انیمیشن دکمه‌های مرحله
	await tween.finished
	
	for i in range(level_buttons.size()):
		var button: Control = level_buttons[i]
		button.scale = Vector2.ZERO
		button.modulate.a = 0
		
		var btn_tween := button.create_tween()
		btn_tween.tween_property(button, "scale", Vector2.ONE, 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * 0.02)
		btn_tween.parallel().tween_property(button, "modulate:a", 1.0, 0.15).set_delay(i * 0.02)
