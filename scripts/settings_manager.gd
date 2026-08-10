extends Node

## SettingsManager - Quản lý cài đặt đồ họa và game (v1.2)
## Singleton autoload, lưu/đọc từ file config
## Tự phát hiện thiết bị và chọn đồ họa phù hợp

signal graphics_quality_changed(level: int)
signal sound_volume_changed(volume: float)
signal music_volume_changed(volume: float)

enum GraphicsQuality {
        VERY_LOW = 0,
        LOW = 1,
        MEDIUM = 2,
        HIGH = 3,
}

enum DeviceTier {
        LOW_END = 0,
        MID_RANGE = 1,
        HIGH_END = 2,
}

# === CÀI ĐẶT ===
var graphics_quality: int = GraphicsQuality.MEDIUM
var show_fps: bool = false
var screen_shake_enabled: bool = true
var show_joystick: bool = true
var sound_volume: float = 1.0
var music_volume: float = 0.7
var sound_enabled: bool = true
var music_enabled: bool = true
# v3.8: Toggles cho UI mới
var show_hit_markers: bool = true  # ✕ khi dart trúng đích
var show_kill_streak: bool = true  # DOUBLE/TRIPLE KILL label
var show_low_hp_vignette: bool = true  # red tint khi HP < 30%
var show_boss_offscreen_arrow: bool = true  # mũi tên chỉ boss
var show_minimap: bool = true  # minimap radar top-right

# === UI CUSTOMIZATION (v1.2) ===
var joystick_size: float = 1.0
var button_size: float = 1.0
var ui_opacity: float = 1.0
var skill_btn_layout: int = 0
var throw_btn_pos: int = 0
var teleport_btn_pos: int = 0
var hud_layout: int = 0

# === v1.3: DRAG-DROP LAYOUT ===
# Lưu vị trí tùy chỉnh của các nút UI dưới dạng Dictionary
# Key: tên nút (joystick, throw, teleport, skill_dash, skill_shield, skill_multishot)
# Value: Dictionary { "x": float, "y": float } - tọa độ chuẩn hóa 0..1 theo viewport
var custom_button_positions: Dictionary = {}
var use_custom_layout: bool = false

# === v2.4: LANGUAGE ===
# "vi" (Tiếng Việt) hoặc "en" (English)
var language: String = "vi"

# v3.4: Tên các nút có thể kéo thả (đã xóa 3 skill buttons)
const DRAGGABLE_BUTTONS: Array = [
        "joystick", "throw", "teleport",
]

# === DAILY LOGIN REWARD (v2.2) ===
# Track ngày chơi cuối + số ngày liên tiếp
var last_play_date: String = ""  # YYYY-MM-DD
var daily_streak: int = 0  # số ngày liên tiếp
# Tổng số trận đã chơi + tổng số trận thắng (cho achievements)
var total_matches: int = 0
var total_wins: int = 0
var total_kills: int = 0
# v3.8: Best kill streak (lưu lại kill streak cao nhất từng đạt)
var best_kill_streak: int = 0
# v3.8: Total stage clears + boss kills (cho stats display)
var total_stage_clears: int = 0

# === THIẾT BỊ ===
var device_tier: int = DeviceTier.MID_RANGE
var was_auto_detected: bool = false
var _device_score: float = 0.0
var pending_scene: String = ""

# === CONFIG PATH ===
var config_path: String = "user://settings.cfg"

func _ready():
        _load_settings()
        _detect_device()
        if _is_touch_device():
                show_joystick = true
        _apply_display_settings()

func _is_touch_device() -> bool:
        if OS.has_feature("mobile"):
                return true
        if OS.has_feature("android"):
                return true
        if OS.has_feature("ios"):
                return true
        if DisplayServer.is_touchscreen_available():
                return true
        var os_name = OS.get_name()
        if os_name == "Android" or os_name == "iOS":
                return true
        return false

func _apply_display_settings():
        if _is_touch_device():
                DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
        if OS.get_name() != "Web":
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

func _detect_device():
        _device_score = 0.0
        var os_name = OS.get_name()
        var is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
        
        var cpu_cores = OS.get_processor_count()
        if cpu_cores >= 8:
                _device_score += 3.0
        elif cpu_cores >= 4:
                _device_score += 2.0
        else:
                _device_score += 0.5
        
        var screen_size = Vector2(1280, 720)
        if DisplayServer.screen_get_size(0).x > 0:
                screen_size = DisplayServer.screen_get_size(0)
        var total_pixels = screen_size.x * screen_size.y
        if total_pixels > 2073600:
                _device_score += 2.0
        elif total_pixels > 921600:
                _device_score += 1.5
        else:
                _device_score += 1.0
        
        var gpu_name = RenderingServer.get_video_adapter_name().to_lower()
        if gpu_name != "":
                if _is_high_end_gpu(gpu_name):
                        _device_score += 3.0
                elif _is_mid_gpu(gpu_name):
                        _device_score += 2.0
                else:
                        _device_score += 0.5
        
        var memory_info = OS.get_memory_info()
        if memory_info.has("physical"):
                var total_ram_mb = memory_info["physical"] / (1024 * 1024)
                if total_ram_mb >= 8192:
                        _device_score += 2.0
                elif total_ram_mb >= 4096:
                        _device_score += 1.5
                else:
                        _device_score += 0.5
        
        if is_mobile:
                _device_score *= 0.7
        
        if _device_score >= 8.0:
                device_tier = DeviceTier.HIGH_END
        elif _device_score >= 4.5:
                device_tier = DeviceTier.MID_RANGE
        else:
                device_tier = DeviceTier.LOW_END
        
        var config = ConfigFile.new()
        var has_saved_quality = false
        if config.load(config_path) == OK:
                has_saved_quality = config.has_section_key("graphics", "quality")
        
        if not has_saved_quality:
                was_auto_detected = true
                match device_tier:
                        DeviceTier.LOW_END:
                                graphics_quality = GraphicsQuality.VERY_LOW
                                screen_shake_enabled = false
                        DeviceTier.MID_RANGE:
                                graphics_quality = GraphicsQuality.MEDIUM
                                screen_shake_enabled = true
                        DeviceTier.HIGH_END:
                                graphics_quality = GraphicsQuality.HIGH
                                screen_shake_enabled = true
                save_settings()
        
        if is_mobile and graphics_quality > GraphicsQuality.MEDIUM:
                graphics_quality = GraphicsQuality.MEDIUM
                save_settings()

func _is_high_end_gpu(gpu_name: String) -> bool:
        var high_end_keywords = [
                "rtx", "gtx 10", "gtx 16", "gtx 20", "gtx 30", "gtx 40",
                "radeon rx 5", "radeon rx 6", "radeon rx 7",
                "rx 5", "rx 6", "rx 7",
                "apple m1", "apple m2", "apple m3", "apple m4",
                "adreno 7", "adreno 6",
                "mali-g7", "mali-g6",
        ]
        for keyword in high_end_keywords:
                if keyword in gpu_name:
                        return true
        return false

func _is_mid_gpu(gpu_name: String) -> bool:
        var mid_keywords = [
                "gtx 9", "gtx 7", "gtx 6",
                "radeon r9", "radeon rx 4", "radeon rx 5",
                "intel uhd", "intel iris",
                "adreno 5", "adreno 4",
                "mali-g5", "mali-g4", "mali-t",
        ]
        for keyword in mid_keywords:
                if keyword in gpu_name:
                        return true
        return false

func save_settings():
        var config = ConfigFile.new()
        config.set_value("graphics", "quality", graphics_quality)
        config.set_value("graphics", "show_fps", show_fps)
        config.set_value("graphics", "screen_shake", screen_shake_enabled)
        config.set_value("gameplay", "show_joystick", show_joystick)
        config.set_value("audio", "sound_volume", sound_volume)
        config.set_value("audio", "music_volume", music_volume)
        config.set_value("audio", "sound_enabled", sound_enabled)
        config.set_value("audio", "music_enabled", music_enabled)
        config.set_value("device", "auto_detected", was_auto_detected)
        # v3.8: UI toggles
        config.set_value("ui_v38", "show_hit_markers", show_hit_markers)
        config.set_value("ui_v38", "show_kill_streak", show_kill_streak)
        config.set_value("ui_v38", "show_low_hp_vignette", show_low_hp_vignette)
        config.set_value("ui_v38", "show_boss_offscreen_arrow", show_boss_offscreen_arrow)
        config.set_value("ui_v38", "show_minimap", show_minimap)
        # v1.2: UI Customization
        config.set_value("ui_custom", "joystick_size", joystick_size)
        config.set_value("ui_custom", "button_size", button_size)
        config.set_value("ui_custom", "ui_opacity", ui_opacity)
        config.set_value("ui_custom", "skill_btn_layout", skill_btn_layout)
        config.set_value("ui_custom", "throw_btn_pos", throw_btn_pos)
        config.set_value("ui_custom", "teleport_btn_pos", teleport_btn_pos)
        config.set_value("ui_custom", "hud_layout", hud_layout)
        # v1.3: drag-drop layout
        config.set_value("ui_custom", "custom_button_positions", custom_button_positions)
        config.set_value("ui_custom", "use_custom_layout", use_custom_layout)
        # v2.2: Daily login + stats
        config.set_value("stats", "last_play_date", last_play_date)
        config.set_value("stats", "daily_streak", daily_streak)
        config.set_value("stats", "total_matches", total_matches)
        config.set_value("stats", "total_wins", total_wins)
        config.set_value("stats", "total_kills", total_kills)
        # v3.8: Best kill streak + total stage clears
        config.set_value("stats", "best_kill_streak", best_kill_streak)
        config.set_value("stats", "total_stage_clears", total_stage_clears)
        # v2.4: Language
        config.set_value("i18n", "language", language)
        config.save(config_path)

func _load_settings():
        var config = ConfigFile.new()
        if config.load(config_path) == OK:
                graphics_quality = config.get_value("graphics", "quality", GraphicsQuality.MEDIUM)
                show_fps = config.get_value("graphics", "show_fps", false)
                screen_shake_enabled = config.get_value("graphics", "screen_shake", true)
                show_joystick = config.get_value("gameplay", "show_joystick", true)
                sound_volume = config.get_value("audio", "sound_volume", 1.0)
                music_volume = config.get_value("audio", "music_volume", 0.7)
                sound_enabled = config.get_value("audio", "sound_enabled", true)
                music_enabled = config.get_value("audio", "music_enabled", true)
                was_auto_detected = config.get_value("device", "auto_detected", false)
                # v3.8: UI toggles
                show_hit_markers = config.get_value("ui_v38", "show_hit_markers", true)
                show_kill_streak = config.get_value("ui_v38", "show_kill_streak", true)
                show_low_hp_vignette = config.get_value("ui_v38", "show_low_hp_vignette", true)
                show_boss_offscreen_arrow = config.get_value("ui_v38", "show_boss_offscreen_arrow", true)
                show_minimap = config.get_value("ui_v38", "show_minimap", true)
                # v1.2: UI Customization
                joystick_size = config.get_value("ui_custom", "joystick_size", 1.0)
                button_size = config.get_value("ui_custom", "button_size", 1.0)
                ui_opacity = config.get_value("ui_custom", "ui_opacity", 1.0)
                skill_btn_layout = config.get_value("ui_custom", "skill_btn_layout", 0)
                throw_btn_pos = config.get_value("ui_custom", "throw_btn_pos", 0)
                teleport_btn_pos = config.get_value("ui_custom", "teleport_btn_pos", 0)
                hud_layout = config.get_value("ui_custom", "hud_layout", 0)
                # v1.3: drag-drop layout
                custom_button_positions = config.get_value("ui_custom", "custom_button_positions", {})
                use_custom_layout = config.get_value("ui_custom", "use_custom_layout", false)
                # v2.2: Daily login + stats
                last_play_date = config.get_value("stats", "last_play_date", "")
                daily_streak = config.get_value("stats", "daily_streak", 0)
                total_matches = config.get_value("stats", "total_matches", 0)
                total_wins = config.get_value("stats", "total_wins", 0)
                total_kills = config.get_value("stats", "total_kills", 0)
                # v3.8: Best kill streak + total stage clears
                best_kill_streak = config.get_value("stats", "best_kill_streak", 0)
                total_stage_clears = config.get_value("stats", "total_stage_clears", 0)
                # v2.4: Language
                language = config.get_value("i18n", "language", "vi")
                

## Lấy vị trí chuẩn hóa (0..1) của một nút; trả về Vector2 mặc định nếu chưa lưu
func get_button_position(button_name: String, default_pos: Vector2) -> Vector2:
        if not use_custom_layout:
                return default_pos
        if custom_button_positions.has(button_name):
                var p = custom_button_positions[button_name]
                return Vector2(p.get("x", default_pos.x), p.get("y", default_pos.y))
        return default_pos

## Lưu vị trí chuẩn hóa (0..1) của một nút
func set_button_position(button_name: String, normalized_pos: Vector2):
        custom_button_positions[button_name] = {
                "x": clamp(normalized_pos.x, 0.0, 1.0),
                "y": clamp(normalized_pos.y, 0.0, 1.0),
        }

## Xóa toàn bộ vị trí tùy chỉnh, trở về mặc định
func clear_custom_layout():
        custom_button_positions.clear()
        use_custom_layout = false
        save_settings()

## Kích hoạt layout tùy chỉnh (sau khi user bấm Lưu)
func enable_custom_layout():
        use_custom_layout = true
        save_settings()

func set_graphics_quality(level: int):
        graphics_quality = clamp(level, GraphicsQuality.VERY_LOW, GraphicsQuality.HIGH)
        was_auto_detected = false
        graphics_quality_changed.emit(graphics_quality)
        save_settings()

func set_sound_volume(volume: float):
        sound_volume = clamp(volume, 0.0, 1.0)
        sound_volume_changed.emit(sound_volume)
        save_settings()

func set_music_volume(volume: float):
        music_volume = clamp(volume, 0.0, 1.0)
        music_volume_changed.emit(music_volume)
        save_settings()

func set_sound_enabled(enabled: bool):
        sound_enabled = enabled
        save_settings()

func set_music_enabled(enabled: bool):
        music_enabled = enabled
        save_settings()

## v2.2: Check-in daily. Trả về (is_first_play_today, streak_count, reward_hp_percent)
## - is_first_play_today: true nếu là lần đầu chơi trong ngày
## - streak_count: số ngày liên tiếp đã chơi
## - reward_hp_percent: % HP bonus (capped at 30%)
func check_daily_login() -> Dictionary:
        var today = _get_today_str()
        var yesterday = _get_yesterday_str()
        var is_first = (last_play_date != today)
        if is_first:
                if last_play_date == yesterday:
                        daily_streak += 1
                else:
                        daily_streak = 1  # reset streak
                last_play_date = today
                save_settings()
        # Reward: 5% HP per streak day, max 30%
        var reward_pct = min(daily_streak * 0.05, 0.30)
        return {
                "is_first_play_today": is_first,
                "streak_count": daily_streak,
                "reward_hp_percent": reward_pct,
        }

func _get_today_str() -> String:
        var dt = Time.get_datetime_dict_from_system()
        return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

func _get_yesterday_str() -> String:
        var today_ts = Time.get_unix_time_from_system()
        var yesterday_ts = today_ts - 86400  # 1 day ago
        var dt = Time.get_datetime_dict_from_unix_time(int(yesterday_ts))
        return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

## v2.2: Record match results để track stats
func record_match_result(kills: int, won: bool):
        total_matches += 1
        total_kills += kills
        if won:
                total_wins += 1
        save_settings()

func get_particle_multiplier() -> float:
        match graphics_quality:
                GraphicsQuality.VERY_LOW: return 0.0
                GraphicsQuality.LOW: return 0.3
                GraphicsQuality.MEDIUM: return 0.7
                GraphicsQuality.HIGH: return 1.0
                _: return 0.7

func get_glow_enabled() -> bool:
        return graphics_quality >= GraphicsQuality.MEDIUM

func get_trail_enabled() -> bool:
        return graphics_quality >= GraphicsQuality.LOW

func get_predicted_line_enabled() -> bool:
        return graphics_quality >= GraphicsQuality.LOW

func get_quality_name() -> String:
        match graphics_quality:
                GraphicsQuality.VERY_LOW: return "Cực Thấp"
                GraphicsQuality.LOW: return "Thấp"
                GraphicsQuality.MEDIUM: return "Trung Bình"
                GraphicsQuality.HIGH: return "Cao"
                _: return "Trung Bình"

func get_device_tier_name() -> String:
        match device_tier:
                DeviceTier.LOW_END: return "Máy Yếu"
                DeviceTier.MID_RANGE: return "Trung Bình"
                DeviceTier.HIGH_END: return "Máy Mạnh"
                _: return "Trung Bình"
