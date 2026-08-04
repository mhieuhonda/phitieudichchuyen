extends Area2D

## Dart - Phi tiêu với sprite thật
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
var spawn_immunity_timer: float = 0.08  # Không va chạm 0.08s đầu để tránh stuck ngay khi spawn

signal dart_stuck(dart: Node2D)
signal dart_expired(dart: Node2D)
signal dart_hit_player(dart: Node2D, player: Node2D)
signal dart_consumed(dart: Node2D)

func _ready():
        collision_layer = 2
        # Dart có thể phát hiện: Player(1), Wall(4), AI(8), Obstacle(16), RemotePlayer(64)
        # v2.2 FIX: thêm RemotePlayer (layer 7 = bit 64) để dart có thể va chạm remote players online
        collision_mask = 1 | 4 | 8 | 16 | 64
        # Tắt monitoring tạm thời để tránh body_entered khi spawn.
        # Godot 4.x: không gán trực tiếp `monitoring` khi Area2D đang ở trong SceneTree
        # (sẽ sinh lỗi runtime) → phải dùng set_deferred.
        set_deferred("monitoring", false)
        # body_entered đã được connect trong .tscn, không connect lại
        lifetime_timer.timeout.connect(_on_lifetime_expired)

        # Load sprite
        var tex = load("res://assets/sprites/dart.png")
        if tex:
                sprite.texture = tex
                # Scale đã set trong .tscn (0.5), không cần set lại ở đây

        # Glow
        glow_sprite.visible = SettingsManager.get_glow_enabled()
        if glow_sprite.visible:
                glow_sprite.modulate = Color(0.3, 0.8, 1.0, 0.5)

        # Trail particles based on quality (đảm bảo amount >= 1)
        var mult = SettingsManager.get_particle_multiplier()
        if mult <= 0:
                trail_particles.emitting = false
                trail_particles.amount = 1  # Godot yêu cầu amount >= 1
        else:
                trail_particles.amount = max(1, int(8 * mult))

        _update_predicted_line()

func set_direction(dir: Vector2, pwr: float):
        direction = dir.normalized()
        power = pwr
        speed = GameManager.dart_speed * power

func _physics_process(delta):
        # Spawn immunity: bật monitoring sau khi đã bay xa khỏi player.
        # Dùng set_deferred để tránh lỗi runtime khi Area2D đang trong SceneTree.
        if not monitoring:
                spawn_immunity_timer -= delta
                if spawn_immunity_timer <= 0:
                        set_deferred("monitoring", true)
        if current_state == State.FLYING:
                var move_amount = direction * speed * delta
                position += move_amount
                flight_distance += move_amount.length()
                rotation = direction.angle()
                trail_particles.emitting = SettingsManager.get_trail_enabled()
                _update_predicted_line()
                if position.x < 0 or position.x > GameManager.map_size.x or \
                   position.y < 0 or position.y > GameManager.map_size.y or \
                   flight_distance >= max_flight_distance:
                        _stick_to_position(position)

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
                predicted_line.default_color = Color(0.3, 0.8, 1.0, 0.3)
        else:
                predicted_line.visible = false

func _on_body_entered(body: Node2D):
        if current_state != State.FLYING:
                return
        if body.is_in_group("walls") or body.is_in_group("obstacles"):
                _stick_to_position(global_position)
                return
        # v2.2 FIX: Thêm check remote_players để dart có thể va chạm remote player online
        if body.is_in_group("ai_players") and ("owner_player_id" in body) and body.owner_player_id != owner_player_id:
                dart_hit_player.emit(self, body)
                _stick_to_position(global_position)
                return
        if body.is_in_group("players") and ("player_id" in body) and body.player_id != owner_player_id:
                dart_hit_player.emit(self, body)
                _stick_to_position(global_position)
                return
        if body.is_in_group("remote_players"):
                # v2.2: dart hit remote player (online mode)
                # Remote player ID là string, không so sánh trực tiếp với owner_player_id (int)
                # Nhưng vẫn emit để client có thể xử lý visual + send kill report lên server
                dart_hit_player.emit(self, body)
                _stick_to_position(global_position)
                return

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
