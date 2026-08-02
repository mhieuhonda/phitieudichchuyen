extends CanvasLayer

## HUD - Giao diện người chơi
## Hiển thị điểm, máu, số phi tiêu, vòng bo, mini-map

@onready var score_label: Label = $ScoreLabel
@onready var hp_bar: ProgressBar = $HpBar
@onready var dart_count_label: Label = $DartCountLabel
@onready var zone_warning: Panel = $ZoneWarning
@onready var zone_timer_label: Label = $ZoneTimerLabel
@onready var kill_feed: VBoxContainer = $KillFeed
@onready var alive_label: Label = $AliveLabel
@onready var controls_label: RichTextLabel = $ControlsLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var restart_label: Label = $GameOverPanel/RestartLabel

var player: CharacterBody2D = null
var zone_shrink_timer: float = 0.0

func _ready():
	GameManager.player_score_changed.connect(_on_score_changed)
	GameManager.player_size_changed.connect(_on_size_changed)
	GameManager.zone_shrank.connect(_on_zone_shrank)
	
	zone_shrink_timer = GameManager.zone_shrink_interval
	
	# Hiển thị điều khiển
	controls_label.text = "[b]ĐIỀU KHIẾN[/b]\n"
	controls_label.text += "WASD: Di chuyển chậm\n"
	controls_label.text += "Chuột phải: Nhắm & Ném phi tiêu\n"
	controls_label.text += "Space: Dịch chuyển tới phi tiêu\n"
	controls_label.text += "R: Chơi lại (khi chết)"
	
	game_over_panel.visible = false
	zone_warning.visible = false

func set_player(p: CharacterBody2D):
	player = p
	player.player_died.connect(_on_player_died)

func _process(delta):
	if not player:
		return
	
	# Cập nhật thanh máu
	hp_bar.value = GameManager.player_hp
	hp_bar.max_value = GameManager.player_max_hp
	
	# Cập nhật số phi tiêu
	if player.stuck_darts.size() > 0:
		dart_count_label.text = "Phi tiêu: %d/%d" % [player.stuck_darts.size(), GameManager.max_darts_per_player]
	else:
		dart_count_label.text = "Phi tiêu: 0/%d (Nhắm để ném!)" % GameManager.max_darts_per_player
	
	# Cập nhật đếm ngược vòng bo
	zone_shrink_timer -= delta
	if zone_shrink_timer <= 0:
		GameManager.shrink_zone()
		zone_shrink_timer = GameManager.zone_shrink_interval
	zone_timer_label.text = "Vòng bo: %.0fs" % zone_shrink_timer
	
	# Cảnh báo ngoài vòng bo
	if not GameManager.is_in_zone(player.global_position):
		zone_warning.visible = true
	else:
		zone_warning.visible = false
	
	# Cập nhật số người còn sống
	var alive_count = get_tree().get_nodes_in_group("ai_players").filter(func(a): return a.is_alive).size()
	alive_count += 1 if player.is_alive else 0
	alive_label.text = "Còn sống: %d" % alive_count

func _on_score_changed(new_score: int):
	score_label.text = "Điểm: %d" % new_score

func _on_size_changed(new_size: float):
	# Cập nhật hiển thị kích thước
	pass

func _on_zone_shrank(new_radius: float):
	zone_timer_label.text = "Vòng bo thu nhỏ!"
	_add_kill_feed("⚠ Vòng bo thu nhỏ!", Color(1.0, 0.5, 0.0))

func _on_player_died(p: CharacterBody2D):
	game_over_panel.visible = true
	game_over_label.text = "BẠN ĐÃ BỊ TIÊU DIỆT!"
	restart_label.text = "Nhấn R để chơi lại"
	_add_kill_feed("Bạn đã bị tiêu diệt!", Color(1.0, 0.2, 0.2))

func _input(event: InputEvent):
	if event.is_action_pressed("restart") and not player.is_alive:
		_restart_game()

func _add_kill_feed(text: String, color: Color = Color.WHITE):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	kill_feed.add_child(label)
	# Tự xóa sau 3 giây
	get_tree().create_timer(3.0).timeout.connect(label.queue_free)

func _restart_game():
	# Reload scene
	get_tree().reload_current_scene()
