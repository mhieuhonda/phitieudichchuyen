extends Control

## StageSelect - Màn hình chọn ải (v3.5)
## v3.8: Thêm nút "Tiếp tục ải hiện tại", dialog xác nhận trước khi reset tiến độ.
## Hiển thị 20 ải dạng lưới. ải đã mở khóa có thể chọn, ải chưa mở khóa bị mờ.
## Hiển thị best time mỗi ải, số lần thử.
## Nút "Reset Tiến Độ" để chơi lại từ đầu.

@onready var grid: GridContainer = $CenterContainer/VBox/ScrollContainer/Grid
@onready var back_btn: Button = $CenterContainer/VBox/BackBtn
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var stats_label: Label = $CenterContainer/VBox/StatsLabel
@onready var reset_btn: Button = $CenterContainer/VBox/ResetBtn

# v3.8: Confirm dialog state
var _confirm_panel: Panel = null
var _continue_btn: Button = null

const COL_GOLD := Color(1.0, 0.85, 0.3)
const COL_GREEN := Color(0.3, 1.0, 0.5)
const COL_RED := Color(1.0, 0.4, 0.3)
const COL_CYAN := Color(0.4, 0.9, 1.0)
const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.13, 0.11, 0.22, 0.98)
const COL_BORDER := Color(0.35, 0.30, 0.55, 0.55)

func _ready():
    back_btn.pressed.connect(_on_back_pressed)
    reset_btn.pressed.connect(_on_reset_pressed)
    _style_button(back_btn, COL_CYAN)
    _style_button(reset_btn, COL_RED)
    _setup_touch_scale(back_btn)
    _setup_touch_scale(reset_btn)
    _populate_grid()
    _update_stats()
    AudioManager.play_music("menu")

func _populate_grid():
    for child in grid.get_children():
        child.queue_free()
    grid.columns = 5
    for i in StageManager.TOTAL_STAGES:
        var stage_num = i + 1
        var btn = Button.new()
        btn.custom_minimum_size = Vector2(120, 110)
        btn.text = ""
        var unlocked = StageManager.is_stage_unlocked(stage_num)
        var is_final = stage_num == StageManager.FINAL_STAGE
        var is_current = stage_num == StageManager.current_stage
        # v3.8: Difficulty color coding
        var difficulty_color = _get_difficulty_color(stage_num)
        var difficulty_label = _get_difficulty_label(stage_num)
        # Build label
        var label_text = "ẢI %d" % stage_num
        if is_final:
            label_text = "ẢI %d\nBOSS" % stage_num
        label_text += "\n" + difficulty_label
        if StageManager.best_time_per_stage.has(stage_num):
            label_text += "\n⏱ %s" % StageManager.format_time(StageManager.best_time_per_stage[stage_num])
        btn.text = label_text
        btn.add_theme_font_size_override("font_size", 13)
        # Style theo trạng thái
        if is_final:
            _style_button(btn, COL_RED)
        elif unlocked:
            # v3.8: Difficulty color nếu đã unlock
            _style_button(btn, difficulty_color if not is_current else COL_GOLD)
        else:
            _style_locked_button(btn)
            btn.disabled = true
        # Click handler
        if unlocked:
            btn.pressed.connect(_on_stage_pressed.bind(stage_num))
            _setup_touch_scale(btn)
        grid.add_child(btn)

## v3.8: Difficulty color theo ải
func _get_difficulty_color(stage: int) -> Color:
    if stage == StageManager.FINAL_STAGE:
        return COL_RED
    if stage <= 5:
        return COL_GREEN  # easy
    if stage <= 10:
        return COL_CYAN  # medium
    if stage <= 15:
        return Color(1.0, 0.7, 0.2)  # orange, hard
    return Color(1.0, 0.4, 0.3)  # red, very hard

## v3.8: Difficulty text label
func _get_difficulty_label(stage: int) -> String:
    if stage == StageManager.FINAL_STAGE:
        return "💀 BOSS"
    if stage <= 5:
        return "🟢 Dễ"
    if stage <= 10:
        return "🔵 TB"
    if stage <= 15:
        return "🟠 Khó"
    return "🔴 RKhó"

func _update_stats():
    var completed = StageManager.best_time_per_stage.size()
    var total_attempts = 0
    for stage in StageManager.attempts_per_stage.keys():
        total_attempts += StageManager.attempts_per_stage[stage]
    # v3.8: Thêm best kill streak + total stage clears
    stats_label.text = "Đã hoàn thành: %d/%d  •  Lần thử: %d  •  Chết: %d  •  Boss: %d\n🏆 Best kill streak: %d  •  Tổng trận: %d  •  Thắng: %d" % [
        completed, StageManager.TOTAL_STAGES, total_attempts,
        StageManager.total_deaths, StageManager.total_boss_kills,
        SettingsManager.best_kill_streak,
        SettingsManager.total_matches,
        SettingsManager.total_wins
    ]

func _on_stage_pressed(stage: int):
    AudioManager.play_ui_click()
    AudioManager.play_confirm()
    StageManager.current_stage = stage
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_back_pressed():
    AudioManager.play_ui_click()
    get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_reset_pressed():
    AudioManager.play_cancel()
    # v3.8: Hiện confirm dialog thay vì reset ngay
    _show_reset_confirm_dialog()

## v3.8: Hiện dialog xác nhận reset tiến độ
func _show_reset_confirm_dialog():
    if _confirm_panel and is_instance_valid(_confirm_panel):
        _confirm_panel.queue_free()
    _confirm_panel = Panel.new()
    _confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
    _confirm_panel.offset_left = -200
    _confirm_panel.offset_right = 200
    _confirm_panel.offset_top = -120
    _confirm_panel.offset_bottom = 120
    _confirm_panel.z_index = 100
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.06, 0.02, 0.04, 0.97)
    style.border_color = Color(0.9, 0.2, 0.15, 0.7)
    style.border_width_top = 3
    style.border_width_bottom = 3
    style.border_width_left = 3
    style.border_width_right = 3
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    style.shadow_color = Color(0.3, 0, 0, 0.6)
    style.shadow_size = 18
    _confirm_panel.add_theme_stylebox_override("panel", style)
    add_child(_confirm_panel)
    # Title
    var title = Label.new()
    title.text = "⚠ XÓA TIẾN ĐỘ?"
    title.set_anchors_preset(Control.PRESET_CENTER_TOP)
    title.offset_left = -180
    title.offset_right = 180
    title.offset_top = 14
    title.offset_bottom = 50
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
    _confirm_panel.add_child(title)
    # Body
    var body = Label.new()
    body.text = "Mọi tiến độ vượt ải, best time,\nsố lần thử sẽ bị xóa vĩnh viễn.\n\nBạn chắc chắn?"
    body.set_anchors_preset(Control.PRESET_CENTER)
    body.offset_left = -180
    body.offset_right = 180
    body.offset_top = -30
    body.offset_bottom = 50
    body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body.add_theme_font_size_override("font_size", 14)
    body.add_theme_color_override("font_color", Color(0.88, 0.85, 0.88))
    _confirm_panel.add_child(body)
    # Buttons HBox
    var hbox = HBoxContainer.new()
    hbox.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    hbox.offset_left = -180
    hbox.offset_right = 180
    hbox.offset_top = 70
    hbox.offset_bottom = 110
    hbox.add_theme_constant_override("separation", 20)
    hbox.alignment = BoxContainer.ALIGNMENT_CENTER
    _confirm_panel.add_child(hbox)
    # Yes button
    var yes_btn = Button.new()
    yes_btn.text = "✓ XÓA"
    yes_btn.custom_minimum_size = Vector2(120, 36)
    var yes_style = StyleBoxFlat.new()
    yes_style.bg_color = Color(0.18, 0.04, 0.04, 0.95)
    yes_style.corner_radius_top_left = 8
    yes_style.corner_radius_top_right = 8
    yes_style.corner_radius_bottom_left = 8
    yes_style.corner_radius_bottom_right = 8
    yes_style.border_color = Color(1.0, 0.3, 0.2, 0.7)
    yes_style.border_width_top = 2
    yes_style.border_width_bottom = 2
    yes_style.border_width_left = 2
    yes_style.border_width_right = 2
    var yes_h = yes_style.duplicate()
    yes_h.bg_color = Color(0.25, 0.06, 0.06, 0.98)
    yes_h.border_color = Color(1.0, 0.4, 0.3, 0.95)
    yes_btn.add_theme_stylebox_override("normal", yes_style)
    yes_btn.add_theme_stylebox_override("hover", yes_h)
    yes_btn.add_theme_stylebox_override("pressed", yes_style)
    yes_btn.add_theme_stylebox_override("focus", yes_style)
    yes_btn.pressed.connect(_on_reset_confirmed)
    hbox.add_child(yes_btn)
    # No button
    var no_btn = Button.new()
    no_btn.text = "✕ Hủy"
    no_btn.custom_minimum_size = Vector2(120, 36)
    var no_style = StyleBoxFlat.new()
    no_style.bg_color = Color(0.04, 0.10, 0.06, 0.95)
    no_style.corner_radius_top_left = 8
    no_style.corner_radius_top_right = 8
    no_style.corner_radius_bottom_left = 8
    no_style.corner_radius_bottom_right = 8
    no_style.border_color = Color(0.3, 1.0, 0.5, 0.5)
    no_style.border_width_top = 2
    no_style.border_width_bottom = 2
    no_style.border_width_left = 2
    no_style.border_width_right = 2
    var no_h = no_style.duplicate()
    no_h.bg_color = Color(0.06, 0.18, 0.10, 0.98)
    no_h.border_color = Color(0.3, 1.0, 0.5, 0.85)
    no_btn.add_theme_stylebox_override("normal", no_style)
    no_btn.add_theme_stylebox_override("hover", no_h)
    no_btn.add_theme_stylebox_override("pressed", no_style)
    no_btn.add_theme_stylebox_override("focus", no_style)
    no_btn.pressed.connect(_on_reset_cancelled)
    hbox.add_child(no_btn)
    # Animate scale-in
    _confirm_panel.scale = Vector2(0.85, 0.85)
    _confirm_panel.modulate.a = 0.0
    var tween = create_tween().set_parallel(true)
    tween.tween_property(_confirm_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(_confirm_panel, "modulate:a", 1.0, 0.15)

func _on_reset_confirmed():
    AudioManager.play_ui_click()
    if _confirm_panel and is_instance_valid(_confirm_panel):
        _confirm_panel.queue_free()
        _confirm_panel = null
    StageManager.reset_progress()
    _populate_grid()
    _update_stats()
    AudioManager.play_success()

func _on_reset_cancelled():
    AudioManager.play_ui_click()
    if _confirm_panel and is_instance_valid(_confirm_panel):
        var tween = create_tween().set_parallel(true)
        tween.tween_property(_confirm_panel, "scale", Vector2(0.92, 0.92), 0.1)
        tween.tween_property(_confirm_panel, "modulate:a", 0.0, 0.12)
        tween.chain().tween_callback(func():
            if is_instance_valid(_confirm_panel):
                _confirm_panel.queue_free()
                _confirm_panel = null)

func _style_button(btn: Button, accent: Color):
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
    normal.border_color = Color(accent.r, accent.g, accent.b, 0.5)
    normal.content_margin_top = 8
    normal.content_margin_bottom = 8
    normal.content_margin_left = 12
    normal.content_margin_right = 12
    normal.shadow_color = Color(0, 0, 0, 0.45)
    normal.shadow_size = 6
    normal.shadow_offset = Vector2(0, 3)
    var hover = normal.duplicate()
    hover.bg_color = COL_BG_HOVER
    hover.border_color = Color(accent.r, accent.g, accent.b, 0.9)
    var pressed = normal.duplicate()
    pressed.bg_color = Color(0.04, 0.04, 0.08, 0.98)
    pressed.border_color = Color(accent.r, accent.g, accent.b, 0.95)
    btn.add_theme_stylebox_override("normal", normal)
    btn.add_theme_stylebox_override("hover", hover)
    btn.add_theme_stylebox_override("pressed", pressed)
    btn.add_theme_stylebox_override("focus", normal)
    btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

func _style_locked_button(btn: Button):
    var normal = StyleBoxFlat.new()
    normal.bg_color = Color(0.04, 0.04, 0.06, 0.85)
    normal.corner_radius_top_left = 10
    normal.corner_radius_top_right = 10
    normal.corner_radius_bottom_left = 10
    normal.corner_radius_bottom_right = 10
    normal.border_width_top = 2
    normal.border_width_bottom = 2
    normal.border_width_left = 2
    normal.border_width_right = 2
    normal.border_color = Color(0.3, 0.3, 0.35, 0.4)
    normal.content_margin_top = 8
    normal.content_margin_bottom = 8
    normal.content_margin_left = 12
    normal.content_margin_right = 12
    btn.add_theme_stylebox_override("normal", normal)
    btn.add_theme_stylebox_override("hover", normal)
    btn.add_theme_stylebox_override("pressed", normal)
    btn.add_theme_stylebox_override("focus", normal)
    btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45, 0.6))

func _setup_touch_scale(btn: Control):
    if not btn:
        return
    btn.gui_input.connect(func(event: InputEvent):
        if event is InputEventMouseButton:
            if event.pressed:
                _animate_scale(btn, Vector2(1.06, 1.06), 0.1)
            else:
                _animate_scale(btn, Vector2(1.0, 1.0), 0.15)
        elif event is InputEventScreenTouch:
            if event.pressed:
                _animate_scale(btn, Vector2(1.06, 1.06), 0.1)
            else:
                _animate_scale(btn, Vector2(1.0, 1.0), 0.15)
    )

func _animate_scale(control: Control, target_scale: Vector2, duration: float):
    if not is_instance_valid(control):
        return
    var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(control, "scale", target_scale, duration)

func _unhandled_input(event: InputEvent):
    if event.is_action_pressed("menu_back"):
        get_viewport().set_input_as_handled()
        _on_back_pressed()
