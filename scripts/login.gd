extends Control

## Login - Màn hình đăng nhập / đăng ký (v4.1)
## Scene: scenes/login.tscn
## - Toggle giữa login / register mode
## - Hiển thị thông báo lỗi / thành công
## - Sau khi đăng nhập thành công → quay lại menu

@onready var tab_login: Button = $CenterContainer/VBox/TabHBox/TabLogin
@onready var tab_register: Button = $CenterContainer/VBox/TabHBox/TabRegister
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var username_edit: LineEdit = $CenterContainer/VBox/FormVBox/UsernameEdit
@onready var password_edit: LineEdit = $CenterContainer/VBox/FormVBox/PasswordEdit
@onready var display_name_row: HBoxContainer = $CenterContainer/VBox/FormVBox/DisplayNameRow
@onready var display_name_edit: LineEdit = $CenterContainer/VBox/FormVBox/DisplayNameRow/DisplayNameEdit
@onready var submit_button: Button = $CenterContainer/VBox/SubmitButton
@onready var status_label: Label = $CenterContainer/VBox/StatusLabel
@onready var back_button: Button = $CenterContainer/VBox/BackHBox/BackButton
@onready var logout_button: Button = $CenterContainer/VBox/BackHBox/LogoutButton

var mode: String = "login"  # "login" or "register"

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.15, 0.13, 0.25, 0.98)
const COL_CYAN := Color(0.4, 0.9, 1.0)
const COL_GOLD := Color(1.0, 0.85, 0.3)
const COL_GREEN := Color(0.4, 0.9, 0.5)
const COL_RED := Color(1.0, 0.4, 0.3)
const COL_PURPLE := Color(0.7, 0.65, 1.0)

func _ready():
	tab_login.pressed.connect(func(): _set_mode("login"))
	tab_register.pressed.connect(func(): _set_mode("register"))
	submit_button.pressed.connect(_on_submit)
	back_button.pressed.connect(_on_back)
	logout_button.pressed.connect(_on_logout)
	AccountManager.login_failed.connect(_on_login_failed)
	AccountManager.register_failed.connect(_on_register_failed)
	AccountManager.logged_in.connect(_on_logged_in)
	AccountManager.logged_out.connect(_on_logged_out)
	# Style
	_style_button(tab_login, COL_CYAN)
	_style_button(tab_register, COL_PURPLE)
	_style_button(submit_button, COL_GREEN)
	_style_button(back_button, COL_RED)
	_style_button(logout_button, COL_GOLD)
	# Default mode
	_set_mode("login")
	# If already logged in, show status
	if AccountManager.is_logged_in():
		status_label.text = "✓ Đã đăng nhập: %s (Lv %d — %s)" % [
			AccountManager.get_display_name(),
			AccountManager.get_level(),
			AccountManager.get_title()
		]
		status_label.modulate = COL_GREEN
		logout_button.visible = true
	else:
		logout_button.visible = false
	AudioManager.play_music("menu")

func _set_mode(new_mode: String):
	mode = new_mode
	if mode == "login":
		title_label.text = "🔐 Đăng Nhập"
		submit_button.text = "Đăng nhập"
		display_name_row.visible = false
		tab_login.modulate = Color(1, 1, 1, 1)
		tab_register.modulate = Color(0.6, 0.6, 0.6, 1)
	else:
		title_label.text = "📝 Đăng Ký"
		submit_button.text = "Đăng ký"
		display_name_row.visible = true
		tab_login.modulate = Color(0.6, 0.6, 0.6, 1)
		tab_register.modulate = Color(1, 1, 1, 1)
	_status("")

func _status(text: String, color: Color = Color(0.7, 0.8, 0.9)):
	status_label.text = text
	status_label.modulate = color

func _on_submit():
	var username = username_edit.text.strip_edges().to_lower()
	var password = password_edit.text
	var display_name = display_name_edit.text.strip_edges()
	if username.is_empty() or password.is_empty():
		_status("⚠ Nhập đầy đủ tên đăng nhập và mật khẩu", COL_RED)
		return
	submit_button.disabled = true
	if mode == "login":
		_status("Đang đăng nhập...", COL_GOLD)
		AccountManager.login(username, password)
	else:
		_status("Đang đăng ký...", COL_GOLD)
		AccountManager.register(username, password, display_name)

func _on_login_failed(reason: String):
	_status("✗ " + reason, COL_RED)
	submit_button.disabled = false

func _on_register_failed(reason: String):
	_status("✗ " + reason, COL_RED)
	submit_button.disabled = false

func _on_logged_in(user: Dictionary):
	_status("✓ Đăng nhập thành công: %s (Lv %d — %s)" % [
		user.get("display_name", "?"),
		user.get("level", 1),
		user.get("title", "")
	], COL_GREEN)
	submit_button.disabled = false
	logout_button.visible = true
	AudioManager.play_confirm()
	# Auto-return to menu after 1.5s
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_logged_out():
	_status("Đã đăng xuất", Color(0.7, 0.8, 0.9))
	logout_button.visible = false

func _on_logout():
	AccountManager.logout()

func _on_back():
	AudioManager.play_cancel()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _style_button(btn: Button, accent: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = COL_BG
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	var hover = normal.duplicate()
	hover.bg_color = COL_BG_HOVER
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.9)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back()
