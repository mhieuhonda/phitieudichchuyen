class_name AIPlayer
extends CharacterBody2D

## AIPlayer - NPC đối thủ (v1.0)
## - Max HP scale theo size (giống player)
## - Hồi 10% max HP khi ăn đối thủ
## - Leaderboard tracking (score, kills, alive)
## - AI uses skills occasionally
## - Hiệu ứng hit flash, kill, level-up

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hp_bar: ProgressBar = $HpBar
@onready var name_label: Label = $NameLabel

var is_alive: bool = true
var current_hp: float
var current_max_hp: float
var current_size: float
var ai_score: int = 0
var ai_kills: int = 0
var all_darts: Array = []
var ai_id: int = 0
var ai_name: String = ""  # empty = auto-assign in _ready; online spawner sets before add_child
var owner_player_id: int = 0

# Shield state (AI cũng có thể có shield khi nhặt powerup hoặc chủ động)
var ai_shield_active: bool = false
var ai_shield_timer: float = 0.0

enum AIState { IDLE, WANDERING, AIMING, THROWING, TELEPORTING, FLEEING, HUNTING, DODGING }
var current_ai_state: AIState = AIState.IDLE
var state_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var target_player: Node2D = null
var incoming_dart: Node2D = null

# Skill cooldowns (AI chỉ dùng dash)
var dash_cooldown: float = 0.0

var dart_scene: PackedScene = preload("res://scenes/dart.tscn")

static var ai_names: Array = ["Rồng", "Phượng", "Hổ", "Báo", "Sói", "Cáo", "Gấu", "Diều", "Cọp", "Chồn"]
static var ai_name_index: int = 0

static func reset_name_index():
    ai_name_index = 0

static var ai_sprite_files: Array = [
    "res://assets/sprites/characters/ai_red.png",
    "res://assets/sprites/characters/ai_green.png",
    "res://assets/sprites/characters/ai_purple.png",
    "res://assets/sprites/characters/ai_yellow.png",
    "res://assets/sprites/characters/ai_orange.png",
    "res://assets/sprites/characters/ai_cyan.png",
    "res://assets/sprites/characters/ai_pink.png",
    "res://assets/sprites/characters/ai_lime.png",
    "res://assets/sprites/characters/ai_teal.png",
    "res://assets/sprites/characters/ai_brown.png",
]

signal ai_died(ai: CharacterBody2D, killer: Node2D)

func _ready():
    add_to_group("ai_players")
    current_size = GameManager.initial_player_radius
    current_max_hp = GameManager.compute_max_hp_for_size(current_size)
    current_hp = current_max_hp
    ai_id = ai_name_index
    if ai_name == "":  # only auto-assign when no name was pre-set (e.g. by online spawn)
        ai_name = ai_names[ai_name_index % ai_names.size()]
    owner_player_id = 1000 + ai_id
    ai_name_index += 1

    # Register vào leaderboard
    GameManager.register_ai_leaderboard(ai_id, ai_name)

    var sprite_path = ai_sprite_files[ai_id % ai_sprite_files.size()]
    var tex = load(sprite_path)
    if tex:
        sprite.texture = tex

    if name_label:
        name_label.text = ai_name

    _update_hp_bar()
    _update_visual_size()
    _choose_new_state()
    collision_layer = 8
    # AI có thể phát hiện: Wall(4), Player(1), Obstacle(16)
    collision_mask = 1 | 4 | 16

func _physics_process(delta):
    if not is_alive:
        return
    state_timer -= delta
    # Shield timer
    if ai_shield_active:
        ai_shield_timer -= delta
        if ai_shield_timer <= 0:
            ai_shield_active = false
    # Dash cooldown
    if dash_cooldown > 0:
        dash_cooldown = max(0.0, dash_cooldown - delta)
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
                # AI cố dash né nếu có sẵn cooldown
                if dash_cooldown <= 0 and randf() < 0.3:
                    _ai_dash(Vector2(-dart.direction.y, dart.direction.x))
                else:
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
            if is_instance_valid(target_player):
                velocity = (global_position - target_player.global_position).normalized() * GameManager.walk_speed * 0.8
                # Dash để bỏ chạy
                if dash_cooldown <= 0 and randf() < 0.02:
                    _ai_dash(velocity.normalized())
            else:
                velocity = Vector2.ZERO
            if state_timer <= 0: _choose_new_state()
        AIState.HUNTING:
            if is_instance_valid(target_player) and target_player.is_alive:
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

func _ai_dash(dir: Vector2):
    if dash_cooldown > 0:
        return
    if dir == Vector2.ZERO:
        return
    dir = dir.normalized()
    # Dash tức thời: dịch chuyển một đoạn nhỏ
    var dash_dist = GameManager.skill_dash_distance * 0.7
    var new_pos = global_position + dir * dash_dist
    new_pos.x = clamp(new_pos.x, 20, GameManager.map_size.x - 20)
    new_pos.y = clamp(new_pos.y, 20, GameManager.map_size.y - 20)
    _spawn_ai_teleport_effect(global_position, false)
    global_position = new_pos
    _spawn_ai_teleport_effect(global_position, true)
    dash_cooldown = GameManager.skill_dash_cooldown * 1.5  # AI dash lâu hơn

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
        if not is_instance_valid(p):
            continue
        if not ("is_alive" in p) or not p.is_alive:
            continue
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
    AudioManager.play_throw()

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
    AudioManager.play_teleport()
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
        if dist < GameManager.teleport_kill_radius + current_size:
            # Nếu player có shield, không kill được
            if p.has_method("is_shield_active") and p.is_shield_active():
                _spawn_ai_teleport_effect(p.global_position, false)
                continue
            # Kill player ngay lập tức
            p.take_damage_from(9999.0, self)  # Lượng lớn để chắc chắn chết
            if not p.is_alive:
                ai_score += GameManager.score_per_kill
                ai_kills += 1
                _grow_size(GameManager.size_per_kill)
                _heal_on_kill()
                GameManager.update_ai_score(ai_id, ai_score)
                GameManager.update_ai_kills(ai_id, ai_kills)
                AudioManager.play_kill()

func _on_dart_stuck(dart: Node2D): pass
func _on_dart_expired(dart: Node2D): all_darts.erase(dart)
func _on_dart_consumed(dart: Node2D): all_darts.erase(dart)

func _on_dart_hit_player(dart: Node2D, hit_player: Node2D):
    if hit_player.has_method("take_damage_from"):
        var was_alive = hit_player.is_alive if "is_alive" in hit_player else true
        hit_player.take_damage_from(GameManager.dart_hit_damage, self)
        # Nếu dart giết được đối thủ, AI ghi kill
        if was_alive and "is_alive" in hit_player and not hit_player.is_alive:
            ai_score += GameManager.score_per_kill
            ai_kills += 1
            _grow_size(GameManager.size_per_kill)
            _heal_on_kill()
            GameManager.update_ai_score(ai_id, ai_score)
            GameManager.update_ai_kills(ai_id, ai_kills)
            AudioManager.play_kill()

func kill(killer: Node2D):
    if not is_alive:
        return
    is_alive = false
    GameManager.set_ai_alive(ai_id, false)
    if SettingsManager.get_particle_multiplier() > 0:
        var death_particles = CPUParticles2D.new()
        death_particles.emitting = true; death_particles.one_shot = true; death_particles.explosiveness = 0.9
        death_particles.amount = max(1, int(30 * SettingsManager.get_particle_multiplier()))
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
    AudioManager.play_death()
    if killer and is_instance_valid(killer):
        ai_died.emit(self, killer)
    else:
        ai_died.emit(self, null)
    # v1.9 FIX: guard respawn callback — if AI is freed during respawn timer,
    # the lambda checks is_instance_valid before calling _respawn.
    var self_ref = self
    get_tree().create_timer(GameManager.respawn_time).timeout.connect(func():
        if is_instance_valid(self_ref):
            self_ref._respawn()
    )

func take_damage_from(amount: float, attacker: Node2D):
    if not is_alive:
        return
    # Shield miễn damage
    if ai_shield_active:
        return
    current_hp -= amount
    _update_hp_bar()
    var tween = create_tween()
    tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3), 0.05)
    tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.2)
    AudioManager.play_hit()
    if current_hp <= 0:
        current_hp = 0
        # Ghi nhận điểm cho attacker nếu là player
        if attacker and is_instance_valid(attacker) and attacker.is_in_group("players"):
            # Player giết AI - register_kill_by_player đã được gọi trong player._check_teleport_kill
            # Hoặc nếu giết bằng dart, attacker sẽ handle trong _on_dart_hit_player
            pass
        kill(attacker)

func _grow_size(amount: float):
    var old_size = current_size
    current_size = min(current_size + amount, GameManager.max_player_size)
    if current_size != old_size:
        # Update max HP theo size mới
        var old_max = current_max_hp
        current_max_hp = GameManager.compute_max_hp_for_size(current_size)
        if current_max_hp > old_max:
            current_hp = min(current_hp + (current_max_hp - old_max), current_max_hp)
        else:
            current_hp = min(current_hp, current_max_hp)
        _update_visual_size()
        _update_hp_bar()
        _spawn_level_up_effect()

func _heal_on_kill():
    var heal_amount = current_max_hp * GameManager.heal_percent_on_kill
    current_hp = min(current_hp + heal_amount, current_max_hp)
    _update_hp_bar()

func _spawn_level_up_effect():
    if SettingsManager.get_particle_multiplier() <= 0: return
    var particles = CPUParticles2D.new()
    particles.emitting = true; particles.one_shot = true; particles.explosiveness = 0.5
    particles.amount = max(1, int(12 * SettingsManager.get_particle_multiplier()))
    particles.lifetime = 0.5; particles.direction = Vector2(0,-1); particles.spread = 180
    particles.initial_velocity_min = 50; particles.initial_velocity_max = 130
    particles.gravity = Vector2(0, -40)
    particles.scale_amount_min = 2; particles.scale_amount_max = 4
    particles.color = Color(1.0, 0.85, 0.2, 0.9)
    get_parent().add_child(particles); particles.global_position = global_position
    get_tree().create_timer(0.9).timeout.connect(particles.queue_free)

func _respawn():
    if GameManager.is_match_over():
        return
    is_alive = true
    current_size = GameManager.initial_player_radius
    current_max_hp = GameManager.compute_max_hp_for_size(current_size)
    current_hp = current_max_hp
    ai_score = 0
    ai_kills = 0
    GameManager.set_ai_alive(ai_id, true)
    GameManager.update_ai_score(ai_id, 0)
    GameManager.update_ai_kills(ai_id, 0)
    sprite.visible = true; hp_bar.visible = true; name_label.visible = true
    collision_shape.set_deferred("disabled", false)
    var angle = randf() * TAU; var dist = randf() * GameManager.zone_radius * 0.6
    global_position = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
    _update_hp_bar(); _update_visual_size(); _choose_new_state()
    AudioManager.play_spawn()

const BASE_SPRITE_SCALE := 0.3

func _update_visual_size():
    var size_ratio = current_size / GameManager.initial_player_radius
    var new_scale = BASE_SPRITE_SCALE * size_ratio
    sprite.scale = Vector2(new_scale, new_scale)
    if collision_shape.shape is CircleShape2D: collision_shape.shape.radius = current_size
    # Scale UI elements ngược để không bị to theo player
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

## AI nhặt pickup health
func heal(amount: float):
    current_hp = min(current_hp + amount, current_max_hp)
    _update_hp_bar()

## AI nhặt dart refill
func refill_darts(bonus: int, duration: float):
    # AI không có dart_bonus field, chỉ heal nhẹ
    current_hp = min(current_hp + 15.0, current_max_hp)
    _update_hp_bar()
