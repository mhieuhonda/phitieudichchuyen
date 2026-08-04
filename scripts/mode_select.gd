extends Control

## ModeSelectScreen - Chọn chế độ chơi: Online hoặc Offline (v2.3)
## v2.0: Cleanup ONE_SHOT signal handlers on scene exit to avoid
## "Invalid access to property or method on freed instance" errors when
## the connection state changes after the user has already navigated away.
## v2.2: 
## - Hiện thông báo lỗi chi tiết hơn
## - Thêm nút "Thử lại" khi server offline
## v2.3:
## - Xóa nút "Đổi server URL" - relay server đã hardcoded trong source
## - Mọi client dùng chung 1 server duy nhất

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var online_button: Button = $CenterContainer/PanelContainer/VBoxContainer/OnlineButton
@onready var offline_button: Button = $CenterContainer/PanelContainer/VBoxContainer/OfflineButton
@onready var back_button: Button = $CenterContainer/PanelContainer/VBoxContainer/BackButton
@onready var server_status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/ServerStatusLabel
@onready var retry_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RetryButton

func _ready():
        online_button.pressed.connect(_on_online_pressed)
        offline_button.pressed.connect(_on_offline_pressed)
        back_button.pressed.connect(_on_back_pressed)
        if retry_button:
                retry_button.pressed.connect(_on_retry_pressed)
                retry_button.visible = false

        for btn in [online_button, offline_button, back_button, retry_button]:
                if btn:
                        btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

        title_label.text = "CHƠI NGAY"
        online_button.text = "🌐 CHƠI ONLINE"
        offline_button.text = "🎮 CHƠI OFFLINE"
        back_button.text = "← QUAY LẠI"
        if retry_button:
                retry_button.text = "🔄 THỬ LẠI"
        server_status_label.text = "Đang kiểm tra server..."

        # Online luôn enabled - user có thể thử lại ngay cả khi check fail
        online_button.disabled = false

        # Check server status
        _check_server_status()

        AudioManager.play_music("menu")

func _exit_tree():
        # v1.9 FIX: Make sure no stale ONE_SHOT handlers remain attached to NetworkManager
        # after this scene is freed. Otherwise, when the server eventually responds, the
        # callback would try to access freed UI nodes and crash.
        _cleanup_status_handlers()

func _cleanup_status_handlers():
        if NetworkManager.connected_to_server.is_connected(_on_server_connected):
                NetworkManager.connected_to_server.disconnect(_on_server_connected)
        if NetworkManager.connection_error.is_connected(_on_server_error):
                NetworkManager.connection_error.disconnect(_on_server_error)

func _check_server_status():
        # v2.3: Server URL đã hardcoded trong NetworkManager.DEFAULT_SERVER_URL
        # Cleanup any previous handlers first (idempotent) - quan trọng để không leak
        _cleanup_status_handlers()
        # v2.2: Nếu đã connected (vd: từ Settings test), emit ngay không cần connect lại
        if NetworkManager.is_server_connected():
                _on_server_connected()
                return
        server_status_label.text = "Đang kết nối đến server..."
        server_status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.4))
        NetworkManager.connected_to_server.connect(_on_server_connected, CONNECT_ONE_SHOT)
        NetworkManager.connection_error.connect(_on_server_error, CONNECT_ONE_SHOT)
        NetworkManager.connect_to_server()
        if retry_button:
                retry_button.visible = false

func _on_server_connected():
        # Disconnect the other ONE_SHOT connection to avoid stale callback firing later
        if NetworkManager.connection_error.is_connected(_on_server_error):
                NetworkManager.connection_error.disconnect(_on_server_error)
        server_status_label.text = "✅ Server online - Sẵn sàng chơi!"
        server_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
        online_button.disabled = false
        if retry_button:
                retry_button.visible = false
        # Login immediately if not logged in
        if not NetworkManager.is_logged_in():
                var player_name = "Player"
                if CharacterData:
                        player_name = CharacterData.get_selected().get("name", "Player")
                NetworkManager.login(player_name, CharacterData.selected_character_id if CharacterData else 0)

func _on_server_error(error_msg: String):
        # Disconnect the other ONE_SHOT connection to avoid stale callback firing later
        if NetworkManager.connected_to_server.is_connected(_on_server_connected):
                NetworkManager.connected_to_server.disconnect(_on_server_connected)
        # v2.2: Hiện thông báo lỗi chi tiết hơn + gợi ý
        server_status_label.text = "❌ Server offline: %s\nVui lòng kiểm tra kết nối mạng và thử lại." % error_msg
        server_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
        # v2.2: Vẫn cho phép bấm Online (user có thể thử lại)
        online_button.disabled = false
        online_button.tooltip_text = "Server không khả dụng - bấm để thử lại"
        if retry_button:
                retry_button.visible = true

func _on_retry_pressed():
        AudioManager.play_ui_click()
        # v2.2: Disconnect hẳn trước khi thử lại (xóa state cũ)
        if NetworkManager.is_server_connected():
                NetworkManager.disconnect_from_server()
        _check_server_status()

func _on_online_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        # v2.2: Nếu server đang offline, thử kết nối lại trước khi vào matchmaking
        if not NetworkManager.is_server_connected():
                _check_server_status()
                # Vẫn vào matchmaking - nó sẽ tự retry nếu cần
        # Go to matchmaking screen
        get_tree().change_scene_to_file("res://scenes/matchmaking.tscn")

func _on_offline_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        # Disconnect from server if connected
        if NetworkManager.is_server_connected():
                NetworkManager.disconnect_from_server()
        # Original offline game flow
        SettingsManager.pending_scene = "res://scenes/main.tscn"
        get_tree().change_scene_to_file("res://scenes/loading.tscn")

func _on_back_pressed():
        AudioManager.play_cancel()
        if NetworkManager.is_server_connected():
                NetworkManager.disconnect_from_server()
        get_tree().change_scene_to_file("res://scenes/menu.tscn")
