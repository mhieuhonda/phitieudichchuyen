extends Node

## StageManager - Quản lý 20 ải vượt ải (v3.5)
## Singleton autoload. Lưu tiến độ vào user://progress.cfg
## - current_stage: ải đang chơi (1..20)
## - max_stage_unlocked: ải cao nhất đã mở khóa (1..20)
## - attempts_per_stage: số lần thử mỗi ải
## - best_time_per_stage: thời gian hoàn thành tốt nhất mỗi ải
##
## Cấu hình 20 ải:
##  - Ải 1-5:   1 AI, info thấp (dodge/accuracy thấp, không kiting)
##  - Ải 6-10:  2 AI, info trung bình (có kiting nhẹ, né đôi chút)
##  - Ải 11-15: 3 AI, info cao (kiting, prediction tốt, né dart)
##  - Ải 16-19: 4 AI, info rất cao (full skills: kiting, prediction, dodge, flee, pursuit)
##  - Ải 20:    BOSS CUỐI — 10M HP, laser, sweep rage ở 10% HP

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

# Boss config cho ải 20
const BOSS_MAX_HP: float = 10000000.0
const BOSS_TELEPORT_DAMAGE: float = 250000.0  # mỗi lần dịch chuyển tới boss = 250k dmg
const BOSS_DART_DAMAGE: float = 100.0          # mỗi phi tiêu trúng boss = 100 dmg (chip)
const BOSS_LASER_DAMAGE_PER_SEC: float = 100.0 # 4x player dart damage
const BOSS_LASER_CENTER_MULTIPLIER: float = 2.0  # đứng giữa laser = 2x damage
const BOSS_RAGE_HP_PERCENT: float = 0.10       # 10% HP -> rage mode
const BOSS_DAMAGE_MULTIPLIER: float = 4.0      # boss hit 4x mạnh hơn player

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
func get_ai_intelligence_for_stage(stage: int) -> Dictionary:
    # progress 0..1 theo stage (1 -> 0.0, 19 -> 1.0)
    var t: float = clamp((float(stage) - 1.0) / 18.0, 0.0, 1.0)
    return {
        "dodge_chance": lerp(0.15, 0.85, t),
        "accuracy": lerp(0.50, 0.95, t),
        "mid_flight_teleport_chance": lerp(0.20, 0.80, t),
        "predict_lead_factor": lerp(0.80, 1.30, t),
        "kite_distance": lerp(180.0, 320.0, t),
        "flee_hp_threshold": lerp(0.25, 0.40, t),
        "pursuit_speed_mult": lerp(1.05, 1.30, t),
        "pickup_seeking": stage >= 8,
        "ai_hp_mult": lerp(0.80, 1.40, t),
        "ai_dmg_mult": lerp(0.70, 1.10, t),
    }

## Số lần chết tối đa trong ải trước khi fail
func get_max_deaths_per_stage(stage: int) -> int:
    if stage == FINAL_STAGE:
        return 5  # ải boss cho phép 5 lần chết
    if stage <= 5:
        return 3
    if stage <= 10:
        return 3
    if stage <= 15:
        return 4
    return 5  # 16..19

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
