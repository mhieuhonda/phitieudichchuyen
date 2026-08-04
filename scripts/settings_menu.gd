extends Control

## SettingsMenu - Menu cài đặt (v2.1)
## Đồ họa, âm thanh, joystick, device info, UI customization
## v2.1: Thêm "Nhập Mã Quà Tặng" - mở khóa nhân vật đặc biệt qua mã
## v2.1: Redesign UI với section headers, scroll, đẹp hơn

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
# v2.2: Network server URL config
@onready var server_url_input: LineEdit = $ScrollContainer/VBox/ServerUrlHBox/ServerUrlInput
@onready var save_url_button: Button = $ScrollContainer/VBox/ServerUrlHBox/SaveUrlButton
@onready var reset_url_button: Button = $ScrollContainer/VBox/ServerUrlHBox/ResetUrlButton
@onready var server_url_result_label: Label = $ScrollContainer/VBox/ServerUrlResultLabel

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

        # v2.1: Gift code redeem
        if redeem_button:
                redeem_button.pressed.connect(_on_redeem_pressed)
        if gift_code_input:
                gift_code_input.text_submitted.connect(func(_t): _on_redeem_pressed())

        # v2.2: Server URL config
        if save_url_button:
                save_url_button.pressed.connect(_on_save_url_pressed)
        if reset_url_button:
                reset_url_button.pressed.connect(_on_reset_url_pressed)
        if server_url_input:
                server_url_input.text = SettingsManager.server_url
                server_url_input.text_submitted.connect(func(_t): _on_save_url_pressed())

        # UI hover sounds
        for btn in [quality_very_low, quality_low, quality_medium, quality_high, back_button, ui_customize_button, redeem_button, save_url_button, reset_url_button]:
                if btn:
                        btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())
        for tog in [fps_toggle, shake_toggle, joystick_toggle, sound_toggle, music_toggle]:
                if tog:
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

## v2.1: Xử lý nhập mã quà tặng
func _on_redeem_pressed():
        var code = gift_code_input.text.strip_edges()
        if code == "":
                gift_code_result_label.text = "⚠ Vui lòng nhập mã!"
                gift_code_result_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
                AudioManager.play_error()
                return
        AudioManager.play_ui_click()
        if CharacterData.redeem_gift_code(code):
                var result_msg = CharacterData.get_last_redeem_message()
                gift_code_result_label.text = "✅ %s" % result_msg
                gift_code_result_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
                AudioManager.play_success()
                AudioManager.play_achievement()
                gift_code_input.text = ""
        else:
                gift_code_result_label.text = "❌ Mã không hợp lệ!"
                gift_code_result_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
                AudioManager.play_error()

## v2.2: Lưu server URL và test kết nối
func _on_save_url_pressed():
        var url = server_url_input.text.strip_edges()
        if url == "":
                server_url_result_label.text = "⚠ URL không được để trống!"
                server_url_result_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
                AudioManager.play_error()
                return
        if not url.begins_with("ws://") and not url.begins_with("wss://"):
                server_url_result_label.text = "⚠ URL phải bắt đầu bằng ws:// hoặc wss://"
                server_url_result_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
                AudioManager.play_error()
                return
        AudioManager.play_ui_click()
        SettingsManager.server_url = url
        SettingsManager.save_settings()
        # Disconnect cũ (nếu có) rồi thử kết nối với URL mới
        if NetworkManager.is_server_connected():
                NetworkManager.disconnect_from_server()
        # Cleanup any stale handlers
        if NetworkManager.connected_to_server.is_connected(_on_url_test_success):
                NetworkManager.connected_to_server.disconnect(_on_url_test_success)
        if NetworkManager.connection_error.is_connected(_on_url_test_fail):
                NetworkManager.connection_error.disconnect(_on_url_test_fail)
        NetworkManager.connected_to_server.connect(_on_url_test_success, CONNECT_ONE_SHOT)
        NetworkManager.connection_error.connect(_on_url_test_fail, CONNECT_ONE_SHOT)
        server_url_result_label.text = "⏳ Đang test kết nối..."
        server_url_result_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.4))
        NetworkManager.connect_to_server(url)

func _on_url_test_success():
        if NetworkManager.connection_error.is_connected(_on_url_test_fail):
                NetworkManager.connection_error.disconnect(_on_url_test_fail)
        server_url_result_label.text = "✅ Kết nối thành công! Server online."
        server_url_result_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
        AudioManager.play_success()

func _on_url_test_fail(err_msg: String):
        if NetworkManager.connected_to_server.is_connected(_on_url_test_success):
                NetworkManager.connected_to_server.disconnect(_on_url_test_success)
        server_url_result_label.text = "❌ %s" % err_msg
        server_url_result_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
        AudioManager.play_error()

## v2.2: Reset URL về mặc định
func _on_reset_url_pressed():
        AudioManager.play_ui_click()
        SettingsManager.reset_server_url()
        server_url_input.text = SettingsManager.server_url
        server_url_result_label.text = "ℹ Đã reset về URL mặc định."
        server_url_result_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))

func _exit_tree():
        # v2.2: Cleanup ONE_SHOT handlers to avoid stale callbacks after scene freed
        if NetworkManager.connected_to_server.is_connected(_on_url_test_success):
                NetworkManager.connected_to_server.disconnect(_on_url_test_success)
        if NetworkManager.connection_error.is_connected(_on_url_test_fail):
                NetworkManager.connection_error.disconnect(_on_url_test_fail)

func _on_back_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/menu.tscn")
