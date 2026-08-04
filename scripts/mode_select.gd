extends Control

## ModeSelectScreen - Chọn chế độ chơi: Online hoặc Offline (v2.0)
## v2.0: Cleanup ONE_SHOT signal handlers on scene exit to avoid
## "Invalid access to property or method on freed instance" errors when
## the connection state changes after the user has already navigated away.

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var online_button: Button = $CenterContainer/PanelContainer/VBoxContainer/OnlineButton
@onready var offline_button: Button = $CenterContainer/PanelContainer/VBoxContainer/OfflineButton
@onready var back_button: Button = $CenterContainer/PanelContainer/VBoxContainer/BackButton
@onready var server_status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/ServerStatusLabel

func _ready():
        online_button.pressed.connect(_on_online_pressed)
        offline_button.pressed.connect(_on_offline_pressed)
        back_button.pressed.connect(_on_back_pressed)

        for btn in [online_button, offline_button, back_button]:
                btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

        title_label.text = "CHƠI NGAY"
        online_button.text = "🌐 CHƠI ONLINE"
        offline_button.text = "🎮 CHƠI OFFLINE"
        back_button.text = "← QUAY LẠI"
        server_status_label.text = "Đang kiểm tra server..."

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
        # Try to connect briefly to check if server is reachable
        server_status_label.text = "Đang kết nối đến server..."
        # Cleanup any previous handlers first (idempotent)
        _cleanup_status_handlers()
        NetworkManager.connected_to_server.connect(_on_server_connected, CONNECT_ONE_SHOT)
        NetworkManager.connection_error.connect(_on_server_error, CONNECT_ONE_SHOT)
        NetworkManager.connect_to_server()

func _on_server_connected():
        # Disconnect the other ONE_SHOT connection to avoid stale callback firing later
        if NetworkManager.connection_error.is_connected(_on_server_error):
                NetworkManager.connection_error.disconnect(_on_server_error)
        server_status_label.text = "✅ Server online - Sẵn sàng chơi!"
        server_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
        online_button.disabled = false
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
        server_status_label.text = "❌ Server offline - Chỉ chơi offline"
        server_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
        online_button.disabled = true
        online_button.tooltip_text = "Server không khả dụng"

func _on_online_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
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
