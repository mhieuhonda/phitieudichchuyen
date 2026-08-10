extends Node

## MultiplayerManager - Quản lý kết nối multiplayer (v4.0)
## Singleton autoload.
## - WebSocket client kết nối tới server wss://phitieu.louis.vangioitutien.com/ws
## - Gửi/nhận JSON messages
## - Quản lý room state, local player, remote players
## - Cung cấp signals cho UI hook vào

signal connected()
signal disconnected()
signal connection_error(reason: String)
signal room_joined(room_id: String, players: Array)
signal room_left()
signal player_joined(player_id: int, name: String)
signal player_left(player_id: int)
signal player_state_updated(player_id: int, pos: Vector2, hp: int, score: int, alive: bool)
signal dart_spawned(dart_id: int, owner_id: int, pos: Vector2, vel: Vector2)
signal dart_removed(dart_id: int)
signal player_hit(victim_id: int, killer_id: int, damage: int)
signal player_died(victim_id: int, killer_id: int)
signal player_respawned(player_id: int, pos: Vector2)
signal chat_received(sender_id: int, sender_name: String, message: String)
signal game_started(initial_players: Array)
signal game_ended(scores: Dictionary)
signal room_list_updated(rooms: Array)

# Server URL — qua Traefik (wss:// + domain)
const SERVER_URL := "wss://phitieu.louis.vangioitutien.com/ws"
const RECONNECT_TIMEOUT := 3.0
const HEARTBEAT_INTERVAL := 10.0

var socket: WebSocketPeer
var is_connected: bool = false
var is_connecting: bool = false
var player_name: String = "Player"
var player_id: int = -1
var current_room_id: String = ""
var current_players: Dictionary = {}  # player_id -> {name, pos, hp, score, alive}

var _reconnect_timer: float = 0.0
var _heartbeat_timer: float = 0.0
var _outgoing_queue: Array = []  # buffer messages khi đang connecting

func _ready():
	set_process(true)

func _process(delta):
	if not socket:
		return
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		is_connected = true
		# Process incoming
		while socket.get_available_packet_count() > 0:
			var pkt = socket.get_packet()
			var text = pkt.get_string_from_utf8()
			_handle_message(text)
		# Heartbeat
		_heartbeat_timer += delta
		if _heartbeat_timer >= HEARTBEAT_INTERVAL:
			_heartbeat_timer = 0.0
			_send({"type": "ping"})
	elif state == WebSocketPeer.STATE_CLOSED:
		if is_connected:
			is_connected = false
			disconnected.emit()
		# Auto-reconnect
		_reconnect_timer += delta
		if _reconnect_timer >= RECONNECT_TIMEOUT and is_connecting:
			_reconnect_timer = 0.0
			_do_connect()
	# Flush outgoing queue
	if is_connected and not _outgoing_queue.is_empty():
		for msg in _outgoing_queue:
			_send_raw(msg)
		_outgoing_queue.clear()

## Bắt đầu kết nối tới server
func connect_to_server(name: String = "Player"):
	player_name = name
	is_connecting = true
	_do_connect()

func _do_connect():
	if socket:
		socket.close()
	socket = WebSocketPeer.new()
	var err = socket.connect_to_url(SERVER_URL)
	if err != OK:
		connection_error.emit("Không thể kết nối: code %d" % err)
		is_connecting = false
		return

## Ngắt kết nối
func disconnect_from_server():
	is_connecting = false
	if socket:
		socket.close()
	is_connected = false
	player_id = -1
	current_room_id = ""
	current_players.clear()
	room_left.emit()

## Gửi message JSON
func _send(msg: Dictionary):
	if not is_connected:
		_outgoing_queue.append(msg)
		return
	_send_raw(msg)

func _send_raw(msg: Dictionary):
	var text = JSON.stringify(msg)
	socket.send_text(text)

# === Room API ===
func create_room(name: String = ""):
	_send({"type": "create_room", "name": name})

func join_room(room_id: String):
	_send({"type": "join_room", "room_id": room_id})

func leave_room():
	_send({"type": "leave_room"})
	current_room_id = ""
	current_players.clear()
	room_left.emit()

func list_rooms():
	_send({"type": "list_rooms"})

func start_game():
	_send({"type": "start_game"})

func send_chat(message: String):
	_send({"type": "chat", "message": message})

# === In-game API ===
func send_player_state(pos: Vector2, hp: int, score: int, alive: bool):
	_send({
		"type": "player_state",
		"pos_x": pos.x,
		"pos_y": pos.y,
		"hp": hp,
		"score": score,
		"alive": alive,
	})

func send_dart(dart_id: int, pos: Vector2, vel: Vector2):
	_send({
		"type": "dart_spawn",
		"dart_id": dart_id,
		"pos_x": pos.x,
		"pos_y": pos.y,
		"vel_x": vel.x,
		"vel_y": vel.y,
	})

func send_dart_remove(dart_id: int):
	_send({"type": "dart_remove", "dart_id": dart_id})

func send_hit(victim_id: int, damage: int):
	_send({"type": "hit", "victim_id": victim_id, "damage": damage})

func send_respawn():
	_send({"type": "respawn"})

# === Message handler ===
func _handle_message(text: String):
	var json = JSON.new()
	if json.parse(text) != OK:
		return
	var msg = json.data
	if typeof(msg) != TYPE_DICTIONARY:
		return
	var type = msg.get("type", "")
	match type:
		"hello":
			player_id = int(msg.get("player_id", -1))
			connected.emit()
		"room_joined":
			current_room_id = String(msg.get("room_id", ""))
			var players = msg.get("players", [])
			current_players.clear()
			for p in players:
				var pid = int(p.get("id", -1))
				current_players[pid] = {
					"name": String(p.get("name", "?")),
					"pos": Vector2(float(p.get("pos_x", 0)), float(p.get("pos_y", 0))),
					"hp": int(p.get("hp", 100)),
					"score": int(p.get("score", 0)),
					"alive": bool(p.get("alive", true)),
				}
			room_joined.emit(current_room_id, players)
		"room_left":
			current_room_id = ""
			current_players.clear()
			room_left.emit()
		"player_joined":
			var pid = int(msg.get("player_id", -1))
			var pname = String(msg.get("name", "?"))
			current_players[pid] = {"name": pname, "pos": Vector2.ZERO, "hp": 100, "score": 0, "alive": true}
			player_joined.emit(pid, pname)
		"player_left":
			var pid = int(msg.get("player_id", -1))
			current_players.erase(pid)
			player_left.emit(pid)
		"player_state":
			var pid = int(msg.get("player_id", -1))
			if current_players.has(pid):
				current_players[pid]["pos"] = Vector2(float(msg.get("pos_x", 0)), float(msg.get("pos_y", 0)))
				current_players[pid]["hp"] = int(msg.get("hp", 100))
				current_players[pid]["score"] = int(msg.get("score", 0))
				current_players[pid]["alive"] = bool(msg.get("alive", true))
				player_state_updated.emit(pid, current_players[pid]["pos"], current_players[pid]["hp"], current_players[pid]["score"], current_players[pid]["alive"])
		"dart_spawn":
			dart_spawned.emit(int(msg.get("dart_id", 0)), int(msg.get("owner_id", -1)), Vector2(float(msg.get("pos_x", 0)), float(msg.get("pos_y", 0))), Vector2(float(msg.get("vel_x", 0)), float(msg.get("vel_y", 0))))
		"dart_remove":
			dart_removed.emit(int(msg.get("dart_id", 0)))
		"hit":
			player_hit.emit(int(msg.get("victim_id", -1)), int(msg.get("killer_id", -1)), int(msg.get("damage", 0)))
		"player_died":
			var vid = int(msg.get("victim_id", -1))
			var kid = int(msg.get("killer_id", -1))
			if current_players.has(vid):
				current_players[vid]["alive"] = false
			player_died.emit(vid, kid)
		"player_respawned":
			var pid = int(msg.get("player_id", -1))
			var pos = Vector2(float(msg.get("pos_x", 0)), float(msg.get("pos_y", 0)))
			if current_players.has(pid):
				current_players[pid]["alive"] = true
				current_players[pid]["hp"] = 100
				current_players[pid]["pos"] = pos
			player_respawned.emit(pid, pos)
		"chat":
			chat_received.emit(int(msg.get("sender_id", -1)), String(msg.get("sender_name", "?")), String(msg.get("message", "")))
		"game_start":
			var players = msg.get("players", [])
			game_started.emit(players)
		"game_end":
			game_ended.emit(msg.get("scores", {}))
		"room_list":
			room_list_updated.emit(msg.get("rooms", []))
		"error":
			connection_error.emit(String(msg.get("message", "Lỗi không rõ")))
		"pong":
			pass  # heartbeat ack

## Lấy danh sách player trong room
func get_players() -> Array:
	return current_players.keys()

func get_player_info(pid: int) -> Dictionary:
	return current_players.get(pid, {})

func get_local_player_id() -> int:
	return player_id
