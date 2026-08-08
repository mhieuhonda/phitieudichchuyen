extends Area2D

## Dart - Phi tiêu với sprite thật (v3.3)
## v3.3: Ricochet (nảy khi chạm tường), knockback khi trúng player
## Bay theo đường thẳng, cắm vào bề mặt, mid-flight teleport

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trail_particles: CPUParticles2D = $TrailParticles
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var glow_sprite: Sprite2D = $GlowSprite
@onready var predicted_line: Line2D = $PredictedLine

enum State { FLYING, STUCK, EXPIRED, CONSUMED }
var current_state: State = State.FLYING
var direction: Vector2 = Vector2.RIGHT
var speed: float = 0.0
var power: float = 1.0
var owner_player: CharacterBody2D = null
var owner_player_id: int = 0
var stuck_position: Vector2 = Vector2.ZERO
var flight_distance: float = 0.0
var max_flight_distance: float = 1500.0
var spawn_immunity_timer: float = 0.08
var ricochet_count: int = 0  # v3.3: đếm số lần nảy
var ricochet_flash_timer: float = 0.0  # Hiệu ứng flash khi nảy

signal dart_stuck(dart: Node2D)
signal dart_expired(dart: Node2D)
signal dart_hit_player(dart: Node2D, player: Node2D)
signal dart_consumed(dart: Node2D)
signal dart_ricocheted(dart: Node2D)

func _ready():
	collision_layer = 2
	# Dart có thể phát hiện: Player(1), Wall(4), AI(8), Obstacle(16), RemotePlayer(64)
	collision_mask = 1 | 4 | 8 | 16 | 64
	set_deferred("monitoring", false)
	lifetime_timer.timeout.connect(_on_lifetime_expired)

	# Load sprite
	var tex = load("res://assets/sprites/dart.png")
	if tex:
		sprite.texture = tex

	# Glow
	glow_sprite.visible = SettingsManager.get_glow_enabled()
	if glow_sprite.visible:
		glow_sprite.modulate = Color(0.3, 0.8, 1.0, 0.5)

	# Trail particles based on quality
	var mult = SettingsManager.get_particle_multiplier()
	if mult <= 0:
		trail_particles.emitting = false
		trail_particles.amount = 1
	else:
		trail_particles.amount = max(1, int(8 * mult))

	_update_predicted_line()

func set_direction(dir: Vector2, pwr: float):
	direction = dir.normalized()
	power = pwr
	speed = GameManager.dart_speed * power

func _physics_process(delta):
	# Spawn immunity
	if not monitoring:
		spawn_immunity_timer -= delta
		if spawn_immunity_timer <= 0:
			set_deferred("monitoring", true)
	# Ricochet flash effect
	if ricochet_flash_timer > 0:
		ricochet_flash_timer -= delta
		if sprite:
			sprite.modulate = Color(0.5, 1.0, 1.0, 1.0)  # Cyan flash
		if ricochet_flash_timer <= 0 and sprite:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if current_state == State.FLYING:
		var move_amount = direction * speed * delta
		position += move_amount
		flight_distance += move_amount.length()
		rotation = direction.angle()
		trail_particles.emitting = SettingsManager.get_trail_enabled()
		# Trail màu thay đổi theo số lần ricochet
		if trail_particles and ricochet_count > 0:
			trail_particles.color = Color(0.3, 1.0, 0.9, 0.7)  # Cyan khi đã nảy
		_update_predicted_line()
		# v3.3: Kiểm tra ngoài map → nảy hoặc stick
		if position.x < 0:
			if _try_ricochet(Vector2(-1, 0)):
				position.x = 0
			else:
				_stick_to_position(position)
		elif position.x > GameManager.map_size.x:
			if _try_ricochet(Vector2(1, 0)):
				position.x = GameManager.map_size.x
			else:
				_stick_to_position(position)
		if position.y < 0:
			if _try_ricochet(Vector2(0, -1)):
				position.y = 0
			else:
				_stick_to_position(position)
		elif position.y > GameManager.map_size.y:
			if _try_ricochet(Vector2(0, 1)):
				position.y = GameManager.map_size.y
			else:
				_stick_to_position(position)
		# Giới hạn khoảng cách bay tối đa
		if flight_distance >= max_flight_distance:
			_stick_to_position(position)

## v3.3: Thử nảy khi chạm tường. Trả về true nếu đã nảy.
func _try_ricochet(wall_normal: Vector2) -> bool:
	if not GameManager.dart_ricochet_enabled:
		return false
	if ricochet_count >= GameManager.dart_max_ricochets:
		return false
	# Tính direction mới: d = d - 2*(d·n)*n
	var dot = direction.dot(wall_normal)
	if dot >= 0:  # Đang bay đi xa tường, không cần nảy
		return false
	direction = (direction - 2 * dot * wall_normal).normalized()
	speed *= GameManager.dart_ricochet_speed_loss
	ricochet_count += 1
	ricochet_flash_timer = 0.15
	# Hiệu ứng tia khi nảy
	_spawn_ricochet_spark()
	dart_ricocheted.emit(self)
	AudioManager.play_dart_stick()  # Reuse sound
	return true

func _spawn_ricochet_spark():
	if SettingsManager.get_particle_multiplier() <= 0:
		return
	var spark = CPUParticles2D.new()
	spark.emitting = true
	spark.one_shot = true
	spark.explosiveness = 0.9
	spark.amount = max(1, int(8 * SettingsManager.get_particle_multiplier()))
	spark.lifetime = 0.25
	spark.direction = Vector2(0, 0)
	spark.spread = 180
	spark.initial_velocity_min = 60
	spark.initial_velocity_max = 140
	spark.gravity = Vector2.ZERO
	spark.scale_amount_min = 1
	spark.scale_amount_max = 3
	spark.color = Color(0.4, 1.0, 0.9, 0.8)
	get_parent().add_child(spark)
	spark.global_position = global_position
	get_tree().create_timer(0.5).timeout.connect(spark.queue_free)

func _update_predicted_line():
	if not predicted_line:
		return
	if current_state == State.FLYING and SettingsManager.get_predicted_line_enabled():
		predicted_line.visible = true
		predicted_line.clear_points()
		var remaining_dist = max_flight_distance - flight_distance
		var steps = 5
		for i in steps + 1:
			var t = i / float(steps)
			predicted_line.add_point(direction * remaining_dist * t)
		# Đổi màu nếu đã nảy
		predicted_line.default_color = Color(0.3, 1.0, 0.9, 0.4) if ricochet_count > 0 else Color(0.3, 0.8, 1.0, 0.3)
	else:
		predicted_line.visible = false

func _on_body_entered(body: Node2D):
	if current_state != State.FLYING:
		return
	if body.is_in_group("walls") or body.is_in_group("obstacles"):
		# v3.3: Nếu là wall ngoài biên → đã được xử lý trong _physics_process.
		# Còn với obstacle (rock, tree, crate) → thử nảy rồi mới stick
		if body.is_in_group("obstacles") and _try_ricochet_off_obstacle(body):
			return
		_stick_to_position(global_position)
		return
	# Va chạm với AI player hoặc Player
	if body.is_in_group("ai_players") and ("owner_player_id" in body) and body.owner_player_id != owner_player_id:
		dart_hit_player.emit(self, body)
		# v3.3: Knockback + slow khi bị trúng dart
		_apply_hit_effects(body)
		_stick_to_position(global_position)
		return
	if body.is_in_group("players") and ("player_id" in body) and body.player_id != owner_player_id:
		dart_hit_player.emit(self, body)
		_apply_hit_effects(body)
		_stick_to_position(global_position)
		return

## v3.3: Nảy khỏi obstacle (rock, tree, crate) — surface normal ~ hướng từ obstacle → dart
func _try_ricochet_off_obstacle(obstacle: Node2D) -> bool:
	if not GameManager.dart_ricochet_enabled:
		return false
	if ricochet_count >= GameManager.dart_max_ricochets:
		return false
	var normal = (global_position - obstacle.global_position).normalized()
	if normal == Vector2.ZERO:
		return false
	var dot = direction.dot(normal)
	if dot >= 0:
		return false
	direction = (direction - 2 * dot * normal).normalized()
	speed *= GameManager.dart_ricochet_speed_loss
	ricochet_count += 1
	ricochet_flash_timer = 0.15
	_spawn_ricochet_spark()
	dart_ricocheted.emit(self)
	AudioManager.play_dart_stick()
	return true

## v3.3: Áp dụng knockback + slow effect khi dart trúng player
func _apply_hit_effects(target: Node2D):
	if not is_instance_valid(target):
		return
	# Knockback: đẩy target theo hướng bay của dart
	if target is CharacterBody2D:
		var knockback = direction * GameManager.dart_knockback_force * power
		target.velocity += knockback
	# Slow effect: set hit_slow_timer nếu target hỗ trợ
	if target.has_method("apply_hit_slow"):
		target.apply_hit_slow(GameManager.hit_slow_duration, GameManager.hit_slow_factor)

func _stick_to_position(pos: Vector2):
	current_state = State.STUCK
	stuck_position = pos
	speed = 0
	trail_particles.emitting = false
	if predicted_line:
		predicted_line.visible = false
	_stick_effect()
	lifetime_timer.start(GameManager.dart_lifetime)
	_start_blink_timer()
	AudioManager.play_dart_stick()
	dart_stuck.emit(self)

func _start_blink_timer():
	await get_tree().create_timer(max(GameManager.dart_lifetime - 1.5, 0.1)).timeout
	if current_state == State.STUCK and is_instance_valid(self):
		_start_blinking()

func _stick_effect():
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.65, 0.65), 0.05)
	tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.1)
	if glow_sprite:
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
	dart_expired.emit(self)

func consume():
	if current_state == State.CONSUMED:
		return
	current_state = State.CONSUMED
	dart_consumed.emit(self)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func is_stuck() -> bool:
	return current_state == State.STUCK

func is_flying() -> bool:
	return current_state == State.FLYING

func is_teleportable() -> bool:
	return current_state == State.FLYING or current_state == State.STUCK

func get_teleport_position() -> Vector2:
	if current_state == State.FLYING:
		return global_position
	return stuck_position

## v3.3: Số lần đã nảy
func get_ricochet_count() -> int:
	return ricochet_count
