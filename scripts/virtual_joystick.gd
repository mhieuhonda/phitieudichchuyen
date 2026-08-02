extends Control

## VirtualJoystick - Joystick ảo cho mobile
## Hiển thị ở góc dưới trái, hỗ trợ touch/mouse

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
	
	# Auto-hide on desktop if not forced
	if not OS.has_feature("mobile") and not OS.has_feature("android"):
		if not SettingsManager.show_joystick:
			visible = false
	
	center_pos = base.position + base.size / 2.0
	_update_stick_position(center_pos)

func _input(event: InputEvent):
	if not visible:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_in_joystick_area(event.position):
				is_pressed = true
				touch_index = event.index
				_update_joystick(event.position)
		else:
			if event.index == touch_index:
				is_pressed = false
				touch_index = -1
				joystick_output = Vector2.ZERO
				_update_stick_position(center_pos)
	
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
	var joy_rect = Rect2(base.global_position - Vector2(60, 60), base.size + Vector2(120, 120))
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
	stick.position = pos - stick.size / 2.0

func get_direction() -> Vector2:
	return joystick_output

func is_active() -> bool:
	return is_pressed and joystick_output.length() > 0.1
