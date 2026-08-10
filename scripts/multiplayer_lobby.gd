extends Control

## MultiplayerLobby - Sảnh chờ multiplayer (v4.0)
## Scene: scenes/multiplayer_lobby.tscn
## - Nhập tên, kết nối server
## - Tạo phòng / Vào phòng
## - Xem danh sách phòng
## - Chat chung (trước khi vào game)

@onready var name_edit: LineEdit = $CenterContainer/VBox/TopHBox/NameEdit
@onready var connect_button: Button = $CenterContainer/VBox/TopHBox/ConnectButton
@onready var status_label: Label = $CenterContainer/VBox/StatusLabel
@onready var room_name_edit: LineEdit = $CenterContainer/VBox/RoomHBox/RoomNameEdit
@onready var create_button: Button = $CenterContainer/VBox/RoomHBox/CreateButton
@onready var refresh_button: Button = $CenterContainer/VBox/RoomHBox/RefreshButton
@onready var room_list_container: VBoxContainer = $CenterContainer/VBox/ScrollContainer/RoomListContainer
@onready var chat_display: RichTextLabel = $CenterContainer/VBox/ChatHBox/ChatDisplay
@onready var chat_input: LineEdit = $CenterContainer/VBox/ChatHBox/ChatInput
@onready var chat_send: Button = $CenterContainer/VBox/ChatHBox/ChatSend
@onready var back_button: Button = $CenterContainer/VBox/BackButton
@onready var start_button: Button = $CenterContainer/VBox/StartButton

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.15, 0.13, 0.25, 0.98)

func _ready():
	back_button.pressed.connect(_on_back)
	connect_button.pressed.connect(_on_connect)
	create_button.pressed.connect(_on_create)
	refresh_button.pressed.connect(_on_refresh)
	chat_send.pressed.connect(_on_chat_send)
	chat_input.text_submitted.connect(func(_t): _on_chat_send())
	start_button.pressed.connect(_on_start)
	start_button.visible = false
	# Hook signals
	MultiplayerManager.connected.connect(_on_connected)
	MultiplayerManager.disconnected.connect(_on_disconnected)
	MultiplayerManager.connection_error.connect(_on_error)
	MultiplayerManager.room_joined.connect(_on_room_joined)
	MultiplayerManager.room_left.connect(_on_room_left)
	MultiplayerManager.room_list_updated.connect(_on_room_list)
	MultiplayerManager.chat_received.connect(_on_chat)
	MultiplayerManager.player_joined.connect(_on_player_joined)
	MultiplayerManager.player_left.connect(_on_player_left)
	MultiplayerManager.game_started.connect(_on_game_started)
	# Default name from previous session
	var saved_name = SettingsManager.get_value("multiplayer_name", "Player%d" % randi_range(100, 999))
	name_edit.text = saved_name
	_status("Chưa kết nối. Ấn [Kết nối] để vào server.")
	_style_all()
	AudioManager.play_music("menu")

func _style_all():
	for btn in [connect_button, create_button, refresh_button, chat_send, back_button, start_button]:
		_style_button(btn, Color(0.4, 0.9, 1.0))
	_style_button(connect_button, Color(0.4, 0.9, 0.5))
	_style_button(create_button, Color(0.4, 0.9, 0.5))
	_style_button(start_button, Color(1.0, 0.85, 0.3))
	_style_button(back_button, Color(1.0, 0.4, 0.3))

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

func _status(text: String, color: Color = Color(0.7, 0.8, 0.9)):
	status_label.text = text
	status_label.modulate = color

func _on_connect():
	var pname = name_edit.text.strip_edges()
	if pname.is_empty():
		_status("⚠ Nhập tên trước khi kết nối", Color(1.0, 0.5, 0.3))
		return
	SettingsManager.set_value("multiplayer_name", pname)
	_status("Đang kết nối tới server wss://phitieu.louis.vangioitutien.com/ws ...", Color(1.0, 0.85, 0.3))
	connect_button.disabled = true
	MultiplayerManager.connect_to_server(pname)

func _on_connected():
	_status("✓ Đã kết nối! Player ID: %d" % MultiplayerManager.player_id, Color(0.5, 1.0, 0.5))
	connect_button.text = "Đã kết nối"
	# Auto-list rooms
	MultiplayerManager.list_rooms()
	# Chat system message
	_chat_system("→ Bạn đã vào sảnh chờ với tên [b]%s[/b]" % MultiplayerManager.player_name)

func _on_disconnected():
	_status("✗ Mất kết nối. Đang thử lại...", Color(1.0, 0.5, 0.3))
	connect_button.disabled = false
	connect_button.text = "Kết nối lại"

func _on_error(reason: String):
	_status("✗ Lỗi: %s" % reason, Color(1.0, 0.5, 0.3))
	connect_button.disabled = false
	connect_button.text = "Thử lại"

func _on_refresh():
	if not MultiplayerManager.is_connected:
		_status("⚠ Chưa kết nối server", Color(1.0, 0.5, 0.3))
		return
	MultiplayerManager.list_rooms()
	_status("Đang làm mới danh sách phòng...", Color(1.0, 0.85, 0.3))

func _on_room_list(rooms: Array):
	for child in room_list_container.get_children():
		child.queue_free()
	if rooms.is_empty():
		var lbl = Label.new()
		lbl.text = "Chưa có phòng nào. Hãy tạo phòng mới!"
		lbl.modulate = Color(0.7, 0.8, 0.9)
		room_list_container.add_child(lbl)
		_status("✓ Chưa có phòng nào. Tạo phòng mới để bắt đầu.", Color(0.5, 1.0, 0.5))
		return
	for room in rooms:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(700, 0)
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
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		style.content_margin_left = 14
		style.content_margin_right = 14
		panel.add_theme_stylebox_override("panel", style)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = 3
		var name_lbl = Label.new()
		name_lbl.text = "🏠 %s" % String(room.get("name", "Phòng không tên"))
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.modulate = Color(1.0, 0.85, 0.3)
		vbox.add_child(name_lbl)
		var info = Label.new()
		info.text = "ID: %s  •  Players: %d/4  •  Status: %s" % [
			String(room.get("id", "")),
			int(room.get("player_count", 0)),
			String(room.get("status", "lobby"))
		]
		info.modulate = Color(0.7, 0.8, 0.9)
		vbox.add_child(info)
		hbox.add_child(vbox)
		var join_btn = Button.new()
		join_btn.text = "Vào phòng"
		join_btn.custom_minimum_size = Vector2(120, 50)
		_style_button(join_btn, Color(0.4, 0.9, 0.5))
		var room_id = String(room.get("id", ""))
		join_btn.pressed.connect(func(): MultiplayerManager.join_room(room_id))
		hbox.add_child(join_btn)
		panel.add_child(hbox)
		room_list_container.add_child(panel)
	_status("✓ Có %d phòng." % rooms.size(), Color(0.5, 1.0, 0.5))

func _on_create():
	if not MultiplayerManager.is_connected:
		_status("⚠ Chưa kết nối server", Color(1.0, 0.5, 0.3))
		return
	var rname = room_name_edit.text.strip_edges()
	if rname.is_empty():
		rname = "Phòng của %s" % MultiplayerManager.player_name
	MultiplayerManager.create_room(rname)
	_status("Đang tạo phòng '%s'..." % rname, Color(1.0, 0.85, 0.3))

func _on_room_joined(room_id: String, players: Array):
	_status("✓ Đã vào phòng %s (%d người)" % [room_id, players.size()], Color(0.5, 1.0, 0.5))
	start_button.visible = true  # host có thể start (server sẽ check)
	_chat_system("→ Đã vào phòng [b]%s[/b]" % room_id)

func _on_room_left():
	start_button.visible = false
	_status("Đã rời phòng.", Color(0.7, 0.8, 0.9))

func _on_player_joined(pid: int, pname: String):
	_chat_system("→ [b]%s[/b] vào phòng" % pname)

func _on_player_left(pid: int):
	_chat_system("← Player #%d rời phòng" % pid)

func _on_chat(sender_id: int, sender_name: String, message: String):
	if sender_id == -1:
		# System message
		_chat_system(message)
	else:
		chat_display.append_text("\n[color=#aaffaa]%s:[/color] %s" % [sender_name.replace("[", "[").replace("]", "]"), message.replace("[", "[").replace("]", "]")])

func _chat_system(text: String):
	chat_display.append_text("\n[color=#888888]%s[/color]" % text)

func _on_chat_send():
	var text = chat_input.text.strip_edges()
	if text.is_empty():
		return
	if not MultiplayerManager.is_connected:
		_status("⚠ Chưa kết nối server", Color(1.0, 0.5, 0.3))
		return
	MultiplayerManager.send_chat(text)
	# Show local
	chat_display.append_text("\n[color=#aaffff]%s (bạn):[/color] %s" % [MultiplayerManager.player_name, text.replace("[", "[").replace("]", "]")])
	chat_input.text = ""

func _on_start():
	if not MultiplayerManager.is_connected or MultiplayerManager.current_room_id.is_empty():
		_status("⚠ Cần vào phòng trước", Color(1.0, 0.5, 0.3))
		return
	MultiplayerManager.start_game()
	_status("Đang bắt đầu game...", Color(1.0, 0.85, 0.3))

func _on_game_started(_players: Array):
	# Server đã start game — chuyển sang arena scene
	get_tree().change_scene_to_file("res://scenes/multiplayer_arena.tscn")

func _on_back():
	AudioManager.play_cancel()
	if MultiplayerManager.is_connected:
		MultiplayerManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back()
