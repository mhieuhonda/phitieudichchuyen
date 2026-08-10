extends Node2D

## Main - Scene chính (v3.4)
## v3.4: Bỏ 3 skill buttons (Dash/Shield/Multishot). Chỉ còn 2 nút: Ném + Dịch.
##       Thêm hiệu ứng shockwave khi teleport + screen flash khi kill.
## - Joystick ảo + mobile controls
## - Match over handling
## - Camera shake

@onready var player: CharacterBody2D = $Player
@onready var ai_container: Node2D = $AIPlayers
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var joystick: Control = $UILayer/VirtualJoystick
@onready var mobile_controls: Control = $UILayer/MobileControls

var ai_scene: PackedScene = preload("res://scenes/ai_player.tscn")
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO

func _ready():
    GameManager.reset_game()
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
    _spawn_ai_players()

    player.player_died.connect(_on_player_died)
    player.player_respawned.connect(_on_player_respawned)
    player.teleport_performed.connect(_on_teleport_performed)

    GameManager.screen_shake_requested.connect(apply_screen_shake)
    GameManager.zone_shrank.connect(_on_zone_shrank)
    GameManager.combo_achieved.connect(_on_combo_achieved)
    GameManager.game_over.connect(_on_game_over)

    _setup_camera()

    AudioManager.play_music("game")

func _spawn_ai_players():
    for i in GameManager.num_ai_players:
        var ai = ai_scene.instantiate()
        ai.ai_id = i
        ai_container.add_child(ai)
        var rng = RandomNumberGenerator.new()
        rng.seed = i * 7 + 13
        var angle = rng.randf() * TAU
        var dist = rng.randf_range(100, 600)
        ai.global_position = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
        ai.ai_died.connect(_on_ai_died)

func _setup_camera():
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    original_camera_offset = camera.offset

func _process(delta):
    if not is_instance_valid(player):
        return
    if player.is_alive:
        camera.position = player.global_position

    if shake_timer > 0 and shake_duration > 0.001:
        shake_timer -= delta
        var intensity = shake_intensity * (shake_timer / shake_duration)
        camera.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
    else:
        shake_timer = 0.0
        camera.offset = original_camera_offset

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
    # v3.4: Screen flash đỏ khi player chết
    _spawn_screen_flash(Color(1.0, 0.05, 0.05, 0.45), 0.4)

func _on_player_respawned(p: CharacterBody2D):
    hud._add_kill_feed("Đã hồi sinh!", Color(0.2, 1.0, 0.2))
    AudioManager.play_respawn()
    AudioManager.play_success()
    # v3.4: Screen flash xanh nhạt khi hồi sinh
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
    # Animate phóng to + fade
    var tween = create_tween().set_parallel(true)
    tween.tween_method(func(r: float):
        ring.clear_points()
        for i in segments + 1:
            var angle = (i / float(segments)) * TAU
            ring.add_point(Vector2(cos(angle), sin(angle)) * r)
    , 20.0, 160.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(ring, "default_color:a", 0.0, 0.45)
    tween.chain().tween_callback(ring.queue_free)

    # Thêm tia spark phát ra từ tâm
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
    # Đợi 1 frame để flash có kích thước thật
    await get_tree().process_frame
    var tween = create_tween()
    tween.tween_property(flash, "color:a", 0.0, duration)
    tween.tween_callback(flash.queue_free)

func _on_ai_died(ai: CharacterBody2D, killer: Node2D):
    if killer == player:
        hud._add_kill_feed("Bạn đã tiêu diệt %s!" % ai.ai_name, Color(0.2, 1.0, 0.2))
        AudioManager.play_kill()
        AudioManager.play_achievement()
        # v3.4: Flash vàng nhẹ khi player giết được AI
        _spawn_screen_flash(Color(1.0, 0.85, 0.3, 0.20), 0.25)
        apply_screen_shake(4.0, 0.2)
    elif killer and killer != ai:
        var killer_name = killer.ai_name if "ai_name" in killer else "Player"
        hud._add_kill_feed("%s bị %s tiêu diệt" % [ai.ai_name, killer_name], Color(1.0, 0.5, 0.2))
    else:
        hud._add_kill_feed("%s đã bị tiêu diệt" % ai.ai_name, Color(1.0, 0.5, 0.2))

func _on_zone_shrank(new_radius: float):
    AudioManager.play_zone_shrink()
    AudioManager.play_zone_warning()
    apply_screen_shake(3.0, 0.4)

func _on_combo_achieved(combo_count: int):
    AudioManager.play_combo(combo_count)

## v3.4: Hook game_over — phát nhạc + screen flash nhẹ nếu player thắng
func _on_game_over(winner_name: String, leaderboard: Array):
    if not leaderboard.is_empty() and leaderboard[0].get("is_player", false):
        _spawn_screen_flash(Color(1.0, 0.85, 0.3, 0.35), 0.8)
    # HUD tự hiển thị results panel

func apply_screen_shake(intensity: float, duration: float):
    shake_intensity = intensity
    shake_duration = duration
    shake_timer = duration

func _input(event: InputEvent):
    if event.is_action_pressed("menu_back"):
        get_tree().change_scene_to_file("res://scenes/menu.tscn")
