## UIAnimations.gd - مدیریت انیمیشن‌های UI
## شامل تمام انیمیشن‌های رابط کاربری
extends Node

# ═══════════════════════════════════════════════════════════════
# ثابت‌های انیمیشن
# ═══════════════════════════════════════════════════════════════
const BUTTON_PRESS_SCALE: float = 0.9
const BUTTON_PRESS_DURATION: float = 0.1
const POPUP_DURATION: float = 0.3
const SLIDE_DURATION: float = 0.4
const FADE_DURATION: float = 0.25
const BOUNCE_DURATION: float = 0.5
const NUMBER_CHANGE_DURATION: float = 0.3

# ═══════════════════════════════════════════════════════════════
# انیمیشن دکمه‌ها
# ═══════════════════════════════════════════════════════════════
func button_press_effect(button: Button) -> void:
	"""افکت فشردن دکمه"""
	var original_scale: Vector2 = button.scale
	
	var tween := button.create_tween()
	tween.tween_property(button, "scale", original_scale * BUTTON_PRESS_SCALE, BUTTON_PRESS_DURATION)
	tween.tween_property(button, "scale", original_scale, BUTTON_PRESS_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func button_hover_effect(button: Button, is_hovering: bool) -> void:
	"""افکت هاور دکمه"""
	var target_scale: Vector2 = Vector2(1.05, 1.05) if is_hovering else Vector2.ONE
	
	var tween := button.create_tween()
	tween.tween_property(button, "scale", target_scale, 0.15)\
		.set_trans(Tween.TRANS_SINE)

func button_shake(button: Button, intensity: float = 5.0, duration: float = 0.3) -> void:
	"""لرزش دکمه (برای خطا)"""
	var original_pos: Vector2 = button.position
	var tween := button.create_tween()
	
	for i in range(5):
		var offset := Vector2(randf_range(-intensity, intensity), 0)
		tween.tween_property(button, "position", original_pos + offset, duration / 10)
	
	tween.tween_property(button, "position", original_pos, duration / 10)

# ═══════════════════════════════════════════════════════════════
# انیمیشن پاپ‌آپ
# ═══════════════════════════════════════════════════════════════
func show_popup(popup: Control, panel: Control = null) -> void:
	"""نمایش پاپ‌آپ با انیمیشن"""
	popup.visible = true
	popup.modulate.a = 0
	
	if panel:
		panel.scale = Vector2(0.7, 0.7)
		panel.pivot_offset = panel.size / 2
	
	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "modulate:a", 1.0, POPUP_DURATION)
	
	if panel:
		tween.tween_property(panel, "scale", Vector2.ONE, POPUP_DURATION)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_popup(popup: Control, callback: Callable = Callable()) -> void:
	"""مخفی کردن پاپ‌آپ با انیمیشن"""
	var tween := popup.create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func():
		popup.visible = false
		if callback.is_valid():
			callback.call()
	)

func popup_bounce(panel: Control) -> void:
	"""افکت بانس برای پنل پاپ‌آپ"""
	var tween := panel.create_tween()
	tween.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ═══════════════════════════════════════════════════════════════
# انیمیشن Slide
# ═══════════════════════════════════════════════════════════════
func slide_in_from_right(control: Control, delay: float = 0.0) -> void:
	"""ورود از راست"""
	var target_x: float = control.position.x
	control.position.x = control.get_viewport_rect().size.x
	control.modulate.a = 0
	
	var tween := control.create_tween()
	tween.tween_property(control, "position:x", target_x, SLIDE_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.parallel().tween_property(control, "modulate:a", 1.0, FADE_DURATION).set_delay(delay)

func slide_in_from_left(control: Control, delay: float = 0.0) -> void:
	"""ورود از چپ"""
	var target_x: float = control.position.x
	control.position.x = -control.size.x
	control.modulate.a = 0
	
	var tween := control.create_tween()
	tween.tween_property(control, "position:x", target_x, SLIDE_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.parallel().tween_property(control, "modulate:a", 1.0, FADE_DURATION).set_delay(delay)

func slide_in_from_top(control: Control, delay: float = 0.0) -> void:
	"""ورود از بالا"""
	var target_y: float = control.position.y
	control.position.y = -control.size.y
	control.modulate.a = 0
	
	var tween := control.create_tween()
	tween.tween_property(control, "position:y", target_y, SLIDE_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.parallel().tween_property(control, "modulate:a", 1.0, FADE_DURATION).set_delay(delay)

func slide_in_from_bottom(control: Control, delay: float = 0.0) -> void:
	"""ورود از پایین"""
	var target_y: float = control.position.y
	control.position.y = control.get_viewport_rect().size.y
	control.modulate.a = 0
	
	var tween := control.create_tween()
	tween.tween_property(control, "position:y", target_y, SLIDE_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.parallel().tween_property(control, "modulate:a", 1.0, FADE_DURATION).set_delay(delay)

func slide_out_to_right(control: Control, callback: Callable = Callable()) -> void:
	"""خروج به راست"""
	var target_x: float = control.get_viewport_rect().size.x
	
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "position:x", target_x, SLIDE_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(control, "modulate:a", 0.0, FADE_DURATION)
	
	if callback.is_valid():
		tween.chain().tween_callback(callback)

# ═══════════════════════════════════════════════════════════════
# انیمیشن اعداد
# ═══════════════════════════════════════════════════════════════
func animate_number_change(label: Label, target_value: int, prefix: String = "", suffix: String = "") -> void:
	"""انیمیشن تغییر عدد"""
	var current_text: String = label.text.replace(prefix, "").replace(suffix, "")
	var current_value: int = int(current_text) if current_text.is_valid_int() else 0
	
	if current_value == target_value:
		return
	
	# افکت scale
	var scale_tween := label.create_tween()
	scale_tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
	scale_tween.tween_property(label, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# شمارش عدد
	var number_tween := label.create_tween()
	number_tween.tween_method(
		func(value: int): label.text = prefix + str(value) + suffix,
		current_value,
		target_value,
		NUMBER_CHANGE_DURATION
	).set_trans(Tween.TRANS_SINE)
	
	# تغییر رنگ موقت
	var is_increase: bool = target_value > current_value
	var highlight_color: Color = Color.GREEN if is_increase else Color.RED
	var original_color: Color = label.modulate
	
	var color_tween := label.create_tween()
	color_tween.tween_property(label, "modulate", highlight_color, 0.1)
	color_tween.tween_property(label, "modulate", original_color, 0.3)

func animate_score_popup(position: Vector2, value: int, parent: Control) -> void:
	"""نمایش امتیاز پاپ‌آپ"""
	var popup_label := Label.new()
	popup_label.text = "+%d" % value if value > 0 else str(value)
	popup_label.position = position
	popup_label.add_theme_font_size_override("font_size", 32)
	popup_label.add_theme_color_override("font_color", Color.YELLOW if value > 0 else Color.RED)
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.z_index = 100
	parent.add_child(popup_label)
	
	var tween := popup_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup_label, "position:y", position.y - 80, 0.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup_label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(popup_label.queue_free)

# ═══════════════════════════════════════════════════════════════
# انیمیشن‌های بازی
# ═══════════════════════════════════════════════════════════════
func animate_letter_select(letter_button: Control) -> void:
	"""انیمیشن انتخاب حرف"""
	var tween := letter_button.create_tween()
	tween.tween_property(letter_button, "scale", Vector2(1.15, 1.15), 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func animate_letter_deselect(letter_button: Control) -> void:
	"""انیمیشن عدم انتخاب حرف"""
	var tween := letter_button.create_tween()
	tween.tween_property(letter_button, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_SINE)

func animate_word_found(word_cells: Array, callback: Callable = Callable()) -> void:
	"""انیمیشن پیدا کردن کلمه"""
	var tween := create_tween()
	
	for i in range(word_cells.size()):
		var cell: Control = word_cells[i]
		tween.parallel().tween_property(cell, "scale", Vector2(1.3, 1.3), 0.15).set_delay(i * 0.05)
		tween.parallel().tween_property(cell, "modulate", Color.GREEN, 0.15).set_delay(i * 0.05)
	
	tween.tween_interval(0.2)
	
	for cell in word_cells:
		tween.parallel().tween_property(cell, "scale", Vector2.ONE, 0.2)
		tween.parallel().tween_property(cell, "modulate", Color.WHITE, 0.2)
	
	if callback.is_valid():
		tween.tween_callback(callback)

func animate_word_wrong(letters: Array) -> void:
	"""انیمیشن کلمه اشتباه"""
	for letter in letters:
		button_shake(letter, 3.0, 0.2)
	
	var tween := create_tween()
	for letter in letters:
		tween.parallel().tween_property(letter, "modulate", Color.RED, 0.1)
	tween.tween_interval(0.15)
	for letter in letters:
		tween.parallel().tween_property(letter, "modulate", Color.WHITE, 0.2)

func animate_level_complete(stars: int, callback: Callable = Callable()) -> void:
	"""انیمیشن تکمیل مرحله"""
	# این انیمیشن در Game.gd پیاده‌سازی می‌شود
	pass

func animate_star(star: Control, delay: float) -> void:
	"""انیمیشن ستاره"""
	star.scale = Vector2.ZERO
	star.modulate.a = 0
	
	var tween := star.create_tween()
	tween.tween_property(star, "scale", Vector2(1.5, 1.5), 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	tween.parallel().tween_property(star, "modulate:a", 1.0, 0.2).set_delay(delay)
	tween.tween_property(star, "scale", Vector2.ONE, 0.2)

func animate_confetti(parent: Control, count: int = 50) -> void:
	"""انیمیشن کانفتی"""
	var colors: Array[Color] = [
		Color.YELLOW, Color.RED, Color.GREEN, Color.BLUE, 
		Color.MAGENTA, Color.CYAN, Color.ORANGE
	]
	
	for i in range(count):
		var confetti := ColorRect.new()
		confetti.size = Vector2(10, 10)
		confetti.color = colors[randi() % colors.size()]
		confetti.position = Vector2(
			randf_range(0, parent.size.x),
			-20
		)
		confetti.rotation = randf_range(0, TAU)
		parent.add_child(confetti)
		
		var end_pos := Vector2(
			confetti.position.x + randf_range(-100, 100),
			parent.size.y + 50
		)
		var duration: float = randf_range(1.5, 3.0)
		
		var tween := confetti.create_tween()
		tween.set_parallel(true)
		tween.tween_property(confetti, "position", end_pos, duration)
		tween.tween_property(confetti, "rotation", confetti.rotation + randf_range(-10, 10), duration)
		tween.tween_property(confetti, "modulate:a", 0.0, duration * 0.3).set_delay(duration * 0.7)
		tween.chain().tween_callback(confetti.queue_free)

# ═══════════════════════════════════════════════════════════════
# انیمیشن‌های Shuffle
# ═══════════════════════════════════════════════════════════════
func animate_shuffle(letters: Array[Control]) -> void:
	"""انیمیشن شافل حروف"""
	var center: Vector2 = Vector2.ZERO
	var positions: Array[Vector2] = []
	
	# محاسبه مرکز و ذخیره موقعیت‌ها
	for letter in letters:
		positions.append(letter.position)
		center += letter.position
	center /= letters.size()
	
	# انیمیشن به مرکز
	var tween := create_tween()
	for letter in letters:
		tween.parallel().tween_property(letter, "position", center, 0.2)
		tween.parallel().tween_property(letter, "scale", Vector2(0.5, 0.5), 0.2)
	
	# شافل موقعیت‌ها
	positions.shuffle()
	
	# انیمیشن به موقعیت جدید
	tween.tween_interval(0.1)
	for i in range(letters.size()):
		tween.parallel().tween_property(letters[i], "position", positions[i], 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(letters[i], "scale", Vector2.ONE, 0.3)

# ═══════════════════════════════════════════════════════════════
# انیمیشن‌های خط اتصال
# ═══════════════════════════════════════════════════════════════
func create_connection_line(from: Vector2, to: Vector2, parent: Control, color: Color = Color.WHITE) -> Line2D:
	"""ایجاد خط اتصال بین حروف"""
	var line := Line2D.new()
	line.add_point(from)
	line.add_point(from)  # شروع از یک نقطه
	line.width = 8.0
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	parent.add_child(line)
	
	# انیمیشن رسم خط
	var tween := line.create_tween()
	tween.tween_method(
		func(point: Vector2): line.set_point_position(1, point),
		from,
		to,
		0.1
	).set_trans(Tween.TRANS_SINE)
	
	return line

func animate_line_glow(line: Line2D) -> void:
	"""انیمیشن درخشش خط"""
	var tween := line.create_tween()
	tween.set_loops()
	tween.tween_property(line, "width", 12.0, 0.3)
	tween.tween_property(line, "width", 8.0, 0.3)

func remove_connection_line(line: Line2D) -> void:
	"""حذف خط اتصال با انیمیشن"""
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)
