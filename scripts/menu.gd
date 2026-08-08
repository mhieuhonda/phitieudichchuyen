extends Control

## Menu - Menu chính (v3.3) - Code-based UI
## v3.3: Bỏ hoàn toàn PNG buttons. Tất cả nút bấm đều là Button (Godot Control)
##       với StyleBoxFlat tạo hiệu ứng hover, gradient, dark theme vàng-tím.
##       Sắp xếp gọn gàng bằng VBoxContainer trong CenterContainer.
## v3.2: Premium PNG UI (đã xóa)
## v3.0: Dọn dẹp - đã xóa nút Hướng Dẫn (Guide), xóa mọi tham chiếu online/zombie/gift code

@onready var play_button: Button = $CenterContainer/MenuVBox/PlayButton
@onready var characters_button: Button = $CenterContainer/MenuVBox/CharactersButton
@onready var settings_button: Button = $CenterContainer/MenuVBox/SettingsButton
@onready var quit_button: Button = $CenterContainer/MenuVBox/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var new_feature_label: RichTextLabel = $CenterContainer/MenuVBox/NewFeatureLabel
@onready var game_title: Label = $CenterContainer/MenuVBox/GameTitle

# Scale animation
const SCALE_UP := Vector2(1.06, 1.06)
const SCALE_NORMAL := Vector2(1.0, 1.0)
const SCALE_DURATION_UP := 0.1
const SCALE_DURATION_DOWN := 0.15

# Palette
const COL_GOLD := Color(1.0, 0.85, 0.3)
const COL_GOLD_DIM := Color(0.55, 0.45, 0.18)
const COL_CYAN := Color(0.4, 0.9, 1.0)
const COL_PURPLE := Color(0.7, 0.65, 1.0)
const COL_GREEN := Color(0.3, 1.0, 0.5)
const COL_RED := Color(1.0, 0.4, 0.3)
const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.13, 0.11, 0.22, 0.98)
const COL_BORDER := Color(0.35, 0.30, 0.55, 0.55)

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	characters_button.pressed.connect(_on_characters_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Style every button
	_style_primary_button(play_button, COL_GOLD)
	_style_button(characters_button, COL_CYAN)
	_style_button(settings_button, COL_PURPLE)
	_style_button(quit_button, COL_RED)

	# Hover & click scale effects for ALL buttons
	for btn in [play_button, characters_button, settings_button, quit_button]:
		if btn:
			btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
			btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
			_setup_touch_scale(btn)

	# Listen for language changes
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

func _on_btn_hover(btn: Button, entering: bool):
	if not btn or not is_instance_valid(btn):
		return
	if entering:
		AudioManager.play_ui_hover()
		_animate_scale(btn, SCALE_UP, SCALE_DURATION_UP)
	else:
		_animate_scale(btn, SCALE_NORMAL, SCALE_DURATION_DOWN)

## Style một button thường (background + border accent)
func _style_button(btn: Button, accent: Color):
	if not btn:
		return
	var normal = StyleBoxFlat.new()
	normal.bg_color = COL_BG
	normal.corner_radius_top_left = 10
	normal.corner_radius_top_right = 10
	normal.corner_radius_bottom_left = 10
	normal.corner_radius_bottom_right = 10
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.35)
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	normal.shadow_color = Color(0, 0, 0, 0.45)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 3)

	var hover = normal.duplicate()
	hover.bg_color = COL_BG_HOVER
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.85)

	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.04, 0.04, 0.08, 0.98)
	pressed.border_color = Color(accent.r, accent.g, accent.b, 0.95)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)

## Style nút chính (Play) — gradient nổi bật hơn
func _style_primary_button(btn: Button, accent: Color):
	if not btn:
		return
	_style_button(btn, accent)
	# Đậm hơn: border dày hơn, glow shadow
	var normal = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if normal:
		normal.border_width_top = 3
		normal.border_width_bottom = 3
		normal.border_width_left = 3
		normal.border_width_right = 3
		normal.border_color = Color(accent.r, accent.g, accent.b, 0.65)
		normal.shadow_color = Color(accent.r * 0.6, accent.g * 0.4, 0.0, 0.55)
		normal.shadow_size = 14

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
		version_label.text = "v3.3 - Phi Tiêu Dịch Chuyển"
	if new_feature_label:
		if I18N.is_vi():
			new_feature_label.text = "[color=#ffaa00][b]v3.3:[/b][/color] Code-based UI — gọn gàng, không còn nút PNG\n[color=#44aaff][b]12 Nhân Vật[/b][/color]: Tất cả nhân vật đều mở khóa sẵn\n[color=#00ff88][b]Offline PvP[/b][/color]: Chơi với 5 AI trên bản đồ 2000×2000\n[color=#aa00ff][b]AI thông minh hơn[/b][/color]: né phi tiêu, dự đoán di chuyển, kiting\n[color=#ff8844][b]Vật lý mới[/b][/color]: ricochet, knockback, dash hiệu ứng"
		else:
			new_feature_label.text = "[color=#ffaa00][b]v3.3:[/b][/color] Code-based UI — clean, no more PNG buttons\n[color=#44aaff][b]12 Characters[/b][/color]: All unlocked\n[color=#00ff88][b]Offline PvP[/b][/color]: Play vs 5 AI on a 2000×2000 map\n[color=#aa00ff][b]Smarter AI[/b][/color]: dodge darts, predict movement, kiting\n[color=#ff8844][b]New physics[/b][/color]: ricochet, knockback, dash trails"
	if play_button:
		play_button.text = I18N.t("menu.play")
	if characters_button:
		characters_button.text = I18N.t("menu.characters")
	if settings_button:
		settings_button.text = I18N.t("menu.settings")
	if quit_button:
		quit_button.text = I18N.t("menu.quit")

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

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_quit_pressed()
