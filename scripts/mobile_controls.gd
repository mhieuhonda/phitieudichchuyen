extends Control

## MobileControls - Nút bấm ảo cho mobile (v0.8)
## ĐÃ SỬA: Luôn hiện trên touch device, đúng tọa độ màn hình
## Cơ chế: Ấn giữ nút phi tiêu → kẻ chỉ màu đỏ
##          Kéo ngón tay để xoay hướng + điều chỉnh lực
##          Thả tay ra → BẮN!

signal teleport_pressed()
signal throw_started()
signal throw_aim_updated(direction: Vector2, power: float)
signal throw_ended(direction: Vector2, power: float)

@onready var teleport_btn: TextureButton = $TeleportButton
@onready var throw_btn: TextureButton = $ThrowButton

# Touch tracking cho nút throw
var is_aiming: bool = false
var aim_touch_index: int = -1
var aim_touch_pos: Vector2 = Vector2.ZERO
# Mouse fallback (cho desktop testing)
var is_mouse_aiming: bool = false
var mouse_aim_pos: Vector2 = Vector2.ZERO
# Cache button rects (tính mỗi frame)
var _throw_rect: Rect2 = Rect2()
var _teleport_rect: Rect2 = Rect2()

func _ready():
        # Load textures
        var tp_tex = load("res://assets/sprites/btn_teleport.png")
        var throw_tex = load("res://assets/sprites/btn_throw.png")
        if tp_tex:
                teleport_btn.texture_normal = tp_tex
        if throw_tex:
                throw_btn.texture_normal = throw_tex

        # Cho phép touch/mouse xuyên qua control (ta tự xử lý hit test)
        # NHƯNG vẫn giữ texture hiển thị
        mouse_filter = Control.MOUSE_FILTER_IGNORE

        # teleport_btn & throw_btn: giữ mouse_filter PASS (default) để pressed signal hoạt động cho teleport
        # throw_btn: set IGNORE để không consume touch (ta tự xử lý aim)
        throw_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

        teleport_btn.pressed.connect(_on_teleport_pressed)

        # Đảm bảo visible (sẽ update lại trong _process)
        visible = true

func _process(_delta):
        _update_visibility()
        # Cập nhật button rects mỗi frame (vì có thể resize/rotation)
        if throw_btn and is_instance_valid(throw_btn):
                var r = throw_btn.get_global_rect()
                # Mở rộng hit area 30px mỗi chiều để dễ chạm hơn
                _throw_rect = r.grow(30.0)
        if teleport_btn and is_instance_valid(teleport_btn):
                _teleport_rect = teleport_btn.get_global_rect().grow(20.0)

func _update_visibility():
        # Luôn hiện trên touch device; trên desktop chỉ hiện khi show_joystick=true
        var is_touch = _is_touch_device()
        if not is_touch and not SettingsManager.show_joystick:
                visible = false
        else:
                visible = true

func _is_touch_device() -> bool:
        # Multiple checks để đảm bảo detect đúng trên mọi thiết bị
        if OS.has_feature("mobile"):
                return true
        if OS.has_feature("android"):
                return true
        if OS.has_feature("ios"):
                return true
        if DisplayServer.is_touchscreen_available():
                return true
        # Fallback: check nếu OS là Android/iOS
        var os_name = OS.get_name()
        if os_name == "Android" or os_name == "iOS":
                return true
        return false

func _on_teleport_pressed():
        AudioManager.play_ui_click()
        emit_signal("teleport_pressed")

func _input(event: InputEvent):
        # === Touch handling ===
        if event is InputEventScreenTouch:
                if event.pressed:
                        # Chạm vào nút throw → bắt đầu aim
                        if _throw_rect.has_point(event.position) and aim_touch_index == -1 and not is_aiming:
                                aim_touch_index = event.index
                                aim_touch_pos = event.position
                                _start_aim()
                                get_viewport().set_input_as_handled()
                else:
                        if event.index == aim_touch_index:
                                # Ngón tay đang aim được nhấc ra → bắn
                                aim_touch_pos = event.position
                                _end_aim()
                                get_viewport().set_input_as_handled()

        elif event is InputEventScreenDrag and event.index == aim_touch_index:
                aim_touch_pos = event.position
                _update_aim()

        # === Mouse fallback (desktop testing) ===
        elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
                if event.pressed and _throw_rect.has_point(event.position) and not is_mouse_aiming and not is_aiming:
                        is_mouse_aiming = true
                        mouse_aim_pos = event.position
                        _start_aim()
                        get_viewport().set_input_as_handled()
                elif not event.pressed and is_mouse_aiming:
                        mouse_aim_pos = event.position
                        is_mouse_aiming = false
                        _end_aim()
                        get_viewport().set_input_as_handled()

        elif event is InputEventMouseMotion and is_mouse_aiming:
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
