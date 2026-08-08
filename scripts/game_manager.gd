extends Node

## GameManager - Quản lý trạng thái toàn cục của game (v1.0)
## Singleton autoload, điều khiển điểm số, combo, respawn, vòng bo, pickups
##
## v1.0 changes:
## - Match time limit (mặc định 5 phút = 300s)
## - Max HP scale theo size: bigger = more HP
## - Heal 10% max HP khi ăn đối thủ
## - Track score/kill cho mọi người chơi (player + AI) cho leaderboard
## - Active skills system (Dash, Shield, Multishot)
## - Game over signal với leaderboard data

signal player_score_changed(new_score: int)
signal player_size_changed(new_size: float)
signal player_hp_changed(hp: float, max_hp: float)
signal player_killed(killer_id: int, victim_id: int)
signal zone_shrank(new_radius: float)
signal game_over(winner_name: String, leaderboard: Array)
signal combo_achieved(combo_count: int)
signal screen_shake_requested(intensity: float, duration: float)
signal match_time_changed(time_remaining: float)
signal skill_used(player_id: int, skill_id: String)
# v2.2: Daily login reward signal
signal daily_reward_granted(streak: int, hp_bonus_percent: float)

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
@export var walk_speed: float = 120.0
@export var teleport_kill_radius: float = 50.0
@export var base_player_max_hp: float = 100.0
@export var hp_per_size_unit: float = 4.0  # Mỗi đơn vị size tăng thêm 4 HP max
@export var heal_percent_on_kill: float = 0.10  # Hồi 10% max HP khi ăn đối thủ
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

@export_group("Map")
@export var map_size: Vector2 = Vector2(2000, 2000)

@export_group("Trận Đấu")
@export var match_duration: float = 300.0  # 5 phút tối đa
@export var match_end_warning_time: float = 30.0  # Cảnh báo khi còn 30s

@export_group("Kỹ Năng Chủ Động")
@export var skill_dash_cooldown: float = 8.0
@export var skill_dash_distance: float = 200.0
@export var skill_dash_duration: float = 0.18
@export var skill_shield_cooldown: float = 15.0
@export var skill_shield_duration: float = 3.0
@export var skill_multishot_cooldown: float = 12.0
@export var skill_multishot_dart_count: int = 3
@export var skill_multishot_spread: float = 0.3  # radians spread

# === v3.3: VẬT LÝ GAME MỚI ===
@export_group("Vật Lý (v3.3)")
@export var dart_ricochet_enabled: bool = true  # Phi tiêu nảy khi chạm tường
@export var dart_max_ricochets: int = 1  # Số lần nảy tối đa
@export var dart_ricochet_speed_loss: float = 0.85  # Mất 15% tốc độ sau mỗi lần nảy
@export var dart_knockback_force: float = 80.0  # Lực đẩy lùi khi bị trúng phi tiêu
@export var teleport_knockback_radius: float = 120.0  # Bán kính knockback khi dịch chuyển tới
@export var teleport_knockback_force: float = 250.0  # Lực đẩy lùi AI xung quanh điểm dịch chuyển
@export var dash_invincibility_frames: float = 0.1  # Bất tử ngắn khi dash
@export var hit_slow_duration: float = 0.4  # Làm chậm 30% khi bị trúng dart
@export var hit_slow_factor: float = 0.7  # Hệ số tốc độ khi bị slow

@export_group("AI (v3.3)")
@export var num_ai_players: int = 5
@export var ai_dodge_chance: float = 0.6  # v3.3: tăng từ 0.4 → 0.6
@export var ai_accuracy: float = 0.85  # v3.3: tăng từ 0.7 → 0.85 (1.0 = perfect)
@export var ai_mid_flight_teleport_chance: float = 0.65  # v3.3: tăng từ 0.5 → 0.65
@export var ai_predict_lead_factor: float = 1.1  # Hệ số dự đoán trước mục tiêu
@export var ai_kite_distance: float = 280.0  # Khoảng cách lý tưởng để kiting
@export var ai_flee_hp_threshold: float = 0.35  # Bỏ chạy khi HP dưới 35%
@export var ai_pursuit_speed_mult: float = 1.15  # Nhanh hơn khi truy đuổi
@export var ai_pickup_seeking: bool = true  # AI chủ động nhặt pickup
@export var ai_pickup_seek_range: float = 400.0  # Phạm vi tìm pickup

## Enum skills - define ở GameManager để truy cập mọi nơi
enum Skill { DASH, SHIELD, MULTISHOT }

# === TRẠNG THÁI ===
var player_score: int = 0
var player_size: float
var player_hp: float
var player_max_hp: float  # Dynamic, scale theo size
var zone_radius: float
var zone_center: Vector2
var game_active: bool = false
var game_ended: bool = false
var players_alive: int = 0
var combo_count: int = 0
var combo_timer: float = 0.0
var current_shrink_count: int = 0
var game_time: float = 0.0
var total_kills: int = 0
var time_remaining: float = 0.0
var match_warning_played: bool = false

# === LEADERBOARD ===
# Mỗi entry: { "id": int, "name": String, "score": int, "kills": int, "is_player": bool, "alive": bool }
var leaderboard_entries: Array = []
var player_kills: int = 0

# === CALLBACK CHO RESPAWN ===
# Khi player/AI respawn, ta cần re-register leaderboard entry alive=true

func _ready():
    reset_game()

func _process(delta):
    if game_active and not game_ended:
        game_time += delta
        time_remaining = max(0.0, match_duration - game_time)
        match_time_changed.emit(time_remaining)

        # Cảnh báo 30s cuối
        if not match_warning_played and time_remaining <= match_end_warning_time and time_remaining > 0:
            match_warning_played = true
            AudioManager.play_warning()

        # Kết thúc trận khi hết giờ
        if time_remaining <= 0:
            end_match()

        if combo_count > 0:
            combo_timer -= delta
            if combo_timer <= 0:
                combo_count = 0

func reset_game():
    player_score = 0
    player_size = initial_player_radius
    # Apply character HP bonus
    var char_hp_bonus = 0.0
    if CharacterData:
        char_hp_bonus = CharacterData.get_hp_bonus(CharacterData.selected_character_id)
    base_player_max_hp = 100.0 + char_hp_bonus
    player_max_hp = compute_max_hp_for_size(player_size)
    # v2.2: Apply daily login reward HP bonus
    if SettingsManager:
        var daily = SettingsManager.check_daily_login()
        if daily.is_first_play_today and daily.reward_hp_percent > 0.0:
            var bonus_hp = int(player_max_hp * daily.reward_hp_percent)
            player_max_hp += bonus_hp
            daily_reward_granted.emit(daily.streak_count, daily.reward_hp_percent)
            print("[GameManager] Daily reward: streak=%d, +%.0f%% HP (+%d)" % [daily.streak_count, daily.reward_hp_percent * 100, bonus_hp])
    player_hp = player_max_hp
    zone_radius = map_size.x * 0.45
    zone_center = map_size / 2.0
    game_active = true
    game_ended = false
    players_alive = num_ai_players + 1
    combo_count = 0
    combo_timer = 0.0
    current_shrink_count = 0
    game_time = 0.0
    total_kills = 0
    player_kills = 0
    time_remaining = match_duration
    match_warning_played = false
    leaderboard_entries.clear()
    # Player entry
    leaderboard_entries.append({
        "id": 0, "name": "Player", "score": 0, "kills": 0,
        "is_player": true, "alive": true
    })
    player_score_changed.emit(player_score)
    player_size_changed.emit(player_size)
    player_hp_changed.emit(player_hp, player_max_hp)
    match_time_changed.emit(time_remaining)

## Tính max HP dựa trên kích thước
func compute_max_hp_for_size(size: float) -> float:
    var size_bonus = max(0.0, size - initial_player_radius) * hp_per_size_unit
    return base_player_max_hp + size_bonus

## Cập nhật max HP khi size thay đổi. Trả về hp_clamped.
func update_player_max_hp_for_size(new_size: float):
    var old_max = player_max_hp
    player_max_hp = compute_max_hp_for_size(new_size)
    # Giữ tỉ lệ HP nếu max tăng
    if player_max_hp > old_max:
        var diff = player_max_hp - old_max
        player_hp = min(player_hp + diff, player_max_hp)
    else:
        player_hp = min(player_hp, player_max_hp)
    player_hp_changed.emit(player_hp, player_max_hp)

func add_score(points: int):
    var multiplier = 1.0 + (combo_count * 0.5)
    var actual_points = int(points * multiplier)
    player_score += actual_points
    _update_leaderboard_score(0, player_score)
    player_score_changed.emit(player_score)
    return actual_points

func add_size(amount: float):
    var old_size = player_size
    player_size = min(player_size + amount, max_player_size)
    if player_size != old_size:
        update_player_max_hp_for_size(player_size)
        player_size_changed.emit(player_size)

func register_kill_by_player():
    total_kills += 1
    player_kills += 1
    combo_count += 1
    combo_timer = combo_window
    _update_leaderboard_kills(0, player_kills)
    if combo_count >= 2:
        combo_achieved.emit(combo_count)

# Legacy alias (cũ)
func register_kill():
    register_kill_by_player()

func take_damage(amount: float) -> bool:
    player_hp -= amount
    if player_hp <= 0:
        player_hp = 0
        player_hp_changed.emit(player_hp, player_max_hp)
        return true
    player_hp_changed.emit(player_hp, player_max_hp)
    return false

func heal(amount: float):
    player_hp = min(player_hp + amount, player_max_hp)
    player_hp_changed.emit(player_hp, player_max_hp)

## Hồi máu theo % max HP (khi ăn đối thủ)
func heal_percent(percent: float):
    heal(player_max_hp * percent)

func shrink_zone():
    if zone_radius > zone_min_radius:
        current_shrink_count += 1
        var actual_amount = zone_shrink_amount * pow(zone_shrink_acceleration, current_shrink_count - 1)
        zone_radius -= actual_amount
        zone_radius = max(zone_radius, zone_min_radius)
        zone_shrank.emit(zone_radius)

func is_in_zone(pos: Vector2) -> bool:
    return pos.distance_to(zone_center) <= zone_radius

func get_zone_damage(delta: float) -> float:
    return zone_damage_per_second * delta

func request_screen_shake(intensity: float = 5.0, duration: float = 0.3):
    if SettingsManager.screen_shake_enabled:
        screen_shake_requested.emit(intensity, duration)

func get_game_time_str() -> String:
    var t = int(game_time)
    var minutes = t / 60
    var seconds = t % 60
    return "%02d:%02d" % [minutes, seconds]

func get_time_remaining_str() -> String:
    var t = int(time_remaining)
    var minutes = t / 60
    var seconds = t % 60
    return "%02d:%02d" % [minutes, seconds]

# === LEADERBOARD API ===

func register_ai_leaderboard(ai_id: int, ai_name: String):
    # Tránh trùng lặp
    for entry in leaderboard_entries:
        if entry["id"] == ai_id + 1:
            entry["alive"] = true
            entry["name"] = ai_name
            return
    leaderboard_entries.append({
        "id": ai_id + 1, "name": ai_name, "score": 0, "kills": 0,
        "is_player": false, "alive": true
    })

func update_ai_score(ai_id: int, score: int):
    for entry in leaderboard_entries:
        if entry["id"] == ai_id + 1:
            entry["score"] = score
            return

func update_ai_kills(ai_id: int, kills: int):
    for entry in leaderboard_entries:
        if entry["id"] == ai_id + 1:
            entry["kills"] = kills
            return

func set_ai_alive(ai_id: int, alive: bool):
    for entry in leaderboard_entries:
        if entry["id"] == ai_id + 1:
            entry["alive"] = alive
            return

func set_player_alive(alive: bool):
    if leaderboard_entries.size() > 0:
        leaderboard_entries[0]["alive"] = alive

func _update_leaderboard_score(player_id: int, score: int):
    if player_id == 0 and leaderboard_entries.size() > 0:
        leaderboard_entries[0]["score"] = score

func _update_leaderboard_kills(player_id: int, kills: int):
    if player_id == 0 and leaderboard_entries.size() > 0:
        leaderboard_entries[0]["kills"] = kills

func get_sorted_leaderboard() -> Array:
    var sorted = leaderboard_entries.duplicate(true)
    sorted.sort_custom(func(a, b):
        if a["score"] != b["score"]:
            return a["score"] > b["score"]
        return a["kills"] > b["kills"]
    )
    return sorted

# === END MATCH ===

func end_match():
    if game_ended:
        return
    game_ended = true
    game_active = false
    var sorted = get_sorted_leaderboard()
    var winner_name = "Hòa!" if sorted.is_empty() else sorted[0]["name"]
    if not sorted.is_empty() and sorted[0]["score"] == 0:
        winner_name = "Không có người thắng!"
    # v2.2: Record match result to SettingsManager for stats/achievements
    var is_win = not sorted.is_empty() and sorted[0].get("is_player", false)
    if SettingsManager:
        SettingsManager.record_match_result(player_kills, is_win)
    game_over.emit(winner_name, sorted)
    AudioManager.play_music("victory" if (sorted.size() > 0 and sorted[0]["is_player"]) else "defeat")

func is_match_over() -> bool:
    return game_ended
