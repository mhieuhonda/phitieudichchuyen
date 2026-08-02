extends Area2D

## Pickup - Vật phẩm nhặt trên bản đồ
## Hồi máu hoặc hồi phi tiêu

enum PickupType { HEALTH, DART_REFILL }

@export var pickup_type: PickupType = PickupType.HEALTH
@export var respawn_time: float = 10.0
@export var health_amount: float = 30.0
@export var dart_refill_count: int = 1

@onready var sprite: ColorRect = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var glow: ColorRect = $GlowSprite
@onready var type_label: Label = $TypeLabel

var is_active: bool = true

func _ready():
	body_entered.connect(_on_body_entered)
	_update_visual()

func _process(_delta):
	if is_active:
		# Floating animation
		var t = Time.get_ticks_msec() / 1000.0
		sprite.position.y = -2.0 + sin(t * 3.0) * 2.0

func _update_visual():
	match pickup_type:
		PickupType.HEALTH:
			sprite.color = Color(0.2, 1.0, 0.3, 0.9)
			glow.color = Color(0.2, 1.0, 0.3, 0.3)
			type_label.text = "+"
			type_label.add_theme_color_override("font_color", Color(0.1, 0.5, 0.1))
		PickupType.DART_REFILL:
			sprite.color = Color(1.0, 0.85, 0.1, 0.9)
			glow.color = Color(1.0, 0.85, 0.1, 0.3)
			type_label.text = "D"
			type_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.0))

func _on_body_entered(body: Node2D):
	if not is_active:
		return
	
	# Người chơi nhặt
	if body.is_in_group("players"):
		_apply_pickup(body)
		_consume()
	# AI nhặt
	elif body.is_in_group("ai_players"):
		_apply_pickup_ai(body)
		_consume()

func _apply_pickup(player: CharacterBody2D):
	match pickup_type:
		PickupType.HEALTH:
			player.heal(health_amount)
		PickupType.DART_REFILL:
			# Tăng max darts tạm thời (không implement phức tạp, chỉ heal 1 ít)
			player.heal(15.0)

func _apply_pickup_ai(ai: CharacterBody2D):
	match pickup_type:
		PickupType.HEALTH:
			ai.current_hp = min(ai.current_hp + health_amount, GameManager.player_max_hp)
			ai._update_hp_bar()
		PickupType.DART_REFILL:
			ai.current_hp = min(ai.current_hp + 15.0, GameManager.player_max_hp)
			ai._update_hp_bar()

func _consume():
	is_active = false
	visible = false
	collision_shape.set_deferred("disabled", true)
	# Tự respawn sau thời gian
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn():
	is_active = true
	visible = true
	collision_shape.set_deferred("disabled", false)
