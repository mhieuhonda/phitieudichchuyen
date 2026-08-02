extends CharacterBody2D

## Player - Nhân vật người chơi
## Di chuyển chậm (WASD), nhắm & ném phi tiêu (chuột phải)
## Dịch chuyển (Space) tới phi tiêu ĐANG BAY hoặc đã cắm
## Cơ chế mid-flight teleport: nhấn Space khi phi tiêu đang bay → dịch chuyển tới vị trí phi tiêu hiện tại

@onready var sprite: ColorRect = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var aim_line: Line2D = $AimLine
@onready var dart_container: Node2D = $DartContainer
@onready var hp_bar: ProgressBar = $HpBar
@onready var name_label: Label = $NameLabel
@onready var teleport_particles: CPUParticles2D = $TeleportParticles
@onready var death_particles: CPUParticles2D = $DeathParticles
@onready var size_indicator: Label = $SizeIndicator
@onready var teleport_ready_indicator: ColorRect = $TeleportReadyIndicator

# === TRẠNG THÁI ===
var is_alive: bool = true
var is_aiming: bool = false
var aim_start_pos: Vector2 = Vector2.ZERO
var aim_current_pos: Vector2 = Vector2.ZERO
var all_darts: Array = []  # Tất cả phi tiêu (bay + cắm) - thay stuck_darts
var player_id: int = 0
var player_name: String = "Player"
var current_hp: float
var last_teleport_time: float = 0.0
var teleport_cooldown: float = 0.15  # Cooldown ngắn giữa các lần dịch chuyển
var is_respawning: bool = false

# === THAM CHIẾU ===
var dart_scene: PackedScene = preload("res://scenes/dart.tscn")

signal dart_thrown(dart: Node2D)
signal player_died(player: CharacterBody2D)
signal player_respawned(player: CharacterBody2D)
signal teleport_performed(player: CharacterBody2D, to_position: Vector2)

func _ready():
	current_hp = GameManager.player_max_hp
	_update_hp_bar()
	_update_visual_size()
	_update_size_indicator()
	aim_line.visible = false
	teleport_ready_indicator.visible = false
	collision_layer = 1  # Layer Player
	collision_mask = 4 | 16  # Wall + Obstacle

func _physics_process(delta):
	if not is_alive:
		return
	
	# Di chuyển chậm bằng WASD
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		velocity = input_dir * GameManager.walk_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Giới hạn trong bản đồ
	position.x = clamp(position.x, 20, GameManager.map_size.x - 20)
	position.y = clamp(position.y, 20, GameManager.map_size.y - 20)
	
	# Kiểm tra ngoài vòng bo
	if not GameManager.is_in_zone(position):
		var dmg = GameManager.get_zone_damage(delta)
		var died = GameManager.take_damage(dmg)
		current_hp = GameManager.player_hp
		_update_hp_bar()
		if died:
			_die()
	
	# Cập nhật indicator có thể dịch chuyển
	_update_teleport_indicator()

func _input(event: InputEvent):
	if not is_alive:
		return
	
	# Bắt đầu nhắm (chuột phải xuống)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_start_aiming(event.global_position)
		else:
			_throw_dart(event.global_position)
	
	# Cập nhật hướng nhắm khi kéo
	if event is InputEventMouseMotion and is_aiming:
		aim_current_pos = event.global_position
		_update_aim_line()
	
	# Dịch chuyển (Space) - tới phi tiêu đang bay HOẶC đã cắm
	if event.is_action_pressed("teleport"):
		_teleport_to_dart()

func _start_aiming(mouse_pos: Vector2):
	if _count_active_darts() >= GameManager.max_darts_per_player:
		return
	is_aiming = true
	aim_start_pos = mouse_pos
	aim_current_pos = mouse_pos
	aim_line.visible = true
	_update_aim_line()

func _update_aim_line():
	if not is_aiming:
		return
	
	var direction = (aim_start_pos - aim_current_pos).normalized()
	var power = _calculate_power()
	var line_length = power * 200
	
	aim_line.clear_points()
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(direction * line_length)
	
	# Đổi màu theo lực
	var t = power
	aim_line.default_color = Color(t, 1.0 - t, 0.0)

func _calculate_power() -> float:
	var drag_distance = (aim_start_pos - aim_current_pos).length()
	var power = clamp(drag_distance / 300.0, GameManager.min_throw_power, GameManager.max_throw_power)
	return power

func _throw_dart(mouse_pos: Vector2):
	if not is_aiming:
		return
	is_aiming = false
	aim_line.visible = false
	
	if _count_active_darts() >= GameManager.max_darts_per_player:
		return
	
	var direction = (aim_start_pos - aim_current_pos).normalized()
	var power = _calculate_power()
	
	# Tạo phi tiêu
	var dart = dart_scene.instantiate()
	dart.global_position = global_position
	dart.set_direction(direction, power)
	dart.owner_player = self
	dart.owner_player_id = player_id
	get_parent().add_child(dart)
	
	# Kết nối signals
	dart.dart_stuck.connect(_on_dart_stuck)
	dart.dart_expired.connect(_on_dart_expired)
	dart.dart_hit_player.connect(_on_dart_hit_player)
	dart.dart_consumed.connect(_on_dart_consumed)
	
	# Thêm vào danh sách tất cả phi tiêu (cả đang bay và cắm)
	all_darts.append(dart)
	
	emit_signal("dart_thrown", dart)

func _count_active_darts() -> int:
	"""Đếm số phi tiêu còn hoạt động (bay + cắm)"""
	var count = 0
	for dart in all_darts:
		if is_instance_valid(dart) and dart.is_teleportable():
			count += 1
	return count

func _teleport_to_dart():
	"""Dịch chuyển tới phi tiêu gần nhất (bay hoặc cắm)
	Cơ chế MỚI: có thể dịch chuyển tới phi tiêu ĐANG BAY"""
	
	# Kiểm tra cooldown
	if Time.get_ticks_msec() / 1000.0 - last_teleport_time < teleport_cooldown:
		return
	
	# Tìm phi tiêu có thể dịch chuyển
	var teleportable_darts = []
	for dart in all_darts:
		if is_instance_valid(dart) and dart.is_teleportable():
			teleportable_darts.append(dart)
	
	if teleportable_darts.size() == 0:
		return
	
	# Lấy phi tiêu cuối cùng (mới nhất) - ưu tiên phi tiêu đang bay
	var target_dart = _select_best_dart(teleportable_darts)
	var target_pos = target_dart.get_teleport_position()
	var was_flying = target_dart.is_flying()
	
	# Hiệu ứng biến mất
	_spawn_teleport_effect(global_position, false, was_flying)
	
	# Dịch chuyển
	global_position = target_pos
	
	# Hiệu ứng xuất hiện
	_spawn_teleport_effect(global_position, true, was_flying)
	
	# Screen shake
	GameManager.request_screen_shake(6.0 if was_flying else 4.0, 0.25 if was_flying else 0.15)
	
	# Tiêu thụ phi tiêu
	target_dart.consume()
	all_darts.erase(target_dart)
	
	# Kiểm tra va chạm tại vị trí đích
	_check_teleport_kill(target_pos)
	
	last_teleport_time = Time.get_ticks_msec() / 1000.0
	
	emit_signal("teleport_performed", self, target_pos)

func _select_best_dart(darts: Array) -> Node2D:
	"""Chọn phi tiêu tốt nhất để dịch chuyển
	Ưu tiên: phi tiêu đang bay (nếu bật mid-flight) > phi tiêu cắm cuối cùng"""
	if GameManager.mid_flight_teleport_enabled:
		# Ưu tiên phi tiêu đang bay (mới nhất)
		for i in range(darts.size() - 1, -1, -1):
			if darts[i].is_flying():
				return darts[i]
	# Fallback: phi tiêu cuối cùng
	return darts[-1]

func _check_teleport_kill(pos: Vector2):
	# Kiểm tra xem có AI nào trong bán kính nuốt không
	var ai_players = get_tree().get_nodes_in_group("ai_players")
	for ai in ai_players:
		if not ai.is_alive:
			continue
		var dist = pos.distance_to(ai.global_position)
		if dist < GameManager.teleport_kill_radius + ai.current_size:
			ai.kill(self)
			GameManager.register_kill()
			var points = GameManager.add_score(GameManager.score_per_kill)
			GameManager.add_size(GameManager.size_per_kill)
			_update_visual_size()
			_update_size_indicator()
			GameManager.request_screen_shake(8.0, 0.3)

func _on_dart_stuck(dart: Node2D):
	# Phi tiêu đã nằm trong all_darts từ lúc ném, không cần thêm lại
	pass

func _on_dart_expired(dart: Node2D):
	all_darts.erase(dart)

func _on_dart_consumed(dart: Node2D):
	all_darts.erase(dart)

func _on_dart_hit_player(dart: Node2D, hit_player: Node2D):
	if hit_player.has_method("take_damage_from"):
		hit_player.take_damage_from(GameManager.dart_hit_damage, self)

func _die():
	is_alive = true  # Sẽ respawn, không xóa hẳn
	is_respawning = true
	death_particles.emitting = true
	sprite.visible = false
	collision_shape.set_deferred("disabled", true)
	aim_line.visible = false
	teleport_ready_indicator.visible = false
	
	# Xóa tất cả phi tiêu
	for dart in all_darts:
		if is_instance_valid(dart):
			dart.queue_free()
	all_darts.clear()
	
	emit_signal("player_died", self)
	
	# Respawn sau vài giây
	get_tree().create_timer(GameManager.respawn_time).timeout.connect(_respawn)

func _respawn():
	is_alive = true
	is_respawning = false
	current_hp = GameManager.player_max_hp
	GameManager.player_hp = GameManager.player_max_hp
	GameManager.player_size = GameManager.initial_player_radius
	sprite.visible = true
	collision_shape.set_deferred("disabled", false)
	
	# Vị trí respawn ngẫu nhiên trong vùng an toàn
	var angle = randf() * TAU
	var dist = randf() * GameManager.zone_radius * 0.5
	global_position = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
	
	_update_hp_bar()
	_update_visual_size()
	_update_size_indicator()
	
	# Hiệu ứng xuất hiện
	_spawn_teleport_effect(global_position, true, false)
	
	emit_signal("player_respawned", self)

func _spawn_teleport_effect(pos: Vector2, is_appear: bool, is_mid_flight: bool):
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 25 if is_mid_flight else 18
	particles.lifetime = 0.5
	particles.direction = Vector2(0, -1) if is_appear else Vector2(0, 1)
	particles.spread = 180
	particles.initial_velocity_min = 60
	particles.initial_velocity_max = 180
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2
	particles.scale_amount_max = 5
	
	# Màu khác nhau cho mid-flight teleport
	if is_mid_flight:
		particles.color = Color(0.2, 0.9, 1.0, 0.9) if is_appear else Color(1.0, 0.3, 0.7, 0.9)
	else:
		particles.color = Color(0.3, 0.7, 1.0, 0.8) if is_appear else Color(1.0, 0.5, 0.2, 0.8)
	
	get_parent().add_child(particles)
	particles.global_position = pos
	get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func _update_teleport_indicator():
	"""Hiển thị indicator khi có thể dịch chuyển"""
	var has_teleportable = false
	for dart in all_darts:
		if is_instance_valid(dart) and dart.is_teleportable():
			has_teleportable = true
			break
	teleport_ready_indicator.visible = has_teleportable and is_alive

func _update_visual_size():
	var new_scale = GameManager.player_size / GameManager.initial_player_radius
	sprite.scale = Vector2(new_scale, new_scale)
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = GameManager.player_size

func _update_size_indicator():
	if size_indicator:
		size_indicator.text = "Size: %.0f" % GameManager.player_size

func _update_hp_bar():
	if hp_bar:
		hp_bar.max_value = GameManager.player_max_hp
		hp_bar.value = current_hp

func heal(amount: float):
	current_hp = min(current_hp + amount, GameManager.player_max_hp)
	GameManager.player_hp = current_hp
	_update_hp_bar()

func take_damage_from(amount: float, attacker: Node2D):
	current_hp -= amount
	GameManager.player_hp = current_hp
	_update_hp_bar()
	# Flash đỏ
	var tween = create_tween()
	tween.tween_property(sprite, "color", Color(1.0, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, "color", Color(0.2, 0.6, 1.0), 0.2)
	if current_hp <= 0:
		current_hp = 0
		_die()
