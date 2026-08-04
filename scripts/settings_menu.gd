extends Control

## SettingsMenu - Menu cài đặt (v2.4)
## Đồ họa, âm thanh, joystick, device info, UI customization, ngôn ngữ
## v2.1: Thêm "Nhập Mã Quà Tặng" - mở khóa nhân vật đặc biệt qua mã
## v2.3: Xóa hoàn toàn phần cấu hình Server URL - relay server đã hardcoded
## v2.4: Thêm language selector (VI/EN) + áp dụng I18N cho UI strings

@onready var back_button: Button = $BackButton
@onready var quality_label: Label = $ScrollContainer/VBox/QualityLabel
@onready var quality_very_low: Button = $ScrollContainer/VBox/QualityButtons/QualityVeryLow
@onready var quality_low: Button = $ScrollContainer/VBox/QualityButtons/QualityLow
@onready var quality_medium: Button = $ScrollContainer/VBox/QualityButtons/QualityMedium
@onready var quality_high: Button = $ScrollContainer/VBox/QualityButtons/QualityHigh
@onready var fps_toggle: CheckButton = $ScrollContainer/VBox/TogglesRow1/FpsToggle
@onready var shake_toggle: CheckButton = $ScrollContainer/VBox/TogglesRow1/ShakeToggle
@onready var joystick_toggle: CheckButton = $ScrollContainer/VBox/TogglesRow2/JoystickToggle
@onready var sound_toggle: CheckButton = $ScrollContainer/VBox/TogglesRow2/SoundToggle
@onready var music_toggle: CheckButton = $ScrollContainer/VBox/TogglesRow2/MusicToggle
@onready var sound_slider: HSlider = $ScrollContainer/VBox/SoundSlider
@onready var music_slider: HSlider = $ScrollContainer/VBox/MusicSlider
@onready var sound_label: Label = $ScrollContainer/VBox/SoundLabel
@onready var music_label: Label = $ScrollContainer/VBox/MusicLabel
@onready var device_info_label: Label = $ScrollContainer/VBox/DeviceInfoLabel
@onready var ui_customize_button: Button = $ScrollContainer/VBox/UICustomizeButton
@onready var gift_code_input: LineEdit = $ScrollContainer/VBox/GiftCodeHBox/GiftCodeInput
@onready var redeem_button: Button = $ScrollContainer/VBox/GiftCodeHBox/RedeemButton
@onready var gift_code_result_label: Label = $ScrollContainer/VBox/GiftCodeResultLabel
# v2.4: Language selector
@onready var lang_vi_button: Button = $ScrollContainer/VBox/LanguageButtons/LangVi
@onready var lang_en_button: Button = $ScrollContainer/VBox/LanguageButtons/LangEn
# v2.4: Section labels (need @onready so we can translate them)
@onready var title_label: Label = $TitleLabel
@onready var graphics_section: Label = $ScrollContainer/VBox/GraphicsSection
@onready var audio_section: Label = $ScrollContainer/VBox/AudioSection
@onready var language_section: Label = $ScrollContainer/VBox/LanguageSection
@onready var gift_code_section: Label = $ScrollContainer/VBox/GiftCodeSection
@onready var ui_section: Label = $ScrollContainer/VBox/UICustomizeSection
@onready var gift_code_desc: Label = $ScrollContainer/VBox/GiftCodeDesc

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

	# v2.4: Language buttons
	if lang_vi_button:
		lang_vi_button.pressed.connect(func(): I18N.set_language(I18N.LANG_VI); _refresh_ui(); AudioManager.play_ui_click())
	if lang_en_button:
		lang_en_button.pressed.connect(func(): I18N.set_language(I18N.LANG_EN); _refresh_ui(); AudioManager.play_ui_click())

	# v1.2: UI Customization button
	if ui_customize_button:
		ui_customize_button.pressed.connect(_on_ui_customize_pressed)

	# v2.1: Gift code redeem
	if redeem_button:
		redeem_button.pressed.connect(_on_redeem_pressed)
	if gift_code_input:
		gift_code_input.text_submitted.connect(func(_t): _on_redeem_pressed())

	# UI hover sounds
	for btn in [quality_very_low, quality_low, quality_medium, quality_high, back_button, ui_customize_button, redeem_button, lang_vi_button, lang_en_button]:
		if btn:
			btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())
	for tog in [fps_toggle, shake_toggle, joystick_toggle, sound_toggle, music_toggle]:
		if tog:
			tog.mouse_entered.connect(func(): AudioManager.play_ui_hover())

	# v2.4: Listen for language changes (in case changed elsewhere)
	if I18N:
		I18N.language_changed.connect(func(_l): _refresh_ui())

	_load_current_settings()
	_refresh_ui()

func _refresh_ui():
	# Translate all UI strings based on current language
	if title_label:
		title_label.text = I18N.t("settings.title")
	if back_button:
		back_button.text = I18N.t("settings.back")
	if graphics_section:
		graphics_section.text = I18N.t("settings.graphics_section")
	if audio_section:
		audio_section.text = I18N.t("settings.audio_section")
	if language_section:
		language_section.text = I18N.t("settings.language_section")
	if gift_code_section:
		gift_code_section.text = I18N.t("settings.giftcode_section")
	if ui_section:
		ui_section.text = I18N.t("settings.ui_section")
	if gift_code_desc:
		gift_code_desc.text = I18N.t("settings.giftcode_desc")
	if gift_code_input:
		gift_code_input.placeholder_text = I18N.t("settings.giftcode_placeholder")
	if redeem_button:
		redeem_button.text = I18N.t("settings.redeem")
	if ui_customize_button:
		ui_customize_button.text = I18N.t("settings.ui_customize")
	if fps_toggle:
		fps_toggle.text = I18N.t("settings.show_fps")
	if shake_toggle:
		shake_toggle.text = I18N.t("settings.screen_shake")
	if joystick_toggle:
		joystick_toggle.text = I18N.t("settings.show_joystick")
	if sound_toggle:
		sound_toggle.text = I18N.t("settings.sound")
	if music_toggle:
		music_toggle.text = I18N.t("settings.music")
	if lang_vi_button:
		lang_vi_button.text = I18N.t("settings.lang_vi")
	if lang_en_button:
		lang_en_button.text = I18N.t("settings.lang_en")
	# Highlight current language button
	if lang_vi_button and lang_en_button:
		lang_vi_button.modulate = Color(0.5, 1.0, 0.5) if I18N.is_vi() else Color(1, 1, 1)
		lang_en_button.modulate = Color(0.5, 1.0, 0.5) if I18N.is_en() else Color(1, 1, 1)
	_update_quality_buttons()
	_update_sound_labels()

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
	if quality_label:
		quality_label.text = I18N.t("settings.quality_label", [_get_quality_name()])
	for btn in [quality_very_low, quality_low, quality_medium, quality_high]:
		btn.modulate = Color(1, 1, 1, 1)
	if quality_very_low: quality_very_low.text = I18N.t("settings.quality_very_low")
	if quality_low: quality_low.text = I18N.t("settings.quality_low")
	if quality_medium: quality_medium.text = I18N.t("settings.quality_medium")
	if quality_high: quality_high.text = I18N.t("settings.quality_high")
	match SettingsManager.graphics_quality:
		SettingsManager.GraphicsQuality.VERY_LOW: if quality_very_low: quality_very_low.modulate = Color(0.5, 1.0, 0.5)
		SettingsManager.GraphicsQuality.LOW: if quality_low: quality_low.modulate = Color(0.5, 1.0, 0.5)
		SettingsManager.GraphicsQuality.MEDIUM: if quality_medium: quality_medium.modulate = Color(0.5, 1.0, 0.5)
		SettingsManager.GraphicsQuality.HIGH: if quality_high: quality_high.modulate = Color(0.5, 1.0, 0.5)

func _get_quality_name() -> String:
	match SettingsManager.graphics_quality:
		SettingsManager.GraphicsQuality.VERY_LOW: return I18N.t("settings.quality_very_low")
		SettingsManager.GraphicsQuality.LOW: return I18N.t("settings.quality_low")
		SettingsManager.GraphicsQuality.MEDIUM: return I18N.t("settings.quality_medium")
		SettingsManager.GraphicsQuality.HIGH: return I18N.t("settings.quality_high")
		_: return I18N.t("settings.quality_medium")

func _update_sound_labels():
	if sound_label:
		sound_label.text = I18N.t("settings.sound_volume", [int(SettingsManager.sound_volume * 100)])
	if music_label:
		music_label.text = I18N.t("settings.music_volume", [int(SettingsManager.music_volume * 100)])

func _update_device_info():
	if device_info_label:
		var gpu_name = RenderingServer.get_video_adapter_name()
		var cpu_cores = OS.get_processor_count()
		var os_name = OS.get_name()
		var tier_name = SettingsManager.get_device_tier_name()
		var auto_str = " (tự động)" if SettingsManager.was_auto_detected and I18N.is_vi() else (" (auto)" if SettingsManager.was_auto_detected else "")
		device_info_label.text = "Thiết bị: %s | CPU: %d core | GPU: %s | OS: %s%s" if I18N.is_vi() else "Device: %s | CPU: %d core | GPU: %s | OS: %s%s"
		device_info_label.text = device_info_label.text % [tier_name, cpu_cores, gpu_name, os_name, auto_str]

func _on_ui_customize_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui_customization.tscn")

## v2.1: Xử lý nhập mã quà tặng
func _on_redeem_pressed():
	var code = gift_code_input.text.strip_edges()
	if code == "":
		gift_code_result_label.text = I18N.t("settings.empty_code")
		gift_code_result_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
		AudioManager.play_error()
		return
	AudioManager.play_ui_click()
	if CharacterData.redeem_gift_code(code):
		var result_msg = CharacterData.get_last_redeem_message()
		gift_code_result_label.text = I18N.t("settings.code_valid", [result_msg])
		gift_code_result_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		AudioManager.play_success()
		AudioManager.play_achievement()
		gift_code_input.text = ""
	else:
		gift_code_result_label.text = I18N.t("settings.code_invalid")
		gift_code_result_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		AudioManager.play_error()

func _on_back_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
