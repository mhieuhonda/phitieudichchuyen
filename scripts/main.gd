extends Node2D

## Main - Scene chính (v3.5)
## v3.5: Chuyển sang Stage Mode (vượt ải).
##   - Ải 1-19: spawn AI theo stage, độ khó tăng dần
##   - Ải 20: spawn Boss (10M HP, laser, sweep rage)
##   - Khi tất cả AI/Boss bị tiêu diệt → stage clear
##   - Khi player chết quá số lần quy định → stage failed
##   - Anti kill-steal: AI chỉ tấn công player, không tấn công AI khác
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
    _spawn_screen_flash(Color(1.0, 0.05, 0.05, 0.45), 0.4)
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
    if event.is_action_pressed("menu_back"):
        get_tree().change_scene_to_file("res://scenes/menu.tscn")
