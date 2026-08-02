extends Area2D

## Dart - Phi tiêu
## Bay theo đường thẳng, cắm vào bề mặt, tồn tại giới hạn
## CÓ THỂ dịch chuyển tới KHI ĐANG BAY (mid-flight teleport)
## Quỹ đạo dự đoán hiển thị khi phi tiêu đang bay

@onready var sprite: ColorRect = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trail_particles: CPUParticles2D = $TrailParticles
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var glow_sprite: ColorRect = $GlowSprite
@onready var predicted_line: Line2D = $PredictedLine

# === TRẠNG THÁI ===
enum State { FLYING, STUCK, EXPIRED, CONSUMED }
var current_state: State = State.FLYING
var direction: Vector2 = Vector2.RIGHT
var speed: float = 0.0
var power: float = 1.0
var owner_player: CharacterBody2D = null
var owner_player_id: int = 0
var stuck_position: Vector2 = Vector2.ZERO
var flight_distance: float = 0.0
var max_flight_distance: float = 1500.0  # Tầm bay tối đa

# === SIGNALS ===
signal dart_stuck(dart: Node2D)
signal dart_expired(dart: Node2D)
signal dart_hit_player(dart: Node2D, player: Node2D)
signal dart_consumed(dart: Node2D)  # Khi phi tiêu bị dùng để dịch chuyển

func _ready():
	collision_layer = 2  # Dart layer
	collision_mask = 4 | 8 | 16  # Wall + AI + Obstacle
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_expired)
	
	# Hiệu ứng glow cho phi tiêu đang bay (màu khác stuck)
	glow_sprite.visible = true
	glow_sprite.modulate = Color(0.3, 0.8, 1.0, 0.5)  # Xanh nhạt khi bay
	_update_predicted_line()

func set_direction(dir: Vector2, pwr: float):
	direction = dir.normalized()
	power = pwr
	speed = GameManager.dart_speed * power

func _physics_process(delta):
	if current_state == State.FLYING:
		# Di chuyển phi tiêu
		var move_amount = direction * speed * delta
		position += move_amount
		flight_distance += move_amount.length()
		
		# Cập nhật góc xoay sprite
		rotation = direction.angle()
		
		# Trail particles
		trail_particles.emitting = true
		
		# Cập nhật predicted line (đường dự đoán)
		_update_predicted_line()
		
		# Kiểm tra ngoài bản đồ hoặc hết tầm bay
		if position.x < 0 or position.x > GameManager.map_size.x or \
		   position.y < 0 or position.y > GameManager.map_size.y or \
		   flight_distance >= max_flight_distance:
			_stick_to_position(position)

func _update_predicted_line():
	if not predicted_line:
		return
	if current_state == State.FLYING:
		predicted_line.visible = true
		predicted_line.clear_points()
		# Dự đoán quỹ đạo (đường thẳng)
		var remaining_dist = max_flight_distance - flight_distance
		var steps = 5
		for i in steps + 1:
			var t = i / float(steps)
			var point = direction * remaining_dist * t
			predicted_line.add_point(point)
		predicted_line.default_color = Color(0.3, 0.8, 1.0, 0.3)
	else:
		predicted_line.visible = false

func _on_body_entered(body: Node2D):
	if current_state != State.FLYING:
		return
	
	# Cắm vào tường/chướng ngại vật
	if body.is_in_group("walls") or body.is_in_group("obstacles"):
		_stick_to_position(global_position)
		return
	
	# Trúng AI
	if body.is_in_group("ai_players") and body.owner_player_id != owner_player_id:
		emit_signal("dart_hit_player", self, body)
		_stick_to_position(global_position)
		return
	
	# Trúng người chơi khác (multiplayer sau này)
	if body.is_in_group("players") and body.player_id != owner_player_id:
		emit_signal("dart_hit_player", self, body)
		_stick_to_position(global_position)
		return

func _stick_to_position(pos: Vector2):
	current_state = State.STUCK
	stuck_position = pos
	speed = 0
	
	# Dừng trail
	trail_particles.emitting = false
	
	# Ẩn predicted line
	if predicted_line:
		predicted_line.visible = false
	
	# Hiệu ứng cắm
	_stick_effect()
	
	# Bắt đầu đếm ngược thời gian tồn tại
	lifetime_timer.start(GameManager.dart_lifetime)
	
	# Phát hiệu ứng nhấp nháy khi sắp hết hạn
	_start_blink_timer()
	
	# Thông báo cho player
	emit_signal("dart_stuck", self)

func _start_blink_timer():
	await get_tree().create_timer(max(GameManager.dart_lifetime - 1.5, 0.1)).timeout
	if current_state == State.STUCK and is_instance_valid(self):
		_start_blinking()

func _stick_effect():
	# Hiệu ứng rung nhẹ khi cắm
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.05)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Đổi glow: từ xanh nhạt (bay) sang vàng (cắm)
	glow_sprite.modulate = Color(1.0, 0.9, 0.3, 0.6)

func _start_blinking():
	var tween = create_tween()
	tween.set_loops(6)
	tween.tween_property(sprite, "modulate:a", 0.2, 0.12)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.12)

func _on_lifetime_expired():
	if current_state == State.STUCK:
		current_state = State.EXPIRED
		_fade_out_and_remove()

func _fade_out_and_remove():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
	emit_signal("dart_expired", self)

func consume():
	"""Đánh dấu phi tiêu đã được dùng để dịch chuyển"""
	if current_state == State.CONSUMED:
		return
	current_state = State.CONSUMED
	emit_signal("dart_consumed", self)
	# Hiệu ứng tiêu thụ
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func get_stuck_position() -> Vector2:
	return stuck_position

func is_stuck() -> bool:
	return current_state == State.STUCK

func is_flying() -> bool:
	return current_state == State.FLYING

func is_teleportable() -> bool:
	"""Phi tiêu có thể dịch chuyển tới khi đang bay HOẶC đã cắm"""
	return current_state == State.FLYING or current_state == State.STUCK

func get_teleport_position() -> Vector2:
	"""Vị trí dịch chuyển: nếu đang bay thì lấy vị trí hiện tại, nếu cắm thì lấy vị trí cắm"""
	if current_state == State.FLYING:
		return global_position
	return stuck_position
