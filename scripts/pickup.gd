class_name Pickup
extends Area2D

## Pickup - Vật phẩm với sprite thật

enum PickupType { HEALTH, DART_REFILL }

@export var pickup_type: PickupType = PickupType.HEALTH
@export var respawn_time: float = 10.0
@export var health_amount: float = 30.0

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var type_label: Label = $TypeLabel

var is_active: bool = true

func _ready():
        body_entered.connect(_on_body_entered)
        _update_visual()

func _process(_delta):
        if is_active:
                var t = Time.get_ticks_msec() / 1000.0
                sprite.position.y = -2.0 + sin(t * 3.0) * 2.0

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
                PickupType.HEALTH: player.heal(health_amount)
                PickupType.DART_REFILL: player.heal(15.0)

func _apply_pickup_ai(ai: CharacterBody2D):
        ai.current_hp = min(ai.current_hp + health_amount, GameManager.player_max_hp)
        ai._update_hp_bar()

func _consume():
        is_active = false; visible = false
        collision_shape.set_deferred("disabled", true)
        get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn():
        is_active = true; visible = true
        collision_shape.set_deferred("disabled", false)
