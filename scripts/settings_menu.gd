extends Control

## SettingsMenu - Menu cài đặt (v3.4) - Tổ chức lại theo từng mục rõ ràng
## v3.4:
##   - Sắp xếp 4 mục rõ ràng: Đồ Họa / Âm Thanh / Ngôn Ngữ / Giao Diện
##   - Thêm slider Joystick size / Button size / UI opacity vào mục Giao Diện
##     (trước nằm trong UI Customization)
##   - Nút "CHỈNH SỬA GIAO DIỆN" vẫn giữ (dùng để kéo thả vị trí nút)
##     nhưng cũng có ở sảnh chờ
## v3.3: Code-based UI (Button + StyleBoxFlat)
## v3.0: Đã xóa gift code redeem
## v2.4: Thêm language selector (VI/EN)

@onready var back_button: Button = $BackButton
@onready var quality_label: Label = $ScrollContainer/VBox/QualityLabel
@onready var quality_very_low: Button = $ScrollContainer/VBox/QualityButtons/QualityVeryLow
@onready var quality_low: Button = $ScrollContainer/VBox/QualityButtons/QualityLow
@onready var quality_medium: Button = $ScrollContainer/VBox/QualityButtons/QualityMedium
@onready var quality_high: Button = $ScrollContainer/VBox/QualityButtons/QualityHigh
@onready var fps_toggle: CheckButton = $ScrollContainer/VBox/GraphicsToggles/FpsToggle
@onready var shake_toggle: CheckButton = $ScrollContainer/VBox/GraphicsToggles/ShakeToggle
@onready var joystick_toggle: CheckButton = $ScrollContainer/VBox/GraphicsToggles/JoystickToggle
@onready var sound_toggle: CheckButton = $ScrollContainer/VBox/AudioToggles/SoundToggle
@onready var music_toggle: CheckButton = $ScrollContainer/VBox/AudioToggles/MusicToggle
@onready var sound_slider: HSlider = $ScrollContainer/VBox/SoundSlider
@onready var music_slider: HSlider = $ScrollContainer/VBox/MusicSlider
@onready var sound_label: Label = $ScrollContainer/VBox/SoundLabel
@onready var music_label: Label = $ScrollContainer/VBox/MusicLabel
@onready var device_info_label: Label = $ScrollContainer/VBox/DeviceInfoLabel
@onready var ui_customize_button: Button = $ScrollContainer/VBox/UICustomizeButton
@onready var lang_vi_button: Button = $ScrollContainer/VBox/LanguageButtons/LangVi
@onready var lang_en_button: Button = $ScrollContainer/VBox/LanguageButtons/LangEn
@onready var title_label: Label = $TitleLabel
@onready var graphics_section: Label = $ScrollContainer/VBox/GraphicsSection
@onready var audio_section: Label = $ScrollContainer/VBox/AudioSection
@onready var language_section: Label = $ScrollContainer/VBox/LanguageSection
@onready var ui_section: Label = $ScrollContainer/VBox/UISection

# v3.4: UI customization sliders (đưa từ ui_customization sang settings)
@onready var joystick_size_slider: HSlider = $ScrollContainer/VBox/JoystickSizeSlider
@onready var joystick_size_label: Label = $ScrollContainer/VBox/JoystickSizeLabel
@onready var button_size_slider: HSlider = $ScrollContainer/VBox/ButtonSizeSlider
@onready var button_size_label: Label = $ScrollContainer/VBox/ButtonSizeLabel
@onready var ui_opacity_slider: HSlider = $ScrollContainer/VBox/UIOpacitySlider
@onready var ui_opacity_label: Label = $ScrollContainer/VBox/UIOpacityLabel

# Scale animation
const SCALE_UP := Vector2(1.04, 1.04)
const SCALE_NORMAL := Vector2(1.0, 1.0)

# Palette
const COL_GOLD := Color(1.0, 0.85, 0.3)
const COL_CYAN := Color(0.4, 0.9, 1.0)
const COL_PURPLE := Color(0.7, 0.65, 1.0)
const COL_GREEN := Color(0.3, 1.0, 0.5)
const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.13, 0.11, 0.22, 0.98)
const COL_BG_ACTIVE := Color(0.10, 0.18, 0.12, 0.98)

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

        # v3.4: UI sliders
        if joystick_size_slider:
                joystick_size_slider.value_changed.connect(_on_joystick_size_changed)
        if button_size_slider:
                button_size_slider.value_changed.connect(_on_button_size_changed)
        if ui_opacity_slider:
                ui_opacity_slider.value_changed.connect(_on_ui_opacity_changed)

        # Language buttons
        if lang_vi_button:
                lang_vi_button.pressed.connect(func(): I18N.set_language(I18N.LANG_VI); _refresh_ui(); AudioManager.play_ui_click())
        if lang_en_button:
                lang_en_button.pressed.connect(func(): I18N.set_language(I18N.LANG_EN); _refresh_ui(); AudioManager.play_ui_click())

        # UI Customization button (cũng có ở sảnh chờ)
        if ui_customize_button:
                ui_customize_button.pressed.connect(_on_ui_customize_pressed)

        # Hover sounds + scale effects for buttons
        for btn in [back_button, quality_very_low, quality_low, quality_medium, quality_high, ui_customize_button, lang_vi_button, lang_en_button]:
                if btn:
                        btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
                        btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
        for tog in [fps_toggle, shake_toggle, joystick_toggle, sound_toggle, music_toggle]:
                if tog:
                        tog.mouse_entered.connect(func(): AudioManager.play_ui_hover())

        # Listen for language changes
        if I18N:
                I18N.language_changed.connect(func(_l): _refresh_ui())

        _apply_premium_styling()
        _load_current_settings()
        _refresh_ui()
        # v3.8: Setup new UI toggles programmatically
        _setup_v38_toggles()

func _on_btn_hover(btn: Button, entering: bool):
        if not btn or not is_instance_valid(btn):
                return
        if entering:
                AudioManager.play_ui_hover()
                _animate_scale(btn, SCALE_UP, 0.1)
        else:
                _animate_scale(btn, SCALE_NORMAL, 0.15)

func _animate_scale(control: Control, target_scale: Vector2, duration: float):
        if not is_instance_valid(control):
                return
        var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
        tween.tween_property(control, "scale", target_scale, duration)

func _apply_premium_styling():
        _style_button(back_button, COL_GOLD)
        for qb in [quality_very_low, quality_low, quality_medium, quality_high]:
                _style_button(qb, COL_CYAN)
        _style_button(ui_customize_button, COL_GREEN)
        _style_button(lang_vi_button, COL_GREEN)
        _style_button(lang_en_button, COL_CYAN)

        # Style sliders
        for slider in [sound_slider, music_slider, joystick_size_slider, button_size_slider, ui_opacity_slider]:
                if slider:
                        slider.add_theme_stylebox_override("grabber_area", _make_slider_bg(Color(0.3, 0.25, 0.5, 0.5)))
                        slider.add_theme_stylebox_override("slider", _make_slider_bg(Color(0.08, 0.08, 0.12, 0.9)))

func _style_button(btn: Button, accent: Color):
        if not btn:
                return
        var normal = StyleBoxFlat.new()
        normal.bg_color = COL_BG
        normal.corner_radius_top_left = 8
        normal.corner_radius_top_right = 8
        normal.corner_radius_bottom_left = 8
        normal.corner_radius_bottom_right = 8
        normal.border_width_top = 1
        normal.border_width_bottom = 1
        normal.border_width_left = 1
        normal.border_width_right = 1
        normal.border_color = Color(accent.r, accent.g, accent.b, 0.35)
        normal.content_margin_top = 8
        normal.content_margin_bottom = 8
        normal.content_margin_left = 18
        normal.content_margin_right = 18
        normal.shadow_color = Color(0, 0, 0, 0.4)
        normal.shadow_size = 4
        normal.shadow_offset = Vector2(0, 2)

        var hover = normal.duplicate()
        hover.bg_color = COL_BG_HOVER
        hover.border_color = Color(accent.r, accent.g, accent.b, 0.75)

        var pressed = normal.duplicate()
        pressed.bg_color = COL_BG_ACTIVE
        pressed.border_color = Color(accent.r, accent.g, accent.b, 0.95)

        btn.add_theme_stylebox_override("normal", normal)
        btn.add_theme_stylebox_override("hover", hover)
        btn.add_theme_stylebox_override("pressed", pressed)
        btn.add_theme_stylebox_override("focus", normal)

func _make_slider_bg(color: Color) -> StyleBoxFlat:
        var s = StyleBoxFlat.new()
        s.bg_color = color
        s.corner_radius_top_left = 4
        s.corner_radius_top_right = 4
        s.corner_radius_bottom_left = 4
        s.corner_radius_bottom_right = 4
        return s

func _refresh_ui():
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
        if ui_section:
                ui_section.text = I18N.t("settings.ui_section")
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
        if ui_customize_button:
                ui_customize_button.text = I18N.t("settings.ui_customize")
        # v3.4: Labels cho UI sliders
        _update_ui_labels()
        # Highlight current language button
        if lang_vi_button and lang_en_button:
                lang_vi_button.modulate = Color(0.6, 1.0, 0.6) if I18N.is_vi() else Color(1, 1, 1)
                lang_en_button.modulate = Color(0.6, 1.0, 0.6) if I18N.is_en() else Color(1, 1, 1)
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
        if joystick_size_slider:
                joystick_size_slider.value = SettingsManager.joystick_size
        if button_size_slider:
                button_size_slider.value = SettingsManager.button_size
        if ui_opacity_slider:
                ui_opacity_slider.value = SettingsManager.ui_opacity
        _update_quality_buttons()
        _update_sound_labels()
        _update_ui_labels()
        _update_device_info()

func _update_quality_buttons():
        if quality_label:
                quality_label.text = I18N.t("settings.quality_label", [_get_quality_name()])
        for btn in [quality_very_low, quality_low, quality_medium, quality_high]:
                if btn:
                        btn.modulate = Color(1, 1, 1, 1)
        match SettingsManager.graphics_quality:
                SettingsManager.GraphicsQuality.VERY_LOW: if quality_very_low: quality_very_low.modulate = Color(0.5, 1.0, 0.5)
                SettingsManager.GraphicsQuality.LOW: if quality_low: quality_low.modulate = Color(0.5, 1.0, 0.5)
                SettingsManager.GraphicsQuality.MEDIUM: if quality_medium: quality_medium.modulate = Color(0.5, 1.0, 0.5)
                SettingsManager.GraphicsQuality.HIGH: if quality_high: quality_high.modulate = Color(0.5, 1.0, 0.5)
        if quality_very_low: quality_very_low.text = I18N.t("settings.quality_very_low")
        if quality_low: quality_low.text = I18N.t("settings.quality_low")
        if quality_medium: quality_medium.text = I18N.t("settings.quality_medium")
        if quality_high: quality_high.text = I18N.t("settings.quality_high")

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

## v3.4: Cập nhật label cho UI sliders
func _update_ui_labels():
        if joystick_size_label:
                joystick_size_label.text = I18N.t("settings.joystick_size", [int(SettingsManager.joystick_size * 100)])
        if button_size_label:
                button_size_label.text = I18N.t("settings.button_size", [int(SettingsManager.button_size * 100)])
        if ui_opacity_label:
                ui_opacity_label.text = I18N.t("settings.ui_opacity", [int(SettingsManager.ui_opacity * 100)])

func _update_device_info():
        if device_info_label:
                var gpu_name = RenderingServer.get_video_adapter_name()
                var cpu_cores = OS.get_processor_count()
                var os_name = OS.get_name()
                var tier_name = SettingsManager.get_device_tier_name()
                var auto_str = ""
                if SettingsManager.was_auto_detected:
                        auto_str = " " + I18N.t("settings.auto_detected")
                device_info_label.text = I18N.t("settings.device_info", [tier_name, cpu_cores, gpu_name, os_name, auto_str])

## v3.4: Callbacks cho UI sliders
func _on_joystick_size_changed(val):
        SettingsManager.joystick_size = val
        SettingsManager.save_settings()
        _update_ui_labels()
        AudioManager.play_ui_click()

func _on_button_size_changed(val):
        SettingsManager.button_size = val
        SettingsManager.save_settings()
        _update_ui_labels()
        AudioManager.play_ui_click()

func _on_ui_opacity_changed(val):
        SettingsManager.ui_opacity = val
        SettingsManager.save_settings()
        _update_ui_labels()
        AudioManager.play_ui_click()

func _on_ui_customize_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/ui_customization.tscn")

func _on_back_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/menu.tscn")

## v3.8: Setup 4 toggles mới (Hit markers / Kill streak / Low-HP vignette / Boss arrow)
## thêm vào cuối VBox (sau UI section hiện có) — code-based, không sửa .tscn.
func _setup_v38_toggles():
        var vbox = $ScrollContainer/VBox
        if not vbox:
                return
        # Section divider
        var spacer = Control.new()
        spacer.custom_minimum_size = Vector2(0, 12)
        vbox.add_child(spacer)
        # Section label
        var section = Label.new()
        section.text = "✦ v3.8 NEW UI"
        section.add_theme_font_size_override("font_size", 18)
        section.add_theme_color_override("font_color", COL_GOLD)
        section.add_theme_color_override("font_shadow_color", Color(0.3, 0.2, 0, 0.5))
        vbox.add_child(section)
        # Subtitle hint
        var hint = Label.new()
        hint.text = "Bật/tắt các tính năng UI mới thêm trong v3.8"
        hint.add_theme_font_size_override("font_size", 12)
        hint.add_theme_color_override("font_color", Color(0.65, 0.7, 0.85))
        vbox.add_child(hint)
        # Toggles HBox
        var hbox = HBoxContainer.new()
        hbox.add_theme_constant_override("separation", 12)
        vbox.add_child(hbox)
        # Hit markers toggle
        var hm_toggle = CheckButton.new()
        hm_toggle.text = "Hit Markers\n(✕ khi trúng đích)"
        hm_toggle.button_pressed = SettingsManager.show_hit_markers
        hm_toggle.toggled.connect(func(v):
                SettingsManager.show_hit_markers = v
                SettingsManager.save_settings()
                AudioManager.play_ui_click())
        hm_toggle.add_theme_font_size_override("font_size", 12)
        hm_toggle.mouse_entered.connect(func(): AudioManager.play_ui_hover())
        hbox.add_child(hm_toggle)
        # Kill streak toggle
        var ks_toggle = CheckButton.new()
        ks_toggle.text = "Kill Streak\n(DOUBLE/TRIPLE KILL)"
        ks_toggle.button_pressed = SettingsManager.show_kill_streak
        ks_toggle.toggled.connect(func(v):
                SettingsManager.show_kill_streak = v
                SettingsManager.save_settings()
                AudioManager.play_ui_click())
        ks_toggle.add_theme_font_size_override("font_size", 12)
        ks_toggle.mouse_entered.connect(func(): AudioManager.play_ui_hover())
        hbox.add_child(ks_toggle)
        # 2nd row
        var hbox2 = HBoxContainer.new()
        hbox2.add_theme_constant_override("separation", 12)
        vbox.add_child(hbox2)
        # Low-HP vignette toggle
        var hp_toggle = CheckButton.new()
        hp_toggle.text = "Low-HP Vignette\n(đỏ mờ khi HP<30%)"
        hp_toggle.button_pressed = SettingsManager.show_low_hp_vignette
        hp_toggle.toggled.connect(func(v):
                SettingsManager.show_low_hp_vignette = v
                SettingsManager.save_settings()
                AudioManager.play_ui_click())
        hp_toggle.add_theme_font_size_override("font_size", 12)
        hp_toggle.mouse_entered.connect(func(): AudioManager.play_ui_hover())
        hbox2.add_child(hp_toggle)
        # Boss arrow toggle
        var ba_toggle = CheckButton.new()
        ba_toggle.text = "Boss Off-screen Arrow\n(mũi tên chỉ boss)"
        ba_toggle.button_pressed = SettingsManager.show_boss_offscreen_arrow
        ba_toggle.toggled.connect(func(v):
                SettingsManager.show_boss_offscreen_arrow = v
                SettingsManager.save_settings()
                AudioManager.play_ui_click())
        ba_toggle.add_theme_font_size_override("font_size", 12)
        ba_toggle.mouse_entered.connect(func(): AudioManager.play_ui_hover())
        hbox2.add_child(ba_toggle)
        # Minimap toggle (3rd row)
        var hbox3 = HBoxContainer.new()
        hbox3.add_theme_constant_override("separation", 12)
        vbox.add_child(hbox3)
        var mm_toggle = CheckButton.new()
        mm_toggle.text = "Minimap Radar\n(bản đồ nhỏ góc phải)"
        mm_toggle.button_pressed = SettingsManager.show_minimap
        mm_toggle.toggled.connect(func(v):
                SettingsManager.show_minimap = v
                SettingsManager.save_settings()
                AudioManager.play_ui_click())
        mm_toggle.add_theme_font_size_override("font_size", 12)
        mm_toggle.mouse_entered.connect(func(): AudioManager.play_ui_hover())
        hbox3.add_child(mm_toggle)
        # Style all new toggles like the existing ones
        for tog in [hm_toggle, ks_toggle, hp_toggle, ba_toggle, mm_toggle]:
                tog.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
                tog.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.4))

func _unhandled_input(event: InputEvent):
        if event.is_action_pressed("menu_back"):
                get_viewport().set_input_as_handled()
                _on_back_pressed()
