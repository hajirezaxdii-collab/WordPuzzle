## ThemeManager.gd - مدیریت تم‌های بازی
## تغییر رنگ‌ها و ظاهر بازی
extends Node
class_name ThemeManager

# ═══════════════════════════════════════════════════════════════
# سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
signal theme_changed(theme_name: String)

# ═══════════════════════════════════════════════════════════════
# تم‌ها
# ═══════════════════════════════════════════════════════════════
const THEMES: Dictionary = {
	"modern": {
		"name": "مدرن",
		"icon": "🌙",
		"background_top": Color(0.1, 0.12, 0.25),
		"background_bottom": Color(0.18, 0.08, 0.22),
		"primary": Color(0.3, 0.5, 0.9),
		"secondary": Color(0.6, 0.3, 0.7),
		"accent": Color(0.4, 0.8, 0.6),
		"text": Color(1, 1, 1),
		"text_secondary": Color(0.8, 0.8, 0.9),
		"letter_bg": Color(0.2, 0.25, 0.4),
		"letter_selected": Color(0.3, 0.6, 0.9),
		"word_hidden": Color(0.15, 0.15, 0.25),
		"word_revealed": Color(0.2, 0.5, 0.3),
		"unlocked": true
	},
	"traditional": {
		"name": "سنتی ایرانی",
		"icon": "🏛️",
		"background_top": Color(0.15, 0.1, 0.08),
		"background_bottom": Color(0.25, 0.15, 0.1),
		"primary": Color(0.7, 0.5, 0.2),
		"secondary": Color(0.5, 0.3, 0.15),
		"accent": Color(0.8, 0.6, 0.2),
		"text": Color(1, 0.95, 0.85),
		"text_secondary": Color(0.9, 0.85, 0.75),
		"letter_bg": Color(0.35, 0.25, 0.15),
		"letter_selected": Color(0.6, 0.45, 0.2),
		"word_hidden": Color(0.25, 0.18, 0.12),
		"word_revealed": Color(0.4, 0.35, 0.2),
		"unlocked": true
	},
	"night": {
		"name": "شب",
		"icon": "🌃",
		"background_top": Color(0.05, 0.05, 0.1),
		"background_bottom": Color(0.1, 0.05, 0.15),
		"primary": Color(0.4, 0.4, 0.6),
		"secondary": Color(0.3, 0.3, 0.5),
		"accent": Color(0.6, 0.5, 0.8),
		"text": Color(0.9, 0.9, 0.95),
		"text_secondary": Color(0.7, 0.7, 0.8),
		"letter_bg": Color(0.15, 0.15, 0.25),
		"letter_selected": Color(0.35, 0.35, 0.55),
		"word_hidden": Color(0.1, 0.1, 0.18),
		"word_revealed": Color(0.25, 0.3, 0.35),
		"unlocked": true
	},
	"nature": {
		"name": "طبیعت",
		"icon": "🌿",
		"background_top": Color(0.1, 0.18, 0.12),
		"background_bottom": Color(0.08, 0.15, 0.1),
		"primary": Color(0.3, 0.6, 0.4),
		"secondary": Color(0.4, 0.55, 0.35),
		"accent": Color(0.5, 0.75, 0.4),
		"text": Color(0.95, 1, 0.95),
		"text_secondary": Color(0.8, 0.9, 0.8),
		"letter_bg": Color(0.2, 0.3, 0.22),
		"letter_selected": Color(0.35, 0.55, 0.4),
		"word_hidden": Color(0.12, 0.2, 0.15),
		"word_revealed": Color(0.25, 0.45, 0.3),
		"unlock_level": 20
	},
	"ocean": {
		"name": "اقیانوس",
		"icon": "🌊",
		"background_top": Color(0.05, 0.15, 0.25),
		"background_bottom": Color(0.08, 0.1, 0.2),
		"primary": Color(0.2, 0.5, 0.7),
		"secondary": Color(0.15, 0.4, 0.6),
		"accent": Color(0.3, 0.7, 0.8),
		"text": Color(0.9, 0.95, 1),
		"text_secondary": Color(0.75, 0.85, 0.95),
		"letter_bg": Color(0.15, 0.25, 0.35),
		"letter_selected": Color(0.25, 0.5, 0.65),
		"word_hidden": Color(0.1, 0.18, 0.28),
		"word_revealed": Color(0.2, 0.4, 0.5),
		"unlock_level": 50
	},
	"sunset": {
		"name": "غروب",
		"icon": "🌅",
		"background_top": Color(0.25, 0.12, 0.15),
		"background_bottom": Color(0.35, 0.18, 0.1),
		"primary": Color(0.8, 0.4, 0.3),
		"secondary": Color(0.7, 0.35, 0.25),
		"accent": Color(0.95, 0.6, 0.3),
		"text": Color(1, 0.95, 0.9),
		"text_secondary": Color(0.9, 0.85, 0.8),
		"letter_bg": Color(0.35, 0.2, 0.18),
		"letter_selected": Color(0.7, 0.4, 0.3),
		"word_hidden": Color(0.28, 0.15, 0.12),
		"word_revealed": Color(0.5, 0.35, 0.25),
		"unlock_level": 100
	}
}

# ═══════════════════════════════════════════════════════════════
# متغیرها
# ═══════════════════════════════════════════════════════════════
static var current_theme: String = "modern"
static var theme_data: Dictionary = THEMES["modern"]

# ═══════════════════════════════════════════════════════════════
# توابع استاتیک
# ═══════════════════════════════════════════════════════════════
static func set_theme(theme_name: String) -> bool:
	"""تنظیم تم"""
	if not THEMES.has(theme_name):
		return false
	
	if not is_theme_unlocked(theme_name):
		return false
	
	current_theme = theme_name
	theme_data = THEMES[theme_name]
	GameData.set_theme(theme_name)
	
	return true

static func get_current_theme() -> Dictionary:
	"""دریافت تم فعلی"""
	return theme_data

static func get_theme(theme_name: String) -> Dictionary:
	"""دریافت یک تم"""
	return THEMES.get(theme_name, THEMES["modern"])

static func get_all_themes() -> Dictionary:
	"""دریافت همه تم‌ها"""
	return THEMES

static func is_theme_unlocked(theme_name: String) -> bool:
	"""بررسی باز بودن تم"""
	var theme: Dictionary = THEMES.get(theme_name, {})
	
	if theme.get("unlocked", false):
		return true
	
	var required_level: int = theme.get("unlock_level", 999)
	return GameData.player_data["level"] >= required_level

static func get_unlocked_themes() -> Array[String]:
	"""دریافت تم‌های باز شده"""
	var result: Array[String] = []
	
	for theme_name in THEMES:
		if is_theme_unlocked(theme_name):
			result.append(theme_name)
	
	return result

# ═══════════════════════════════════════════════════════════════
# رنگ‌ها
# ═══════════════════════════════════════════════════════════════
static func get_color(color_name: String) -> Color:
	"""دریافت یک رنگ از تم"""
	return theme_data.get(color_name, Color.WHITE)

static func get_background_gradient() -> Array[Color]:
	"""دریافت گرادیانت پس‌زمینه"""
	return [
		theme_data.get("background_top", Color.BLACK),
		theme_data.get("background_bottom", Color.BLACK)
	]

# ═══════════════════════════════════════════════════════════════
# اعمال تم
# ═══════════════════════════════════════════════════════════════
static func apply_to_background(bg: ColorRect) -> void:
	"""اعمال تم به پس‌زمینه"""
	if bg.material and bg.material is ShaderMaterial:
		var shader_mat: ShaderMaterial = bg.material
		shader_mat.set_shader_parameter("color_top", theme_data["background_top"])
		shader_mat.set_shader_parameter("color_bottom", theme_data["background_bottom"])

static func create_letter_style_normal() -> StyleBoxFlat:
	"""ایجاد استایل حرف عادی"""
	var style := StyleBoxFlat.new()
	style.bg_color = theme_data["letter_bg"]
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = theme_data["primary"].lightened(0.2)
	style.corner_radius_top_left = 35
	style.corner_radius_top_right = 35
	style.corner_radius_bottom_right = 35
	style.corner_radius_bottom_left = 35
	return style

static func create_letter_style_selected() -> StyleBoxFlat:
	"""ایجاد استایل حرف انتخاب شده"""
	var style := StyleBoxFlat.new()
	style.bg_color = theme_data["letter_selected"]
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = theme_data["accent"]
	style.corner_radius_top_left = 35
	style.corner_radius_top_right = 35
	style.corner_radius_bottom_right = 35
	style.corner_radius_bottom_left = 35
	style.shadow_color = theme_data["accent"]
	style.shadow_color.a = 0.5
	style.shadow_size = 10
	return style

static func create_button_style() -> StyleBoxFlat:
	"""ایجاد استایل دکمه"""
	var style := StyleBoxFlat.new()
	style.bg_color = theme_data["primary"]
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = theme_data["primary"].lightened(0.2)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_right = 15
	style.corner_radius_bottom_left = 15
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	return style
