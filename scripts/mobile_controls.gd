extends Control

## MobileControls - Nút bấm ảo cho mobile (v3.4)
## v3.4: CHỈ còn 2 nút chính:
##       - Teleport: nút TRÒN màu XANH
##       - Throw (Ném phi tiêu): nút TRÒN màu ĐỎ
##       Đã xóa 3 nút kỹ năng (Dash/Shield/Multishot) theo yêu cầu.
## v3.3: Code-based UI (Button + StyleBoxFlat)
## - Multi-touch hoàn toàn
## - Touch & mouse mode tách biệt
## - Teleport check TRƯỚC nút ném để fix bug overlap

signal teleport_pressed()
signal throw_started()
signal throw_aim_updated(direction: Vector2, power: float)
signal throw_ended(direction: Vector2, power: float)

@onready var teleport_btn: Button = $TeleportButton
@onready var throw_btn: Button = $ThrowButton

var is_aiming: bool = false
var aim_touch_index: int = -1
var aim_touch_pos: Vector2 = Vector2.ZERO

var teleport_touch_index: int = -1

var is_mouse_aiming: bool = false
var mouse_aim_pos: Vector2 = Vector2.ZERO
var is_mouse_on_teleport: bool = false

var _throw_rect: Rect2 = Rect2()
var _teleport_rect: Rect2 = Rect2()

var _is_touch_device_cached: bool = false
var _is_touch_device_init: bool = false

# v3.4: Palette cho 2 nút chính
# Teleport = XANH LÁ (round)
# Throw    = ĐỎ    (round)
const COL_TELEPORT := Color(0.20, 0.95, 0.40)   # xanh lá sáng
const COL_TELEPORT_GLOW := Color(0.10, 0.60, 0.20)
const COL_THROW := Color(1.00, 0.22, 0.22)       # đỏ tươi
const COL_THROW_GLOW := Color(0.65, 0.05, 0.05)
const COL_BG := Color(0.05, 0.05, 0.10, 0.85)

# v3.4: hiệu ứng pulse cho nút khi sẵn sàng
var _teleport_pulse_tween: Tween = null
var _throw_pulse_tween: Tween = null

func _ready():
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        throw_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
        teleport_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

        # v3.4: Style 2 nút TRÒN
        _style_round_button(teleport_btn, COL_TELEPORT, COL_TELEPORT_GLOW)
        _style_round_button(throw_btn, COL_THROW, COL_THROW_GLOW)

        # Áp dụng kích thước tùy chỉnh
        visible = true
        call_deferred("_apply_custom_layout")
        call_deferred("_start_pulse_animations")

## v3.4: Style nút tròn — corner_radius = nửa kích thước → thành hình tròn
func _style_round_button(btn: Button, accent: Color, glow: Color):
        if not btn:
                return
        # Đảm bảo nút là hình vuông để khi bo góc = 50% thành tròn
        var sz = btn.size
        if sz.x == 0 or sz.y == 0:
                sz = Vector2(110, 110)
        var radius = int(min(sz.x, sz.y) * 0.5)

        var normal = StyleBoxFlat.new()
        normal.bg_color = Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 0.92)
        normal.corner_radius_top_left = radius
        normal.corner_radius_top_right = radius
        normal.corner_radius_bottom_left = radius
        normal.corner_radius_bottom_right = radius
        normal.border_width_top = 3
        normal.border_width_bottom = 3
        normal.border_width_left = 3
        normal.border_width_right = 3
        normal.border_color = Color(accent.r, accent.g, accent.b, 0.85)
        normal.content_margin_top = 4
        normal.content_margin_bottom = 4
        normal.content_margin_left = 4
        normal.content_margin_right = 4
        normal.shadow_color = Color(glow.r, glow.g, glow.b, 0.55)
        normal.shadow_size = 14
        normal.shadow_offset = Vector2(0, 0)

        var hover = normal.duplicate()
        hover.bg_color = Color(accent.r * 0.55, accent.g * 0.55, accent.b * 0.55, 0.98)
        hover.border_color = Color(accent.r, accent.g, accent.b, 1.0)
        hover.shadow_size = 22

        var pressed = normal.duplicate()
        pressed.bg_color = Color(accent.r * 0.75, accent.g * 0.75, accent.b * 0.75, 1.0)
        pressed.border_color = Color(1.0, 1.0, 1.0, 0.95)
        pressed.shadow_size = 8

        btn.add_theme_stylebox_override("normal", normal)
        btn.add_theme_stylebox_override("hover", hover)
        btn.add_theme_stylebox_override("pressed", pressed)
        btn.add_theme_stylebox_override("focus", normal)
        btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
        btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
        btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
        btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
        btn.add_theme_constant_override("outline_size", 3)

## v3.4: Hiệu ứng pulse nhẹ cho 2 nút — làm nút "sống động" hơn
func _start_pulse_animations():
        if teleport_btn and is_instance_valid(teleport_btn):
                _teleport_pulse_tween = create_tween().set_loops()
                _teleport_pulse_tween.tween_property(teleport_btn, "modulate", Color(1.05, 1.10, 1.05, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
                _teleport_pulse_tween.tween_property(teleport_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE)
        if throw_btn and is_instance_valid(throw_btn):
                _throw_pulse_tween = create_tween().set_loops()
                _throw_pulse_tween.tween_property(throw_btn, "modulate", Color(1.10, 1.05, 1.05, 1.0), 1.0).set_trans(Tween.TRANS_SINE)
                _throw_pulse_tween.tween_property(throw_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)

## v1.3: Áp dụng vị trí nút tùy chỉnh (đã lưu trong SettingsManager)
func _apply_custom_layout():
        if not SettingsManager.use_custom_layout:
                _apply_size_and_opacity()
                return
        var vp_size := get_viewport_rect().size
        if vp_size.x <= 1 or vp_size.y <= 1:
                call_deferred("_apply_custom_layout")
                return
        var defaults := {
                "teleport": Vector2(0.84, 0.83),
                "throw": Vector2(0.95, 0.85),
        }
        _apply_node_position(teleport_btn, "teleport", defaults["teleport"], vp_size)
        _apply_node_position(throw_btn, "throw", defaults["throw"], vp_size)
        var bscale := SettingsManager.button_size
        for n in [teleport_btn, throw_btn]:
                if n and is_instance_valid(n):
                        n.scale = Vector2(bscale, bscale)
        modulate.a = SettingsManager.ui_opacity

func _apply_size_and_opacity():
        var bscale := SettingsManager.button_size
        for n in [teleport_btn, throw_btn]:
                if n and is_instance_valid(n):
                        n.scale = Vector2(bscale, bscale)
        modulate.a = SettingsManager.ui_opacity

func _apply_node_position(node: Control, key: String, default_pos: Vector2, vp_size: Vector2):
        if not node or not is_instance_valid(node):
                return
        var normalized := SettingsManager.get_button_position(key, default_pos)
        var px := Vector2(normalized.x * vp_size.x, normalized.y * vp_size.y)
        node.set_anchors_preset(Control.PRESET_TOP_LEFT)
        node.anchor_left = 0.0
        node.anchor_top = 0.0
        node.anchor_right = 0.0
        node.anchor_bottom = 0.0
        node.position = px - node.size * 0.5
        node.position.x = clamp(node.position.x, 0, max(0, vp_size.x - node.size.x))
        node.position.y = clamp(node.position.y, 0, max(0, vp_size.y - node.size.y))

func _process(_delta):
        _update_visibility()
        if throw_btn and is_instance_valid(throw_btn):
                _throw_rect = throw_btn.get_global_rect().grow(20.0)
        if teleport_btn and is_instance_valid(teleport_btn):
                _teleport_rect = teleport_btn.get_global_rect().grow(12.0)

func _update_visibility():
        var is_touch = _is_touch_device()
        if not is_touch and not SettingsManager.show_joystick:
                visible = false
        else:
                visible = true

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
        AudioManager.play_teleport()
        teleport_pressed.emit()

func _on_teleport_down():
        if teleport_btn and is_instance_valid(teleport_btn):
                var tween = create_tween()
                tween.tween_property(teleport_btn, "modulate", Color(1.3, 1.5, 1.3, 1.0), 0.08)

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
                if _teleport_rect.has_point(event.position) and teleport_touch_index == -1:
                        teleport_touch_index = event.index
                        _on_teleport_down()
                        # TELEPORT NGAY KHI PRESS - không đợi release
                        _on_teleport_pressed()
                        get_viewport().set_input_as_handled()
                        return
                if _throw_rect.has_point(event.position) and aim_touch_index == -1 and not is_aiming:
                        aim_touch_index = event.index
                        aim_touch_pos = event.position
                        _start_aim()
                        if throw_btn and is_instance_valid(throw_btn):
                                var tween = create_tween()
                                tween.tween_property(throw_btn, "modulate", Color(1.4, 1.2, 1.2, 1.0), 0.08)
                        get_viewport().set_input_as_handled()
                        return
        else:
                if event.index == teleport_touch_index:
                        teleport_touch_index = -1
                        _on_teleport_up()
                        get_viewport().set_input_as_handled()
                elif event.index == aim_touch_index:
                        aim_touch_pos = event.position
                        _end_aim()
                        if throw_btn and is_instance_valid(throw_btn):
                                var tween = create_tween()
                                tween.tween_property(throw_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
                        get_viewport().set_input_as_handled()

func _handle_drag_event(event: InputEventScreenDrag):
        if event.index == aim_touch_index and is_aiming:
                aim_touch_pos = event.position
                _update_aim()
                get_viewport().set_input_as_handled()

func _handle_mouse_event(event: InputEvent):
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
                if event.pressed:
                        if _teleport_rect.has_point(event.position) and not is_mouse_on_teleport:
                                is_mouse_on_teleport = true
                                _on_teleport_down()
                                _on_teleport_pressed()
                                get_viewport().set_input_as_handled()
                        elif _throw_rect.has_point(event.position) and not is_mouse_aiming and not is_aiming:
                                is_mouse_aiming = true
                                mouse_aim_pos = event.position
                                _start_aim()
                                if throw_btn and is_instance_valid(throw_btn):
                                        var tween = create_tween()
                                        tween.tween_property(throw_btn, "modulate", Color(1.4, 1.2, 1.2, 1.0), 0.08)
                                get_viewport().set_input_as_handled()
                else:
                        if is_mouse_on_teleport:
                                is_mouse_on_teleport = false
                                _on_teleport_up()
                                get_viewport().set_input_as_handled()
                        elif is_mouse_aiming:
                                mouse_aim_pos = event.position
                                is_mouse_aiming = false
                                _end_aim()
                                if throw_btn and is_instance_valid(throw_btn):
                                        var tween = create_tween()
                                        tween.tween_property(throw_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
                                get_viewport().set_input_as_handled()

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
        throw_started.emit()

func _update_aim():
        var dir = _calculate_direction()
        var power = _calculate_power()
        throw_aim_updated.emit(dir, power)

func _end_aim():
        if not is_aiming:
                return
        is_aiming = false
        var dir = _calculate_direction()
        var power = _calculate_power()
        aim_touch_index = -1
        is_mouse_aiming = false
        throw_ended.emit(dir, power)

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
