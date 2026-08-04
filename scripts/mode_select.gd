extends Control

## ModeSelectScreen - Chọn chế độ chơi: Online, Offline, hoặc Vượt Ải (v2.4)
## v2.0: Cleanup ONE_SHOT signal handlers on scene exit
## v2.2: Hiện thông báo lỗi chi tiết hơn + nút "Thử lại" khi server offline
## v2.3: Xóa nút "Đổi server URL" - relay server đã hardcoded trong source
## v2.4: Thêm nút "Vượt Ải" + đa ngôn ngữ (VI/EN)

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var online_button: Button = $CenterContainer/PanelContainer/VBoxContainer/OnlineButton
@onready var offline_button: Button = $CenterContainer/PanelContainer/VBoxContainer/OfflineButton
@onready var endless_button: Button = $CenterContainer/PanelContainer/VBoxContainer/EndlessButton
@onready var back_button: Button = $CenterContainer/PanelContainer/VBoxContainer/BackButton
@onready var server_status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/ServerStatusLabel
@onready var retry_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RetryButton

func _ready():
	online_button.pressed.connect(_on_online_pressed)
	offline_button.pressed.connect(_on_offline_pressed)
	if endless_button:
		endless_button.pressed.connect(_on_endless_pressed)
	back_button.pressed.connect(_on_back_pressed)
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
		retry_button.visible = false

	for btn in [online_button, offline_button, endless_button, back_button, retry_button]:
		if btn:
			btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

	# v2.4: Listen for language changes
	if I18N:
		I18N.language_changed.connect(func(_l): _refresh_ui())

	_refresh_ui()
	# Online luôn enabled - user có thể thử lại ngay cả khi check fail
	online_button.disabled = false
	# Check server status
	_check_server_status()
	AudioManager.play_music("menu")

func _refresh_ui():
	if title_label:
		title_label.text = I18N.t("mode.title")
	if online_button:
		online_button.text = I18N.t("mode.online")
	if offline_button:
		offline_button.text = I18N.t("mode.offline")
	if endless_button:
		endless_button.text = I18N.t("mode.endless")
	if back_button:
		back_button.text = I18N.t("mode.back")
	if retry_button:
		retry_button.text = I18N.t("mode.retry")

func _exit_tree():
	_cleanup_status_handlers()

func _cleanup_status_handlers():
	if NetworkManager.connected_to_server.is_connected(_on_server_connected):
		NetworkManager.connected_to_server.disconnect(_on_server_connected)
	if NetworkManager.connection_error.is_connected(_on_server_error):
		NetworkManager.connection_error.disconnect(_on_server_error)

func _check_server_status():
	_cleanup_status_handlers()
	if NetworkManager.is_server_connected():
		_on_server_connected()
		return
	if server_status_label:
		server_status_label.text = I18N.t("mode.connecting")
		server_status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.4))
	NetworkManager.connected_to_server.connect(_on_server_connected, CONNECT_ONE_SHOT)
	NetworkManager.connection_error.connect(_on_server_error, CONNECT_ONE_SHOT)
	NetworkManager.connect_to_server()
	if retry_button:
		retry_button.visible = false

func _on_server_connected():
	if NetworkManager.connection_error.is_connected(_on_server_error):
		NetworkManager.connection_error.disconnect(_on_server_error)
	if server_status_label:
		server_status_label.text = I18N.t("mode.server_online")
		server_status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	online_button.disabled = false
	if retry_button:
		retry_button.visible = false
	if not NetworkManager.is_logged_in():
		var player_name = "Player"
		if CharacterData:
			player_name = CharacterData.get_selected().get("name", "Player")
		NetworkManager.login(player_name, CharacterData.selected_character_id if CharacterData else 0)

func _on_server_error(error_msg: String):
	if NetworkManager.connected_to_server.is_connected(_on_server_connected):
		NetworkManager.connected_to_server.disconnect(_on_server_connected)
	if server_status_label:
		server_status_label.text = I18N.t("mode.server_offline", [error_msg])
		server_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	online_button.disabled = false
	online_button.tooltip_text = I18N.t("mode.server_offline", [error_msg])
	if retry_button:
		retry_button.visible = true

func _on_retry_pressed():
	AudioManager.play_ui_click()
	if NetworkManager.is_server_connected():
		NetworkManager.disconnect_from_server()
	_check_server_status()

func _on_online_pressed():
	AudioManager.play_ui_click()
	AudioManager.play_confirm()
	if not NetworkManager.is_server_connected():
		_check_server_status()
	get_tree().change_scene_to_file("res://scenes/matchmaking.tscn")

func _on_offline_pressed():
	AudioManager.play_ui_click()
	AudioManager.play_confirm()
	if NetworkManager.is_server_connected():
		NetworkManager.disconnect_from_server()
	SettingsManager.pending_scene = "res://scenes/main.tscn"
	get_tree().change_scene_to_file("res://scenes/loading.tscn")

## v2.4: Vào chế độ Vượt Ải - 500 level, đường thẳng, 15 kỹ năng
func _on_endless_pressed():
	AudioManager.play_ui_click()
	AudioManager.play_confirm()
	if NetworkManager.is_server_connected():
		NetworkManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/endless_mode.tscn")

func _on_back_pressed():
	AudioManager.play_cancel()
	if NetworkManager.is_server_connected():
		NetworkManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
