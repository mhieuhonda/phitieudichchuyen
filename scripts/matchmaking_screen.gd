extends Control

## MatchmakingScreen - Màn hình ghép trận online (v1.7)
## Hiển thị trạng thái matchmaking, số người trong queue,
## đếm ngược, nút hủy

@onready var status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel
@onready var queue_label: Label = $CenterContainer/PanelContainer/VBoxContainer/QueueLabel
@onready var countdown_label: Label = $CenterContainer/PanelContainer/VBoxContainer/CountdownLabel
@onready var players_list: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/PlayersList
@onready var cancel_button: Button = $CenterContainer/PanelContainer/VBoxContainer/CancelButton
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _is_counting_down: bool = false
var _countdown_seconds: int = 0

func _ready():
	cancel_button.pressed.connect(_on_cancel_pressed)
	cancel_button.mouse_entered.connect(func(): AudioManager.play_ui_hover())

	# Connect network signals
	NetworkManager.matchmaking_update.connect(_on_matchmaking_update)
	NetworkManager.matchmaking_found.connect(_on_match_found)
	NetworkManager.matchmaking_timeout.connect(_on_matchmaking_timeout)
	NetworkManager.match_countdown.connect(_on_match_countdown)
	NetworkManager.match_start.connect(_on_match_start)

	status_label.text = "Đang tìm trận..."
	queue_label.text = "Người chơi: 0 / 10"
	countdown_label.text = ""

	if anim_player:
		anim_player.play("searching")

func _on_cancel_pressed():
	AudioManager.play_cancel()
	NetworkManager.leave_matchmaking()
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _on_matchmaking_update(queue_size: int, min_players: int, max_players: int):
	queue_label.text = "Người chơi: %d / %d (tối đa %d)" % [queue_size, min_players, max_players]
	status_label.text = "Đang tìm trận..."

func _on_match_found(room_id: String, player_count: int, bot_count: int, total_players: int):
	status_label.text = "Tìm thấy trận!"
	queue_label.text = "%d người chơi + %d bot = %d tổng" % [player_count, bot_count, total_players]
	if anim_player:
		anim_player.stop()
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
	if anim_player:
		anim_player.stop()
	AudioManager.play_confirm()

func _on_match_start(data: Dictionary):
	# Chuyển sang scene game online
	SettingsManager.pending_scene = "res://scenes/main_online.tscn"
	get_tree().change_scene_to_file("res://scenes/loading.tscn")
