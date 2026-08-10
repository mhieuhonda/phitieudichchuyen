extends Node2D

## MultiplayerArena - Arena deathmatch online (v4.1)
## Scene: scenes/multiplayer_arena.tscn
## Top-down 2D arena, 2-4 players, throw darts at each other.
## Server-authoritative: positions, hits, scores.
## v4.1: Submit match result + handle level_up/exp_gained events.

@onready var players_container: Node2D = $PlayersContainer
@onready var darts_container: Node2D = $DartsContainer
@onready var arena_bg: ColorRect = $ArenaBg
@onready var hud: CanvasLayer = $HUD
@onready var score_label: Label = $HUD/ScoreLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var players_label: Label = $HUD/PlayersLabel
@onready var kill_feed: RichTextLabel = $HUD/KillFeed
@onready var chat_display: RichTextLabel = $HUD/ChatDisplay
@onready var chat_input: LineEdit = $HUD/ChatInput
@onready var leave_button: Button = $HUD/LeaveButton
@onready var message_label: Label = $HUD/MessageLabel
@onready var exp_label: Label = $HUD/ExpLabel

const ARENA_WIDTH := 1280.0
const ARENA_HEIGHT := 720.0
const PLAYER_SPEED := 320.0
const PLAYER_RADIUS := 22.0
const DART_SPEED := 700.0
const DART_RADIUS := 8.0
const DART_LIFETIME := 2.0
const DART_DAMAGE := 25
const RESPAWN_TIME := 3.0
const GAME_DURATION := 180.0  # 3 minutes

# Local player state
var local_pos: Vector2 = Vector2(200, 360)
var local_hp: int = 100
var local_score: int = 0
var local_kills: int = 0
var local_alive: bool = true
var local_respawn_timer: float = 0.0
var local_dart_id_counter: int = 0

# Remote player visual nodes (player_id -> Node2D)
var remote_players: Dictionary = {}

# Local darts (dart_id -> {node, owner_id, pos, vel, lifetime})
var local_darts: Dictionary = {}

# Game state
var game_time_left: float = GAME_DURATION
var game_active: bool = false
var game_ended: bool = false  # v4.1: prevent double-submit

# Colors for each player slot
const PLAYER_COLORS = [
	Color(0.4, 0.9, 0.5),  # green
	Color(0.4, 0.7, 1.0),  # blue
	Color(1.0, 0.6, 0.3),  # orange
	Color(0.9, 0.4, 0.7),  # pink
]

func _ready():
	# Hook MultiplayerManager signals
	MultiplayerManager.player_state_updated.connect(_on_player_state)
	MultiplayerManager.player_joined.connect(_on_player_joined)
	MultiplayerManager.player_left.connect(_on_player_left)
	MultiplayerManager.player_died.connect(_on_player_died)
	MultiplayerManager.player_respawned.connect(_on_player_respawned)
	MultiplayerManager.dart_spawned.connect(_on_dart_spawned)
	MultiplayerManager.dart_removed.connect(_on_dart_removed)
	MultiplayerManager.player_hit.connect(_on_player_hit)
	MultiplayerManager.chat_received.connect(_on_chat)
	MultiplayerManager.game_ended.connect(_on_game_end)
	MultiplayerManager.disconnected.connect(_on_disconnect)
	MultiplayerManager.level_up.connect(_on_level_up)
	MultiplayerManager.exp_gained.connect(_on_exp_gained)

	# Init local player at random spawn
	local_pos = Vector2(randf_range(100, ARENA_WIDTH - 100), randf_range(100, ARENA_HEIGHT - 100))

	leave_button.pressed.connect(_on_leave)
	chat_input.text_submitted.connect(func(_t): _on_chat_send())

	# Start game
	game_active = true
	message_label.text = ""
	message_label.modulate = Color(1, 1, 1, 0)
	exp_label.text = ""
	exp_label.modulate = Color(1, 1, 1, 0)

	AudioManager.play_music("boss")

	# Build existing remote players from MultiplayerManager state
	for pid in MultiplayerManager.get_players():
		if pid != MultiplayerManager.get_local_player_id():
			_ensure_remote_player(pid)

	_welcome_chat()

func _welcome_chat():
	_chat_system("— Arena bắt đầu! 3 phút, ghi điểm cao nhất thắng —")
	_chat_system("WASD di chuyển, Space ném phi tiêu, Rời phòng để thoát")
	if AccountManager.is_logged_in():
		_chat_system("✓ Đã đăng nhập — sẽ nhận EXP sau match")
	else:
		_chat_system("⚠ Chưa đăng nhập — sẽ không nhận EXP. Quay lại để đăng nhập.")

func _process(delta):
	if not game_active:
		return

	# Game timer
	game_time_left -= delta
	if game_time_left <= 0:
		game_time_left = 0
		_end_game()
	timer_label.text = "⏱ %d:%02d" % [int(game_time_left) / 60, int(game_time_left) % 60]

	# Local player movement
	if local_alive:
		var input_vec = Vector2.ZERO
		if Input.is_action_pressed("move_up"):
			input_vec.y -= 1
		if Input.is_action_pressed("move_down"):
			input_vec.y += 1
		if Input.is_action_pressed("move_left"):
			input_vec.x -= 1
		if Input.is_action_pressed("move_right"):
			input_vec.x += 1
		if input_vec.length() > 0:
			input_vec = input_vec.normalized()
			local_pos += input_vec * PLAYER_SPEED * delta
			local_pos.x = clamp(local_pos.x, PLAYER_RADIUS, ARENA_WIDTH - PLAYER_RADIUS)
			local_pos.y = clamp(local_pos.y, PLAYER_RADIUS, ARENA_HEIGHT - PLAYER_RADIUS)

		# Throw dart on Space
		if Input.is_action_just_pressed("teleport"):
			_throw_dart()

	# Update local darts
	var to_remove = []
	for dart_id in local_darts.keys():
		var d = local_darts[dart_id]
		d.pos += d.vel * delta
		d.lifetime -= delta
		# Out of bounds or expired
		if d.lifetime <= 0 or d.pos.x < 0 or d.pos.x > ARENA_WIDTH or d.pos.y < 0 or d.pos.y > ARENA_HEIGHT:
			to_remove.append(dart_id)
			continue
		# Check collision with remote players
		for pid in remote_players.keys():
			if pid == d.owner_id:
				continue
			var rp = remote_players[pid]
			var info = MultiplayerManager.get_player_info(pid)
			if not info.get("alive", true):
				continue
			var rpos = info.get("pos", Vector2.ZERO)
			if d.pos.distance_to(rpos) < PLAYER_RADIUS + DART_RADIUS:
				# Hit!
				MultiplayerManager.send_hit(pid, DART_DAMAGE)
				to_remove.append(dart_id)
				MultiplayerManager.send_dart_remove(dart_id)
				break
	for dart_id in to_remove:
		_remove_dart(dart_id)

	# Update dart visuals
	for dart_id in local_darts.keys():
		var d = local_darts[dart_id]
		if d.has("node") and is_instance_valid(d.node):
			d.node.position = d.pos

	# Respawn timer
	if not local_alive:
		local_respawn_timer -= delta
		if local_respawn_timer <= 0:
			local_alive = true
			local_hp = 100
			local_pos = Vector2(randf_range(100, ARENA_WIDTH - 100), randf_range(100, ARENA_HEIGHT - 100))
			MultiplayerManager.send_respawn()

	# Send local state to server (10 Hz)
	if Engine.get_frames_drawn() % 6 == 0:
		MultiplayerManager.send_player_state(local_pos, local_hp, local_score, local_alive)

	# Update HUD
	score_label.text = "Score: %d  •  HP: %d  •  Kills: %d" % [local_score, local_hp, local_kills]
	players_label.text = "Phòng: %d người" % (remote_players.size() + 1)

	# Update local player visual
	_update_local_player_visual()

	# Update remote player visuals
	for pid in remote_players.keys():
		_update_remote_player_visual(pid)

# === Local player visual ===
var _local_player_visual: Node2D = null

func _update_local_player_visual():
	if not _local_player_visual:
		_local_player_visual = _create_player_visual(MultiplayerManager.get_local_player_id(), MultiplayerManager.player_name)
		_local_player_visual.position = local_pos
		players_container.add_child(_local_player_visual)
	else:
		_local_player_visual.position = local_pos
		var sprite = _local_player_visual.get_node_or_null("Sprite")
		if sprite:
			sprite.modulate = Color(1, 1, 1, 1) if local_alive else Color(0.4, 0.4, 0.4, 0.5)
		var hp_bar = _local_player_visual.get_node_or_null("HpBar")
		if hp_bar:
			hp_bar.value = local_hp
		var name_lbl = _local_player_visual.get_node_or_null("NameLabel")
		if name_lbl:
			name_lbl.text = "%s (bạn)" % MultiplayerManager.player_name

# === Remote player visual ===
func _ensure_remote_player(pid: int):
	if remote_players.has(pid):
		return
	var info = MultiplayerManager.get_player_info(pid)
	var pname = info.get("name", "Player#%d" % pid)
	var node = _create_player_visual(pid, pname)
	players_container.add_child(node)
	remote_players[pid] = node

func _update_remote_player_visual(pid: int):
	if not remote_players.has(pid):
		_ensure_remote_player(pid)
	var node = remote_players[pid]
	var info = MultiplayerManager.get_player_info(pid)
	node.position = info.get("pos", Vector2.ZERO)
	var sprite = node.get_node_or_null("Sprite")
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1) if info.get("alive", true) else Color(0.4, 0.4, 0.4, 0.5)
	var hp_bar = node.get_node_or_null("HpBar")
	if hp_bar:
		hp_bar.value = int(info.get("hp", 100))
	# Update name label to show level/title
	var name_lbl = node.get_node_or_null("NameLabel")
	if name_lbl:
		var lvl = int(info.get("level", 0))
		var title = String(info.get("title", ""))
		if lvl > 0 and not title.is_empty():
			name_lbl.text = "%s [Lv%d %s]" % [info.get("name", "?"), lvl, title]
		else:
			name_lbl.text = info.get("name", "?")

func _create_player_visual(pid: int, pname: String) -> Node2D:
	var node = Node2D.new()
	var color = PLAYER_COLORS[pid % PLAYER_COLORS.size()]
	# Body sprite (circle)
	var sprite = ColorRect.new()
	sprite.name = "Sprite"
	sprite.color = color
	sprite.size = Vector2(PLAYER_RADIUS * 2, PLAYER_RADIUS * 2)
	sprite.position = Vector2(-PLAYER_RADIUS, -PLAYER_RADIUS)
	sprite.z_index = 1
	node.add_child(sprite)
	# HP bar
	var hp_bar = ProgressBar.new()
	hp_bar.name = "HpBar"
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.custom_minimum_size = Vector2(50, 6)
	hp_bar.position = Vector2(-25, -PLAYER_RADIUS - 14)
	hp_bar.z_index = 2
	node.add_child(hp_bar)
	# Name label
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = pname
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", color.lightened(0.3))
	name_lbl.position = Vector2(-60, -PLAYER_RADIUS - 32)
	name_lbl.custom_minimum_size = Vector2(120, 16)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.z_index = 2
	node.add_child(name_lbl)
	return node

# === Dart ===
func _throw_dart():
	local_dart_id_counter += 1
	var dart_id = local_dart_id_counter
	# Direction: toward mouse
	var mouse_pos = get_local_mouse_position()
	var dir = (mouse_pos - local_pos).normalized()
	if dir.length() < 0.01:
		dir = Vector2.RIGHT
	var vel = dir * DART_SPEED
	var pos = local_pos + dir * (PLAYER_RADIUS + 5)
	# Spawn local
	_spawn_dart_visual(dart_id, pos, false)  # local = yellow
	local_darts[dart_id] = {
		"pos": pos,
		"vel": vel,
		"lifetime": DART_LIFETIME,
		"owner_id": MultiplayerManager.get_local_player_id(),
		"local": true,
	}
	# Notify server
	MultiplayerManager.send_dart(dart_id, pos, vel)

func _spawn_dart_visual(dart_id: int, pos: Vector2, is_remote: bool):
	var rect = ColorRect.new()
	rect.color = Color(1.0, 0.95, 0.3) if not is_remote else Color(1.0, 0.4, 0.4)
	rect.size = Vector2(DART_RADIUS * 2, DART_RADIUS * 2)
	rect.position = pos - Vector2(DART_RADIUS, DART_RADIUS)
	rect.z_index = 3
	darts_container.add_child(rect)
	if local_darts.has(dart_id):
		local_darts[dart_id]["node"] = rect

func _remove_dart(dart_id: int):
	if local_darts.has(dart_id):
		var d = local_darts[dart_id]
		if d.has("node") and is_instance_valid(d.node):
			d.node.queue_free()
		local_darts.erase(dart_id)

# === Signal handlers ===
func _on_player_state(pid: int, pos: Vector2, hp: int, score: int, alive: bool):
	_ensure_remote_player(pid)

func _on_player_joined(pid: int, _name: String):
	_ensure_remote_player(pid)
	_chat_system("→ [b]%s[/b] vào arena" % _name)

func _on_player_left(pid: int):
	if remote_players.has(pid):
		remote_players[pid].queue_free()
		remote_players.erase(pid)

func _on_player_died(victim_id: int, killer_id: int):
	if victim_id == MultiplayerManager.get_local_player_id():
		local_alive = false
		local_hp = 0
		local_respawn_timer = RESPAWN_TIME
		var killer_name = MultiplayerManager.player_name if killer_id == MultiplayerManager.get_local_player_id() else MultiplayerManager.get_player_info(killer_id).get("name", "?")
		_kill_feed_add("☠ Bạn bị tiêu diệt bởi [b]%s[/b]" % killer_name)
	else:
		var vname = MultiplayerManager.get_player_info(victim_id).get("name", "?")
		var kname = MultiplayerManager.get_player_info(killer_id).get("name", "?") if killer_id != victim_id else "chính mình"
		_kill_feed_add("☠ [b]%s[/b] bị tiêu diệt bởi [b]%s[/b]" % [vname, kname])

func _on_player_respawned(pid: int, pos: Vector2):
	if pid == MultiplayerManager.get_local_player_id():
		local_pos = pos
		local_alive = true
		local_hp = 100
		_chat_system("→ Bạn hồi sinh")
	else:
		_ensure_remote_player(pid)

func _on_dart_spawned(dart_id: int, owner_id: int, pos: Vector2, vel: Vector2):
	if owner_id == MultiplayerManager.get_local_player_id():
		return  # đã có local
	# Remote dart — store but don't simulate (owner simulates)
	if not local_darts.has(dart_id):
		local_darts[dart_id] = {
			"pos": pos,
			"vel": vel,
			"lifetime": DART_LIFETIME,
			"owner_id": owner_id,
			"local": false,
		}
		_spawn_dart_visual(dart_id, pos, true)

func _on_dart_removed(dart_id: int):
	_remove_dart(dart_id)

func _on_player_hit(victim_id: int, killer_id: int, damage: int):
	if victim_id == MultiplayerManager.get_local_player_id():
		local_hp = max(0, local_hp - damage)
		if local_hp <= 0 and local_alive:
			local_alive = false
			local_respawn_timer = RESPAWN_TIME
	if killer_id == MultiplayerManager.get_local_player_id() and victim_id != killer_id:
		local_score += 1
		local_kills += 1

func _on_chat(sender_id: int, sender_name: String, message: String):
	if sender_id == -1:
		_chat_system(message)
	else:
		var safe_name = sender_name.replace("[", "").replace("]", "")
		var safe_msg = message.replace("[", "").replace("]", "")
		chat_display.append_text("\n[color=#aaffaa]%s:[/color] %s" % [safe_name, safe_msg])

func _on_game_end(scores: Dictionary, kills: Dictionary):
	game_active = false
	# Determine if local player won
	var winner_id = -1
	var winner_score = -1
	for pid in scores.keys():
		if int(scores[pid]) > winner_score:
			winner_score = int(scores[pid])
			winner_id = int(pid)
	# Update local kills from server (more authoritative)
	if kills.has(MultiplayerManager.get_local_player_id()):
		local_kills = int(kills[MultiplayerManager.get_local_player_id()])
	# Display result
	if winner_id == MultiplayerManager.get_local_player_id():
		message_label.text = "🏆 BẠN THẮNG! Score: %d  •  Kills: %d" % [winner_score, local_kills]
		message_label.modulate = Color(1.0, 0.85, 0.3)
	else:
		var wname = MultiplayerManager.get_player_info(winner_id).get("name", "?")
		message_label.text = "🏆 Người thắng: %s (%d điểm)\nBạn: %d điểm • %d kills" % [wname, winner_score, local_score, local_kills]
		message_label.modulate = Color(0.7, 0.85, 1.0)
	AudioManager.play_variation("chime", 1.0, 1.1)
	# v4.1: Submit match result to backend for EXP
	_submit_match_result(winner_id == MultiplayerManager.get_local_player_id())

func _submit_match_result(won: bool):
	if game_ended:
		return
	game_ended = true
	if not AccountManager.is_logged_in():
		_show_exp_msg("⚠ Chưa đăng nhập — không nhận EXP", Color(0.9, 0.7, 0.3))
		return
	_show_exp_msg("Đang nộp kết quả match...", Color(0.7, 0.85, 1.0))
	AccountManager.submit_match_result(local_kills, local_score, won)

func _on_level_up(old_level: int, new_level: int, new_title: String):
	_show_exp_msg("🎉 LÊN LEVEL %d → %d! Danh hiệu: %s" % [old_level, new_level, new_title], Color(1.0, 0.85, 0.3))
	_kill_feed_add("🎉 [b]LEVEL UP[/b] %d → %d — %s" % [old_level, new_level, new_title])

func _on_exp_gained(amount: int, _total: int):
	_show_exp_msg("✨ Nhận %d EXP" % amount, Color(0.5, 1.0, 0.5))
	_kill_feed_add("✨ +%d EXP" % amount)

func _show_exp_msg(text: String, color: Color):
	exp_label.text = text
	exp_label.modulate = color
	# Fade out after 4 seconds
	var tween = create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(exp_label, "modulate:a", 0.0, 1.5)

func _on_disconnect():
	message_label.text = "⚠ Mất kết nối server"
	message_label.modulate = Color(1.0, 0.4, 0.3)
	game_active = false

func _end_game():
	if not game_active:
		return
	game_active = false
	message_label.text = "Hết giờ! Đang chờ kết quả..."
	message_label.modulate = Color(0.7, 0.85, 1.0)

# === Chat ===
func _chat_system(text: String):
	chat_display.append_text("\n[color=#888888]%s[/color]" % text)

func _on_chat_send():
	var text = chat_input.text.strip_edges()
	if text.is_empty():
		return
	MultiplayerManager.send_chat(text)
	var safe = text.replace("[", "").replace("]", "")
	chat_display.append_text("\n[color=#aaffff]%s (bạn):[/color] %s" % [MultiplayerManager.player_name, safe])
	chat_input.text = ""

func _kill_feed_add(text: String):
	kill_feed.append_text("\n• %s" % text)
	# Keep last 5 lines
	var lines = kill_feed.text.split("\n")
	if lines.size() > 6:
		kill_feed.text = "\n".join(lines.slice(lines.size() - 6, lines.size() - 1))

func _on_leave():
	AudioManager.play_cancel()
	MultiplayerManager.leave_room()
	# Stay connected to server, go back to lobby
	get_tree().change_scene_to_file("res://scenes/multiplayer_lobby.tscn")

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_leave()
