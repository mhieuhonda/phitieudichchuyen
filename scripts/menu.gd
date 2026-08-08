extends Control

## Menu - Menu chính (v3.2) - Premium PNG UI Edition
## v3.2: Tất cả nút đều dùng PNG (TextureButton), bỏ AnhNen/TenGame khỏi sảnh chờ
##       Fix PlayButton kích thước + vị trí, Fix SettingsButton bị lấp
## v3.1: Sử dụng ảnh custom (PlayButton, SettingButton, Win, YouDie)
## v3.0: Dọn dẹp - đã xóa nút Hướng Dẫn (Guide), xóa mọi tham chiếu online/zombie/gift code

@onready var play_button: TextureButton = $PlayButton
@onready var characters_button: TextureButton = $CharactersButton
@onready var settings_button: TextureButton = $SettingsButton
@onready var quit_button: TextureButton = $QuitButton
@onready var version_label: Label = $VersionLabel
@onready var new_feature_label: RichTextLabel = $NewFeatureLabel
@onready var game_title: Label = $GameTitle

# Scale animation
const SCALE_UP := Vector2(1.08, 1.08)
const SCALE_NORMAL := Vector2(1.0, 1.0)
const SCALE_DURATION_UP := 0.1
const SCALE_DURATION_DOWN := 0.15

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	characters_button.pressed.connect(_on_characters_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Touch scale effects for ALL buttons
	_setup_touch_scale(play_button)
	_setup_touch_scale(characters_button)
	_setup_touch_scale(settings_button)
	_setup_touch_scale(quit_button)

	# Hover effects for TextureButtons
	for btn in [play_button, characters_button, settings_button, quit_button]:
		if btn:
			btn.mouse_entered.connect(_on_tex_btn_hover.bind(btn, true))
			btn.mouse_exited.connect(_on_tex_btn_hover.bind(btn, false))

	# v2.4: Listen for language changes
	if I18N:
		I18N.language_changed.connect(func(_l): _refresh_ui())

	_apply_premium_styling()
	_refresh_ui()
	AudioManager.play_music("menu")

## Setup touch scale animation (phóng to khi chạm, thu nhỏ khi thả)
func _setup_touch_scale(btn: Control):
	if not btn:
		return
	btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.pressed:
				_animate_scale(btn, SCALE_UP, SCALE_DURATION_UP)
			else:
				_animate_scale(btn, SCALE_NORMAL, SCALE_DURATION_DOWN)
		elif event is InputEventScreenTouch:
			if event.pressed:
				_animate_scale(btn, SCALE_UP, SCALE_DURATION_UP)
			else:
				_animate_scale(btn, SCALE_NORMAL, SCALE_DURATION_DOWN)
	)

func _animate_scale(control: Control, target_scale: Vector2, duration: float):
	if not is_instance_valid(control):
		return
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(control, "scale", target_scale, duration)

func _on_tex_btn_hover(btn: TextureButton, entering: bool):
	if not btn or not is_instance_valid(btn):
		return
	if entering:
		AudioManager.play_ui_hover()
		_animate_scale(btn, SCALE_UP, SCALE_DURATION_UP)
	else:
		_animate_scale(btn, SCALE_NORMAL, SCALE_DURATION_DOWN)

func _apply_premium_styling():
	# Game title glow pulse effect
	if game_title:
		var tween = create_tween().set_loops()
		tween.tween_property(game_title, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(game_title, "modulate", Color(0.85, 0.85, 0.95, 0.9), 2.0).set_trans(Tween.TRANS_SINE)

	# New feature label styling
	if new_feature_label:
		new_feature_label.add_theme_color_override("default_color", Color(0.75, 0.8, 0.9))

func _refresh_ui():
	if version_label:
		version_label.text = "v3.2 - Phi Tiêu Dịch Chuyển"
	if new_feature_label:
		if I18N.is_vi():
			new_feature_label.text = "[color=#ffaa00][b]v3.2:[/b][/color] Premium PNG UI - Tất cả nút đều là ảnh custom\n[color=#44aaff][b]12 Nhân Vật[/b][/color]: Tất cả nhân vật đều mở khóa sẵn\n[color=#00ff88][b]Offline PvP[/b][/color]: Chơi với 5 AI trên bản đồ 2000x2000\n[color=#aa00ff][b]Premium UI[/b][/color]: Custom PNG buttons, touch scale effects"
		else:
			new_feature_label.text = "[color=#ffaa00][b]v3.2:[/b][/color] Premium PNG UI - All buttons are custom images\n[color=#44aaff][b]12 Characters[/b][/color]: All characters unlocked\n[color=#00ff88][b]Offline PvP[/b][/color]: Play vs 5 AI on a 2000x2000 map\n[color=#aa00ff][b]Premium UI[/b][/color]: Custom PNG buttons, touch scale effects"

func _on_play_pressed():
	AudioManager.play_ui_click()
	AudioManager.play_confirm()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_characters_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/character_screen.tscn")

func _on_settings_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
	AudioManager.play_cancel()
	get_tree().quit()
