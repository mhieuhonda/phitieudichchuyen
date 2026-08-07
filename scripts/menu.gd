extends Control

## Menu - Menu chính (v3.0) - Premium UI Edition
## v3.0: Dọn dẹp - đã xóa nút Hướng Dẫn (Guide), xóa mọi tham chiếu online/zombie/gift code
## v2.4: Thêm nút "Vượt Ải" + đa ngôn ngữ (VI/EN) + ẩn mã bí mật (đã xóa v3.0)

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var play_button: Button = $PlayButton
@onready var characters_button: Button = $CharactersButton
@onready var settings_button: Button = $SettingsButton
@onready var quit_button: Button = $QuitButton
@onready var version_label: Label = $VersionLabel
@onready var new_feature_label: RichTextLabel = $NewFeatureLabel

# Premium color palette
const GOLD := Color(1.0, 0.85, 0.3)
const CYAN := Color(0.4, 0.9, 1.0)
const GREEN := Color(0.15, 1.0, 0.55)
const PURPLE := Color(0.75, 0.65, 1.0)
const RED_SOFT := Color(0.85, 0.45, 0.45)
const BG_DARK := Color(0.06, 0.06, 0.12, 0.95)

func _ready():
        play_button.pressed.connect(_on_play_pressed)
        characters_button.pressed.connect(_on_characters_pressed)
        settings_button.pressed.connect(_on_settings_pressed)
        quit_button.pressed.connect(_on_quit_pressed)

        # Premium hover effects with tweens
        for btn in [play_button, characters_button, settings_button, quit_button]:
                if btn:
                        btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
                        btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))

        # v2.4: Listen for language changes
        if I18N:
                I18N.language_changed.connect(func(_l): _refresh_ui())

        _apply_premium_styling()
        _refresh_ui()
        AudioManager.play_music("menu")

func _apply_premium_styling():
        # Title glow pulse effect
        if title_label:
                var tween = create_tween().set_loops()
                tween.tween_property(title_label, "theme_override_colors/font_shadow_color", Color(1.0, 0.7, 0.0, 0.9), 1.5).set_trans(Tween.TRANS_SINE)
                tween.tween_property(title_label, "theme_override_colors/font_shadow_color", Color(0.6, 0.3, 0.0, 0.5), 1.5).set_trans(Tween.TRANS_SINE)

        # Style buttons with hover color modulate
        _style_button(play_button, Color(0.05, 0.15, 0.1, 0.9), GREEN)
        _style_button(characters_button, Color(0.08, 0.1, 0.2, 0.85), Color(0.6, 0.75, 1.0))
        _style_button(settings_button, Color(0.12, 0.08, 0.2, 0.85), PURPLE)
        _style_button(quit_button, Color(0.15, 0.06, 0.06, 0.8), RED_SOFT)

        # New feature label styling
        if new_feature_label:
                new_feature_label.add_theme_color_override("default_color", Color(0.75, 0.8, 0.9))

func _style_button(btn: Button, bg_color: Color, accent_color: Color):
        if not btn:
                return
        # Apply a semi-transparent dark background via StyleBoxFlat
        var style_normal = StyleBoxFlat.new()
        style_normal.bg_color = bg_color
        style_normal.corner_radius_top_left = 10
        style_normal.corner_radius_top_right = 10
        style_normal.corner_radius_bottom_left = 10
        style_normal.corner_radius_bottom_right = 10
        style_normal.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.3)
        style_normal.border_width_top = 1
        style_normal.border_width_bottom = 1
        style_normal.border_width_left = 1
        style_normal.border_width_right = 1
        style_normal.content_margin_top = 8
        style_normal.content_margin_bottom = 8
        style_normal.content_margin_left = 16
        style_normal.content_margin_right = 16
        style_normal.shadow_color = Color(0, 0, 0, 0.4)
        style_normal.shadow_size = 4
        style_normal.shadow_offset = Vector2(0, 3)

        var style_hover = style_normal.duplicate()
        style_hover.bg_color = Color(bg_color.r + 0.06, bg_color.g + 0.06, bg_color.b + 0.08, bg_color.a)
        style_hover.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.6)
        style_hover.shadow_size = 6

        var style_pressed = style_normal.duplicate()
        style_pressed.bg_color = Color(bg_color.r * 0.8, bg_color.g * 0.8, bg_color.b * 0.8, bg_color.a)
        style_pressed.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.8)

        btn.add_theme_stylebox_override("normal", style_normal)
        btn.add_theme_stylebox_override("hover", style_hover)
        btn.add_theme_stylebox_override("pressed", style_pressed)

func _on_btn_hover(btn: Button, entering: bool):
        if not btn or not is_instance_valid(btn):
                return
        AudioManager.play_ui_hover()
        var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
        if entering:
                tween.tween_property(btn, "scale", Vector2(1.04, 1.06), 0.12)
        else:
                tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)

func _refresh_ui():
        if title_label:
                title_label.text = I18N.t("menu.title")
        if subtitle_label:
                subtitle_label.text = I18N.t("menu.subtitle")
        if play_button:
                play_button.text = I18N.t("menu.play")
        if characters_button:
                characters_button.text = I18N.t("menu.characters")
        if settings_button:
                settings_button.text = I18N.t("menu.settings")
        if quit_button:
                quit_button.text = I18N.t("menu.quit")
        if version_label:
                version_label.text = "v3.0 - Phi Tiêu Dịch Chuyển"
        if new_feature_label:
                if I18N.is_vi():
                        new_feature_label.text = "[color=#ffaa00][b]v3.0:[/b][/color] Phiên bản Offline hoàn toàn - Đã xóa Zombie mode, Online mode, Guide, Gift Code và nhân vật Ma Tôn / Hieu Louis.\n[color=#44aaff][b]12 Nhân Vật[/b][/color]: Tất cả nhân vật đều mở khóa sẵn - tự do chọn lựa\n[color=#00ff88][b]Offline PvP[/b][/color]: Chơi với 5 AI trên bản đồ 2000x2000 - vòng bo thu nhỏ, leaderboard đầy đủ\n[color=#aa00ff][b]Premium UI[/b][/color]: Hover effects, glow pulse, dark theme vàng-tím nhất quán"
                else:
                        new_feature_label.text = "[color=#ffaa00][b]v3.0:[/b][/color] Fully Offline version - Removed Zombie mode, Online mode, Guide, Gift Code and Ma Tôn / Hieu Louis characters.\n[color=#44aaff][b]12 Characters[/b][/color]: All characters unlocked - freely choose\n[color=#00ff88][b]Offline PvP[/b][/color]: Play vs 5 AI on a 2000x2000 map - shrinking zone, full leaderboard\n[color=#aa00ff][b]Premium UI[/b][/color]: Hover effects, glow pulse, consistent gold-purple dark theme"

func _on_play_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        # v3.0: Vào thẳng trận Offline (chỉ còn 1 chế độ chơi)
        get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_characters_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/character_screen.tscn")

func _on_settings_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
        AudioManager.play_cancel()
        get_tree().quit()
