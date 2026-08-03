extends Node2D

## Main - Scene chính với joystick ảo + mobile controls

@onready var player: CharacterBody2D = $Player
@onready var ai_container: Node2D = $AIPlayers
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var joystick: Control = $VirtualJoystick
@onready var mobile_controls: Control = $MobileControls

var ai_scene: PackedScene = preload("res://scenes/ai_player.tscn")
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO

func _ready():
        GameManager.reset_game()
        # Reset static AI name index để tên bot reset đúng mỗi game
        AIPlayer.reset_name_index()

        player.player_id = 0
        player.player_name = "Player"
        player.add_to_group("players")

        # Connect joystick to player
        if joystick:
                player.set_joystick(joystick)

        # Connect mobile controls
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

        # Kết nối signal screen shake từ GameManager đến camera
        GameManager.screen_shake_requested.connect(apply_screen_shake)
        # Kết nối signal zone_shrank để play sound
        GameManager.zone_shrank.connect(_on_zone_shrank)
        # Kết nối signal combo_achieved để play sound
        GameManager.combo_achieved.connect(_on_combo_achieved)

        _setup_camera()

        # Phát nhạc game
        AudioManager.play_music("game")

func _spawn_ai_players():
        # Reset AI name index
        # Can't access static var directly, so we just instantiate
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
        if player.is_alive:
                camera.position = player.global_position
        
        if shake_timer > 0:
                shake_timer -= delta
                var intensity = shake_intensity * (shake_timer / shake_duration)
                camera.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
        else:
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

func _on_player_respawned(p: CharacterBody2D):
        hud._add_kill_feed("Đã hồi sinh!", Color(0.2, 1.0, 0.2))
        AudioManager.play_success()

func _on_teleport_performed(p: CharacterBody2D, to_position: Vector2):
        apply_screen_shake(4.0, 0.2)

func _on_ai_died(ai: CharacterBody2D, killer: Node2D):
        if killer == player:
                hud._add_kill_feed("Bạn đã tiêu diệt %s!" % ai.ai_name, Color(0.2, 1.0, 0.2))
                AudioManager.play_achievement()
        elif killer and killer != ai:
                hud._add_kill_feed("%s bị %s tiêu diệt" % [ai.ai_name, killer.ai_name if "ai_name" in killer else "Player"], Color(1.0, 0.5, 0.2))
        else:
                hud._add_kill_feed("%s đã bị tiêu diệt" % ai.ai_name, Color(1.0, 0.5, 0.2))

func _on_zone_shrank(new_radius: float):
        AudioManager.play_zone_shrink()

func _on_combo_achieved(combo_count: int):
        AudioManager.play_combo(combo_count)

func apply_screen_shake(intensity: float, duration: float):
        shake_intensity = intensity
        shake_duration = duration
        shake_timer = duration

func _input(event: InputEvent):
        # Escape: quay lại menu
        if event.is_action_pressed("menu_back"):
                get_tree().change_scene_to_file("res://scenes/menu.tscn")
