extends Control

## MobileControls - Nút bấm ảo cho mobile (v0.9)
##
## v0.9 FIXES:
## - Tách biệt touch mode và mouse mode hoàn toàn (như virtual_joystick).
##   Trước đây, mouse events emulated từ touch gây ra conflict khi user
##   nhấn nhiều nút cùng lúc.
## - Track teleport button qua _input (không chỉ依赖 GUI pressed signal)
##   → responsive hơn, hỗ trợ multi-touch index tracking.
## - Fix hit area overlap giữa throw và teleport button.
## - Visual feedback (modulate) khi nhấn nút.
## - Teleport button: hỗ trợ tap-to-teleport responsive.
##
## Cơ chế ném phi tiêu (v0.7+):
##   Ấn giữ nút throw → kẻ chỉ màu đỏ từ player
##   Kéo ngón tay → xoay hướng + điều chỉnh lực
##   Thả tay → BẮN!

signal teleport_pressed()
signal throw_started()
signal throw_aim_updated(direction: Vector2, power: float)
signal throw_ended(direction: Vector2, power: float)

@onready var teleport_btn: TextureButton = $TeleportButton
@onready var throw_btn: TextureButton = $ThrowButton

# === Touch tracking (mobile) - cho nút throw ===
var is_aiming: bool = false
var aim_touch_index: int = -1
var aim_touch_pos: Vector2 = Vector2.ZERO

# === Touch tracking - cho nút teleport ===
var teleport_touch_index: int = -1

# === Mouse fallback (desktop testing) ===
var is_mouse_aiming: bool = false
var mouse_aim_pos: Vector2 = Vector2.ZERO
var is_mouse_on_teleport: bool = false

# Cache button rects (tính mỗi frame)
var _throw_rect: Rect2 = Rect2()
var _teleport_rect: Rect2 = Rect2()

# Touch device cache
var _is_touch_device_cached: bool = false
var _is_touch_device_init: bool = false

func _ready():
        # Load textures
        var tp_tex = load("res://assets/sprites/btn_teleport.png")
        var throw_tex = load("res://assets/sprites/btn_throw.png")
        if tp_tex:
                teleport_btn.texture_normal = tp_tex
        if throw_tex:
                throw_btn.texture_normal = throw_tex

        # Cho phép touch/mouse xuyên qua parent control (ta tự xử lý hit test)
        mouse_filter = Control.MOUSE_FILTER_IGNORE

        # throw_btn: IGNORE để không consume touch (ta tự xử lý aim)
        throw_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
        # teleport_btn: IGNORE để tránh duplicate handling giữa _input và GUI signals.
        # Trước đây (mouse_filter=STOP) gây ra teleport fire 2 lần: 1 từ _input,
        # 1 từ GUI pressed signal (do emulate_mouse_from_touch).
        teleport_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

        # NOTE: Không connect pressed/button_down/button_up signals vì
        # mouse_filter=IGNORE khiến GUI không nhận event → signals không fire.
        # Toàn bộ handling nằm trong _input để đảm bảo multi-touch hoạt động đúng.

        # Đảm bảo visible (sẽ update lại trong _process)
        visible = true

func _process(_delta):
        _update_visibility()
        # Cập nhật button rects mỗi frame (vì có thể resize/rotation)
        if throw_btn and is_instance_valid(throw_btn):
                var r = throw_btn.get_global_rect()
                # Mở rộng hit area 25px mỗi chiều để dễ chạm hơn
                _throw_rect = r.grow(25.0)
        if teleport_btn and is_instance_valid(teleport_btn):
                _teleport_rect = teleport_btn.get_global_rect().grow(15.0)

func _update_visibility():
        # Luôn hiện trên touch device; trên desktop chỉ hiện khi show_joystick=true
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

# === Teleport button handlers ===
func _on_teleport_pressed():
        AudioManager.play_ui_click()
        emit_signal("teleport_pressed")

func _on_teleport_down():
        # Visual feedback khi nhấn giữ
        if teleport_btn and is_instance_valid(teleport_btn):
                var tween = create_tween()
                tween.tween_property(teleport_btn, "modulate", Color(0.7, 0.85, 1.0, 1.0), 0.08)

func _on_teleport_up():
        # Reset visual feedback
        if teleport_btn and is_instance_valid(teleport_btn):
                var tween = create_tween()
                tween.tween_property(teleport_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _input(event: InputEvent):
        if _is_touch_device():
                # === TOUCH MODE (mobile) ===
                # Chỉ xử lý touch events, IGNORE mouse events hoàn toàn để
                # fix multi-touch bug (mouse events emulated từ touch gây conflict).
                if event is InputEventScreenTouch:
                        _handle_touch_event(event)
                elif event is InputEventScreenDrag:
                        _handle_drag_event(event)
        else:
                # === MOUSE MODE (desktop testing) ===
                _handle_mouse_event(event)

func _handle_touch_event(event: InputEventScreenTouch):
        if event.pressed:
                # Touch DOWN
                # Ưu tiên teleport trước (không overlap với throw nhờ layout v0.9)
                if _teleport_rect.has_point(event.position) and teleport_touch_index == -1:
                        teleport_touch_index = event.index
                        _on_teleport_down()
                        get_viewport().set_input_as_handled()
                # Throw button: bắt đầu aim
                elif _throw_rect.has_point(event.position) and aim_touch_index == -1 and not is_aiming:
                        aim_touch_index = event.index
                        aim_touch_pos = event.position
                        _start_aim()
                        # Visual feedback
                        if throw_btn and is_instance_valid(throw_btn):
                                var tween = create_tween()
                                tween.tween_property(throw_btn, "modulate", Color(1.0, 0.85, 0.7, 1.0), 0.08)
                        get_viewport().set_input_as_handled()
        else:
                # Touch UP
                if event.index == teleport_touch_index:
                        teleport_touch_index = -1
                        _on_teleport_up()
                        _on_teleport_pressed()
                        get_viewport().set_input_as_handled()
                elif event.index == aim_touch_index:
                        aim_touch_pos = event.position
                        _end_aim()
                        # Reset visual feedback
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
        # Mouse fallback for desktop testing
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
                if event.pressed:
                        # Ưu tiên teleport trước
                        if _teleport_rect.has_point(event.position) and not is_mouse_on_teleport:
                                is_mouse_on_teleport = true
                                _on_teleport_down()
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
                                _on_teleport_pressed()
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
        # Hướng từ tâm nút throw đến vị trí ngón tay
        var btn_center = throw_btn.global_position + throw_btn.size / 2.0
        var diff = _get_aim_pos() - btn_center
        if diff.length() < 12.0:
                return Vector2.ZERO
        return diff.normalized()

func _calculate_power() -> float:
        var btn_center = throw_btn.global_position + throw_btn.size / 2.0
        var dist = (_get_aim_pos() - btn_center).length()
        return clamp(dist / 150.0, GameManager.min_throw_power, GameManager.max_throw_power)
