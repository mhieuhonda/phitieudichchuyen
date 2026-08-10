extends Control

## Menu - Menu chính / Sảnh chờ (v3.5)
## v3.5:
##   - Nút "VƯỢT ẢI" thay cho "CHƠI NGAY" — vào màn hình chọn ải
##   - Nút "CHƠI TIẾP" nếu có ải đang chơi dở (tiếp tục ải hiện tại)
##   - Hiển thị tiến độ vượt ải (X/20) trên sảnh chờ
## v3.4: Đưa nút "CHỈNH SỬA GIAO DIỆN" ra ngoài sảnh chờ (trước nằm trong Settings).
##       Bỏ 3 skill buttons khỏi mobile controls; UI chỉ còn 2 nút chính.
## v3.3: Code-based UI - bỏ hoàn toàn PNG buttons. Tất cả nút bấm đều là Button
##       (Godot Control) với StyleBoxFlat tạo hiệu ứng hover, gradient, dark theme
##       vàng-tím nhất quán. Sắp xếp gọn gàng bằng VBoxContainer trong CenterContainer.

@onready var play_button: Button = $CenterContainer/MenuVBox/PlayButton
@onready var world_button: Button = $CenterContainer/MenuVBox/WorldButton
@onready var continue_button: Button = $CenterContainer/MenuVBox/ContinueButton
@onready var characters_button: Button = $CenterContainer/MenuVBox/CharactersButton
@onready var settings_button: Button = $CenterContainer/MenuVBox/SettingsButton
@onready var ui_customize_button: Button = $CenterContainer/MenuVBox/UICustomizeButton
@onready var quit_button: Button = $CenterContainer/MenuVBox/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var new_feature_label: RichTextLabel = $CenterContainer/MenuVBox/NewFeatureLabel
@onready var game_title: Label = $CenterContainer/MenuVBox/GameTitle
@onready var progress_label: Label = $CenterContainer/MenuVBox/ProgressLabel

# Scale animation
const SCALE_UP := Vector2(1.06, 1.06)
const SCALE_NORMAL := Vector2(1.0, 1.0)
const SCALE_DURATION_UP := 0.1
const SCALE_DURATION_DOWN := 0.15

# Palette
const COL_GOLD := Color(1.0, 0.85, 0.3)
const COL_GOLD_DIM := Color(0.55, 0.45, 0.18)
const COL_CYAN := Color(0.4, 0.9, 1.0)
const COL_PURPLE := Color(0.7, 0.65, 1.0)
const COL_GREEN := Color(0.3, 1.0, 0.5)
const COL_RED := Color(1.0, 0.4, 0.3)
const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.13, 0.11, 0.22, 0.98)
const COL_BORDER := Color(0.35, 0.30, 0.55, 0.55)

func _ready():
        play_button.pressed.connect(_on_play_pressed)
        if world_button:
                world_button.pressed.connect(_on_world_pressed)
        if continue_button:
                continue_button.pressed.connect(_on_continue_pressed)
        characters_button.pressed.connect(_on_characters_pressed)
        settings_button.pressed.connect(_on_settings_pressed)
        ui_customize_button.pressed.connect(_on_ui_customize_pressed)
        quit_button.pressed.connect(_on_quit_pressed)

        # Style every button
        _style_primary_button(play_button, COL_GOLD)
        if world_button:
                _style_button(world_button, COL_CYAN)
        if continue_button:
                _style_button(continue_button, COL_GREEN)
        _style_button(characters_button, COL_CYAN)
        _style_button(settings_button, COL_PURPLE)
        _style_button(ui_customize_button, COL_GREEN)
        _style_button(quit_button, COL_RED)

        # Hover & click scale effects for ALL buttons
        var buttons = [play_button, characters_button, settings_button, ui_customize_button, quit_button]
        if world_button:
                buttons.append(world_button)
        if continue_button:
                buttons.append(continue_button)
        for btn in buttons:
                if btn:
                        btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
                        btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
                        _setup_touch_scale(btn)

        # Listen for language changes
        if I18N:
                I18N.language_changed.connect(func(_l): _refresh_ui())

        _apply_premium_styling()
        _refresh_ui()
        AudioManager.play_music("menu")

## Setup touch scale animation (phóng to khi chạm, thu nhỏ khi thả)
func _setup_touch_scale(btn: Control):
        if not btn:
                return
        btn.gui_input.connect(func(event: InputEvent):
                if event is InputEventMouseButton:
                        if event.pressed:
                                _animate_scale(btn, SCALE_UP, SCALE_DURATION_UP)
                        else:
                                _animate_scale(btn, SCALE_NORMAL, SCALE_DURATION_DOWN)
                elif event is InputEventScreenTouch:
                        if event.pressed:
                                _animate_scale(btn, SCALE_UP, SCALE_DURATION_UP)
                        else:
                                _animate_scale(btn, SCALE_NORMAL, SCALE_DURATION_DOWN)
        )

func _animate_scale(control: Control, target_scale: Vector2, duration: float):
        if not is_instance_valid(control):
                return
        var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
        tween.tween_property(control, "scale", target_scale, duration)

func _on_btn_hover(btn: Button, entering: bool):
        if not btn or not is_instance_valid(btn):
                return
        if entering:
                AudioManager.play_ui_hover()
                _animate_scale(btn, SCALE_UP, SCALE_DURATION_UP)
        else:
                _animate_scale(btn, SCALE_NORMAL, SCALE_DURATION_DOWN)

## Style một button thường (background + border accent)
func _style_button(btn: Button, accent: Color):
        if not btn:
                return
        var normal = StyleBoxFlat.new()
        normal.bg_color = COL_BG
        normal.corner_radius_top_left = 10
        normal.corner_radius_top_right = 10
        normal.corner_radius_bottom_left = 10
        normal.corner_radius_bottom_right = 10
        normal.border_width_top = 2
        normal.border_width_bottom = 2
        normal.border_width_left = 2
        normal.border_width_right = 2
        normal.border_color = Color(accent.r, accent.g, accent.b, 0.35)
        normal.content_margin_top = 12
        normal.content_margin_bottom = 12
        normal.content_margin_left = 24
        normal.content_margin_right = 24
        normal.shadow_color = Color(0, 0, 0, 0.45)
        normal.shadow_size = 6
        normal.shadow_offset = Vector2(0, 3)

        var hover = normal.duplicate()
        hover.bg_color = COL_BG_HOVER
        hover.border_color = Color(accent.r, accent.g, accent.b, 0.85)

        var pressed = normal.duplicate()
        pressed.bg_color = Color(0.04, 0.04, 0.08, 0.98)
        pressed.border_color = Color(accent.r, accent.g, accent.b, 0.95)

        btn.add_theme_stylebox_override("normal", normal)
        btn.add_theme_stylebox_override("hover", hover)
        btn.add_theme_stylebox_override("pressed", pressed)
        btn.add_theme_stylebox_override("focus", normal)

## Style nút chính (Play) — gradient nổi bật hơn
func _style_primary_button(btn: Button, accent: Color):
        if not btn:
                return
        _style_button(btn, accent)
        var normal = btn.get_theme_stylebox("normal") as StyleBoxFlat
        if normal:
                normal.border_width_top = 3
                normal.border_width_bottom = 3
                normal.border_width_left = 3
                normal.border_width_right = 3
                normal.border_color = Color(accent.r, accent.g, accent.b, 0.65)
                normal.shadow_color = Color(accent.r * 0.6, accent.g * 0.4, 0.0, 0.55)
                normal.shadow_size = 14

func _apply_premium_styling():
        # Game title glow pulse effect
        if game_title:
                var tween = create_tween().set_loops()
                tween.tween_property(game_title, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.0).set_trans(Tween.TRANS_SINE)
                tween.tween_property(game_title, "modulate", Color(0.85, 0.85, 0.95, 0.9), 2.0).set_trans(Tween.TRANS_SINE)

        if new_feature_label:
                new_feature_label.add_theme_color_override("default_color", Color(0.75, 0.8, 0.9))

func _refresh_ui():
        if version_label:
                version_label.text = "v3.7 - Phi Tiêu Dịch Chuyển"
        if new_feature_label:
                if I18N.is_vi():
                        new_feature_label.text = "[color=#ffaa00][b]v3.7 MỚI:[/b][/color] Thế giới 4 vùng + 10 loài động vật + hệ thống class/đồng đội\n[color=#44ff88][b]Fix:[/b][/color] Lỗi laser boss không gây sát thương (abs Vector2 bug)\n[color=#ff4444][b]Cân bằng:[/b][/color] Boss ải 20 dmg < 4x player, laser đốt liên tục, độ khó ải tăng\n[color=#aa44ff][b]Meta:[/b][/color] HL Coin, uy tín, độ thân mật, thành tựu, nội chiến loài"
                else:
                        new_feature_label.text = "[color=#ffaa00][b]v3.7 NEW:[/b][/color] 4-region world + 10 species + class/teammate system\n[color=#44ff88][b]Fix:[/b][/color] Boss laser hitbox bug (abs Vector2 returned Vector2, never damaged)\n[color=#ff4444][b]Balance:[/b][/color] Stage 20 boss dmg < 4x player, continuous laser burn, harder stages\n[color=#aa44ff][b]Meta:[/b][/color] HL Coin, reputation, intimacy, achievements, civil war"
        if play_button:
                play_button.text = "⚔ VƯỢT ẢI" if I18N.is_vi() else "⚔ STAGES"
        if world_button:
                world_button.text = "🌍 THẾ GIỚI" if I18N.is_vi() else "🌍 WORLD"
        if continue_button:
                continue_button.text = "▶ CHƠI TIẾP" if I18N.is_vi() else "▶ CONTINUE"
                # Chỉ hiện nút Continue nếu có ải đang chơi dở (current_stage > 1 hoặc đã vượt qua ải 1)
                var has_progress = StageManager.max_stage_unlocked > 1 or StageManager.current_stage > 1
                continue_button.visible = has_progress
        if characters_button:
                characters_button.text = I18N.t("menu.characters")
        if settings_button:
                settings_button.text = I18N.t("menu.settings")
        if ui_customize_button:
                ui_customize_button.text = I18N.t("settings.ui_customize")
        if quit_button:
                quit_button.text = I18N.t("menu.quit")
        # v3.5: Progress label
        if progress_label:
                var completed = StageManager.best_time_per_stage.size()
                progress_label.text = "Tiến độ: %d / %d ải  •  ải cao nhất: %d" % [completed, StageManager.TOTAL_STAGES, StageManager.max_stage_unlocked]
                progress_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))

func _on_play_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        get_tree().change_scene_to_file("res://scenes/stage_select.tscn")

## v3.7: Vào thế giới meta-game
func _on_world_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        # Cấp player theo số ải vượt qua (1 ải = 1 level, max 5)
        ProgressionManager.gain_xp_and_level(0)
        get_tree().change_scene_to_file("res://scenes/world_map.tscn")

## v3.5: Chơi tiếp ải hiện tại
func _on_continue_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_characters_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/character_screen.tscn")

func _on_settings_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/settings.tscn")

## v3.4: Nút "Chỉnh sửa giao diện" ra thẳng sảnh chờ
func _on_ui_customize_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/ui_customization.tscn")

func _on_quit_pressed():
        AudioManager.play_cancel()
        get_tree().quit()

func _unhandled_input(event: InputEvent):
        if event.is_action_pressed("menu_back"):
                get_viewport().set_input_as_handled()
                _on_quit_pressed()
