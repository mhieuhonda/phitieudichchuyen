extends Control

## VirtualJoystick - Joystick ảo cho mobile (v0.8)
## Hiển thị ở góc dưới trái, hỗ trợ touch/mouse
## Tự động scale với mọi kích thước màn hình
## ĐÃ SỬA: Dùng get_global_rect() để đúng tọa độ màn hình

@export var max_distance: float = 80.0
@export var deadzone: float = 10.0
@export var joystick_color: Color = Color(1, 1, 1, 0.4)

var is_pressed: bool = false
var touch_index: int = -1
var joystick_output: Vector2 = Vector2.ZERO
var center_pos: Vector2 = Vector2.ZERO

@onready var base: TextureRect = $Base
@onready var stick: TextureRect = $Stick

func _ready():
        # Load textures
        var base_tex = load("res://assets/sprites/joystick_base.png")
        var stick_tex = load("res://assets/sprites/joystick_stick.png")
        if base_tex:
                base.texture = base_tex
        if stick_tex:
                stick.texture = stick_tex

        # Cho phép touch xuyên qua control (ta tự xử lý hit test)
        mouse_filter = Control.MOUSE_FILTER_IGNORE

        # Defer center calc để layout kịp compute
        call_deferred("_refresh_center")

func _is_touch_device() -> bool:
        if OS.has_feature("mobile"):
                return true
        if OS.has_feature("android"):
                return true
        if OS.has_feature("ios"):
                return true
        if DisplayServer.is_touchscreen_available():
                return true
        var os_name = OS.get_name()
        if os_name == "Android" or os_name == "iOS":
                return true
        return false

func _refresh_center():
        if base and is_instance_valid(base):
                # get_global_rect() trả về screen coords (vì parent là CanvasLayer)
                var rect = base.get_global_rect()
                center_pos = rect.position + rect.size / 2.0
                _update_stick_position(center_pos)

func _process(_delta):
        # Cập nhật center_pos mỗi frame để handle resize/rotation
        if not is_pressed:
                _refresh_center()

func _input(event: InputEvent):
        # Refresh center mỗi lần nhận input để chắc chắn đúng vị trí
        _refresh_center()

        if event is InputEventScreenTouch:
                if event.pressed:
                        if _is_in_joystick_area(event.position):
                                is_pressed = true
                                touch_index = event.index
                                _update_joystick(event.position)
                                get_viewport().set_input_as_handled()
                else:
                        if event.index == touch_index:
                                is_pressed = false
                                touch_index = -1
                                joystick_output = Vector2.ZERO
                                _update_stick_position(center_pos)
                                get_viewport().set_input_as_handled()

        elif event is InputEventScreenDrag:
                if event.index == touch_index and is_pressed:
                        _update_joystick(event.position)

        # Mouse fallback for testing
        elif event is InputEventMouseButton:
                if event.button_index == MOUSE_BUTTON_LEFT:
                        if event.pressed:
                                if _is_in_joystick_area(event.position):
                                        is_pressed = true
                                        _update_joystick(event.position)
                        else:
                                is_pressed = false
                                joystick_output = Vector2.ZERO
                                _update_stick_position(center_pos)

        elif event is InputEventMouseMotion:
                if is_pressed:
                        _update_joystick(event.position)

func _is_in_joystick_area(pos: Vector2) -> bool:
        # Hit area = base rect + 80px padding mỗi chiều (dễ chạm bằng ngón cái)
        if not base or not is_instance_valid(base):
                return false
        var joy_rect = base.get_global_rect().grow(80.0)
        return joy_rect.has_point(pos)

func _update_joystick(touch_pos: Vector2):
        var diff = touch_pos - center_pos
        var dist = diff.length()

        if dist <= deadzone:
                joystick_output = Vector2.ZERO
                _update_stick_position(center_pos)
                return

        var clamped_dist = min(dist, max_distance)
        var direction = diff.normalized()
        joystick_output = direction * (clamped_dist / max_distance)

        var stick_pos = center_pos + direction * clamped_dist
        _update_stick_position(stick_pos)

func _update_stick_position(pos: Vector2):
        if stick and is_instance_valid(stick):
                stick.global_position = pos - stick.size / 2.0

func get_direction() -> Vector2:
        return joystick_output

func is_active() -> bool:
        return is_pressed and joystick_output.length() > 0.1
