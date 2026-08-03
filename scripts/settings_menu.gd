extends Control

## SettingsMenu - Menu cài đặt (v1.2)
## Đồ họa, âm thanh, joystick, device info, UI customization

@onready var back_button: Button = $BackButton
@onready var quality_label: Label = $QualityLabel
@onready var quality_very_low: Button = $QualityButtons/QualityVeryLow
@onready var quality_low: Button = $QualityButtons/QualityLow
@onready var quality_medium: Button = $QualityButtons/QualityMedium
@onready var quality_high: Button = $QualityButtons/QualityHigh
@onready var fps_toggle: CheckButton = $FpsToggle
@onready var shake_toggle: CheckButton = $ShakeToggle
@onready var joystick_toggle: CheckButton = $JoystickToggle
@onready var sound_toggle: CheckButton = $SoundToggle
@onready var music_toggle: CheckButton = $MusicToggle
@onready var sound_slider: HSlider = $SoundSlider
@onready var music_slider: HSlider = $MusicSlider
@onready var sound_label: Label = $SoundLabel
@onready var music_label: Label = $MusicLabel
@onready var device_info_label: Label = $DeviceInfoLabel
@onready var ui_customize_button: Button = $UICustomizeButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	quality_very_low.pressed.connect(func(): SettingsManager.set_graphics_quality(SettingsManager.GraphicsQuality.VERY_LOW); _update_quality_buttons(); AudioManager.play_ui_click())
	quality_low.pressed.connect(func(): SettingsManager.set_graphics_quality(SettingsManager.GraphicsQuality.LOW); _update_quality_buttons(); AudioManager.play_ui_click())
	quality_medium.pressed.connect(func(): SettingsManager.set_graphics_quality(SettingsManager.GraphicsQuality.MEDIUM); _update_quality_buttons(); AudioManager.play_ui_click())
	quality_high.pressed.connect(func(): SettingsManager.set_graphics_quality(SettingsManager.GraphicsQuality.HIGH); _update_quality_buttons(); AudioManager.play_ui_click())
	fps_toggle.toggled.connect(func(v): SettingsManager.show_fps = v; SettingsManager.save_settings(); AudioManager.play_ui_click())
	shake_toggle.toggled.connect(func(v): SettingsManager.screen_shake_enabled = v; SettingsManager.save_settings(); AudioManager.play_ui_click())
	joystick_toggle.toggled.connect(func(v): SettingsManager.show_joystick = v; SettingsManager.save_settings(); AudioManager.play_ui_click())
	sound_toggle.toggled.connect(func(v): SettingsManager.set_sound_enabled(v); AudioManager.set_sound_enabled(v); AudioManager.play_ui_click())
	music_toggle.toggled.connect(func(v): SettingsManager.set_music_enabled(v); AudioManager.set_music_enabled(v); if v: AudioManager.play_music("menu"); AudioManager.play_ui_click())
	sound_slider.value_changed.connect(func(v): SettingsManager.set_sound_volume(v); _update_sound_labels())
	music_slider.value_changed.connect(func(v): SettingsManager.set_music_volume(v); _update_sound_labels())
	
	# v1.2: UI Customization button
	if ui_customize_button:
		ui_customize_button.pressed.connect(_on_ui_customize_pressed)
	
	# UI hover sounds
	for btn in [quality_very_low, quality_low, quality_medium, quality_high, back_button, ui_customize_button]:
		if btn:
			btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())
	for tog in [fps_toggle, shake_toggle, joystick_toggle, sound_toggle, music_toggle]:
		tog.mouse_entered.connect(func(): AudioManager.play_ui_hover())
	
	_load_current_settings()

func _load_current_settings():
	fps_toggle.button_pressed = SettingsManager.show_fps
	shake_toggle.button_pressed = SettingsManager.screen_shake_enabled
	joystick_toggle.button_pressed = SettingsManager.show_joystick
	sound_toggle.button_pressed = SettingsManager.sound_enabled
	music_toggle.button_pressed = SettingsManager.music_enabled
	sound_slider.value = SettingsManager.sound_volume
	music_slider.value = SettingsManager.music_volume
	_update_quality_buttons()
	_update_sound_labels()
	_update_device_info()

func _update_quality_buttons():
	quality_label.text = "Chất lượng đồ họa: %s" % SettingsManager.get_quality_name()
	for btn in [quality_very_low, quality_low, quality_medium, quality_high]:
		btn.modulate = Color(1, 1, 1, 1)
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

func _on_ui_customize_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui_customization.tscn")

func _on_back_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
