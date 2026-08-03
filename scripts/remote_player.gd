extends CharacterBody2D

## RemotePlayer - Đại diện người chơi khác trên mạng (v1.7)
## Không nhận input từ local, chỉ cập nhật vị trí/trạng thái từ server

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hp_bar: ProgressBar = $HpBar
@onready var name_label: Label = $NameLabel

var player_id: String = ""
var player_name: String = "Player"
var character_id: int = 0
var is_alive: bool = true
var current_hp: float = 100.0
var current_max_hp: float = 100.0
var current_size: float = 20.0
var remote_score: int = 0
var remote_kills: int = 0

# Interpolation
var _target_pos: Vector2 = Vector2.ZERO
var _interp_speed: float = 10.0

const BASE_SPRITE_SCALE := 0.3

func _ready():
        add_to_group("remote_players")
        _update_visual()
        _target_pos = global_position

func _physics_process(delta):
        # Smooth interpolation toward target position
        global_position = global_position.lerp(_target_pos, _interp_speed * delta)

## Cập nhật trạng thái từ network sync
func update_from_network(data: Dictionary):
        if data.has("x") and data.has("y"):
                _target_pos = Vector2(float(data["x"]), float(data["y"]))
        if data.has("hp"):
                current_hp = float(data["hp"])
        if data.has("maxHp"):
                current_max_hp = float(data["maxHp"])
        if data.has("size"):
                var new_size = float(data["size"])
                if new_size != current_size:
                        current_size = new_size
                        _update_visual_size()
        if data.has("alive"):
                var new_alive = bool(data["alive"])
                if new_alive != is_alive:
                        is_alive = new_alive
                        sprite.visible = is_alive
                        hp_bar.visible = is_alive
                        name_label.visible = is_alive
                        collision_shape.set_deferred("disabled", not is_alive)
        if data.has("score"):
                remote_score = int(data["score"])
        if data.has("kills"):
                remote_kills = int(data["kills"])
        _update_hp_bar()

func teleport_to(pos: Vector2):
        _target_pos = pos
        global_position = pos
        _spawn_teleport_effect(pos)

func respawn_at(pos: Vector2):
        is_alive = true
        current_hp = current_max_hp
        _target_pos = pos
        global_position = pos
        sprite.visible = true
        hp_bar.visible = true
        name_label.visible = true
        collision_shape.set_deferred("disabled", false)
        _update_hp_bar()

func _update_visual():
        if name_label:
                name_label.text = player_name
        # Load character sprite
        if character_id >= 0:
                var sprite_path = CharacterData.get_sprite_path(character_id) if CharacterData else ""
                if sprite_path != "":
                        var tex = load(sprite_path)
                        if tex:
                                sprite.texture = tex
        _update_visual_size()
        _update_hp_bar()

func _update_visual_size():
        var size_ratio = current_size / GameManager.initial_player_radius
        var new_scale = BASE_SPRITE_SCALE * size_ratio
        sprite.scale = Vector2(new_scale, new_scale)
        if collision_shape.shape is CircleShape2D:
                collision_shape.shape.radius = current_size
        var inv = 1.0 / size_ratio if size_ratio > 0.01 else 1.0
        if hp_bar:
                hp_bar.scale = Vector2(inv, inv)
                hp_bar.position.y = -35.0 * size_ratio
        if name_label:
                name_label.scale = Vector2(inv, inv)
                name_label.position.y = -55.0 * size_ratio

func _update_hp_bar():
        if hp_bar:
                hp_bar.max_value = current_max_hp
                hp_bar.value = current_hp

func _spawn_teleport_effect(pos: Vector2):
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.8
        particles.amount = int(15 * SettingsManager.get_particle_multiplier())
        particles.lifetime = 0.4
        particles.direction = Vector2(0, -1)
        particles.spread = 180
        particles.initial_velocity_min = 40
        particles.initial_velocity_max = 120
        particles.gravity = Vector2.ZERO
        particles.scale_amount_min = 2
        particles.scale_amount_max = 4
        particles.color = Color(0.3, 0.7, 1.0, 0.6)
        get_parent().add_child(particles)
        particles.global_position = pos
        get_tree().create_timer(0.8).timeout.connect(particles.queue_free)
