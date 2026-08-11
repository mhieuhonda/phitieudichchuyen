extends Control

## Login - Màn hình đăng nhập / đăng ký (v4.2)
## Scene: scenes/login.tscn
## - Toggle giữa login / register mode
## - Hiển thị thông báo lỗi / thành công
## - v4.2: Premium styling đồng bộ với menu (hover scale, glow title, shadow buttons)
## - v4.2: Loading spinner + auto re-enable button on timeout (fix "nút cứng đơ")
## - v4.2: Nút "Chơi guest" để bỏ qua login nếu user không muốn đăng ký
## - v4.2: Hỗ trợ LoginRouter.next_scene — sau khi login OK, forward sang scene đó
##   (nếu rỗng thì về menu.tscn như cũ)
## - v4.2: Branding "Game developed by Hieu Louis"

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
@onready var guest_button: Button = $CenterContainer/VBox/BackHBox/GuestButton
@onready var developer_label: Label = $DeveloperLabel

var mode: String = "login"  # "login" or "register"
var _submit_lock: bool = false  # v4.2: chống double-submit
var _spinner_tween: Tween = null

const SCALE_UP := Vector2(1.05, 1.05)
const SCALE_NORMAL := Vector2(1.0, 1.0)
const SCALE_DURATION_UP := 0.1
const SCALE_DURATION_DOWN := 0.15

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.13, 0.11, 0.22, 0.98)
const COL_BG_PRESSED := Color(0.04, 0.04, 0.08, 0.98)
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
	guest_button.pressed.connect(_on_guest)
	username_edit.text_submitted.connect(func(_t): _on_submit())
	password_edit.text_submitted.connect(func(_t): _on_submit())
	display_name_edit.text_submitted.connect(func(_t): _on_submit())
	AccountManager.login_failed.connect(_on_login_failed)
	AccountManager.register_failed.connect(_on_register_failed)
	AccountManager.logged_in.connect(_on_logged_in)
	AccountManager.logged_out.connect(_on_logged_out)
	# Style
	_style_button(tab_login, COL_CYAN)
	_style_button(tab_register, COL_PURPLE)
	_style_primary_button(submit_button, COL_GREEN)
	_style_button(back_button, COL_RED)
	_style_button(logout_button, COL_GOLD)
	_style_button(guest_button, COL_CYAN)
	# Hover & touch scale effects
	for btn in [tab_login, tab_register, submit_button, back_button, logout_button, guest_button]:
		if btn:
			btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
			btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
			_setup_touch_scale(btn)
	# Premium title glow
	if title_label:
		var tween = create_tween().set_loops()
		tween.tween_property(title_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(title_label, "modulate", Color(0.85, 0.85, 0.95, 0.92), 2.0).set_trans(Tween.TRANS_SINE)
	# Branding
	if developer_label:
		developer_label.text = "Game developed by Hieu Louis"
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

# === Hover / touch scale effects ===

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

# === Mode handling ===

func _set_mode(new_mode: String):
	mode = new_mode
	if mode == "login":
		title_label.text = "🔐 ĐĂNG NHẬP"
		submit_button.text = "Đăng nhập"
		display_name_row.visible = false
		tab_login.modulate = Color(1, 1, 1, 1)
		tab_register.modulate = Color(0.6, 0.6, 0.6, 1)
	else:
		title_label.text = "📝 ĐĂNG KÝ"
		submit_button.text = "Đăng ký"
		display_name_row.visible = true
		tab_login.modulate = Color(0.6, 0.6, 0.6, 1)
		tab_register.modulate = Color(1, 1, 1, 1)
	_status("")

func _status(text: String, color: Color = Color(0.7, 0.8, 0.9)):
	status_label.text = text
	status_label.modulate = color

# === Submit ===

func _on_submit():
	if _submit_lock:
		return
	var username = username_edit.text.strip_edges().to_lower()
	var password = password_edit.text
	var display_name = display_name_edit.text.strip_edges()
	if mode == "register" and username.length() < 3:
		_status("⚠ Tên đăng nhập phải 3-32 ký tự", COL_RED)
		AudioManager.play_cancel()
		return
	if password.length() < 6:
		_status("⚠ Mật khẩu phải ít nhất 6 ký tự", COL_RED)
		AudioManager.play_cancel()
		return
	# v4.2: lock + show clear loading state + spinner
	_submit_lock = true
	submit_button.disabled = true
	submit_button.text = "⏳ Đang xử lý..." if mode == "login" else "⏳ Đang đăng ký..."
	_start_spinner()
	AudioManager.play_ui_click()
	if mode == "login":
		_status("Đang kết nối server và đăng nhập...", COL_GOLD)
		AccountManager.login(username, password)
	else:
		_status("Đang đăng ký tài khoản...", COL_GOLD)
		AccountManager.register(username, password, display_name)
	# v4.2: safety net — sau 20s nếu vẫn chưa có response, re-enable button
	# (tránh "nút cứng đơ" vĩnh viễn nếu HTTP timeout bị skip)
	get_tree().create_timer(20.0).timeout.connect(_on_submit_timeout)

func _on_submit_timeout():
	if _submit_lock:
		_stop_spinner()
		_submit_lock = false
		submit_button.disabled = false
		submit_button.text = "Đăng nhập" if mode == "login" else "Đăng ký"
		_status("✗ Hết thời gian chờ server — kiểm tra mạng và thử lại", COL_RED)
		AudioManager.play_cancel()

func _start_spinner():
	_stop_spinner()
	if not is_instance_valid(submit_button):
		return
	_spinner_tween = create_tween().set_loops()
	_spinner_tween.tween_property(submit_button, "modulate", Color(1.0, 0.95, 0.5, 1.0), 0.4).set_trans(Tween.TRANS_SINE)
	_spinner_tween.tween_property(submit_button, "modulate", Color(0.85, 0.85, 1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE)

func _stop_spinner():
	if _spinner_tween and _spinner_tween.is_valid():
		_spinner_tween.kill()
	_spinner_tween = null
	if is_instance_valid(submit_button):
		submit_button.modulate = Color(1, 1, 1, 1)

# === Account callbacks ===

func _on_login_failed(reason: String):
	_stop_spinner()
	_submit_lock = false
	submit_button.disabled = false
	submit_button.text = "Đăng nhập" if mode == "login" else "Đăng ký"
	_status("✗ " + reason, COL_RED)
	AudioManager.play_cancel()

func _on_register_failed(reason: String):
	_stop_spinner()
	_submit_lock = false
	submit_button.disabled = false
	submit_button.text = "Đăng nhập" if mode == "login" else "Đăng ký"
	_status("✗ " + reason, COL_RED)
	AudioManager.play_cancel()

func _on_logged_in(user: Dictionary):
	_stop_spinner()
	_submit_lock = false
	submit_button.disabled = false
	submit_button.text = "Đăng nhập" if mode == "login" else "Đăng ký"
	_status("✓ Đăng nhập thành công: %s (Lv %d — %s)" % [
		user.get("display_name", "?"),
		user.get("level", 1),
		user.get("title", "")
	], COL_GREEN)
	logout_button.visible = true
	AudioManager.play_confirm()
	# Auto-forward after 1.2s
	await get_tree().create_timer(1.2).timeout
	_forward_to_next_scene()

func _on_logged_out():
	_stop_spinner()
	_submit_lock = false
	submit_button.disabled = false
	submit_button.text = "Đăng nhập" if mode == "login" else "Đăng ký"
	_status("Đã đăng xuất", Color(0.7, 0.8, 0.9))
	logout_button.visible = false

func _on_logout():
	AudioManager.play_ui_click()
	AccountManager.logout()

func _on_guest():
	AudioManager.play_ui_click()
	AudioManager.play_confirm()
	_status("Chơi guest — sẽ không lưu tiến trình online", Color(0.7, 0.8, 0.9))
	# Forward to next_scene after short delay
	await get_tree().create_timer(0.4).timeout
	_forward_to_next_scene()

func _forward_to_next_scene():
	var next_scene = ""
	if LoginRouter:
		next_scene = LoginRouter.next_scene
		LoginRouter.next_scene = ""  # clear
	if next_scene.is_empty():
		next_scene = "res://scenes/menu.tscn"
	get_tree().change_scene_to_file(next_scene)

func _on_back():
	AudioManager.play_cancel()
	# Clear any pending route
	if LoginRouter:
		LoginRouter.next_scene = ""
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

# === Styling (match menu.gd premium look) ===

func _style_button(btn: Button, accent: Color):
	if not btn:
		return
	var normal = StyleBoxFlat.new()
	normal.bg_color = COL_BG
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.35)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.shadow_color = Color(0, 0, 0, 0.45)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 2)
	var hover = normal.duplicate()
	hover.bg_color = COL_BG_HOVER
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.85)
	var pressed = normal.duplicate()
	pressed.bg_color = COL_BG_PRESSED
	pressed.border_color = Color(accent.r, accent.g, accent.b, 0.95)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override("disabled", normal)

func _style_primary_button(btn: Button, accent: Color):
	if not btn:
		return
	_style_button(btn, accent)
	var normal = btn.get_theme_stylebox("normal") as StyleBoxFlat
	if normal:
		normal.border_width_top = 3
		normal.border_width_bottom = 3
		normal.border_width_left = 3
		normal.border_width_right = 3
		normal.border_color = Color(accent.r, accent.g, accent.b, 0.65)
		normal.shadow_color = Color(accent.g * 0.6, accent.g * 0.4, 0.0, 0.55)
		normal.shadow_size = 10

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back()
