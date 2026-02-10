## SaveManager.gd - مدیریت ذخیره و بارگذاری داده‌ها
## با رمزنگاری AES برای امنیت داده‌ها
extends Node

# ═══════════════════════════════════════════════════════════════
# سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
signal save_completed
signal load_completed
signal save_error(message: String)
signal load_error(message: String)

# ═══════════════════════════════════════════════════════════════
# ثابت‌ها
# ═══════════════════════════════════════════════════════════════
const SAVE_PATH: String = "user://save_data.dat"
const BACKUP_PATH: String = "user://save_backup.dat"
const ENCRYPTION_KEY: String = "PersianWordPuzzle2024SecretKey!!"  # 32 کاراکتر
const SAVE_VERSION: int = 1

# ═══════════════════════════════════════════════════════════════
# متغیرها
# ═══════════════════════════════════════════════════════════════
var _save_timer: Timer
var _auto_save_interval: float = 30.0  # ذخیره خودکار هر 30 ثانیه
var _is_saving: bool = false
var _pending_save: bool = false

# ═══════════════════════════════════════════════════════════════
# توابع چرخه حیات
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	# تنظیم تایمر ذخیره خودکار
	_save_timer = Timer.new()
	_save_timer.wait_time = _auto_save_interval
	_save_timer.timeout.connect(_on_auto_save_timer)
	_save_timer.autostart = true
	add_child(_save_timer)

func _notification(what: int) -> void:
	# ذخیره هنگام خروج از بازی
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game_sync()

# ═══════════════════════════════════════════════════════════════
# ذخیره‌سازی
# ═══════════════════════════════════════════════════════════════
func save_game() -> void:
	"""ذخیره غیرهمزمان بازی"""
	if _is_saving:
		_pending_save = true
		return
	
	_is_saving = true
	
	# اجرا در Thread جداگانه برای جلوگیری از lag
	var thread := Thread.new()
	thread.start(_save_thread_function)

func _save_thread_function() -> void:
	"""تابع ذخیره در Thread"""
	var save_data: Dictionary = _prepare_save_data()
	var json_string: String = JSON.stringify(save_data)
	var encrypted: PackedByteArray = _encrypt_data(json_string)
	
	# ابتدا بکاپ
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
	
	# ذخیره فایل جدید
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_buffer(encrypted)
		file.close()
		call_deferred("_on_save_completed")
	else:
		call_deferred("_on_save_error", "خطا در باز کردن فایل ذخیره")

func _on_save_completed() -> void:
	_is_saving = false
	save_completed.emit()
	
	if _pending_save:
		_pending_save = false
		save_game()

func _on_save_error(message: String) -> void:
	_is_saving = false
	save_error.emit(message)
	push_error("Save Error: " + message)

func save_game_sync() -> bool:
	"""ذخیره همزمان (برای خروج از بازی)"""
	var save_data: Dictionary = _prepare_save_data()
	var json_string: String = JSON.stringify(save_data)
	var encrypted: PackedByteArray = _encrypt_data(json_string)
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_buffer(encrypted)
		file.close()
		return true
	return false

func _prepare_save_data() -> Dictionary:
	"""آماده‌سازی داده‌ها برای ذخیره"""
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player_data": GameData.player_data,
		"completed_levels": GameData.completed_levels
	}

# ═══════════════════════════════════════════════════════════════
# بارگذاری
# ═══════════════════════════════════════════════════════════════
func load_game() -> bool:
	"""بارگذاری داده‌های بازی"""
	if not FileAccess.file_exists(SAVE_PATH):
		# اگر فایل وجود ندارد، از بکاپ استفاده کن
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.copy_absolute(BACKUP_PATH, SAVE_PATH)
		else:
			# بازی جدید
			load_completed.emit()
			return true
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		load_error.emit("خطا در باز کردن فایل ذخیره")
		return false
	
	var encrypted: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	
	var json_string: String = _decrypt_data(encrypted)
	if json_string.is_empty():
		# تلاش با بکاپ
		return _try_load_backup()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		return _try_load_backup()
	
	var save_data: Dictionary = json.data
	
	# بررسی نسخه و مهاجرت در صورت نیاز
	if save_data.get("version", 0) < SAVE_VERSION:
		save_data = _migrate_save_data(save_data)
	
	# بارگذاری داده‌ها
	_apply_save_data(save_data)
	
	load_completed.emit()
	return true

func _try_load_backup() -> bool:
	"""تلاش برای بارگذاری از بکاپ"""
	if not FileAccess.file_exists(BACKUP_PATH):
		load_error.emit("فایل ذخیره خراب است")
		return false
	
	DirAccess.copy_absolute(BACKUP_PATH, SAVE_PATH)
	return load_game()

func _apply_save_data(save_data: Dictionary) -> void:
	"""اعمال داده‌های بارگذاری شده"""
	if save_data.has("player_data"):
		# ادغام با داده‌های پیش‌فرض (برای فیلدهای جدید)
		for key in save_data["player_data"].keys():
			GameData.player_data[key] = save_data["player_data"][key]
	
	if save_data.has("completed_levels"):
		GameData.completed_levels = save_data["completed_levels"]

func _migrate_save_data(old_data: Dictionary) -> Dictionary:
	"""مهاجرت داده‌های قدیمی به نسخه جدید"""
	# در اینجا منطق مهاجرت برای نسخه‌های مختلف
	old_data["version"] = SAVE_VERSION
	return old_data

# ═══════════════════════════════════════════════════════════════
# رمزنگاری
# ═══════════════════════════════════════════════════════════════
func _encrypt_data(data: String) -> PackedByteArray:
	"""رمزنگاری داده‌ها با AES-256"""
	var aes := AESContext.new()
	var key: PackedByteArray = ENCRYPTION_KEY.to_utf8_buffer()
	var iv: PackedByteArray = _generate_iv()
	
	# Padding برای AES
	var data_bytes: PackedByteArray = data.to_utf8_buffer()
	var padding_size: int = 16 - (data_bytes.size() % 16)
	for i in range(padding_size):
		data_bytes.append(padding_size)
	
	aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv)
	var encrypted: PackedByteArray = aes.update(data_bytes)
	aes.finish()
	
	# ترکیب IV و داده رمزنگاری شده
	var result: PackedByteArray = iv
	result.append_array(encrypted)
	return result

func _decrypt_data(data: PackedByteArray) -> String:
	"""رمزگشایی داده‌ها"""
	if data.size() < 32:  # حداقل 16 بایت IV + 16 بایت داده
		return ""
	
	var aes := AESContext.new()
	var key: PackedByteArray = ENCRYPTION_KEY.to_utf8_buffer()
	var iv: PackedByteArray = data.slice(0, 16)
	var encrypted: PackedByteArray = data.slice(16)
	
	aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
	var decrypted: PackedByteArray = aes.update(encrypted)
	aes.finish()
	
	# حذف Padding
	if decrypted.size() > 0:
		var padding_size: int = decrypted[-1]
		if padding_size <= 16:
			decrypted = decrypted.slice(0, decrypted.size() - padding_size)
	
	return decrypted.get_string_from_utf8()

func _generate_iv() -> PackedByteArray:
	"""تولید IV تصادفی 16 بایتی"""
	var iv: PackedByteArray = PackedByteArray()
	for i in range(16):
		iv.append(randi() % 256)
	return iv

# ═══════════════════════════════════════════════════════════════
# توابع کمکی
# ═══════════════════════════════════════════════════════════════
func _on_auto_save_timer() -> void:
	save_game()

func delete_save() -> void:
	"""حذف داده‌های ذخیره شده"""
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)

func has_save() -> bool:
	"""بررسی وجود فایل ذخیره"""
	return FileAccess.file_exists(SAVE_PATH)

func get_save_info() -> Dictionary:
	"""دریافت اطلاعات فایل ذخیره"""
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	
	return {
		"size": file.get_length(),
		"modified": FileAccess.get_modified_time(SAVE_PATH)
	}

# ═══════════════════════════════════════════════════════════════
# Export/Import
# ═══════════════════════════════════════════════════════════════
func export_save_to_string() -> String:
	"""صدور داده‌های ذخیره به صورت Base64"""
	var save_data: Dictionary = _prepare_save_data()
	var json_string: String = JSON.stringify(save_data)
	return Marshalls.utf8_to_base64(json_string)

func import_save_from_string(base64_data: String) -> bool:
	"""وارد کردن داده‌ها از Base64"""
	var json_string: String = Marshalls.base64_to_utf8(base64_data)
	if json_string.is_empty():
		return false
	
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return false
	
	var save_data: Dictionary = json.data
	_apply_save_data(save_data)
	save_game()
	return true
