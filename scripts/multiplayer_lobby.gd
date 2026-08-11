extends Control

## MultiplayerLobby - Sảnh chờ multiplayer (v4.2)
## Scene: scenes/multiplayer_lobby.tscn
## v4.2:
##   - Premium styling đồng bộ với menu (hover scale, glow title, shadow buttons)
##   - Auto-connect tới server khi vào lobby (không cần bấm [Kết nối] thủ công)
##   - Hiển thị trạng thái kết nối realtime rõ ràng
##   - Branding "Game developed by Hieu Louis"
##   - Nút [Kết nối lại] khi mất kết nối
## v4.1:
##   - Hiển thị trạng thái đăng nhập + nút đăng nhập/đăng ký
##   - Hiển thị level/title của người chơi
##   - UI compact hơn

@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var name_edit: LineEdit = $CenterContainer/VBox/TopHBox/NameEdit
@onready var connect_button: Button = $CenterContainer/VBox/TopHBox/ConnectButton
@onready var status_label: Label = $CenterContainer/VBox/StatusLabel
@onready var account_label: Label = $CenterContainer/VBox/AccountHBox/AccountLabel
@onready var account_button: Button = $CenterContainer/VBox/AccountHBox/AccountButton
@onready var room_name_edit: LineEdit = $CenterContainer/VBox/RoomHBox/RoomNameEdit
@onready var create_button: Button = $CenterContainer/VBox/RoomHBox/CreateButton
@onready var refresh_button: Button = $CenterContainer/VBox/RoomHBox/RefreshButton
@onready var room_list_container: VBoxContainer = $CenterContainer/VBox/ScrollContainer/RoomListContainer
@onready var chat_display: RichTextLabel = $CenterContainer/VBox/ChatHBox/ChatDisplay
@onready var chat_input: LineEdit = $CenterContainer/VBox/ChatHBox/ChatInput
@onready var chat_send: Button = $CenterContainer/VBox/ChatHBox/ChatSend
@onready var back_button: Button = $CenterContainer/VBox/BottomHBox/BackButton
@onready var start_button: Button = $CenterContainer/VBox/BottomHBox/StartButton
@onready var developer_label: Label = $DeveloperLabel

const SCALE_UP := Vector2(1.05, 1.05)
const SCALE_NORMAL := Vector2(1.0, 1.0)
const SCALE_DURATION_UP := 0.1
const SCALE_DURATION_DOWN := 0.15

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.13, 0.11, 0.22, 0.98)
const COL_BG_PRESSED := Color(0.04, 0.04, 0.08, 0.98)
const COL_BORDER := Color(0.35, 0.30, 0.55, 0.55)
const COL_CYAN := Color(0.4, 0.9, 1.0)
const COL_GOLD := Color(1.0, 0.85, 0.3)
const COL_GREEN := Color(0.4, 0.9, 0.5)
const COL_RED := Color(1.0, 0.4, 0.3)
const COL_PURPLE := Color(0.7, 0.65, 1.0)

func _ready():
	back_button.pressed.connect(_on_back)
	connect_button.pressed.connect(_on_connect)
	create_button.pressed.connect(_on_create)
	refresh_button.pressed.connect(_on_refresh)
	chat_send.pressed.connect(_on_chat_send)
	chat_input.text_submitted.connect(func(_t): _on_chat_send())
	start_button.pressed.connect(_on_start)
	start_button.visible = false
	account_button.pressed.connect(_on_account_button)
	# Hook signals
	MultiplayerManager.connected.connect(_on_connected)
	MultiplayerManager.disconnected.connect(_on_disconnected)
	MultiplayerManager.connection_error.connect(_on_error)
	MultiplayerManager.auth_failed.connect(_on_auth_failed)
	MultiplayerManager.room_joined.connect(_on_room_joined)
	MultiplayerManager.room_left.connect(_on_room_left)
	MultiplayerManager.room_list_updated.connect(_on_room_list)
	MultiplayerManager.chat_received.connect(_on_chat)
	MultiplayerManager.player_joined.connect(_on_player_joined)
	MultiplayerManager.player_left.connect(_on_player_left)
	MultiplayerManager.game_started.connect(_on_game_started)
	MultiplayerManager.level_up.connect(_on_level_up)
	MultiplayerManager.exp_gained.connect(_on_exp_gained)
	# Hook account signals
	AccountManager.logged_in.connect(_on_account_changed)
	AccountManager.logged_out.connect(_on_account_changed)
	AccountManager.profile_updated.connect(_on_account_changed)
	# Default name from previous session or use account display_name
	var saved_name = SettingsManager.get_value("multiplayer_name", "Player%d" % randi_range(100, 999))
	if AccountManager.is_logged_in():
		saved_name = AccountManager.get_display_name()
	name_edit.text = saved_name
	name_edit.editable = not AccountManager.is_logged_in()
	# Style
	_style_all()
	_setup_hover_effects()
	_apply_premium_styling()
	_refresh_account_label()
	# Branding
	if developer_label:
		developer_label.text = "Game developed by Hieu Louis"
	AudioManager.play_music("menu")
	# v4.2: Auto-connect to server on entry so chat/rooms work immediately
	_status("Đang tự động kết nối tới server...", COL_GOLD)
	call_deferred("_auto_connect")

func _auto_connect():
	# Wait one frame for the scene to be fully ready, then connect
	await get_tree().process_frame
	if not MultiplayerManager.is_connected and not MultiplayerManager.is_connecting:
		var pname = name_edit.text.strip_edges()
		if pname.is_empty():
			pname = "Player%d" % randi_range(100, 999)
			name_edit.text = pname
		_status("Đang kết nối tới server...", COL_GOLD)
		connect_button.disabled = true
		connect_button.text = "⏳ Đang kết nối..."
		MultiplayerManager.connect_to_server(pname)

# === Hover / touch scale effects (match menu.gd) ===

func _setup_hover_effects():
	for btn in [connect_button, create_button, refresh_button, chat_send, back_button, start_button, account_button]:
		if btn:
			btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
			btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
			_setup_touch_scale(btn)

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

func _apply_premium_styling():
	# Glow animation on title (same as menu GameTitle)
	if title_label:
		var tween = create_tween().set_loops()
		tween.tween_property(title_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(title_label, "modulate", Color(0.85, 0.85, 0.95, 0.92), 2.0).set_trans(Tween.TRANS_SINE)

# === Styling (match menu.gd premium look) ===

func _style_all():
	_style_button(connect_button, COL_GREEN)
	_style_button(create_button, COL_GREEN)
	_style_button(refresh_button, COL_CYAN)
	_style_button(chat_send, COL_CYAN)
	_style_button(back_button, COL_RED)
	_style_primary_button(start_button, COL_GOLD)
	_style_button(account_button, COL_PURPLE)

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

# === Status & account ===

func _status(text: String, color: Color = Color(0.7, 0.8, 0.9)):
	status_label.text = text
	status_label.modulate = color

func _refresh_account_label():
	if AccountManager.is_logged_in():
		var level = AccountManager.get_level()
		var title = AccountManager.get_title()
		var display = AccountManager.get_display_name()
		account_label.text = "👤 %s  •  %s  •  Lv %d" % [display, title, level]
		account_label.modulate = Color(0.5, 1.0, 0.7)
		account_button.text = "Hồ sơ"
		name_edit.editable = false
		name_edit.text = display
	else:
		account_label.text = "Chưa đăng nhập — chơi guest sẽ không nhận EXP"
		account_label.modulate = Color(0.8, 0.6, 0.4)
		account_button.text = "Đăng nhập"
		name_edit.editable = true

func _on_account_changed(_user = null):
	_refresh_account_label()

func _on_account_button():
	AudioManager.play_ui_click()
	if AccountManager.is_logged_in():
		get_tree().change_scene_to_file("res://scenes/profile.tscn")
	else:
		# v4.2: route back to this scene after login
		LoginRouter.next_scene = "res://scenes/multiplayer_lobby.tscn"
		get_tree().change_scene_to_file("res://scenes/login.tscn")

# === Connection ===

func _on_connect():
	AudioManager.play_ui_click()
	var pname = name_edit.text.strip_edges()
	if pname.is_empty():
		_status("⚠ Nhập tên trước khi kết nối", COL_RED)
		AudioManager.play_cancel()
		return
	SettingsManager.set_value("multiplayer_name", pname)
	_status("Đang kết nối tới server...", COL_GOLD)
	connect_button.disabled = true
	connect_button.text = "⏳ Đang kết nối..."
	MultiplayerManager.connect_to_server(pname)

func _on_connected():
	var auth_str = " (guest)" if not MultiplayerManager.authenticated else " (đã đăng nhập)"
	_status("✓ Đã kết nối server! Player ID: %d%s" % [MultiplayerManager.player_id, auth_str], COL_GREEN)
	connect_button.text = "✓ Đã kết nối"
	connect_button.disabled = false
	AudioManager.play_confirm()
	MultiplayerManager.list_rooms()
	_chat_system("→ Bạn đã vào sảnh chờ với tên [b]%s[/b]%s" % [MultiplayerManager.player_name, auth_str])
	# Welcome hints
	_chat_system("💡 Tạo phòng mới hoặc vào phòng có sẵn. Chat Enter để gửi.")
	_chat_system("💡 Mẹo: đăng nhập để nhận EXP sau mỗi trận đấu.")

func _on_disconnected():
	_status("✗ Mất kết nối. Đang thử lại...", COL_RED)
	connect_button.disabled = false
	connect_button.text = "🔄 Kết nối lại"
	AudioManager.play_cancel()

func _on_error(reason: String):
	_status("✗ Lỗi: %s" % reason, COL_RED)
	connect_button.disabled = false
	connect_button.text = "🔄 Thử lại"
	AudioManager.play_cancel()

func _on_auth_failed(message: String):
	_status("⚠ Auth: %s (vẫn chơi được nhưng không nhận EXP)" % message, Color(0.9, 0.7, 0.3))

# === Rooms ===

func _on_refresh():
	AudioManager.play_ui_click()
	if not MultiplayerManager.is_connected:
		_status("⚠ Chưa kết nối server", COL_RED)
		AudioManager.play_cancel()
		return
	MultiplayerManager.list_rooms()
	_status("Đang làm mới danh sách phòng...", COL_GOLD)

func _on_room_list(rooms: Array):
	for child in room_list_container.get_children():
		child.queue_free()
	if rooms.is_empty():
		var lbl = Label.new()
		lbl.text = "Chưa có phòng nào. Hãy tạo phòng mới!"
		lbl.modulate = Color(0.7, 0.8, 0.9)
		room_list_container.add_child(lbl)
		_status("✓ Chưa có phòng nào. Tạo phòng mới để bắt đầu.", COL_GREEN)
		return
	for room in rooms:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(640, 0)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.10, 0.18, 0.95)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.45, 0.4, 0.65, 0.5)
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		style.content_margin_left = 12
		style.content_margin_right = 12
		panel.add_theme_stylebox_override("panel", style)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = 3
		var name_lbl = Label.new()
		name_lbl.text = "🏠 %s" % String(room.get("name", "Phòng không tên"))
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.modulate = Color(1.0, 0.85, 0.3)
		vbox.add_child(name_lbl)
		var info = Label.new()
		info.text = "ID: %s  •  Players: %d/4  •  %s" % [
			String(room.get("id", "")),
			int(room.get("player_count", 0)),
			String(room.get("status", "lobby"))
		]
		info.modulate = Color(0.7, 0.8, 0.9)
		info.add_theme_font_size_override("font_size", 13)
		vbox.add_child(info)
		hbox.add_child(vbox)
		var join_btn = Button.new()
		join_btn.text = "Vào phòng"
		join_btn.custom_minimum_size = Vector2(100, 44)
		_style_button(join_btn, COL_GREEN)
		var room_id = String(room.get("id", ""))
		join_btn.pressed.connect(func(): MultiplayerManager.join_room(room_id))
		hbox.add_child(join_btn)
		panel.add_child(hbox)
		room_list_container.add_child(panel)
	_status("✓ Có %d phòng." % rooms.size(), COL_GREEN)

func _on_create():
	AudioManager.play_ui_click()
	if not MultiplayerManager.is_connected:
		_status("⚠ Chưa kết nối server", COL_RED)
		AudioManager.play_cancel()
		return
	var rname = room_name_edit.text.strip_edges()
	if rname.is_empty():
		rname = "Phòng của %s" % MultiplayerManager.player_name
	MultiplayerManager.create_room(rname)
	_status("Đang tạo phòng '%s'..." % rname, COL_GOLD)

func _on_room_joined(room_id: String, players: Array):
	_status("✓ Đã vào phòng %s (%d người)" % [room_id, players.size()], COL_GREEN)
	start_button.visible = true
	AudioManager.play_confirm()
	_chat_system("→ Đã vào phòng [b]%s[/b]" % room_id)

func _on_room_left():
	start_button.visible = false
	_status("Đã rời phòng.", Color(0.7, 0.8, 0.9))

func _on_player_joined(pid: int, pname: String):
	_chat_system("→ [b]%s[/b] vào phòng" % pname)

func _on_player_left(pid: int):
	_chat_system("← Player #%d rời phòng" % pid)

# === Chat ===

func _on_chat(sender_id: int, sender_name: String, message: String):
	if sender_id == -1:
		_chat_system(message)
	else:
		var safe_name = sender_name.replace("[", "").replace("]", "")
		var safe_msg = message.replace("[", "").replace("]", "")
		chat_display.append_text("\n[color=#aaffaa]%s:[/color] %s" % [safe_name, safe_msg])

func _chat_system(text: String):
	chat_display.append_text("\n[color=#888888]%s[/color]" % text)

func _on_chat_send():
	AudioManager.play_ui_click()
	var text = chat_input.text.strip_edges()
	if text.is_empty():
		return
	if not MultiplayerManager.is_connected:
		_status("⚠ Chưa kết nối server — đang thử kết nối lại...", COL_RED)
		AudioManager.play_cancel()
		_auto_connect()
		return
	MultiplayerManager.send_chat(text)
	var safe = text.replace("[", "").replace("]", "")
	chat_display.append_text("\n[color=#aaffff]%s (bạn):[/color] %s" % [MultiplayerManager.player_name, safe])
	chat_input.text = ""

# === Game start ===

func _on_start():
	AudioManager.play_ui_click()
	if not MultiplayerManager.is_connected or MultiplayerManager.current_room_id.is_empty():
		_status("⚠ Cần vào phòng trước", COL_RED)
		AudioManager.play_cancel()
		return
	MultiplayerManager.start_game()
	_status("Đang bắt đầu game...", COL_GOLD)

func _on_game_started(_players: Array):
	get_tree().change_scene_to_file("res://scenes/multiplayer_arena.tscn")

func _on_level_up(old_level: int, new_level: int, new_title: String):
	_chat_system("🎉 [b]LÊN LEVEL %d[/b] — Danh hiệu mới: [b]%s[/b]" % [new_level, new_title])
	_refresh_account_label()

func _on_exp_gained(amount: int, _total: int):
	_chat_system("✨ Nhận %d EXP" % amount)
	_refresh_account_label()

func _on_back():
	AudioManager.play_cancel()
	if MultiplayerManager.is_connected:
		MultiplayerManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back()
