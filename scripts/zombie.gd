extends CharacterBody2D

## Zombie - Quái vật cho chế độ Vượt Ải (v2.5)
## - 3 loại: walker (xanh, chậm, HP thấp), runner (đỏ, nhanh, HP thấp), brute (tím sẫm, chậm, HP cao)
## - Di chuyển xuống dưới về phía player
## - Trừ damage cho player khi chạm
## - Chết khi HP <= 0, emit signal zombie_killed
## - Visual: wobble, damage flash, death animation, freeze fx, brute pulse

signal zombie_killed(zombie: Node2D)
signal zombie_reached_player(zombie: Node2D, damage: float)
signal zombie_escaped(zombie: Node2D)

enum ZombieType { WALKER, RUNNER, BRUTE }

@export var zombie_type: int = ZombieType.WALKER
@export var hp: float = 30.0
@export var max_hp: float = 30.0
@export var move_speed: float = 60.0
@export var damage: float = 15.0
@export var freeze_timer: float = 0.0  # Đóng băng
@export var slow_mult: float = 1.0  # Slow time

var is_dead: bool = false
var _player_node: Node2D = null
var _damage_cooldown: float = 0.0  # Tránh giật liên tục
var _attack_cooldown: float = 0.8  # giây giữa 2 lần cắn player
var owner_player_id: int = -1  # For dart.gd compatibility (zombies don't throw darts)

# --- Visual state ---
var _wobble_time: float = 0.0
var _damage_flash_timer: float = 0.0
var _brute_pulse_time: float = 0.0
var _base_body_color: Color = Color.WHITE
var _base_head_color: Color = Color.WHITE
var _base_glow_color: Color = Color.WHITE
var _base_arms_color: Color = Color.WHITE
var _was_frozen: bool = false

# --- Node refs ---
@onready var body_rect: ColorRect = $BodyRect
@onready var hp_bar: ProgressBar = $HpBar
@onready var eyes: ColorRect = $Eyes
@onready var arms: ColorRect = $Arms
@onready var glow_rect: ColorRect = get_node_or_null("GlowRect")
@onready var shadow_rect: ColorRect = get_node_or_null("ShadowRect")
@onready var head_rect: ColorRect = get_node_or_null("HeadRect")
@onready var mouth_rect: ColorRect = get_node_or_null("MouthRect")
@onready var wound_rect: ColorRect = get_node_or_null("WoundRect")


func _ready():
        # Groups "zombies" and "ai_players" are already set in zombie.tscn
        hp_bar.max_value = max_hp
        hp_bar.value = hp
        _apply_type_visual()


func _apply_type_visual():
        ## Apply zombie-type-specific colors, scales, and glow.
        ## Each type has a distinct look: WALKER=rotten green, RUNNER=feral red, BRUTE=dark purple.
        match zombie_type:
                ZombieType.WALKER:
                        # --- Rotten zombie green: dark, decomposed, slightly transparent ---
                        _base_body_color = Color(0.18, 0.35, 0.10, 0.95)
                        _base_head_color = Color(0.20, 0.38, 0.12, 0.95)
                        _base_arms_color = Color(0.15, 0.30, 0.08, 0.95)
                        _base_glow_color = Color(0.2, 0.5, 0.1, 0.15)
                        body_rect.color = _base_body_color
                        if head_rect: head_rect.color = _base_head_color
                        eyes.color = Color(0.85, 0.95, 0.15, 1.0)  # sickly yellow-green
                        if mouth_rect: mouth_rect.color = Color(0.08, 0.05, 0.03, 1.0)
                        if wound_rect: wound_rect.color = Color(0.10, 0.20, 0.05, 0.9)
                        arms.color = _base_arms_color
                        if glow_rect: glow_rect.color = _base_glow_color
                        if shadow_rect: shadow_rect.color = Color(0.0, 0.0, 0.0, 0.3)
                        # Normal size
                        body_rect.scale = Vector2(1.0, 1.0)
                        if head_rect: head_rect.scale = Vector2(1.0, 1.0)

                ZombieType.RUNNER:
                        # --- Feral red: intense, glowing, lean ---
                        _base_body_color = Color(0.60, 0.10, 0.06, 1.0)
                        _base_head_color = Color(0.55, 0.08, 0.04, 1.0)
                        _base_arms_color = Color(0.50, 0.08, 0.04, 1.0)
                        _base_glow_color = Color(0.8, 0.15, 0.05, 0.25)
                        body_rect.color = _base_body_color
                        if head_rect: head_rect.color = _base_head_color
                        eyes.color = Color(1.0, 0.20, 0.05, 1.0)  # glowing red-orange
                        if mouth_rect: mouth_rect.color = Color(0.20, 0.02, 0.02, 1.0)
                        if wound_rect: wound_rect.color = Color(0.30, 0.02, 0.02, 0.9)
                        arms.color = _base_arms_color
                        if glow_rect: glow_rect.color = _base_glow_color
                        if shadow_rect: shadow_rect.color = Color(0.0, 0.0, 0.0, 0.25)
                        # Leaner, slightly smaller
                        body_rect.scale = Vector2(0.85, 0.95)
                        if head_rect: head_rect.scale = Vector2(0.85, 0.9)

                ZombieType.BRUTE:
                        # --- Massive dark purple: intimidating, pulsing glow ---
                        _base_body_color = Color(0.12, 0.04, 0.20, 1.0)
                        _base_head_color = Color(0.10, 0.03, 0.18, 1.0)
                        _base_arms_color = Color(0.10, 0.03, 0.16, 1.0)
                        _base_glow_color = Color(0.4, 0.1, 0.6, 0.2)
                        body_rect.color = _base_body_color
                        if head_rect: head_rect.color = _base_head_color
                        eyes.color = Color(0.85, 0.12, 0.65, 1.0)  # glowing magenta
                        if mouth_rect: mouth_rect.color = Color(0.06, 0.02, 0.08, 1.0)
                        if wound_rect: wound_rect.color = Color(0.08, 0.02, 0.12, 0.9)
                        arms.color = _base_arms_color
                        if glow_rect: glow_rect.color = _base_glow_color
                        if shadow_rect: shadow_rect.color = Color(0.0, 0.0, 0.0, 0.4)
                        # Massive
                        body_rect.scale = Vector2(1.4, 1.3)
                        if head_rect: head_rect.scale = Vector2(1.3, 1.2)


## Khởi tạo zombie với stats theo level
func setup(type: int, p_max_hp: float, p_speed: float, p_damage: float, player_node: Node2D):
        zombie_type = type
        max_hp = p_max_hp
        hp = p_max_hp
        move_speed = p_speed
        damage = p_damage
        _player_node = player_node
        # Cập nhật lại visual + hp_bar với stats mới (vì _ready() chạy với default)
        _apply_type_visual()
        if hp_bar:
                hp_bar.max_value = max_hp
                hp_bar.value = hp


func _physics_process(delta: float):
        if is_dead:
                return

        # Cập nhật cooldown cắn player
        if _damage_cooldown > 0:
                _damage_cooldown -= delta

        # ===================== WOBBLE ANIMATION =====================
        # Shambling S-shape movement: different speed per type for personality
        _wobble_time += delta
        var wobble_speed := 5.0
        var wobble_amp_x := 2.5
        var wobble_amp_rot := 0.07
        match zombie_type:
                ZombieType.WALKER:
                        wobble_speed = 4.5   # slow, shambling
                        wobble_amp_x = 2.5
                        wobble_amp_rot = 0.07
                ZombieType.RUNNER:
                        wobble_speed = 8.0   # fast, jerky
                        wobble_amp_x = 3.0
                        wobble_amp_rot = 0.10
                ZombieType.BRUTE:
                        wobble_speed = 3.0   # heavy, slow sway
                        wobble_amp_x = 2.0
                        wobble_amp_rot = 0.04

        var wobble_x = sin(_wobble_time * wobble_speed) * wobble_amp_x
        var wobble_rot = sin(_wobble_time * wobble_speed * 1.3) * wobble_amp_rot

        # Apply wobble to body parts (head leads, body follows, arms swing opposite)
        body_rect.position.x = wobble_x
        body_rect.rotation = wobble_rot
        if head_rect:
                head_rect.position.x = wobble_x * 1.15
                head_rect.rotation = wobble_rot * 0.6
        eyes.position.x = wobble_x * 1.15
        if mouth_rect:
                mouth_rect.position.x = wobble_x * 1.15
        arms.position.x = wobble_x * 0.8
        arms.rotation = sin(_wobble_time * wobble_speed * 0.9 + 1.5) * wobble_amp_rot * 1.5  # arms swing offset
        if wound_rect:
                wound_rect.position.x = wobble_x
        if glow_rect:
                glow_rect.position.x = wobble_x * 0.5

        # ===================== FREEZE / SLOW =====================
        var effective_speed = move_speed
        if freeze_timer > 0:
                freeze_timer -= delta
                effective_speed = 0.0
                _was_frozen = true

                # --- Ice crystal visual effect: blue tint + slight scale up ---
                var ice_modulate = Color(0.50, 0.78, 1.0, 1.0)
                body_rect.modulate = ice_modulate
                if head_rect: head_rect.modulate = ice_modulate
                arms.modulate = ice_modulate
                eyes.modulate = Color(0.7, 0.9, 1.0, 1.0)  # eyes get icy too

                if glow_rect:
                        glow_rect.color = Color(0.3, 0.65, 1.0, 0.35)  # blue glow when frozen
                if shadow_rect:
                        shadow_rect.color = Color(0.1, 0.2, 0.35, 0.35)  # bluish shadow

                # Slight frozen expansion (ice crystals growing)
                var frozen_pulse = 1.0 + sin(_wobble_time * 1.5) * 0.02
                match zombie_type:
                        ZombieType.WALKER:
                                body_rect.scale = Vector2(1.05, 1.05) * frozen_pulse
                        ZombieType.RUNNER:
                                body_rect.scale = Vector2(0.90, 1.0) * frozen_pulse
                        ZombieType.BRUTE:
                                body_rect.scale = Vector2(1.45, 1.35) * frozen_pulse
        else:
                # --- Restore from freeze ---
                if _was_frozen:
                        _was_frozen = false
                        body_rect.modulate = Color(1, 1, 1, 1)
                        if head_rect: head_rect.modulate = Color(1, 1, 1, 1)
                        arms.modulate = Color(1, 1, 1, 1)
                        eyes.modulate = Color(1, 1, 1, 1)
                        if glow_rect: glow_rect.color = _base_glow_color
                        if shadow_rect: shadow_rect.color = Color(0, 0, 0, 0.3)
                        # Restore normal scale
                        match zombie_type:
                                ZombieType.WALKER:
                                        body_rect.scale = Vector2(1.0, 1.0)
                                        if head_rect: head_rect.scale = Vector2(1.0, 1.0)
                                ZombieType.RUNNER:
                                        body_rect.scale = Vector2(0.85, 0.95)
                                        if head_rect: head_rect.scale = Vector2(0.85, 0.9)
                                ZombieType.BRUTE:
                                        body_rect.scale = Vector2(1.4, 1.3)
                                        if head_rect: head_rect.scale = Vector2(1.3, 1.2)

        effective_speed *= slow_mult

        # ===================== BRUTE PULSING GLOW =====================
        if zombie_type == ZombieType.BRUTE and freeze_timer <= 0:
                _brute_pulse_time += delta
                var pulse_alpha = 0.15 + sin(_brute_pulse_time * 3.0) * 0.12
                if glow_rect:
                        glow_rect.color = Color(_base_glow_color.r, _base_glow_color.g, _base_glow_color.b, pulse_alpha)
                # Subtle body scale pulse (breathing/heaving effect)
                var scale_pulse = 1.0 + sin(_brute_pulse_time * 2.5) * 0.025
                body_rect.scale = Vector2(1.4 * scale_pulse, 1.3 * scale_pulse)
                if head_rect:
                        head_rect.scale = Vector2(1.3 * scale_pulse, 1.2 * scale_pulse)

        # ===================== DAMAGE FLASH =====================
        if _damage_flash_timer > 0:
                _damage_flash_timer -= delta
                var flash_intensity = clamp(_damage_flash_timer / 0.15, 0.0, 1.0)
                if freeze_timer <= 0:  # don't override freeze tint
                        # Bright warm flash that fades: white-yellow → normal
                        var flash_mod = Color(
                                1.0 + flash_intensity * 1.8,
                                1.0 + flash_intensity * 0.8,
                                1.0 + flash_intensity * 0.3,
                                1.0
                        )
                        body_rect.modulate = flash_mod
                        if head_rect: head_rect.modulate = flash_mod
                        arms.modulate = Color(
                                1.0 + flash_intensity * 1.2,
                                1.0 + flash_intensity * 0.4,
                                1.0 + flash_intensity * 0.2,
                                1.0
                        )
                        # Eyes flash extra bright
                        eyes.modulate = Color(
                                1.0 + flash_intensity * 2.0,
                                1.0 + flash_intensity * 1.5,
                                1.0 + flash_intensity * 0.5,
                                1.0
                        )
        elif freeze_timer <= 0 and not _was_frozen:
                # Ensure modulate is clean when no flash and no freeze
                body_rect.modulate = Color(1, 1, 1, 1)
                if head_rect: head_rect.modulate = Color(1, 1, 1, 1)
                arms.modulate = Color(1, 1, 1, 1)
                eyes.modulate = Color(1, 1, 1, 1)

        # ===================== MOVEMENT =====================
        # Lái nhẹ về phía player X (cho tự nhiên)
        if is_instance_valid(_player_node):
                var dx = _player_node.global_position.x - global_position.x
                global_position.x += clamp(dx, -effective_speed * delta, effective_speed * delta) * 0.5
        # Di chuyển xuống
        global_position.y += effective_speed * delta

        # Kiểm tra chạm player
        if is_instance_valid(_player_node) and _damage_cooldown <= 0:
                var dist = global_position.distance_to(_player_node.global_position)
                if dist < 40.0:
                        # Cắn player
                        if _player_node.has_method("take_damage"):
                                _player_node.call("take_damage", damage)
                        _damage_cooldown = _attack_cooldown
                        if AudioManager:
                                AudioManager.play_hit()

        # Kiểm tra đi quá màn hình (player né được)
        if global_position.y > 800:
                # Zombie vượt qua → emit escaped signal để endless_mode có thể track
                zombie_escaped.emit(self)
                _queue_free_safe()


## Nhận damage từ dart
func take_damage(amount: float):
        if is_dead:
                return
        hp = max(0.0, hp - amount)
        hp_bar.value = hp
        # --- Damage flash effect ---
        _damage_flash_timer = 0.15
        # v2.8: Spawn floating damage number
        _spawn_damage_number(amount)
        if hp <= 0:
                _die()

## v2.8: Spawn floating damage number
func _spawn_damage_number(amount: float):
        var label = Label.new()
        label.add_theme_font_size_override("font_size", 18)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        var is_crit = amount >= 60.0
        if is_crit:
                label.text = "CRIT! %d" % int(amount)
                label.add_theme_font_size_override("font_size", 24)
                label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
        else:
                label.text = "%d" % int(amount)
                label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
        var angle = randf_range(-0.6, 0.6) - PI / 2.0
        var vel = Vector2(cos(angle), sin(angle)) * randf_range(40, 80)
        get_parent().add_child(label)
        label.global_position = global_position + Vector2(randf_range(-10, 10), -20)
        label.z_index = 10
        # Animate: float up + fade
        var tween = create_tween()
        tween.tween_property(label, "position", label.position + vel, 0.8)
        tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
        tween.tween_callback(label.queue_free)


func _die():
        if is_dead:
                return
        is_dead = true
        if AudioManager:
                AudioManager.play_kill()
        zombie_killed.emit(self)

        # --- Dramatic death animation ---
        # Phase 0: Flash bright (instant visual burst)
        body_rect.color = Color(1.0, 0.9, 0.6)
        if head_rect: head_rect.color = Color(1.0, 0.95, 0.7)
        eyes.color = Color(1.0, 1.0, 1.0)  # eyes go white
        if mouth_rect: mouth_rect.color = Color(0.5, 0.1, 0.05)  # bloody mouth
        if glow_rect: glow_rect.color = Color(1.0, 0.8, 0.3, 0.5)  # bright death glow
        if wound_rect: wound_rect.color = Color(0.5, 0.05, 0.0)  # wound bleeds

        # Reset wobble offsets so death anim looks clean
        _reset_visual_positions()

        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)

        # Phase 1: Expand slightly (burst effect) — 0.1s
        tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.1).set_trans(Tween.TRANS_QUAD)

        # Phase 2: Body turns dark/bloody while starting to collapse — parallel 0.2s
        tween.parallel().tween_property(body_rect, "color", Color(0.3, 0.08, 0.03), 0.25)
        if head_rect:
                tween.parallel().tween_property(head_rect, "color", Color(0.25, 0.06, 0.02), 0.25)

        # Phase 3: Splat collapse — scale X wide, Y flat — 0.25s
        tween.tween_property(self, "scale", Vector2(1.7, 0.25), 0.3).set_trans(Tween.TRANS_BOUNCE)

        # Phase 4: Glow expands and fades — parallel
        if glow_rect:
                tween.parallel().tween_property(glow_rect, "color:a", 0.0, 0.35)

        # Phase 5: Fade out entirely — 0.3s
        tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR)

        # Phase 6: Remove from scene
        tween.tween_callback(_queue_free_safe)


func _reset_visual_positions():
        ## Zero out wobble offsets on all visual rects for clean death anim.
        body_rect.position.x = 0
        body_rect.rotation = 0
        if head_rect:
                head_rect.position.x = 0
                head_rect.rotation = 0
        eyes.position.x = 0
        if mouth_rect:
                mouth_rect.position.x = 0
        arms.position.x = 0
        arms.rotation = 0
        if wound_rect:
                wound_rect.position.x = 0
        if glow_rect:
                glow_rect.position.x = 0


func _queue_free_safe():
        if is_instance_valid(self):
                queue_free()


## Đóng băng zombie
func freeze(duration: float):
        freeze_timer = max(freeze_timer, duration)


## Slow zombie (slow_time)
func set_slow(mult: float):
        slow_mult = mult


func clear_slow():
        slow_mult = 1.0


## Force kill (NUKE skill)
func force_kill():
        _die()
