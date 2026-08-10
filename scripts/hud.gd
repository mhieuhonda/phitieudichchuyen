extends CanvasLayer

## HUD - Giao diện người chơi (v3.5) - Code-based UI
## v3.5:
##   - Hiển thị "ẢI X/20" thay cho match timer
##   - Thanh máu BOSS lớn trên cùng (khi đánh boss)
##   - Panel "VƯỢT ẢI!" khi complete stage
##   - Panel "THẤT BẠI!" khi fail stage
##   - Số lần chết còn lại trong ải
## v3.4: Bỏ SkillPanel (đã xóa 3 kỹ năng). Chỉ còn HP/Điểm/Phi tiêu/Combo.
## v3.3: Bỏ hoàn toàn Win.png + YouDie.png. Thay bằng BigBanner (Label lớn) vẽ bằng code
##       với hiệu ứng fade-in/scale. Result buttons chuyển từ TextureButton → Button.

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var hp_bar: ProgressBar = $TopBar/HpBar
@onready var dart_count_label: Label = $TopBar/DartCountLabel
@onready var zone_warning: Panel = $ZoneWarning
@onready var zone_timer_label: Label = $TopBar/ZoneTimerLabel
@onready var kill_feed: VBoxContainer = $KillFeed
@onready var alive_label: Label = $TopBar/AliveLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var restart_label: Label = $GameOverPanel/RestartLabel
@onready var combo_label: Label = $ComboLabel
@onready var match_timer_label: Label = $MatchTimerLabel
@onready var mid_flight_hint: Label = $MidFlightHint
@onready var fps_label: Label = $FPSLabel
@onready var results_panel: Panel = $ResultsPanel
@onready var results_title: Label = $ResultsPanel/ResultsTitle
@onready var results_list: VBoxContainer = $ResultsPanel/ResultsList
@onready var results_restart_btn: Button = $ResultsPanel/ResultsRestartBtn
@onready var results_menu_btn: Button = $ResultsPanel/ResultsMenuBtn
@onready var big_banner: Label = $BigBanner
# v3.5: Stage UI elements
@onready var stage_label: Label = $StageLabel
@onready var boss_hp_container: Panel = $BossHpContainer
@onready var boss_hp_bar: ProgressBar = $BossHpContainer/BossHpBar
@onready var boss_name_label: Label = $BossHpContainer/BossNameLabel
@onready var stage_clear_panel: Panel = $StageClearPanel
@onready var stage_clear_title: Label = $StageClearPanel/StageClearTitle
@onready var stage_clear_subtitle: Label = $StageClearPanel/StageClearSubtitle
@onready var stage_clear_next_btn: Button = $StageClearPanel/StageClearNextBtn
@onready var stage_clear_menu_btn: Button = $StageClearPanel/StageClearMenuBtn
@onready var stage_fail_panel: Panel = $StageFailPanel
@onready var stage_fail_title: Label = $StageFailPanel/StageFailTitle
@onready var stage_fail_subtitle: Label = $StageFailPanel/StageFailSubtitle
@onready var stage_fail_retry_btn: Button = $StageFailPanel/StageFailRetryBtn
@onready var stage_fail_menu_btn: Button = $StageFailPanel/StageFailMenuBtn
@onready var deaths_label: Label = $DeathsLabel

# v3.8: Boss HP segment markers (12 segments, vạch trắng chia HP bar)
var _boss_hp_segments: Line2D = null
# v3.8: Boss HP percentage text (hiển thị lớn bên dưới bar)
var _boss_hp_pct_label: Label = null
# v3.8: Onboarding hint panel (chỉ hiện ải 1 lần đầu)
var _onboarding_panel: Panel = null
var _onboarding_dismissed: bool = false

var player: CharacterBody2D = null
var zone_shrink_timer: float = 0.0
var combo_display_timer: float = 0.0
var fps_update_timer: float = 0.0
var zone_warning_sound_timer: float = 0.0
var was_outside_zone: bool = false
var _combo_display_active: bool = false
var _kill_streak: int = 0
var _kill_streak_timer: float = 0.0
const KILL_STREAK_WINDOW: float = 5.0

# v3.5: Stage state
var current_stage: int = 1
var boss_ref: Node2D = null
var is_boss_stage: bool = false

# Premium colors
const GOLD := Color(1.0, 0.85, 0.3)
const CYAN := Color(0.4, 0.9, 1.0)
const GREEN := Color(0.3, 1.0, 0.5)
const PURPLE := Color(0.7, 0.65, 1.0)
const RED := Color(1.0, 0.4, 0.3)
const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.13, 0.11, 0.22, 0.98)

func _ready():
    GameManager.player_score_changed.connect(_on_score_changed)
    GameManager.player_size_changed.connect(_on_size_changed)
    GameManager.player_hp_changed.connect(_on_hp_changed)
    GameManager.zone_shrank.connect(_on_zone_shrank)
    GameManager.combo_achieved.connect(_on_combo_achieved)
    GameManager.screen_shake_requested.connect(_on_screen_shake)
    GameManager.match_time_changed.connect(_on_match_time_changed)
    GameManager.game_over.connect(_on_game_over)
    # v3.5: Stage signals
    GameManager.stage_cleared.connect(_on_stage_cleared)
    GameManager.stage_failed_signal.connect(_on_stage_failed)
    GameManager.boss_hp_changed.connect(_on_boss_hp_changed)
    GameManager.ai_count_changed.connect(_on_ai_count_changed)
    add_to_group("hud")
    if not GameManager.daily_reward_granted.is_connected(_on_daily_reward):
        GameManager.daily_reward_granted.connect(_on_daily_reward)

    zone_shrink_timer = GameManager.zone_shrink_interval

    game_over_panel.visible = false
    zone_warning.visible = false
    combo_label.visible = false
    mid_flight_hint.visible = false
    results_panel.visible = false
    # v3.5: Stage UI panels
    if stage_clear_panel:
        stage_clear_panel.visible = false
    if stage_fail_panel:
        stage_fail_panel.visible = false
    if boss_hp_container:
        boss_hp_container.visible = false
    if stage_label:
        stage_label.visible = true
    if deaths_label:
        deaths_label.visible = true

    if big_banner:
        big_banner.visible = false

    fps_label.visible = SettingsManager.show_fps

    if results_restart_btn:
        results_restart_btn.pressed.connect(_on_results_restart)
    if results_menu_btn:
        results_menu_btn.pressed.connect(_on_results_menu)
    # v3.5: Stage panel buttons
    if stage_clear_next_btn:
        stage_clear_next_btn.pressed.connect(_on_stage_clear_next)
    if stage_clear_menu_btn:
        stage_clear_menu_btn.pressed.connect(_on_stage_clear_menu)
    if stage_fail_retry_btn:
        stage_fail_retry_btn.pressed.connect(_on_stage_fail_retry)
    if stage_fail_menu_btn:
        stage_fail_menu_btn.pressed.connect(_on_stage_fail_menu)

    _apply_premium_styling()
    _apply_ui_opacity()
    _setup_touch_scale(results_restart_btn)
    _setup_touch_scale(results_menu_btn)
    if stage_clear_next_btn:
        _setup_touch_scale(stage_clear_next_btn)
    if stage_clear_menu_btn:
        _setup_touch_scale(stage_clear_menu_btn)
    if stage_fail_retry_btn:
        _setup_touch_scale(stage_fail_retry_btn)
    if stage_fail_menu_btn:
        _setup_touch_scale(stage_fail_menu_btn)

    if I18N:
        I18N.language_changed.connect(func(_l): _refresh_ui())

func _refresh_ui():
    if results_restart_btn:
        results_restart_btn.text = "CHƠI LẠI" if I18N.is_vi() else "PLAY AGAIN"
    if results_menu_btn:
        results_menu_btn.text = "VỀ MENU" if I18N.is_vi() else "MAIN MENU"
    if stage_clear_next_btn:
        if current_stage >= StageManager.TOTAL_STAGES:
            stage_clear_next_btn.text = "HOÀN THÀNH" if I18N.is_vi() else "FINISH"
        else:
            stage_clear_next_btn.text = "ẢI TIẾP THEO" if I18N.is_vi() else "NEXT STAGE"
    if stage_clear_menu_btn:
        stage_clear_menu_btn.text = "VỀ MENU" if I18N.is_vi() else "MAIN MENU"
    if stage_fail_retry_btn:
        stage_fail_retry_btn.text = "THỬ LẠI" if I18N.is_vi() else "RETRY"
    if stage_fail_menu_btn:
        stage_fail_menu_btn.text = "VỀ MENU" if I18N.is_vi() else "MAIN MENU"

## v3.5: Set stage hiện tại
func set_stage(stage: int):
    current_stage = stage
    is_boss_stage = (stage == StageManager.FINAL_STAGE)
    if stage_label:
        if is_boss_stage:
            stage_label.text = "ẢI CUỐI — BOSS"
            stage_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
        else:
            stage_label.text = "ẢI %d / %d" % [stage, StageManager.TOTAL_STAGES]
            stage_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
    _refresh_ui()
    # v3.8: Hiện onboarding hint panel nếu là ải 1 và chưa dismissed
    if stage == 1 and not _onboarding_dismissed:
        _show_onboarding_hint()

## v3.8: Hiện onboarding panel — hướng dẫn cơ bản cho người chơi mới.
## Chỉ hiện ở ải 1, có nút "Đã hiểu" để dismiss.
func _show_onboarding_hint():
    if _onboarding_panel and is_instance_valid(_onboarding_panel):
        return  # đã tồn tại
    if not _onboarding_panel:
        _onboarding_panel = Panel.new()
        _onboarding_panel.set_anchors_preset(Control.PRESET_CENTER)
        _onboarding_panel.offset_left = -260
        _onboarding_panel.offset_right = 260
        _onboarding_panel.offset_top = -180
        _onboarding_panel.offset_bottom = 180
        _onboarding_panel.z_index = 180
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.04, 0.06, 0.10, 0.97)
        style.border_color = Color(0.4, 0.6, 1.0, 0.6)
        style.border_width_top = 3
        style.border_width_bottom = 3
        style.border_width_left = 3
        style.border_width_right = 3
        style.corner_radius_top_left = 14
        style.corner_radius_top_right = 14
        style.corner_radius_bottom_left = 14
        style.corner_radius_bottom_right = 14
        style.shadow_color = Color(0, 0, 0, 0.6)
        style.shadow_size = 15
        _onboarding_panel.add_theme_stylebox_override("panel", style)
        add_child(_onboarding_panel)
        # Title
        var title = Label.new()
        title.text = "🎯 HƯỚNG DẪN"
        title.set_anchors_preset(Control.PRESET_CENTER_TOP)
        title.offset_left = -200
        title.offset_right = 200
        title.offset_top = 14
        title.offset_bottom = 50
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title.add_theme_font_size_override("font_size", 24)
        title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
        title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
        _onboarding_panel.add_child(title)
        # Body
        var body = Label.new()
        body.text = "🎮 DI CHUYỂN: WASD / ←↑↓→ / Joystick trái

🎯 NÉM PHI TIÊU:
   • PC: Kéo chuột phải → thả để ném
   • Mobile: Nút ĐỎ (NÉM) — kéo để nhắm

✨ DỊCH CHUYỂN: Space (PC) / Nút XANH (DỊCH)
   Dịch tới phi tiêu gần nhất để tiêu diệt địch trong bán kính 50px

⚡ PAUSE: P hoặc ESC | R: Chơi lại ải

💡 Mẹo: Phi tiêu NẢY khi chạm tường — hãy tận dụng góc bắn!"
        body.set_anchors_preset(Control.PRESET_CENTER)
        body.offset_left = -230
        body.offset_right = 230
        body.offset_top = -100
        body.offset_bottom = 130
        body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        body.add_theme_font_size_override("font_size", 13)
        body.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
        body.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
        body.add_theme_constant_override("shadow_offset_y", 1)
        body.add_theme_constant_override("shadow_outline_size", 2)
        _onboarding_panel.add_child(body)
        # Dismiss button
        var btn = Button.new()
        btn.text = "✓ ĐÃ HIỂU — VÀO GAME!"
        btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
        btn.offset_left = -120
        btn.offset_right = 120
        btn.offset_top = 130
        btn.offset_bottom = 168
        var style_n = StyleBoxFlat.new()
        style_n.bg_color = Color(0.04, 0.18, 0.10, 0.95)
        style_n.corner_radius_top_left = 10
        style_n.corner_radius_top_right = 10
        style_n.corner_radius_bottom_left = 10
        style_n.corner_radius_bottom_right = 10
        style_n.border_color = Color(0.3, 1.0, 0.5, 0.6)
        style_n.border_width_top = 2
        style_n.border_width_bottom = 2
        style_n.border_width_left = 2
        style_n.border_width_right = 2
        var style_h = style_n.duplicate()
        style_h.bg_color = Color(0.08, 0.25, 0.12, 0.98)
        style_h.border_color = Color(0.3, 1.0, 0.5, 0.9)
        btn.add_theme_stylebox_override("normal", style_n)
        btn.add_theme_stylebox_override("hover", style_h)
        btn.add_theme_stylebox_override("pressed", style_n)
        btn.add_theme_stylebox_override("focus", style_n)
        btn.pressed.connect(_dismiss_onboarding)
        _onboarding_panel.add_child(btn)
    # Animate scale-in
    _onboarding_panel.scale = Vector2(0.85, 0.85)
    _onboarding_panel.modulate.a = 0.0
    var tween = create_tween().set_parallel(true)
    tween.tween_property(_onboarding_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(_onboarding_panel, "modulate:a", 1.0, 0.2)

func _dismiss_onboarding():
    _onboarding_dismissed = true
    if not _onboarding_panel:
        return
    var tween = create_tween().set_parallel(true)
    tween.tween_property(_onboarding_panel, "scale", Vector2(0.92, 0.92), 0.12)
    tween.tween_property(_onboarding_panel, "modulate:a", 0.0, 0.15)
    tween.chain().tween_callback(func():
        if is_instance_valid(_onboarding_panel):
            _onboarding_panel.visible = false)
    AudioManager.play_ui_click()

## v3.5: Set boss ref (khi vào ải 20)
## v3.8: FIX BUG — trước đây hardcode "BOSS — 10,000,000 HP" trong khi BOSS_MAX_HP
## thực tế đã được đổi thành 12M (v3.7). Dùng dynamic text từ constant để đồng bộ.
## v3.8: THÊM segment markers (12 vạch chia HP bar) + percentage label lớn.
func set_boss(boss: Node2D):
    boss_ref = boss
    if boss_hp_container:
        boss_hp_container.visible = true
    if boss_name_label:
        var max_hp_int = int(StageManager.BOSS_MAX_HP)
        boss_name_label.text = "BOSS — %s HP" % _format_big_number(max_hp_int)
        boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
    if boss_hp_bar:
        boss_hp_bar.max_value = StageManager.BOSS_MAX_HP
        boss_hp_bar.value = StageManager.BOSS_MAX_HP
    # v3.8: Setup segment markers + percentage label
    _setup_boss_hp_segments()
    _setup_boss_hp_pct_label()

## v3.8: Tạo 11 vạch dọc chia Boss HP bar thành 12 đoạn (mỗi đoạn = 8.33% HP).
## Giúp player thấy rõ tiến độ damage. Vạch màu trắng mờ, vạch cuối (rage threshold
## ở 12% HP) màu cam sáng.
func _setup_boss_hp_segments():
    if _boss_hp_segments and is_instance_valid(_boss_hp_segments):
        _boss_hp_segments.queue_free()
    if not boss_hp_bar:
        return
    _boss_hp_segments = Line2D.new()
    _boss_hp_segments.width = 1.5
    _boss_hp_segments.default_color = Color(1.0, 1.0, 1.0, 0.35)
    _boss_hp_segments.z_index = 5
    # Vẽ 11 vạch dọc (chia 12 đoạn)
    var bar_rect = boss_hp_bar.get_rect()
    var bar_w = bar_rect.size.x
    var bar_h = bar_rect.size.y
    var num_segments = 12
    for i in range(1, num_segments):
        var x = bar_rect.position.x + (bar_w * i) / float(num_segments)
        # Vạch cuối (i=11) = 1/12 ≈ 8.33% HP → gần rage threshold (12%)
        # Đánh dấu vạch rage bằng màu cam sáng
        if i >= num_segments - 1:
            _boss_hp_segments.add_point(Vector2(x, bar_rect.position.y - 2))
            _boss_hp_segments.add_point(Vector2(x, bar_rect.position.y + bar_h + 2))
            # Phải add_point liên tục vì Line2D vẽ nối điểm
        else:
            _boss_hp_segments.add_point(Vector2(x, bar_rect.position.y - 1))
            _boss_hp_segments.add_point(Vector2(x, bar_rect.position.y + bar_h + 1))
    boss_hp_bar.add_child(_boss_hp_segments)

## v3.8: Setup label % HP lớn bên dưới bar — hiển thị "87.3%" rõ ràng
func _setup_boss_hp_pct_label():
    if _boss_hp_pct_label and is_instance_valid(_boss_hp_pct_label):
        _boss_hp_pct_label.queue_free()
    if not boss_hp_container:
        return
    _boss_hp_pct_label = Label.new()
    _boss_hp_pct_label.text = "100.0%"
    _boss_hp_pct_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    _boss_hp_pct_label.offset_left = -60
    _boss_hp_pct_label.offset_right = 60
    _boss_hp_pct_label.offset_top = 1
    _boss_hp_pct_label.offset_bottom = 18
    _boss_hp_pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _boss_hp_pct_label.add_theme_font_size_override("font_size", 11)
    _boss_hp_pct_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.95))
    _boss_hp_pct_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
    _boss_hp_pct_label.add_theme_constant_override("shadow_offset_y", 1)
    _boss_hp_pct_label.add_theme_constant_override("shadow_outline_size", 2)
    boss_hp_container.add_child(_boss_hp_pct_label)

## v3.8: Format số lớn với dấu phẩy ngăn cách hàng nghìn (VD: 12000000 → "12,000,000")
func _format_big_number(n: int) -> String:
    var s = str(n)
    var out = ""
    var count = 0
    for i in range(s.length() - 1, -1, -1):
        if count > 0 and count % 3 == 0:
            out = "," + out
        out = s[i] + out
        count += 1
    return out

func _setup_touch_scale(btn: Control):
    if not btn:
        return
    btn.gui_input.connect(func(event: InputEvent):
        if event is InputEventMouseButton:
            if event.pressed:
                _animate_scale(btn, Vector2(1.08, 1.08), 0.1)
            else:
                _animate_scale(btn, Vector2(1.0, 1.0), 0.15)
        elif event is InputEventScreenTouch:
            if event.pressed:
                _animate_scale(btn, Vector2(1.08, 1.08), 0.1)
            else:
                _animate_scale(btn, Vector2(1.0, 1.0), 0.15)
    )

func _animate_scale(control: Control, target_scale: Vector2, duration: float):
    if not is_instance_valid(control):
        return
    var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(control, "scale", target_scale, duration)

func _apply_premium_styling():
    if $TopBar:
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.04, 0.04, 0.08, 0.88)
        style.border_color = Color(0.25, 0.2, 0.4, 0.3)
        style.border_width_bottom = 2
        style.shadow_color = Color(0, 0, 0, 0.4)
        style.shadow_size = 4
        style.shadow_offset = Vector2(0, 3)
        $TopBar.add_theme_stylebox_override("panel", style)

    if hp_bar:
        var fill_style = StyleBoxFlat.new()
        fill_style.bg_color = Color(0.2, 0.85, 0.3)
        fill_style.corner_radius_top_left = 4
        fill_style.corner_radius_top_right = 4
        fill_style.corner_radius_bottom_left = 4
        fill_style.corner_radius_bottom_right = 4
        hp_bar.add_theme_stylebox_override("fill", fill_style)
        var bg_style = StyleBoxFlat.new()
        bg_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
        bg_style.corner_radius_top_left = 4
        bg_style.corner_radius_top_right = 4
        bg_style.corner_radius_bottom_left = 4
        bg_style.corner_radius_bottom_right = 4
        hp_bar.add_theme_stylebox_override("background", bg_style)

    # v3.5: Style Boss HP bar (đỏ đậm, lớn hơn)
    if boss_hp_bar:
        var boss_fill = StyleBoxFlat.new()
        boss_fill.bg_color = Color(0.85, 0.15, 0.1)
        boss_fill.corner_radius_top_left = 6
        boss_fill.corner_radius_top_right = 6
        boss_fill.corner_radius_bottom_left = 6
        boss_fill.corner_radius_bottom_right = 6
        boss_hp_bar.add_theme_stylebox_override("fill", boss_fill)
        var boss_bg = StyleBoxFlat.new()
        boss_bg.bg_color = Color(0.15, 0.04, 0.04, 0.95)
        boss_bg.corner_radius_top_left = 6
        boss_bg.corner_radius_top_right = 6
        boss_bg.corner_radius_bottom_left = 6
        boss_bg.corner_radius_bottom_right = 6
        boss_bg.border_color = Color(0.6, 0.15, 0.1, 0.7)
        boss_bg.border_width_top = 2
        boss_bg.border_width_bottom = 2
        boss_bg.border_width_left = 2
        boss_bg.border_width_right = 2
        boss_hp_bar.add_theme_stylebox_override("background", boss_bg)

    if boss_hp_container:
        var cstyle = StyleBoxFlat.new()
        cstyle.bg_color = Color(0.06, 0.03, 0.05, 0.85)
        cstyle.border_color = Color(0.7, 0.2, 0.15, 0.5)
        cstyle.border_width_top = 2
        cstyle.border_width_bottom = 2
        cstyle.border_width_left = 2
        cstyle.border_width_right = 2
        cstyle.corner_radius_top_left = 8
        cstyle.corner_radius_top_right = 8
        cstyle.corner_radius_bottom_left = 8
        cstyle.corner_radius_bottom_right = 8
        boss_hp_container.add_theme_stylebox_override("panel", cstyle)

    # v3.5: Style stage panels
    if stage_clear_panel:
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.04, 0.06, 0.04, 0.95)
        style.border_color = Color(0.3, 0.85, 0.4, 0.7)
        style.border_width_top = 3
        style.border_width_bottom = 3
        style.border_width_left = 3
        style.border_width_right = 3
        style.corner_radius_top_left = 14
        style.corner_radius_top_right = 14
        style.corner_radius_bottom_left = 14
        style.corner_radius_bottom_right = 14
        stage_clear_panel.add_theme_stylebox_override("panel", style)
    if stage_fail_panel:
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.08, 0.02, 0.02, 0.95)
        style.border_color = Color(0.9, 0.2, 0.15, 0.7)
        style.border_width_top = 3
        style.border_width_bottom = 3
        style.border_width_left = 3
        style.border_width_right = 3
        style.corner_radius_top_left = 14
        style.corner_radius_top_right = 14
        style.corner_radius_bottom_left = 14
        style.corner_radius_bottom_right = 14
        stage_fail_panel.add_theme_stylebox_override("panel", style)

    if game_over_panel:
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.04, 0.02, 0.06, 0.92)
        style.border_color = Color(0.8, 0.2, 0.2, 0.5)
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.border_width_left = 2
        style.border_width_right = 2
        style.corner_radius_top_left = 12
        style.corner_radius_top_right = 12
        style.corner_radius_bottom_left = 12
        style.corner_radius_bottom_right = 12
        style.shadow_color = Color(0.3, 0, 0, 0.5)
        style.shadow_size = 10
        game_over_panel.add_theme_stylebox_override("panel", style)

    if results_panel:
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.02, 0.02, 0.05, 0.95)
        style.border_color = Color(0.5, 0.4, 0.15, 0.4)
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.border_width_left = 2
        style.border_width_right = 2
        results_panel.add_theme_stylebox_override("panel", style)

    _style_button(results_restart_btn, Color(0.04, 0.1, 0.06, 0.9), GREEN)
    _style_button(results_menu_btn, Color(0.08, 0.06, 0.14, 0.9), PURPLE)
    # v3.5: Style stage panel buttons
    if stage_clear_next_btn:
        _style_button(stage_clear_next_btn, Color(0.06, 0.1, 0.04, 0.9), GOLD)
    if stage_clear_menu_btn:
        _style_button(stage_clear_menu_btn, Color(0.08, 0.06, 0.14, 0.9), PURPLE)
    if stage_fail_retry_btn:
        _style_button(stage_fail_retry_btn, Color(0.1, 0.05, 0.04, 0.9), RED)
    if stage_fail_menu_btn:
        _style_button(stage_fail_menu_btn, Color(0.08, 0.06, 0.14, 0.9), PURPLE)

    if zone_warning:
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.2, 0.04, 0.04, 0.85)
        style.border_color = Color(1.0, 0.2, 0.2, 0.6)
        style.border_width_top = 1
        style.border_width_bottom = 1
        style.border_width_left = 1
        style.border_width_right = 1
        style.corner_radius_top_left = 8
        style.corner_radius_top_right = 8
        style.corner_radius_bottom_left = 8
        style.corner_radius_bottom_right = 8
        zone_warning.add_theme_stylebox_override("panel", style)

func _style_button(btn: Button, bg_color: Color, accent_color: Color):
    if not btn:
        return
    var style_normal = StyleBoxFlat.new()
    style_normal.bg_color = bg_color
    style_normal.corner_radius_top_left = 8
    style_normal.corner_radius_top_right = 8
    style_normal.corner_radius_bottom_left = 8
    style_normal.corner_radius_bottom_right = 8
    style_normal.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.3)
    style_normal.border_width_top = 1
    style_normal.border_width_bottom = 1
    style_normal.border_width_left = 1
    style_normal.border_width_right = 1
    style_normal.content_margin_top = 8
    style_normal.content_margin_bottom = 8
    style_normal.content_margin_left = 18
    style_normal.content_margin_right = 18
    style_normal.shadow_color = Color(0, 0, 0, 0.3)
    style_normal.shadow_size = 4
    style_normal.shadow_offset = Vector2(0, 2)

    var style_hover = style_normal.duplicate()
    style_hover.bg_color = Color(bg_color.r + 0.04, bg_color.g + 0.04, bg_color.b + 0.06, bg_color.a)
    style_hover.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.6)

    var style_pressed = style_normal.duplicate()
    style_pressed.bg_color = Color(bg_color.r * 0.5, bg_color.g * 0.5, bg_color.b * 0.5, 0.98)

    btn.add_theme_stylebox_override("normal", style_normal)
    btn.add_theme_stylebox_override("hover", style_hover)
    btn.add_theme_stylebox_override("pressed", style_pressed)
    btn.add_theme_stylebox_override("focus", style_normal)

    btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

func _apply_ui_opacity():
    var opacity = SettingsManager.ui_opacity
    if $TopBar:
        $TopBar.modulate.a = opacity

func set_player(p: CharacterBody2D):
    player = p
    player.player_died.connect(_on_player_died)
    player.player_respawned.connect(_on_player_respawned)
    player.dart_thrown.connect(_on_dart_thrown)
    player.teleport_performed.connect(_on_teleport_performed)

func _process(delta):
    if not player:
        return

    # Cập nhật thanh máu
    hp_bar.value = GameManager.player_hp
    hp_bar.max_value = GameManager.player_max_hp
    var hp_ratio = GameManager.player_hp / GameManager.player_max_hp if GameManager.player_max_hp > 0 else 0
    var hp_fill = hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
    if hp_fill:
        if hp_ratio > 0.6:
            hp_fill.bg_color = Color(0.2, 0.85, 0.3)
        elif hp_ratio > 0.3:
            hp_fill.bg_color = Color(0.9, 0.8, 0.15)
        else:
            hp_fill.bg_color = Color(0.9, 0.2, 0.15)

    # v3.8: Tính dart info & flying flag trong 1 lần lặp duy nhất
    # (trước đây lặp 2 lần qua player.all_darts mỗi frame — wasteful).
    var dart_stats = _get_dart_stats()
    dart_count_label.text = dart_stats["info"]
    mid_flight_hint.visible = dart_stats["has_flying"]

    # v3.5: Stage mode — không thu nhỏ vòng bo
    if not GameManager.is_stage_mode:
        zone_shrink_timer -= delta
        if zone_shrink_timer <= 0 and GameManager.game_active:
            GameManager.shrink_zone()
            zone_shrink_timer = GameManager.zone_shrink_interval
    zone_timer_label.text = "Bo: ∞" if GameManager.is_stage_mode else "Bo: %.0fs" % zone_shrink_timer

    # Cảnh báo ngoài vòng bo (vẫn có trong stage mode nếu player đi quá xa)
    if not GameManager.is_in_zone(player.global_position):
        zone_warning.visible = true
        zone_warning_sound_timer -= delta
        if zone_warning_sound_timer <= 0:
            AudioManager.play_zone_warning()
            zone_warning_sound_timer = 1.5
        was_outside_zone = true
    else:
        zone_warning.visible = false
        if was_outside_zone:
            was_outside_zone = false
            zone_warning_sound_timer = 0.0

    # v3.8: Dùng GameManager.stage_alive_ai (đã được duy trì chính xác bởi
    # GameManager.on_ai_killed_in_stage) thay vì lặp qua group ai_players mỗi
    # frame. Ngoài ra vẫn đếm group cho non-stage mode.
    if GameManager.is_stage_mode:
        alive_label.text = "Địch: %d/%d" % [GameManager.stage_alive_ai, GameManager.stage_total_ai]
    else:
        var alive_count = 0
        for a in get_tree().get_nodes_in_group("ai_players"):
            if is_instance_valid(a) and "is_alive" in a and a.is_alive:
                alive_count += 1
        if is_instance_valid(player) and player.is_alive:
            alive_count += 1
        alive_label.text = "Sống: %d" % alive_count

    # v3.5: Stage mode — hiển thị thời gian đã trôi qua thay vì countdown
    if GameManager.is_stage_mode:
        match_timer_label.text = "⏱ %s" % StageManager.format_time(StageManager.get_elapsed_stage_time())
        match_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
    else:
        match_timer_label.text = "%s" % GameManager.get_time_remaining_str()
        if GameManager.time_remaining <= 30.0:
            match_timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
        else:
            match_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

    # v3.5: Update deaths label
    if deaths_label:
        var max_deaths = StageManager.get_max_deaths_per_stage(current_stage)
        var deaths_used = StageManager.player_deaths_this_stage
        var deaths_left = max(0, max_deaths - deaths_used)
        deaths_label.text = "Mạng: %d" % deaths_left
        if deaths_left <= 1:
            deaths_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
        else:
            deaths_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))

    # Combo display timer
    if combo_label.visible and _combo_display_active:
        combo_display_timer -= delta
        if combo_display_timer <= 0:
            combo_label.visible = false
            _combo_display_active = false

    if _kill_streak > 0:
        _kill_streak_timer -= delta
        if _kill_streak_timer <= 0:
            _kill_streak = 0

    fps_label.visible = SettingsManager.show_fps
    if SettingsManager.show_fps:
        fps_update_timer -= delta
        if fps_update_timer <= 0:
            fps_update_timer = 0.5
            fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

## v3.8: Kết hợp _get_dart_info + _has_flying_darts thành 1 lần lặp duy nhất
## mỗi frame. Trả về Dictionary với "info" (string hiển thị) và "has_flying".
func _get_dart_stats() -> Dictionary:
    var flying = 0
    var stuck = 0
    for dart in player.all_darts:
        if is_instance_valid(dart):
            if dart.is_flying():
                flying += 1
            elif dart.is_stuck():
                stuck += 1
    var max_darts = GameManager.max_darts_per_player + player.dart_bonus + player.char_dart_bonus
    var info: String
    if flying > 0:
        info = "Phi tiêu: %d bay + %d cắm / %d" % [flying, stuck, max_darts]
    elif stuck > 0:
        info = "Phi tiêu: %d cắm / %d" % [stuck, max_darts]
    else:
        info = "Phi tiêu: 0/%d" % max_darts
    return {"info": info, "has_flying": flying > 0}

# v3.8: Giữ lại hàm cũ dưới tên alias để code bên ngoài (nếu có) không vỡ.
func _get_dart_info() -> String:
    return _get_dart_stats()["info"]

func _has_flying_darts() -> bool:
    return _get_dart_stats()["has_flying"]

func _on_score_changed(new_score: int):
    score_label.text = "Điểm: %d" % new_score

func _on_size_changed(new_size: float):
    pass

func _on_hp_changed(hp: float, max_hp: float):
    hp_bar.value = hp
    hp_bar.max_value = max_hp

func _on_match_time_changed(time_remaining: float):
    # v3.5: Stage mode dùng -1.0 làm sentinel — HUD tự tính time trong _process
    pass

# v3.5: Boss HP handler
## v3.8: Cập nhật thêm percentage label lớn bên dưới bar
func _on_boss_hp_changed(hp: float, max_hp: float, is_rage: bool):
    if not boss_hp_bar:
        return
    boss_hp_bar.value = hp
    boss_hp_bar.max_value = max_hp
    # Đổi màu fill khi rage
    var fill = boss_hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
    if fill:
        if is_rage:
            fill.bg_color = Color(1.0, 0.4, 0.1, 1.0)  # cam sáng khi rage
        else:
            fill.bg_color = Color(0.85, 0.15, 0.1, 1.0)
    var pct = hp / max_hp * 100.0 if max_hp > 0 else 0
    # Cập nhật label trên (tên + % HP)
    if boss_name_label:
        if is_rage:
            boss_name_label.text = "⚠ BOSS RAGE!  %.1f%% HP" % pct
            boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
        else:
            boss_name_label.text = "BOSS  %.1f%% HP  (%s / %s)" % [
                pct,
                _format_big_number(int(hp)),
                _format_big_number(int(max_hp))
            ]
            boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.7))
    # v3.8: Cập nhật % label lớn bên dưới
    if _boss_hp_pct_label:
        _boss_hp_pct_label.text = "%.1f%%" % pct
        if is_rage:
            _boss_hp_pct_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.1, 1.0))
        elif pct < 25.0:
            _boss_hp_pct_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))
        else:
            _boss_hp_pct_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.95))

func _on_ai_count_changed(alive_count: int, total_count: int):
    if alive_label:
        alive_label.text = "Địch: %d/%d" % [alive_count, total_count]

func _on_zone_shrank(new_radius: float):
    _add_kill_feed("Vòng bo thu nhỏ!", Color(1.0, 0.5, 0.0))

func _on_combo_achieved(combo_count: int):
    combo_label.text = "COMBO x%d!" % combo_count
    combo_label.visible = true
    combo_display_timer = 2.0
    _combo_display_active = true
    _add_kill_feed("COMBO x%d!" % combo_count, Color(1.0, 0.8, 0.0))

func _on_screen_shake(intensity: float, duration: float):
    var tween = create_tween()
    var steps = max(int(duration / 0.02), 1)
    for i in steps:
        var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
        tween.tween_property(self, "offset", offset, 0.02)
    tween.tween_property(self, "offset", Vector2.ZERO, 0.05)

func _on_player_died(p: CharacterBody2D):
    game_over_panel.visible = true
    var killer = p.get_killer_name()
    if killer != "":
        game_over_label.text = "BẠN BỊ %s TIÊU DIỆT!" % killer.to_upper()
    else:
        game_over_label.text = "BẠN ĐÃ BỊ TIÊU DIỆT!"
    # v3.5: Show deaths info in restart_label
    if GameManager.is_stage_mode:
        var max_deaths = StageManager.get_max_deaths_per_stage(current_stage)
        var deaths_left = max(0, max_deaths - StageManager.player_deaths_this_stage)
        if deaths_left > 0:
            restart_label.text = "Còn %d mạng — Hồi sinh sau %.0fs..." % [deaths_left, GameManager.respawn_time]
        else:
            restart_label.text = "Hết mạng — Thất bại!"
    else:
        restart_label.text = "Hồi sinh sau %.0fs..." % GameManager.respawn_time
    _add_kill_feed("Bạn đã bị tiêu diệt!", Color(1.0, 0.2, 0.2))
    _kill_streak = 0
    _kill_streak_timer = 0.0
    _show_big_banner("BẠN CHẾT!", Color(1.0, 0.25, 0.25, 1.0), 2.0)

func _on_player_respawned(p: CharacterBody2D):
    game_over_panel.visible = false
    _add_kill_feed("Đã hồi sinh!", Color(0.2, 1.0, 0.2))
    _hide_big_banner()

func _on_dart_thrown(dart: Node2D):
    mid_flight_hint.visible = true
    var hint_ref = mid_flight_hint
    var self_ref = self
    get_tree().create_timer(1.5).timeout.connect(func():
        if is_instance_valid(hint_ref) and is_instance_valid(self_ref):
            if not self_ref._has_flying_darts():
                hint_ref.visible = false
    )

func _on_teleport_performed(p: CharacterBody2D, to_position: Vector2):
    mid_flight_hint.visible = false

func _add_kill_feed(text: String, color: Color = Color.WHITE):
    var label = Label.new()
    label.text = text
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_size_override("font_size", 13)
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
    label.add_theme_constant_override("shadow_offset_y", 1)
    label.add_theme_constant_override("shadow_outline_size", 2)
    kill_feed.add_child(label)
    var tween = create_tween()
    tween.tween_interval(2.0)
    tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
    tween.tween_callback(label.queue_free)

func register_player_kill():
    _kill_streak += 1
    _kill_streak_timer = KILL_STREAK_WINDOW
    if _kill_streak < 2:
        return
    var announcement = ""
    var color = Color(1.0, 0.85, 0.2)
    match _kill_streak:
        2:
            announcement = "DOUBLE KILL!"
            color = Color(0.4, 1.0, 0.5)
        3:
            announcement = "TRIPLE KILL!"
            color = Color(1.0, 0.7, 0.2)
        4:
            announcement = "QUADRA KILL!"
            color = Color(1.0, 0.5, 0.3)
        5:
            announcement = "PENTA KILL!"
            color = Color(1.0, 0.4, 0.7)
        6, 7, 8:
            announcement = "KILLING SPREE x%d!" % _kill_streak
            color = Color(1.0, 0.4, 0.5)
        9, 10:
            announcement = "UNSTOPPABLE x%d!" % _kill_streak
            color = Color(1.0, 0.3, 0.5)
        _:
            announcement = "GODLIKE x%d!" % _kill_streak
            color = Color(1.0, 0.2, 0.8)
    if announcement != "":
        _add_kill_feed(announcement, color)
        if combo_label:
            combo_label.text = announcement
            combo_label.visible = true
            combo_display_timer = 2.5
            _combo_display_active = true
            combo_label.add_theme_color_override("font_color", color)
        if _kill_streak >= 3:
            AudioManager.play_combo(min(_kill_streak, 5))

func get_kill_streak() -> int:
    return _kill_streak

func _on_daily_reward(streak: int, hp_bonus_percent: float):
    var msg = "ĐĂNG NHẬP NGÀY %d!\n+%.0f%% HP bonus!" % [streak, hp_bonus_percent * 100]
    _add_kill_feed(msg, Color(1.0, 0.85, 0.2))
    if combo_label:
        combo_label.text = "DAY %d!\n+%.0f%% HP" % [streak, hp_bonus_percent * 100]
        combo_label.visible = true
        combo_display_timer = 4.0
        _combo_display_active = true
        combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
    AudioManager.play_achievement()

# === Big Banner ===

func _show_big_banner(text: String, color: Color, hold_seconds: float = 2.0):
    if not big_banner:
        return
    big_banner.text = text
    big_banner.add_theme_color_override("font_color", color)
    big_banner.visible = true
    big_banner.modulate.a = 0.0
    big_banner.scale = Vector2(0.7, 0.7)
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(big_banner, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(big_banner, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.chain().tween_interval(hold_seconds)
    tween.chain().tween_property(big_banner, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
    tween.tween_callback(func():
        if is_instance_valid(big_banner):
            big_banner.visible = false
    )

func _hide_big_banner():
    if not big_banner:
        return
    var tween = create_tween()
    tween.tween_property(big_banner, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD)
    tween.tween_callback(func():
        if is_instance_valid(big_banner):
            big_banner.visible = false
    )

# === v3.5: Stage Clear / Fail handlers ===
## v3.8: Hiển thị thêm thông tin stats: best time, PB (personal best), retries

func _on_stage_cleared(stage: int):
    _hide_big_banner()
    if stage_clear_panel:
        stage_clear_panel.visible = true
        var elapsed = StageManager.get_elapsed_stage_time()
        var elapsed_str = StageManager.format_time(elapsed)
        var best_time = StageManager.best_time_per_stage.get(stage, -1.0)
        var is_new_pb = best_time > 0 and elapsed <= best_time + 0.01
        var deaths_used = StageManager.player_deaths_this_stage
        var max_deaths = StageManager.get_max_deaths_per_stage(stage)
        var attempts = StageManager.attempts_per_stage.get(stage, 1)
        if stage >= StageManager.TOTAL_STAGES:
            stage_clear_title.text = "🎉 HOÀN THÀNH GAME! 🎉"
            stage_clear_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
            stage_clear_subtitle.text = "Bạn đã vượt tất cả %d ải và tiêu diệt Boss!\nThời gian ải cuối: %s" % [StageManager.TOTAL_STAGES, elapsed_str]
            if stage_clear_next_btn:
                stage_clear_next_btn.text = "VỀ MENU"
        else:
            stage_clear_title.text = "✦ VƯỢT ẢI %d! ✦" % stage
            stage_clear_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
            var pb_text = ""
            if is_new_pb and attempts > 1:
                pb_text = " 🏆 NEW PB!"
            elif best_time > 0:
                pb_text = "\nBest: %s" % StageManager.format_time(best_time)
            stage_clear_subtitle.text = "⏱ Thời gian: %s%s\n🎯 Số lần thử: %d\n❤ Mạng còn lại: %d / %d\n✓ Đã mở khóa ải %d!" % [
                elapsed_str, pb_text, attempts, max_deaths - deaths_used, max_deaths, stage + 1
            ]
            if stage_clear_next_btn:
                stage_clear_next_btn.text = "ẢI TIẾP THEO →"
        _refresh_ui()
    _show_big_banner("VƯỢT ẢI!", Color(0.4, 1.0, 0.5, 1.0), 2.0)

func _on_stage_failed(stage: int):
    _hide_big_banner()
    if stage_fail_panel:
        stage_fail_panel.visible = true
        stage_fail_title.text = "✗ THẤT BẠI ✗"
        stage_fail_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
        var elapsed = StageManager.get_elapsed_stage_time()
        var elapsed_str = StageManager.format_time(elapsed)
        var attempts = StageManager.attempts_per_stage.get(stage, 1)
        var deaths_used = StageManager.player_deaths_this_stage
        var max_deaths = StageManager.get_max_deaths_per_stage(stage)
        stage_fail_subtitle.text = "Bạn đã hết mạng ở ải %d.\n⏱ Thời gian: %s\n❤ Mạng: %d / %d (đã dùng hết)\n🎯 Lần thử: %d\n\nThử lại nhé!" % [
            stage, elapsed_str, deaths_used, max_deaths, attempts
        ]
        _refresh_ui()
    _show_big_banner("THẤT BẠI!", Color(1.0, 0.25, 0.25, 1.0), 2.5)

# === Stage panel button handlers ===

func _on_stage_clear_next():
    AudioManager.play_ui_click()
    if current_stage >= StageManager.TOTAL_STAGES:
        # Hoàn thành game — về menu
        get_tree().change_scene_to_file("res://scenes/menu.tscn")
        return
    # Sang ải tiếp theo
    var next_stage = current_stage + 1
    StageManager.current_stage = next_stage
    get_tree().reload_current_scene()

func _on_stage_clear_menu():
    AudioManager.play_ui_click()
    get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_stage_fail_retry():
    AudioManager.play_ui_click()
    get_tree().reload_current_scene()

func _on_stage_fail_menu():
    AudioManager.play_ui_click()
    get_tree().change_scene_to_file("res://scenes/menu.tscn")

# === Results (legacy, dùng cho non-stage mode) ===

func _show_results(winner_name: String, leaderboard: Array):
    game_over_panel.visible = false
    if big_banner and big_banner.visible:
        _hide_big_banner()
    results_panel.visible = true
    results_title.text = "KẾT THÚC! %s thắng!" % winner_name
    var is_player_win = false
    if leaderboard.size() > 0 and leaderboard[0].get("is_player", false):
        is_player_win = true
        results_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
        _show_big_banner("CHIẾN THẮNG!", Color(1.0, 0.85, 0.2, 1.0), 2.5)
    else:
        results_title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
    for child in results_list.get_children():
        child.queue_free()
    for i in range(leaderboard.size()):
        var entry = leaderboard[i]
        var row = HBoxContainer.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var rank_label = Label.new()
        rank_label.text = "#%d" % (i + 1)
        rank_label.custom_minimum_size = Vector2(60, 0)
        rank_label.add_theme_font_size_override("font_size", 20)
        rank_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
        rank_label.add_theme_constant_override("shadow_offset_y", 1)
        rank_label.add_theme_constant_override("shadow_outline_size", 2)
        if i == 0:
            rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
        elif i == 1:
            rank_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
        elif i == 2:
            rank_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.3))
        row.add_child(rank_label)
        var name_label2 = Label.new()
        name_label2.text = entry["name"]
        name_label2.custom_minimum_size = Vector2(160, 0)
        name_label2.add_theme_font_size_override("font_size", 18)
        name_label2.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
        name_label2.add_theme_constant_override("shadow_offset_y", 1)
        name_label2.add_theme_constant_override("shadow_outline_size", 2)
        if entry.get("is_player", false):
            name_label2.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
            name_label2.text = entry["name"] + " (Bạn)"
        row.add_child(name_label2)
        var score_lbl = Label.new()
        score_lbl.text = "Điểm: %d" % entry["score"]
        score_lbl.custom_minimum_size = Vector2(120, 0)
        score_lbl.add_theme_font_size_override("font_size", 18)
        score_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
        score_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
        score_lbl.add_theme_constant_override("shadow_offset_y", 1)
        score_lbl.add_theme_constant_override("shadow_outline_size", 2)
        row.add_child(score_lbl)
        var kills_lbl = Label.new()
        kills_lbl.text = "Kill: %d" % entry["kills"]
        kills_lbl.custom_minimum_size = Vector2(80, 0)
        kills_lbl.add_theme_font_size_override("font_size", 18)
        kills_lbl.add_theme_color_override("font_color", Color(0.85, 0.4, 0.4))
        kills_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
        kills_lbl.add_theme_constant_override("shadow_offset_y", 1)
        kills_lbl.add_theme_constant_override("shadow_outline_size", 2)
        row.add_child(kills_lbl)
        results_list.add_child(row)
    AudioManager.play_achievement()

func _on_results_restart():
    AudioManager.play_ui_click()
    get_tree().reload_current_scene()

func _on_results_menu():
    AudioManager.play_ui_click()
    get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_game_over(winner_name: String, leaderboard: Array):
    if not GameManager.is_stage_mode:
        _show_results(winner_name, leaderboard)
