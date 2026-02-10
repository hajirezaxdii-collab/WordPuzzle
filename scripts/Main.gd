## Main.gd - صفحه اصلی بازی
## مدیریت منوی اصلی و ناوبری
extends Control

# ═══════════════════════════════════════════════════════════════
# رفرنس‌های نودها
# ═══════════════════════════════════════════════════════════════
@onready var ui_animations: Node = $UIAnimations
@onready var background: ColorRect = $Background

# Top Bar
@onready var coin_count_label: Label = $TopBar/HBoxContainer/CoinContainer/CoinCount
@onready var diamond_count_label: Label = $TopBar/HBoxContainer/DiamondContainer/DiamondCount
@onready var level_label: Label = $TopBar/HBoxContainer/LevelBadge/LevelLabel
@onready var settings_button: Button = $TopBar/HBoxContainer/SettingsButton
@onready var profile_button: Button = $TopBar/HBoxContainer/ProfileButton
@onready var add_coin_button: Button = $TopBar/HBoxContainer/AddCoinButton

# Main Content
@onready var title_label: Label = $MainContent/TitleContainer/Title
@onready var play_button: Button = $MainContent/ButtonsContainer/PlayButton
@onready var levels_button: Button = $MainContent/ButtonsContainer/LevelsButton
@onready var daily_challenge_button: Button = $MainContent/ButtonsContainer/DailyChallengeButton

# Bottom Buttons
@onready var shop_button: Button = $MainContent/BottomButtons/ShopButton
@onready var daily_reward_button: Button = $MainContent/BottomButtons/DailyRewardButton
@onready var achievements_button: Button = $MainContent/BottomButtons/AchievementsButton
@onready var stats_button: Button = $MainContent/BottomButtons/StatsButton

# Energy
@onready var energy_progress: ProgressBar = $MainContent/EnergyBar/EnergyProgress
@onready var energy_label: Label = $MainContent/EnergyBar/EnergyLabel
@onready var energy_timer_label: Label = $MainContent/EnergyBar/EnergyTimer

# Popups
@onready var daily_reward_popup: Control = $DailyRewardPopup
@onready var settings_popup: Control = $SettingsPopup
@onready var music_slider: HSlider = $SettingsPopup/PopupPanel/Content/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPopup/PopupPanel/Content/SFXContainer/SFXSlider
@onready var vibration_toggle: CheckButton = $SettingsPopup/PopupPanel/Content/VibrationContainer/VibrationToggle

# ═══════════════════════════════════════════════════════════════
# متغیرها
# ═══════════════════════════════════════════════════════════════
var _bg_time: float = 0.0
var _energy_update_timer: float = 0.0

# ═══════════════════════════════════════════════════════════════
# توابع چرخه حیات
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	_connect_signals()
	_update_ui()
	_play_entrance_animation()
	_check_daily_reward()
	
	# شروع موسیقی منو
	AudioManager.play_music("menu")

func _process(delta: float) -> void:
	# بروزرسانی شیدر پس‌زمینه
	_bg_time += delta
	if background.material:
		background.material.set_shader_parameter("time", _bg_time)
	
	# بروزرسانی انرژی
	_energy_update_timer += delta
	if _energy_update_timer >= 1.0:
		_energy_update_timer = 0.0
		_update_energy_display()

# ═══════════════════════════════════════════════════════════════
# اتصال سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
func _connect_signals() -> void:
	# دکمه‌های اصلی
	play_button.pressed.connect(_on_play_pressed)
	levels_button.pressed.connect(_on_levels_pressed)
	daily_challenge_button.pressed.connect(_on_daily_challenge_pressed)
	
	# دکمه‌های پایین
	shop_button.pressed.connect(_on_shop_pressed)
	daily_reward_button.pressed.connect(_on_daily_reward_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	
	# تنظیمات
	settings_button.pressed.connect(_on_settings_pressed)
	
	# سیگنال‌های GameData
	GameData.coins_changed.connect(_on_coins_changed)
	GameData.diamonds_changed.connect(_on_diamonds_changed)
	GameData.energy_changed.connect(_on_energy_changed)
	GameData.xp_changed.connect(_on_xp_changed)
	
	# تنظیمات پاپ‌آپ
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	vibration_toggle.toggled.connect(_on_vibration_toggled)
	
	$SettingsPopup/PopupPanel/Content/CloseButton.pressed.connect(_close_settings_popup)
	$SettingsPopup/Overlay.gui_input.connect(_on_settings_overlay_input)
	
	$DailyRewardPopup/PopupPanel/Content/ClaimButton.pressed.connect(_on_claim_daily_reward)
	$DailyRewardPopup/PopupPanel/Content/CloseButton.pressed.connect(_close_daily_reward_popup)
	$DailyRewardPopup/Overlay.gui_input.connect(_on_daily_reward_overlay_input)

# ═══════════════════════════════════════════════════════════════
# بروزرسانی UI
# ═══════════════════════════════════════════════════════════════
func _update_ui() -> void:
	# ارزها
	coin_count_label.text = str(GameData.get_coins())
	diamond_count_label.text = str(GameData.get_diamonds())
	
	# سطح
	level_label.text = "سطح %d" % GameData.player_data["level"]
	
	# انرژی
	_update_energy_display()
	
	# تنظیمات
	music_slider.value = AudioManager.get_music_volume()
	sfx_slider.value = AudioManager.get_sfx_volume()
	vibration_toggle.button_pressed = GameData.player_data["vibration_enabled"]

func _update_energy_display() -> void:
	var energy: int = GameData.get_energy()
	var max_energy: int = GameData.MAX_ENERGY
	
	energy_progress.max_value = max_energy
	energy_progress.value = energy
	energy_label.text = "%d/%d" % [energy, max_energy]
	
	# تایمر ریکاوری
	var recovery_time: int = GameData.get_energy_recovery_time()
	if recovery_time > 0 and energy < max_energy:
		var minutes: int = recovery_time / 60
		var seconds: int = recovery_time % 60
		energy_timer_label.text = "%d:%02d" % [minutes, seconds]
	else:
		energy_timer_label.text = ""

func _on_coins_changed(new_amount: int) -> void:
	# انیمیشن تغییر سکه
	ui_animations.animate_number_change(coin_count_label, new_amount)

func _on_diamonds_changed(new_amount: int) -> void:
	ui_animations.animate_number_change(diamond_count_label, new_amount)

func _on_energy_changed(new_amount: int) -> void:
	_update_energy_display()

func _on_xp_changed(new_xp: int, new_level: int) -> void:
	level_label.text = "سطح %d" % new_level

# ═══════════════════════════════════════════════════════════════
# انیمیشن‌ها
# ═══════════════════════════════════════════════════════════════
func _play_entrance_animation() -> void:
	# مخفی کردن اولیه
	modulate.a = 0
	
	var all_buttons: Array[Button] = [
		play_button, levels_button, daily_challenge_button,
		shop_button, daily_reward_button, achievements_button, stats_button
	]
	
	for button in all_buttons:
		button.scale = Vector2(0.8, 0.8)
		button.modulate.a = 0
	
	title_label.position.y -= 50
	title_label.modulate.a = 0
	
	# شروع انیمیشن
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# عنوان
	tween.parallel().tween_property(title_label, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tween.parallel().tween_property(title_label, "position:y", title_label.position.y + 50, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.2)
	
	# دکمه‌ها
	var delay: float = 0.4
	for button in all_buttons:
		tween.parallel().tween_property(button, "modulate:a", 1.0, 0.3).set_delay(delay)
		tween.parallel().tween_property(button, "scale", Vector2.ONE, 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
		delay += 0.05

# ═══════════════════════════════════════════════════════════════
# هندلرهای دکمه‌ها
# ═══════════════════════════════════════════════════════════════
func _on_play_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(play_button)
	
	# بررسی انرژی
	if GameData.get_energy() <= 0:
		_show_no_energy_popup()
		return
	
	# رفتن به آخرین مرحله باز شده
	_go_to_game(GameData.player_data["current_level"])

func _on_levels_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(levels_button)
	
	await _play_exit_animation()
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_daily_challenge_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(daily_challenge_button)
	# TODO: صفحه چالش روزانه
	pass

func _on_shop_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(shop_button)
	# TODO: صفحه فروشگاه
	pass

func _on_daily_reward_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(daily_reward_button)
	_show_daily_reward_popup()

func _on_achievements_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(achievements_button)
	# TODO: صفحه دستاوردها
	pass

func _on_stats_pressed() -> void:
	AudioManager.play_click()
	ui_animations.button_press_effect(stats_button)
	# TODO: صفحه آمار
	pass

func _on_settings_pressed() -> void:
	AudioManager.play_click()
	_show_settings_popup()

func _go_to_game(level_id: int) -> void:
	GameData.player_data["current_level"] = level_id
	await _play_exit_animation()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _play_exit_animation() -> Signal:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	return tween.finished

# ═══════════════════════════════════════════════════════════════
# پاپ‌آپ تنظیمات
# ═══════════════════════════════════════════════════════════════
func _show_settings_popup() -> void:
	settings_popup.visible = true
	settings_popup.modulate.a = 0
	
	var panel: Control = $SettingsPopup/PopupPanel
	panel.scale = Vector2(0.8, 0.8)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(settings_popup, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _close_settings_popup() -> void:
	AudioManager.play_click()
	
	var tween := create_tween()
	tween.tween_property(settings_popup, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): settings_popup.visible = false)

func _on_settings_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_settings_popup()

func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	GameData.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	GameData.set_sfx_volume(value)
	if value > 0:
		AudioManager.play_click()

func _on_vibration_toggled(enabled: bool) -> void:
	GameData.player_data["vibration_enabled"] = enabled
	SaveManager.save_game()
	if enabled:
		Input.vibrate_handheld(100)

# ═══════════════════════════════════════════════════════════════
# پاپ‌آپ جایزه روزانه
# ═══════════════════════════════════════════════════════════════
func _check_daily_reward() -> void:
	if GameData.can_claim_daily_reward():
		# نمایش نشانگر روی دکمه
		daily_reward_button.modulate = Color(1, 1, 0.5)
		_pulse_button(daily_reward_button)

func _pulse_button(button: Button) -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(button, "scale", Vector2.ONE, 0.5)

func _show_daily_reward_popup() -> void:
	if not GameData.can_claim_daily_reward():
		# نمایش پیام
		return
	
	daily_reward_popup.visible = true
	daily_reward_popup.modulate.a = 0
	
	var panel: Control = $DailyRewardPopup/PopupPanel
	panel.scale = Vector2(0.8, 0.8)
	
	# بروزرسانی اطلاعات
	var day: int = GameData.player_data["streak_days"] + 1
	if day > 7: day = 1
	$DailyRewardPopup/PopupPanel/Content/DayLabel.text = "روز %d" % day
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(daily_reward_popup, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _close_daily_reward_popup() -> void:
	var tween := create_tween()
	tween.tween_property(daily_reward_popup, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): daily_reward_popup.visible = false)

func _on_daily_reward_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_daily_reward_popup()

func _on_claim_daily_reward() -> void:
	AudioManager.play_sfx("reward")
	
	var reward: Dictionary = GameData.claim_daily_reward()
	if reward.is_empty():
		return
	
	# انیمیشن جمع‌آوری
	# TODO: افکت ذرات و انیمیشن
	
	_close_daily_reward_popup()
	daily_reward_button.modulate = Color.WHITE
	
	# بروزرسانی UI
	_update_ui()

func _show_no_energy_popup() -> void:
	# TODO: پاپ‌آپ عدم انرژی
	pass
