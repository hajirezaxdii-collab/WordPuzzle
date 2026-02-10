## WordGrid.gd - مدیریت جدول کلمات
## نمایش کلمات هدف و وضعیت پیدا شدن آنها
extends Control

# ═══════════════════════════════════════════════════════════════
# سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
signal word_revealed(word: String)
signal all_words_revealed

# ═══════════════════════════════════════════════════════════════
# Export ها
# ═══════════════════════════════════════════════════════════════
@export var cell_size: Vector2 = Vector2(45, 50)
@export var cell_spacing: float = 5.0
@export var max_columns: int = 8

# ═══════════════════════════════════════════════════════════════
# رفرنس‌ها
# ═══════════════════════════════════════════════════════════════
@onready var grid_container: VBoxContainer = $GridContainer

# ═══════════════════════════════════════════════════════════════
# استایل‌ها
# ═══════════════════════════════════════════════════════════════
var style_hidden: StyleBoxFlat
var style_revealed: StyleBoxFlat
var style_hint: StyleBoxFlat

# ═══════════════════════════════════════════════════════════════
# متغیرها
# ═══════════════════════════════════════════════════════════════
var words: Array[String] = []
var word_rows: Dictionary = {}  # word: HBoxContainer
var word_cells: Dictionary = {}  # word: Array[Control]
var revealed_words: Array[String] = []
var revealed_letters: Dictionary = {}  # word: Array[int] (indices)

# ═══════════════════════════════════════════════════════════════
# توابع چرخه حیات
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	_create_styles()

func _create_styles() -> void:
	"""ایجاد استایل‌ها"""
	# استایل سلول مخفی
	style_hidden = StyleBoxFlat.new()
	style_hidden.bg_color = Color(0.15, 0.15, 0.25, 0.9)
	style_hidden.border_width_left = 2
	style_hidden.border_width_top = 2
	style_hidden.border_width_right = 2
	style_hidden.border_width_bottom = 2
	style_hidden.border_color = Color(0.3, 0.3, 0.5, 0.8)
	style_hidden.corner_radius_top_left = 8
	style_hidden.corner_radius_top_right = 8
	style_hidden.corner_radius_bottom_right = 8
	style_hidden.corner_radius_bottom_left = 8
	
	# استایل سلول آشکار شده
	style_revealed = StyleBoxFlat.new()
	style_revealed.bg_color = Color(0.2, 0.5, 0.3, 0.9)
	style_revealed.border_width_left = 2
	style_revealed.border_width_top = 2
	style_revealed.border_width_right = 2
	style_revealed.border_width_bottom = 2
	style_revealed.border_color = Color(0.3, 0.7, 0.4, 1)
	style_revealed.corner_radius_top_left = 8
	style_revealed.corner_radius_top_right = 8
	style_revealed.corner_radius_bottom_right = 8
	style_revealed.corner_radius_bottom_left = 8
	
	# استایل سلول راهنما
	style_hint = StyleBoxFlat.new()
	style_hint.bg_color = Color(0.5, 0.4, 0.1, 0.9)
	style_hint.border_width_left = 2
	style_hint.border_width_top = 2
	style_hint.border_width_right = 2
	style_hint.border_width_bottom = 2
	style_hint.border_color = Color(0.7, 0.6, 0.2, 1)
	style_hint.corner_radius_top_left = 8
	style_hint.corner_radius_top_right = 8
	style_hint.corner_radius_bottom_right = 8
	style_hint.corner_radius_bottom_left = 8

# ═══════════════════════════════════════════════════════════════
# راه‌اندازی
# ═══════════════════════════════════════════════════════════════
func setup(new_words: Array) -> void:
	"""راه‌اندازی با کلمات جدید"""
	_clear_grid()
	
	# تبدیل به Array[String]
	words.clear()
	for w in new_words:
		words.append(str(w))
	
	# مرتب‌سازی بر اساس طول
	words.sort_custom(func(a, b): return a.length() > b.length())
	
	_create_word_rows()
	_play_entrance_animation()

func _clear_grid() -> void:
	"""پاک کردن جدول"""
	for child in grid_container.get_children():
		child.queue_free()
	
	word_rows.clear()
	word_cells.clear()
	revealed_words.clear()
	revealed_letters.clear()

func _create_word_rows() -> void:
	"""ایجاد ردیف‌های کلمات"""
	for word in words:
		var row := _create_word_row(word)
		grid_container.add_child(row)
		word_rows[word] = row

func _create_word_row(word: String) -> HBoxContainer:
	"""ایجاد یک ردیف کلمه"""
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(cell_spacing))
	
	var cells: Array[Control] = []
	
	# ایجاد سلول‌ها (از راست به چپ برای فارسی)
	for i in range(word.length() - 1, -1, -1):
		var cell := _create_cell(word[i], i)
		row.add_child(cell)
		cells.append(cell)
	
	# معکوس کردن برای ترتیب صحیح
	cells.reverse()
	word_cells[word] = cells
	revealed_letters[word] = []
	
	return row

func _create_cell(letter: String, index: int) -> Control:
	"""ایجاد یک سلول حرف"""
	var cell := PanelContainer.new()
	cell.custom_minimum_size = cell_size
	cell.add_theme_stylebox_override("panel", style_hidden.duplicate())
	cell.set_meta("letter", letter)
	cell.set_meta("index", index)
	cell.set_meta("revealed", false)
	
	var label := Label.new()
	label.text = ""  # مخفی
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	cell.add_child(label)
	
	cell.set_meta("label", label)
	
	return cell

# ═══════════════════════════════════════════════════════════════
# آشکار کردن کلمات
# ═══════════════════════════════════════════════════════════════
func reveal_word(word: String) -> void:
	"""آشکار کردن کامل یک کلمه"""
	if word not in words or word in revealed_words:
		return
	
	revealed_words.append(word)
	var cells: Array = word_cells.get(word, [])
	
	# انیمیشن آشکار شدن
	for i in range(cells.size()):
		var cell: Control = cells[i]
		_reveal_cell(cell, word[i], i * 0.05)
	
	word_revealed.emit(word)
	
	# بررسی تکمیل
	if revealed_words.size() >= words.size():
		all_words_revealed.emit()

func _reveal_cell(cell: Control, letter: String, delay: float = 0.0) -> void:
	"""آشکار کردن یک سلول"""
	if cell.get_meta("revealed"):
		return
	
	cell.set_meta("revealed", true)
	var label: Label = cell.get_meta("label")
	
	# انیمیشن
	var tween := cell.create_tween()
	
	# Flip effect
	tween.tween_property(cell, "scale:x", 0.0, 0.15).set_delay(delay)
	tween.tween_callback(func():
		label.text = letter
		cell.add_theme_stylebox_override("panel", style_revealed.duplicate())
	)
	tween.tween_property(cell, "scale:x", 1.0, 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Bounce
	tween.tween_property(cell, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.1)

func reveal_letter_in_word(word: String) -> void:
	"""آشکار کردن یک حرف از یک کلمه (راهنما)"""
	if word not in words or word in revealed_words:
		return
	
	var cells: Array = word_cells.get(word, [])
	var revealed_indices: Array = revealed_letters.get(word, [])
	
	# پیدا کردن اولین حرف آشکار نشده
	for i in range(cells.size()):
		if i not in revealed_indices:
			var cell: Control = cells[i]
			_reveal_cell_as_hint(cell, word[i])
			revealed_indices.append(i)
			revealed_letters[word] = revealed_indices
			break

func _reveal_cell_as_hint(cell: Control, letter: String) -> void:
	"""آشکار کردن سلول به عنوان راهنما"""
	if cell.get_meta("revealed"):
		return
	
	cell.set_meta("revealed", true)
	cell.set_meta("is_hint", true)
	var label: Label = cell.get_meta("label")
	
	# انیمیشن
	var tween := cell.create_tween()
	tween.tween_property(cell, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_callback(func():
		label.text = letter
		cell.add_theme_stylebox_override("panel", style_hint.duplicate())
	)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

# ═══════════════════════════════════════════════════════════════
# انیمیشن‌ها
# ═══════════════════════════════════════════════════════════════
func _play_entrance_animation() -> void:
	"""انیمیشن ورود جدول"""
	var delay: float = 0.0
	
	for word in words:
		var cells: Array = word_cells.get(word, [])
		for cell in cells:
			cell.scale = Vector2.ZERO
			cell.modulate.a = 0
			
			var tween := cell.create_tween()
			tween.tween_property(cell, "scale", Vector2.ONE, 0.2)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
			tween.parallel().tween_property(cell, "modulate:a", 1.0, 0.15).set_delay(delay)
			
			delay += 0.02

func shake_word(word: String) -> void:
	"""لرزش یک کلمه"""
	var cells: Array = word_cells.get(word, [])
	
	for cell in cells:
		var original_pos: Vector2 = cell.position
		var tween := cell.create_tween()
		
		for i in range(3):
			tween.tween_property(cell, "position:x", original_pos.x + 5, 0.05)
			tween.tween_property(cell, "position:x", original_pos.x - 5, 0.05)
		
		tween.tween_property(cell, "position:x", original_pos.x, 0.05)

func highlight_word(word: String, color: Color = Color.YELLOW) -> void:
	"""هایلایت یک کلمه"""
	var cells: Array = word_cells.get(word, [])
	
	for cell in cells:
		var tween := cell.create_tween()
		tween.tween_property(cell, "modulate", color, 0.2)
		tween.tween_property(cell, "modulate", Color.WHITE, 0.3)

# ═══════════════════════════════════════════════════════════════
# توابع کمکی
# ═══════════════════════════════════════════════════════════════
func is_word_revealed(word: String) -> bool:
	return word in revealed_words

func get_revealed_count() -> int:
	return revealed_words.size()

func get_total_count() -> int:
	return words.size()

func get_progress() -> float:
	if words.size() == 0:
		return 1.0
	return float(revealed_words.size()) / float(words.size())
