class_name Pickup
extends Area2D

## Pickup - Vật phẩm với sprite thật
## HEALTH: hồi máu, DART_REFILL: tăng giới hạn phi tiêu tạm thời

enum PickupType { HEALTH, DART_REFILL }

@export var pickup_type: PickupType = PickupType.HEALTH
@export var respawn_time: float = 10.0
@export var health_amount: float = 30.0
@export var dart_refill_amount: int = 1
@export var dart_refill_duration: float = 8.0

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var type_label: Label = $TypeLabel

var is_active: bool = true

func _ready():
        # body_entered đã được connect trong .tscn, không connect lại
        _update_visual()

func _process(_delta):
        if is_active:
                var t = Time.get_ticks_msec() / 1000.0
                sprite.position.y = -2.0 + sin(t * 3.0) * 2.0
                # Xoay nhẹ pickup để nổi bật
                sprite.rotation = sin(t * 1.5) * 0.15

func _update_visual():
        match pickup_type:
                PickupType.HEALTH:
                        var tex = load("res://assets/sprites/pickup_health.png")
                        if tex: sprite.texture = tex
                        type_label.text = "+"
                        type_label.add_theme_color_override("font_color", Color(0.1, 0.5, 0.1))
                PickupType.DART_REFILL:
                        var tex = load("res://assets/sprites/pickup_dart.png")
                        if tex: sprite.texture = tex
                        type_label.text = "D"
                        type_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.0))

func _on_body_entered(body: Node2D):
        if not is_active: return
        if body.is_in_group("players"):
                _apply_pickup(body); _consume()
        elif body.is_in_group("ai_players"):
                _apply_pickup_ai(body); _consume()

func _apply_pickup(player: CharacterBody2D):
        match pickup_type:
                PickupType.HEALTH:
                        if player.has_method("heal"):
                                player.heal(health_amount)
                        _spawn_pickup_burst(Color(0.3, 1.0, 0.4, 0.95))
                PickupType.DART_REFILL:
                        if player.has_method("refill_darts"):
                                player.refill_darts(dart_refill_amount, dart_refill_duration)
                        _spawn_pickup_burst(Color(1.0, 0.85, 0.2, 0.95))

## v3.8: Spawn pickup burst particles (hiệu ứng nhặt vật phẩm rõ ràng hơn)
func _spawn_pickup_burst(color: Color):
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var burst = CPUParticles2D.new()
        burst.emitting = true
        burst.one_shot = true
        burst.explosiveness = 0.85
        burst.amount = max(1, int(14 * SettingsManager.get_particle_multiplier()))
        burst.lifetime = 0.45
        burst.direction = Vector2(0, -1)
        burst.spread = 90.0
        burst.initial_velocity_min = 80
        burst.initial_velocity_max = 180
        burst.gravity = Vector2(0, 80)
        burst.scale_amount_min = 2
        burst.scale_amount_max = 5
        burst.color = color
        get_parent().add_child(burst)
        burst.global_position = global_position
        get_tree().create_timer(0.8).timeout.connect(burst.queue_free)

func _apply_pickup_ai(ai: CharacterBody2D):
        # Fix v1.4: trước đây dùng GameManager.player_max_hp làm ceiling cho
        # máu của AI → AI có thể vượt quá max HP riêng. Đã sửa thành ai.current_max_hp.
        match pickup_type:
                PickupType.HEALTH:
                        if ai.has_method("heal"):
                                ai.heal(health_amount)
                        elif "current_hp" in ai and "current_max_hp" in ai:
                                ai.current_hp = min(ai.current_hp + health_amount, ai.current_max_hp)
                                if ai.has_method("_update_hp_bar"):
                                        ai._update_hp_bar()
                PickupType.DART_REFILL:
                        if ai.has_method("refill_darts"):
                                ai.refill_darts(dart_refill_amount, dart_refill_duration)
                        elif "current_hp" in ai and "current_max_hp" in ai:
                                # AI cũng được hồi máu nhẹ khi nhặt dart refill
                                ai.current_hp = min(ai.current_hp + 15.0, ai.current_max_hp)
                                if ai.has_method("_update_hp_bar"):
                                        ai._update_hp_bar()

func _consume():
        is_active = false; visible = false
        collision_shape.set_deferred("disabled", true)
        get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn():
        is_active = true; visible = true
        collision_shape.set_deferred("disabled", false)
