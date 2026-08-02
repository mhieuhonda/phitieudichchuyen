extends Control

## MobileControls - Nút bấm ảo cho mobile (v0.7)
## Cơ chế MỚI: Ấn giữ nút phi tiêu → xuất hiện kẻ chỉ màu đỏ
##                Kéo ngón tay để xoay hướng + điều chỉnh lực
##                Thả tay ra → BẮN!
## Cơ chế dịch chuyển: Chạm nút → dịch chuyển tới phi tiêu

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

func _ready():
	# Load textures
	var tp_tex = load("res://assets/sprites/btn_teleport.png")
	var throw_tex = load("res://assets/sprites/btn_throw.png")
	if tp_tex:
		teleport_btn.texture_normal = tp_tex
	if throw_tex:
		throw_btn.texture_normal = throw_tex

	_update_visibility()

	teleport_btn.pressed.connect(_on_teleport_pressed)

func _update_visibility():
	# Luôn hiện trên touch device; trên desktop chỉ hiện khi show_joystick=true
	var is_touch = _is_touch_device()
	if not is_touch and not SettingsManager.show_joystick:
		visible = false
	else:
		visible = true

func _is_touch_device() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()

func _on_teleport_pressed():
	emit_signal("teleport_pressed")

func _input(event: InputEvent):
	# === Touch handling ===
	if event is InputEventScreenTouch:
		if event.pressed:
			# Chạm vào nút throw → bắt đầu aim
			if _is_point_in_throw_button(event.position) and aim_touch_index == -1 and not is_aiming:
				aim_touch_index = event.index
				aim_touch_pos = event.position
				_start_aim()
		elif event.index == aim_touch_index:
			# Ngón tay đang aim được nhấc ra → bắn
			aim_touch_pos = event.position
			_end_aim()

	elif event is InputEventScreenDrag and event.index == aim_touch_index:
		aim_touch_pos = event.position
		_update_aim()

	# === Mouse fallback (desktop testing) ===
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_point_in_throw_button(event.position) and not is_mouse_aiming and not is_aiming:
			is_mouse_aiming = true
			mouse_aim_pos = event.position
			_start_aim()
		elif not event.pressed and is_mouse_aiming:
			mouse_aim_pos = event.position
			is_mouse_aiming = false
			_end_aim()

	elif event is InputEventMouseMotion and is_mouse_aiming:
		mouse_aim_pos = event.global_position
		_update_aim()

func _is_point_in_throw_button(pos: Vector2) -> bool:
	var rect = Rect2(throw_btn.global_position, throw_btn.size)
	# Mở rộng hit area 20px mỗi chiều để dễ chạm hơn
	var expanded = rect.grow(20.0)
	return expanded.has_point(pos)

func _get_aim_pos() -> Vector2:
	if aim_touch_index != -1:
		return aim_touch_pos
	if is_mouse_aiming:
		return mouse_aim_pos
	return throw_btn.global_position + throw_btn.size / 2.0

func _start_aim():
	is_aiming = true
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
	if diff.length() < 8.0:
		return Vector2.ZERO
	return diff.normalized()

func _calculate_power() -> float:
	var btn_center = throw_btn.global_position + throw_btn.size / 2.0
	var dist = (_get_aim_pos() - btn_center).length()
	return clamp(dist / 150.0, GameManager.min_throw_power, GameManager.max_throw_power)
