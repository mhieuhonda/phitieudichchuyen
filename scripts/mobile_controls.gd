extends Control

## MobileControls - Nút bấm ảo cho mobile
## Teleport + Throw buttons ở góc dưới phải

signal teleport_pressed()
signal throw_started(pos: Vector2)
signal throw_ended(pos: Vector2)

@onready var teleport_btn: TextureButton = $TeleportButton
@onready var throw_btn: TextureButton = $ThrowButton

var is_aiming: bool = false
var aim_start_pos: Vector2 = Vector2.ZERO

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
	is_aiming = true
	aim_start_pos = throw_btn.global_position + throw_btn.size / 2.0
	emit_signal("throw_started", aim_start_pos)

func _on_throw_up():
	var end_pos = throw_btn.global_position + throw_btn.size / 2.0
	is_aiming = false
	emit_signal("throw_ended", end_pos)
