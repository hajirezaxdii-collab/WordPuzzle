## AudioManager.gd - مدیریت صداها و موسیقی
extends Node

# ═══════════════════════════════════════════════════════════════
# سیگنال‌ها
# ═══════════════════════════════════════════════════════════════
signal music_changed(track_name: String)
signal volume_changed(bus_name: String, volume: float)

# ═══════════════════════════════════════════════════════════════
# ثابت‌ها
# ═══════════════════════════════════════════════════════════════
const MUSIC_FADE_DURATION: float = 1.0
const SFX_POOL_SIZE: int = 8

# مسیر فایل‌های صوتی
const MUSIC_PATHS: Dictionary = {
	"menu": "res://assets/audio/music/menu_theme.ogg",
	"game": "res://assets/audio/music/game_theme.ogg",
	"victory": "res://assets/audio/music/victory.ogg"
}

const SFX_PATHS: Dictionary = {
	"click": "res://assets/audio/sfx/click.wav",
	"correct": "res://assets/audio/sfx/correct.wav",
	"wrong": "res://assets/audio/sfx/wrong.wav",
	"complete": "res://assets/audio/sfx/complete.wav",
	"bonus": "res://assets/audio/sfx/bonus.wav",
	"star": "res://assets/audio/sfx/star.wav",
	"coin": "res://assets/audio/sfx/coin.wav",
	"hint": "res://assets/audio/sfx/hint.wav",
	"shuffle": "res://assets/audio/sfx/shuffle.wav",
	"letter_select": "res://assets/audio/sfx/letter_select.wav",
	"letter_connect": "res://assets/audio/sfx/letter_connect.wav",
	"level_up": "res://assets/audio/sfx/level_up.wav",
	"reward": "res://assets/audio/sfx/reward.wav",
	"pop": "res://assets/audio/sfx/pop.wav"
}

# ═══════════════════════════════════════════════════════════════
# متغیرها
# ═══════════════════════════════════════════════════════════════
var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

var _music_volume: float = 0.7
var _sfx_volume: float = 1.0
var _is_music_enabled: bool = true
var _is_sfx_enabled: bool = true

var _current_music: String = ""
var _sfx_cache: Dictionary = {}  # کش صداها برای لود سریع‌تر

var _music_tween: Tween

# ═══════════════════════════════════════════════════════════════
# توابع چرخه حیات
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_preload_sfx()

func _setup_audio_players() -> void:
	"""راه‌اندازی پلیرهای صوتی"""
	# پلیر موسیقی
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = linear_to_db(_music_volume)
	add_child(_music_player)
	
	# پول صداهای افکت
	for i in range(SFX_POOL_SIZE):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		sfx_player.volume_db = linear_to_db(_sfx_volume)
		add_child(sfx_player)
		_sfx_pool.append(sfx_player)

func _preload_sfx() -> void:
	"""پیش‌بارگذاری صداهای افکت"""
	for sfx_name in SFX_PATHS.keys():
		var path: String = SFX_PATHS[sfx_name]
		if ResourceLoader.exists(path):
			_sfx_cache[sfx_name] = load(path)

# ═══════════════════════════════════════════════════════════════
# کنترل موسیقی
# ═══════════════════════════════════════════════════════════════
func play_music(track_name: String, fade_in: bool = true) -> void:
	"""پخش موسیقی"""
	if not _is_music_enabled:
		return
	
	if track_name == _current_music and _music_player.playing:
		return
	
	var path: String = MUSIC_PATHS.get(track_name, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("Music track not found: " + track_name)
		return
	
	# توقف موسیقی قبلی با Fade
	if _music_player.playing and fade_in:
		_fade_out_music()
		await get_tree().create_timer(MUSIC_FADE_DURATION).timeout
	
	_current_music = track_name
	_music_player.stream = load(path)
	_music_player.play()
	
	if fade_in:
		_fade_in_music()
	
	music_changed.emit(track_name)

func stop_music(fade_out: bool = true) -> void:
	"""توقف موسیقی"""
	if not _music_player.playing:
		return
	
	if fade_out:
		_fade_out_music()
		await get_tree().create_timer(MUSIC_FADE_DURATION).timeout
	
	_music_player.stop()
	_current_music = ""

func pause_music() -> void:
	"""مکث موسیقی"""
	_music_player.stream_paused = true

func resume_music() -> void:
	"""ادامه موسیقی"""
	_music_player.stream_paused = false

func _fade_in_music() -> void:
	"""Fade in موسیقی"""
	if _music_tween:
		_music_tween.kill()
	
	_music_player.volume_db = -40.0
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", linear_to_db(_music_volume), MUSIC_FADE_DURATION)

func _fade_out_music() -> void:
	"""Fade out موسیقی"""
	if _music_tween:
		_music_tween.kill()
	
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_DURATION)

# ═══════════════════════════════════════════════════════════════
# کنترل افکت‌های صوتی
# ═══════════════════════════════════════════════════════════════
func play_sfx(sfx_name: String, pitch_variation: float = 0.0) -> void:
	"""پخش صدای افکت"""
	if not _is_sfx_enabled:
		return
	
	var stream: AudioStream = _sfx_cache.get(sfx_name)
	if not stream:
		var path: String = SFX_PATHS.get(sfx_name, "")
		if path.is_empty() or not ResourceLoader.exists(path):
			push_warning("SFX not found: " + sfx_name)
			return
		stream = load(path)
		_sfx_cache[sfx_name] = stream
	
	var player: AudioStreamPlayer = _get_available_sfx_player()
	player.stream = stream
	
	# تنوع در Pitch
	if pitch_variation > 0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	else:
		player.pitch_scale = 1.0
	
	player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""دریافت پلیر آزاد از پول"""
	# ابتدا پلیر غیرفعال
	for player in _sfx_pool:
		if not player.playing:
			return player
	
	# اگر همه فعالند، از روش Round-robin استفاده کن
	var player: AudioStreamPlayer = _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	return player

func stop_all_sfx() -> void:
	"""توقف همه صداها"""
	for player in _sfx_pool:
		player.stop()

# ═══════════════════════════════════════════════════════════════
# صداهای رایج (میانبر)
# ═══════════════════════════════════════════════════════════════
func play_click() -> void:
	play_sfx("click")

func play_correct() -> void:
	play_sfx("correct")

func play_wrong() -> void:
	play_sfx("wrong")

func play_complete() -> void:
	play_sfx("complete")

func play_letter_select() -> void:
	play_sfx("letter_select", 0.1)

func play_letter_connect() -> void:
	play_sfx("letter_connect", 0.05)

func play_coin() -> void:
	play_sfx("coin", 0.1)

func play_star() -> void:
	play_sfx("star")

# ═══════════════════════════════════════════════════════════════
# تنظیمات صدا
# ═══════════════════════════════════════════════════════════════
func set_music_volume(volume: float) -> void:
	"""تنظیم صدای موسیقی (0.0 - 1.0)"""
	_music_volume = clampf(volume, 0.0, 1.0)
	_is_music_enabled = _music_volume > 0
	_music_player.volume_db = linear_to_db(_music_volume)
	
	if not _is_music_enabled:
		stop_music(false)
	
	volume_changed.emit("Music", _music_volume)

func set_sfx_volume(volume: float) -> void:
	"""تنظیم صدای افکت‌ها (0.0 - 1.0)"""
	_sfx_volume = clampf(volume, 0.0, 1.0)
	_is_sfx_enabled = _sfx_volume > 0
	
	for player in _sfx_pool:
		player.volume_db = linear_to_db(_sfx_volume)
	
	volume_changed.emit("SFX", _sfx_volume)

func get_music_volume() -> float:
	return _music_volume

func get_sfx_volume() -> float:
	return _sfx_volume

func is_music_enabled() -> bool:
	return _is_music_enabled

func is_sfx_enabled() -> bool:
	return _is_sfx_enabled

func toggle_music() -> bool:
	if _is_music_enabled:
		set_music_volume(0.0)
	else:
		set_music_volume(0.7)
	return _is_music_enabled

func toggle_sfx() -> bool:
	if _is_sfx_enabled:
		set_sfx_volume(0.0)
	else:
		set_sfx_volume(1.0)
	return _is_sfx_enabled

# ═══════════════════════════════════════════════════════════════
# ذخیره و بارگذاری تنظیمات
# ═══════════════════════════════════════════════════════════════
func apply_settings() -> void:
	"""اعمال تنظیمات از GameData"""
	set_music_volume(GameData.player_data["music_volume"])
	set_sfx_volume(GameData.player_data["sfx_volume"])

func save_settings() -> void:
	"""ذخیره تنظیمات در GameData"""
	GameData.player_data["music_volume"] = _music_volume
	GameData.player_data["sfx_volume"] = _sfx_volume
