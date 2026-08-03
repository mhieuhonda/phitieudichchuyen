extends Node

## GameManager - Quản lý trạng thái toàn cục của game
## Singleton autoload, điều khiển điểm số, combo, respawn, vòng bo, pickups

signal player_score_changed(new_score: int)
signal player_size_changed(new_size: float)
signal player_killed(killer_id: int, victim_id: int)
signal zone_shrank(new_radius: float)
signal game_over(winner_name: String)
signal combo_achieved(combo_count: int)
signal screen_shake_requested(intensity: float, duration: float)

# === CẤU HÌNH ===
@export_group("Phi Tiêu")
@export var max_darts_per_player: int = 3
@export var dart_lifetime: float = 5.0
@export var dart_speed: float = 800.0
@export var max_throw_power: float = 1.0
@export var min_throw_power: float = 0.2
@export var dart_hit_damage: float = 25.0
@export var mid_flight_teleport_enabled: bool = true

@export_group("Người Chơi")
@export var walk_speed: float = 80.0
@export var teleport_kill_radius: float = 40.0
@export var player_max_hp: float = 100.0
@export var initial_player_radius: float = 20.0
@export var size_per_kill: float = 5.0
@export var score_per_kill: int = 100
@export var respawn_time: float = 3.0
@export var combo_window: float = 2.0
@export var max_player_size: float = 60.0

@export_group("Vòng Bo")
@export var zone_shrink_interval: float = 30.0
@export var zone_shrink_amount: float = 50.0
@export var zone_min_radius: float = 200.0
@export var zone_damage_per_second: float = 10.0
@export var zone_shrink_acceleration: float = 1.1

@export_group("AI")
@export var num_ai_players: int = 5
@export var ai_dodge_chance: float = 0.4
@export var ai_accuracy: float = 0.7
@export var ai_mid_flight_teleport_chance: float = 0.5

@export_group("Map")
@export var map_size: Vector2 = Vector2(2000, 2000)

# === TRẠNG THÁI ===
var player_score: int = 0
var player_size: float
var player_hp: float
var zone_radius: float
var zone_center: Vector2
var game_active: bool = false
var players_alive: int = 0
var combo_count: int = 0
var combo_timer: float = 0.0
var current_shrink_count: int = 0
var game_time: float = 0.0
var total_kills: int = 0

func _ready():
    reset_game()

func _process(delta):
    if game_active:
        game_time += delta
        if combo_count > 0:
            combo_timer -= delta
            if combo_timer <= 0:
                combo_count = 0

func reset_game():
    player_score = 0
    player_size = initial_player_radius
    player_hp = player_max_hp
    zone_radius = map_size.x * 0.45
    zone_center = map_size / 2.0
    game_active = true
    players_alive = num_ai_players + 1
    combo_count = 0
    combo_timer = 0.0
    current_shrink_count = 0
    game_time = 0.0
    total_kills = 0
    emit_signal("player_score_changed", player_score)
    emit_signal("player_size_changed", player_size)

func add_score(points: int):
    var multiplier = 1.0 + (combo_count * 0.5)
    var actual_points = int(points * multiplier)
    player_score += actual_points
    emit_signal("player_score_changed", player_score)
    return actual_points

func add_size(amount: float):
    player_size = min(player_size + amount, max_player_size)
    emit_signal("player_size_changed", player_size)

func register_kill():
    total_kills += 1
    combo_count += 1
    combo_timer = combo_window
    if combo_count >= 2:
        emit_signal("combo_achieved", combo_count)

func take_damage(amount: float) -> bool:
    player_hp -= amount
    if player_hp <= 0:
        player_hp = 0
        return true
    return false

func heal(amount: float):
    player_hp = min(player_hp + amount, player_max_hp)

func shrink_zone():
    if zone_radius > zone_min_radius:
        current_shrink_count += 1
        var actual_amount = zone_shrink_amount * pow(zone_shrink_acceleration, current_shrink_count - 1)
        zone_radius -= actual_amount
        zone_radius = max(zone_radius, zone_min_radius)
        emit_signal("zone_shrank", zone_radius)

func is_in_zone(pos: Vector2) -> bool:
    return pos.distance_to(zone_center) <= zone_radius

func get_zone_damage(delta: float) -> float:
    return zone_damage_per_second * delta

func request_screen_shake(intensity: float = 5.0, duration: float = 0.3):
    if SettingsManager.screen_shake_enabled:
        emit_signal("screen_shake_requested", intensity, duration)

func get_game_time_str() -> String:
    var minutes = int(game_time) / 60
    var seconds = int(game_time) % 60
    return "%02d:%02d" % [minutes, seconds]
