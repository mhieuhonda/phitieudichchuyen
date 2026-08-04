extends CharacterBody2D

## Zombie - Quái vật cho chế độ Vượt Ải (v2.4)
## - 3 loại: walker (xanh, chậm, HP thấp), runner (đỏ, nhanh, HP thấp), brute (tím sẫm, chậm, HP cao)
## - Di chuyển xuống dưới về phía player
## - Trừ damage cho player khi chạm
## - Chết khi HP <= 0, emit signal zombie_killed

signal zombie_killed(zombie: Node2D)
signal zombie_reached_player(zombie: Node2D, damage: float)

enum ZombieType { WALKER, RUNNER, BRUTE }

@export var zombie_type: int = ZombieType.WALKER
@export var hp: float = 30.0
@export var max_hp: float = 30.0
@export var move_speed: float = 60.0
@export var damage: float = 15.0
@export var freeze_timer: float = 0.0  # Đóng băng
@export var slow_mult: float = 1.0  # Slow time

var is_dead: bool = false
var _player_node: Node2D = null
var _damage_cooldown: float = 0.0  # Tránh giật liên tục
var _attack_cooldown: float = 0.8  # giây giữa 2 lần cắn player

@onready var body_rect: ColorRect = $BodyRect
@onready var hp_bar: ProgressBar = $HpBar
@onready var eyes: ColorRect = $Eyes
@onready var arms: ColorRect = $Arms

func _ready():
	add_to_group("zombies")
	add_to_group("ai_players")  # Để dart có thể phát hiện
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	_apply_type_visual()

func _apply_type_visual():
	match zombie_type:
		ZombieType.WALKER:
			body_rect.color = Color(0.35, 0.55, 0.25, 1.0)
			eyes.color = Color(1.0, 0.9, 0.2, 1.0)
		ZombieType.RUNNER:
			body_rect.color = Color(0.7, 0.18, 0.18, 1.0)
			eyes.color = Color(1.0, 0.3, 0.2, 1.0)
		ZombieType.BRUTE:
			body_rect.color = Color(0.18, 0.12, 0.25, 1.0)
			eyes.color = Color(1.0, 0.2, 0.8, 1.0)

## Khởi tạo zombie với stats theo level
func setup(type: int, p_max_hp: float, p_speed: float, p_damage: float, player_node: Node2D):
	zombie_type = type
	max_hp = p_max_hp
	hp = p_max_hp
	move_speed = p_speed
	damage = p_damage
	_player_node = player_node
	# Cập nhật lại visual + hp_bar với stats mới (vì _ready() chạy với default)
	_apply_type_visual()
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp

func _physics_process(delta: float):
	if is_dead:
		return
	# Cập nhật cooldown cắn player
	if _damage_cooldown > 0:
		_damage_cooldown -= delta
	# Freeze / slow
	var effective_speed = move_speed
	if freeze_timer > 0:
		freeze_timer -= delta
		effective_speed = 0.0
		# Hiệu ứng đóng băng (xanh nhạt)
		body_rect.modulate = Color(0.6, 0.8, 1.0, 1.0)
	else:
		body_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
	effective_speed *= slow_mult
	# Lái nhẹ về phía player X (cho tự nhiên) — player chỉ di chuyển dọc nên x luôn ở _fixed_x
	if is_instance_valid(_player_node):
		var dx = _player_node.global_position.x - global_position.x
		global_position.x += clamp(dx, -effective_speed * delta, effective_speed * delta) * 0.5
	# Di chuyển xuống
	global_position.y += effective_speed * delta
	# Kiểm tra chạm player
	if is_instance_valid(_player_node) and _damage_cooldown <= 0:
		var dist = global_position.distance_to(_player_node.global_position)
		if dist < 40.0:
			# Cắn player
			_player_node.call("take_damage", damage)
			_damage_cooldown = _attack_cooldown
			if AudioManager:
				AudioManager.play_hit()
	# Kiểm tra đi quá màn hình (player né được)
	if global_position.y > 800:
		# Zombie vượt qua → biến mất, không emit kill
		_queue_free_safe()

## Nhận damage từ dart
func take_damage(amount: float):
	if is_dead:
		return
	hp = max(0.0, hp - amount)
	hp_bar.value = hp
	if hp <= 0:
		_die()

func _die():
	if is_dead:
		return
	is_dead = true
	if AudioManager:
		AudioManager.play_kill()
	emit_signal("zombie_killed", self)
	# Death animation: fade + scale
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_property(self, "scale", Vector2(1.3, 0.7), 0.15)
	tween.tween_callback(_queue_free_safe)

func _queue_free_safe():
	if is_instance_valid(self):
		queue_free()

## Đóng băng zombie
func freeze(duration: float):
	freeze_timer = max(freeze_timer, duration)

## Slow zombie (slow_time)
func set_slow(mult: float):
	slow_mult = mult

func clear_slow():
	slow_mult = 1.0

## Force kill (NUKE skill)
func force_kill():
	_die()
