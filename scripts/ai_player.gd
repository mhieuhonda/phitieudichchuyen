extends CharacterBody2D

## AIPlayer - NPC đối thủ
## Di chuyển ngẫu nhiên, ném phi tiêu đơn giản, dịch chuyển tới phi tiêu

@onready var sprite: ColorRect = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hp_bar: ProgressBar = $HpBar
@onready var name_label: Label = $NameLabel

# === TRẠNG THÁI ===
var is_alive: bool = true
var current_hp: float
var current_size: float
var ai_score: int = 0
var stuck_darts: Array = []
var ai_id: int = 0
var ai_name: String = "Bot"

# === AI STATE ===
enum AIState { IDLE, WANDERING, AIMING, THROWING, TELEPORTING, FLEEING }
var current_ai_state: AIState = AIState.IDLE
var state_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var target_player: Node2D = null

# === THAM CHIẾU ===
var dart_scene: PackedScene = preload("res://scenes/dart.tscn")

# Tên AI
static var ai_names: Array = ["Rồng", "Phượng", "Hổ", "Báo", "Sói", "Cáo", "Gấu", "Diều", "Cọp", "Chồn"]
static var ai_name_index: int = 0

signal ai_died(ai: CharacterBody2D, killer: Node2D)

func _ready():
	current_hp = GameManager.player_max_hp
	current_size = GameManager.initial_player_radius
	ai_id = ai_name_index
	ai_name = ai_names[ai_name_index % ai_names.size()]
	ai_name_index += 1
	
	add_to_group("ai_players")
	
	# Màu ngẫu nhiên
	var colors = [Color(1.0, 0.3, 0.3), Color(0.3, 1.0, 0.3), Color(0.3, 0.3, 1.0),
	              Color(1.0, 1.0, 0.3), Color(1.0, 0.3, 1.0), Color(0.3, 1.0, 1.0),
	              Color(1.0, 0.6, 0.2), Color(0.6, 0.2, 1.0)]
	sprite.color = colors[ai_id % colors.size()]
	
	_update_hp_bar()
	_update_visual_size()
	_choose_new_state()
	
	collision_layer = 8  # AI layer
	collision_mask = 4 | 16  # Wall + Obstacle

func _physics_process(delta):
	if not is_alive:
		return
	
	state_timer -= delta
	
	# Kiểm tra ngoài vòng bo
	if not GameManager.is_in_zone(global_position):
		current_hp -= GameManager.zone_damage_per_second * delta
		_update_hp_bar()
		if current_hp <= 0:
			kill(null)
			return
	
	# Cập nhật AI state
	_update_ai(delta)
	
	# Di chuyển
	if velocity != Vector2.ZERO:
		move_and_slide()
		position.x = clamp(position.x, 20, GameManager.map_size.x - 20)
		position.y = clamp(position.y, 20, GameManager.map_size.y - 20)

func _update_ai(delta):
	match current_ai_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
			if state_timer <= 0:
				_choose_new_state()
		
		AIState.WANDERING:
			velocity = wander_direction * GameManager.walk_speed * 0.6
			if state_timer <= 0:
				_choose_new_state()
		
		AIState.AIMING:
			velocity = Vector2.ZERO
			# Nhìn về phía người chơi gần nhất
			_find_nearest_player()
			if state_timer <= 0:
				current_ai_state = AIState.THROWING
				state_timer = 0.3
		
		AIState.THROWING:
			velocity = Vector2.ZERO
			if state_timer <= 0:
				_throw_dart_ai()
				_choose_new_state()
		
		AIState.TELEPORTING:
			velocity = Vector2.ZERO
			if stuck_darts.size() > 0 and state_timer <= 0:
				_teleport_ai()
				_choose_new_state()
			elif state_timer <= 0:
				_choose_new_state()
		
		AIState.FLEEING:
			if target_player:
				var flee_dir = (global_position - target_player.global_position).normalized()
				velocity = flee_dir * GameManager.walk_speed * 0.8
			else:
				velocity = Vector2.ZERO
			if state_timer <= 0:
				_choose_new_state()

func _choose_new_state():
	var states = [AIState.IDLE, AIState.WANDERING, AIState.AIMING, AIState.TELEPORTING]
	
	# Nếu có phi tiêu cắm, ưu tiên dịch chuyển
	if stuck_darts.size() > 0:
		states.append(AIState.TELEPORTING)
		states.append(AIState.TELEPORTING)
	
	# Nếu thấy người chơi, có thể ném hoặc chạy
	if _find_nearest_player():
		if randf() < 0.6:
			states.append(AIState.AIMING)
		else:
			states.append(AIState.FLEEING)
	
	var chosen = states[randi() % states.size()]
	current_ai_state = chosen
	
	match chosen:
		AIState.IDLE:
			state_timer = randf_range(0.5, 2.0)
		AIState.WANDERING:
			state_timer = randf_range(1.0, 3.0)
			wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		AIState.AIMING:
			state_timer = randf_range(0.5, 1.5)
		AIState.THROWING:
			state_timer = 0.3
		AIState.TELEPORTING:
			state_timer = randf_range(0.3, 1.0)
		AIState.FLEEING:
			state_timer = randf_range(1.0, 2.5)

func _find_nearest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("players")
	var nearest: Node2D = null
	var nearest_dist: float = 500.0  # Tầm nhìn AI
	
	for p in players:
		if not p.is_alive:
			continue
		var dist = global_position.distance_to(p.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = p
	
	target_player = nearest
	return nearest

func _throw_dart_ai():
	if stuck_darts.size() >= GameManager.max_darts_per_player:
		return
	
	var throw_dir: Vector2
	if target_player:
		# Nhắm về phía người chơi (có độ lệch ngẫu nhiên)
		throw_dir = (target_player.global_position - global_position).normalized()
		throw_dir = throw_dir.rotated(randf_range(-0.3, 0.3))  # Độ lệch
	else:
		throw_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	var power = randf_range(0.4, 0.9)
	
	var dart = dart_scene.instantiate()
	dart.global_position = global_position
	dart.set_direction(throw_dir, power)
	dart.owner_player = self
	dart.owner_player_id = 1000 + ai_id
	get_parent().add_child(dart)
	
	dart.dart_stuck.connect(_on_dart_stuck)
	dart.dart_expired.connect(_on_dart_expired)

func _teleport_ai():
	if stuck_darts.size() == 0:
		return
	
	var target_dart = stuck_darts[-1]
	var target_pos = target_dart.global_position
	
	global_position = target_pos
	target_dart.queue_free()
	stuck_darts.erase(target_dart)
	
	# Kiểm tra va chạm tại vị trí đích
	_check_teleport_kill(target_pos)

func _check_teleport_kill(pos: Vector2):
	var players = get_tree().get_nodes_in_group("players")
	for p in players:
		if not p.is_alive:
			continue
		var dist = pos.distance_to(p.global_position)
		if dist < GameManager.teleport_kill_radius + GameManager.player_size:
			p._die()
			ai_score += GameManager.score_per_kill
			current_size += GameManager.size_per_kill
			_update_visual_size()

func _on_dart_stuck(dart: Node2D):
	stuck_darts.append(dart)

func _on_dart_expired(dart: Node2D):
	stuck_darts.erase(dart)

func kill(killer: Node2D):
	is_alive = false
	# Hiệu ứng chết
	var death_particles = CPUParticles2D.new()
	death_particles.emitting = true
	death_particles.one_shot = true
	death_particles.explosiveness = 0.9
	death_particles.amount = 30
	death_particles.lifetime = 0.6
	death_particles.direction = Vector2(0, -1)
	death_particles.spread = 180
	death_particles.initial_velocity_min = 50
	death_particles.initial_velocity_max = 200
	death_particles.gravity = Vector2(0, 200)
	death_particles.scale_amount_min = 3
	death_particles.scale_amount_max = 6
	death_particles.color = sprite.color
	get_parent().add_child(death_particles)
	death_particles.global_position = global_position
	get_tree().create_timer(1.5).timeout.connect(death_particles.queue_free)
	
	# Xóa phi tiêu
	for dart in stuck_darts:
		if is_instance_valid(dart):
			dart.queue_free()
	stuck_darts.clear()
	
	sprite.visible = false
	hp_bar.visible = false
	name_label.visible = false
	collision_shape.set_deferred("disabled", true)
	
	emit_signal("ai_died", self, killer)
	
	# Respawn sau vài giây
	get_tree().create_timer(GameManager.respawn_time).timeout.connect(_respawn)

func take_damage_from(amount: float, attacker: Node2D):
	current_hp -= amount
	_update_hp_bar()
	if current_hp <= 0:
		current_hp = 0
		kill(attacker)

func _respawn():
	is_alive = true
	current_hp = GameManager.player_max_hp
	current_size = GameManager.initial_player_radius
	ai_score = 0
	sprite.visible = true
	hp_bar.visible = true
	name_label.visible = true
	collision_shape.set_deferred("disabled", false)
	
	# Vị trí respawn ngẫu nhiên trong vùng an toàn
	var angle = randf() * TAU
	var dist = randf() * GameManager.zone_radius * 0.6
	global_position = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
	
	_update_hp_bar()
	_update_visual_size()
	_choose_new_state()

func _update_visual_size():
	var new_scale = current_size / GameManager.initial_player_radius
	sprite.scale = Vector2(new_scale, new_scale)
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = current_size

func _update_hp_bar():
	if hp_bar:
		hp_bar.max_value = GameManager.player_max_hp
		hp_bar.value = current_hp
