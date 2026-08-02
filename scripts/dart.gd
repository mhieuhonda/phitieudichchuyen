extends Area2D

## Dart - Phi tiêu
## Bay theo đường thẳng, cắm vào bề mặt, tồn tại giới hạn, có thể dịch chuyển tới

@onready var sprite: ColorRect = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trail_particles: CPUParticles2D = $TrailParticles
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var glow_sprite: ColorRect = $GlowSprite

# === TRẠNG THÁI ===
enum State { FLYING, STUCK, EXPIRED }
var current_state: State = State.FLYING
var direction: Vector2 = Vector2.RIGHT
var speed: float = 0.0
var power: float = 1.0
var owner_player: CharacterBody2D = null
var owner_player_id: int = 0
var stuck_position: Vector2 = Vector2.ZERO

# === SIGNALS ===
signal dart_stuck(dart: Node2D)
signal dart_expired(dart: Node2D)
signal dart_hit_player(dart: Node2D, player: Node2D)

func _ready():
	# Layer cho phi tiêu
	collision_layer = 2  # Dart layer
	collision_mask = 4 | 8 | 16  # Wall + AI + Obstacle
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_expired)

func set_direction(dir: Vector2, pwr: float):
	direction = dir.normalized()
	power = pwr
	speed = GameManager.dart_speed * power

func _physics_process(delta):
	if current_state == State.FLYING:
		# Di chuyển phi tiêu
		position += direction * speed * delta
		
		# Cập nhật góc xoay sprite
		rotation = direction.angle()
		
		# Trail particles
		trail_particles.emitting = true
		
		# Kiểm tra ngoài bản đồ
		if position.x < 0 or position.x > GameManager.map_size.x or \
		   position.y < 0 or position.y > GameManager.map_size.y:
			_stick_to_position(position)

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
	
	# Hiệu ứng cắm
	_stick_effect()
	
	# Bắt đầu đếm ngược thời gian tồn tại
	lifetime_timer.start(GameManager.dart_lifetime)
	
	# Phát hiệu ứng nhấp nháy khi sắp hết hạn
	await get_tree().create_timer(GameManager.dart_lifetime - 1.5).timeout
	if current_state == State.STUCK and is_instance_valid(self):
		_start_blinking()
	
	# Thông báo cho player
	emit_signal("dart_stuck", self)

func _stick_effect():
	# Hiệu ứng rung nhẹ khi cắm
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.05)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Bật glow
	glow_sprite.visible = true
	glow_sprite.modulate.a = 0.6

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

func get_stuck_position() -> Vector2:
	return stuck_position

func is_stuck() -> bool:
	return current_state == State.STUCK
