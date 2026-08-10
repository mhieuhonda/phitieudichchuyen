extends Node

## GameManager - Quản lý trạng thái toàn cục của game (v3.9)
## Singleton autoload, điều khiển điểm số, combo, respawn, vòng bo, pickups
##
## v3.9 changes:
## - Thêm Quest Mode: chơi ải riêng theo quest của Thế Giới (kill X / boss mini / find)
## - Áp dụng meta-progression (magic/physical/agility/class/team) vào combat stats
## - dart_hit_damage_multi cho phép scale damage theo power (player & AI)
## v3.5 changes:
## - Hỗ trợ Stage Mode (vượt ải) qua StageManager autoload
## - Stage Mode: không thu nhỏ vòng bo, không có match time limit
## - Anti kill-steal: AI không gây damage cho AI khác, chỉ cho player
## - Khi player chết: nếu còn lượt chết (theo stage) → respawn tại vị trí an toàn
## - Khi hết lượt chết → fail stage
## - Khi tất cả AI/Boss bị tiêu diệt → complete stage
## v1.0: Match time limit, max HP scale theo size, heal 10% max HP khi ăn đối thủ

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
# v3.5: Stage signals
signal stage_cleared(stage: int)
signal stage_failed_signal(stage: int)
signal ai_count_changed(alive_count: int, total_count: int)
signal boss_hp_changed(hp: float, max_hp: float, is_rage: bool)
# v3.9: Quest mode signals
signal quest_progress_changed(quest_id: String, current: int, target: int)
signal quest_objective_reached(quest_id: String)
signal quest_completed(quest_id: String)

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

# v3.5: Stage mode state
var is_stage_mode: bool = true  # default true từ v3.5 — toàn bộ game là vượt ải
var stage_total_ai: int = 0     # tổng số AI/Boss cần tiêu diệt trong ải
var stage_alive_ai: int = 0     # số AI/Boss còn sống
var stage_failed: bool = false
var stage_cleared_flag: bool = false
var stage_boss_ref: Node2D = null  # ref tới boss nếu ải 20

# v3.9: Quest Mode state — khi player nhận quest ở Tavern và vào ải để làm quest
var quest_mode: bool = false
var active_quest_id: String = ""
var active_quest_data: Dictionary = {}
var quest_type: String = ""          # "kill" | "boss_mini" | "find"
var quest_kills_target: int = 0
var quest_kills_current: int = 0
var quest_target_reached: bool = false
var quest_target_node: Node2D = null  # node mục tiêu cho quest "find"
var quest_completed_flag: bool = false
var quest_failed_flag: bool = false

# v3.9: Meta-progression combat bonuses (load từ ProgressionManager)
# Áp dụng cho player. Tính lại mỗi khi vào stage/quest.
var meta_hp_mult: float = 1.0
var meta_dmg_mult: float = 1.0
var meta_speed_mult: float = 1.0
var meta_dart_count_bonus: int = 0
var meta_tp_cooldown_mult: float = 1.0  # <1 = nhanh hơn

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
        # v3.5: Trong stage mode không dùng match time
        if not is_stage_mode:
            time_remaining = max(0.0, match_duration - game_time)
            match_time_changed.emit(time_remaining)
            # Cảnh báo 30s cuối
            if not match_warning_played and time_remaining <= match_end_warning_time and time_remaining > 0:
                match_warning_played = true
                AudioManager.play_warning()
            # Kết thúc trận khi hết giờ
            if time_remaining <= 0:
                end_match()
        else:
            # Stage mode: emit thời gian đã trôi qua (âm để HUD biết là stage mode)
            match_time_changed.emit(-1.0)

        if combo_count > 0:
            combo_timer -= delta
            if combo_timer <= 0:
                combo_count = 0

func reset_game():
    player_score = 0
    player_size = initial_player_radius
    # v3.9: Tính meta-progression bonus TRƯỚC khi apply character bonus
    _recalculate_meta_bonuses()
    # Apply character HP bonus
    var char_hp_bonus = 0.0
    if CharacterData:
        char_hp_bonus = CharacterData.get_hp_bonus(CharacterData.selected_character_id)
    base_player_max_hp = (100.0 + char_hp_bonus) * meta_hp_mult
    player_max_hp = compute_max_hp_for_size(player_size)
    # v2.2: Apply daily login reward HP bonus
    if SettingsManager:
        var daily = SettingsManager.check_daily_login()
        if daily.is_first_play_today and daily.reward_hp_percent > 0.0:
            var bonus_hp = int(player_max_hp * daily.reward_hp_percent)
            player_max_hp += bonus_hp
            daily_reward_granted.emit(daily.streak_count, daily.reward_hp_percent)
    player_hp = player_max_hp
    # v3.5: Stage mode — vòng bo = full map (không thu nhỏ)
    if is_stage_mode:
        zone_radius = map_size.x * 0.55
    else:
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
    # v3.5: Reset stage state
    stage_failed = false
    stage_cleared_flag = false
    stage_boss_ref = null
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
    # v3.5: Stage mode không thu nhỏ vòng bo
    if is_stage_mode:
        return
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

# === v3.5: STAGE MODE API ===

## Bắt đầu ải mới — reset stage state
func start_stage(stage: int):
    is_stage_mode = true
    reset_game()
    StageManager.start_stage(stage)
    stage_total_ai = StageManager.get_ai_count_for_stage(stage)
    stage_alive_ai = stage_total_ai
    if StageManager.is_final_stage():
        stage_total_ai = 1  # 1 boss
        stage_alive_ai = 1
    ai_count_changed.emit(stage_alive_ai, stage_total_ai)

## Đăng ký boss cho ải 20
func register_boss(boss: Node2D):
    stage_boss_ref = boss
    boss.boss_damaged.connect(_on_boss_damaged)
    boss.boss_died.connect(_on_boss_died)
    boss.boss_rage_started.connect(_on_boss_rage)
    # v3.8: Phase 2 signal
    if boss.has_signal("boss_phase2_started"):
        boss.boss_phase2_started.connect(_on_boss_phase2)

## v3.8: Hook cho boss phase 2 (50% HP)
func _on_boss_phase2(_boss: Node2D):
    # Tạm dùng stage_failed_signal path không — chỉ emit kill_feed message
    # qua existing signal mechanism. HUD sẽ hiển thị big_banner.
    pass

func _on_boss_damaged(_amount: float, hp: float, max_hp: float):
    var is_rage = hp <= max_hp * StageManager.BOSS_RAGE_HP_PERCENT
    boss_hp_changed.emit(hp, max_hp, is_rage)

func _on_boss_died(_boss: Node2D):
    stage_alive_ai = 0
    ai_count_changed.emit(0, stage_total_ai)
    boss_hp_changed.emit(0.0, StageManager.BOSS_MAX_HP, false)
    # v3.7: Reward HL Coin + achievement cho player
    if ProgressionManager:
        ProgressionManager.add_coins(500)
        ProgressionManager.unlock_achievement("boss_slayer")
    _complete_stage()

func _on_boss_rage(_boss: Node2D):
    # HUD tự update rage indicator qua boss_hp_changed is_rage flag
    pass

## AI bị tiêu diệt (gọi từ AIPlayer.kill)
func on_ai_killed_in_stage():
    if stage_alive_ai > 0:
        stage_alive_ai -= 1
    # v3.7: Reward HL Coin nhỏ mỗi AI kill
    if ProgressionManager:
        ProgressionManager.add_coins(15)
        ProgressionManager.unlock_achievement("first_blood")
    ai_count_changed.emit(stage_alive_ai, stage_total_ai)
    if stage_alive_ai <= 0 and not stage_cleared_flag:
        _complete_stage()

func _complete_stage():
    if stage_cleared_flag or stage_failed:
        return
    stage_cleared_flag = true
    game_active = false
    var elapsed = StageManager.get_elapsed_stage_time()
    StageManager.complete_stage(elapsed)
    # v3.7: Achievement theo ải
    if ProgressionManager:
        var stage = StageManager.current_stage
        if stage >= 5:
            ProgressionManager.unlock_achievement("stage_5_clear")
        if stage >= 10:
            ProgressionManager.unlock_achievement("stage_10_clear")
        if stage >= 15:
            ProgressionManager.unlock_achievement("stage_15_clear")
        # v3.8: All stages cleared achievement
        if StageManager.max_stage_unlocked >= StageManager.TOTAL_STAGES:
            ProgressionManager.unlock_achievement("all_stages_clear")
        # Update player level theo stage đã mở khóa
        ProgressionManager.gain_xp_and_level(0)
        # v3.8: Perfect stage bonus — không chết trong ải = bonus HL Coin
        if StageManager.player_deaths_this_stage == 0:
            var perfect_bonus = 50 + stage * 10  # ải càng cao, bonus càng lớn
            ProgressionManager.add_coins(perfect_bonus)
            _last_perfect_bonus = perfect_bonus
            # v3.8: Perfect stage achievement
            ProgressionManager.unlock_achievement("perfect_stage")
        else:
            _last_perfect_bonus = 0
        # v3.8: Speed bonus — hoàn thành dưới 60s = bonus HL Coin
        if elapsed < 60.0:
            var speed_bonus = 30 + int((60.0 - elapsed) * 1.0)
            ProgressionManager.add_coins(speed_bonus)
            _last_speed_bonus = speed_bonus
            # v3.8: Speed runner achievement
            ProgressionManager.unlock_achievement("speed_runner")
        else:
            _last_speed_bonus = 0
    # v3.8: Track total stage clears stat
    if SettingsManager:
        SettingsManager.total_stage_clears += 1
        SettingsManager.save_settings()
    stage_cleared.emit(StageManager.current_stage)
    AudioManager.play_music("victory")

# v3.8: Cache last bonus amounts để HUD hiển thị
var _last_perfect_bonus: int = 0
var _last_speed_bonus: int = 0

## v3.8: API cho HUD lấy bonus info
func get_last_stage_bonus() -> Dictionary:
    return {
        "perfect_bonus": _last_perfect_bonus,
        "speed_bonus": _last_speed_bonus,
        "is_perfect": _last_perfect_bonus > 0,
        "is_speed": _last_speed_bonus > 0,
    }

## Player chết trong stage — return true nếu respawn được, false nếu fail
func on_player_died_in_stage() -> bool:
    StageManager.register_player_death()
    var max_deaths: int
    if quest_mode:
        # v3.9: Quest mode — dùng max_deaths từ quest preset (lưu trong active_quest_data)
        max_deaths = int(active_quest_data.get("_max_player_deaths", 3))
    else:
        max_deaths = StageManager.get_max_deaths_per_stage(StageManager.current_stage)
    if StageManager.player_deaths_this_stage >= max_deaths:
        _fail_stage()
        return false
    return true  # cho phép respawn

## v3.9: Setter cho quest preset max_player_deaths (gọi từ main.gd::_setup_quest_mode)
func set_quest_max_deaths(max_deaths: int):
    active_quest_data["_max_player_deaths"] = max_deaths

func _fail_stage():
    if stage_failed or stage_cleared_flag:
        return
    stage_failed = true
    game_active = false
    StageManager.fail_stage()
    stage_failed_signal.emit(StageManager.current_stage)
    AudioManager.play_music("defeat")

## Reset stage flags (khi chơi lại ải)
func reset_stage_flags():
    stage_failed = false
    stage_cleared_flag = false
    stage_boss_ref = null
    stage_alive_ai = stage_total_ai
    # v3.9: Reset quest flags khi retry
    if quest_mode:
        quest_completed_flag = false
        quest_failed_flag = false
        quest_target_reached = false
        quest_kills_current = 0

## Cấu hình AI theo stage hiện tại
func apply_stage_ai_config():
    if not is_stage_mode or not StageManager:
        return
    var cfg = StageManager.get_ai_intelligence_for_stage(StageManager.current_stage)
    ai_dodge_chance = cfg["dodge_chance"]
    ai_accuracy = cfg["accuracy"]
    ai_mid_flight_teleport_chance = cfg["mid_flight_teleport_chance"]
    ai_predict_lead_factor = cfg["predict_lead_factor"]
    ai_kite_distance = cfg["kite_distance"]
    ai_flee_hp_threshold = cfg["flee_hp_threshold"]
    ai_pursuit_speed_mult = cfg["pursuit_speed_mult"]
    ai_pickup_seeking = cfg["pickup_seeking"]
    num_ai_players = StageManager.get_ai_count_for_stage(StageManager.current_stage)

# v3.9: Quest Mode API ======================================================

## Bắt đầu 1 quest. Đặt quest_mode = true, reset quest state, cấu hình theo type.
func start_quest(quest: Dictionary):
    quest_mode = true
    is_stage_mode = true  # quest dùng stage mode physics
    active_quest_id = quest.get("id", "")
    active_quest_data = quest
    quest_completed_flag = false
    quest_failed_flag = false
    quest_target_reached = false
    quest_target_node = null
    quest_kills_current = 0
    # Phân loại quest theo target string
    var target_str = String(quest.get("target", "")).to_lower()
    if target_str.begins_with("kill"):
        quest_type = "kill"
        # Parse số từ chuỗi "kill 5", "kill 18"...
        var parts = target_str.split(" ", false)
        if parts.size() >= 2:
            quest_kills_target = int(parts[1])
        else:
            quest_kills_target = 5
    elif target_str.find("boss") >= 0:
        quest_type = "boss_mini"
        quest_kills_target = 1
    elif target_str.find("find") >= 0:
        quest_type = "find"
        quest_kills_target = 1
    else:
        quest_type = "kill"
        quest_kills_target = 5
    quest_kills_target = max(1, quest_kills_target)

## Thoát quest mode — gọi khi quit/retry
func end_quest_mode():
    quest_mode = false
    active_quest_id = ""
    active_quest_data = {}
    quest_type = ""
    quest_kills_current = 0
    quest_kills_target = 0
    quest_target_reached = false
    quest_target_node = null
    quest_completed_flag = false
    quest_failed_flag = false

## Gọi từ main.gd khi 1 AI/mini-boss bị kill trong quest mode
func on_quest_kill():
    if not quest_mode or quest_type == "" or quest_type == "find":
        return
    quest_kills_current += 1
    quest_progress_changed.emit(active_quest_id, quest_kills_current, quest_kills_target)
    if quest_kills_current >= quest_kills_target and not quest_completed_flag:
        quest_objective_reached.emit(active_quest_id)
        _complete_quest_objective()

## Gọi từ main.gd khi player chạm quest target (find quest)
func on_quest_target_reached():
    if not quest_mode or quest_type != "find" or quest_target_reached:
        return
    quest_target_reached = true
    quest_progress_changed.emit(active_quest_id, 1, 1)
    quest_objective_reached.emit(active_quest_id)
    _complete_quest_objective()

func _complete_quest_objective():
    if quest_completed_flag:
        return
    quest_completed_flag = true
    game_active = false
    # Reward quest qua ProgressionManager
    if ProgressionManager and active_quest_id != "":
        ProgressionManager.complete_quest(active_quest_id)
    quest_completed.emit(active_quest_id)
    AudioManager.play_music("victory")

## v3.9: Tính lại meta-progression bonuses từ ProgressionManager.
## Gọi mỗi khi vào stage/quest (reset_game). Bonus = player stats + class + team.
func _recalculate_meta_bonuses():
    meta_hp_mult = 1.0
    meta_dmg_mult = 1.0
    meta_speed_mult = 1.0
    meta_dart_count_bonus = 0
    meta_tp_cooldown_mult = 1.0
    if not ProgressionManager:
        return
    # Player stats: mỗi điểm = 5% bonus cho stat tương ứng
    # Magic → +dmg (phi tiêu mạnh hơn)
    # Physical → +HP & +dmg nhỏ
    # Agility → +speed & -tp cooldown
    var m = ProgressionManager.player_magic
    var p = ProgressionManager.player_physical
    var a = ProgressionManager.player_agility
    meta_dmg_mult *= 1.0 + m * 0.05 + p * 0.025
    meta_hp_mult *= 1.0 + p * 0.05
    meta_speed_mult *= 1.0 + a * 0.04
    meta_tp_cooldown_mult *= max(0.5, 1.0 - a * 0.05)
    # Class bonus: nếu player đang là 1 loài chính, +1 dart & +10% HP
    var sid = ProgressionManager.current_class_id
    if sid >= 0:
        var sp = SpeciesData.get_species(sid)
        if sp.get("main", false):
            meta_dart_count_bonus += 1
            meta_hp_mult *= 1.10
    # Team bonus
    var tb = ProgressionManager.get_team_bonus_for_player()
    meta_hp_mult *= 1.0 + float(tb.get("hp_bonus_pct", 0.0)) / 100.0
    meta_dmg_mult *= 1.0 + float(tb.get("damage_bonus_pct", 0.0)) / 100.0
    meta_speed_mult *= 1.0 + float(tb.get("speed_bonus_pct", 0.0)) / 100.0

## v3.9: Helper cho player.gd — tính dart damage với power & meta bonus
func compute_player_dart_damage(power: float) -> float:
    return dart_hit_damage * power * meta_dmg_mult

## v3.9: Helper cho ai_player.gd — tính dart damage với power & stage dmg_mult
func compute_ai_dart_damage(power: float) -> float:
    var dmg_mult = 1.0
    if is_stage_mode and StageManager:
        var cfg = StageManager.get_ai_intelligence_for_stage(StageManager.current_stage)
        dmg_mult = float(cfg.get("ai_dmg_mult", 1.0))
    return dart_hit_damage * power * dmg_mult

## v3.9: Helper cho player — walk speed sau meta bonus
func get_player_walk_speed() -> float:
    return walk_speed * meta_speed_mult

## v3.9: Helper cho player — max darts sau meta bonus
func get_player_max_darts(base: int, char_bonus: int) -> int:
    return base + char_bonus + meta_dart_count_bonus
