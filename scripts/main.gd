extends Node2D

## Main - Scene chính (v3.5)
## v3.5: Chuyển sang Stage Mode (vượt ải).
##   - Ải 1-19: spawn AI theo stage, độ khó tăng dần
##   - Ải 20: spawn Boss (10M HP, laser, sweep rage)
##   - Khi tất cả AI/Boss bị tiêu diệt → stage clear
##   - Khi player chết quá số lần quy định → stage failed
##   - Anti kill-steal: AI chỉ tấn công player, không tấn công AI khác
## v3.8: Pause menu (P/ESC), Quick Retry (R), low-HP vignette, kill streak UI
## v3.4: Hook teleport_performed — spawn shockwave ring + screen shake
## v3.1: Joystick ảo + mobile controls, Match over handling, Camera shake

@onready var player: CharacterBody2D = $Player
@onready var ai_container: Node2D = $AIPlayers
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var joystick: Control = $UILayer/VirtualJoystick
@onready var mobile_controls: Control = $UILayer/MobileControls

var ai_scene: PackedScene = preload("res://scenes/ai_player.tscn")
var boss_scene: PackedScene = preload("res://scenes/boss.tscn")
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO

# v3.8: Pause menu state
var _pause_panel: Panel = null
var _pause_overlay: ColorRect = null
var _is_paused: bool = false

# v3.8: Low-HP vignette
var _hp_vignette: ColorRect = null
var _hp_vignette_tween: Tween = null

# v3.8: Kill streak label
var _kill_streak_label: Label = null
const KILL_STREAK_WINDOW: float = 5.0
var _kill_streak: int = 0
var _kill_streak_timer: float = 0.0

# v3.8: Hit marker (X dấu khi dart trúng AI)
var _hit_marker: Label = null
var _hit_marker_tween: Tween = null

# v3.8: Low-HP heartbeat sound timer
var _heartbeat_timer: float = 0.0
const HEARTBEAT_INTERVAL_LOW: float = 1.0   # khi HP < 20%
const HEARTBEAT_INTERVAL_MED: float = 1.5   # khi HP < 30%

# v3.8: Boss off-screen indicator (mũi tên chỉ hướng boss)
var _boss_indicator: Line2D = null
var _boss_indicator_label: Label = null

# v3.8: Minimap radar (top-right corner, 140x140)
var _minimap: Panel = null
var _minimap_draw: Control = null
const MINIMAP_SIZE: float = 140.0
const MINIMAP_MARGIN: float = 20.0

func _ready():
    # v3.5: Khởi tạo stage mode
    var target_stage = 1
    if StageManager and StageManager.stage_active:
        target_stage = StageManager.current_stage
    elif StageManager:
        target_stage = StageManager.current_stage
    GameManager.start_stage(target_stage)
    GameManager.apply_stage_ai_config()
    AIPlayer.reset_name_index()

    player.player_id = 0
    player.player_name = "Player"
    player.add_to_group("players")

    if joystick:
        player.set_joystick(joystick)

    if mobile_controls:
        mobile_controls.teleport_pressed.connect(_on_mobile_teleport)
        mobile_controls.throw_started.connect(_on_mobile_throw_start)
        mobile_controls.throw_aim_updated.connect(_on_mobile_throw_aim)
        mobile_controls.throw_ended.connect(_on_mobile_throw_end)

    hud.set_player(player)
    hud.set_stage(StageManager.current_stage)
    _spawn_enemies()

    player.player_died.connect(_on_player_died)
    player.player_respawned.connect(_on_player_respawned)
    player.teleport_performed.connect(_on_teleport_performed)

    GameManager.screen_shake_requested.connect(apply_screen_shake)
    GameManager.combo_achieved.connect(_on_combo_achieved)
    GameManager.stage_cleared.connect(_on_stage_cleared)
    GameManager.stage_failed_signal.connect(_on_stage_failed)
    GameManager.game_over.connect(_on_game_over)

    _setup_camera()

    # v3.8: Setup pause menu, vignette, kill streak label
    _setup_pause_menu()
    _setup_hp_vignette()
    _setup_kill_streak_label()
    _setup_hit_marker()
    _setup_boss_indicator()
    _setup_minimap()

    # v3.5: Music khác nhau cho ải boss
    if StageManager.is_final_stage():
        AudioManager.play_music("defeat")  # nhạc căng thẳng cho boss fight
    else:
        AudioManager.play_music("game")

func _spawn_enemies():
    if StageManager.is_final_stage():
        _spawn_boss()
    else:
        _spawn_ai_players()

func _spawn_boss():
    var boss = boss_scene.instantiate()
    ai_container.add_child(boss)
    # Spawn boss ở xa player
    var angle = randf() * TAU
    var dist = 600.0
    boss.global_position = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
    GameManager.register_boss(boss)
    hud.set_boss(boss)
    # v3.8: Hook boss phase 2 signal để show big banner
    if boss.has_signal("boss_phase2_started"):
        boss.boss_phase2_started.connect(_on_boss_phase2)

## v3.8: Hook khi boss vào phase 2 (50% HP)
func _on_boss_phase2(_boss: Node2D):
    hud._add_kill_feed("⚠ BOSS PHASE 2 — Triple Dart Spread!", Color(1.0, 0.5, 0.2))
    hud._show_big_banner("PHASE 2!", Color(1.0, 0.5, 0.2, 1.0), 2.0)
    _spawn_screen_flash(Color(1.0, 0.4, 0.2, 0.30), 0.6)
    apply_screen_shake(6.0, 0.4)

func _spawn_ai_players():
    for i in GameManager.num_ai_players:
        var ai = ai_scene.instantiate()
        ai.ai_id = i
        ai_container.add_child(ai)
        var rng = RandomNumberGenerator.new()
        rng.seed = i * 7 + 13 + StageManager.current_stage  # đổi seed mỗi stage
        var angle = rng.randf() * TAU
        var dist = rng.randf_range(200, 600)
        ai.global_position = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
        ai.ai_died.connect(_on_ai_died)

func _setup_camera():
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    original_camera_offset = camera.offset

func _process(delta):
    if not is_instance_valid(player):
        return
    if player.is_alive and not _is_paused:
        camera.position = player.global_position

    if shake_timer > 0 and shake_duration > 0.001 and not _is_paused:
        shake_timer -= delta
        var intensity = shake_intensity * (shake_timer / shake_duration)
        camera.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
    else:
        shake_timer = 0.0
        camera.offset = original_camera_offset

    # v3.8: Cập nhật low-HP vignette
    _update_hp_vignette(delta)
    # v3.8: Cập nhật kill streak timer
    _update_kill_streak(delta)
    # v3.8: Cập nhật low-HP heartbeat sound
    _update_heartbeat(delta)
    # v3.8: Cập nhật boss off-screen indicator
    _update_boss_indicator()
    # v3.8: Queue minimap redraw (Control.queue_redraw)
    if _minimap_draw and is_instance_valid(_minimap_draw):
        _minimap.visible = SettingsManager.show_minimap
        if SettingsManager.show_minimap:
            _minimap_draw.queue_redraw()

## v3.8: Setup pause menu (code-based, không cần scene riêng)
func _setup_pause_menu():
    # Overlay tối phía sau panel
    _pause_overlay = ColorRect.new()
    _pause_overlay.color = Color(0, 0, 0, 0)
    _pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _pause_overlay.z_index = 200
    hud.add_child(_pause_overlay)

    # Panel chính
    _pause_panel = Panel.new()
    _pause_panel.set_anchors_preset(Control.PRESET_CENTER)
    _pause_panel.offset_left = -180
    _pause_panel.offset_right = 180
    _pause_panel.offset_top = -200
    _pause_panel.offset_bottom = 200
    _pause_panel.z_index = 201
    _pause_panel.visible = false
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.04, 0.04, 0.08, 0.97)
    style.border_color = Color(0.6, 0.5, 0.85, 0.6)
    style.border_width_top = 3
    style.border_width_bottom = 3
    style.border_width_left = 3
    style.border_width_right = 3
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    style.shadow_color = Color(0, 0, 0, 0.6)
    style.shadow_size = 20
    _pause_panel.add_theme_stylebox_override("panel", style)
    hud.add_child(_pause_panel)

    # Title
    var title = Label.new()
    title.text = "⏸ TẠM DỪNG"
    title.set_anchors_preset(Control.PRESET_CENTER_TOP)
    title.offset_left = -150
    title.offset_right = 150
    title.offset_top = 18
    title.offset_bottom = 60
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
    title.add_theme_color_override("font_shadow_color", Color(0.4, 0.3, 0, 0.7))
    title.add_theme_constant_override("shadow_offset_y", 2)
    title.add_theme_constant_override("shadow_outline_size", 4)
    _pause_panel.add_child(title)

    # Stage info label
    var info = Label.new()
    info.name = "StageInfoLabel"
    info.set_anchors_preset(Control.PRESET_CENTER_TOP)
    info.offset_left = -150
    info.offset_right = 150
    info.offset_top = 68
    info.offset_bottom = 90
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 13)
    info.add_theme_color_override("font_color", Color(0.75, 0.78, 0.88))
    _pause_panel.add_child(info)

    # VBox cho buttons
    var vbox = VBoxContainer.new()
    vbox.set_anchors_preset(Control.PRESET_CENTER)
    vbox.offset_left = -130
    vbox.offset_right = 130
    vbox.offset_top = 90
    vbox.offset_bottom = 360
    vbox.add_theme_constant_override("separation", 12)
    _pause_panel.add_child(vbox)

    var btn_resume = _create_pause_button("▶ TIẾP TỤC", Color(0.04, 0.18, 0.10, 0.9), Color(0.3, 1.0, 0.5))
    btn_resume.pressed.connect(_pause_resume)
    vbox.add_child(btn_resume)

    var btn_retry = _create_pause_button("↻ CHƠI LẠI ẢI", Color(0.14, 0.10, 0.04, 0.9), Color(1.0, 0.7, 0.3))
    btn_retry.pressed.connect(_pause_retry)
    vbox.add_child(btn_retry)

    var btn_settings = _create_pause_button("⚙ CÀI ĐẶT", Color(0.08, 0.06, 0.14, 0.9), Color(0.7, 0.6, 1.0))
    btn_settings.pressed.connect(_pause_settings)
    vbox.add_child(btn_settings)

    var btn_menu = _create_pause_button("✕ VỀ MENU", Color(0.14, 0.04, 0.04, 0.9), Color(1.0, 0.4, 0.3))
    btn_menu.pressed.connect(_pause_to_menu)
    vbox.add_child(btn_menu)

    # Hint footer
    var hint = Label.new()
    hint.text = "ESC/P: tiếp tục  •  R: chơi lại"
    hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    hint.offset_left = -150
    hint.offset_right = 150
    hint.offset_top = 360
    hint.offset_bottom = 385
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 11)
    hint.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68))
    _pause_panel.add_child(hint)

func _create_pause_button(text: String, bg: Color, accent: Color) -> Button:
    var btn = Button.new()
    btn.text = text
    btn.custom_minimum_size = Vector2(260, 44)
    var style_n = StyleBoxFlat.new()
    style_n.bg_color = bg
    style_n.corner_radius_top_left = 10
    style_n.corner_radius_top_right = 10
    style_n.corner_radius_bottom_left = 10
    style_n.corner_radius_bottom_right = 10
    style_n.border_color = Color(accent.r, accent.g, accent.b, 0.4)
    style_n.border_width_top = 2
    style_n.border_width_bottom = 2
    style_n.border_width_left = 2
    style_n.border_width_right = 2
    style_n.content_margin_top = 10
    style_n.content_margin_bottom = 10
    var style_h = style_n.duplicate()
    style_h.bg_color = Color(bg.r + 0.05, bg.g + 0.05, bg.b + 0.06, bg.a)
    style_h.border_color = Color(accent.r, accent.g, accent.b, 0.85)
    var style_p = style_n.duplicate()
    style_p.bg_color = Color(bg.r * 0.6, bg.g * 0.6, bg.b * 0.6, bg.a)
    btn.add_theme_stylebox_override("normal", style_n)
    btn.add_theme_stylebox_override("hover", style_h)
    btn.add_theme_stylebox_override("pressed", style_p)
    btn.add_theme_stylebox_override("focus", style_n)
    btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())
    return btn

func _pause_show():
    if _is_paused:
        return
    # Không cho pause khi stage đã kết thúc
    if GameManager.stage_failed or GameManager.stage_cleared_flag:
        return
    _is_paused = true
    get_tree().paused = true
    _pause_panel.visible = true
    # Update stage info
    var info = _pause_panel.get_node_or_null("StageInfoLabel")
    if info:
        info.text = "Ải %d / %d  •  ⏱ %s" % [
            StageManager.current_stage,
            StageManager.TOTAL_STAGES,
            StageManager.format_time(StageManager.get_elapsed_stage_time())
        ]
    # Fade in overlay
    _pause_overlay.color = Color(0, 0, 0, 0)
    var tween = create_tween()
    tween.tween_property(_pause_overlay, "color:a", 0.65, 0.2).set_trans(Tween.TRANS_QUAD)
    # Scale-in panel
    _pause_panel.scale = Vector2(0.85, 0.85)
    _pause_panel.modulate.a = 0.0
    var tween2 = create_tween().set_parallel(true)
    tween2.tween_property(_pause_panel, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween2.tween_property(_pause_panel, "modulate:a", 1.0, 0.15)
    AudioManager.play_ui_click()

func _pause_resume():
    if not _is_paused:
        return
    _is_paused = false
    get_tree().paused = false
    var tween = create_tween().set_parallel(true)
    tween.tween_property(_pause_overlay, "color:a", 0.0, 0.15)
    tween.tween_property(_pause_panel, "scale", Vector2(0.92, 0.92), 0.12)
    tween.tween_property(_pause_panel, "modulate:a", 0.0, 0.15)
    tween.chain().tween_callback(func():
        if is_instance_valid(_pause_panel):
            _pause_panel.visible = false)
    AudioManager.play_ui_click()

func _pause_retry():
    _is_paused = false
    get_tree().paused = false
    AudioManager.play_ui_click()
    get_tree().reload_current_scene()

func _pause_settings():
    _is_paused = false
    get_tree().paused = false
    AudioManager.play_ui_click()
    get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _pause_to_menu():
    _is_paused = false
    get_tree().paused = false
    AudioManager.play_cancel()
    get_tree().change_scene_to_file("res://scenes/menu.tscn")

## v3.8: Setup low-HP vignette (red border pulse when HP < 30%)
func _setup_hp_vignette():
    _hp_vignette = ColorRect.new()
    _hp_vignette.color = Color(0.6, 0.05, 0.05, 0.0)
    _hp_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
    _hp_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hp_vignette.z_index = 95
    hud.add_child(_hp_vignette)

func _update_hp_vignette(delta):
    if not _hp_vignette or not is_instance_valid(player):
        return
    # Respect settings toggle
    if not SettingsManager.show_low_hp_vignette:
        if _hp_vignette.color.a > 0.01:
            _hp_vignette.color = Color(0.6, 0.05, 0.05, 0.0)
        return
    var hp_ratio = GameManager.player_hp / GameManager.player_max_hp if GameManager.player_max_hp > 0 else 1.0
    var target_alpha = 0.0
    if hp_ratio < 0.30 and player.is_alive and GameManager.game_active:
        # Pulse intensity based on how low HP is
        var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 200.0)
        var danger_intensity = (0.30 - hp_ratio) / 0.30  # 0..1
        target_alpha = 0.20 + 0.25 * danger_intensity * pulse
    var cur_alpha = _hp_vignette.color.a
    var new_alpha = lerp(cur_alpha, target_alpha, 0.15)
    _hp_vignette.color = Color(0.6, 0.05, 0.05, new_alpha)

## v3.8: Setup kill streak label (top-right)
func _setup_kill_streak_label():
    _kill_streak_label = Label.new()
    _kill_streak_label.text = ""
    _kill_streak_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    _kill_streak_label.offset_left = -260
    _kill_streak_label.offset_right = -20
    _kill_streak_label.offset_top = 60
    _kill_streak_label.offset_bottom = 100
    _kill_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _kill_streak_label.add_theme_font_size_override("font_size", 22)
    _kill_streak_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
    _kill_streak_label.add_theme_constant_override("shadow_offset_y", 2)
    _kill_streak_label.add_theme_constant_override("shadow_outline_size", 3)
    _kill_streak_label.visible = false
    hud.add_child(_kill_streak_label)

func _update_kill_streak(delta):
    if _kill_streak > 0:
        _kill_streak_timer -= delta
        if _kill_streak_timer <= 0:
            _kill_streak = 0
            if _kill_streak_label:
                _kill_streak_label.visible = false
        else:
            _update_kill_streak_label()

func _update_kill_streak_label():
    if not _kill_streak_label:
        return
    # Respect settings toggle
    if not SettingsManager.show_kill_streak:
        _kill_streak_label.visible = false
        return
    if _kill_streak < 2:
        _kill_streak_label.visible = false
        return
    var text = ""
    var color = Color(1.0, 0.85, 0.2)
    match _kill_streak:
        2:
            text = "⚔⚔ DOUBLE KILL!"
            color = Color(0.4, 1.0, 0.5)
        3:
            text = "⚔⚔⚔ TRIPLE KILL!"
            color = Color(1.0, 0.7, 0.2)
        4:
            text = "⚔⚔⚔⚔ QUADRA KILL!"
            color = Color(1.0, 0.5, 0.3)
        5:
            text = "⚔⚔⚔⚔⚔ PENTA KILL!"
            color = Color(1.0, 0.4, 0.7)
        6, 7, 8:
            text = "🔥 KILLING SPREE x%d!" % _kill_streak
            color = Color(1.0, 0.4, 0.5)
        9, 10:
            text = "💀 UNSTOPPABLE x%d!" % _kill_streak
            color = Color(1.0, 0.3, 0.5)
        _:
            text = "👑 GODLIKE x%d!" % _kill_streak
            color = Color(1.0, 0.2, 0.8)
    _kill_streak_label.text = text
    _kill_streak_label.add_theme_color_override("font_color", color)
    _kill_streak_label.visible = true

## v3.8: Hook HUD.register_player_kill để track kill streak ở main.gd
## (gọi từ HUD._on_player_died path)
func register_player_kill_main():
    _kill_streak += 1
    _kill_streak_timer = KILL_STREAK_WINDOW
    _update_kill_streak_label()
    if _kill_streak >= 3:
        AudioManager.play_combo(min(_kill_streak, 5))

## v3.8: Setup hit marker (x dấu khi dart trúng AI/boss)
func _setup_hit_marker():
    _hit_marker = Label.new()
    _hit_marker.text = "✕"
    _hit_marker.set_anchors_preset(Control.PRESET_CENTER)
    _hit_marker.offset_left = -30
    _hit_marker.offset_right = 30
    _hit_marker.offset_top = -50
    _hit_marker.offset_bottom = -20
    _hit_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hit_marker.add_theme_font_size_override("font_size", 36)
    _hit_marker.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 0.95))
    _hit_marker.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
    _hit_marker.add_theme_constant_override("shadow_offset_y", 2)
    _hit_marker.add_theme_constant_override("shadow_outline_size", 3)
    _hit_marker.visible = false
    hud.add_child(_hit_marker)

## v3.8: Hiển thị hit marker ngắn (0.2s) khi dart trúng AI
func show_hit_marker(is_crit: bool = false):
    # Respect settings toggle
    if not SettingsManager.show_hit_markers:
        return
    if not _hit_marker:
        return
    if _hit_marker_tween and is_instance_valid(_hit_marker_tween):
        _hit_marker_tween.kill()
    _hit_marker.text = "✕" if not is_crit else "✕ CRIT!"
    _hit_marker.add_theme_color_override("font_color",
        Color(1.0, 0.3, 0.3, 0.95) if is_crit else Color(1.0, 0.85, 0.2, 0.95))
    _hit_marker.scale = Vector2(1.4, 1.4)
    _hit_marker.modulate.a = 1.0
    _hit_marker.visible = true
    _hit_marker_tween = create_tween()
    _hit_marker_tween.set_parallel(true)
    _hit_marker_tween.tween_property(_hit_marker, "scale", Vector2(0.9, 0.9), 0.2).set_trans(Tween.TRANS_QUAD)
    _hit_marker_tween.tween_property(_hit_marker, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD)
    _hit_marker_tween.chain().tween_callback(func():
        if is_instance_valid(_hit_marker):
            _hit_marker.visible = false)

func _on_mobile_teleport():
    player._teleport_to_dart()

func _on_mobile_throw_start():
    player.start_aim_mobile()

func _on_mobile_throw_aim(direction: Vector2, power: float):
    player.update_aim_mobile(direction, power)

func _on_mobile_throw_end(direction: Vector2, power: float):
    player.throw_dart_mobile(direction, power)

func _on_player_died(p: CharacterBody2D):
    var killer = p.get_killer_name()
    if killer != "":
        hud._add_kill_feed("Bạn bị %s tiêu diệt!" % killer, Color(1.0, 0.3, 0.3))
    else:
        hud._add_kill_feed("Bạn đã bị tiêu diệt!", Color(1.0, 0.2, 0.2))
    AudioManager.play_warning()
    _spawn_screen_flash(Color(1.0, 0.05, 0.05, 0.45), 0.4)
    # v3.8: Reset kill streak khi chết
    _kill_streak = 0
    _kill_streak_timer = 0.0
    if _kill_streak_label:
        _kill_streak_label.visible = false
    # v3.6: Đã bỏ gọi GameManager.on_player_died_in_stage() tại đây để fix
    # bug double-count mạng — player._die() đã gọi nó trước khi emit signal.
    # Trước đây player_deaths_this_stage bị +2 mỗi lần chết (1 từ _die(),
    # 1 từ đây) → player thất bại sớm hơn số mạng quy định.
    # Stage fail được phát signal qua GameManager.stage_failed_signal và
    # HUD tự hiển thị panel tương ứng.

func _on_player_respawned(p: CharacterBody2D):
    hud._add_kill_feed("Đã hồi sinh!", Color(0.2, 1.0, 0.2))
    AudioManager.play_respawn()
    AudioManager.play_success()
    _spawn_screen_flash(Color(0.2, 1.0, 0.4, 0.30), 0.35)

## v3.4: Hook teleport_performed — spawn shockwave ring + screen shake
func _on_teleport_performed(p: CharacterBody2D, to_position: Vector2):
    _spawn_teleport_shockwave(to_position)
    apply_screen_shake(6.0, 0.25)
    AudioManager.play_teleport()

## v3.4: Spawn shockwave ring (vòng tròn phóng to + fade) tại điểm dịch chuyển
func _spawn_teleport_shockwave(at_pos: Vector2):
    var ring = Line2D.new()
    ring.width = 6.0
    ring.default_color = Color(0.3, 1.0, 0.5, 0.9)
    ring.z_index = 50
    var segments = 48
    var radius = 20.0
    for i in segments + 1:
        var angle = (i / float(segments)) * TAU
        ring.add_point(Vector2(cos(angle), sin(angle)) * radius)
    add_child(ring)
    ring.global_position = at_pos
    var tween = create_tween().set_parallel(true)
    tween.tween_method(func(r: float):
        ring.clear_points()
        for i in segments + 1:
            var angle = (i / float(segments)) * TAU
            ring.add_point(Vector2(cos(angle), sin(angle)) * r)
    , 20.0, 160.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(ring, "default_color:a", 0.0, 0.45)
    tween.chain().tween_callback(ring.queue_free)

    if SettingsManager.get_particle_multiplier() > 0:
        var spark = CPUParticles2D.new()
        spark.emitting = true
        spark.one_shot = true
        spark.explosiveness = 0.9
        spark.amount = max(8, int(20 * SettingsManager.get_particle_multiplier()))
        spark.lifetime = 0.45
        spark.direction = Vector2(0, 0)
        spark.spread = 180.0
        spark.initial_velocity_min = 120
        spark.initial_velocity_max = 280
        spark.gravity = Vector2.ZERO
        spark.scale_amount_min = 2
        spark.scale_amount_max = 5
        spark.color = Color(0.3, 1.0, 0.5, 0.85)
        add_child(spark)
        spark.global_position = at_pos
        get_tree().create_timer(0.8).timeout.connect(spark.queue_free)

## v3.4: Screen flash overlay (ColorRect full màn hình, fade out nhanh)
func _spawn_screen_flash(color: Color, duration: float):
    var flash = ColorRect.new()
    flash.color = color
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flash.z_index = 100
    flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(flash)
    await get_tree().process_frame
    var tween = create_tween()
    tween.tween_property(flash, "color:a", 0.0, duration)
    tween.tween_callback(flash.queue_free)

func _on_ai_died(ai: CharacterBody2D, killer: Node2D):
    # v3.5: Stage mode — notify GameManager
    GameManager.on_ai_killed_in_stage()
    if killer == player:
        hud._add_kill_feed("Bạn đã tiêu diệt %s!" % ai.ai_name, Color(0.2, 1.0, 0.2))
        AudioManager.play_kill()
        AudioManager.play_achievement()
        _spawn_screen_flash(Color(1.0, 0.85, 0.3, 0.20), 0.25)
        apply_screen_shake(4.0, 0.2)
        # v3.8: Tăng kill streak
        _kill_streak += 1
        _kill_streak_timer = KILL_STREAK_WINDOW
        _update_kill_streak_label()
    else:
        hud._add_kill_feed("%s đã bị tiêu diệt" % ai.ai_name, Color(1.0, 0.5, 0.2))

func _on_combo_achieved(combo_count: int):
    AudioManager.play_combo(combo_count)

## v3.5: Stage clear handler
func _on_stage_cleared(stage: int):
    _spawn_screen_flash(Color(1.0, 0.85, 0.3, 0.35), 0.8)
    apply_screen_shake(8.0, 0.5)
    AudioManager.play_achievement()
    AudioManager.play_variation("success", 2.0, 1.0)
    AudioManager.play_variation("drum_crash", 3.0, 1.0)
    # HUD sẽ hiển thị stage clear panel

## v3.5: Stage fail handler
func _on_stage_failed(stage: int):
    _spawn_screen_flash(Color(1.0, 0.05, 0.05, 0.55), 1.0)
    apply_screen_shake(12.0, 0.8)
    AudioManager.play_warning()
    AudioManager.play_variation("error", 2.0, 0.85)
    # HUD sẽ hiển thị stage fail panel

## v3.4: Hook game_over — phát nhạc + screen flash nhẹ nếu player thắng
func _on_game_over(winner_name: String, leaderboard: Array):
    if not leaderboard.is_empty() and leaderboard[0].get("is_player", false):
        _spawn_screen_flash(Color(1.0, 0.85, 0.3, 0.35), 0.8)

func apply_screen_shake(intensity: float, duration: float):
    shake_intensity = intensity
    shake_duration = duration
    shake_timer = duration

func _input(event: InputEvent):
    # v3.8: Pause menu — ESC hoặc P
    if event.is_action_pressed("pause") or event.is_action_pressed("menu_back"):
        if _is_paused:
            _pause_resume()
        else:
            _pause_show()
        get_viewport().set_input_as_handled()
        return
    # v3.8: Quick Retry với phím R khi đang pause
    if event.is_action_pressed("restart") and _is_paused:
        _pause_retry()
        get_viewport().set_input_as_handled()
        return

## v3.8: Hook player.dart_thrown để không hiện hit marker lúc ném (chỉ khi trúng)
## Hit marker được trigger từ player.gd khi _on_dart_hit_player
func _on_dart_hit_ai(amount: float, is_crit: bool):
    show_hit_marker(is_crit)

## v3.8: Phát heartbeat sound khi HP < 30%. Càng thấp thì beat càng nhanh.
func _update_heartbeat(delta: float):
    if not is_instance_valid(player) or not player.is_alive:
        _heartbeat_timer = 0.0
        return
    var hp_ratio = GameManager.player_hp / GameManager.player_max_hp if GameManager.player_max_hp > 0 else 1.0
    if hp_ratio >= 0.30:
        _heartbeat_timer = 0.0
        return
    var interval = HEARTBEAT_INTERVAL_LOW if hp_ratio < 0.20 else HEARTBEAT_INTERVAL_MED
    _heartbeat_timer += delta
    if _heartbeat_timer >= interval:
        _heartbeat_timer = 0.0
        AudioManager.play_variation("heartbeat", -2.0, 1.0 if hp_ratio > 0.20 else 1.15)

## v3.8: Setup & update boss off-screen indicator
## Nếu boss ở ngoài tầm nhìn camera, vẽ mũi tên đỏ ở rìa màn hình chỉ hướng boss.
func _setup_boss_indicator():
    # Line2D làm mũi tên (tam giác) ở rìa màn hình
    _boss_indicator = Line2D.new()
    _boss_indicator.width = 4.0
    _boss_indicator.default_color = Color(1.0, 0.3, 0.2, 0.9)
    _boss_indicator.z_index = 90
    _boss_indicator.visible = false
    hud.add_child(_boss_indicator)
    # Label khoảng cách
    _boss_indicator_label = Label.new()
    _boss_indicator_label.text = ""
    _boss_indicator_label.add_theme_font_size_override("font_size", 12)
    _boss_indicator_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3, 0.95))
    _boss_indicator_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
    _boss_indicator_label.add_theme_constant_override("shadow_offset_y", 1)
    _boss_indicator_label.add_theme_constant_override("shadow_outline_size", 2)
    _boss_indicator_label.visible = false
    hud.add_child(_boss_indicator_label)

func _update_boss_indicator():
    # Respect settings toggle
    if not SettingsManager.show_boss_offscreen_arrow:
        if _boss_indicator:
            _boss_indicator.visible = false
        if _boss_indicator_label:
            _boss_indicator_label.visible = false
        return
    if not StageManager.is_final_stage():
        if _boss_indicator:
            _boss_indicator.visible = false
        if _boss_indicator_label:
            _boss_indicator_label.visible = false
        return
    if not _boss_indicator:
        _setup_boss_indicator()
    if not is_instance_valid(GameManager.stage_boss_ref) or not GameManager.stage_boss_ref.is_alive:
        if _boss_indicator:
            _boss_indicator.visible = false
        if _boss_indicator_label:
            _boss_indicator_label.visible = false
        return
    # Lấy vị trí boss & player trên screen
    var boss_pos = GameManager.stage_boss_ref.global_position
    var player_pos = player.global_position
    var cam_pos = camera.get_screen_center_position()
    var viewport_size = get_viewport_rect().size
    var half_view = viewport_size * 0.5
    # Boss position relative to camera center
    var rel = boss_pos - cam_pos
    # Check if boss is on-screen
    var on_screen = abs(rel.x) < half_view.x - 40 and abs(rel.y) < half_view.y - 40
    if on_screen:
        if _boss_indicator:
            _boss_indicator.visible = false
        if _boss_indicator_label:
            _boss_indicator_label.visible = false
        return
    # Tính hướng từ player tới boss (camera center = player position roughly)
    var dir = (boss_pos - player_pos).normalized()
    if dir == Vector2.ZERO:
        dir = Vector2.RIGHT
    # Clamp vị trí mũi tên vào rìa màn hình (camera center ± half_view * 0.85)
    var edge_x = half_view.x * 0.88
    var edge_y = half_view.y * 0.88
    # Tìm điểm trên rìa viewport theo hướng dir
    var t_x = edge_x / abs(dir.x) if abs(dir.x) > 0.001 else INF
    var t_y = edge_y / abs(dir.y) if abs(dir.y) > 0.001 else INF
    var t = min(t_x, t_y)
    # arrow_pos relative to camera center → convert to viewport coords
    # (CanvasLayer draws at viewport origin = top-left)
    var arrow_pos_viewport = half_view + dir * t
    # Vẽ mũi tên tam giác (3 điểm) tại arrow_pos_viewport, hướng dir
    _boss_indicator.clear_points()
    var arrow_size = 18.0
    var tip = arrow_pos_viewport + dir * arrow_size
    var back = arrow_pos_viewport - dir * arrow_size * 0.5
    var perp = Vector2(-dir.y, dir.x) * arrow_size * 0.7
    _boss_indicator.add_point(tip)
    _boss_indicator.add_point(back + perp)
    _boss_indicator.add_point(back - perp)
    _boss_indicator.add_point(tip)  # close
    _boss_indicator.visible = true
    # Update label khoảng cách
    var dist = int(player_pos.distance_to(boss_pos))
    if _boss_indicator_label:
        _boss_indicator_label.text = "BOSS %dpx" % dist
        _boss_indicator_label.position = arrow_pos_viewport + Vector2(-30, -25)
        _boss_indicator_label.visible = true

## v3.8: Setup minimap radar — top-right corner, 140x140, semi-transparent.
## Hiển thị player (cyan), AI (red), boss (large red), darts (yellow).
func _setup_minimap():
    _minimap = Panel.new()
    _minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    _minimap.offset_left = -MINIMAP_SIZE - MINIMAP_MARGIN
    _minimap.offset_right = -MINIMAP_MARGIN
    _minimap.offset_top = MINIMAP_MARGIN + 50  # dưới top bar
    _minimap.offset_bottom = MINIMAP_MARGIN + 50 + MINIMAP_SIZE
    _minimap.z_index = 80
    _minimap.modulate.a = 0.85
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.04, 0.06, 0.10, 0.85)
    style.border_color = Color(0.4, 0.6, 1.0, 0.5)
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.border_width_left = 2
    style.border_width_right = 2
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    _minimap.add_theme_stylebox_override("panel", style)
    hud.add_child(_minimap)
    # Custom draw control
    _minimap_draw = Control.new()
    _minimap_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
    _minimap_draw.draw.connect(_draw_minimap)
    _minimap.add_child(_minimap_draw)

## v3.8: Draw minimap content — player/AI/boss/darts as colored dots
func _draw_minimap():
    if not is_instance_valid(player):
        return
    var map_w = GameManager.map_size.x
    var map_h = GameManager.map_size.y
    if map_w <= 0 or map_h <= 0:
        return
    # Scale: map_size → MINIMAP_SIZE
    var sx = MINIMAP_SIZE / map_w
    var sy = MINIMAP_SIZE / map_h
    # Draw zone circle
    var zone_center_minimap = GameManager.zone_center * Vector2(sx, sy)
    var zone_radius_minimap = GameManager.zone_radius * (sx + sy) * 0.5
    _minimap_draw.draw_arc(zone_center_minimap, zone_radius_minimap, 0, TAU, 48, Color(0.3, 0.8, 0.5, 0.4), 1.0)
    # Draw AI as red dots
    for ai in get_tree().get_nodes_in_group("ai_players"):
        if not is_instance_valid(ai) or not ("is_alive" in ai) or not ai.is_alive:
            continue
        var ai_pos_minimap = ai.global_position * Vector2(sx, sy)
        var is_boss = ai.has_method("is_boss") and ai.is_boss()
        if is_boss:
            # Boss = larger orange dot
            _minimap_draw.draw_circle(ai_pos_minimap, 5.0, Color(1.0, 0.4, 0.1, 0.95))
            _minimap_draw.draw_arc(ai_pos_minimap, 7.0, 0, TAU, 24, Color(1.0, 0.6, 0.2, 0.5), 1.5)
        else:
            _minimap_draw.draw_circle(ai_pos_minimap, 2.5, Color(1.0, 0.3, 0.3, 0.9))
    # Draw darts as yellow dots (only player's)
    for dart in player.all_darts:
        if not is_instance_valid(dart):
            continue
        var dart_pos_minimap = dart.global_position * Vector2(sx, sy)
        _minimap_draw.draw_circle(dart_pos_minimap, 1.5, Color(1.0, 0.9, 0.3, 0.85))
    # Draw player as cyan dot with white outline
    var player_pos_minimap = player.global_position * Vector2(sx, sy)
    _minimap_draw.draw_circle(player_pos_minimap, 4.0, Color(0.3, 1.0, 1.0, 0.95))
    _minimap_draw.draw_arc(player_pos_minimap, 5.5, 0, TAU, 24, Color(1.0, 1.0, 1.0, 0.7), 1.5)
