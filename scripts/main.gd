extends Node2D

## Main - Scene chính
## Khởi tạo game, spawn AI, quản lý camera, kết nối signals

@onready var player: CharacterBody2D = $Player
@onready var ai_container: Node2D = $AIPlayers
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD

var ai_scene: PackedScene = preload("res://scenes/ai_player.tscn")

func _ready():
	# Reset game state
	GameManager.reset_game()
	
	# Setup player
	player.player_id = 0
	player.player_name = "Player"
	player.add_to_group("players")
	
	# Setup HUD
	hud.set_player(player)
	
	# Spawn AI players
	_spawn_ai_players()
	
	# Connect player signals
	player.player_died.connect(_on_player_died)
	
	# Setup camera follow
	_setup_camera()

func _spawn_ai_players():
	for i in GameManager.num_ai_players:
		var ai = ai_scene.instantiate()
		ai.ai_id = i
		ai_container.add_child(ai)
		
		# Vị trí ngẫu nhiên trong bản đồ
		var rng = RandomNumberGenerator.new()
		rng.seed = i * 7 + 13
		var angle = rng.randf() * TAU
		var dist = rng.randf_range(100, 600)
		ai.global_position = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
		
		ai.ai_died.connect(_on_ai_died)

func _setup_camera():
	# Camera theo dõi người chơi
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0

func _process(_delta):
	# Camera theo dõi người chơi
	if player.is_alive:
		camera.position = player.global_position

func _on_player_died(p: CharacterBody2D):
	# Xử lý khi người chơi chết
	print("Player died!")
	GameManager.game_active = false

func _on_ai_died(ai: CharacterBody2D, killer: Node2D):
	# Thêm kill feed
	if killer == player:
		hud._add_kill_feed("Bạn đã tiêu diệt %s!" % ai.ai_name, Color(0.2, 1.0, 0.2))
	elif killer:
		hud._add_kill_feed("%s đã bị tiêu diệt" % ai.ai_name, Color(1.0, 0.5, 0.2))
