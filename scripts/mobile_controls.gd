extends Control

## MobileControls - Nút bấm ảo cho mobile
## Teleport + Throw buttons ở góc dưới phải
## Throw: hold button + kéo ngón tay để ngắm, thả để ném (slingshot)

signal teleport_pressed()
signal throw_started(pos: Vector2)
signal throw_ended(pos: Vector2)

@onready var teleport_btn: TextureButton = $TeleportButton
@onready var throw_btn: TextureButton = $ThrowButton

var is_aiming: bool = false
var aim_start_pos: Vector2 = Vector2.ZERO
var aim_current_pos: Vector2 = Vector2.ZERO
var active_throw_touch_index: int = -1

func _ready():
	# Load textures
	var tp_tex = load("res://assets/sprites/btn_teleport.png")
	var throw_tex = load("res://assets/sprites/btn_throw.png")
	if tp_tex:
		teleport_btn.texture_normal = tp_tex
	if throw_tex:
		throw_btn.texture_normal = throw_tex
	
	# Auto-hide on desktop
	if not OS.has_feature("mobile") and not OS.has_feature("android"):
		if not SettingsManager.show_joystick:
			visible = false
	
	teleport_btn.pressed.connect(_on_teleport_pressed)
	throw_btn.button_down.connect(_on_throw_down)
	throw_btn.button_up.connect(_on_throw_up)

func _on_teleport_pressed():
	emit_signal("teleport_pressed")

func _on_throw_down():
	# Bắt đầu aim: dùng vị trí ngón tay hiện tại làm start
	aim_start_pos = _get_active_touch_pos()
	if aim_start_pos == Vector2.ZERO:
		# Fallback: trung tâm nút
		aim_start_pos = throw_btn.global_position + throw_btn.size / 2.0
	aim_current_pos = aim_start_pos
	is_aiming = true
	emit_signal("throw_started", aim_start_pos)

func _on_throw_up():
	# Kết thúc aim: emit vị trí ngón tay hiện tại
	var end_pos = aim_current_pos if aim_current_pos != Vector2.ZERO else throw_btn.global_position + throw_btn.size / 2.0
	is_aiming = false
	active_throw_touch_index = -1
	emit_signal("throw_ended", end_pos)
	aim_current_pos = Vector2.ZERO
	aim_start_pos = Vector2.ZERO

func _input(event: InputEvent):
	if not is_aiming:
		return
	
	# Cập nhật vị trí ngón tay khi kéo (aim current)
	if event is InputEventScreenTouch and event.pressed and active_throw_touch_index == -1:
		active_throw_touch_index = event.index
		aim_current_pos = event.position
	elif event is InputEventScreenTouch and not event.pressed and event.index == active_throw_touch_index:
		aim_current_pos = event.position
		# Button up sẽ được gọi tự động
	elif event is InputEventScreenDrag and event.index == active_throw_touch_index:
		aim_current_pos = event.position
	# Mouse fallback (testing trên desktop)
	elif event is InputEventMouseMotion:
		aim_current_pos = event.global_position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		aim_current_pos = event.global_position

func _get_active_touch_pos() -> Vector2:
	# Trả về vị trí touch hiện tại nếu có
	# (Godot 4 không có API trực tiếp để lấy tất cả touch, nên dùng fallback)
	return Vector2.ZERO
