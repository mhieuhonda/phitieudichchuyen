extends Control

## SettingsMenu - Menu cài đặt
## Đồ họa từ cực thấp đến cao, âm thanh, joystick, device info

@onready var back_button: Button = $BackButton
@onready var quality_label: Label = $QualityLabel
@onready var quality_very_low: Button = $QualityVeryLow
@onready var quality_low: Button = $QualityLow
@onready var quality_medium: Button = $QualityMedium
@onready var quality_high: Button = $QualityHigh
@onready var fps_toggle: CheckButton = $FpsToggle
@onready var shake_toggle: CheckButton = $ShakeToggle
@onready var joystick_toggle: CheckButton = $JoystickToggle
@onready var sound_slider: HSlider = $SoundSlider
@onready var music_slider: HSlider = $MusicSlider
@onready var sound_label: Label = $SoundLabel
@onready var music_label: Label = $MusicLabel
@onready var device_info_label: Label = $DeviceInfoLabel

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	quality_very_low.pressed.connect(func(): SettingsManager.set_graphics_quality(SettingsManager.GraphicsQuality.VERY_LOW); _update_quality_buttons())
	quality_low.pressed.connect(func(): SettingsManager.set_graphics_quality(SettingsManager.GraphicsQuality.LOW); _update_quality_buttons())
	quality_medium.pressed.connect(func(): SettingsManager.set_graphics_quality(SettingsManager.GraphicsQuality.MEDIUM); _update_quality_buttons())
	quality_high.pressed.connect(func(): SettingsManager.set_graphics_quality(SettingsManager.GraphicsQuality.HIGH); _update_quality_buttons())
	fps_toggle.toggled.connect(func(v): SettingsManager.show_fps = v; SettingsManager.save_settings())
	shake_toggle.toggled.connect(func(v): SettingsManager.screen_shake_enabled = v; SettingsManager.save_settings())
	joystick_toggle.toggled.connect(func(v): SettingsManager.show_joystick = v; SettingsManager.save_settings())
	sound_slider.value_changed.connect(func(v): SettingsManager.sound_volume = v; SettingsManager.save_settings(); _update_sound_labels())
	music_slider.value_changed.connect(func(v): SettingsManager.music_volume = v; SettingsManager.save_settings(); _update_sound_labels())
	
	_load_current_settings()

func _load_current_settings():
	fps_toggle.button_pressed = SettingsManager.show_fps
	shake_toggle.button_pressed = SettingsManager.screen_shake_enabled
	joystick_toggle.button_pressed = SettingsManager.show_joystick
	sound_slider.value = SettingsManager.sound_volume
	music_slider.value = SettingsManager.music_volume
	_update_quality_buttons()
	_update_sound_labels()
	_update_device_info()

func _update_quality_buttons():
	quality_label.text = "Chất lượng đồ họa: %s" % SettingsManager.get_quality_name()
	# Reset all button colors
	for btn in [quality_very_low, quality_low, quality_medium, quality_high]:
		btn.modulate = Color(1, 1, 1, 1)
	# Highlight current
	match SettingsManager.graphics_quality:
		SettingsManager.GraphicsQuality.VERY_LOW: quality_very_low.modulate = Color(0.5, 1.0, 0.5)
		SettingsManager.GraphicsQuality.LOW: quality_low.modulate = Color(0.5, 1.0, 0.5)
		SettingsManager.GraphicsQuality.MEDIUM: quality_medium.modulate = Color(0.5, 1.0, 0.5)
		SettingsManager.GraphicsQuality.HIGH: quality_high.modulate = Color(0.5, 1.0, 0.5)

func _update_sound_labels():
	sound_label.text = "Âm thanh: %d%%" % int(SettingsManager.sound_volume * 100)
	music_label.text = "Nhạc: %d%%" % int(SettingsManager.music_volume * 100)

func _update_device_info():
	if device_info_label:
		var gpu_name = RenderingServer.get_video_adapter_name()
		var cpu_cores = OS.get_processor_count()
		var os_name = OS.get_name()
		var tier_name = SettingsManager.get_device_tier_name()
		var auto_str = " (tự động)" if SettingsManager.was_auto_detected else ""
		device_info_label.text = "Thiết bị: %s | CPU: %d core | GPU: %s | OS: %s%s" % [tier_name, cpu_cores, gpu_name, os_name, auto_str]

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
