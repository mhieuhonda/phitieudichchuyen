extends Node

## NetworkManager - Quản lý kết nối mạng cho game online (v1.7)
## Singleton autoload, kết nối WebSocket đến Relay Server
## Xử lý: login, matchmaking, state sync, room events

signal connected_to_server()
signal disconnected_from_server()
signal connection_error(error_message: String)
signal login_success(player_id: String)
signal matchmaking_update(queue_size: int, min_players: int, max_players: int)
signal matchmaking_found(room_id: String, player_count: int, bot_count: int, total_players: int)
signal matchmaking_timeout(message: String)
signal matchmaking_left()
signal match_countdown(seconds: int)
signal match_start(data: Dictionary)
signal match_end(data: Dictionary)
signal state_sync(data: Dictionary)
signal room_player_joined(data: Dictionary)
signal room_player_left(data: Dictionary)
signal remote_player_update(player_id: String, data: Dictionary)
signal remote_dart_throw(player_id: String, data: Dictionary)
signal remote_teleport(player_id: String, data: Dictionary)
signal remote_player_killed(data: Dictionary)
signal remote_skill_used(player_id: String, data: Dictionary)
signal remote_player_respawned(data: Dictionary)
signal chat_message(data: Dictionary)
signal zone_shrank(radius: float)
signal pong_received(latency_ms: int)

# === CONFIG ===
const DEFAULT_SERVER_URL := "ws://163.44.96.79:25671/ws"
var server_url: String = DEFAULT_SERVER_URL
var auto_reconnect: bool = true
var max_reconnect_attempts: int = 5
var reconnect_delay: float = 3.0

# === STATE ===
var _ws: WebSocketPeer = null
var _is_connected: bool = false
var _is_logged_in: bool = false
var _player_id: String = ""
var _room_id: String = ""
var _reconnect_attempts: int = 0
var _ping_timer: float = 0.0
var _last_ping_time: int = 0
var _is_in_matchmaking: bool = false
var _is_in_match: bool = false

# Remote players cache
var remote_players: Dictionary = {}  # playerId -> { name, characterId, x, y, hp, maxHp, size, alive, score, kills, isBot }

enum ConnectionState { DISCONNECTED, CONNECTING, CONNECTED, LOGGED_IN }
var connection_state: ConnectionState = ConnectionState.DISCONNECTED

func _ready():
        _ws = WebSocketPeer.new()
        set_process(false)

func _process(delta):
        if not _ws:
                return

        _ws.poll()

        while _ws.get_available_packet_count() > 0:
                var packet = _ws.get_packet()
                if _ws.get_packet_mode() == WebSocketPeer.PACKET_MODE_TEXT:
                        var msg = packet.get_string_from_utf8()
                        _handle_message(msg)

        var state = _ws.get_ready_state()
        if state == WebSocketPeer.STATE_CLOSED:
                if _is_connected:
                        _is_connected = false
                        connection_state = ConnectionState.DISCONNECTED
                        disconnected_from_server.emit()
                        _try_reconnect()
        elif state == WebSocketPeer.STATE_OPEN:
                if not _is_connected:
                        _is_connected = true
                        connection_state = ConnectionState.CONNECTED
                        _reconnect_attempts = 0
                        connected_to_server.emit()

        # Ping
        if _is_connected:
                _ping_timer += delta
                if _ping_timer >= 15.0:
                        _ping_timer = 0.0
                        _send_message("ping", {})

# === PUBLIC API ===

func connect_to_server(url: String = ""):
        if url != "":
                server_url = url
        if _is_connected:
                return
        connection_state = ConnectionState.CONNECTING
        var err = _ws.connect_to_url(server_url)
        if err != OK:
                connection_error.emit("Không thể kết nối đến server")
                connection_state = ConnectionState.DISCONNECTED
                return
        set_process(true)

func disconnect_from_server():
        auto_reconnect = false
        _is_in_matchmaking = false
        _is_in_match = false
        if _ws:
                _ws.close()
        _is_connected = false
        _is_logged_in = false
        connection_state = ConnectionState.DISCONNECTED
        set_process(false)

func is_connected() -> bool:
        return _is_connected

func is_logged_in() -> bool:
        return _is_logged_in

func is_in_matchmaking() -> bool:
        return _is_in_matchmaking

func is_in_match() -> bool:
        return _is_in_match

func get_player_id() -> String:
        return _player_id

func get_room_id() -> String:
        return _room_id

func get_latency() -> int:
        return 0  # Updated on pong

# === LOGIN ===

func login(player_name: String = "Player", character_id: int = 0):
        if not _is_connected:
                return
        var stored_id = _get_stored_player_id()
        _send_message("login", {
                "playerId": stored_id,
                "name": player_name,
                "characterId": character_id
        })

# === MATCHMAKING ===

func join_matchmaking(name: String = "", character_id: int = -1):
        if not _is_logged_in:
                return
        _is_in_matchmaking = true
        var data = {}
        if name != "":
                data["name"] = name
        if character_id >= 0:
                data["characterId"] = character_id
        _send_message("matchmaking_join", data)

func leave_matchmaking():
        _is_in_matchmaking = false
        _send_message("matchmaking_leave", {})

# === GAME ACTIONS ===

func send_player_update(x: float, y: float, hp: float, max_hp: float, size: float, alive: bool, score: int, kills: int):
        if not _is_in_match:
                return
        _send_message("player_update", {
                "x": x, "y": y, "hp": hp, "maxHp": max_hp,
                "size": size, "alive": alive, "score": score, "kills": kills
        })

func send_dart_throw(direction_x: float, direction_y: float, power: float, dart_x: float, dart_y: float):
        if not _is_in_match:
                return
        _send_message("dart_throw", {
                "dirX": direction_x, "dirY": direction_y,
                "power": power, "x": dart_x, "y": dart_y
        })

func send_teleport(x: float, y: float):
        if not _is_in_match:
                return
        _send_message("player_teleport", { "x": x, "y": y })

func send_kill(victim_id: String, score: int = 100):
        if not _is_in_match:
                return
        _send_message("player_kill", { "victimId": victim_id, "score": score })

func send_skill_use(skill_id: String, data: Dictionary = {}):
        if not _is_in_match:
                return
        data["skillId"] = skill_id
        _send_message("skill_use", data)

func send_respawn():
        if not _is_in_match:
                return
        _send_message("player_respawn", {})

func send_chat(message: String):
        if not _is_in_match:
                return
        _send_message("chat", { "message": message })

# === INTERNAL ===

func _send_message(type: String, data: Dictionary):
        if not _ws or not _is_connected:
                return
        var msg = JSON.stringify({ "type": type, "data": data })
        _ws.send_text(msg)

func _handle_message(raw: String):
        var json = JSON.new()
        if json.parse(raw) != OK:
                return
        var obj = json.get_data()
        if not obj is Dictionary:
                return
        var type = obj.get("type", "")
        var data = obj.get("data", {})

        match type:
                "login_ok":
                        _player_id = str(data.get("playerId", ""))
                        _is_logged_in = true
                        connection_state = ConnectionState.LOGGED_IN
                        _store_player_id(_player_id)
                        login_success.emit(_player_id)

                "matchmaking_update":
                        matchmaking_update.emit(
                                int(data.get("queueSize", 0)),
                                int(data.get("minPlayers", 10)),
                                int(data.get("maxPlayers", 20))
                        )

                "matchmaking_timeout":
                        matchmaking_timeout.emit(str(data.get("message", "")))

                "matchmaking_left":
                        _is_in_matchmaking = false
                        matchmaking_left.emit()

                "match_found":
                        _is_in_matchmaking = false
                        _is_in_match = true
                        _room_id = str(data.get("roomId", ""))
                        matchmaking_found.emit(
                                _room_id,
                                int(data.get("playerCount", 0)),
                                int(data.get("botCount", 0)),
                                int(data.get("totalPlayers", 0))
                        )

                "match_countdown":
                        match_countdown.emit(int(data.get("seconds", 0)))

                "match_start":
                        _is_in_match = true
                        # Parse remote players
                        remote_players.clear()
                        for p in data.get("players", []):
                                var pid = str(p.get("playerId", ""))
                                remote_players[pid] = {
                                        "name": p.get("name", ""),
                                        "characterId": p.get("characterId", 0),
                                        "x": p.get("x", 0.0),
                                        "y": p.get("y", 0.0),
                                        "hp": 100.0, "maxHp": 100.0, "size": 20.0,
                                        "alive": true, "score": 0, "kills": 0,
                                        "isBot": p.get("isBot", false)
                                }
                        match_start.emit(data)

                "match_end":
                        _is_in_match = false
                        match_end.emit(data)

                "state_sync":
                        # Update remote players from state sync
                        for p in data.get("players", []):
                                var pid = str(p.get("playerId", ""))
                                if pid == _player_id:
                                        continue
                                if remote_players.has(pid):
                                        var rp = remote_players[pid]
                                        rp["x"] = p.get("x", rp["x"])
                                        rp["y"] = p.get("y", rp["y"])
                                        rp["hp"] = p.get("hp", rp["hp"])
                                        rp["maxHp"] = p.get("maxHp", rp["maxHp"])
                                        rp["size"] = p.get("size", rp["size"])
                                        rp["alive"] = p.get("alive", rp["alive"])
                                        rp["score"] = p.get("score", rp["score"])
                                        rp["kills"] = p.get("kills", rp["kills"])
                                else:
                                        remote_players[pid] = {
                                                "name": p.get("name", ""),
                                                "characterId": p.get("characterId", 0),
                                                "x": p.get("x", 0.0), "y": p.get("y", 0.0),
                                                "hp": p.get("hp", 100.0), "maxHp": p.get("maxHp", 100.0),
                                                "size": p.get("size", 20.0), "alive": p.get("alive", true),
                                                "score": p.get("score", 0), "kills": p.get("kills", 0),
                                                "isBot": p.get("isBot", false)
                                        }
                        state_sync.emit(data)

                "room_player_joined":
                        var pid = str(data.get("playerId", ""))
                        remote_players[pid] = {
                                "name": data.get("name", ""),
                                "characterId": data.get("characterId", 0),
                                "x": 0.0, "y": 0.0, "hp": 100.0, "maxHp": 100.0,
                                "size": 20.0, "alive": true, "score": 0, "kills": 0,
                                "isBot": data.get("isBot", false)
                        }
                        room_player_joined.emit(data)

                "room_player_left":
                        var pid = str(data.get("playerId", ""))
                        remote_players.erase(pid)
                        room_player_left.emit(data)

                "dart_thrown":
                        remote_dart_throw.emit(str(data.get("playerId", "")), data)

                "player_teleport":
                        remote_teleport.emit(str(data.get("playerId", "")), data)

                "player_killed":
                        remote_player_killed.emit(data)

                "skill_used":
                        remote_skill_used.emit(str(data.get("playerId", "")), data)

                "player_respawned":
                        remote_player_respawned.emit(data)

                "chat_message":
                        chat_message.emit(data)

                "zone_shrank":
                        zone_shrank.emit(float(data.get("radius", 900.0)))

                "pong":
                        var latency = Time.get_ticks_msec() - _last_ping_time
                        pong_received.emit(latency)

func _try_reconnect():
        if not auto_reconnect:
                return
        if _reconnect_attempts >= max_reconnect_attempts:
                connection_error.emit("Không thể kết nối lại sau %d lần thử" % max_reconnect_attempts)
                return
        _reconnect_attempts += 1
        get_tree().create_timer(reconnect_delay).timeout.connect(func():
                connect_to_server(server_url)
        )

func _get_stored_player_id() -> String:
        var config = ConfigFile.new()
        if config.load("user://network.cfg") == OK:
                return config.get_value("network", "player_id", "")
        return ""

func _store_player_id(pid: String):
        var config = ConfigFile.new()
        config.set_value("network", "player_id", pid)
        config.save("user://network.cfg")

func _exit_tree():
        disconnect_from_server()
