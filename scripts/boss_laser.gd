extends Node2D

## BossLaser - Tia laser của boss (v3.5)
## Cơ chế:
##   1. WARNING phase (warn_duration): vẽ tia mờ mờ (alpha thấp) để cảnh báo
##      Player có thời gian né. Phát sound warning beep.
##   2. ACTIVE phase (active_duration): tia sáng đậm, gây sát thương liên tục
##      đứng giữa tia = 2x damage (center multiplier), đứng rìa = 1x.
##      Phát sound laser liên tục.
##   3. FADE phase: tắt dần
##
## Hỗ trợ 2 mode:
##   - STATIC: tia thẳng từ boss theo hướng cố định
##   - SWEEP: tia quay vòng 360° (rage mode ở 10% HP)

enum Mode { STATIC, SWEEP }
enum Phase { WARNING, ACTIVE, FADE, DONE }

@onready var beam_line: Line2D = $BeamLine
@onready var center_line: Line2D = $CenterLine

var mode: int = Mode.STATIC
var phase: int = Phase.WARNING

var warn_duration: float = 1.0
var active_duration: float = 1.5
var fade_duration: float = 0.3

var warn_timer: float = 0.0
var active_timer: float = 0.0
var fade_timer: float = 0.0

var direction: Vector2 = Vector2.RIGHT  # hướng tia (STATIC) hoặc hướng bắt đầu (SWEEP)
var length: float = 1200.0              # độ dài tia
var width: float = 70.0                 # độ rộng tia (chiều ngang)
var center_width: float = 24.0          # độ rộng "lõi" giữa (2x damage)

var damage_per_sec: float = 100.0       # sát thương/giây (rìa tia)
var center_multiplier: float = 2.0      # stood in center = 2x damage

var sweep_angular_speed: float = TAU * 0.5  # rad/sec (0.5 vòng/giây)
var sweep_total_angle: float = TAU * 1.5    # tổng góc quét (1.5 vòng)

var boss_ref: Node2D = null  # boss sở hữu laser
var player_ref: CharacterBody2D = null  # target player (lấy mỗi frame)

var _sweep_angle_swept: float = 0.0
var _laser_sound_timer: float = 0.0

signal laser_finished(laser: Node2D)

const COLOR_WARNING := Color(1.0, 0.4, 0.2, 0.25)
const COLOR_ACTIVE_OUTER := Color(1.0, 0.15, 0.05, 0.85)
const COLOR_ACTIVE_CENTER := Color(1.0, 0.95, 0.5, 1.0)
const COLOR_SWEEP_WARNING := Color(0.9, 0.3, 1.0, 0.30)
const COLOR_SWEEP_ACTIVE := Color(0.7, 0.2, 1.0, 0.95)
const COLOR_SWEEP_CENTER := Color(1.0, 0.6, 1.0, 1.0)

func _ready():
    beam_line.width = width
    center_line.width = center_width
    _apply_phase_visual()

func setup_static(dir: Vector2, len: float, w: float, dmg_per_sec: float, warn: float, active: float, boss: Node2D):
    mode = Mode.STATIC
    direction = dir.normalized()
    length = len
    width = w
    damage_per_sec = dmg_per_sec
    warn_duration = warn
    active_duration = active
    boss_ref = boss
    _apply_phase_visual()

func setup_sweep(start_dir: Vector2, len: float, w: float, dmg_per_sec: float, warn: float, active: float, boss: Node2D, angular_speed: float = TAU * 0.5):
    mode = Mode.SWEEP
    direction = start_dir.normalized()
    length = len
    width = w
    damage_per_sec = dmg_per_sec
    warn_duration = warn
    active_duration = active
    boss_ref = boss
    sweep_angular_speed = angular_speed
    _apply_phase_visual()

func _process(delta):
    if phase == Phase.WARNING:
        warn_timer += delta
        # Pulse warning alpha for visibility
        var pulse = 0.6 + 0.4 * sin(warn_timer * 18.0)
        _set_warning_alpha(pulse)
        # Vẽ lại vị trí tia (nếu sweep thì đứng yên lúc warning)
        _update_beam_geometry()
        # Warning beep sound mỗi 0.25s
        if int(warn_timer * 4) > int((warn_timer - delta) * 4):
            AudioManager.play_variation("alarm", -3.0, 1.3)
        if warn_timer >= warn_duration:
            phase = Phase.ACTIVE
            active_timer = 0.0
            _apply_phase_visual()
            # Laser fire sound
            AudioManager.play_variation("laser", 4.0, 0.85)
            AudioManager.play_variation("bass", 3.0, 0.7)
    elif phase == Phase.ACTIVE:
        active_timer += delta
        if mode == Mode.SWEEP:
            direction = direction.rotated(sweep_angular_speed * delta)
            _sweep_angle_swept += abs(sweep_angular_speed * delta)
        _update_beam_geometry()
        _apply_damage(delta)
        # Looping laser hum sound
        _laser_sound_timer -= delta
        if _laser_sound_timer <= 0:
            AudioManager.play_variation("laser", 2.0, randf_range(0.95, 1.05))
            _laser_sound_timer = 0.35
        # Check end conditions
        var sweep_done = mode == Mode.SWEEP and _sweep_angle_swept >= sweep_total_angle
        if active_timer >= active_duration or sweep_done:
            phase = Phase.FADE
            fade_timer = 0.0
            _apply_phase_visual()
    elif phase == Phase.FADE:
        fade_timer += delta
        var t = clamp(fade_timer / fade_duration, 0.0, 1.0)
        _set_fade_alpha(1.0 - t)
        _update_beam_geometry()
        if fade_timer >= fade_duration:
            phase = Phase.DONE
            laser_finished.emit(self)
            queue_free()

func _apply_phase_visual():
    if phase == Phase.WARNING:
        if mode == Mode.STATIC:
            beam_line.default_color = COLOR_WARNING
            center_line.default_color = COLOR_WARNING
        else:
            beam_line.default_color = COLOR_SWEEP_WARNING
            center_line.default_color = COLOR_SWEEP_WARNING
        beam_line.width = width * 0.6
        center_line.width = center_width * 0.5
    elif phase == Phase.ACTIVE:
        if mode == Mode.STATIC:
            beam_line.default_color = COLOR_ACTIVE_OUTER
            center_line.default_color = COLOR_ACTIVE_CENTER
        else:
            beam_line.default_color = COLOR_SWEEP_ACTIVE
            center_line.default_color = COLOR_SWEEP_CENTER
        beam_line.width = width
        center_line.width = center_width
    elif phase == Phase.FADE:
        # Giữ màu active nhưng fade alpha
        pass

func _set_warning_alpha(a: float):
    var col = beam_line.default_color
    col.a = a
    beam_line.default_color = col
    var ccol = center_line.default_color
    ccol.a = a
    center_line.default_color = ccol

func _set_fade_alpha(a: float):
    var col = beam_line.default_color
    col.a = a * (0.85 if mode == Mode.STATIC else 0.95)
    beam_line.default_color = col
    var ccol = center_line.default_color
    ccol.a = a
    center_line.default_color = ccol

func _update_beam_geometry():
    if not boss_ref or not is_instance_valid(boss_ref):
        return
    global_position = boss_ref.global_position
    beam_line.clear_points()
    center_line.clear_points()
    beam_line.add_point(Vector2.ZERO)
    beam_line.add_point(direction * length)
    center_line.add_point(Vector2.ZERO)
    center_line.add_point(direction * length)
    # Rotate beam to align with direction (for visual thickness)
    beam_line.rotation = 0  # width is perpendicular by default
    center_line.rotation = 0

func _apply_damage(delta: float):
    if not boss_ref or not is_instance_valid(boss_ref):
        return
    # Lấy TẤT CẢ player từ group (fix v3.7: trước đây chỉ lấy players[0],
    # nếu player chết hoặc chưa spawn thì laser không gây damage cho ai)
    var players = get_tree().get_nodes_in_group("players")
    if players.is_empty():
        return
    # Tính vị trí player tương đối với boss
    for p in players:
        if not is_instance_valid(p) or not p.get("is_alive"):
            continue
        var to_player = p.global_position - boss_ref.global_position
        var dist_along = to_player.dot(direction)
        # FIX v3.7: abs(Vector2) trả về Vector2 (không phải scalar).
        # Phải dùng .length() để có khoảng cách vuông góc đúng.
        # Đây là nguyên nhân laser không gây sát thương.
        var perp_vec = to_player - direction * dist_along
        var dist_perp = perp_vec.length()
        # Trong phạm vi tia?
        if dist_along < 0 or dist_along > length:
            continue
        if dist_perp > width * 0.5:
            continue
        # Tính damage: center = 2x, rìa = 1x (linear interpolate theo dist_perp)
        var t_center = clamp(dist_perp / max(center_width * 0.5, 1.0), 0.0, 1.0)
        var dmg_multiplier = lerp(center_multiplier, 1.0, t_center)
        var dmg = damage_per_sec * dmg_multiplier * delta
        if p.has_method("take_damage_from"):
            p.take_damage_from(dmg, boss_ref)
        # Cache player_ref để dùng cho hit flash effect bên dưới
        player_ref = p
    # Hiệu ứng hit flash nhẹ cho player khi đứng trong laser
    if is_instance_valid(player_ref) and randf() < 0.3:
        var sprite = player_ref.get_node_or_null("Sprite")
        if sprite:
            sprite.modulate = Color(1.0, 0.4, 0.4, 1.0)
            var tween = create_tween()
            tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
