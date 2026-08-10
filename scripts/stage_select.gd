extends Control

## StageSelect - Màn hình chọn ải (v3.5)
## Hiển thị 20 ải dạng lưới. ải đã mở khóa có thể chọn, ải chưa mở khóa bị mờ.
## Hiển thị best time mỗi ải, số lần thử.
## Nút "Reset Tiến Độ" để chơi lại từ đầu.

@onready var grid: GridContainer = $CenterContainer/VBox/ScrollContainer/Grid
@onready var back_btn: Button = $CenterContainer/VBox/BackBtn
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var stats_label: Label = $CenterContainer/VBox/StatsLabel
@onready var reset_btn: Button = $CenterContainer/VBox/ResetBtn

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
        # Build label
        var label_text = "ẢI %d" % stage_num
        if is_final:
            label_text = "ẢI %d\nBOSS" % stage_num
        if StageManager.best_time_per_stage.has(stage_num):
            label_text += "\n⏱ %s" % StageManager.format_time(StageManager.best_time_per_stage[stage_num])
        btn.text = label_text
        btn.add_theme_font_size_override("font_size", 14)
        # Style theo trạng thái
        if is_final:
            _style_button(btn, COL_RED)
        elif unlocked:
            _style_button(btn, COL_GREEN if not is_current else COL_GOLD)
        else:
            _style_locked_button(btn)
            btn.disabled = true
        # Click handler
        if unlocked:
            btn.pressed.connect(_on_stage_pressed.bind(stage_num))
            _setup_touch_scale(btn)
        grid.add_child(btn)

func _update_stats():
    var completed = StageManager.best_time_per_stage.size()
    var total_attempts = 0
    for stage in StageManager.attempts_per_stage.keys():
        total_attempts += StageManager.attempts_per_stage[stage]
    stats_label.text = "Đã hoàn thành: %d/%d  •  Tổng số lần thử: %d  •  Tổng số chết: %d  •  Boss đã giết: %d" % [
        completed, StageManager.TOTAL_STAGES, total_attempts,
        StageManager.total_deaths, StageManager.total_boss_kills
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
    # Confirm dialog đơn giản — reset ngay
    StageManager.reset_progress()
    _populate_grid()
    _update_stats()
    AudioManager.play_success()

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
