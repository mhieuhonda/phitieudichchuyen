extends Control

## PauseMenu - Menu tam dung trong game (v2.8)
## ESC/P de tam dung, tiep tuc, quay lai menu

@onready var resume_button: Button = $VBox/ResumeButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var menu_button: Button = $VBox/MenuButton
@onready var title_label: Label = $TitleLabel

var _previous_scene: String = ""

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Work even when tree is paused
	
	resume_button.pressed.connect(_on_resume)
	settings_button.pressed.connect(_on_settings)
	menu_button.pressed.connect(_on_menu)
	
	for btn in [resume_button, settings_button, menu_button]:
		if btn:
			btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())
	
	_apply_premium_styling()
	_refresh_ui()
	
	if I18N:
		I18N.language_changed.connect(func(_l): _refresh_ui())

func _apply_premium_styling():
	# Panel background
	var panel = $Panel
	if panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.02, 0.06, 0.95)
		style.border_color = Color(0.5, 0.3, 0.7, 0.5)
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		style.shadow_color = Color(0.3, 0, 0.3, 0.5)
		style.shadow_size = 20
		panel.add_theme_stylebox_override("panel", style)
	
	_style_button(resume_button, Color(0.04, 0.12, 0.06, 0.9), Color(0.3, 1.0, 0.5))
	_style_button(settings_button, Color(0.08, 0.06, 0.14, 0.9), Color(0.7, 0.6, 1.0))
	_style_button(menu_button, Color(0.12, 0.04, 0.04, 0.9), Color(1.0, 0.5, 0.3))

func _style_button(btn: Button, bg_color: Color, accent: Color):
	if not btn:
		return
	var style_n = StyleBoxFlat.new()
	style_n.bg_color = bg_color
	style_n.corner_radius_top_left = 10
	style_n.corner_radius_top_right = 10
	style_n.corner_radius_bottom_left = 10
	style_n.corner_radius_bottom_right = 10
	style_n.border_color = Color(accent.r, accent.g, accent.b, 0.3)
	style_n.border_width_top = 1
	style_n.border_width_bottom = 1
	style_n.border_width_left = 1
	style_n.border_width_right = 1
	style_n.content_margin_top = 10
	style_n.content_margin_bottom = 10
	style_n.content_margin_left = 30
	style_n.content_margin_right = 30
	var style_h = style_n.duplicate()
	style_h.bg_color = Color(bg_color.r + 0.06, bg_color.g + 0.04, bg_color.b + 0.06, bg_color.a)
	style_h.border_color = Color(accent.r, accent.g, accent.b, 0.6)
	btn.add_theme_stylebox_override("normal", style_n)
	btn.add_theme_stylebox_override("hover", style_h)

func _refresh_ui():
	if title_label:
		title_label.text = I18N.t("pause.title")
	if resume_button:
		resume_button.text = I18N.t("pause.resume")
	if settings_button:
		settings_button.text = I18N.t("pause.settings")
	if menu_button:
		menu_button.text = I18N.t("pause.menu")

func show_pause():
	visible = true
	get_tree().paused = true
	AudioManager.play_ui_click()

func hide_pause():
	visible = false
	get_tree().paused = false
	AudioManager.play_ui_click()

func _on_resume():
	hide_pause()

func _on_settings():
	hide_pause()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_menu():
	hide_pause()
	if NetworkManager and NetworkManager.is_server_connected():
		NetworkManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _input(event: InputEvent):
	if event.is_action_pressed("menu_back") or event.is_action_pressed("pause"):
		if visible:
			hide_pause()
		else:
			show_pause()
