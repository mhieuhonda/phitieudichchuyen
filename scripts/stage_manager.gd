extends Node

## StageManager - Quản lý 20 ải vượt ải (v3.9)
## Singleton autoload. Lưu tiến độ vào user://progress.cfg
## - current_stage: ải đang chơi (1..20)
## - max_stage_unlocked: ải cao nhất đã mở khóa (1..20)
## - attempts_per_stage: số lần thử mỗi ải
## - best_time_per_stage: thời gian hoàn thành tốt nhất mỗi ải
##
## v3.9: Thêm get_quest_difficulty() cho Quest Mode — preset theo loài yêu cầu.
##       Cân bằng lại đường cong AI dmg_mult (0.80→1.30) để ải cuối cảm thấy nguy hiểm.
## Cấu hình 20 ải:
##  - Ải 1-5:   1 AI, info thấp (dodge/accuracy thấp, không kiting)
##  - Ải 6-10:  2 AI, info trung bình (có kiting nhẹ, né đôi chút)
##  - Ải 11-15: 3 AI, info cao (kiting, prediction tốt, né dart)
##  - Ải 16-19: 4 AI, info rất cao (full skills: kiting, prediction, dodge, flee, pursuit)
##  - Ải 20:    BOSS CUỐI — 12M HP, laser, sweep rage ở 12% HP

signal stage_started(stage: int)
signal stage_completed(stage: int, time_seconds: float)
signal stage_failed(stage: int)
signal progress_loaded()

const TOTAL_STAGES: int = 20
const FINAL_STAGE: int = 20
const PROGRESS_PATH: String = "user://progress.cfg"

# === SAVE STATE ===
var current_stage: int = 1
var max_stage_unlocked: int = 1
var attempts_per_stage: Dictionary = {}  # stage -> int
var best_time_per_stage: Dictionary = {}  # stage -> float (seconds), -1.0 = chưa hoàn thành
var total_deaths: int = 0
var total_boss_kills: int = 0

# === STAGE SESSION (không lưu) ===
var stage_start_time: float = 0.0
var stage_active: bool = false
var player_deaths_this_stage: int = 0

# Boss config cho ải 20 (v3.7: rebalance — sát thương < 4x player dart)
# Player dart damage = 25 → 4x = 100. Boss dmg phải < 100.
const BOSS_MAX_HP: float = 12000000.0       # v3.7: 12M (tăng từ 10M) vì laser đã fix sát thương
const BOSS_TELEPORT_DAMAGE: float = 280000.0  # mỗi lần dịch chuyển tới boss = 280k dmg
const BOSS_DART_DAMAGE: float = 80.0          # < 4x player dart (4x = 100)
const BOSS_LASER_DAMAGE_PER_SEC: float = 80.0 # < 4x player dart, nhưng LIÊN TỤC mỗi frame
const BOSS_LASER_CENTER_MULTIPLIER: float = 2.0  # đứng giữa laser = 2x damage (= 160/s, vẫn < 4x = 100*4=400/s, vì player dart 25)
const BOSS_RAGE_HP_PERCENT: float = 0.12      # 12% HP -> rage mode (tăng nhẹ)
const BOSS_DAMAGE_MULTIPLIER: float = 3.2      # v3.7: < 4x player (trước đây 4.0)

func _ready():
    _load_progress()
    progress_loaded.emit()

# === PUBLIC API ===

## Bắt đầu một ải mới
func start_stage(stage: int):
    current_stage = clamp(stage, 1, TOTAL_STAGES)
    stage_start_time = Time.get_ticks_msec() / 1000.0
    stage_active = true
    player_deaths_this_stage = 0
    if not attempts_per_stage.has(current_stage):
        attempts_per_stage[current_stage] = 0
    attempts_per_stage[current_stage] += 1
    _save_progress()
    stage_started.emit(current_stage)

## Hoàn thành ải — lưu best time, mở khóa ải tiếp theo
func complete_stage(time_seconds: float):
    if not stage_active:
        return
    stage_active = false
    var prev_best = best_time_per_stage.get(current_stage, -1.0)
    if prev_best < 0.0 or time_seconds < prev_best:
        best_time_per_stage[current_stage] = time_seconds
    if current_stage == FINAL_STAGE:
        total_boss_kills += 1
    # Mở khóa ải tiếp theo
    if current_stage < TOTAL_STAGES and max_stage_unlocked < current_stage + 1:
        max_stage_unlocked = current_stage + 1
    _save_progress()
    stage_completed.emit(current_stage, time_seconds)

## Thất bại ải
func fail_stage():
    if not stage_active:
        return
    stage_active = false
    total_deaths += 1
    _save_progress()
    stage_failed.emit(current_stage)

## Player chết trong ải — tăng counter, không kết thúc ải ngay
func register_player_death():
    player_deaths_this_stage += 1

## Kiểm tra ải đã mở khóa chưa
func is_stage_unlocked(stage: int) -> bool:
    return stage >= 1 and stage <= max_stage_unlocked

## Reset toàn bộ tiến độ (New Game)
func reset_progress():
    current_stage = 1
    max_stage_unlocked = 1
    attempts_per_stage.clear()
    best_time_per_stage.clear()
    total_deaths = 0
    total_boss_kills = 0
    stage_active = false
    player_deaths_this_stage = 0
    _save_progress()

## Lấy thời gian đã trôi qua trong ải hiện tại
func get_elapsed_stage_time() -> float:
    if not stage_active:
        return 0.0
    return Time.get_ticks_msec() / 1000.0 - stage_start_time

## Có phải ải cuối (boss) không
func is_final_stage() -> bool:
    return current_stage == FINAL_STAGE

# === STAGE CONFIG ===

## Số lượng AI cho mỗi ải (ải 20 = 0 vì chỉ có boss)
func get_ai_count_for_stage(stage: int) -> int:
    if stage == FINAL_STAGE:
        return 0
    if stage <= 5:
        return 1
    if stage <= 10:
        return 2
    if stage <= 15:
        return 3
    return 4  # 16..19

## Thông số AI theo ải (dodge, accuracy, kiting, prediction...)
## v3.9: Tinh chỉnh lại — dmg_mult nâng lên 0.80→1.30 (trước 1.25) để ải cuối nguy hiểm hơn.
##       HP mult giảm nhẹ ở ải giữa để tránh sponginess, tăng nhẹ ở ải cuối.
func get_ai_intelligence_for_stage(stage: int) -> Dictionary:
    # progress 0..1 theo stage (1 -> 0.0, 19 -> 1.0)
    # v3.7: dùng curve mũ nhẹ để ải đầu khó hơn + ải cuối khó hơn nữa
    var t: float = clamp((float(stage) - 1.0) / 18.0, 0.0, 1.0)
    var t_curved: float = t * t * 0.6 + t * 0.4  # ease-in: ải giữa khó hơn
    return {
        "dodge_chance": lerp(0.25, 0.92, t_curved),       # v3.7: 0.15→0.85 thành 0.25→0.92
        "accuracy": lerp(0.60, 0.97, t_curved),           # v3.7: 0.50→0.95 thành 0.60→0.97
        "mid_flight_teleport_chance": lerp(0.30, 0.85, t_curved),  # v3.7: tăng từ 0.20→0.80
        "predict_lead_factor": lerp(0.85, 1.40, t_curved),
        "kite_distance": lerp(200.0, 340.0, t_curved),
        "flee_hp_threshold": lerp(0.25, 0.45, t_curved),
        "pursuit_speed_mult": lerp(1.10, 1.40, t_curved), # v3.7: tăng pursuit
        "pickup_seeking": stage >= 6,                     # v3.7: AI nhặt pickup từ ải 6 (trước 8)
        "ai_hp_mult": lerp(0.85, 1.60, t_curved),         # v3.9: 0.90→1.55 thành 0.85→1.60
        "ai_dmg_mult": lerp(0.80, 1.30, t_curved),        # v3.9: 0.80→1.25 thành 0.80→1.30
    }

## v3.9: Quest difficulty preset — cấu hình AI cho quest scene theo quest type
## Trả về Dictionary với các key:
##   ai_count, hp_mult, dmg_mult, dodge_chance, accuracy, kite_distance, pursuit_speed_mult, mini_boss
func get_quest_difficulty(quest: Dictionary) -> Dictionary:
    var target_str = String(quest.get("target", "")).to_lower()
    var qid = String(quest.get("id", ""))
    # Parse số kill
    var num_kills = 5
    if target_str.begins_with("kill"):
        var parts = target_str.split(" ", false)
        if parts.size() >= 2:
            num_kills = int(parts[1])
    # Quest có yêu cầu team ≥3 → khó hơn
    var req_team = int(quest.get("require_min_team", 1))
    var difficulty_tier = 0  # 0=easy, 1=medium, 2=hard, 3=very_hard
    if target_str.find("boss") >= 0:
        difficulty_tier = 2  # mini-boss fight
    elif num_kills >= 15:
        difficulty_tier = 3  # very hard
    elif num_kills >= 10:
        difficulty_tier = 2
    elif num_kills >= 6:
        difficulty_tier = 1
    else:
        difficulty_tier = 0
    # Tier-based stats
    var presets = [
        # easy: 1-5 kills, 2-3 AI spawn, low HP/dodge
        {"ai_count": 2, "hp_mult": 0.95, "dmg_mult": 0.90, "dodge_chance": 0.30,
         "accuracy": 0.65, "kite_distance": 220.0, "pursuit_speed_mult": 1.15,
         "mini_boss": false, "spawn_interval": 4.0},
        # medium: 6-9 kills, 3 AI spawn, mid stats
        {"ai_count": 3, "hp_mult": 1.10, "dmg_mult": 1.00, "dodge_chance": 0.45,
         "accuracy": 0.75, "kite_distance": 260.0, "pursuit_speed_mult": 1.20,
         "mini_boss": false, "spawn_interval": 3.5},
        # hard: 10-14 kills or mini-boss, 4 AI spawn, high stats
        {"ai_count": 4, "hp_mult": 1.25, "dmg_mult": 1.10, "dodge_chance": 0.60,
         "accuracy": 0.85, "kite_distance": 290.0, "pursuit_speed_mult": 1.30,
         "mini_boss": (target_str.find("boss") >= 0), "spawn_interval": 3.0},
        # very hard: 15+ kills, 4 AI + mini-boss, top stats
        {"ai_count": 4, "hp_mult": 1.45, "dmg_mult": 1.20, "dodge_chance": 0.75,
         "accuracy": 0.92, "kite_distance": 320.0, "pursuit_speed_mult": 1.40,
         "mini_boss": (target_str.find("boss") >= 0), "spawn_interval": 2.5},
    ]
    var preset = presets[difficulty_tier]
    # Reward scales với difficulty — bonus HL Coin + reputation
    var reward_bonus = [0, 25, 60, 120][difficulty_tier]
    preset["reward_bonus"] = reward_bonus
    preset["max_player_deaths"] = 3 if difficulty_tier >= 2 else 2
    preset["spawn_count"] = num_kills
    preset["is_find_quest"] = (target_str.find("find") >= 0)
    return preset

## Số lần chết tối đa trong ải trước khi fail (v3.7: giảm để tăng độ khó)
func get_max_deaths_per_stage(stage: int) -> int:
    if stage == FINAL_STAGE:
        return 4  # v3.7: ải boss 4 lần chết (trước 5)
    if stage <= 5:
        return 2  # v3.7: 2 (trước 3)
    if stage <= 10:
        return 2  # v3.7: 2 (trước 3)
    if stage <= 15:
        return 3  # v3.7: 3 (trước 4)
    return 4  # 16..19 (trước 5)

# === SAVE / LOAD ===

func _save_progress():
    var config = ConfigFile.new()
    config.set_value("progress", "current_stage", current_stage)
    config.set_value("progress", "max_stage_unlocked", max_stage_unlocked)
    config.set_value("progress", "attempts_per_stage", attempts_per_stage)
    config.set_value("progress", "best_time_per_stage", best_time_per_stage)
    config.set_value("progress", "total_deaths", total_deaths)
    config.set_value("progress", "total_boss_kills", total_boss_kills)
    var err = config.save(PROGRESS_PATH)
    if err != OK:
        push_warning("[StageManager] Failed to save progress: %d" % err)

func _load_progress():
    var config = ConfigFile.new()
    if config.load(PROGRESS_PATH) == OK:
        current_stage = config.get_value("progress", "current_stage", 1)
        max_stage_unlocked = config.get_value("progress", "max_stage_unlocked", 1)
        attempts_per_stage = config.get_value("progress", "attempts_per_stage", {})
        best_time_per_stage = config.get_value("progress", "best_time_per_stage", {})
        total_deaths = config.get_value("progress", "total_deaths", 0)
        total_boss_kills = config.get_value("progress", "total_boss_kills", 0)
        # Sanitize
        current_stage = clamp(current_stage, 1, TOTAL_STAGES)
        max_stage_unlocked = clamp(max_stage_unlocked, 1, TOTAL_STAGES)
    else:
        # First run
        current_stage = 1
        max_stage_unlocked = 1
        _save_progress()

## Format thời gian mm:ss
func format_time(seconds: float) -> String:
    var m = int(seconds) / 60
    var s = int(seconds) % 60
    return "%02d:%02d" % [m, s]
