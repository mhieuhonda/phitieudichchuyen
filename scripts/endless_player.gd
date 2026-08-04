extends CharacterBody2D

## EndlessPlayer - Nhân vật người chơi cho chế độ Vượt Ải (v2.4)
## - Khóa trên đường thẳng đứng (chỉ di chuyển lên/xuống)
## - Tự động ném phi tiêu lên trên để giết zombie
## - Hỗ trợ 15 skills (gọi từ skills_hub)
## - Đơn giản hóa từ player.gd để không phụ thuộc multiplayer/teleport
##
## Skill IDs (matching skills_hub.gd):
##   1=QUICK_SHOT, 2=HEAL, 3=SHIELD, 4=MULTISHOT, 5=FREEZE, 6=BOMB,
##   7=SPEED_BOOST, 8=PIERCE, 9=LIFE_STEAL, 10=SLOW_TIME, 11=HOMING,
##   12=EXPLOSION, 13=BERSERK, 14=NUKE, 15=INVINCIBLE

signal hp_changed(hp: float, max_hp: float)
signal player_died

# === THUỘC TÍNH ===
@export var max_hp: float = 100.0
@export var move_speed: float = 180.0
@export var base_throw_cooldown: float = 0.8  # giây giữa 2 lần ném
@export var dart_speed: float = 700.0
@export var dart_damage: float = 35.0

var hp: float = 100.0
var is_alive: bool = true

# === SKILL STATE ===
var throw_cooldown_mult: float = 1.0  # QUICK_SHOT giảm 50%
var damage_mult: float = 1.0  # BERSERK x2
var speed_mult: float = 1.0  # SPEED_BOOST x1.5
var invincible_remaining: float = 0.0  # INVINCIBLE / SHIELD
var multishot_remaining: float = 0.0  # MULTISHOT active
var pierce_remaining: float = 0.0  # PIERCE active
var homing_remaining: float = 0.0  # HOMING active
var life_steal_remaining: float = 0.0  # LIFE_STEAL active
var explosion_remaining: float = 0.0  # EXPLOSION chain

# === INTERNAL ===
var _throw_timer: float = 0.0
var _joystick_output: Vector2 = Vector2.ZERO
var _dart_scene: PackedScene = preload("res://scenes/endless_dart.tscn")
var _y_upper_limit: float = 380.0  # Giới hạn trên (Y nhỏ, gần giữa màn hình)
var _y_lower_limit: float = 680.0  # Giới hạn dưới (Y lớn, gần cuối màn hình)
var _fixed_x: float = 0.0  # X cố định (đường thẳng)

@onready var body_rect: ColorRect = $BodyRect
@onready var hp_bar: ProgressBar = $HpBar
@onready var shield_sprite: ColorRect = $ShieldSprite
@onready var muzzle: Marker2D = $Muzzle

func _ready():
        add_to_group("players")
        hp = max_hp
        hp_bar.max_value = max_hp
        hp_bar.value = hp
        shield_sprite.visible = false
        hp_changed.emit(hp, max_hp)

func _physics_process(delta: float):
        if not is_alive:
                return
        # Cập nhật timers skill
        _update_skill_timers(delta)
        # Di chuyển dọc trục Y dựa trên joystick (lên = -Y, xuống = +Y)
        # Chỉ cho phép đi lên (forward) + đi lùi (backward) trong khoảng giới hạn
        var move_y := 0.0
        if _joystick_output.length() > 0.1:
                # Dùng thành phần Y của joystick (âm = lên, dương = xuống)
                move_y = _joystick_output.y * move_speed * speed_mult * delta
        var new_y = global_position.y + move_y
        new_y = clamp(new_y, _y_upper_limit, _y_lower_limit)
        global_position.y = new_y
        global_position.x = _fixed_x  # Khóa X
        # Tự động ném phi tiêu lên trên theo cooldown
        _throw_timer -= delta
        if _throw_timer <= 0.0:
                _throw_darts()
                _throw_timer = base_throw_cooldown * throw_cooldown_mult

func _update_skill_timers(delta: float):
        if invincible_remaining > 0:
                invincible_remaining = max(0.0, invincible_remaining - delta)
                shield_sprite.visible = invincible_remaining > 0
        if multishot_remaining > 0:
                multishot_remaining = max(0.0, multishot_remaining - delta)
        if pierce_remaining > 0:
                pierce_remaining = max(0.0, pierce_remaining - delta)
        if homing_remaining > 0:
                homing_remaining = max(0.0, homing_remaining - delta)
        if life_steal_remaining > 0:
                life_steal_remaining = max(0.0, life_steal_remaining - delta)
        if explosion_remaining > 0:
                explosion_remaining = max(0.0, explosion_remaining - delta)

## Thiết lập joystick output (gọi từ endless_mode)
func set_joystick_output(output: Vector2):
        _joystick_output = output

## Ném phi tiêu lên trên
func _throw_darts():
        var dart_count := 1
        if multishot_remaining > 0:
                dart_count = 3
        var base_angle := -PI / 2.0  # Hướng lên trên
        for i in dart_count:
                var dart = _dart_scene.instantiate()
                var spread := 0.0
                if dart_count > 1:
                        spread = (i - (dart_count - 1) / 2.0) * 0.18
                var angle = base_angle + spread
                var dir = Vector2(cos(angle), sin(angle))
                get_parent().add_child(dart)
                dart.global_position = muzzle.global_position
                dart.setup(dir, dart_speed, dart_damage * damage_mult, self)
                # Tag dart với pierce/homing/explosion
                if pierce_remaining > 0:
                        dart.set_pierce(true)
                if homing_remaining > 0:
                        dart.set_homing(true)
                if explosion_remaining > 0:
                        dart.set_explosion(true)
        if AudioManager:
                AudioManager.play_throw()

## Nhận damage từ zombie
func take_damage(amount: float):
        if not is_alive:
                return
        if invincible_remaining > 0:
                return  # Bất tử / Khiên
        hp = max(0.0, hp - amount)
        hp_bar.value = hp
        hp_changed.emit(hp, max_hp)
        # Hit flash effect
        _flash_hit()
        if AudioManager:
                AudioManager.play_damage()
        if hp <= 0:
                _die()

func _flash_hit():
        var tween = create_tween()
        tween.tween_property(body_rect, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.08)
        tween.tween_property(body_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func _die():
        if not is_alive:
                return
        is_alive = false
        if AudioManager:
                AudioManager.play_death()
        player_died.emit()

## Hồi máu (HEAL skill)
func heal(amount: float):
        hp = min(max_hp, hp + amount)
        hp_bar.value = hp
        hp_changed.emit(hp, max_hp)
        if AudioManager:
                AudioManager.play_pickup_health()

## === SKILL ACTIVATION (gọi từ skills_hub) ===

func activate_quick_shot():
        throw_cooldown_mult = 0.5

func activate_heal():
        heal(30.0)

func activate_shield(duration: float = 3.0):
        invincible_remaining = max(invincible_remaining, duration)

func activate_multishot(duration: float = 8.0):
        multishot_remaining = duration

func activate_freeze(_duration: float = 2.0):
        # Freeze được xử lý ở endless_mode (apply cho tất cả zombie)
        pass

func activate_bomb(_radius: float = 200.0, _damage: float = 80.0):
        # Bomb được xử lý ở endless_mode
        pass

func activate_speed_boost(duration: float = 5.0):
        speed_mult = 1.5
        await get_tree().create_timer(duration).timeout
        if not is_instance_valid(self):
                return
        speed_mult = 1.0

func activate_pierce(duration: float = 8.0):
        pierce_remaining = duration

func activate_life_steal(duration: float = 10.0):
        life_steal_remaining = duration

func activate_slow_time(_duration: float = 3.0):
        # Slow time được xử lý ở endless_mode
        pass

func activate_homing(duration: float = 8.0):
        homing_remaining = duration

func activate_explosion(duration: float = 8.0):
        explosion_remaining = duration

func activate_berserk(duration: float = 5.0):
        damage_mult = 2.0
        await get_tree().create_timer(duration).timeout
        if not is_instance_valid(self):
                return
        damage_mult = 1.0

func activate_invincible(duration: float = 5.0):
        invincible_remaining = max(invincible_remaining, duration)

## Reset skill states khi bắt đầu level mới
func reset_temporary_skills():
        multishot_remaining = 0.0
        pierce_remaining = 0.0
        homing_remaining = 0.0
        life_steal_remaining = 0.0
        explosion_remaining = 0.0
        throw_cooldown_mult = 1.0
        damage_mult = 1.0
        speed_mult = 1.0
        invincible_remaining = 0.0
        if shield_sprite:
                shield_sprite.visible = false

## Khôi phục full HP (khi qua ải)
func refill_darts(bonus: int, duration: float):
        ## Pickup dart refill - heal slightly (endless mode has infinite darts)
        heal(15.0)

func full_heal():
        hp = max_hp
        hp_bar.value = hp
        hp_changed.emit(hp, max_hp)
