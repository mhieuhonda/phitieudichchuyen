extends Control

## MobileControls - Nút bấm ảo cho mobile (v1.0)
## - Throw + Teleport + 3 nút kỹ năng (Dash, Shield, Multishot)
## - Multi-touch hoàn toàn
## - Touch & mouse mode tách biệt

signal teleport_pressed()
signal throw_started()
signal throw_aim_updated(direction: Vector2, power: float)
signal throw_ended(direction: Vector2, power: float)
signal skill_dash_pressed()
signal skill_shield_pressed()
signal skill_multishot_pressed()

@onready var teleport_btn: TextureButton = $TeleportButton
@onready var throw_btn: TextureButton = $ThrowButton
@onready var skill_dash_btn: Button = $SkillDashButton
@onready var skill_shield_btn: Button = $SkillShieldButton
@onready var skill_multishot_btn: Button = $SkillMultishotButton

var is_aiming: bool = false
var aim_touch_index: int = -1
var aim_touch_pos: Vector2 = Vector2.ZERO

var teleport_touch_index: int = -1
var dash_touch_index: int = -1
var shield_touch_index: int = -1
var multishot_touch_index: int = -1

var is_mouse_aiming: bool = false
var mouse_aim_pos: Vector2 = Vector2.ZERO
var is_mouse_on_teleport: bool = false
var is_mouse_on_dash: bool = false
var is_mouse_on_shield: bool = false
var is_mouse_on_multishot: bool = false

var _throw_rect: Rect2 = Rect2()
var _teleport_rect: Rect2 = Rect2()
var _dash_rect: Rect2 = Rect2()
var _shield_rect: Rect2 = Rect2()
var _multishot_rect: Rect2 = Rect2()

var _is_touch_device_cached: bool = false
var _is_touch_device_init: bool = false

func _ready():
    var tp_tex = load("res://assets/sprites/btn_teleport.png")
    var throw_tex = load("res://assets/sprites/btn_throw.png")
    if tp_tex:
        teleport_btn.texture_normal = tp_tex
    if throw_tex:
        throw_btn.texture_normal = throw_tex

    mouse_filter = Control.MOUSE_FILTER_IGNORE
    throw_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
    teleport_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

    # Skill buttons giữ STOP để click通常 works
    if skill_dash_btn:
        skill_dash_btn.pressed.connect(func():
            emit_signal("skill_dash_pressed")
            AudioManager.play_ui_click()
        )
    if skill_shield_btn:
        skill_shield_btn.pressed.connect(func():
            emit_signal("skill_shield_pressed")
            AudioManager.play_ui_click()
        )
    if skill_multishot_btn:
        skill_multishot_btn.pressed.connect(func():
            emit_signal("skill_multishot_pressed")
            AudioManager.play_ui_click()
        )

    visible = true

    # v1.3: áp dụng vị trí tùy chỉnh nếu user đã Lưu layout
    call_deferred("_apply_custom_layout")

## v1.3: Áp dụng vị trí nút tùy chỉnh (đã lưu trong SettingsManager)
## Vị trí lưu dạng chuẩn hóa 0..1 theo viewport → chuyển sang pixel
func _apply_custom_layout():
    if not SettingsManager.use_custom_layout:
        return
    var vp_size := get_viewport_rect().size
    if vp_size.x <= 1 or vp_size.y <= 1:
        # Viewport chưa có kích thước, thử lại frame kế
        call_deferred("_apply_custom_layout")
        return
    # Vị trí mặc định chuẩn hóa cho mỗi nút (giống DEFAULT_POSITIONS trong ui_customization.gd)
    var defaults := {
        "teleport": Vector2(0.78, 0.85),
        "throw": Vector2(0.88, 0.78),
        "skill_dash": Vector2(0.50, 0.86),
        "skill_shield": Vector2(0.58, 0.86),
        "skill_multishot": Vector2(0.42, 0.86),
    }
    _apply_node_position(teleport_btn, "teleport", defaults["teleport"], vp_size)
    _apply_node_position(throw_btn, "throw", defaults["throw"], vp_size)
    _apply_node_position(skill_dash_btn, "skill_dash", defaults["skill_dash"], vp_size)
    _apply_node_position(skill_shield_btn, "skill_shield", defaults["skill_shield"], vp_size)
    _apply_node_position(skill_multishot_btn, "skill_multishot", defaults["skill_multishot"], vp_size)
    # Áp dụng button_size scale
    var bscale := SettingsManager.button_size
    for n in [teleport_btn, throw_btn, skill_dash_btn, skill_shield_btn, skill_multishot_btn]:
        if n and is_instance_valid(n):
            n.scale = Vector2(bscale, bscale)
    # Áp dụng opacity
    modulate.a = SettingsManager.ui_opacity

func _apply_node_position(node: Control, key: String, default_pos: Vector2, vp_size: Vector2):
    if not node or not is_instance_valid(node):
        return
    var normalized := SettingsManager.get_button_position(key, default_pos)
    var px := Vector2(normalized.x * vp_size.x, normalized.y * vp_size.y)
    # Bỏ anchor để set position tuyệt đối
    node.set_anchors_preset(Control.PRESET_TOP_LEFT)
    node.anchor_left = 0.0
    node.anchor_top = 0.0
    node.anchor_right = 0.0
    node.anchor_bottom = 0.0
    # Căn giữa nút vào điểm chuẩn hóa
    node.position = px - node.size * 0.5
    # Clamp để không tràn màn hình
    node.position.x = clamp(node.position.x, 0, max(0, vp_size.x - node.size.x))
    node.position.y = clamp(node.position.y, 0, max(0, vp_size.y - node.size.y))

func _process(_delta):
    _update_visibility()
    if throw_btn and is_instance_valid(throw_btn):
        _throw_rect = throw_btn.get_global_rect().grow(25.0)
    if teleport_btn and is_instance_valid(teleport_btn):
        _teleport_rect = teleport_btn.get_global_rect().grow(15.0)
    if skill_dash_btn and is_instance_valid(skill_dash_btn):
        _dash_rect = skill_dash_btn.get_global_rect().grow(10.0)
    if skill_shield_btn and is_instance_valid(skill_shield_btn):
        _shield_rect = skill_shield_btn.get_global_rect().grow(10.0)
    if skill_multishot_btn and is_instance_valid(skill_multishot_btn):
        _multishot_rect = skill_multishot_btn.get_global_rect().grow(10.0)

func _update_visibility():
    var is_touch = _is_touch_device()
    if not is_touch and not SettingsManager.show_joystick:
        visible = false
    else:
        visible = true
    # Skill buttons chỉ hiện trên mobile
    if skill_dash_btn: skill_dash_btn.visible = is_touch or SettingsManager.show_joystick
    if skill_shield_btn: skill_shield_btn.visible = is_touch or SettingsManager.show_joystick
    if skill_multishot_btn: skill_multishot_btn.visible = is_touch or SettingsManager.show_joystick

func _is_touch_device() -> bool:
    if _is_touch_device_init:
        return _is_touch_device_cached
    _is_touch_device_init = true
    if OS.has_feature("mobile"):
        _is_touch_device_cached = true
        return true
    if OS.has_feature("android"):
        _is_touch_device_cached = true
        return true
    if OS.has_feature("ios"):
        _is_touch_device_cached = true
        return true
    if DisplayServer.is_touchscreen_available():
        _is_touch_device_cached = true
        return true
    var os_name = OS.get_name()
    if os_name == "Android" or os_name == "iOS":
        _is_touch_device_cached = true
        return true
    _is_touch_device_cached = false
    return false

func _on_teleport_pressed():
    AudioManager.play_ui_click()
    emit_signal("teleport_pressed")

func _on_teleport_down():
    if teleport_btn and is_instance_valid(teleport_btn):
        var tween = create_tween()
        tween.tween_property(teleport_btn, "modulate", Color(0.7, 0.85, 1.0, 1.0), 0.08)

func _on_teleport_up():
    if teleport_btn and is_instance_valid(teleport_btn):
        var tween = create_tween()
        tween.tween_property(teleport_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _input(event: InputEvent):
    if _is_touch_device():
        if event is InputEventScreenTouch:
            _handle_touch_event(event)
        elif event is InputEventScreenDrag:
            _handle_drag_event(event)
    else:
        _handle_mouse_event(event)

func _handle_touch_event(event: InputEventScreenTouch):
    if event.pressed:
        # Skill buttons first (priority for left-side taps)
        if _dash_rect.has_point(event.position) and dash_touch_index == -1:
            dash_touch_index = event.index
            emit_signal("skill_dash_pressed")
            AudioManager.play_ui_click()
            get_viewport().set_input_as_handled()
            return
        if _shield_rect.has_point(event.position) and shield_touch_index == -1:
            shield_touch_index = event.index
            emit_signal("skill_shield_pressed")
            AudioManager.play_ui_click()
            get_viewport().set_input_as_handled()
            return
        if _multishot_rect.has_point(event.position) and multishot_touch_index == -1:
            multishot_touch_index = event.index
            emit_signal("skill_multishot_pressed")
            AudioManager.play_ui_click()
            get_viewport().set_input_as_handled()
            return
        if _teleport_rect.has_point(event.position) and teleport_touch_index == -1:
            teleport_touch_index = event.index
            _on_teleport_down()
            # TELEPORT NGAY KHI PRESS - không đợi release
            _on_teleport_pressed()
            get_viewport().set_input_as_handled()
        elif _throw_rect.has_point(event.position) and aim_touch_index == -1 and not is_aiming:
            aim_touch_index = event.index
            aim_touch_pos = event.position
            _start_aim()
            if throw_btn and is_instance_valid(throw_btn):
                var tween = create_tween()
                tween.tween_property(throw_btn, "modulate", Color(1.0, 0.85, 0.7, 1.0), 0.08)
            get_viewport().set_input_as_handled()
    else:
        if event.index == teleport_touch_index:
            teleport_touch_index = -1
            _on_teleport_up()
            # Không teleport lại khi release - đã teleport khi press rồi
            get_viewport().set_input_as_handled()
        elif event.index == aim_touch_index:
            aim_touch_pos = event.position
            _end_aim()
            if throw_btn and is_instance_valid(throw_btn):
                var tween = create_tween()
                tween.tween_property(throw_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
            get_viewport().set_input_as_handled()
        elif event.index == dash_touch_index:
            dash_touch_index = -1
        elif event.index == shield_touch_index:
            shield_touch_index = -1
        elif event.index == multishot_touch_index:
            multishot_touch_index = -1

func _handle_drag_event(event: InputEventScreenDrag):
    if event.index == aim_touch_index and is_aiming:
        aim_touch_pos = event.position
        _update_aim()
        get_viewport().set_input_as_handled()

func _handle_mouse_event(event: InputEvent):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if _dash_rect.has_point(event.position) and not is_mouse_on_dash:
                is_mouse_on_dash = true
                emit_signal("skill_dash_pressed")
                AudioManager.play_ui_click()
                get_viewport().set_input_as_handled()
            elif _shield_rect.has_point(event.position) and not is_mouse_on_shield:
                is_mouse_on_shield = true
                emit_signal("skill_shield_pressed")
                AudioManager.play_ui_click()
                get_viewport().set_input_as_handled()
            elif _multishot_rect.has_point(event.position) and not is_mouse_on_multishot:
                is_mouse_on_multishot = true
                emit_signal("skill_multishot_pressed")
                AudioManager.play_ui_click()
                get_viewport().set_input_as_handled()
            elif _teleport_rect.has_point(event.position) and not is_mouse_on_teleport:
                is_mouse_on_teleport = true
                _on_teleport_down()
                # TELEPORT NGAY KHI CLICK - không đợi release
                _on_teleport_pressed()
                get_viewport().set_input_as_handled()
            elif _throw_rect.has_point(event.position) and not is_mouse_aiming and not is_aiming:
                is_mouse_aiming = true
                mouse_aim_pos = event.position
                _start_aim()
                if throw_btn and is_instance_valid(throw_btn):
                    var tween = create_tween()
                    tween.tween_property(throw_btn, "modulate", Color(1.0, 0.85, 0.7, 1.0), 0.08)
                get_viewport().set_input_as_handled()
        else:
            if is_mouse_on_teleport:
                is_mouse_on_teleport = false
                _on_teleport_up()
                # Không teleport lại khi release - đã teleport khi click rồi
                get_viewport().set_input_as_handled()
            elif is_mouse_aiming:
                mouse_aim_pos = event.position
                is_mouse_aiming = false
                _end_aim()
                if throw_btn and is_instance_valid(throw_btn):
                    var tween = create_tween()
                    tween.tween_property(throw_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
                get_viewport().set_input_as_handled()
            elif is_mouse_on_dash:
                is_mouse_on_dash = false
            elif is_mouse_on_shield:
                is_mouse_on_shield = false
            elif is_mouse_on_multishot:
                is_mouse_on_multishot = false

    elif event is InputEventMouseMotion:
        if is_mouse_aiming:
            mouse_aim_pos = event.position
            _update_aim()

func _get_aim_pos() -> Vector2:
    if aim_touch_index != -1:
        return aim_touch_pos
    if is_mouse_aiming:
        return mouse_aim_pos
    return throw_btn.global_position + throw_btn.size / 2.0

func _start_aim():
    is_aiming = true
    AudioManager.play_aim_start()
    emit_signal("throw_started")

func _update_aim():
    var dir = _calculate_direction()
    var power = _calculate_power()
    emit_signal("throw_aim_updated", dir, power)

func _end_aim():
    if not is_aiming:
        return
    is_aiming = false
    var dir = _calculate_direction()
    var power = _calculate_power()
    aim_touch_index = -1
    is_mouse_aiming = false
    emit_signal("throw_ended", dir, power)

func _calculate_direction() -> Vector2:
    var btn_center = throw_btn.global_position + throw_btn.size / 2.0
    var diff = _get_aim_pos() - btn_center
    if diff.length() < 12.0:
        return Vector2.ZERO
    return diff.normalized()

func _calculate_power() -> float:
    var btn_center = throw_btn.global_position + throw_btn.size / 2.0
    var dist = (_get_aim_pos() - btn_center).length()
    return clamp(dist / 150.0, GameManager.min_throw_power, GameManager.max_throw_power)
