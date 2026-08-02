extends Node

## SettingsManager - Quản lý cài đặt đồ họa và game
## Singleton autoload, lưu/đọc từ file config

signal graphics_quality_changed(level: int)

enum GraphicsQuality {
	VERY_LOW = 0,   # Tắt mọi hiệu ứng
	LOW = 1,        # Giảm particle, tắt glow
	MEDIUM = 2,     # Particle vừa, glow nhẹ
	HIGH = 3,       # Tất cả hiệu ứng
}

# === CÀI ĐẶT ===
var graphics_quality: int = GraphicsQuality.MEDIUM
var show_fps: bool = false
var screen_shake_enabled: bool = true
var show_joystick: bool = true  # Auto-detect mobile
var sound_volume: float = 1.0
var music_volume: float = 0.7

# === CONFIG PATH ===
var config_path: String = "user://settings.cfg"

func _ready():
	_load_settings()
	# Auto-detect mobile
	if OS.has_feature("mobile") or OS.has_feature("android"):
		show_joystick = true
		graphics_quality = min(graphics_quality, GraphicsQuality.MEDIUM)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("graphics", "quality", graphics_quality)
	config.set_value("graphics", "show_fps", show_fps)
	config.set_value("graphics", "screen_shake", screen_shake_enabled)
	config.set_value("gameplay", "show_joystick", show_joystick)
	config.set_value("audio", "sound_volume", sound_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.save(config_path)

func _load_settings():
	var config = ConfigFile.new()
	if config.load(config_path) == OK:
		graphics_quality = config.get_value("graphics", "quality", GraphicsQuality.MEDIUM)
		show_fps = config.get_value("graphics", "show_fps", false)
		screen_shake_enabled = config.get_value("graphics", "screen_shake", true)
		show_joystick = config.get_value("gameplay", "show_joystick", true)
		sound_volume = config.get_value("audio", "sound_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 0.7)

func set_graphics_quality(level: int):
	graphics_quality = clamp(level, GraphicsQuality.VERY_LOW, GraphicsQuality.HIGH)
	emit_signal("graphics_quality_changed", graphics_quality)
	save_settings()

func get_particle_multiplier() -> float:
	match graphics_quality:
		GraphicsQuality.VERY_LOW: return 0.0
		GraphicsQuality.LOW: return 0.3
		GraphicsQuality.MEDIUM: return 0.7
		GraphicsQuality.HIGH: return 1.0
		_: return 0.7

func get_glow_enabled() -> bool:
	return graphics_quality >= GraphicsQuality.MEDIUM

func get_trail_enabled() -> bool:
	return graphics_quality >= GraphicsQuality.LOW

func get_predicted_line_enabled() -> bool:
	return graphics_quality >= GraphicsQuality.LOW

func get_quality_name() -> String:
	match graphics_quality:
		GraphicsQuality.VERY_LOW: return "Cực Thấp"
		GraphicsQuality.LOW: return "Thấp"
		GraphicsQuality.MEDIUM: return "Trung Bình"
		GraphicsQuality.HIGH: return "Cao"
		_: return "Trung Bình"
