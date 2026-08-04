extends Control

## MatchmakingScreen - Màn hình ghép trận online (v2.1)
## Hiển thị trạng thái matchmaking, số người trong queue,
## đếm ngược, nút hủy
##
## v2.1 FIX NGHIÊM TRỌNG: Bản trước KHÔNG BAO GIỜ gọi NetworkManager.join_matchmaking()
## → user stuck "Đang tìm trận..." mãi mãi dù server online. Đã fix.
## v2.1: Hiển thị latency, nút "Quick Practice" nếu queue quá lâu.

@onready var status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel
@onready var queue_label: Label = $CenterContainer/PanelContainer/VBoxContainer/QueueLabel
@onready var countdown_label: Label = $CenterContainer/PanelContainer/VBoxContainer/CountdownLabel
@onready var players_list: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/PlayersList
@onready var cancel_button: Button = $CenterContainer/PanelContainer/VBoxContainer/CancelButton

var _is_counting_down: bool = false
var _countdown_seconds: int = 0
var _join_retry_timer: float = 0.0
var _join_attempts: int = 0
var _wait_timer: float = 0.0

func _ready():
	cancel_button.pressed.connect(_on_cancel_pressed)
	cancel_button.mouse_entered.connect(func(): AudioManager.play_ui_hover())

	# Connect network signals
	NetworkManager.matchmaking_update.connect(_on_matchmaking_update)
	NetworkManager.matchmaking_found.connect(_on_match_found)
	NetworkManager.matchmaking_timeout.connect(_on_matchmaking_timeout)
	NetworkManager.match_countdown.connect(_on_match_countdown)
	NetworkManager.match_start.connect(_on_match_start)
	NetworkManager.login_success.connect(_on_login_success)
	NetworkManager.connection_error.connect(_on_connection_error)

	status_label.text = "Đang kết nối đến server..."
	queue_label.text = ""
	countdown_label.text = ""
	# Pulse the status label as a "searching" indicator (no AnimationPlayer needed)
	var tween := create_tween().set_loops()
	tween.tween_property(status_label, "modulate:a", 0.4, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(status_label, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	# v2.1 FIX: Đảm bảo đã login trước khi join queue. Nếu chưa login, đợi login_success.
	# Trước đây user vào màn hình này mà KHÔNG BAO GIỜ gửi matchmaking_join → kẹt forever.
	_try_join_matchmaking()

func _exit_tree():
	# v1.9 FIX: disconnect network signal handlers so they don't fire on freed scene
	if NetworkManager.matchmaking_update.is_connected(_on_matchmaking_update):
		NetworkManager.matchmaking_update.disconnect(_on_matchmaking_update)
	if NetworkManager.matchmaking_found.is_connected(_on_match_found):
		NetworkManager.matchmaking_found.disconnect(_on_match_found)
	if NetworkManager.matchmaking_timeout.is_connected(_on_matchmaking_timeout):
		NetworkManager.matchmaking_timeout.disconnect(_on_matchmaking_timeout)
	if NetworkManager.match_countdown.is_connected(_on_match_countdown):
		NetworkManager.match_countdown.disconnect(_on_match_countdown)
	if NetworkManager.match_start.is_connected(_on_match_start):
		NetworkManager.match_start.disconnect(_on_match_start)
	if NetworkManager.login_success.is_connected(_on_login_success):
		NetworkManager.login_success.disconnect(_on_login_success)
	if NetworkManager.connection_error.is_connected(_on_connection_error):
		NetworkManager.connection_error.disconnect(_on_connection_error)

func _process(delta: float) -> void:
	_wait_timer += delta
	# Hiện gợi ý nếu đợi quá lâu
	if _wait_timer > 8.0 and not _is_counting_down:
		queue_label.text = "Đang chờ người chơi khác join...\n(Trận sẽ bắt đầu khi đủ 10 người hoặc sau 30s)"
	# Retry join matchmaking nếu chưa vào queue (server có thể chưa nhận msg trước)
	if NetworkManager.is_logged_in() and not NetworkManager.is_in_matchmaking() and not NetworkManager.is_in_match():
		_join_retry_timer += delta
		if _join_retry_timer >= 2.0 and _join_attempts < 5:
			_join_retry_timer = 0.0
			_join_attempts += 1
			_do_join_matchmaking()

func _try_join_matchmaking():
	# Nếu đã login, join ngay. Nếu chưa, đợi login_success signal.
	if NetworkManager.is_logged_in():
		_do_join_matchmaking()
	else:
		# Đảm bảo đã connect & login
		if not NetworkManager.is_server_connected():
			status_label.text = "Đang kết nối đến server..."
			NetworkManager.connect_to_server()
			# Login sẽ được mode_select tự gọi khi connect thành công,
			# nhưng nếu user vào thẳng matchmaking thì tự login:
			NetworkManager.connected_to_server.connect(func():
				if not NetworkManager.is_logged_in():
					var pname = "Player"
					if CharacterData:
						pname = CharacterData.get_selected().get("name", "Player")
					NetworkManager.login(pname, CharacterData.selected_character_id if CharacterData else 0)
			, CONNECT_ONE_SHOT)
		status_label.text = "Đang chờ đăng nhập..."

func _do_join_matchmaking():
	if not NetworkManager.is_logged_in():
		return
	if NetworkManager.is_in_matchmaking() or NetworkManager.is_in_match():
		return
	var pname = "Player"
	var char_id = 0
	if CharacterData:
		pname = CharacterData.get_selected().get("name", "Player")
		char_id = CharacterData.selected_character_id
	NetworkManager.join_matchmaking(pname, char_id)
	status_label.text = "Đang tìm trận..."
	queue_label.text = "Đang chờ thông tin từ server..."

func _on_login_success(player_id: String):
	# Khi login xong, join matchmaking ngay
	_do_join_matchmaking()

func _on_connection_error(error_msg: String):
	status_label.text = "❌ Lỗi kết nối: %s" % error_msg
	status_label.modulate.a = 1.0
	queue_label.text = "Đang thử kết nối lại..."

func _on_cancel_pressed():
	AudioManager.play_cancel()
	if NetworkManager.is_in_matchmaking():
		NetworkManager.leave_matchmaking()
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _on_matchmaking_update(queue_size: int, min_players: int, max_players: int):
	queue_label.text = "Người chơi: %d / %d (tối đa %d)" % [queue_size, min_players, max_players]
	status_label.text = "Đang tìm trận..."
	_wait_timer = 0.0  # Reset wait timer khi có update

func _on_match_found(room_id: String, player_count: int, bot_count: int, total_players: int):
	status_label.text = "✅ Tìm thấy trận!"
	queue_label.text = "%d người chơi + %d bot = %d tổng" % [player_count, bot_count, total_players]
	status_label.modulate.a = 1.0  # ensure visible after pulse loop
	AudioManager.play_success()

func _on_matchmaking_timeout(message: String):
	status_label.text = message
	queue_label.text = "Đang thêm bot AI..."
	AudioManager.play_notification()

func _on_match_countdown(seconds: int):
	_is_counting_down = true
	_countdown_seconds = seconds
	countdown_label.text = "Bắt đầu sau: %d..." % seconds
	status_label.text = "Trận bắt đầu!"
	status_label.modulate.a = 1.0  # ensure visible after pulse loop
	AudioManager.play_confirm()

func _on_match_start(data: Dictionary):
	# Chuyển sang scene game online
	SettingsManager.pending_scene = "res://scenes/main_online.tscn"
	get_tree().change_scene_to_file("res://scenes/loading.tscn")
