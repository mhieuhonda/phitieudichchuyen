extends CanvasLayer

## HUD - Giao diện người chơi
## Hiển thị điểm, máu, số phi tiêu, combo, vòng bo, mini-map, FPS, device info

@onready var score_label: Label = $ScoreLabel
@onready var hp_bar: ProgressBar = $HpBar
@onready var dart_count_label: Label = $DartCountLabel
@onready var zone_warning: Panel = $ZoneWarning
@onready var zone_timer_label: Label = $ZoneTimerLabel
@onready var kill_feed: VBoxContainer = $KillFeed
@onready var alive_label: Label = $AliveLabel
@onready var controls_label: RichTextLabel = $ControlsLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var restart_label: Label = $GameOverPanel/RestartLabel
@onready var combo_label: Label = $ComboLabel
@onready var size_label: Label = $SizeLabel
@onready var time_label: Label = $TimeLabel
@onready var mid_flight_hint: Label = $MidFlightHint
@onready var fps_label: Label = $FPSLabel
@onready var device_label: Label = $DeviceLabel
@onready var quality_notice: Label = $QualityNotice

var player: CharacterBody2D = null
var zone_shrink_timer: float = 0.0
var combo_display_timer: float = 0.0
var fps_update_timer: float = 0.0
var quality_notice_timer: float = 0.0

func _ready():
        GameManager.player_score_changed.connect(_on_score_changed)
        GameManager.player_size_changed.connect(_on_size_changed)
        GameManager.zone_shrank.connect(_on_zone_shrank)
        GameManager.combo_achieved.connect(_on_combo_achieved)
        GameManager.screen_shake_requested.connect(_on_screen_shake)
        
        zone_shrink_timer = GameManager.zone_shrink_interval
        
        controls_label.text = "[b]ĐIỀU KHIỂN[/b]\n"
        controls_label.text += "PC: WASD = Di chuyển | Chuột phải = Ngắm & Ném\n"
        controls_label.text += "PC: Space = Dịch chuyển | Esc = Menu\n"
        controls_label.text += "[color=cyan]Mobile:[/color] Joystick = Di chuyển | Nút = Bắn/Dịch chuyển\n"
        controls_label.text += "[color=cyan]Mobile:[/color] Giữ nút bắn = Kẻ đỏ ngắm, kéo xoay hướng, thả = bắn"
        
        game_over_panel.visible = false
        zone_warning.visible = false
        combo_label.visible = false
        mid_flight_hint.visible = false
        
        # FPS counter
        fps_label.visible = SettingsManager.show_fps
        
        # Device info label
        _show_device_info()
        
        # Show quality auto-detect notice
        if SettingsManager.was_auto_detected:
                quality_notice.visible = true
                quality_notice.text = "Tự động chọn đồ họa: %s" % SettingsManager.get_quality_name()
                quality_notice_timer = 4.0

func _show_device_info():
        if device_label:
                device_label.visible = SettingsManager.show_fps
                device_label.text = "%s | %s" % [SettingsManager.get_device_tier_name(), SettingsManager.get_quality_name()]

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
        
        # Cập nhật số phi tiêu
        var dart_info = _get_dart_info()
        dart_count_label.text = dart_info
        mid_flight_hint.visible = _has_flying_darts()
        
        # Cập nhật đếm ngược vòng bo
        zone_shrink_timer -= delta
        if zone_shrink_timer <= 0:
                GameManager.shrink_zone()
                zone_shrink_timer = GameManager.zone_shrink_interval
        zone_timer_label.text = "Vòng bo: %.0fs" % zone_shrink_timer
        
        # Cảnh báo ngoài vòng bo
        if not GameManager.is_in_zone(player.global_position):
                zone_warning.visible = true
        else:
                zone_warning.visible = false
        
        # Cập nhật số người còn sống
        var alive_count = get_tree().get_nodes_in_group("ai_players").filter(func(a): return a.is_alive).size()
        alive_count += 1 if player.is_alive else 0
        alive_label.text = "Còn sống: %d" % alive_count
        
        # Cập nhật kích thước
        size_label.text = "Kích thước: %.0f" % GameManager.player_size
        
        # Cập nhật thời gian
        time_label.text = GameManager.get_game_time_str()
        
        # Combo display timer
        if combo_label.visible:
                combo_display_timer -= delta
                if combo_display_timer <= 0:
                        combo_label.visible = false
        
        # FPS counter - cập nhật mỗi 0.5s
        fps_label.visible = SettingsManager.show_fps
        device_label.visible = SettingsManager.show_fps
        if SettingsManager.show_fps:
                fps_update_timer -= delta
                if fps_update_timer <= 0:
                        fps_update_timer = 0.5
                        fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
        
        # Quality notice tự ẩn
        if quality_notice.visible:
                quality_notice_timer -= delta
                if quality_notice_timer <= 0:
                        quality_notice.visible = false

func _get_dart_info() -> String:
        var flying = 0
        var stuck = 0
        for dart in player.all_darts:
                if is_instance_valid(dart):
                        if dart.is_flying():
                                flying += 1
                        elif dart.is_stuck():
                                stuck += 1
        var max_darts = GameManager.max_darts_per_player + player.dart_bonus
        var bonus_str = " +%d" % player.dart_bonus if player.dart_bonus > 0 else ""
        if flying > 0:
                return "Phi tiêu: %d bay + %d cắm / %d%s" % [flying, stuck, max_darts, bonus_str]
        elif stuck > 0:
                return "Phi tiêu: %d cắm / %d%s" % [stuck, max_darts, bonus_str]
        else:
                return "Phi tiêu: 0/%d%s (Nhắm để ném!)" % [max_darts, bonus_str]

func _has_flying_darts() -> bool:
        for dart in player.all_darts:
                if is_instance_valid(dart) and dart.is_flying():
                        return true
        return false

func _on_score_changed(new_score: int):
        score_label.text = "Điểm: %d" % new_score

func _on_size_changed(new_size: float):
        size_label.text = "Kích thước: %.0f" % new_size

func _on_zone_shrank(new_radius: float):
        _add_kill_feed("Vòng bo thu nhỏ!", Color(1.0, 0.5, 0.0))

func _on_combo_achieved(combo_count: int):
        combo_label.text = "COMBO x%d!" % combo_count
        combo_label.visible = true
        combo_display_timer = 2.0
        _add_kill_feed("COMBO x%d! (x%.1f điểm)" % [combo_count, 1.0 + (combo_count * 0.5)], Color(1.0, 0.8, 0.0))

func _on_screen_shake(intensity: float, duration: float):
        # Screen shake effect trên HUD
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
        restart_label.text = "Tự hồi sinh sau %.0fs..." % GameManager.respawn_time
        _add_kill_feed("Bạn đã bị tiêu diệt!", Color(1.0, 0.2, 0.2))

func _on_player_respawned(p: CharacterBody2D):
        game_over_panel.visible = false
        _add_kill_feed("Đã hồi sinh!", Color(0.2, 1.0, 0.2))

func _on_dart_thrown(dart: Node2D):
        mid_flight_hint.visible = true
        # Ẩn hint sau 1.5s nếu không có phi tiêu đang bay
        get_tree().create_timer(1.5).timeout.connect(func():
                if not _has_flying_darts():
                        mid_flight_hint.visible = false
        )

func _on_teleport_performed(player: CharacterBody2D, to_position: Vector2):
        # Hiển thị hint khi dịch chuyển giữa chừng
        # (sẽ có hiệu ứng riêng)
        pass

func _input(event: InputEvent):
        # Restart action không còn dùng (player tự respawn)
        pass

func _add_kill_feed(text: String, color: Color = Color.WHITE):
        var label = Label.new()
        label.text = text
        label.add_theme_color_override("font_color", color)
        kill_feed.add_child(label)
        get_tree().create_timer(3.0).timeout.connect(label.queue_free)

func _restart_game():
        get_tree().reload_current_scene()
