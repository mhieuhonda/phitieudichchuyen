class_name AIPlayer
extends CharacterBody2D

## AIPlayer - NPC đối thủ với sprite thật

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hp_bar: ProgressBar = $HpBar
@onready var name_label: Label = $NameLabel

var is_alive: bool = true
var current_hp: float
var current_size: float
var ai_score: int = 0
var all_darts: Array = []
var ai_id: int = 0
var ai_name: String = "Bot"
var owner_player_id: int = 0

enum AIState { IDLE, WANDERING, AIMING, THROWING, TELEPORTING, FLEEING, HUNTING, DODGING }
var current_ai_state: AIState = AIState.IDLE
var state_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var target_player: Node2D = null
var incoming_dart: Node2D = null

var dart_scene: PackedScene = preload("res://scenes/dart.tscn")

static var ai_names: Array = ["Rồng", "Phượng", "Hổ", "Báo", "Sói", "Cáo", "Gấu", "Diều", "Cọp", "Chồn"]
static var ai_name_index: int = 0

## Reset static index - gọi khi game reset để AI tên reset đúng
static func reset_name_index():
        ai_name_index = 0

static var ai_sprite_files: Array = [
        "res://assets/sprites/ai_red.png",
        "res://assets/sprites/ai_green.png",
        "res://assets/sprites/ai_purple.png",
        "res://assets/sprites/ai_yellow.png",
        "res://assets/sprites/ai_orange.png",
        "res://assets/sprites/ai_cyan.png",
        "res://assets/sprites/ai_pink.png",
        "res://assets/sprites/ai_lime.png",
        "res://assets/sprites/ai_teal.png",
        "res://assets/sprites/ai_red.png",
]

signal ai_died(ai: CharacterBody2D, killer: Node2D)

func _ready():
        current_hp = GameManager.player_max_hp
        current_size = GameManager.initial_player_radius
        ai_id = ai_name_index
        ai_name = ai_names[ai_name_index % ai_names.size()]
        owner_player_id = 1000 + ai_id
        ai_name_index += 1
        # Group "ai_players" đã được khai báo trong scene, không cần add lại
        
        # Load sprite
        var sprite_path = ai_sprite_files[ai_id % ai_sprite_files.size()]
        var tex = load(sprite_path)
        if tex:
                sprite.texture = tex
        
        # Cập nhật tên hiển thị
        if name_label:
                name_label.text = ai_name
        
        _update_hp_bar()
        _update_visual_size()
        _choose_new_state()
        collision_layer = 8
        collision_mask = 4 | 16

func _physics_process(delta):
        if not is_alive:
                return
        state_timer -= delta
        _check_incoming_darts()
        if not GameManager.is_in_zone(global_position):
                current_hp -= GameManager.zone_damage_per_second * delta
                _update_hp_bar()
                var to_center = (GameManager.zone_center - global_position).normalized()
                velocity = to_center * GameManager.walk_speed * 1.2
                move_and_slide()
                if current_hp <= 0:
                        kill(null)
                        return
                return
        _update_ai(delta)
        if velocity != Vector2.ZERO:
                move_and_slide()
                position.x = clamp(position.x, 20, GameManager.map_size.x - 20)
                position.y = clamp(position.y, 20, GameManager.map_size.y - 20)

func _check_incoming_darts():
        incoming_dart = null
        var all_dart_nodes = get_tree().get_nodes_in_group("darts")
        for dart in all_dart_nodes:
                if not is_instance_valid(dart) or not dart.is_flying():
                        continue
                if dart.owner_player_id == owner_player_id:
                        continue
                var to_self = (global_position - dart.global_position).normalized()
                var dot = to_self.dot(dart.direction)
                var dist = global_position.distance_to(dart.global_position)
                if dot > 0.7 and dist < 300:
                        incoming_dart = dart
                        if current_ai_state in [AIState.IDLE, AIState.WANDERING] and randf() < GameManager.ai_dodge_chance:
                                current_ai_state = AIState.DODGING
                                state_timer = 0.5
                        break

func _update_ai(delta):
        match current_ai_state:
                AIState.IDLE:
                        velocity = Vector2.ZERO
                        if state_timer <= 0: _choose_new_state()
                AIState.WANDERING:
                        velocity = wander_direction * GameManager.walk_speed * 0.6
                        if state_timer <= 0: _choose_new_state()
                AIState.AIMING:
                        velocity = Vector2.ZERO
                        _find_nearest_player()
                        if state_timer <= 0:
                                current_ai_state = AIState.THROWING
                                state_timer = 0.3
                AIState.THROWING:
                        velocity = Vector2.ZERO
                        if state_timer <= 0:
                                _throw_dart_ai()
                                _choose_new_state()
                AIState.TELEPORTING:
                        velocity = Vector2.ZERO
                        if _has_teleportable_darts() and state_timer <= 0:
                                _teleport_ai()
                                _choose_new_state()
                        elif state_timer <= 0:
                                _choose_new_state()
                AIState.FLEEING:
                        if target_player:
                                velocity = (global_position - target_player.global_position).normalized() * GameManager.walk_speed * 0.8
                        else:
                                velocity = Vector2.ZERO
                        if state_timer <= 0: _choose_new_state()
                AIState.HUNTING:
                        if target_player and target_player.is_alive:
                                velocity = (target_player.global_position - global_position).normalized() * GameManager.walk_speed * 0.7
                                var dist = global_position.distance_to(target_player.global_position)
                                if dist < 300 and _count_active_darts() < GameManager.max_darts_per_player:
                                        current_ai_state = AIState.AIMING
                                        state_timer = 0.5
                        else:
                                _choose_new_state()
                        if state_timer <= 0: _choose_new_state()
                AIState.DODGING:
                        if incoming_dart and is_instance_valid(incoming_dart):
                                var dodge_dir = Vector2(-incoming_dart.direction.y, incoming_dart.direction.x)
                                if randf() < 0.5: dodge_dir = -dodge_dir
                                velocity = dodge_dir * GameManager.walk_speed * 1.2
                        else:
                                velocity = Vector2.ZERO
                        if state_timer <= 0: _choose_new_state()

func _choose_new_state():
        var states = [AIState.IDLE, AIState.WANDERING, AIState.AIMING, AIState.TELEPORTING]
        if _has_teleportable_darts():
                states.append(AIState.TELEPORTING)
                states.append(AIState.TELEPORTING)
        if _find_nearest_player():
                if randf() < 0.5: states.append(AIState.HUNTING)
                states.append(AIState.AIMING)
                if randf() < 0.3: states.append(AIState.FLEEING)
        var chosen = states[randi() % states.size()]
        current_ai_state = chosen
        match chosen:
                AIState.IDLE: state_timer = randf_range(0.5, 2.0)
                AIState.WANDERING: state_timer = randf_range(1.0, 3.0); wander_direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
                AIState.AIMING: state_timer = randf_range(0.5, 1.5)
                AIState.THROWING: state_timer = 0.3
                AIState.TELEPORTING: state_timer = randf_range(0.3, 1.0)
                AIState.FLEEING: state_timer = randf_range(1.0, 2.5)
                AIState.HUNTING: state_timer = randf_range(2.0, 4.0)
                AIState.DODGING: state_timer = randf_range(0.3, 0.8)

func _find_nearest_player() -> Node2D:
        var players = get_tree().get_nodes_in_group("players")
        var nearest: Node2D = null
        var nearest_dist: float = 600.0
        for p in players:
                if not p.is_alive: continue
                var dist = global_position.distance_to(p.global_position)
                if dist < nearest_dist:
                        nearest_dist = dist
                        nearest = p
        target_player = nearest
        return nearest

func _has_teleportable_darts() -> bool:
        for dart in all_darts:
                if is_instance_valid(dart) and dart.is_teleportable(): return true
        return false

func _count_active_darts() -> int:
        var count = 0
        for dart in all_darts:
                if is_instance_valid(dart) and dart.is_teleportable(): count += 1
        return count

func _throw_dart_ai():
        if _count_active_darts() >= GameManager.max_darts_per_player: return
        var throw_dir: Vector2
        if target_player:
                var dist = global_position.distance_to(target_player.global_position)
                var time_to_reach = dist / (GameManager.dart_speed * 0.7)
                var predicted_pos = target_player.global_position + target_player.velocity * time_to_reach
                throw_dir = (predicted_pos - global_position).normalized()
                throw_dir = throw_dir.rotated(randf_range(-0.3, 0.3) * (1.0 - GameManager.ai_accuracy))
        else:
                throw_dir = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
        var power = randf_range(0.4, 0.9)
        var dart = dart_scene.instantiate()
        dart.global_position = global_position
        dart.set_direction(throw_dir, power)
        dart.owner_player = self
        dart.owner_player_id = owner_player_id
        dart.add_to_group("darts")
        get_parent().add_child(dart)
        dart.dart_stuck.connect(_on_dart_stuck)
        dart.dart_expired.connect(_on_dart_expired)
        dart.dart_consumed.connect(_on_dart_consumed)
        dart.dart_hit_player.connect(_on_dart_hit_player)
        all_darts.append(dart)

func _teleport_ai():
        var teleportable_darts = []
        for dart in all_darts:
                if is_instance_valid(dart) and dart.is_teleportable(): teleportable_darts.append(dart)
        if teleportable_darts.size() == 0: return
        var target_dart = teleportable_darts[-1]
        var was_flying = target_dart.is_flying()
        global_position = target_dart.get_teleport_position()
        target_dart.consume()
        all_darts.erase(target_dart)
        _spawn_ai_teleport_effect(global_position, was_flying)
        _check_teleport_kill(global_position)

func _spawn_ai_teleport_effect(pos: Vector2, was_flying: bool):
        if SettingsManager.get_particle_multiplier() <= 0: return
        var particles = CPUParticles2D.new()
        particles.emitting = true; particles.one_shot = true; particles.explosiveness = 0.8
        particles.amount = int(15 * SettingsManager.get_particle_multiplier())
        particles.lifetime = 0.4; particles.direction = Vector2(0,-1); particles.spread = 180
        particles.initial_velocity_min = 40; particles.initial_velocity_max = 120
        particles.gravity = Vector2.ZERO; particles.scale_amount_min = 2; particles.scale_amount_max = 4
        particles.color = Color(0.2,0.9,1.0,0.7) if was_flying else Color(0.3,0.7,1.0,0.6)
        get_parent().add_child(particles); particles.global_position = pos
        get_tree().create_timer(0.8).timeout.connect(particles.queue_free)

func _check_teleport_kill(pos: Vector2):
        var players = get_tree().get_nodes_in_group("players")
        for p in players:
                if not is_instance_valid(p) or not p.is_alive: continue
                var dist = pos.distance_to(p.global_position)
                if dist < GameManager.teleport_kill_radius + GameManager.player_size:
                        p.take_damage_from(50, self)
                        ai_score += GameManager.score_per_kill
                        current_size = min(current_size + GameManager.size_per_kill, GameManager.max_player_size)
                        _update_visual_size()

func _on_dart_stuck(dart: Node2D): pass
func _on_dart_expired(dart: Node2D): all_darts.erase(dart)
func _on_dart_consumed(dart: Node2D): all_darts.erase(dart)

func _on_dart_hit_player(dart: Node2D, hit_player: Node2D):
        # AI dart gây sát thương lên player/AI trúng đạn
        if hit_player.has_method("take_damage_from"):
                hit_player.take_damage_from(GameManager.dart_hit_damage, self)

func kill(killer: Node2D):
        is_alive = false
        if SettingsManager.get_particle_multiplier() > 0:
                var death_particles = CPUParticles2D.new()
                death_particles.emitting = true; death_particles.one_shot = true; death_particles.explosiveness = 0.9
                death_particles.amount = int(30 * SettingsManager.get_particle_multiplier())
                death_particles.lifetime = 0.6; death_particles.direction = Vector2(0,-1); death_particles.spread = 180
                death_particles.initial_velocity_min = 50; death_particles.initial_velocity_max = 200
                death_particles.gravity = Vector2(0,200); death_particles.scale_amount_min = 3; death_particles.scale_amount_max = 6
                death_particles.color = sprite.modulate if sprite.modulate != Color(1,1,1) else Color(1,0.3,0.3)
                get_parent().add_child(death_particles); death_particles.global_position = global_position
                get_tree().create_timer(1.5).timeout.connect(death_particles.queue_free)
        for dart in all_darts:
                if is_instance_valid(dart): dart.queue_free()
        all_darts.clear()
        sprite.visible = false; hp_bar.visible = false; name_label.visible = false
        collision_shape.set_deferred("disabled", true)
        emit_signal("ai_died", self, killer)
        get_tree().create_timer(GameManager.respawn_time).timeout.connect(_respawn)

func take_damage_from(amount: float, attacker: Node2D):
        current_hp -= amount; _update_hp_bar()
        var tween = create_tween()
        tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3), 0.05)
        tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.2)
        if current_hp <= 0: current_hp = 0; kill(attacker)

func _respawn():
        is_alive = true; current_hp = GameManager.player_max_hp; current_size = GameManager.initial_player_radius
        ai_score = 0; sprite.visible = true; hp_bar.visible = true; name_label.visible = true
        collision_shape.set_deferred("disabled", false)
        var angle = randf() * TAU; var dist = randf() * GameManager.zone_radius * 0.6
        global_position = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
        _update_hp_bar(); _update_visual_size(); _choose_new_state()

func _update_visual_size():
        var new_scale = current_size / GameManager.initial_player_radius
        sprite.scale = Vector2(new_scale, new_scale)
        if collision_shape.shape is CircleShape2D: collision_shape.shape.radius = current_size

func _update_hp_bar():
        if hp_bar: hp_bar.max_value = GameManager.player_max_hp; hp_bar.value = current_hp
