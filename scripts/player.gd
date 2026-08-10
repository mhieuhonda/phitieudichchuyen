extends CharacterBody2D

## Player - Nhân vật người chơi (v3.5)
## v3.5:
##   - Hỗ trợ Stage Mode: chết quá số lần quy định → fail stage
##   - Dịch chuyển tới Boss → gây 250k damage (thay vì kill)
##   - Dart trúng Boss → 100 chip damage
##   - Fix kill-steal: dart chỉ gây damage cho AI khác, không cho AI cùng team
## v3.4: Đã xóa 3 kỹ năng chủ động (Dash/Shield/Multishot). Chỉ còn Ném + Dịch.
## - Hỗ trợ CharacterData (chọn nhân vật, bonus chỉ số HP/Speed/Dart)
## - Max HP scale theo size
## - Hồi 10% max HP khi ăn đối thủ
## - Joystick ảo + mobile controls
## - Hiệu ứng: hit flash, level-up, floating damage text, teleport shockwave
## - FIX: Không bị khóa di chuyển khi ném phi tiêu

const KILLER_NONE := ""

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
var dash_invincibility_timer: float = 0.0  # v3.3: iframe khi dash
var multishot_ready: bool = false
# v3.3: Slow effect khi bị trúng dart
var hit_slow_timer: float = 0.0
var hit_slow_factor: float = 1.0

# === CHARACTER DATA (v1.2) ===
var char_hp_bonus: float = 0.0
var char_speed_bonus: float = 0.0
var char_dart_bonus: int = 0
var char_skill_bonus: String = ""

var dart_scene: PackedScene = preload("res://scenes/dart.tscn")

signal dart_thrown(dart: Node2D)
signal player_died(player: CharacterBody2D)
signal player_respawned(player: CharacterBody2D)
signal teleport_performed(player: CharacterBody2D, to_position: Vector2)
signal skill_activated(skill_id: int)
signal skill_cooldown_updated(skill_id: int, remaining: float)

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

func _apply_character_data():
        ## Áp dụng bonus chỉ số từ nhân vật đã chọn
        var char_data = CharacterData.get_selected()
        char_hp_bonus = char_data["hp_bonus"]
        char_speed_bonus = char_data["speed_bonus"]
        char_dart_bonus = char_data["dart_bonus"]
        char_skill_bonus = char_data["skill_bonus"]

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

        # v3.3: Cập nhật hit slow timer
        if hit_slow_timer > 0:
                hit_slow_timer -= delta
                if hit_slow_timer <= 0:
                        hit_slow_factor = 1.0
                        hit_slow_timer = 0.0

        # v3.3: Cập nhật dash invincibility timer
        if dash_invincibility_timer > 0:
                dash_invincibility_timer -= delta

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
                        # Apply character speed bonus + hit slow factor
                        velocity = input_dir * (GameManager.walk_speed + char_speed_bonus) * hit_slow_factor
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
        # v3.4: Đã xóa 3 skills (Dash/Shield/Multishot) — không còn input actions này

# === SKILLS (v3.4: DEPRECATED — giữ lại hàm để tương thích, nhưng no-op) ===
func activate_skill(skill: int) -> bool:
        # v3.4: Skills đã bị xóa. Hàm giữ lại để tránh lỗi nếu code cũ gọi.
        return false

func _do_dash() -> bool:
        # v3.4: deprecated — không còn dash
        return false

## v3.3: Áp dụng hiệu ứng slow khi bị trúng dart
func apply_hit_slow(duration: float, factor: float):
        hit_slow_timer = max(hit_slow_timer, duration)
        hit_slow_factor = factor

func _do_shield() -> bool:
        # v3.4: deprecated — không còn shield
        return false

func _deactivate_shield():
        shield_active = false
        if shield_sprite:
                shield_sprite.visible = false

func _do_multishot() -> bool:
        # v3.4: deprecated — không còn multishot
        return false

func is_shield_active() -> bool:
        return false  # v3.4: luôn false — không còn shield

# === MOBILE API ===
func start_aim_mobile():
        if _count_active_darts() >= _get_max_darts():
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
        if _count_active_darts() >= _get_max_darts():
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
        if _count_active_darts() >= _get_max_darts():
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
        if _count_active_darts() >= _get_max_darts():
                return
        aim_current_pos = mouse_pos
        var direction = (aim_start_pos - aim_current_pos).normalized()
        if direction == Vector2.ZERO:
                direction = Vector2.RIGHT
        var power = _calculate_power_slingshot()
        _spawn_dart(direction, power)

func _spawn_dart(direction: Vector2, power: float):
        # v3.4: Đã xóa multishot — luôn ném 1 phi tiêu duy nhất
        _spawn_single_dart(direction, power)

func _spawn_single_dart(direction: Vector2, power: float):
        if _count_active_darts() >= _get_max_darts():
                return
        var dart = dart_scene.instantiate()
        dart.global_position = global_position
        dart.set_direction(direction, power)
        dart.owner_player = self
        dart.owner_player_id = player_id
        # v3.8: FIX BUG — player darts PHẢI add vào group "darts" để AI có thể
        # phát hiện và né (trước đây chỉ AI/boss thêm group, player không thêm →
        # AI không bao giờ dodge được dart của player dù có dodge_chance cao).
        dart.add_to_group("darts")
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
        if Time.get_ticks_msec() / 1000.0 - last_teleport_time < teleport_cooldown:
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
                # v3.5: Boss — gây damage lớn thay vì kill
                if ai.has_method("is_boss") and ai.is_boss():
                        # Trong bán kính boss → gây teleport damage
                        if dist < GameManager.teleport_kill_radius + ai.current_size:
                                ai.take_teleport_damage(StageManager.BOSS_TELEPORT_DAMAGE, self)
                                _spawn_floating_text("-%d" % int(StageManager.BOSS_TELEPORT_DAMAGE),
                                                Color(1.0, 0.3, 0.3), ai.global_position + Vector2(0, -60))
                                GameManager.request_screen_shake(8.0, 0.3)
                                continue
                        # Ngoài kill zone nhưng trong knockback zone → báo MISS
                        if dist < GameManager.teleport_knockback_radius + ai.current_size:
                                _spawn_floating_text("MISS", Color(0.6, 0.6, 0.6), ai.global_position + Vector2(0, -40))
                                continue
                # Kill zone for regular AI
                if dist < GameManager.teleport_kill_radius + ai.current_size:
                        # FIX: Check shield properly
                        if ai.ai_shield_active:
                                _spawn_floating_text("BLOCK!", Color(0.5, 0.9, 1.0), ai.global_position)
                                continue
                        ai.kill(self)
                        _register_kill_and_reward()
                        continue
                # v3.3: Knockback cho AI trong bán kính lớn hơn (không giết, chỉ đẩy)
                if dist < GameManager.teleport_knockback_radius + ai.current_size:
                        var knockback_dir = (ai.global_position - pos).normalized()
                        if knockback_dir == Vector2.ZERO:
                                knockback_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
                        ai.velocity += knockback_dir * GameManager.teleport_knockback_force * (1.0 - dist / (GameManager.teleport_knockback_radius + ai.current_size))
                        if ai.has_method("apply_hit_slow"):
                                ai.apply_hit_slow(GameManager.hit_slow_duration * 0.5, GameManager.hit_slow_factor)

func _register_kill_and_reward():
        GameManager.register_kill_by_player()
        var score_gain = GameManager.score_per_kill
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
        # Notify HUD để track kill streak (Double/Triple/Quadra/Penta Kill)
        var hud_node = get_tree().get_first_node_in_group("hud")
        if hud_node and hud_node.has_method("register_player_kill"):
                hud_node.register_player_kill()

func _on_dart_stuck(dart: Node2D):
        pass

func _on_dart_expired(dart: Node2D):
        all_darts.erase(dart)

func _on_dart_consumed(dart: Node2D):
        all_darts.erase(dart)

func _on_dart_hit_player(dart: Node2D, hit_player: Node2D):
        if hit_player.has_method("take_damage_from"):
                var was_alive = hit_player.is_alive if "is_alive" in hit_player else true
                # v3.8: Hit marker — báo cho main.gd biết dart đã trúng đích
                # Player là con của main.gd trong scene tree, nên get_parent() chính là main.
                var main_node = get_parent()
                hit_player.take_damage_from(GameManager.dart_hit_damage, self)
                if main_node and main_node.has_method("show_hit_marker"):
                        main_node.show_hit_marker(false)
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
        # v3.5: Stage mode — check if player can respawn
        var can_respawn = true
        if GameManager.is_stage_mode:
                can_respawn = GameManager.on_player_died_in_stage()
        if can_respawn:
                var self_ref = self
                get_tree().create_timer(GameManager.respawn_time).timeout.connect(func():
                        if is_instance_valid(self_ref):
                                self_ref._respawn()
                )

func get_killer_name() -> String:
        return last_killer_name

func _respawn():
        # v3.5: Don't respawn if stage ended (failed/cleared)
        if GameManager.is_stage_mode and (GameManager.stage_failed or GameManager.stage_cleared_flag):
                return
        if not GameManager.is_stage_mode and GameManager.is_match_over():
                return
        is_alive = true
        is_respawning = false
        last_killer_name = KILLER_NONE
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
        # v3.5: Respawn ở vị trí an toàn — xa boss/AI nhất có thể
        global_position = _find_safe_respawn_position()
        _update_hp_bar()
        _update_visual_size()
        _update_size_indicator()
        _spawn_teleport_effect(global_position, true, false)
        AudioManager.play_respawn()
        player_respawned.emit(self)

## v3.5: Tìm vị trí respawn an toàn — xa tất cả AI/Boss
func _find_safe_respawn_position() -> Vector2:
        var best_pos = GameManager.zone_center
        var best_dist = -1.0
        var enemies = get_tree().get_nodes_in_group("ai_players")
        # Thử 8 vị trí trong zone, chọn vị trí xa enemy nhất
        for i in 8:
                var angle = (i / 8.0) * TAU + randf_range(-0.3, 0.3)
                var dist = randf_range(150, GameManager.zone_radius * 0.7)
                var pos = GameManager.zone_center + Vector2(cos(angle), sin(angle)) * dist
                # Tính khoảng cách tới enemy gần nhất
                var min_enemy_dist = 99999.0
                for enemy in enemies:
                        if is_instance_valid(enemy) and enemy.is_alive:
                                var d = pos.distance_to(enemy.global_position)
                                if d < min_enemy_dist:
                                        min_enemy_dist = d
                if min_enemy_dist > best_dist:
                        best_dist = min_enemy_dist
                        best_pos = pos
        # Clamp trong map
        best_pos.x = clamp(best_pos.x, 50, GameManager.map_size.x - 50)
        best_pos.y = clamp(best_pos.y, 50, GameManager.map_size.y - 50)
        return best_pos

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
        if shield_active:
                _spawn_floating_text("BLOCK!", Color(0.5, 0.9, 1.0), global_position)
                AudioManager.play_zone_warning()
                return
        # v3.3: Bất tử khi dash (iframe)
        if dash_invincibility_timer > 0:
                _spawn_floating_text("EVADE!", Color(0.5, 1.0, 0.9), global_position)
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
