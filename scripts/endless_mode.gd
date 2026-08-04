extends Node2D

## EndlessMode - Controller chính cho chế độ Vượt Ải (v2.4)
## - 500 level với độ khó tăng dần
## - Player khóa trên đường thẳng đứng, ném phi tiêu lên trên
## - Zombie spawn từ trên xuống, player phải giết hết để qua ải
## - 15 skills được mở khóa dần theo level
## - HUD + joystick (trái) + skills hub (phải) KHÔNG chồng lấn
## - Lưu tiến độ: SettingsManager.endless_max_level

const MAX_LEVEL := 500
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombie.tscn")

# === NODES ===
@onready var player: CharacterBody2D = $EndlessPlayer
@onready var zombie_container: Node2D = $ZombieContainer
@onready var bg_color: ColorRect = $Background
@onready var bg_fog: ColorRect = $FogLayer
@onready var hud_layer: CanvasLayer = $HUDLayer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var joystick: Control = $UILayer/VirtualJoystick
@onready var skills_hub: Control = $UILayer/SkillsHub

# HUD elements
@onready var level_label: Label = $HUDLayer/HUDContainer/TopBar/LevelLabel
@onready var hp_label: Label = $HUDLayer/HUDContainer/TopBar/HpLabel
@onready var kills_label: Label = $HUDLayer/HUDContainer/TopBar/KillsLabel
@onready var message_label: Label = $HUDLayer/HUDContainer/MessageLabel
@onready var game_over_panel: Panel = $HUDLayer/HUDContainer/GameOverPanel
@onready var game_over_label: Label = $HUDLayer/HUDContainer/GameOverPanel/VBox/GameOverLabel
@onready var retry_button: Button = $HUDLayer/HUDContainer/GameOverPanel/VBox/RetryButton
@onready var menu_button: Button = $HUDLayer/HUDContainer/GameOverPanel/VBox/MenuButton
@onready var next_level_button: Button = $HUDLayer/HUDContainer/GameOverPanel/VBox/NextLevelButton

# === GAME STATE ===
var current_level: int = 1
var total_kills: int = 0
var level_kills: int = 0
var zombies_to_spawn: int = 0
var zombies_spawned: int = 0
var zombies_escaped: int = 0  # Track zombies that went off-screen
var is_game_over: bool = false
var is_level_transitioning: bool = false
var _spawn_timer: float = 0.0
var _spawn_interval: float = 0.6  # giây giữa 2 zombie spawn
var _quick_shot_timer: SceneTreeTimer = null  # v2.8: prevent race condition
var _slow_timer: SceneTreeTimer = null  # v2.8: prevent race condition for slow_time
var _combo_count: int = 0  # v2.8: combo kills tracking
var _combo_timer: float = 0.0  # v2.8: combo window timer (2s)
var _combo_label: Label = null  # v2.8: dynamic combo label
var _perf_label: Label = null  # v2.8: performance stats overlay
var _perf_timer: float = 0.0  # v2.8: perf update throttle

func _ready():
        # Setup player
        player._fixed_x = 640.0  # Giữa màn hình 1280px
        player.global_position = Vector2(640, 600)
        # Connect signals
        player.hp_changed.connect(_on_player_hp_changed)
        player.player_died.connect(_on_player_died)
        skills_hub.skill_activated.connect(_on_skill_activated)
        # Connect buttons
        retry_button.pressed.connect(_on_retry)
        menu_button.pressed.connect(_on_menu)
        next_level_button.pressed.connect(_on_next_level)
        for btn in [retry_button, menu_button, next_level_button]:
                btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())
        # Setup HUD
        game_over_panel.visible = false
        next_level_button.visible = false
        # Listen language changes
        if I18N:
                I18N.language_changed.connect(func(_l): _refresh_hud())
        # Apply premium styling to game over panel
        _apply_premium_styling()
        # Khởi tạo ải đầu tiên
        _start_level(1)
        if AudioManager:
                AudioManager.play_music("game")
                AudioManager.play_warning()  # horror atmosphere hint
        # v2.8: Create combo label for kill combo counter
        _combo_label = Label.new()
        _combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _combo_label.add_theme_font_size_override("font_size", 36)
        _combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
        _combo_label.visible = false
        _combo_label.z_index = 20
        hud_layer.add_child(_combo_label)
        _combo_label.position = Vector2(540, 250)
        # v2.8: Performance stats overlay
        _perf_label = Label.new()
        _perf_label.add_theme_font_size_override("font_size", 12)
        _perf_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.7))
        _perf_label.visible = SettingsManager.show_fps if SettingsManager else false
        hud_layer.add_child(_perf_label)
        _perf_label.position = Vector2(10, 680)

func _apply_premium_styling():
        # Style game over panel
        if game_over_panel:
                var style = StyleBoxFlat.new()
                style.bg_color = Color(0.04, 0.02, 0.06, 0.94)
                style.border_color = Color(0.5, 0.15, 0.15, 0.5)
                style.border_width_top = 2
                style.border_width_bottom = 2
                style.border_width_left = 2
                style.border_width_right = 2
                style.corner_radius_top_left = 14
                style.corner_radius_top_right = 14
                style.corner_radius_bottom_left = 14
                style.corner_radius_bottom_right = 14
                style.shadow_color = Color(0.3, 0, 0, 0.5)
                style.shadow_size = 12
                game_over_panel.add_theme_stylebox_override("panel", style)
        # Style buttons
        _style_game_button(retry_button, Color(0.12, 0.1, 0.04, 0.9), Color(1.0, 0.85, 0.2))
        _style_game_button(next_level_button, Color(0.04, 0.12, 0.06, 0.9), Color(0.3, 1.0, 0.5))
        _style_game_button(menu_button, Color(0.08, 0.08, 0.1, 0.8), Color(0.65, 0.65, 0.75))

func _style_game_button(btn: Button, bg_color: Color, accent_color: Color):
        if not btn:
                return
        var style_normal = StyleBoxFlat.new()
        style_normal.bg_color = bg_color
        style_normal.corner_radius_top_left = 10
        style_normal.corner_radius_top_right = 10
        style_normal.corner_radius_bottom_left = 10
        style_normal.corner_radius_bottom_right = 10
        style_normal.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.3)
        style_normal.border_width_top = 1
        style_normal.border_width_bottom = 1
        style_normal.border_width_left = 1
        style_normal.border_width_right = 1
        style_normal.content_margin_top = 8
        style_normal.content_margin_bottom = 8
        style_normal.content_margin_left = 16
        style_normal.content_margin_right = 16
        style_normal.shadow_color = Color(0, 0, 0, 0.35)
        style_normal.shadow_size = 5
        style_normal.shadow_offset = Vector2(0, 3)
        var style_hover = style_normal.duplicate()
        style_hover.bg_color = Color(bg_color.r + 0.07, bg_color.g + 0.05, bg_color.b + 0.07, bg_color.a)
        style_hover.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.6)
        style_hover.shadow_size = 7
        var style_pressed = style_normal.duplicate()
        style_pressed.bg_color = Color(bg_color.r * 0.8, bg_color.g * 0.8, bg_color.b * 0.8, bg_color.a)
        btn.add_theme_stylebox_override("normal", style_normal)
        btn.add_theme_stylebox_override("hover", style_hover)
        btn.add_theme_stylebox_override("pressed", style_pressed)

func _process(delta: float):
        if is_game_over or is_level_transitioning:
                # Dừng input player khi đang chuyển ải / game over
                if is_instance_valid(player):
                        player.set_joystick_output(Vector2.ZERO)
                return
        # Cập nhật joystick → player
        if joystick and is_instance_valid(player):
                player.set_joystick_output(joystick.get_direction())
        # Spawn zombie theo interval
        if zombies_spawned < zombies_to_spawn:
                _spawn_timer -= delta
                if _spawn_timer <= 0.0:
                        _spawn_zombie()
                        zombies_spawned += 1
                        _spawn_timer = _spawn_interval
        # v2.8: Combo timer countdown
        if _combo_timer > 0:
                _combo_timer -= delta
                if _combo_timer <= 0:
                        _combo_count = 0
                        if _combo_label:
                                _combo_label.visible = false
        # v2.8: Combo label fade out
        if _combo_label and _combo_label.visible and _combo_timer < 0.8:
                _combo_label.modulate.a = _combo_timer / 0.8
        # v2.8: Performance stats update (throttled to 4x/sec)
        if _perf_label and _perf_label.visible:
                _perf_timer -= delta
                if _perf_timer <= 0:
                        _perf_timer = 0.25
                        var fps = Engine.get_frames_per_second()
                        var zombie_count = get_tree().get_nodes_in_group("zombies").size()
                        var dart_count = get_tree().get_nodes_in_group("darts").size()
                        var obj_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
                        _perf_label.text = "FPS: %d | Zombies: %d | Darts: %d | Nodes: %d" % [fps, zombie_count, dart_count, obj_count]

# === LEVEL MANAGEMENT ===

func _start_level(level: int):
        current_level = level
        level_kills = 0
        zombies_spawned = 0
        zombies_escaped = 0
        zombies_to_spawn = _calc_zombies_count(level)
        _spawn_timer = 0.5  # delay 0.5s trước khi spawn
        # Cập nhật skills hub level
        skills_hub.set_level(level)
        # Cập nhật HUD
        _refresh_hud()
        # Hiển thị thông báo qua ải
        _show_message(I18N.t("endless.level", [level]), 1.2)
        # Lưu tiến độ
        if current_level > SettingsManager.endless_max_level:
                SettingsManager.endless_max_level = current_level
                SettingsManager.save_settings()

func _calc_zombies_count(level: int) -> int:
        return int(floor(3 + level * 0.5))

func _spawn_zombie():
        var level = current_level
        var zombie = ZOMBIE_SCENE.instantiate()
        # Random X trong khoảng rộng, Y = -50 (ngoài màn hình trên)
        var rng = RandomNumberGenerator.new()
        rng.randomize()
        var spawn_x = rng.randf_range(200, 1080)
        var spawn_y = -60.0
        zombie_container.add_child(zombie)
        zombie.global_position = Vector2(spawn_x, spawn_y)
        # Tính stats theo level
        var base_hp = 30.0 + level * 2.0
        var base_speed = 50.0 + level * 1.0
        var base_damage = 10.0 + level * 0.5
        # Chọn type dựa trên level
        var z_type = 0  # WALKER
        var r = rng.randf()
        if level >= 25 and r < 0.20:
                z_type = 2  # BRUTE
                base_hp *= 2.5
                base_speed *= 0.7
                base_damage *= 1.5
        elif level >= 10 and r < 0.45:
                z_type = 1  # RUNNER
                base_speed *= 1.8
                base_hp *= 0.7
        # Setup
        zombie.setup(z_type, base_hp, base_speed, base_damage, player)
        # Connect zombie_killed (signal truyền zombie instance)
        zombie.zombie_killed.connect(_on_zombie_killed)
        # Connect zombie_escaped để track zombie đi mất
        zombie.zombie_escaped.connect(_on_zombie_escaped)
        # v2.4: Horror sounds - 50% chance growl when spawning, scream for runner/brute
        if AudioManager:
                if z_type == 0:
                        if randf() < 0.5:
                                AudioManager.play_zombie_growl()
                elif z_type == 1:
                        AudioManager.play_zombie_scream()
                else:  # BRUTE
                        AudioManager.play_zombie_growl()
                        AudioManager.play_horror_drone()

func _on_zombie_killed(zombie: Node2D):
        if not is_instance_valid(zombie):
                _check_level_complete()
                return
        level_kills += 1
        total_kills += 1
        # v2.8: Kill combo counter
        _combo_count += 1
        _combo_timer = 2.0  # Reset combo window
        if _combo_label:
                if _combo_count >= 2:
                        _combo_label.text = "COMBO x%d!" % _combo_count
                        _combo_label.visible = true
                        _combo_label.modulate.a = 1.0
                        _combo_label.add_theme_color_override("font_color",
                                Color(1.0, 0.85, 0.2) if _combo_count < 5 else
                                Color(1.0, 0.3, 0.2) if _combo_count < 10 else
                                Color(1.0, 0.1, 0.8))
                        _combo_label.add_theme_font_size_override("font_size",
                                36 + min(_combo_count * 2, 20))
                        if AudioManager:
                                AudioManager.play_combo(_combo_count)
        # LIFE_STEAL: hồi HP khi kill
        if is_instance_valid(player) and player.life_steal_remaining > 0:
                player.heal(5.0)
        _refresh_hud()
        _check_level_complete()

func _on_zombie_escaped(_zombie: Node2D):
        ## Zombie went off-screen without being killed - track it for level completion
        zombies_escaped += 1
        _refresh_hud()
        _check_level_complete()

func _check_level_complete():
        if is_game_over or is_level_transitioning:
                return
        # Level complete when all zombies have been spawned AND
        # all have been either killed or escaped off-screen
        if zombies_spawned >= zombies_to_spawn and (level_kills + zombies_escaped) >= zombies_to_spawn:
                _level_complete()

func _level_complete():
        is_level_transitioning = true
        # Show level cleared
        if AudioManager:
                AudioManager.play_success()
                AudioManager.play_jump_scare()  # v2.4: jump scare stinger for transition
        # Delay một chút trước khi hiển thị panel
        await get_tree().create_timer(0.6).timeout
        if is_game_over:
                return
        if current_level >= MAX_LEVEL:
                # Hoàn thành tất cả ải!
                game_over_label.text = "🏆 " + I18N.t("endless.victory", [MAX_LEVEL])
                game_over_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
                next_level_button.visible = false
                retry_button.visible = true
                menu_button.visible = true
                game_over_panel.visible = true
                return
        # Show next level option
        game_over_label.text = I18N.t("endless.victory", [current_level])
        game_over_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
        retry_button.visible = false
        next_level_button.visible = true
        menu_button.visible = true
        next_level_button.text = I18N.t("endless.next_level", [current_level + 1])
        game_over_panel.visible = true

func _on_next_level():
        if AudioManager:
                AudioManager.play_ui_click()
        game_over_panel.visible = false
        is_level_transitioning = false
        # Reset player temporary skills
        if is_instance_valid(player):
                player.full_heal()
                player.reset_temporary_skills()
        # Reset skills hub cooldowns
        skills_hub.reset_cooldowns()
        # Xóa zombie còn sót (nếu có)
        _clear_zombies()
        zombies_escaped = 0  # Reset escaped count for new level
        _start_level(current_level + 1)

# === GAME OVER ===

func _on_player_died():
        if is_game_over:
                return
        is_game_over = true
        if AudioManager:
                AudioManager.play_death()
                AudioManager.play_zombie_scream()  # v2.4: horror scream on death
                AudioManager.play_horror_drone()   # v2.4: doom drone
        # Delay trước khi show panel
        await get_tree().create_timer(0.5).timeout
        game_over_label.text = I18N.t("endless.game_over")
        game_over_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
        next_level_button.visible = false
        retry_button.visible = true
        menu_button.visible = true
        retry_button.text = I18N.t("endless.retry")
        menu_button.text = I18N.t("endless.menu")
        game_over_panel.visible = true

func _on_retry():
        if AudioManager:
                AudioManager.play_ui_click()
        # Reset toàn bộ
        is_game_over = false
        is_level_transitioning = false
        _clear_zombies()
        game_over_panel.visible = false
        if is_instance_valid(player):
                player.is_alive = true
                player.full_heal()
                player.reset_temporary_skills()
                player.global_position = Vector2(640, 600)
        skills_hub.reset_cooldowns()
        total_kills = 0
        zombies_escaped = 0
        _start_level(1)

func _on_menu():
        if AudioManager:
                AudioManager.play_ui_click()
                AudioManager.play_cancel()
        if NetworkManager and NetworkManager.is_server_connected():
                NetworkManager.disconnect_from_server()
        get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

# === SKILL DISPATCH ===

func _on_skill_activated(skill_id: int, skill_key: String):
        if not is_instance_valid(player):
                return
        match skill_key:
                "QUICK_SHOT":
                        player.activate_quick_shot()
                        # v2.8 FIX: Cancel previous quick_shot coroutine to prevent race condition
                        if _quick_shot_timer and is_instance_valid(_quick_shot_timer):
                                _quick_shot_timer.time_left = 5.0  # Reset timer
                        else:
                                _quick_shot_timer = get_tree().create_timer(5.0)
                                _quick_shot_timer.timeout.connect(func():
                                        if is_instance_valid(player):
                                                player.throw_cooldown_mult = 1.0
                                        _quick_shot_timer = null
                                )
                "HEAL":
                        player.activate_heal()
                "SHIELD":
                        player.activate_shield(3.0)
                "MULTISHOT":
                        player.activate_multishot(8.0)
                "FREEZE":
                        _freeze_all_zombies(2.0)
                "BOMB":
                        _bomb_aoe(player.global_position, 220.0, 120.0)
                "SPEED_BOOST":
                        player.activate_speed_boost(5.0)
                "PIERCE":
                        player.activate_pierce(8.0)
                "LIFE_STEAL":
                        player.activate_life_steal(10.0)
                "SLOW_TIME":
                        _slow_all_zombies(3.0, 0.3)
                "HOMING":
                        player.activate_homing(8.0)
                "EXPLOSION":
                        player.activate_explosion(8.0)
                "BERSERK":
                        player.activate_berserk(5.0)
                "NUKE":
                        _nuke_all()
                "INVINCIBLE":
                        player.activate_invincible(5.0)

func _freeze_all_zombies(duration: float):
        for z in get_tree().get_nodes_in_group("zombies"):
                if is_instance_valid(z) and z.has_method("freeze"):
                        z.freeze(duration)
        if AudioManager:
                AudioManager.play_spawn()  # sound hiệu ứng đóng băng

func _slow_all_zombies(duration: float, mult: float):
        # v2.8 FIX: Cancel previous slow timer to prevent race condition
        if _slow_timer and is_instance_valid(_slow_timer):
                # A previous slow is active - clear_slow all first before applying new
                for z in get_tree().get_nodes_in_group("zombies"):
                        if is_instance_valid(z) and z.has_method("clear_slow"):
                                z.clear_slow()
                _slow_timer.time_left = duration  # Reset timer
        else:
                for z in get_tree().get_nodes_in_group("zombies"):
                        if is_instance_valid(z) and z.has_method("set_slow"):
                                z.set_slow(mult)
                _slow_timer = get_tree().create_timer(duration)
                _slow_timer.timeout.connect(func():
                        for z in get_tree().get_nodes_in_group("zombies"):
                                if is_instance_valid(z) and z.has_method("clear_slow"):
                                        z.clear_slow()
                        _slow_timer = null
                )

func _bomb_aoe(center: Vector2, radius: float, damage: float):
        # Hiệu ứng nổ
        _spawn_bomb_fx(center, radius)
        # Damage tất cả zombie trong radius
        for z in get_tree().get_nodes_in_group("zombies"):
                if not is_instance_valid(z):
                        continue
                var d = center.distance_to(z.global_position)
                if d < radius:
                        z.take_damage(damage)
        if AudioManager:
                AudioManager.play_variation("explosion", 2.0)

func _spawn_bomb_fx(center: Vector2, radius: float):
        var fx = ColorRect.new()
        fx.color = Color(1.0, 0.4, 0.1, 0.6)
        fx.size = Vector2(radius * 2, radius * 2)
        fx.z_index = 5
        add_child(fx)
        fx.global_position = center - Vector2(radius, radius)
        var tween = create_tween()
        tween.tween_property(fx, "modulate:a", 0.0, 0.4)
        tween.tween_callback(fx.queue_free)

func _nuke_all():
        if AudioManager:
                AudioManager.play_variation("explosion", 4.0, 0.7)
        # Hiệu ứng nổ toàn màn hình
        var fx = ColorRect.new()
        fx.color = Color(1.0, 0.2, 0.1, 0.5)
        fx.size = Vector2(1280, 720)
        fx.position = Vector2(0, 0)
        fx.z_index = 10
        add_child(fx)
        var tween = create_tween()
        tween.tween_property(fx, "modulate:a", 0.0, 0.6)
        tween.tween_callback(fx.queue_free)
        # Force kill tất cả zombie
        var to_kill = []
        for z in get_tree().get_nodes_in_group("zombies"):
                if is_instance_valid(z) and not z.is_dead:
                        to_kill.append(z)
        for z in to_kill:
                z.force_kill()

# === HUD ===

var _last_hp_for_sound: float = 100.0  # v2.4: track HP for horror sound triggers

func _on_player_hp_changed(hp: float, max_hp: float):
        _refresh_hud()
        # v2.4: Horror sound feedback
        if not AudioManager:
                _last_hp_for_sound = hp
                return
        # Play bite sound when taking damage
        if hp < _last_hp_for_sound - 0.5:
                AudioManager.play_zombie_bite()
        # Heartbeat when HP < 30%
        if hp > 0 and hp / max_hp < 0.3:
                if randf() < 0.3:  # don't play every frame
                        AudioManager.play_heartbeat_slow()
        _last_hp_for_sound = hp

func _refresh_hud():
        if level_label:
                level_label.text = I18N.t("endless.level", [current_level])
        if hp_label and is_instance_valid(player):
                hp_label.text = I18N.t("endless.hp", [int(player.hp), int(player.max_hp)])
        if kills_label:
                var target_count = zombies_to_spawn - zombies_escaped
                kills_label.text = I18N.t("endless.kills", [level_kills, target_count])

func _show_message(text: String, duration: float):
        message_label.text = text
        message_label.visible = true
        message_label.modulate.a = 1.0
        var tween = create_tween()
        tween.tween_interval(duration)
        tween.tween_property(message_label, "modulate:a", 0.0, 0.6)
        tween.tween_callback(func(): message_label.visible = false)

# === CLEANUP ===

func _clear_zombies():
        for z in get_tree().get_nodes_in_group("zombies"):
                if is_instance_valid(z):
                        z.queue_free()

func _exit_tree():
        # Godot 4.7: clean up zombie references để tránh leak warnings
        _clear_zombies()
