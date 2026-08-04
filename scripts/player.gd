extends CharacterBody2D

## Player - Nhân vật người chơi (v2.1)
## - Hỗ trợ CharacterData (chọn nhân vật, bonus chỉ số)
## - Max HP scale theo size
## - Hồi 10% max HP khi ăn đối thủ
## - 4 kỹ năng chủ động: Dash, Shield, Multishot, Crown (v2.1)
## - Joystick ảo + mobile controls
## - Hiệu ứng: hit flash, level-up, floating damage text
## - FIX: Không bị khóa di chuyển khi ném phi tiêu
##
## v2.1 NEW:
## - Classic mode (Hieu Louis): spawn glitch 3s bất tử + code hacker effect
## - Crown skill: ghim 5 đối thủ, +50% điểm, CD 50s
## - SMG reward sau 50 kills: 20s tiểu liên vô hạn
## - Vòng tròn đỏ highlight đối thủ khi aim trúng
## - Vô hạn đạn, không cooldown bắn (cho Classic)
## - HP bar dài hơn cho Classic

const KILLER_NONE := ""
const CLASSIC_FILE := "char_hieu_louis_classic"

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var aim_line: Line2D = $AimLine
@onready var hp_bar: ProgressBar = $HpBar
@onready var name_label: Label = $NameLabel
@onready var size_indicator: Label = $SizeIndicator
@onready var teleport_ready_indicator: Sprite2D = $TeleportReadyIndicator
@onready var teleport_particles: CPUParticles2D = $TeleportParticles
@onready var death_particles: CPUParticles2D = $DeathParticles
@onready var shield_sprite: Sprite2D = $ShieldSprite
@onready var skill_cooldown_label: Label = $SkillCooldownLabel

var is_alive: bool = true
var is_aiming: bool = false
var aim_direction: Vector2 = Vector2.RIGHT
var aim_power: float = 0.5
var aim_start_pos: Vector2 = Vector2.ZERO
var aim_current_pos: Vector2 = Vector2.ZERO
var all_darts: Array = []
var player_id: int = 0
var player_name: String = "Player"
var current_hp: float
var last_teleport_time: float = 0.0
var teleport_cooldown: float = 0.15
var is_respawning: bool = false
var joystick_ref: Control = null
var last_killer_name: String = KILLER_NONE
var dart_bonus: int = 0
var dart_bonus_timer: float = 0.0
var aim_touch_index: int = -1
const AIM_MODE_MOBILE_SENTINEL: int = -2

# === KỸ NĂNG CHỦ ĐỘNG ===
var skill_cooldowns: Dictionary = {}
var shield_active: bool = false
var shield_timer: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var multishot_ready: bool = false

# === CHARACTER DATA (v1.2) ===
var char_hp_bonus: float = 0.0
var char_speed_bonus: float = 0.0
var char_dart_bonus: int = 0
var char_skill_bonus: String = ""

# === v2.1: CLASSIC MODE ===
var is_classic_mode: bool = false
var spawn_invulnerable_timer: float = 0.0  # 3s bất tử khi spawn
var spawn_glitch_timer: float = 0.0
var is_spawn_invulnerable: bool = false

# === v2.1: CROWN SKILL ===
const CROWN_COOLDOWN: float = 50.0
const CROWN_TARGET_COUNT: int = 5
const CROWN_SCORE_BONUS: float = 0.5  # +50% điểm
var crown_cooldown_timer: float = 0.0
var crown_active: bool = false  # Đang ghim (auto-target darts)
var crown_active_timer: float = 0.0  # Thời gian ghim còn lại
var pinned_targets: Array = []  # Các đối thủ bị ghim
var crown_score_multiplier_active: bool = false

# === v2.1: SMG REWARD (50 KILLS) ===
const SMG_KILL_THRESHOLD: int = 50
const SMG_DURATION: float = 20.0
const SMG_FIRE_INTERVAL: float = 0.08  # Very fast fire
var smg_active: bool = false
var smg_timer: float = 0.0
var smg_fire_timer: float = 0.0
var smg_announced: bool = false  # Đã thông báo lần đầu chưa

# === v2.1: TARGET HIGHLIGHT ===
var highlighted_target: Node2D = null  # Đối thủ đang được highlight (vòng tròn đỏ)
var target_highlight: Node2D = null  # Node vẽ vòng tròn

var dart_scene: PackedScene = preload("res://scenes/dart.tscn")

signal dart_thrown(dart: Node2D)
signal player_died(player: CharacterBody2D)
signal player_respawned(player: CharacterBody2D)
signal teleport_performed(player: CharacterBody2D, to_position: Vector2)
signal skill_activated(skill_id: int)
signal skill_cooldown_updated(skill_id: int, remaining: float)
signal crown_skill_activated(targets: Array)
signal smg_activated()
signal smg_expired()

func _ready():
        # Load character data
        _apply_character_data()

        # Khởi tạo skill cooldowns (enum values chỉ sẵn sàng lúc runtime)
        skill_cooldowns = {
                GameManager.Skill.DASH: 0.0,
                GameManager.Skill.SHIELD: 0.0,
                GameManager.Skill.MULTISHOT: 0.0,
        }

        current_hp = GameManager.player_max_hp
        _update_hp_bar()
        _update_visual_size()
        _update_size_indicator()
        aim_line.visible = false
        teleport_ready_indicator.visible = false
        collision_layer = 1
        collision_mask = 4 | 8 | 16

        # Load character sprite
        var sprite_path = CharacterData.get_sprite_path(CharacterData.selected_character_id)
        var tex = load(sprite_path)
        if tex:
                sprite.texture = tex
        _apply_quality_settings()

        # Shield sprite setup
        if shield_sprite:
                shield_sprite.visible = false
        if skill_cooldown_label:
                skill_cooldown_label.visible = false

        # Connect HP changed signal
        if not GameManager.player_hp_changed.is_connected(_on_player_hp_changed):
                GameManager.player_hp_changed.connect(_on_player_hp_changed)

        # v2.1: Setup Classic mode
        if is_classic_mode:
                _start_spawn_invulnerability()
                # HP bar dài hơn cho Classic
                if hp_bar:
                        hp_bar.custom_minimum_size = Vector2(80, 6)
                        hp_bar.size = Vector2(80, 6)

        # v2.1: Tạo target highlight node
        _create_target_highlight()

func _apply_character_data():
        ## Áp dụng bonus chỉ số từ nhân vật đã chọn
        var char_data = CharacterData.get_selected()
        char_hp_bonus = char_data["hp_bonus"]
        char_speed_bonus = char_data["speed_bonus"]
        char_dart_bonus = char_data["dart_bonus"]
        char_skill_bonus = char_data["skill_bonus"]
        # v2.1: Classic mode detection
        is_classic_mode = char_data.has("file") and char_data["file"] == CLASSIC_FILE

func set_joystick(joy: Control):
        joystick_ref = joy

func _apply_quality_settings():
        var mult = SettingsManager.get_particle_multiplier()
        teleport_particles.amount = max(1, int(20 * mult))
        death_particles.amount = max(1, int(30 * mult))
        if mult <= 0:
                teleport_particles.emitting = false
                death_particles.emitting = false

func _on_player_hp_changed(hp: float, max_hp: float):
        current_hp = hp
        _update_hp_bar()

func _physics_process(delta):
        if not is_alive:
                return

        # Cập nhật skill cooldowns
        _update_skills(delta)

        # v2.1: Cập nhật timers
        _update_classic_timers(delta)
        _update_crown(delta)
        _update_smg(delta)
        _update_target_highlight()

        # FIX: Di chuyển LUÔN hoạt động, kể cả khi đang aiming
        var input_dir = Vector2.ZERO
        if not is_dashing:
                if Input.is_action_pressed("move_up"):
                        input_dir.y -= 1
                if Input.is_action_pressed("move_down"):
                        input_dir.y += 1
                if Input.is_action_pressed("move_left"):
                        input_dir.x -= 1
                if Input.is_action_pressed("move_right"):
                        input_dir.x += 1
                if joystick_ref and joystick_ref.is_active():
                        input_dir += joystick_ref.get_direction()
                if input_dir != Vector2.ZERO:
                        input_dir = input_dir.normalized()
                        # Apply character speed bonus
                        velocity = input_dir * (GameManager.walk_speed + char_speed_bonus)
                else:
                        velocity = Vector2.ZERO
        else:
                var t = 1.0 - (dash_timer / GameManager.skill_dash_duration)
                var speed_mult = 4.0 * (1.0 - t * 0.5)
                velocity = dash_direction * (GameManager.walk_speed + char_speed_bonus) * speed_mult

        move_and_slide()
        position.x = clamp(position.x, 20, GameManager.map_size.x - 20)
        position.y = clamp(position.y, 20, GameManager.map_size.y - 20)

        # Ngoài vòng bo
        if not GameManager.is_in_zone(position):
                var dmg = GameManager.get_zone_damage(delta)
                var died = GameManager.take_damage(dmg)
                if died:
                        last_killer_name = "Vòng Bo"
                        _die()

        if dart_bonus > 0:
                dart_bonus_timer -= delta
                if dart_bonus_timer <= 0:
                        dart_bonus = 0

        _update_teleport_indicator()
        _update_shield_visual(delta)

        # v2.1: SMG auto-fire khi active
        if smg_active and is_alive:
                smg_fire_timer -= delta
                if smg_fire_timer <= 0:
                        smg_fire_timer = SMG_FIRE_INTERVAL
                        _fire_smg()

func _update_skills(delta):
        for skill in [GameManager.Skill.DASH, GameManager.Skill.SHIELD, GameManager.Skill.MULTISHOT]:
                if skill_cooldowns[skill] > 0:
                        skill_cooldowns[skill] = max(0.0, skill_cooldowns[skill] - delta)
                        skill_cooldown_updated.emit(skill, skill_cooldowns[skill])

        if shield_active:
                shield_timer -= delta
                if shield_timer <= 0:
                        _deactivate_shield()

        if is_dashing:
                dash_timer -= delta
                if dash_timer <= 0:
                        is_dashing = false

func _update_shield_visual(delta):
        if shield_sprite and shield_sprite.visible:
                shield_sprite.rotation += delta * 2.0
                var pulse = 0.85 + 0.15 * sin(Time.get_ticks_msec() / 100.0)
                shield_sprite.scale = Vector2(pulse, pulse) * (GameManager.player_size / GameManager.initial_player_radius) * 1.6

func _input(event: InputEvent):
        if not is_alive:
                return

        # Desktop: right-click slingshot
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
                if event.pressed:
                        _start_aim_desktop(event.global_position)
                else:
                        _throw_dart_desktop(event.global_position)

        if event is InputEventMouseMotion and is_aiming:
                if aim_touch_index == -1:
                        aim_current_pos = event.global_position
                        _calc_and_update_aim_from_slingshot()

        if event.is_action_pressed("teleport"):
                _teleport_to_dart()
        # Skills (PC)
        if event.is_action_pressed("skill_dash"):
                activate_skill(GameManager.Skill.DASH)
        if event.is_action_pressed("skill_shield"):
                activate_skill(GameManager.Skill.SHIELD)
        if event.is_action_pressed("skill_multishot"):
                activate_skill(GameManager.Skill.MULTISHOT)
        # v2.1: Crown skill (PC key C)
        if event.is_action_pressed("skill_crown"):
                activate_crown_skill()

# === SKILLS ===
func activate_skill(skill: int) -> bool:
        if not is_alive:
                return false
        if skill_cooldowns[skill] > 0:
                AudioManager.play_error()
                return false
        match skill:
                GameManager.Skill.DASH:
                        return _do_dash()
                GameManager.Skill.SHIELD:
                        return _do_shield()
                GameManager.Skill.MULTISHOT:
                        return _do_multishot()
        return false

func _do_dash() -> bool:
        var dir = Vector2.ZERO
        if Input.is_action_pressed("move_up"): dir.y -= 1
        if Input.is_action_pressed("move_down"): dir.y += 1
        if Input.is_action_pressed("move_left"): dir.x -= 1
        if Input.is_action_pressed("move_right"): dir.x += 1
        if joystick_ref and joystick_ref.is_active():
                dir = joystick_ref.get_direction()
        if dir == Vector2.ZERO:
                dir = aim_direction if aim_direction != Vector2.ZERO else Vector2.RIGHT
        dir = dir.normalized()
        dash_direction = dir
        is_dashing = true
        dash_timer = GameManager.skill_dash_duration

        # Character bonus: Dash cooldown reduced for assassin
        var cd = GameManager.skill_dash_cooldown
        if char_skill_bonus == "dash":
                cd *= 0.7  # 30% reduction
        # v2.1: Classic mode - dash cooldown giảm 50%
        if is_classic_mode:
                cd *= 0.5
        skill_cooldowns[GameManager.Skill.DASH] = cd

        _spawn_dash_effect(dir)
        AudioManager.play_whoosh()
        skill_activated.emit(GameManager.Skill.DASH)
        GameManager.skill_used.emit(player_id, "dash")
        return true

func _do_shield() -> bool:
        shield_active = true
        # Character bonus: Shield longer for brawler
        var duration = GameManager.skill_shield_duration
        if char_skill_bonus == "shield":
                duration *= 1.5
        # v2.1: Classic mode - shield duration gấp 3
        if is_classic_mode:
                duration *= 3.0
        shield_timer = duration
        skill_cooldowns[GameManager.Skill.SHIELD] = GameManager.skill_shield_cooldown
        if shield_sprite:
                shield_sprite.visible = true
        AudioManager.play_powerup()
        _spawn_shield_effect()
        skill_activated.emit(GameManager.Skill.SHIELD)
        GameManager.skill_used.emit(player_id, "shield")
        return true

func _deactivate_shield():
        shield_active = false
        if shield_sprite:
                shield_sprite.visible = false

func _do_multishot() -> bool:
        multishot_ready = true
        skill_cooldowns[GameManager.Skill.MULTISHOT] = GameManager.skill_multishot_cooldown
        AudioManager.play_powerup()
        _spawn_buff_effect(Color(1.0, 0.6, 0.2))
        skill_activated.emit(GameManager.Skill.MULTISHOT)
        GameManager.skill_used.emit(player_id, "multishot")
        return true

func is_shield_active() -> bool:
        return shield_active or is_spawn_invulnerable  # v2.1: spawn invulnerable cũng block damage

# === v2.1: CROWN SKILL ===
func activate_crown_skill() -> bool:
        if not is_alive:
                return false
        if not is_classic_mode:
                AudioManager.play_error()
                return false
        if crown_cooldown_timer > 0:
                AudioManager.play_error()
                _spawn_floating_text("Crown: %.1fs" % crown_cooldown_timer, Color(1.0, 0.6, 0.2), global_position)
                return false

        # Tìm 5 đối thủ gần nhất
        var targets = _find_nearest_enemies(CROWN_TARGET_COUNT)
        if targets.size() == 0:
                AudioManager.play_error()
                _spawn_floating_text("Không có đối thủ!", Color(1.0, 0.3, 0.3), global_position)
                return false

        pinned_targets = targets
        crown_active = true
        crown_active_timer = 8.0  # 8 giây ghim
        crown_cooldown_timer = CROWN_COOLDOWN
        crown_score_multiplier_active = true  # +50% score trong khi crown active

        # Hiệu ứng ghim: spawn dart nhắm thẳng vào mỗi đối thủ
        for target in targets:
                if is_instance_valid(target):
                        var dir = (target.global_position - global_position).normalized()
                        _spawn_single_dart(dir, 1.0)
                        _spawn_crown_pin_effect(target.global_position)

        AudioManager.play_powerup()
        AudioManager.play_achievement()
        _spawn_buff_effect(Color(1.0, 0.85, 0.2))
        _spawn_floating_text("CROWN: +50%% SCORE!" % [], Color(1.0, 0.85, 0.2), global_position)
        crown_skill_activated.emit(targets)
        GameManager.skill_used.emit(player_id, "crown")
        return true

func _find_nearest_enemies(count: int) -> Array:
        var enemies = []
        # Tìm AI players
        for ai in get_tree().get_nodes_in_group("ai_players"):
                if is_instance_valid(ai) and ai.is_alive:
                        var dist = global_position.distance_to(ai.global_position)
                        enemies.append({"node": ai, "dist": dist})
        # Tìm remote players (online)
        for rp in get_tree().get_nodes_in_group("remote_players"):
                if is_instance_valid(rp):
                        var dist = global_position.distance_to(rp.global_position)
                        enemies.append({"node": rp, "dist": dist})
        # Sort theo khoảng cách
        enemies.sort_custom(func(a, b): return a["dist"] < b["dist"])
        # Lấy `count` phần tử đầu
        var result = []
        for i in range(min(count, enemies.size())):
                result.append(enemies[i]["node"])
        return result

func _update_crown(delta: float):
        if crown_cooldown_timer > 0:
                crown_cooldown_timer = max(0.0, crown_cooldown_timer - delta)
        if crown_active:
                crown_active_timer -= delta
                if crown_active_timer <= 0:
                        crown_active = false
                        pinned_targets.clear()
                else:
                        # Xóa targets đã chết/invalid
                        var valid = []
                        for t in pinned_targets:
                                if is_instance_valid(t):
                                        if "is_alive" in t and t.is_alive:
                                                valid.append(t)
                                        elif "alive" in t and t.alive:
                                                valid.append(t)
                        pinned_targets = valid

func _spawn_crown_pin_effect(pos: Vector2):
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.9
        particles.amount = max(1, int(30 * SettingsManager.get_particle_multiplier()))
        particles.lifetime = 0.8
        particles.direction = Vector2(0, -1)
        particles.spread = 180
        particles.initial_velocity_min = 50
        particles.initial_velocity_max = 200
        particles.gravity = Vector2(0, -50)
        particles.scale_amount_min = 3
        particles.scale_amount_max = 7
        particles.color = Color(1.0, 0.85, 0.2, 0.95)
        get_parent().add_child(particles)
        particles.global_position = pos
        get_tree().create_timer(1.2).timeout.connect(particles.queue_free)

# === v2.1: CLASSIC SPAWN INVULNERABILITY ===
func _start_spawn_invulnerability():
        is_spawn_invulnerable = true
        spawn_invulnerable_timer = 3.0
        spawn_glitch_timer = 3.0
        _spawn_glitch_effect()

func _update_classic_timers(delta: float):
        if is_spawn_invulnerable:
                spawn_invulnerable_timer -= delta
                # Glitch hiệu ứng
                spawn_glitch_timer -= delta
                if spawn_glitch_timer <= 0:
                        _spawn_glitch_effect()
                        spawn_glitch_timer = 0.15  # Glitch mỗi 0.15s
                if spawn_invulnerable_timer <= 0:
                        is_spawn_invulnerable = false
                        if sprite:
                                sprite.modulate = Color(1, 1, 1, 1)

func _spawn_glitch_effect():
        if not sprite:
                return
        # Random glitch offset + color shift
        var glitch_offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
        var tween = create_tween()
        tween.set_parallel(true)
        # RGB split effect
        var r_offset = Vector2(randf_range(-4, 4), 0)
        var g_offset = Vector2(randf_range(-4, 4), 0)
        tween.tween_property(sprite, "position", glitch_offset, 0.05)
        tween.tween_property(sprite, "modulate", Color(randf(), randf(), randf(), 1.0).lerp(Color(0, 1, 0.5), 0.5), 0.05)
        tween.chain().tween_property(sprite, "position", Vector2.ZERO, 0.05)
        tween.chain().tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.05)
        # Spawn floating code lines (hacker effect)
        _spawn_code_line_effect()

func _spawn_code_line_effect():
        # Tạo các dòng code "hacker" bay quanh player
        var code_snippets = [
                "01101001", "EXE", "ROOT", "0xCC", "BREACH", "ACCESS",
                "01", "10", "11", "00", "0xDEAD", "0xBEEF", "ROOTED",
                "HACK", "BYPASS", "GRANTED", "SYS", "KERN", "0x90",
        ]
        for i in range(3):
                var label = Label.new()
                label.text = code_snippets[randi() % code_snippets.size()]
                label.add_theme_color_override("font_color", Color(0, 1, 0.5, 0.9))
                label.add_theme_font_size_override("font_size", 10)
                label.z_index = 100
                label.position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
                get_parent().add_child(label)
                var tween = label.create_tween()
                tween.set_parallel(true)
                var end_pos = label.position + Vector2(randf_range(-20, 20), randf_range(-30, -60))
                tween.tween_property(label, "position", end_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tween.tween_property(label, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
                tween.chain().tween_callback(label.queue_free)

# === v2.1: SMG REWARD (50 KILLS) ===
func _check_smg_reward():
        if is_classic_mode and not smg_announced and GameManager.player_kills >= SMG_KILL_THRESHOLD:
                smg_announced = true
                _activate_smg()

func _activate_smg():
        smg_active = true
        smg_timer = SMG_DURATION
        smg_fire_timer = 0.0
        AudioManager.play_powerup()
        AudioManager.play_achievement()
        _spawn_buff_effect(Color(1.0, 0.4, 0.2))
        _spawn_floating_text("TIỂU LIÊN VÔ HẠN!", Color(1.0, 0.4, 0.2), global_position)
        smg_activated.emit()

func _update_smg(delta: float):
        if smg_active:
                smg_timer -= delta
                if smg_timer <= 0:
                        smg_active = false
                        _spawn_floating_text("Hết SMG", Color(0.6, 0.6, 0.6), global_position)
                        smg_expired.emit()

func _fire_smg():
        # Bắn phi tiêu nhanh về hướng aim
        var dir = aim_direction
        if dir == Vector2.ZERO:
                # Tìm đối thủ gần nhất nếu không có aim
                var enemies = _find_nearest_enemies(1)
                if enemies.size() > 0:
                        dir = (enemies[0].global_position - global_position).normalized()
                else:
                        dir = Vector2.RIGHT
        _spawn_single_dart(dir, 0.7)  # Power thấp hơn để bắn nhanh
        # SMG không giới hạn đạn, không tăng all_darts (để không fill up)

# === v2.1: TARGET HIGHLIGHT ===
func _create_target_highlight():
        # Tạo một Node2D để vẽ vòng tròn đỏ quanh đối thủ được highlight
        target_highlight = Node2D.new()
        target_highlight.name = "TargetHighlight"
        target_highlight.z_index = 50
        # Vẽ vòng tròn bằng _draw
        var draw_script = load("res://scripts/target_highlight.gd")
        if draw_script:
                target_highlight.set_script(draw_script)
        get_parent().add_child(target_highlight)
        target_highlight.visible = false

func _update_target_highlight():
        if not is_aiming or not target_highlight:
                if target_highlight:
                        target_highlight.visible = false
                highlighted_target = null
                return
        # Tìm đối thủ gần nhất với đường ngắm
        var best_target = null
        var best_dist = 60.0  # Đường ngắm cách bao nhiêu px thì coi như trúng
        # Check AI players
        for ai in get_tree().get_nodes_in_group("ai_players"):
                if not is_instance_valid(ai) or not ("is_alive" in ai) or not ai.is_alive:
                        continue
                var to_target = ai.global_position - global_position
                var dist = to_target.length()
                if dist > 600:  # Giới hạn tầm
                        continue
                var dir_to_target = to_target.normalized()
                var dot = dir_to_target.dot(aim_direction.normalized())
                if dot > 0.95:  # Đối thủ trong đường ngắm
                        # Tính khoảng cách từ đường ngắm
                        var perp_dist = (to_target - aim_direction.normalized() * dist).length()
                        if perp_dist < best_dist:
                                best_dist = perp_dist
                                best_target = ai
        # Check remote players
        for rp in get_tree().get_nodes_in_group("remote_players"):
                if not is_instance_valid(rp):
                        continue
                var to_target = rp.global_position - global_position
                var dist = to_target.length()
                if dist > 600:
                        continue
                var dir_to_target = to_target.normalized()
                var dot = dir_to_target.dot(aim_direction.normalized())
                if dot > 0.95:
                        var perp_dist = (to_target - aim_direction.normalized() * dist).length()
                        if perp_dist < best_dist:
                                best_dist = perp_dist
                                best_target = rp
        highlighted_target = best_target
        if best_target:
                target_highlight.visible = true
                if target_highlight.has_method("set_target"):
                        target_highlight.set_target(best_target)
        else:
                target_highlight.visible = false

# === MOBILE API ===
func start_aim_mobile():
        # v2.1: Classic mode - không giới hạn số dart
        if not is_classic_mode and _count_active_darts() >= _get_max_darts():
                return
        is_aiming = true
        aim_touch_index = AIM_MODE_MOBILE_SENTINEL
        aim_direction = Vector2.RIGHT
        aim_power = GameManager.min_throw_power
        aim_line.visible = true
        _update_aim_line()

func update_aim_mobile(direction: Vector2, power: float):
        if not is_aiming:
                return
        if direction != Vector2.ZERO:
                aim_direction = direction.normalized()
        aim_power = clamp(power, GameManager.min_throw_power, GameManager.max_throw_power)
        _update_aim_line()

func throw_dart_mobile(direction: Vector2, power: float):
        if not is_aiming:
                return
        is_aiming = false
        aim_line.visible = false
        aim_touch_index = -1
        # v2.1: Classic mode - không giới hạn số dart
        if not is_classic_mode and _count_active_darts() >= _get_max_darts():
                return
        var dir = direction
        if dir == Vector2.ZERO:
                dir = aim_direction
        if dir == Vector2.ZERO:
                dir = Vector2.RIGHT
        dir = dir.normalized()
        var pwr = clamp(power, GameManager.min_throw_power, GameManager.max_throw_power)
        _spawn_dart(dir, pwr)

# === DESKTOP slingshot ===
func _start_aim_desktop(mouse_pos: Vector2):
        # v2.1: Classic mode - không giới hạn số dart
        if not is_classic_mode and _count_active_darts() >= _get_max_darts():
                return
        is_aiming = true
        aim_touch_index = -1
        aim_start_pos = mouse_pos
        aim_current_pos = mouse_pos
        aim_line.visible = true
        _calc_and_update_aim_from_slingshot()

func _calc_and_update_aim_from_slingshot():
        var direction = (aim_start_pos - aim_current_pos).normalized()
        if direction == Vector2.ZERO:
                direction = Vector2.RIGHT
        aim_direction = direction
        aim_power = _calculate_power_slingshot()
        _update_aim_line()

func _calculate_power_slingshot() -> float:
        var drag_distance = (aim_start_pos - aim_current_pos).length()
        return clamp(drag_distance / 300.0, GameManager.min_throw_power, GameManager.max_throw_power)

func _throw_dart_desktop(mouse_pos: Vector2):
        if not is_aiming:
                return
        is_aiming = false
        aim_line.visible = false
        # v2.1: Classic mode - không giới hạn số dart
        if not is_classic_mode and _count_active_darts() >= _get_max_darts():
                return
        aim_current_pos = mouse_pos
        var direction = (aim_start_pos - aim_current_pos).normalized()
        if direction == Vector2.ZERO:
                direction = Vector2.RIGHT
        var power = _calculate_power_slingshot()
        _spawn_dart(direction, power)

func _spawn_dart(direction: Vector2, power: float):
        # Character bonus: Multishot fires more for mage
        var multishot_count = GameManager.skill_multishot_dart_count
        if multishot_ready and char_skill_bonus == "multishot":
                multishot_count += 1  # Extra dart for mage

        if multishot_ready:
                multishot_ready = false
                var spread = GameManager.skill_multishot_spread
                for i in multishot_count:
                        var t = (i - (multishot_count - 1) / 2.0) / max(1, multishot_count - 1)
                        var offset_angle = t * spread
                        var dir = direction.rotated(offset_angle)
                        _spawn_single_dart(dir, power * (0.9 + 0.2 * (1.0 - abs(t))))
                AudioManager.play_combo(3)
                return
        _spawn_single_dart(direction, power)

func _spawn_single_dart(direction: Vector2, power: float):
        # v2.1: Classic mode - không giới hạn số dart (vô hạn)
        if not is_classic_mode and _count_active_darts() >= _get_max_darts():
                return
        var dart = dart_scene.instantiate()
        dart.global_position = global_position
        dart.set_direction(direction, power)
        dart.owner_player = self
        dart.owner_player_id = player_id
        get_parent().add_child(dart)
        dart.dart_stuck.connect(_on_dart_stuck)
        dart.dart_expired.connect(_on_dart_expired)
        dart.dart_consumed.connect(_on_dart_consumed)
        dart.dart_hit_player.connect(_on_dart_hit_player)
        all_darts.append(dart)
        dart_thrown.emit(dart)
        AudioManager.play_throw()
        _spawn_smoke_puff(global_position)

func _get_max_darts() -> int:
        # v2.1: Classic mode - số dart cực cao (vô hạn trên thực tế)
        if is_classic_mode:
                return 999
        return GameManager.max_darts_per_player + dart_bonus + char_dart_bonus

func _update_aim_line():
        if not is_aiming:
                return
        aim_line.clear_points()
        aim_line.add_point(Vector2.ZERO)
        var line_length = 80.0 + aim_power * 220.0
        aim_line.add_point(aim_direction * line_length)
        aim_line.default_color = Color(1.0, 0.15, 0.15, 0.9)
        aim_line.width = 3.0 + aim_power * 2.0

func _count_active_darts() -> int:
        var count = 0
        for dart in all_darts:
                if is_instance_valid(dart) and dart.is_teleportable():
                        count += 1
        return count

func _teleport_to_dart():
        # v2.1: Classic mode - teleport cooldown giảm mạnh
        var actual_cooldown = teleport_cooldown
        if is_classic_mode:
                actual_cooldown = 0.05  # Gần như không có cooldown
        if Time.get_ticks_msec() / 1000.0 - last_teleport_time < actual_cooldown:
                return
        var teleportable_darts = []
        for dart in all_darts:
                if is_instance_valid(dart) and dart.is_teleportable():
                        teleportable_darts.append(dart)
        if teleportable_darts.size() == 0:
                return

        var target_dart = _select_best_dart(teleportable_darts)
        var target_pos = target_dart.get_teleport_position()
        var was_flying = target_dart.is_flying()

        _spawn_teleport_effect(global_position, false, was_flying)
        global_position = target_pos
        _spawn_teleport_effect(global_position, true, was_flying)
        GameManager.request_screen_shake(6.0 if was_flying else 4.0, 0.25 if was_flying else 0.15)
        AudioManager.play_teleport()

        target_dart.consume()
        all_darts.erase(target_dart)
        _check_teleport_kill(target_pos)
        last_teleport_time = Time.get_ticks_msec() / 1000.0
        teleport_performed.emit(self, target_pos)

func _select_best_dart(darts: Array) -> Node2D:
        if GameManager.mid_flight_teleport_enabled:
                for i in range(darts.size() - 1, -1, -1):
                        if darts[i].is_flying():
                                return darts[i]
        return darts[-1]

func _check_teleport_kill(pos: Vector2):
        var ai_players = get_tree().get_nodes_in_group("ai_players")
        for ai in ai_players:
                if not is_instance_valid(ai) or not ai.is_alive:
                        continue
                var dist = pos.distance_to(ai.global_position)
                if dist < GameManager.teleport_kill_radius + ai.current_size:
                        # FIX: Check shield properly
                        if ai.ai_shield_active:
                                _spawn_floating_text("BLOCK!", Color(0.5, 0.9, 1.0), ai.global_position)
                                continue
                        ai.kill(self)
                        _register_kill_and_reward()

func _register_kill_and_reward():
        # v2.1: Tách logic reward ra để dùng cho cả teleport kill và dart kill
        GameManager.register_kill_by_player()
        # v2.1: Crown active → +50% score
        var score_gain = GameManager.score_per_kill
        if crown_score_multiplier_active:
                score_gain = int(score_gain * 1.5)
        GameManager.add_score(score_gain)
        GameManager.add_size(GameManager.size_per_kill)
        _update_visual_size()
        _update_size_indicator()
        GameManager.heal_percent(GameManager.heal_percent_on_kill)
        current_hp = GameManager.player_hp
        _update_hp_bar()
        _spawn_kill_effect(global_position)
        _spawn_floating_text("+%d" % score_gain, Color(1.0, 0.9, 0.2), global_position)
        _spawn_floating_text("+%d HP" % int(GameManager.player_max_hp * GameManager.heal_percent_on_kill), Color(0.3, 1.0, 0.3), global_position + Vector2(0, -20))
        GameManager.request_screen_shake(8.0, 0.3)
        AudioManager.play_kill()
        AudioManager.play_size_grow()
        _spawn_level_up_effect()
        # v2.1: Check SMG reward
        _check_smg_reward()

func _on_dart_stuck(dart: Node2D):
        pass

func _on_dart_expired(dart: Node2D):
        all_darts.erase(dart)

func _on_dart_consumed(dart: Node2D):
        all_darts.erase(dart)

func _on_dart_hit_player(dart: Node2D, hit_player: Node2D):
        if hit_player.has_method("take_damage_from"):
                var was_alive = hit_player.is_alive if "is_alive" in hit_player else true
                hit_player.take_damage_from(GameManager.dart_hit_damage, self)
                if was_alive and "is_alive" in hit_player and not hit_player.is_alive:
                        _register_kill_and_reward()

func _die():
        is_alive = false
        is_respawning = true
        is_aiming = false
        aim_touch_index = -1
        dart_bonus = 0
        dart_bonus_timer = 0.0
        _deactivate_shield()
        is_dashing = false
        multishot_ready = false
        # v2.1: Reset Classic state
        is_spawn_invulnerable = false
        smg_active = false
        crown_active = false
        crown_score_multiplier_active = false
        pinned_targets.clear()
        if target_highlight:
                target_highlight.visible = false
        death_particles.emitting = true
        sprite.visible = false
        collision_shape.set_deferred("disabled", true)
        aim_line.visible = false
        teleport_ready_indicator.visible = false
        if shield_sprite:
                shield_sprite.visible = false
        if hp_bar:
                hp_bar.visible = false
        if name_label:
                name_label.visible = false
        if size_indicator:
                size_indicator.visible = false
        for dart in all_darts:
                if is_instance_valid(dart):
                        dart.queue_free()
        all_darts.clear()
        AudioManager.play_death()
        GameManager.set_player_alive(false)
        player_died.emit(self)
        # v1.9 FIX: guard respawn callback
        var self_ref = self
        get_tree().create_timer(GameManager.respawn_time).timeout.connect(func():
                if is_instance_valid(self_ref):
                        self_ref._respawn()
        )

func get_killer_name() -> String:
        return last_killer_name

func _respawn():
        if GameManager.is_match_over():
                return
        is_alive = true
        is_respawning = false
        current_hp = GameManager.player_max_hp
        GameManager.player_hp = GameManager.player_max_hp
        GameManager.player_size = GameManager.initial_player_radius
        GameManager.update_player_max_hp_for_size(GameManager.player_size)
        GameManager.set_player_alive(true)
        sprite.visible = true
        collision_shape.set_deferred("disabled", false)
        if hp_bar:
                hp_bar.visible = true
        if name_label:
                name_label.visible = true
        if size_indicator:
                size_indicator.visible = true
        var angle = randf() * TAU
        var dist = randf() * GameManager.zone_radius * 0.5
        global_position = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
        _update_hp_bar()
        _update_visual_size()
        _update_size_indicator()
        _spawn_teleport_effect(global_position, true, false)
        AudioManager.play_respawn()
        player_respawned.emit(self)
        # v2.1: Classic mode - spawn invulnerability
        if is_classic_mode:
                _start_spawn_invulnerability()

func _spawn_teleport_effect(pos: Vector2, is_appear: bool, is_mid_flight: bool):
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.8
        particles.amount = int((25 if is_mid_flight else 18) * SettingsManager.get_particle_multiplier())
        particles.lifetime = 0.5
        particles.direction = Vector2(0, -1) if is_appear else Vector2(0, 1)
        particles.spread = 180
        particles.initial_velocity_min = 60
        particles.initial_velocity_max = 180
        particles.gravity = Vector2.ZERO
        particles.scale_amount_min = 2
        particles.scale_amount_max = 5
        if is_mid_flight:
                particles.color = Color(0.2, 0.9, 1.0, 0.9) if is_appear else Color(1.0, 0.3, 0.7, 0.9)
        else:
                particles.color = Color(0.3, 0.7, 1.0, 0.8) if is_appear else Color(1.0, 0.5, 0.2, 0.8)
        # v2.1: Classic mode - màu hacker green
        if is_classic_mode:
                particles.color = Color(0, 1, 0.5, 0.9) if is_appear else Color(0, 0.8, 0.4, 0.8)
        get_parent().add_child(particles)
        particles.global_position = pos
        get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func _spawn_dash_effect(dir: Vector2):
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.7
        particles.amount = max(1, int(15 * SettingsManager.get_particle_multiplier()))
        particles.lifetime = 0.35
        particles.direction = -dir
        particles.spread = 35
        particles.initial_velocity_min = 80
        particles.initial_velocity_max = 160
        particles.gravity = Vector2.ZERO
        particles.scale_amount_min = 2
        particles.scale_amount_max = 5
        particles.color = Color(0.3, 1.0, 0.9, 0.8)
        if is_classic_mode:
                particles.color = Color(0, 1, 0.5, 0.9)
        get_parent().add_child(particles)
        particles.global_position = global_position
        get_tree().create_timer(0.6).timeout.connect(particles.queue_free)

func _spawn_shield_effect():
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.5
        particles.amount = max(1, int(24 * SettingsManager.get_particle_multiplier()))
        particles.lifetime = 0.6
        particles.direction = Vector2(0, -1)
        particles.spread = 180
        particles.initial_velocity_min = 30
        particles.initial_velocity_max = 100
        particles.gravity = Vector2.ZERO
        particles.scale_amount_min = 2
        particles.scale_amount_max = 4
        particles.color = Color(0.5, 0.9, 1.0, 0.9)
        get_parent().add_child(particles)
        particles.global_position = global_position
        get_tree().create_timer(0.9).timeout.connect(particles.queue_free)

func _spawn_buff_effect(color: Color):
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.5
        particles.amount = max(1, int(20 * SettingsManager.get_particle_multiplier()))
        particles.lifetime = 0.5
        particles.direction = Vector2(0, -1)
        particles.spread = 180
        particles.initial_velocity_min = 40
        particles.initial_velocity_max = 120
        particles.gravity = Vector2.ZERO
        particles.scale_amount_min = 2
        particles.scale_amount_max = 4
        particles.color = color
        get_parent().add_child(particles)
        particles.global_position = global_position
        get_tree().create_timer(0.8).timeout.connect(particles.queue_free)

func _spawn_kill_effect(pos: Vector2):
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.9
        particles.amount = max(1, int(35 * SettingsManager.get_particle_multiplier()))
        particles.lifetime = 0.7
        particles.direction = Vector2(0, -1)
        particles.spread = 180
        particles.initial_velocity_min = 80
        particles.initial_velocity_max = 250
        particles.gravity = Vector2(0, 200)
        particles.scale_amount_min = 3
        particles.scale_amount_max = 7
        particles.color = Color(1.0, 0.3, 0.3, 0.95)
        get_parent().add_child(particles)
        particles.global_position = pos
        get_tree().create_timer(1.5).timeout.connect(particles.queue_free)

func _spawn_level_up_effect():
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.5
        particles.amount = max(1, int(18 * SettingsManager.get_particle_multiplier()))
        particles.lifetime = 0.6
        particles.direction = Vector2(0, -1)
        particles.spread = 180
        particles.initial_velocity_min = 60
        particles.initial_velocity_max = 150
        particles.gravity = Vector2(0, -50)
        particles.scale_amount_min = 2
        particles.scale_amount_max = 5
        particles.color = Color(1.0, 0.85, 0.2, 0.95)
        get_parent().add_child(particles)
        particles.global_position = global_position
        get_tree().create_timer(1.0).timeout.connect(particles.queue_free)

func _spawn_smoke_puff(pos: Vector2):
        if SettingsManager.get_particle_multiplier() <= 0:
                return
        var particles = CPUParticles2D.new()
        particles.emitting = true
        particles.one_shot = true
        particles.explosiveness = 0.7
        particles.amount = max(1, int(8 * SettingsManager.get_particle_multiplier()))
        particles.lifetime = 0.3
        particles.direction = Vector2(0, -1)
        particles.spread = 180
        particles.initial_velocity_min = 20
        particles.initial_velocity_max = 50
        particles.gravity = Vector2.ZERO
        particles.scale_amount_min = 1
        particles.scale_amount_max = 3
        particles.color = Color(0.7, 0.7, 0.8, 0.5)
        get_parent().add_child(particles)
        particles.global_position = pos
        get_tree().create_timer(0.5).timeout.connect(particles.queue_free)

func _spawn_floating_text(text: String, color: Color, pos: Vector2):
        var label = Label.new()
        label.text = text
        label.add_theme_color_override("font_color", color)
        label.add_theme_font_size_override("font_size", 18)
        label.z_index = 100
        label.position = pos + Vector2(randf_range(-10, 10), 0)
        get_parent().add_child(label)
        var tween = label.create_tween()
        tween.set_parallel(true)
        tween.tween_property(label, "position:y", label.position.y - 50, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(label, "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
        tween.chain().tween_callback(label.queue_free)

func _update_teleport_indicator():
        var has_teleportable = false
        for dart in all_darts:
                if is_instance_valid(dart) and dart.is_teleportable():
                        has_teleportable = true
                        break
        teleport_ready_indicator.visible = has_teleportable and is_alive

const BASE_SPRITE_SCALE := 0.3

func _update_visual_size():
        var size_ratio = GameManager.player_size / GameManager.initial_player_radius
        var new_scale = BASE_SPRITE_SCALE * size_ratio
        sprite.scale = Vector2(new_scale, new_scale)
        if collision_shape.shape is CircleShape2D:
                collision_shape.shape.radius = GameManager.player_size
        var inv = 1.0 / size_ratio if size_ratio > 0.01 else 1.0
        if hp_bar:
                hp_bar.scale = Vector2(inv, inv)
                hp_bar.position.y = -35.0 * size_ratio
        if name_label:
                name_label.scale = Vector2(inv, inv)
                name_label.position.y = -55.0 * size_ratio
        if size_indicator:
                size_indicator.scale = Vector2(inv, inv)
                size_indicator.position.y = 25.0 * size_ratio
        if teleport_ready_indicator:
                teleport_ready_indicator.scale = Vector2(0.3 * inv, 0.1 * inv)
                teleport_ready_indicator.position.y = -27.0 * size_ratio
        if skill_cooldown_label:
                skill_cooldown_label.scale = Vector2(inv, inv)
                skill_cooldown_label.position.y = -75.0 * size_ratio
        _update_hp_bar()

func _update_size_indicator():
        if size_indicator:
                size_indicator.text = "Size: %.0f" % GameManager.player_size

func _update_hp_bar():
        if hp_bar:
                hp_bar.max_value = GameManager.player_max_hp
                hp_bar.value = current_hp

func heal(amount: float):
        GameManager.heal(amount)
        current_hp = GameManager.player_hp
        _update_hp_bar()
        AudioManager.play_pickup_health()
        _spawn_floating_text("+%d HP" % int(amount), Color(0.3, 1.0, 0.3), global_position)

func refill_darts(bonus: int, duration: float):
        dart_bonus = max(dart_bonus, bonus)
        dart_bonus_timer = max(dart_bonus_timer, duration)
        AudioManager.play_pickup_dart()

func take_damage_from(amount: float, attacker: Node2D):
        # v2.1: Spawn invulnerable - không nhận damage
        if is_spawn_invulnerable:
                _spawn_floating_text("INVUL!", Color(0, 1, 0.5), global_position)
                return
        if shield_active:
                _spawn_floating_text("BLOCK!", Color(0.5, 0.9, 1.0), global_position)
                AudioManager.play_zone_warning()
                return
        GameManager.take_damage(amount)
        current_hp = GameManager.player_hp
        _update_hp_bar()
        var tween = create_tween()
        tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3), 0.05)
        tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0), 0.2)
        AudioManager.play_damage()
        _spawn_floating_text("-%d" % int(amount), Color(1.0, 0.3, 0.3), global_position + Vector2(0, -10))
        if attacker and "ai_name" in attacker:
                last_killer_name = attacker.ai_name
        elif attacker and "player_name" in attacker:
                last_killer_name = attacker.player_name
        else:
                last_killer_name = KILLER_NONE
        if current_hp <= 0:
                current_hp = 0
                _die()
