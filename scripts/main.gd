extends Node2D

## Main - Scene chính
## Khởi tạo game, spawn AI, quản lý camera, kết nối signals, screen shake

@onready var player: CharacterBody2D = $Player
@onready var ai_container: Node2D = $AIPlayers
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD

var ai_scene: PackedScene = preload("res://scenes/ai_player.tscn")
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO

func _ready():
	GameManager.reset_game()
	
	player.player_id = 0
	player.player_name = "Player"
	player.add_to_group("players")
	
	hud.set_player(player)
	
	_spawn_ai_players()
	
	player.player_died.connect(_on_player_died)
	player.player_respawned.connect(_on_player_respawned)
	player.teleport_performed.connect(_on_teleport_performed)
	
	_setup_camera()

func _spawn_ai_players():
	# Reset AI name index
	AIPlayer.ai_name_index = 0
	
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
	# Camera theo dõi người chơi
	if player.is_alive:
		camera.position = player.global_position
	
	# Screen shake
	if shake_timer > 0:
		shake_timer -= delta
		var intensity = shake_intensity * (shake_timer / shake_duration)
		camera.offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
	else:
		camera.offset = original_camera_offset

func _on_player_died(p: CharacterBody2D):
	print("Player died! Respawning...")

func _on_player_respawned(p: CharacterBody2D):
	print("Player respawned!")

func _on_teleport_performed(p: CharacterBody2D, to_position: Vector2):
	# Screen shake khi dịch chuyển
	apply_screen_shake(4.0, 0.2)

func _on_ai_died(ai: CharacterBody2D, killer: Node2D):
	if killer == player:
		hud._add_kill_feed("Bạn đã tiêu diệt %s!" % ai.ai_name, Color(0.2, 1.0, 0.2))
	elif killer:
		hud._add_kill_feed("%s đã bị tiêu diệt" % ai.ai_name, Color(1.0, 0.5, 0.2))

func apply_screen_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
