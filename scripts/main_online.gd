extends Node2D

## MainOnline - Scene chính game ONLINE (v1.7)
## - Giống main.gd nhưng đồng bộ với relay server
## - Remote players + bot AI được spawn như entity
## - State sync qua NetworkManager

@onready var player: CharacterBody2D = $Player
@onready var remote_container: Node2D = $RemotePlayers
@onready var ai_container: Node2D = $AIPlayers
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var joystick: Control = $UILayer/VirtualJoystick
@onready var mobile_controls: Control = $UILayer/MobileControls

var ai_scene: PackedScene = preload("res://scenes/ai_player.tscn")
var remote_player_scene: PackedScene = preload("res://scenes/remote_player.tscn")
var dart_scene: PackedScene = preload("res://scenes/dart.tscn")
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_camera_offset: Vector2 = Vector2.ZERO

# Sync throttling
var _sync_timer: float = 0.0
var _sync_interval: float = 0.05  # 20 ticks/giây
var _is_match_active: bool = false

func _ready():
        GameManager.reset_game()
        AIPlayer.reset_name_index()

        player.player_id = 0
        player.player_name = "Player"
        player.add_to_group("players")

        if joystick:
                player.set_joystick(joystick)

        if mobile_controls:
                mobile_controls.teleport_pressed.connect(_on_mobile_teleport)
                mobile_controls.throw_started.connect(_on_mobile_throw_start)
                mobile_controls.throw_aim_updated.connect(_on_mobile_throw_aim)
                mobile_controls.throw_ended.connect(_on_mobile_throw_end)
                mobile_controls.skill_dash_pressed.connect(_on_mobile_skill_dash)
                mobile_controls.skill_shield_pressed.connect(_on_mobile_skill_shield)
                mobile_controls.skill_multishot_pressed.connect(_on_mobile_skill_multishot)
                if mobile_controls.has_signal("skill_crown_pressed"):
                        mobile_controls.skill_crown_pressed.connect(_on_mobile_skill_crown)

        hud.set_player(player)

        player.player_died.connect(_on_player_died)
        player.player_respawned.connect(_on_player_respawned)
        player.teleport_performed.connect(_on_teleport_performed)

        GameManager.screen_shake_requested.connect(apply_screen_shake)
        GameManager.zone_shrank.connect(_on_zone_shrank)
        GameManager.combo_achieved.connect(_on_combo_achieved)
        GameManager.game_over.connect(_on_game_over)

        _setup_camera()

        # Connect network signals
        NetworkManager.state_sync.connect(_on_state_sync)
        NetworkManager.remote_dart_throw.connect(_on_remote_dart_throw)
        NetworkManager.remote_teleport.connect(_on_remote_teleport)
        NetworkManager.remote_player_killed.connect(_on_remote_player_killed)
        NetworkManager.remote_skill_used.connect(_on_remote_skill_used)
        NetworkManager.remote_player_respawned.connect(_on_remote_player_respawned)
        NetworkManager.zone_shrank.connect(_on_net_zone_shrank)
        NetworkManager.match_end.connect(_on_match_end)
        NetworkManager.room_player_joined.connect(_on_room_player_joined)
        NetworkManager.room_player_left.connect(_on_room_player_left)

        # Spawn initial remote players from NetworkManager cache
        _spawn_initial_remote_players()

        AudioManager.play_music("game")

        _is_match_active = true

func _exit_tree():
        # v1.9 FIX: disconnect network signal handlers so they don't fire on freed scene
        # (which would cause "Invalid access to property/method on freed instance" errors)
        _is_match_active = false
        if NetworkManager.state_sync.is_connected(_on_state_sync):
                NetworkManager.state_sync.disconnect(_on_state_sync)
        if NetworkManager.remote_dart_throw.is_connected(_on_remote_dart_throw):
                NetworkManager.remote_dart_throw.disconnect(_on_remote_dart_throw)
        if NetworkManager.remote_teleport.is_connected(_on_remote_teleport):
                NetworkManager.remote_teleport.disconnect(_on_remote_teleport)
        if NetworkManager.remote_player_killed.is_connected(_on_remote_player_killed):
                NetworkManager.remote_player_killed.disconnect(_on_remote_player_killed)
        if NetworkManager.remote_skill_used.is_connected(_on_remote_skill_used):
                NetworkManager.remote_skill_used.disconnect(_on_remote_skill_used)
        if NetworkManager.remote_player_respawned.is_connected(_on_remote_player_respawned):
                NetworkManager.remote_player_respawned.disconnect(_on_remote_player_respawned)
        if NetworkManager.zone_shrank.is_connected(_on_net_zone_shrank):
                NetworkManager.zone_shrank.disconnect(_on_net_zone_shrank)
        if NetworkManager.match_end.is_connected(_on_match_end):
                NetworkManager.match_end.disconnect(_on_match_end)
        if NetworkManager.room_player_joined.is_connected(_on_room_player_joined):
                NetworkManager.room_player_joined.disconnect(_on_room_player_joined)
        if NetworkManager.room_player_left.is_connected(_on_room_player_left):
                NetworkManager.room_player_left.disconnect(_on_room_player_left)

func _spawn_initial_remote_players():
        for pid in NetworkManager.remote_players:
                var rp_data = NetworkManager.remote_players[pid]
                if rp_data.get("isBot", false):
                        # Spawn bot as AI
                        _spawn_bot_ai(pid, rp_data)
                else:
                        # Spawn remote player
                        _spawn_remote_player(pid, rp_data)

func _spawn_remote_player(pid: String, data: Dictionary):
        if remote_container.get_node_or_null(pid):
                return  # Already spawned
        var remote = remote_player_scene.instantiate()
        remote.name = pid
        remote.player_id = pid
        remote.player_name = data.get("name", "Player")
        remote.character_id = data.get("characterId", 0)
        remote.global_position = Vector2(data.get("x", 1000), data.get("y", 1000))
        remote_container.add_child(remote)

func _spawn_bot_ai(pid: String, data: Dictionary):
        var ai = ai_scene.instantiate()
        ai.name = pid
        # Set server-provided name BEFORE add_child so _ready() doesn't overwrite it.
        # (ai_player._ready checks if ai_name is non-empty before auto-assigning.)
        ai.ai_name = data.get("name", "Bot")
        ai.global_position = Vector2(
                GameManager.zone_center.x + randf_range(-400, 400),
                GameManager.zone_center.y + randf_range(-400, 400)
        )
        ai_container.add_child(ai)
        # Re-assert name + label after _ready() in case anything reset it
        ai.ai_name = data.get("name", "Bot")
        if ai.name_label:
                ai.name_label.text = ai.ai_name
        ai.ai_died.connect(_on_ai_died)

func _process(delta):
        if not is_instance_valid(player):
                return
        if player.is_alive:
                camera.position = player.global_position

        if shake_timer > 0 and shake_duration > 0.001:
                shake_timer -= delta
                var intensity = shake_intensity * (shake_timer / shake_duration)
                camera.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
        else:
                shake_timer = 0.0
                camera.offset = original_camera_offset

        # Sync local player state to server
        if _is_match_active and NetworkManager.is_in_match():
                _sync_timer += delta
                if _sync_timer >= _sync_interval:
                        _sync_timer = 0.0
                        NetworkManager.send_player_update(
                                player.global_position.x, player.global_position.y,
                                GameManager.player_hp, GameManager.player_max_hp,
                                GameManager.player_size, player.is_alive,
                                GameManager.player_score, GameManager.player_kills
                        )

        # Update remote player positions from cache
        _update_remote_visuals()

func _update_remote_visuals():
        for pid in NetworkManager.remote_players:
                var data = NetworkManager.remote_players[pid]
                var node = remote_container.get_node_or_null(pid)
                if node and node.has_method("update_from_network"):
                        node.update_from_network(data)

# === NETWORK HANDLERS ===

func _on_state_sync(data: Dictionary):
        var time_remaining = float(data.get("timeRemaining", "300"))
        GameManager.time_remaining = time_remaining
        # Zone sync from server
        var zone_r = float(data.get("zoneRadius", 900))
        GameManager.zone_radius = zone_r

func _on_remote_dart_throw(player_id: String, data: Dictionary):
        var dir = Vector2(data.get("dirX", 1.0), data.get("dirY", 0.0))
        var power = data.get("power", 0.5)
        var dart = dart_scene.instantiate()
        dart.global_position = Vector2(data.get("x", 0), data.get("y", 0))
        dart.set_direction(dir, power)
        dart.owner_player_id = hash(player_id)
        dart.add_to_group("darts")
        # Don't connect kill signals for remote darts in online mode
        $Map.add_child(dart)
        AudioManager.play_throw()

func _on_remote_teleport(player_id: String, data: Dictionary):
        var node = remote_container.get_node_or_null(player_id)
        if node and node.has_method("teleport_to"):
                node.teleport_to(Vector2(data.get("x", 0), data.get("y", 0)))

func _on_remote_player_killed(data: Dictionary):
        var killer_name = data.get("killerName", "")
        var victim_name = data.get("victimName", "")
        if victim_name != "":
                hud._add_kill_feed("%s bị %s tiêu diệt" % [victim_name, killer_name], Color(1.0, 0.5, 0.2))
        AudioManager.play_kill()

func _on_remote_skill_used(player_id: String, data: Dictionary):
        pass  # Visual effect handled by remote player node

func _on_remote_player_respawned(data: Dictionary):
        var pid = str(data.get("playerId", ""))
        var node = remote_container.get_node_or_null(pid)
        if node and node.has_method("respawn_at"):
                node.respawn_at(Vector2(data.get("x", 0), data.get("y", 0)))
        hud._add_kill_feed("Người chơi hồi sinh!", Color(0.2, 1.0, 0.2))

func _on_net_zone_shrank(radius: float):
        GameManager.zone_radius = radius
        hud._add_kill_feed("Vòng bo thu nhỏ!", Color(1.0, 0.5, 0.0))

func _on_match_end(data: Dictionary):
        _is_match_active = false
        var winner_name = data.get("winnerName", "Hòa")
        var leaderboard = data.get("leaderboard", [])
        hud._show_results(winner_name, _convert_leaderboard(leaderboard))
        AudioManager.play_achievement()

func _on_room_player_joined(data: Dictionary):
        var pid = str(data.get("playerId", ""))
        var is_bot = data.get("isBot", false)
        if is_bot:
                _spawn_bot_ai(pid, { "name": data.get("name", "Bot") })
        else:
                _spawn_remote_player(pid, data)
        hud._add_kill_feed("%s vào trận!" % data.get("name", ""), Color(0.4, 1.0, 0.4))

func _on_room_player_left(data: Dictionary):
        var pid = str(data.get("playerId", ""))
        var node = remote_container.get_node_or_null(pid)
        if node:
                node.queue_free()
        hud._add_kill_feed("%s rời trận" % data.get("name", ""), Color(1.0, 0.5, 0.2))

func _convert_leaderboard(lb_data: Array) -> Array:
        var result = []
        for entry in lb_data:
                result.append({
                        "id": entry.get("rank", 0),
                        "name": entry.get("name", ""),
                        "score": entry.get("score", 0),
                        "kills": entry.get("kills", 0),
                        "is_player": str(entry.get("playerId", "")) == NetworkManager.get_player_id(),
                        "alive": true
                })
        return result

# === LOCAL HANDLERS (same as main.gd) ===

func _setup_camera():
        camera.position_smoothing_enabled = true
        camera.position_smoothing_speed = 5.0
        original_camera_offset = camera.offset

func _on_mobile_teleport():
        player._teleport_to_dart()
        if NetworkManager.is_in_match():
                NetworkManager.send_teleport(player.global_position.x, player.global_position.y)

func _on_mobile_throw_start():
        player.start_aim_mobile()

func _on_mobile_throw_aim(direction: Vector2, power: float):
        player.update_aim_mobile(direction, power)

func _on_mobile_throw_end(direction: Vector2, power: float):
        player.throw_dart_mobile(direction, power)
        if NetworkManager.is_in_match():
                NetworkManager.send_dart_throw(direction.x, direction.y, power, player.global_position.x, player.global_position.y)

func _on_mobile_skill_dash():
        player.activate_skill(GameManager.Skill.DASH)
        if NetworkManager.is_in_match():
                NetworkManager.send_skill_use("dash")

func _on_mobile_skill_shield():
        player.activate_skill(GameManager.Skill.SHIELD)
        if NetworkManager.is_in_match():
                NetworkManager.send_skill_use("shield")

func _on_mobile_skill_multishot():
        player.activate_skill(GameManager.Skill.MULTISHOT)
        if NetworkManager.is_in_match():
                NetworkManager.send_skill_use("multishot")

func _on_mobile_skill_crown():
        if player.has_method("activate_crown_skill"):
                player.activate_crown_skill()
                if NetworkManager.is_in_match():
                        NetworkManager.send_skill_use("crown")

func _on_player_died(p: CharacterBody2D):
        var killer = p.get_killer_name()
        if killer != "":
                hud._add_kill_feed("Bạn bị %s tiêu diệt!" % killer, Color(1.0, 0.3, 0.3))
        else:
                hud._add_kill_feed("Bạn đã bị tiêu diệt!", Color(1.0, 0.2, 0.2))
        AudioManager.play_warning()

func _on_player_respawned(p: CharacterBody2D):
        hud._add_kill_feed("Đã hồi sinh!", Color(0.2, 1.0, 0.2))
        AudioManager.play_success()
        if NetworkManager.is_in_match():
                NetworkManager.send_respawn()

func _on_teleport_performed(p: CharacterBody2D, to_position: Vector2):
        if NetworkManager.is_in_match():
                NetworkManager.send_teleport(to_position.x, to_position.y)

func _on_ai_died(ai: CharacterBody2D, killer: Node2D):
        if killer == player:
                hud._add_kill_feed("Bạn đã tiêu diệt %s!" % ai.ai_name, Color(0.2, 1.0, 0.2))
                AudioManager.play_achievement()
        else:
                var killer_name = killer.ai_name if "ai_name" in killer else "Player"
                hud._add_kill_feed("%s bị %s tiêu diệt" % [ai.ai_name, killer_name], Color(1.0, 0.5, 0.2))

func _on_zone_shrank(new_radius: float):
        AudioManager.play_zone_shrink()

func _on_combo_achieved(combo_count: int):
        AudioManager.play_combo(combo_count)

func _on_game_over(winner_name: String, leaderboard: Array):
        pass  # Handled by network match_end

func apply_screen_shake(intensity: float = 5.0, duration: float = 0.3):
        if SettingsManager.screen_shake_enabled:
                shake_intensity = intensity
                shake_duration = duration
                shake_timer = duration

func _input(event: InputEvent):
        if event.is_action_pressed("menu_back"):
                if NetworkManager.is_server_connected():
                        NetworkManager.disconnect_from_server()
                get_tree().change_scene_to_file("res://scenes/menu.tscn")
