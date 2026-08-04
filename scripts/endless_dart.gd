extends Area2D

## EndlessDart - Phi tiêu cho chế độ Vượt Ải (v2.4)
## - Bay theo hướng được set (mặc định lên trên)
## - Va chạm với nhóm "zombies" → gây damage
## - Hỗ trợ pierce (xuyên nhiều zombie), homing (tự tìm), explosion (nổ chain)
## - Đơn giản hóa từ dart.gd để không phụ thuộc GameManager / multiplayer

signal dart_hit_zombie(zombie: Node2D, damage: float)

var direction: Vector2 = Vector2.UP
var speed: float = 700.0
var damage: float = 35.0
var owner_player: Node2D = null

var _pierce: bool = false
var _homing: bool = false
var _explosion: bool = false
var _pierce_count: int = 3  # Số zombie có thể xuyên qua
var _hit_targets: Array = []  # Zombie đã hit (tránh hit trùng)
var _lifetime: float = 3.0

@onready var body_rect: ColorRect = $BodyRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready():
	collision_layer = 2
	collision_mask = 8  # Zombie layer
	# Tránh hit ngay khi spawn
	set_deferred("monitoring", false)
	await get_tree().process_frame
	set_deferred("monitoring", true)
	body_entered.connect(_on_body_entered)
	lifetime_timer.wait_time = _lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.start()
	lifetime_timer.timeout.connect(_on_lifetime_expired)

## Khởi tạo dart
func setup(dir: Vector2, spd: float, dmg: float, owner_node: Node2D):
	direction = dir.normalized()
	speed = spd
	damage = dmg
	owner_player = owner_node
	rotation = direction.angle()

func set_pierce(enabled: bool):
	_pierce = enabled

func set_homing(enabled: bool):
	_homing = enabled

func set_explosion(enabled: bool):
	_explosion = enabled

func _physics_process(delta: float):
	# Homing: lái về zombie gần nhất
	if _homing:
		var target = _find_nearest_zombie()
		if target:
			var to_target = (target.global_position - global_position).normalized()
			direction = direction.lerp(to_target, 0.08).normalized()
			rotation = direction.angle()
	global_position += direction * speed * delta

func _find_nearest_zombie() -> Node2D:
	var nearest = null
	var nearest_dist = 9999.0
	for z in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(z) or z.is_dead:
			continue
		if z in _hit_targets:
			continue
		var d = global_position.distance_to(z.global_position)
		if d < nearest_dist and d < 400.0:
			nearest_dist = d
			nearest = z
	return nearest

func _on_body_entered(body: Node2D):
	if not body or not body.is_in_group("zombies"):
		return
	if body in _hit_targets:
		return
	if not body.has_method("take_damage"):
		return
	_hit_targets.append(body)
	body.take_damage(damage)
	emit_signal("dart_hit_zombie", body, damage)
	if AudioManager:
		AudioManager.play_hit()
	# Explosion: nổ AOE
	if _explosion:
		_explosion_aoe()
		_consume()
		return
	# Pierce: tiếp tục nếu còn lượt
	if _pierce and _pierce_count > 1:
		_pierce_count -= 1
		return
	_consume()

func _explosion_aoe():
	var radius = 120.0
	var explosion_damage = damage * 1.5
	for z in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(z) or z.is_dead:
			continue
		if z in _hit_targets:
			continue
		var d = global_position.distance_to(z.global_position)
		if d < radius:
			z.take_damage(explosion_damage)
			_hit_targets.append(z)
	# Hiệu ứng nổ
	_spawn_explosion_fx()

func _spawn_explosion_fx():
	var fx = ColorRect.new()
	fx.color = Color(1.0, 0.5, 0.1, 0.7)
	fx.size = Vector2(240, 240)
	fx.position = Vector2(-120, -120)
	fx.z_index = 5
	add_child(fx)
	var tween = create_tween()
	tween.tween_property(fx, "modulate:a", 0.0, 0.3)
	tween.tween_callback(fx.queue_free)

func _consume():
	# Fade out và remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)

func _on_lifetime_expired():
	_consume()
