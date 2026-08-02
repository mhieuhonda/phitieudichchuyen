extends Node

## GameManager - Quản lý trạng thái toàn cục của game
## Singleton autoload, điều khiển điểm số, respawn, và vòng bo

signal player_score_changed(new_score: int)
signal player_size_changed(new_size: float)
signal player_killed(killer_id: int, victim_id: int)
signal zone_shrank(new_radius: float)
signal game_over(winner_name: String)

# === CẤU HÌNH ===
@export var max_darts_per_player: int = 3
@export var dart_lifetime: float = 5.0
@export var dart_speed: float = 800.0
@export var max_throw_power: float = 1.0
@export var min_throw_power: float = 0.2
@export var walk_speed: float = 80.0
@export var teleport_kill_radius: float = 40.0
@export var dart_hit_damage: float = 25.0
@export var player_max_hp: float = 100.0
@export var initial_player_radius: float = 20.0
@export var size_per_kill: float = 5.0
@export var score_per_kill: int = 100
@export var respawn_time: float = 3.0
@export var zone_shrink_interval: float = 30.0
@export var zone_shrink_amount: float = 50.0
@export var zone_min_radius: float = 200.0
@export var zone_damage_per_second: float = 10.0
@export var num_ai_players: int = 5

# === TRẠNG THÁI ===
var player_score: int = 0
var player_size: float
var player_hp: float
var zone_radius: float
var zone_center: Vector2
var game_active: bool = false
var players_alive: int = 0

# Map bounds
var map_size: Vector2 = Vector2(2000, 2000)

func _ready():
	reset_game()

func reset_game():
	player_score = 0
	player_size = initial_player_radius
	player_hp = player_max_hp
	zone_radius = map_size.x * 0.45
	zone_center = map_size / 2.0
	game_active = true
	players_alive = num_ai_players + 1
	emit_signal("player_score_changed", player_score)
	emit_signal("player_size_changed", player_size)

func add_score(points: int):
	player_score += points
	emit_signal("player_score_changed", player_score)

func add_size(amount: float):
	player_size += amount
	emit_signal("player_size_changed", player_size)

func take_damage(amount: float) -> bool:
	player_hp -= amount
	if player_hp <= 0:
		player_hp = 0
		return true  # Chết
	return false

func heal(amount: float):
	player_hp = min(player_hp + amount, player_max_hp)

func shrink_zone():
	if zone_radius > zone_min_radius:
		zone_radius -= zone_shrink_amount
		zone_radius = max(zone_radius, zone_min_radius)
		emit_signal("zone_shrank", zone_radius)

func is_in_zone(pos: Vector2) -> bool:
	return pos.distance_to(zone_center) <= zone_radius

func get_zone_damage(delta: float) -> float:
	return zone_damage_per_second * delta
