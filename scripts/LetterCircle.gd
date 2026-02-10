## LetterCircle.gd - مدیریت دایره حروف
## کنترل انتخاب و اتصال حروف توسط کاربر
extends Control

# ═══════════════════════════════════════════════════════════════
# سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
signal letter_selected(letter: String, button: Control)
signal letter_deselected(letter: String, button: Control)
signal word_submitted(word: String)
signal selection_cleared

# ═══════════════════════════════════════════════════════════════
# Export ها
# ═══════════════════════════════════════════════════════════════
@export var circle_radius: float = 120.0
@export var letter_button_size: float = 70.0
@export var min_swipe_distance: float = 30.0

# ═══════════════════════════════════════════════════════════════
# رفرنس‌ها
# ═══════════════════════════════════════════════════════════════
@onready var letters_container: Control = $LettersContainer
@onready var connection_line: Line2D = $ConnectionLine
@onready var circle_bg: Panel = $CircleBackground

# ═══════════════════════════════════════════════════════════════
# استایل‌ها
# ═══════════════════════════════════════════════════════════════
var style_normal: StyleBoxFlat
var style_selected: StyleBoxFlat
var letter_settings: LabelSettings

# ═══════════════════════════════════════════════════════════════
# متغیرها
# ═══════════════════════════════════════════════════════════════
var letters: String = ""
var letter_buttons: Array[Control] = []
var selected_buttons: Array[Control] = []
var selected_letters: String = ""
var is_dragging: bool = false
var last_touch_position: Vector2 = Vector2.ZERO

# ═══════════════════════════════════════════════════════════════
# توابع چرخه حیات
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	_load_styles()

func _load_styles() -> void:
	"""بارگذاری استایل‌ها"""
	style_normal = preload("res://resources/themes/letter_normal.tres") if ResourceLoader.exists("res://resources/themes/letter_normal.tres") else _create_default_style_normal()
	style_selected = preload("res://resources/themes/letter_selected.tres") if ResourceLoader.exists("res://resources/themes/letter_selected.tres") else _create_default_style_selected()
	letter_settings = _create_letter_settings()

func _create_default_style_normal() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.25, 0.4, 1)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 0.5, 0.7, 1)
	style.corner_radius_top_left = 35
	style.corner_radius_top_right = 35
	style.corner_radius_bottom_right = 35
	style.corner_radius_bottom_left = 35
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style

func _create_default_style_selected() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.6, 0.9, 1)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.5, 0.8, 1, 1)
	style.corner_radius_top_left = 35
	style.corner_radius_top_right = 35
	style.corner_radius_bottom_right = 35
	style.corner_radius_bottom_left = 35
	style.shadow_color = Color(0.2, 0.5, 0.8, 0.5)
	style.shadow_size = 10
	return style

func _create_letter_settings() -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_size = 42
	settings.font_color = Color.WHITE
	settings.shadow_size = 2
	settings.shadow_color = Color(0, 0, 0, 0.4)
	settings.shadow_offset = Vector2(1, 2)
	return settings

# ═══════════════════════════════════════════════════════════════
# راه‌اندازی
# ═══════════════════════════════════════════════════════════════
func setup(new_letters: String) -> void:
	"""راه‌اندازی با حروف جدید"""
	letters = new_letters
	_clear_letters()
	_create_letter_buttons()
	_position_letters()

func _clear_letters() -> void:
	"""پاک کردن حروف قبلی"""
	for button in letter_buttons:
		button.queue_free()
	letter_buttons.clear()
	selected_buttons.clear()
	selected_letters = ""
	connection_line.clear_points()

func _create_letter_buttons() -> void:
	"""ایجاد دکمه‌های حروف"""
	for i in range(letters.length()):
		var letter: String = letters[i]
		var button := _create_letter_button(letter, i)
		letters_container.add_child(button)
		letter_buttons.append(button)

func _create_letter_button(letter: String, index: int) -> Control:
	"""ایجاد یک دکمه حرف"""
	var container := Control.new()
	container.custom_minimum_size = Vector2(letter_button_size, letter_button_size)
	container.size = Vector2(letter_button_size, letter_button_size)
	container.set_meta("letter", letter)
	container.set_meta("index", index)
	container.set_meta("selected", false)
	
	# پنل پس‌زمینه
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", style_normal.duplicate())
	container.add_child(panel)
	
	# لیبل حرف
	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = letter
	label.label_settings = letter_settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	container.set_meta("panel", panel)
	container.set_meta("label", label)
	
	return container

func _position_letters() -> void:
	"""چیدمان حروف در دایره"""
	var center: Vector2 = size / 2
	var count: int = letter_buttons.size()
	
	if count == 0:
		return
	
	# اگر فقط یک حرف داریم، در مرکز قرار بده
	if count == 1:
		var button: Control = letter_buttons[0]
		button.position = center - button.size / 2
		return
	
	# چیدمان دایره‌ای
	var angle_step: float = TAU / count
	var start_angle: float = -PI / 2  # شروع از بالا
	
	for i in range(count):
		var angle: float = start_angle + (i * angle_step)
		var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * circle_radius
		var button: Control = letter_buttons[i]
		button.position = pos - button.size / 2
		
		# انیمیشن ورود
		button.scale = Vector2.ZERO
		button.modulate.a = 0
		
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(i * 0.05)
		tween.parallel().tween_property(button, "modulate:a", 1.0, 0.2).set_delay(i * 0.05)

# ═══════════════════════════════════════════════════════════════
# مدیریت ورودی
# ═══════════════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			_on_touch_start(event.position)
		else:
			_on_touch_end(event.position)
	
	elif event is InputEventMouseMotion and is_dragging:
		_on_touch_move(event.position)
	
	# پشتیبانی از تاچ
	elif event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_start(event.position)
		else:
			_on_touch_end(event.position)
	
	elif event is InputEventScreenDrag and is_dragging:
		_on_touch_move(event.position)

func _on_touch_start(pos: Vector2) -> void:
	"""شروع لمس"""
	var local_pos: Vector2 = get_global_transform().affine_inverse() * pos
	var button: Control = _get_button_at_position(local_pos)
	
	if button:
		is_dragging = true
		last_touch_position = local_pos
		_select_button(button)

func _on_touch_move(pos: Vector2) -> void:
	"""حرکت لمس"""
	if not is_dragging:
		return
	
	var local_pos: Vector2 = get_global_transform().affine_inverse() * pos
	var button: Control = _get_button_at_position(local_pos)
	
	# بروزرسانی خط
	_update_connection_line(local_pos)
	
	if button:
		if button.get_meta("selected"):
			# بررسی برگشت (حذف آخرین حرف)
			if selected_buttons.size() > 1 and button == selected_buttons[-2]:
				_deselect_last_button()
		else:
			_select_button(button)
	
	last_touch_position = local_pos

func _on_touch_end(pos: Vector2) -> void:
	"""پایان لمس"""
	if not is_dragging:
		return
	
	is_dragging = false
	
	# ارسال کلمه
	if selected_letters.length() >= 2:
		word_submitted.emit(selected_letters)
	else:
		selection_cleared.emit()
	
	_clear_selection_internal()

func _get_button_at_position(pos: Vector2) -> Control:
	"""پیدا کردن دکمه در موقعیت"""
	for button in letter_buttons:
		var rect := Rect2(button.position, button.size)
		# گسترش ناحیه لمس
		rect = rect.grow(10)
		if rect.has_point(pos):
			return button
	return null

# ═══════════════════════════════════════════════════════════════
# مدیریت انتخاب
# ═══════════════════════════════════════════════════════════════
func _select_button(button: Control) -> void:
	"""انتخاب یک دکمه"""
	if button.get_meta("selected"):
		return
	
	button.set_meta("selected", true)
	selected_buttons.append(button)
	selected_letters += button.get_meta("letter")
	
	# تغییر استایل
	var panel: Panel = button.get_meta("panel")
	panel.add_theme_stylebox_override("panel", style_selected.duplicate())
	
	# انیمیشن
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# بروزرسانی خط
	connection_line.add_point(button.position + button.size / 2)
	
	letter_selected.emit(button.get_meta("letter"), button)

func _deselect_last_button() -> void:
	"""لغو انتخاب آخرین دکمه"""
	if selected_buttons.is_empty():
		return
	
	var button: Control = selected_buttons.pop_back()
	button.set_meta("selected", false)
	selected_letters = selected_letters.substr(0, selected_letters.length() - 1)
	
	# تغییر استایل
	var panel: Panel = button.get_meta("panel")
	panel.add_theme_stylebox_override("panel", style_normal.duplicate())
	
	# انیمیشن
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)
	
	# بروزرسانی خط
	if connection_line.get_point_count() > 0:
		connection_line.remove_point(connection_line.get_point_count() - 1)
	
	letter_deselected.emit(button.get_meta("letter"), button)

func _clear_selection_internal() -> void:
	"""پاک کردن انتخاب‌ها (داخلی)"""
	for button in selected_buttons:
		button.set_meta("selected", false)
		var panel: Panel = button.get_meta("panel")
		panel.add_theme_stylebox_override("panel", style_normal.duplicate())
		
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.1)
	
	selected_buttons.clear()
	selected_letters = ""
	connection_line.clear_points()

func clear_selection() -> void:
	"""پاک کردن انتخاب‌ها (عمومی)"""
	_clear_selection_internal()
	selection_cleared.emit()

func _update_connection_line(current_pos: Vector2) -> void:
	"""بروزرسانی خط اتصال"""
	# خط موقت به موقعیت فعلی
	if connection_line.get_point_count() > selected_buttons.size():
		connection_line.remove_point(connection_line.get_point_count() - 1)
	
	if selected_buttons.size() > 0:
		connection_line.add_point(current_pos)

# ═══════════════════════════════════════════════════════════════
# شافل
# ═══════════════════════════════════════════════════════════════
func shuffle_letters() -> void:
	"""شافل حروف"""
	clear_selection()
	
	# ذخیره موقعیت‌های فعلی
	var positions: Array[Vector2] = []
	for button in letter_buttons:
		positions.append(button.position)
	
	# شافل موقعیت‌ها
	positions.shuffle()
	
	# انیمیشن به مرکز
	var center: Vector2 = size / 2 - Vector2(letter_button_size, letter_button_size) / 2
	var tween := create_tween()
	
	for button in letter_buttons:
		tween.parallel().tween_property(button, "position", center, 0.2)
		tween.parallel().tween_property(button, "scale", Vector2(0.5, 0.5), 0.2)
		tween.parallel().tween_property(button, "rotation", TAU, 0.2)
	
	tween.tween_interval(0.1)
	
	# انیمیشن به موقعیت جدید
	for i in range(letter_buttons.size()):
		tween.parallel().tween_property(letter_buttons[i], "position", positions[i], 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(letter_buttons[i], "scale", Vector2.ONE, 0.3)
		tween.parallel().tween_property(letter_buttons[i], "rotation", 0.0, 0.3)

# ═══════════════════════════════════════════════════════════════
# افکت‌ها
# ═══════════════════════════════════════════════════════════════
func highlight_letters(letters_to_highlight: String) -> void:
	"""هایلایت حروف خاص"""
	for button in letter_buttons:
		var letter: String = button.get_meta("letter")
		if letter in letters_to_highlight:
			var tween := button.create_tween()
			tween.tween_property(button, "modulate", Color.YELLOW, 0.2)
			tween.tween_property(button, "modulate", Color.WHITE, 0.2)

func pulse_all_letters() -> void:
	"""پالس همه حروف"""
	for i in range(letter_buttons.size()):
		var button: Control = letter_buttons[i]
		var tween := button.create_tween()
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.15).set_delay(i * 0.05)
		tween.tween_property(button, "scale", Vector2.ONE, 0.15)
