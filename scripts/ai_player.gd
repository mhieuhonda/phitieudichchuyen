class_name AIPlayer
extends CharacterBody2D

## AIPlayer - NPC đối thủ (v3.5)
## v3.5:
##   - Anti kill-steal: AI chỉ nhắm player, KHÔNG tấn công AI khác
##   - Khi bị tiêu diệt, thông báo cho GameManager.on_ai_killed_in_stage()
##   - Respawn bị vô hiệu hóa trong stage mode (AI chết là chết thật)
##   - Thông số AI được cấu hình động qua StageManager
## v3.4: Bỏ dash (skill đã bị loại bỏ). AI vẫn có: kiting, prediction, né dart,
##       flee khi HP thấp, pursuit speed boost, chủ động nhặt pickup.
## - Max HP scale theo size (giống player)
## - Hồi 10% max HP khi ăn đối thủ
## - Leaderboard tracking (score, kills, alive)
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
var ai_name: String = ""
var owner_player_id: int = 0

# Shield state
var ai_shield_active: bool = false
var ai_shield_timer: float = 0.0

# v3.3: Hit slow effect
var hit_slow_timer: float = 0.0
var hit_slow_factor: float = 1.0

enum AIState { IDLE, WANDERING, AIMING, THROWING, TELEPORTING, FLEEING, HUNTING, DODGING, KITING, SEEKING_PICKUP }
var current_ai_state: AIState = AIState.IDLE
var state_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var target_player: Node2D = null
var incoming_dart: Node2D = null
var target_pickup: Node2D = null

# Skill cooldowns (AI có dash)
var dash_cooldown: float = 0.0
var teleport_cooldown: float = 0.0  # AI cũng có cooldown dịch chuyển

var dart_scene: PackedScene = preload("res://scenes/dart.tscn")

# v3.3: Memory cho AI - tránh kẹt corner, nhớ last safe zone
var last_safe_position: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0
var last_position_check: Vector2 = Vector2.ZERO

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
        # v3.5: Scale HP theo stage config
        if GameManager.is_stage_mode and StageManager:
                var cfg = StageManager.get_ai_intelligence_for_stage(StageManager.current_stage)
                current_max_hp *= cfg["ai_hp_mult"]
        current_hp = current_max_hp
        ai_id = ai_name_index
        if ai_name == "":
                ai_name = ai_names[ai_name_index % ai_names.size()]
        owner_player_id = 1000 + ai_id
        ai_name_index += 1

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
        collision_mask = 1 | 4 | 16
        last_safe_position = global_position

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
        # v3.8: Dodge burst cooldown
        if _ai_dodge_cooldown > 0:
                _ai_dodge_cooldown = max(0.0, _ai_dodge_cooldown - delta)
        # Teleport cooldown
        if teleport_cooldown > 0:
                teleport_cooldown = max(0.0, teleport_cooldown - delta)
        # Hit slow timer
        if hit_slow_timer > 0:
                hit_slow_timer -= delta
                if hit_slow_timer <= 0:
                        hit_slow_factor = 1.0
                        hit_slow_timer = 0.0
        # Detect incoming darts (luôn luôn, dù đang làm gì)
        _check_incoming_darts()
        # Ngoài vùng bo → ưu tiên về center
        if not GameManager.is_in_zone(global_position):
                current_hp -= GameManager.zone_damage_per_second * delta
                _update_hp_bar()
                var to_center = (GameManager.zone_center - global_position).normalized()
                velocity = to_center * GameManager.walk_speed * 1.4  # Nhanh hơn khi ngoài bo
                velocity *= hit_slow_factor
                move_and_slide()
                if current_hp <= 0:
                        kill(null)
                        return
                return
        else:
                # Lưu vị trí an toàn trong zone
                if global_position.distance_to(GameManager.zone_center) < GameManager.zone_radius * 0.7:
                        last_safe_position = global_position

        # v3.3: Phát hiện kẹt (stuck) - nếu vị trí gần như không đổi sau 1s thì chọn state mới
        stuck_timer += delta
        if stuck_timer > 1.0:
                var moved = global_position.distance_to(last_position_check)
                if moved < 5.0 and current_ai_state not in [AIState.DODGING, AIState.FLEEING]:
                        _choose_new_state()
                stuck_timer = 0.0
                last_position_check = global_position

        _update_ai(delta)
        if velocity != Vector2.ZERO:
                move_and_slide()
                position.x = clamp(position.x, 20, GameManager.map_size.x - 20)
                position.y = clamp(position.y, 20, GameManager.map_size.y - 20)

## v3.3: Áp dụng hit slow effect cho AI (gọi từ dart.gd)
func apply_hit_slow(duration: float, factor: float):
        hit_slow_timer = max(hit_slow_timer, duration)
        hit_slow_factor = factor

func _check_incoming_darts():
        incoming_dart = null
        var all_dart_nodes = get_tree().get_nodes_in_group("darts")
        var best_dart: Node2D = null
        var best_threat: float = 0.0
        for dart in all_dart_nodes:
                if not is_instance_valid(dart) or not dart.is_flying():
                        continue
                if dart.owner_player_id == owner_player_id:
                        continue
                var to_self = (global_position - dart.global_position).normalized()
                var dot = to_self.dot(dart.direction)
                var dist = global_position.distance_to(dart.global_position)
                # Threat score: dot cao (đang bay thẳng tới) + dist thấp = threat cao
                if dot > 0.6 and dist < 400:
                        var threat = dot * (1.0 - dist / 400.0)
                        if threat > best_threat:
                                best_threat = threat
                                best_dart = dart
        incoming_dart = best_dart
        # v3.3: Phản ứng thông minh hơn với dart sắp trúng
        if incoming_dart and is_instance_valid(incoming_dart):
                var dist = global_position.distance_to(incoming_dart.global_position)
                var time_to_impact = dist / max(incoming_dart.speed, 1.0)
                # Nếu sắp trúng (<0.6s) → dash né ngay
                if time_to_impact < 0.6 and dash_cooldown <= 0:
                        var dart_perp = Vector2(-incoming_dart.direction.y, incoming_dart.direction.x)
                        # Chọn hướng né có khoảng trống lớn hơn (xa dart path)
                        var try_a = global_position + dart_perp * 80
                        var try_b = global_position - dart_perp * 80
                        # Chọn hướng về phía center nếu có thể
                        var center_dir = (GameManager.zone_center - global_position).normalized()
                        if center_dir.dot(dart_perp) > 0:
                                _ai_dash(dart_perp)
                        else:
                                _ai_dash(-dart_perp)
                        return
                # Nếu threat cao → chuyển sang DODGING state
                if best_threat > 0.4 and current_ai_state not in [AIState.DODGING, AIState.FLEEING, AIState.TELEPORTING]:
                        if randf() < GameManager.ai_dodge_chance:
                                current_ai_state = AIState.DODGING
                                state_timer = 0.6

func _update_ai(delta):
        match current_ai_state:
                AIState.IDLE:
                        velocity = Vector2.ZERO
                        if state_timer <= 0: _choose_new_state()
                AIState.WANDERING:
                        # v3.3: Nếu gần edge của zone → quay vào center
                        var dist_to_center = global_position.distance_to(GameManager.zone_center)
                        if dist_to_center > GameManager.zone_radius * 0.85:
                                wander_direction = (GameManager.zone_center - global_position).normalized()
                        velocity = wander_direction * GameManager.walk_speed * 0.6 * hit_slow_factor
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
                        if _has_teleportable_darts() and state_timer <= 0 and teleport_cooldown <= 0:
                                # v3.3: Chỉ teleport khi có lợi (gần player hoặc dart đã tới gần player)
                                if _should_teleport():
                                        _teleport_ai()
                                _choose_new_state()
                        elif state_timer <= 0:
                                _choose_new_state()
                AIState.FLEEING:
                        if is_instance_valid(target_player):
                                var flee_dir = (global_position - target_player.global_position).normalized()
                                # v3.3: Flee thông minh - nếu gần edge zone thì chạy dọc theo edge
                                var dist_to_center = global_position.distance_to(GameManager.zone_center)
                                if dist_to_center > GameManager.zone_radius * 0.8:
                                        # Tạo hướng tangent để chạy dọc edge
                                        var tangent = Vector2(-flee_dir.y, flee_dir.x)
                                        if tangent.dot((GameManager.zone_center - global_position)) > 0:
                                                tangent = -tangent
                                        flee_dir = flee_dir * 0.5 + tangent * 0.5
                                        flee_dir = flee_dir.normalized()
                                velocity = flee_dir * GameManager.walk_speed * 0.85 * hit_slow_factor
                                # Dash để bỏ chạy
                                if dash_cooldown <= 0 and randf() < 0.04:
                                        _ai_dash(velocity.normalized())
                        else:
                                velocity = Vector2.ZERO
                        if state_timer <= 0: _choose_new_state()
                AIState.HUNTING:
                        if is_instance_valid(target_player) and target_player.is_alive:
                                var to_target = (target_player.global_position - global_position)
                                var dist = to_target.length()
                                # v3.3: Pursuit speed boost
                                var pursuit_speed = GameManager.walk_speed * GameManager.ai_pursuit_speed_mult * hit_slow_factor
                                velocity = to_target.normalized() * pursuit_speed
                                # Nếu đã đủ gần → aim/throw
                                if dist < 320 and _count_active_darts() < GameManager.max_darts_per_player:
                                        # Nếu target đang yếu → truy tiếp, nếu mạnh → giữ khoảng cách
                                        var target_hp_ratio = 1.0
                                        if "current_hp" in target_player and "current_max_hp" in target_player:
                                                target_hp_ratio = target_player.current_hp / target_player.current_max_hp
                                        if target_hp_ratio < 0.5:
                                                # Truy đuổi sát
                                                current_ai_state = AIState.AIMING
                                                state_timer = 0.4
                                        else:
                                                # Kiting
                                                current_ai_state = AIState.KITING
                                                state_timer = 1.0
                                # Dash để truy đuổi
                                if dist > 100 and dist < 250 and dash_cooldown <= 0 and randf() < 0.03:
                                        _ai_dash(velocity.normalized())
                        else:
                                _choose_new_state()
                        if state_timer <= 0: _choose_new_state()
                AIState.DODGING:
                        if incoming_dart and is_instance_valid(incoming_dart):
                                # v3.3: Dodge theo hướng vuông góc với dart direction
                                var dodge_dir = Vector2(-incoming_dart.direction.y, incoming_dart.direction.x)
                                # Chọn hướng né ưu tiên về center zone
                                var to_center = (GameManager.zone_center - global_position).normalized()
                                if to_center.dot(dodge_dir) < 0:
                                        dodge_dir = -dodge_dir
                                velocity = dodge_dir * GameManager.walk_speed * 1.3 * hit_slow_factor
                        else:
                                velocity = Vector2.ZERO
                        if state_timer <= 0: _choose_new_state()
                AIState.KITING:
                        # v3.3: Kiting - giữ khoảng cách lý tưởng, bắn phi tiêu
                        if is_instance_valid(target_player) and target_player.is_alive:
                                var to_target = (target_player.global_position - global_position)
                                var dist = to_target.length()
                                var ideal = GameManager.ai_kite_distance
                                if dist < ideal - 50:
                                        # Quá gần → lùi
                                        velocity = -to_target.normalized() * GameManager.walk_speed * 0.85 * hit_slow_factor
                                elif dist > ideal + 50:
                                        # Quá xa → tới
                                        velocity = to_target.normalized() * GameManager.walk_speed * 0.7 * hit_slow_factor
                                else:
                                        # Khoảng cách lý tưởng → strafe
                                        var strafe = Vector2(-to_target.y, to_target.x).normalized()
                                        # Đổi hướng strafe thỉnh thoảng
                                        if int(state_timer * 2) % 2 == 0:
                                                strafe = -strafe
                                        velocity = strafe * GameManager.walk_speed * 0.7 * hit_slow_factor
                                # Throw dart khi kiting
                                if _count_active_darts() < GameManager.max_darts_per_player and randf() < 0.04:
                                        current_ai_state = AIState.AIMING
                                        state_timer = 0.4
                        else:
                                _choose_new_state()
                        if state_timer <= 0: _choose_new_state()
                AIState.SEEKING_PICKUP:
                        # v3.3: Chủ động nhặt pickup khi HP thấp
                        if is_instance_valid(target_pickup):
                                var to_pickup = (target_pickup.global_position - global_position)
                                var dist = to_pickup.length()
                                if dist < 30:
                                        _choose_new_state()
                                else:
                                        velocity = to_pickup.normalized() * GameManager.walk_speed * 0.85 * hit_slow_factor
                        else:
                                _choose_new_state()
                        if state_timer <= 0: _choose_new_state()

## v3.4: Đã xóa dash (skill bị loại bỏ). Hàm giữ lại để code cũ không vỡ.
## v3.8: Reactivate thành "dodge burst" — vận tốc tức thời theo hướng _dir,
## không phải skill dash dài. Giúp AI né dart hiệu quả hơn (đặc biệt ải cao).
var _ai_dodge_cooldown: float = 0.0
const AI_DODGE_BURST_FORCE: float = 380.0
const AI_DODGE_COOLDOWN: float = 1.2  # giới hạn để không spam dash

func _ai_dash(dir: Vector2):
        if _ai_dodge_cooldown > 0:
                return
        if dir == Vector2.ZERO:
                return
        # v3.8: Dodge burst — vận tốc tức thời + cooldown ngắn
        velocity = dir.normalized() * AI_DODGE_BURST_FORCE
        _ai_dodge_cooldown = AI_DODGE_COOLDOWN
        # Small visual effect (subtle cyan particle burst)
        if SettingsManager.get_particle_multiplier() > 0:
                var spark = CPUParticles2D.new()
                spark.emitting = true
                spark.one_shot = true
                spark.explosiveness = 0.85
                spark.amount = max(1, int(8 * SettingsManager.get_particle_multiplier()))
                spark.lifetime = 0.25
                spark.direction = -dir.normalized()
                spark.spread = 35.0
                spark.initial_velocity_min = 60
                spark.initial_velocity_max = 120
                spark.gravity = Vector2.ZERO
                spark.scale_amount_min = 1
                spark.scale_amount_max = 3
                spark.color = Color(0.3, 1.0, 0.9, 0.7)
                get_parent().add_child(spark)
                spark.global_position = global_position
                get_tree().create_timer(0.4).timeout.connect(spark.queue_free)

func _choose_new_state():
        # v3.3: AI quyết định state dựa trên HP ratio, vị trí, target
        var hp_ratio = current_hp / current_max_hp if current_max_hp > 0 else 0
        # Nếu HP thấp → flee hoặc tìm pickup
        if hp_ratio < GameManager.ai_flee_hp_threshold:
                # Nếu có pickup gần → đi nhặt
                if GameManager.ai_pickup_seeking:
                        var pickup = _find_nearest_pickup()
                        if pickup:
                                target_pickup = pickup
                                current_ai_state = AIState.SEEKING_PICKUP
                                state_timer = randf_range(2.0, 4.0)
                                return
                # Nếu có target → flee
                _find_nearest_player()
                if target_player:
                        current_ai_state = AIState.FLEEING
                        state_timer = randf_range(1.5, 3.0)
                        return
        # Nếu có target → hunt/kite/aim
        _find_nearest_player()
        if target_player:
                var dist = global_position.distance_to(target_player.global_position)
                # v3.3: Nếu có dart cắm sẵn và target ở gần → teleport để ăn
                if _has_teleportable_darts() and teleport_cooldown <= 0 and dist < 250:
                        if randf() < GameManager.ai_mid_flight_teleport_chance and _should_teleport():
                                current_ai_state = AIState.TELEPORTING
                                state_timer = randf_range(0.3, 0.8)
                                return
                # Random chọn hunt/kite/aim
                var r = randf()
                if dist > 320:
                        current_ai_state = AIState.HUNTING
                        state_timer = randf_range(2.0, 4.0)
                elif r < 0.35:
                        current_ai_state = AIState.AIMING
                        state_timer = randf_range(0.4, 1.2)
                elif r < 0.6:
                        current_ai_state = AIState.KITING
                        state_timer = randf_range(1.0, 2.5)
                else:
                        current_ai_state = AIState.HUNTING
                        state_timer = randf_range(1.5, 3.0)
                return
        # Không có target → wander
        var r2 = randf()
        if r2 < 0.3:
                current_ai_state = AIState.IDLE
                state_timer = randf_range(0.5, 1.5)
        else:
                current_ai_state = AIState.WANDERING
                state_timer = randf_range(1.5, 3.5)
                wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
                # Ưu tiên hướng về center zone nếu đang gần edge
                var dist_to_center = global_position.distance_to(GameManager.zone_center)
                if dist_to_center > GameManager.zone_radius * 0.8:
                        wander_direction = (GameManager.zone_center - global_position).normalized()

func _find_nearest_player() -> Node2D:
        var players = get_tree().get_nodes_in_group("players")
        var nearest: Node2D = null
        var nearest_dist: float = 700.0
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

## v3.5: AI không nhắm vào AI khác (chỉ nhắm player) — tránh kill-steal

## v3.3: Tìm pickup gần nhất (health hoặc dart refill)
func _find_nearest_pickup() -> Node2D:
        var pickups = get_tree().get_nodes_in_group("pickups")
        var nearest: Node2D = null
        var nearest_dist: float = GameManager.ai_pickup_seek_range
        for pk in pickups:
                if not is_instance_valid(pk):
                        continue
                var dist = global_position.distance_to(pk.global_position)
                if dist < nearest_dist:
                        nearest_dist = dist
                        nearest = pk
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

## v3.3: Kiểm tra xem có nên teleport không - chỉ teleport khi có lợi
func _should_teleport() -> bool:
        if not _has_teleportable_darts():
                return false
        # Tìm dart xa nhất (cắm sẵn hoặc đang bay)
        var best_dart: Node2D = null
        var best_dist: float = -1.0
        for dart in all_darts:
                if is_instance_valid(dart) and dart.is_teleportable():
                        var d = global_position.distance_to(dart.global_position)
                        if d > best_dist:
                                best_dist = d
                                best_dart = dart
        if not best_dart:
                return false
        # Nếu teleport tới dart đó sẽ gần target hơn → có lợi
        if is_instance_valid(target_player):
                var dist_no_tp = global_position.distance_to(target_player.global_position)
                var dist_with_tp = best_dart.global_position.distance_to(target_player.global_position)
                # Có lợi nếu giảm khoảng cách tới target ít nhất 100px
                if dist_with_tp < dist_no_tp - 100:
                        return true
        # Nếu dart đã bay xa → có thể teleport để ăn target dart rơi
        if best_dart.is_flying() and best_dist > 200:
                return randf() < 0.5
        return false

func _throw_dart_ai():
        if _count_active_darts() >= GameManager.max_darts_per_player: return
        var throw_dir: Vector2
        if target_player and is_instance_valid(target_player):
                var dist = global_position.distance_to(target_player.global_position)
                # v3.3: Prediction tốt hơn với lead factor
                var time_to_reach = dist / (GameManager.dart_speed * 0.75)
                # Dự đoán vị trí target với lead factor
                var predicted_velocity = target_player.velocity if "velocity" in target_player else Vector2.ZERO
                var predicted_pos = target_player.global_position + predicted_velocity * time_to_reach * GameManager.ai_predict_lead_factor
                throw_dir = (predicted_pos - global_position).normalized()
                # v3.3: Spread nhỏ hơn (AI chính xác hơn) + bắn trước target 1 chút
                var spread_amount = (1.0 - GameManager.ai_accuracy) * 0.4  # Tối đa 0.4 rad
                throw_dir = throw_dir.rotated(randf_range(-spread_amount, spread_amount))
                # v3.3: Power scale theo distance
                var power = clamp(dist / 800.0 + 0.3, GameManager.min_throw_power, GameManager.max_throw_power)
                # Throw
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
        else:
                # Không có target → ném random
                throw_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
                var dart = dart_scene.instantiate()
                dart.global_position = global_position
                dart.set_direction(throw_dir, 0.5)
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
        # v3.3: Chọn dart có lợi nhất (gần target nhất nếu có target)
        var target_dart = teleportable_darts[-1]
        if is_instance_valid(target_player):
                var best_dist = INF
                for dart in teleportable_darts:
                        var d = dart.global_position.distance_to(target_player.global_position)
                        if d < best_dist:
                                best_dist = d
                                target_dart = dart
        var was_flying = target_dart.is_flying()
        # v3.8: Warning sound — báo cho player biết AI sắp dịch chuyển
        # (chỉ khi AI đang nhắm player)
        if is_instance_valid(target_player) and randf() < 0.7:
                AudioManager.play_variation("warning", -4.0, 1.3)
        global_position = target_dart.get_teleport_position()
        target_dart.consume()
        all_darts.erase(target_dart)
        _spawn_ai_teleport_effect(global_position, was_flying)
        AudioManager.play_teleport()
        teleport_cooldown = 1.5  # AI cooldown ngắn hơn player
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
        # v3.5: AI chỉ tấn công player (anti kill-steal) — không tấn công AI khác
        var players = get_tree().get_nodes_in_group("players")
        for p in players:
                if not is_instance_valid(p) or not p.is_alive: continue
                var dist = pos.distance_to(p.global_position)
                if dist < GameManager.teleport_kill_radius + current_size:
                        if p.has_method("is_shield_active") and p.is_shield_active():
                                _spawn_ai_teleport_effect(p.global_position, false)
                                continue
                        if p.has_method("take_damage_from"):
                                p.take_damage_from(80.0, self)  # AI teleport hit = 80 dmg (không kill)
                        # v3.5: AI không còn "ăn" player để tránh kill-steal

func _on_dart_stuck(dart: Node2D): pass
func _on_dart_expired(dart: Node2D): all_darts.erase(dart)
func _on_dart_consumed(dart: Node2D): all_darts.erase(dart)

func _on_dart_hit_player(dart: Node2D, hit_player: Node2D):
        # v3.5: Anti kill-steal — AI dart chỉ gây damage cho player, không cho AI khác
        if hit_player.is_in_group("ai_players") and hit_player != self:
                return  # bỏ qua — không gây damage cho AI khác
        if hit_player.has_method("take_damage_from"):
                var was_alive = hit_player.is_alive if "is_alive" in hit_player else true
                var dmg = GameManager.dart_hit_damage * dart.power
                hit_player.take_damage_from(dmg, self)
                if was_alive and "is_alive" in hit_player and not hit_player.is_alive:
                        # v3.5: Nếu player bị AI giết — không ghi score cho AI
                        pass

func kill(killer: Node2D):
        if not is_alive:
                return
        is_alive = false
        GameManager.set_ai_alive(ai_id, false)
        # v3.6: Đã bỏ gọi GameManager.on_ai_killed_in_stage() tại đây để fix
        # bug double-count — main._on_ai_died (signal handler) đã gọi nó.
        # Trước đây stage_alive_ai bị -2 mỗi lần AI chết (1 từ đây,
        # 1 từ main._on_ai_died), gây hiển thị sai số địch còn lại.
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
        # v3.5: Stage mode — AI không respawn (chỉ player mới respawn)
        if not GameManager.is_stage_mode:
                var self_ref = self
                get_tree().create_timer(GameManager.respawn_time).timeout.connect(func():
                        if is_instance_valid(self_ref):
                                self_ref._respawn()
                )
        else:
                # Stage mode: ẩn hoàn toàn sau 1.5s, không respawn
                var self_ref2 = self
                get_tree().create_timer(1.5).timeout.connect(func():
                        if is_instance_valid(self_ref2):
                                self_ref2.queue_free()
                )

func take_damage_from(amount: float, attacker: Node2D):
        if not is_alive:
                return
        # Shield miễn damage
        if ai_shield_active:
                return
        # v3.5: Anti kill-steal — AI chỉ nhận damage từ player hoặc boss, không từ AI khác
        if attacker and attacker.is_in_group("ai_players") and not (attacker.has_method("is_boss") and attacker.is_boss()):
                return  # AI khác bắn trúng → không gây damage
        current_hp -= amount
        _update_hp_bar()
        _spawn_damage_number(amount)
        var tween = create_tween()
        tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3), 0.05)
        tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.2)
        AudioManager.play_hit()
        # v3.3: Khi bị bắn → có thể flee (phản ứng smart)
        if current_ai_state in [AIState.WANDERING, AIState.IDLE, AIState.HUNTING, AIState.KITING]:
                if attacker and is_instance_valid(attacker):
                        # v3.5: AI chỉ phản ứng với attacker là player
                        if attacker.is_in_group("players"):
                                target_player = attacker
                                # Nếu HP thấp → flee, nếu không → kiting
                                var hp_ratio = current_hp / current_max_hp if current_max_hp > 0 else 0
                                if hp_ratio < GameManager.ai_flee_hp_threshold:
                                        current_ai_state = AIState.FLEEING
                                        state_timer = randf_range(1.5, 2.5)
                                else:
                                        current_ai_state = AIState.KITING
                                        state_timer = randf_range(1.0, 2.0)
        if current_hp <= 0:
                current_hp = 0
                kill(attacker)

func _spawn_damage_number(amount: float):
        var label = Label.new()
        label.add_theme_font_size_override("font_size", 16)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var is_crit = amount >= 50.0
        if is_crit:
                label.text = "CRIT! %d" % int(amount)
                label.add_theme_font_size_override("font_size", 22)
                label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
        else:
                label.text = "%d" % int(amount)
                label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
        var angle = randf_range(-0.6, 0.6) - PI / 2.0
        var vel = Vector2(cos(angle), sin(angle)) * randf_range(40, 80)
        get_parent().add_child(label)
        label.global_position = global_position + Vector2(randf_range(-10, 10), -20)
        label.z_index = 10
        var tween = create_tween()
        tween.tween_property(label, "position", label.position + vel, 0.8)
        tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
        tween.tween_callback(label.queue_free)

func _grow_size(amount: float):
        var old_size = current_size
        current_size = min(current_size + amount, GameManager.max_player_size)
        if current_size != old_size:
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
        hit_slow_factor = 1.0
        hit_slow_timer = 0.0
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
        current_hp = min(current_hp + 15.0, current_max_hp)
        _update_hp_bar()
