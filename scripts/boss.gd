class_name Boss
extends CharacterBody2D

## Boss - Boss cuối (v3.5) - Ải 20
## - 10,000,000 HP (10M)
## - Sát thương 4x người chơi (laser 100 dmg/giây, center 200 dmg/giây)
## - Laser attack:
##     + Phase 1: cảnh báo 1s (tia mờ mờ) — player có thời gian né
##     + Phase 2: bắn 1.5s, sát thương liên tục, center = 2x
## - Spinning sweep (rage mode) ở 10% HP:
##     + Quét 360° liên tục 3s
##     + Sát thương cao
## - Player dịch chuyển tới boss = 250k damage (4 hits/second max)
## - Player dart trúng boss = 100 chip damage
## - Sprite: Boss.png
## - HP bar riêng trên HUD (lớn, trên cùng màn hình)
##
## Sound effects:
##   - boss_spawn: drum crash + alarm khi xuất hiện
##   - laser_warning: alarm beep khi đang cảnh báo
##   - laser_fire: laser + bass khi bắn
##   - rage_roar: drum crash + bass khi vào rage (10% HP)
##   - sweep_whoosh: whoosh liên tục khi quét
##   - boss_hurt: hit impact khi bị damage
##   - boss_death: explosion + drum crash khi chết

const KILLER_NONE := ""

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hp_bar: ProgressBar = $HpBar
@onready var name_label: Label = $NameLabel
@onready var rage_aura: CPUParticles2D = $RageAura
@onready var laser_anchor: Node2D = $LaserAnchor

var is_alive: bool = true
var current_hp: float = StageManager.BOSS_MAX_HP
var current_max_hp: float = StageManager.BOSS_MAX_HP
var current_size: float = 80.0  # boss lớn hơn player (80 vs 20)
var owner_player_id: int = 9999  # boss id — để dart check không trùng player

# Boss AI state
enum BossState { IDLE, AIMING, THROWING, LASER_CHARGE, LASER_FIRE, SWEEP_CHARGE, SWEEP_FIRE, RAGE, DEAD }
var current_state: BossState = BossState.IDLE
var state_timer: float = 0.0

# Target
var target_player: CharacterBody2D = null

# Laser system
var laser_scene: PackedScene = preload("res://scenes/boss_laser.tscn")
var active_laser: Node2D = null
var has_used_rage: bool = false

# Movement (boss bay chậm theo player)
var move_speed: float = 60.0

# Dart throwing
var dart_scene: PackedScene = preload("res://scenes/dart.tscn")
var all_darts: Array = []
var dart_throw_cooldown: float = 0.0
# v3.8: Đổi từ const → var để phase 2 có thể giảm interval (2.5s → 1.8s)
var DART_THROW_INTERVAL: float = 2.5  # ném 1 phi tiêu mỗi 2.5s (1.8s ở phase 2)

# Cooldown giữa các đợt laser
var laser_cooldown: float = 0.0
const LASER_COOLDOWN_INTERVAL: float = 4.0  # 4s giữa các đợt laser

# v3.8: Phase 2 — boss vào phase 2 ở 50% HP, bắn 3 dart spread thay vì 1
var has_used_phase2: bool = false
const BOSS_PHASE2_HP_PERCENT: float = 0.50
const PHASE2_SPREAD_ANGLE: float = 0.35  # radians (~20° mỗi bên)

# Damage flash
var _hurt_flash_timer: float = 0.0

# Boss damage (v3.7: < 4x player dart — player dart = 25, 4x = 100, boss = 80)
# v3.9: Dùng StageManager.BOSS_DART_DAMAGE làm single source of truth (trước đây
#       boss.gd và stage_manager.gd đều define const BOSS_DART_DAMAGE = 80, dễ lệch).
const BOSS_DART_DAMAGE: float = StageManager.BOSS_DART_DAMAGE

signal boss_damaged(amount: float, current_hp: float, max_hp: float)
signal boss_died(boss: Node2D)
signal boss_rage_started(boss: Node2D)
signal boss_laser_warning(boss: Node2D)
signal boss_laser_fired(boss: Node2D)
signal boss_phase2_started(boss: Node2D)  # v3.8: phase 2 ở 50% HP

func _ready():
    add_to_group("ai_players")  # để dart của player có thể trúng
    add_to_group("boss")
    # Load Boss.png
    var tex = load("res://assets/sprites/Boss.png")
    if tex:
        sprite.texture = tex
    # Boss lớn hơn — scale sprite cho phù hợp
    sprite.scale = Vector2(0.12, 0.12)  # 1536x1024 * 0.12 ≈ 184x123 → to hơn player
    # Collision shape lớn hơn
    if collision_shape.shape is CircleShape2D:
        collision_shape.shape.radius = current_size
    collision_layer = 8  # cùng layer với AI
    collision_mask = 1 | 4 | 16  # Player + Wall + Obstacle
    # HP bar
    if hp_bar:
        hp_bar.max_value = current_max_hp
        hp_bar.value = current_hp
        hp_bar.visible = false  # ẩn HP bar nhỏ trên đầu boss (dùng HUD bar lớn)
    if name_label:
        name_label.text = "BOSS"
        name_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
        name_label.add_theme_font_size_override("font_size", 22)
    # Rage aura (particle quanh boss khi rage)
    if rage_aura:
        rage_aura.emitting = false
        rage_aura.amount = 30
        rage_aura.lifetime = 0.6
        rage_aura.one_shot = false
        rage_aura.explosiveness = 0.2
        rage_aura.direction = Vector2(0, -1)
        rage_aura.spread = 180.0
        rage_aura.initial_velocity_min = 30.0
        rage_aura.initial_velocity_max = 80.0
        rage_aura.gravity = Vector2(0, -30)
        rage_aura.scale_amount_min = 4.0
        rage_aura.scale_amount_max = 8.0
        rage_aura.color = Color(1.0, 0.15, 0.05, 0.85)
    # Boss spawn sound
    _play_spawn_sound()
    # v3.8: Dramatic spawn effect — particle ring expanding outward + screen shake
    _spawn_dramatic_entrance()
    # Initial state
    current_state = BossState.IDLE
    state_timer = 1.5  # 1.5s idle đầu tiên
    laser_cooldown = 3.0  # 3s đầu không bắn laser

## v3.8: Dramatic spawn effect khi boss xuất hiện
func _spawn_dramatic_entrance():
    if SettingsManager.get_particle_multiplier() > 0:
        # 3-wave particle burst outward
        for i in 3:
            var wave = CPUParticles2D.new()
            wave.emitting = true
            wave.one_shot = true
            wave.explosiveness = 0.95
            wave.amount = max(8, int(25 * SettingsManager.get_particle_multiplier()))
            wave.lifetime = 0.8
            wave.direction = Vector2(0, -1)
            wave.spread = 180.0
            wave.initial_velocity_min = 150 + i * 80
            wave.initial_velocity_max = 280 + i * 100
            wave.gravity = Vector2.ZERO
            wave.scale_amount_min = 4
            wave.scale_amount_max = 9
            var colors = [Color(1.0, 0.2, 0.1, 0.95), Color(1.0, 0.5, 0.2, 0.9), Color(0.8, 0.1, 0.4, 0.9)]
            wave.color = colors[i]
            get_parent().add_child(wave)
            wave.global_position = global_position
            # Stagger
            var delay = i * 0.12
            var wave_ref = wave
            create_tween().tween_interval(delay).tween_callback(func():
                if is_instance_valid(wave_ref):
                    wave_ref.emitting = true)
            get_tree().create_timer(2.0).timeout.connect(wave.queue_free)
    # Big screen shake
    GameManager.request_screen_shake(8.0, 0.6)

## v3.8: Spawn 1 particle朝着 boss hướng về phía player (laser charge buildup)
## Hỗ trợ visual telegraph cho player biết laser sắp bắn theo hướng nào.
func _spawn_laser_charge_particle():
    if not is_instance_valid(target_player):
        return
    var dir = (target_player.global_position - global_position).normalized()
    if dir == Vector2.ZERO:
        dir = Vector2.RIGHT
    var spark = CPUParticles2D.new()
    spark.emitting = true
    spark.one_shot = true
    spark.explosiveness = 0.9
    spark.amount = max(1, int(3 * SettingsManager.get_particle_multiplier()))
    spark.lifetime = 0.3
    spark.direction = -dir  # particle bay ngược lại (về phía boss)
    spark.spread = 30.0
    spark.initial_velocity_min = 80
    spark.initial_velocity_max = 180
    spark.gravity = Vector2.ZERO
    spark.scale_amount_min = 2
    spark.scale_amount_max = 4
    spark.color = Color(1.0, 0.5, 0.2, 0.85)
    get_parent().add_child(spark)
    # Spawn particle ở phía trước boss (hướng player), bay về boss
    spark.global_position = global_position + dir * 80
    get_tree().create_timer(0.5).timeout.connect(spark.queue_free)

func _play_spawn_sound():
    AudioManager.play_variation("drum_crash", 4.0, 0.8)
    AudioManager.play_variation("alarm", 2.0, 0.7)
    AudioManager.play_variation("bass", 5.0, 0.6)

func _physics_process(delta):
    if not is_alive:
        return
    _update_target()
    _update_movement(delta)
    _update_timers(delta)
    _update_state(delta)
    _update_hurt_flash(delta)
    if velocity != Vector2.ZERO:
        move_and_slide()
        # Clamp trong map
        position.x = clamp(position.x, current_size, GameManager.map_size.x - current_size)
        position.y = clamp(position.y, current_size, GameManager.map_size.y - current_size)

func _update_target():
    if is_instance_valid(target_player) and target_player.is_alive:
        return
    target_player = null
    var players = get_tree().get_nodes_in_group("players")
    for p in players:
        if is_instance_valid(p) and p.is_alive:
            target_player = p
            return

func _update_movement(delta):
    if not is_instance_valid(target_player):
        velocity = Vector2.ZERO
        return
    # Boss bay chậm về phía player, giữ khoảng cách 200-300px
    var to_player = target_player.global_position - global_position
    var dist = to_player.length()
    if dist > 320.0:
        velocity = to_player.normalized() * move_speed
    elif dist < 180.0:
        velocity = -to_player.normalized() * move_speed * 0.6
    else:
        # Strafe nhẹ
        var strafe = Vector2(-to_player.y, to_player.x).normalized()
        velocity = strafe * move_speed * 0.5

func _update_timers(delta):
    state_timer -= delta
    if laser_cooldown > 0:
        laser_cooldown -= delta
    if dart_throw_cooldown > 0:
        dart_throw_cooldown -= delta

func _update_state(delta):
    match current_state:
        BossState.IDLE:
            velocity *= 0.8  # slow down
            if state_timer <= 0:
                _choose_next_action()
        BossState.AIMING:
            # Stop, aim
            velocity *= 0.5
            if state_timer <= 0:
                current_state = BossState.THROWING
                state_timer = 0.3
        BossState.THROWING:
            if state_timer <= 0:
                _throw_dart()
                current_state = BossState.IDLE
                state_timer = randf_range(0.5, 1.0)
        BossState.LASER_CHARGE:
            velocity *= 0.3
            # v3.8: Particle buildup at boss during charge phase
            if SettingsManager.get_particle_multiplier() > 0 and randf() < 0.5:
                _spawn_laser_charge_particle()
            if state_timer <= 0:
                _fire_laser()
        BossState.LASER_FIRE:
            # Đang bắn laser — chờ tới khi laser kết thúc
            if not is_instance_valid(active_laser):
                current_state = BossState.IDLE
                state_timer = randf_range(0.8, 1.5)
                laser_cooldown = LASER_COOLDOWN_INTERVAL
        BossState.SWEEP_CHARGE:
            velocity *= 0.3
            if state_timer <= 0:
                _fire_sweep()
        BossState.SWEEP_FIRE:
            if not is_instance_valid(active_laser):
                current_state = BossState.IDLE
                state_timer = randf_range(1.0, 2.0)
                laser_cooldown = LASER_COOLDOWN_INTERVAL * 0.5  # rage mode: cooldown ngắn hơn
        BossState.RAGE:
            # Transition state — vào rage thì chuyển sang SWEEP_CHARGE ngay
            current_state = BossState.SWEEP_CHARGE
            state_timer = 1.0
        BossState.DEAD:
            pass

func _choose_next_action():
    if not is_instance_valid(target_player):
        current_state = BossState.IDLE
        state_timer = 1.0
        return
    # v3.8: FIX BUG — nếu laser đang active mà vào IDLE, _choose_next_action
    # có thể spawn laser thứ hai trùng lặp (gây double damage + visual glitch).
    # Chỉ cho phép bắn laser mới khi không có laser active.
    if is_instance_valid(active_laser):
        # Đang có laser active → idle ngắn rồi check lại
        current_state = BossState.IDLE
        state_timer = randf_range(0.4, 0.8)
        return
    # Quyết định hành động tiếp theo:
    # - Nếu laser sẵn sàng (cooldown = 0) → 60% chance bắn laser (hoặc sweep nếu rage)
    # - Nếu dart sẵn sàng → 30% chance ném dart
    # - Còn lại → idle ngắn
    var r = randf()
    if laser_cooldown <= 0 and r < 0.55:
        # Rage mode: sweep nhiều hơn
        if has_used_rage and randf() < 0.4:
            current_state = BossState.SWEEP_CHARGE
            state_timer = 0.8
            boss_laser_warning.emit(self)
            AudioManager.play_variation("alarm", 0.0, 1.2)
        else:
            current_state = BossState.LASER_CHARGE
            state_timer = 1.0  # 1s cảnh báo
            boss_laser_warning.emit(self)
            AudioManager.play_variation("alarm", 0.0, 1.1)
    elif dart_throw_cooldown <= 0 and r < 0.85:
        current_state = BossState.AIMING
        state_timer = 0.5
    else:
        current_state = BossState.IDLE
        state_timer = randf_range(0.5, 1.5)

func _fire_laser():
    if not is_instance_valid(target_player):
        current_state = BossState.IDLE
        state_timer = 1.0
        return
    var dir = (target_player.global_position - global_position).normalized()
    if dir == Vector2.ZERO:
        dir = Vector2.RIGHT
    active_laser = laser_scene.instantiate()
    get_parent().add_child(active_laser)
    active_laser.setup_static(
        dir, 1200.0, 80.0,
        StageManager.BOSS_LASER_DAMAGE_PER_SEC,  # v3.7: 80 dmg/s (< 4x = 100), liên tục mỗi frame
        1.0,  # warn đã chạy ở LASER_CHARGE, nhưng laser scene cũng có warn — ta set 0.01 để skip
        1.5,  # active duration
        self
    )
    # Skip warn phase (đã warn ở LASER_CHARGE state)
    active_laser.warn_duration = 0.01
    active_laser.center_multiplier = StageManager.BOSS_LASER_CENTER_MULTIPLIER
    current_state = BossState.LASER_FIRE
    boss_laser_fired.emit(self)
    AudioManager.play_variation("laser", 4.0, 0.85)
    AudioManager.play_variation("bass", 3.0, 0.7)

func _fire_sweep():
    if not is_instance_valid(target_player):
        current_state = BossState.IDLE
        state_timer = 1.0
        return
    # Sweep bắt đầu từ hướng player, quét 1.5 vòng
    var start_dir = (target_player.global_position - global_position).normalized()
    if start_dir == Vector2.ZERO:
        start_dir = Vector2.RIGHT
    active_laser = laser_scene.instantiate()
    get_parent().add_child(active_laser)
    active_laser.setup_sweep(
        start_dir, 1200.0, 90.0,
        StageManager.BOSS_LASER_DAMAGE_PER_SEC * 1.2,  # v3.7: sweep mạnh hơn 20% (96 dmg/s, vẫn < 100)
        0.01,  # skip warn
        4.0,   # 4 giây quét
        self,
        TAU * 0.45  # 0.45 vòng/giây
    )
    active_laser.center_multiplier = StageManager.BOSS_LASER_CENTER_MULTIPLIER
    active_laser.sweep_total_angle = TAU * 1.5
    current_state = BossState.SWEEP_FIRE
    boss_laser_fired.emit(self)
    AudioManager.play_variation("laser", 5.0, 0.7)
    AudioManager.play_variation("drum_crash", 3.0, 0.85)
    AudioManager.play_variation("bass", 4.0, 0.6)

func _throw_dart():
    if not is_instance_valid(target_player):
        return
    if _count_active_darts() >= 3:
        return
    var dist = global_position.distance_to(target_player.global_position)
    var time_to_reach = dist / (GameManager.dart_speed * 0.75)
    var predicted_pos = target_player.global_position + target_player.velocity * time_to_reach * 1.2
    var throw_dir = (predicted_pos - global_position).normalized()
    if throw_dir == Vector2.ZERO:
        throw_dir = Vector2.RIGHT
    var power = clamp(dist / 800.0 + 0.3, GameManager.min_throw_power, GameManager.max_throw_power)
    # v3.8: Phase 2 — bắn 3 dart spread (chính giữa + 2 bên) khi HP < 50%
    if has_used_phase2:
        _spawn_boss_dart(throw_dir, power)
        _spawn_boss_dart(throw_dir.rotated(PHASE2_SPREAD_ANGLE), power * 0.9)
        _spawn_boss_dart(throw_dir.rotated(-PHASE2_SPREAD_ANGLE), power * 0.9)
        AudioManager.play_variation("throw", 1.0, 0.9)
    else:
        _spawn_boss_dart(throw_dir, power)
        AudioManager.play_throw()
    dart_throw_cooldown = DART_THROW_INTERVAL

## v3.8: Helper — spawn 1 boss dart với direction + power cho trước
func _spawn_boss_dart(throw_dir: Vector2, power: float):
    if _count_active_darts() >= 5:  # phase 2 cho phép tối đa 5 darts
        return
    var dart = dart_scene.instantiate()
    dart.global_position = global_position
    dart.set_direction(throw_dir, power)
    dart.owner_player = self
    dart.owner_player_id = 9999  # boss id (không trùng player 0 hay AI 1-4)
    dart.add_to_group("darts")
    get_parent().add_child(dart)
    dart.dart_stuck.connect(_on_dart_stuck)
    dart.dart_expired.connect(_on_dart_expired)
    dart.dart_consumed.connect(_on_dart_consumed)
    dart.dart_hit_player.connect(_on_dart_hit_player)
    all_darts.append(dart)

func _count_active_darts() -> int:
    var count = 0
    for dart in all_darts:
        if is_instance_valid(dart) and dart.is_teleportable():
            count += 1
    return count

func _on_dart_stuck(_dart: Node2D): pass
func _on_dart_expired(dart: Node2D): all_darts.erase(dart)
func _on_dart_consumed(dart: Node2D): all_darts.erase(dart)

func _on_dart_hit_player(_dart: Node2D, hit_player: Node2D):
    if hit_player.has_method("take_damage_from"):
        # Boss dart = 4x player dart damage
        var dmg = BOSS_DART_DAMAGE
        hit_player.take_damage_from(dmg, self)

func _update_hurt_flash(delta):
    if _hurt_flash_timer > 0:
        _hurt_flash_timer -= delta
        if _hurt_flash_timer <= 0 and sprite:
            sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

## Player dịch chuyển tới boss → gây damage lớn (250k)
func take_teleport_damage(amount: float, attacker: Node2D):
    if not is_alive:
        return
    current_hp = max(0.0, current_hp - amount)
    if hp_bar:
        hp_bar.value = current_hp
    boss_damaged.emit(amount, current_hp, current_max_hp)
    _spawn_damage_number(amount, true)  # big crit-like number
    _hurt_flash_timer = 0.12
    if sprite:
        sprite.modulate = Color(1.0, 0.5, 0.5, 1.0)
    AudioManager.play_variation("hit", 2.0, 1.0)
    # v3.8: Phase 2 trigger — 50% HP
    if not has_used_phase2 and current_hp <= current_max_hp * BOSS_PHASE2_HP_PERCENT:
        _enter_phase2()
    # Rage mode trigger
    if not has_used_rage and current_hp <= current_max_hp * StageManager.BOSS_RAGE_HP_PERCENT:
        _enter_rage_mode()
    if current_hp <= 0:
        _die()

## Dart trúng boss → chip damage (100)
func take_damage_from(amount: float, attacker: Node2D):
    if not is_alive:
        return
    # Boss chỉ nhận 1/4 damage từ dart (để teleport là nguồn damage chính)
    var actual_amount = amount * 0.25
    current_hp = max(0.0, current_hp - actual_amount)
    if hp_bar:
        hp_bar.value = current_hp
    boss_damaged.emit(actual_amount, current_hp, current_max_hp)
    _spawn_damage_number(actual_amount, false)
    _hurt_flash_timer = 0.08
    if sprite:
        sprite.modulate = Color(1.0, 0.7, 0.7, 1.0)
    # v3.8: Phase 2 trigger — 50% HP
    if not has_used_phase2 and current_hp <= current_max_hp * BOSS_PHASE2_HP_PERCENT:
        _enter_phase2()
    if not has_used_rage and current_hp <= current_max_hp * StageManager.BOSS_RAGE_HP_PERCENT:
        _enter_rage_mode()
    if current_hp <= 0:
        _die()

## v3.8: Phase 2 — boss vào phase 2 ở 50% HP, bắn 3 dart spread thay vì 1.
## Tăng move_speed nhẹ + giảm dart cooldown để fight căng hơn.
func _enter_phase2():
    has_used_phase2 = true
    # Tăng move speed nhẹ (chưa bằng rage mode)
    move_speed = 75.0
    # Giãn dart throw interval (từ 2.5s → 1.8s)
    DART_THROW_INTERVAL = 1.8
    boss_phase2_started.emit(self)
    AudioManager.play_variation("drum_crash", 3.0, 0.85)
    AudioManager.play_variation("alarm", 2.0, 0.9)
    AudioManager.play_variation("bass", 4.0, 0.6)
    GameManager.request_screen_shake(6.0, 0.4)

func _enter_rage_mode():
    has_used_rage = true
    boss_rage_started.emit(self)
    AudioManager.play_variation("drum_crash", 5.0, 0.7)
    AudioManager.play_variation("bass", 6.0, 0.5)
    AudioManager.play_variation("alarm", 3.0, 0.8)
    if rage_aura:
        rage_aura.emitting = true
    # Tăng move speed khi rage
    move_speed = 90.0
    # Screen shake mạnh
    GameManager.request_screen_shake(10.0, 0.6)
    # Force next state là SWEEP_CHARGE ngay sau khi state hiện tại kết thúc
    # (sẽ tự động pickup trong _choose_next_action vì has_used_rage = true)
    # Hủy laser hiện tại nếu có
    if is_instance_valid(active_laser):
        active_laser.queue_free()
        active_laser = null
    current_state = BossState.RAGE
    state_timer = 0.5  # brief pause trước khi sweep

func _spawn_damage_number(amount: float, is_big: bool):
    var label = Label.new()
    label.add_theme_font_size_override("font_size", 28 if is_big else 18)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if is_big:
        label.text = "-%d" % int(amount)
        label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
        label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
        label.add_theme_constant_override("shadow_offset_y", 2)
        label.add_theme_constant_override("shadow_outline_size", 5)
    else:
        label.text = "%d" % int(amount)
        label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
    var angle = randf_range(-0.4, 0.4) - PI / 2.0
    var vel = Vector2(cos(angle), sin(angle)) * randf_range(60, 120) * (1.5 if is_big else 1.0)
    get_parent().add_child(label)
    label.global_position = global_position + Vector2(randf_range(-30, 30), -50)
    label.z_index = 30
    var tween = create_tween()
    tween.tween_property(label, "position", label.position + vel, 1.0 if is_big else 0.7)
    tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0 if is_big else 0.7).set_delay(0.4)
    tween.tween_callback(label.queue_free)

func _die():
    if not is_alive:
        return
    is_alive = false
    current_state = BossState.DEAD
    # Hủy laser
    if is_instance_valid(active_laser):
        active_laser.queue_free()
        active_laser = null
    # Hủy darts
    for dart in all_darts:
        if is_instance_valid(dart):
            dart.queue_free()
    all_darts.clear()
    # v3.8: Multi-stage death explosion — 5 waves over 1.5s
    _spawn_death_explosion()
    _spawn_delayed_death_waves()
    # Death sound
    AudioManager.play_variation("explosion", 6.0, 0.7)
    AudioManager.play_variation("drum_crash", 5.0, 0.6)
    AudioManager.play_variation("bass", 7.0, 0.4)
    # Hide visual
    sprite.visible = false
    if hp_bar:
        hp_bar.visible = false
    if name_label:
        name_label.visible = false
    if rage_aura:
        rage_aura.emitting = false
    collision_shape.set_deferred("disabled", true)
    GameManager.request_screen_shake(15.0, 1.0)
    # v3.8: Additional screen shake waves for dramatic effect
    var shake_tween = create_tween()
    for i in 3:
        shake_tween.tween_callback(func():
            GameManager.request_screen_shake(10.0 - i * 2.0, 0.4))
        shake_tween.tween_interval(0.3)
    boss_died.emit(self)

## v3.8: Spawn delayed death waves — 4 additional explosions after initial
func _spawn_delayed_death_waves():
    if SettingsManager.get_particle_multiplier() <= 0:
        return
    for i in 4:
        var delay = 0.2 + i * 0.25
        var delay_tween = create_tween()
        delay_tween.tween_interval(delay)
        delay_tween.tween_callback(func():
            if not is_instance_valid(self):
                return
            _spawn_single_death_wave(i))

func _spawn_death_explosion():
    if SettingsManager.get_particle_multiplier() <= 0:
        return
    for i in 3:
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.9
        particles.amount = max(1, int(40 * SettingsManager.get_particle_multiplier()))
        particles.lifetime = 1.2
        particles.direction = Vector2(0, -1)
        particles.spread = 180.0
        particles.initial_velocity_min = 100
        particles.initial_velocity_max = 350
        particles.gravity = Vector2(0, 200)
        particles.scale_amount_min = 4
        particles.scale_amount_max = 10
        var colors = [Color(1.0, 0.3, 0.1, 0.95), Color(1.0, 0.85, 0.2, 0.9), Color(0.8, 0.2, 0.6, 0.9)]
        particles.color = colors[i]
        get_parent().add_child(particles)
        particles.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
        # Stagger by delay
        var delay_tween = create_tween()
        delay_tween.tween_interval(i * 0.15)
        delay_tween.tween_callback(func():
            if is_instance_valid(particles):
                particles.emitting = true)
        get_tree().create_timer(2.5).timeout.connect(particles.queue_free)

## v3.8: Spawn 1 single death wave — staggered explosions sau initial
func _spawn_single_death_wave(wave_idx: int):
    if SettingsManager.get_particle_multiplier() <= 0:
        return
    var particles = CPUParticles2D.new()
    particles.emitting = true
    particles.one_shot = true
    particles.explosiveness = 0.95
    particles.amount = max(1, int(30 * SettingsManager.get_particle_multiplier()))
    particles.lifetime = 0.9
    particles.direction = Vector2(0, -1)
    particles.spread = 180.0
    particles.initial_velocity_min = 150 + wave_idx * 50
    particles.initial_velocity_max = 300 + wave_idx * 80
    particles.gravity = Vector2(0, 150)
    particles.scale_amount_min = 3
    particles.scale_amount_max = 8
    # Color shift per wave: red → orange → yellow → white
    var colors = [
        Color(1.0, 0.3, 0.1, 0.95),
        Color(1.0, 0.6, 0.2, 0.9),
        Color(1.0, 0.85, 0.3, 0.9),
        Color(1.0, 1.0, 0.9, 0.95)
    ]
    particles.color = colors[wave_idx % colors.size()]
    get_parent().add_child(particles)
    # Random offset around death position
    particles.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
    # Sound per wave
    AudioManager.play_variation("explosion", 3.0 + wave_idx, 0.8 - wave_idx * 0.1)
    get_tree().create_timer(2.0).timeout.connect(particles.queue_free)

## API cho player check
func is_boss() -> bool:
    return true

## Block teleport-kill (boss không chết vì teleport vào, chỉ nhận damage)
func kill(_killer: Node2D):
    # Boss không dùng cơ chế kill() thường — chỉ take_teleport_damage
    pass

## AI Dart hit boss → chỉ nhận chip damage
func apply_hit_slow(_duration: float, _factor: float):
    # Boss không bị slow
    pass

## Boss không nhận heal
func heal(_amount: float):
    pass

func refill_darts(_bonus: int, _duration: float):
    pass
