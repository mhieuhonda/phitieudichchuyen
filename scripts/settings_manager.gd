extends Node

## SettingsManager - Quản lý cài đặt đồ họa và game
## Singleton autoload, lưu/đọc từ file config
## Tự phát hiện thiết bị và chọn đồ họa phù hợp

signal graphics_quality_changed(level: int)

enum GraphicsQuality {
        VERY_LOW = 0,   # Tắt mọi hiệu ứng
        LOW = 1,        # Giảm particle, tắt glow
        MEDIUM = 2,     # Particle vừa, glow nhẹ
        HIGH = 3,       # Tất cả hiệu ứng
}

enum DeviceTier {
        LOW_END = 0,    # Máy yếu: điện thoại cũ, máy tính tích hợp
        MID_RANGE = 1,  # Máy trung bình: điện thoại tầm trung
        HIGH_END = 2,   # Máy mạnh: flagship, PC gaming
}

# === CÀI ĐẶT ===
var graphics_quality: int = GraphicsQuality.MEDIUM
var show_fps: bool = false
var screen_shake_enabled: bool = true
var show_joystick: bool = true  # Auto-detect mobile
var sound_volume: float = 1.0
var music_volume: float = 0.7

# === THIẾT BỊ ===
var device_tier: int = DeviceTier.MID_RANGE
var was_auto_detected: bool = false
var _device_score: float = 0.0
var pending_scene: String = ""

# === CONFIG PATH ===
var config_path: String = "user://settings.cfg"

func _ready():
        _load_settings()
        # Tự phát hiện thiết bị và chọn đồ họa
        _detect_device()
        # Auto-detect mobile (bao gồm iOS)
        if _is_touch_device():
                show_joystick = true
        # Force fullscreen + landscape trên mọi thiết bị
        _apply_display_settings()

func _is_touch_device() -> bool:
        return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()

func _apply_display_settings():
        # Force landscape orientation trên mobile
        if _is_touch_device():
                DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
        # Fullscreen trên mọi thiết bị (trừ web)
        if OS.get_name() != "Web":
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        # Đảm bảo viewport co giãn đúng
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

func _detect_device():
        """Phát hiện khả năng thiết bị và tự chọn đồ họa phù hợp"""
        _device_score = 0.0
        
        # 1. Kiểm tra nền tảng
        var os_name = OS.get_name()
        var is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
        
        # 2. Kiểm tra số core CPU
        var cpu_cores = OS.get_processor_count()
        if cpu_cores >= 8:
                _device_score += 3.0
        elif cpu_cores >= 4:
                _device_score += 2.0
        else:
                _device_score += 0.5
        
        # 3. Kiểm tra độ phân giải màn hình
        var screen_size = Vector2(1280, 720)
        if DisplayServer.screen_get_size(0).x > 0:
                screen_size = DisplayServer.screen_get_size(0)
        var total_pixels = screen_size.x * screen_size.y
        if total_pixels > 2073600:  # > 1080p
                _device_score += 2.0
        elif total_pixels > 921600:  # > 720p
                _device_score += 1.5
        else:
                _device_score += 1.0
        
        # 4. Kiểm tra GPU
        var gpu_name = RenderingServer.get_video_adapter_name().to_lower()
        if gpu_name != "":
                # GPU mạnh
                if _is_high_end_gpu(gpu_name):
                        _device_score += 3.0
                elif _is_mid_gpu(gpu_name):
                        _device_score += 2.0
                else:
                        _device_score += 0.5
        
        # 5. Kiểm tra RAM (ước tính qua available memory)
        var memory_info = OS.get_memory_info()
        if memory_info.has("physical"):
                var total_ram_mb = memory_info["physical"] / (1024 * 1024)
                if total_ram_mb >= 8192:
                        _device_score += 2.0
                elif total_ram_mb >= 4096:
                        _device_score += 1.5
                else:
                        _device_score += 0.5
        
        # 6. Mobile thường yếu hơn
        if is_mobile:
                _device_score *= 0.7
        
        # 7. Chọn tier thiết bị
        if _device_score >= 8.0:
                device_tier = DeviceTier.HIGH_END
        elif _device_score >= 4.5:
                device_tier = DeviceTier.MID_RANGE
        else:
                device_tier = DeviceTier.LOW_END
        
        # 8. Tự chọn đồ họa dựa trên tier (chỉ nếu chưa có cài đặt lưu)
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
                print("[DeviceDetector] Tự động chọn đồ họa: %s (score: %.1f)" % [get_quality_name(), _device_score])
        else:
                print("[DeviceDetector] Đã có cài đặt lưu: %s (score: %.1f)" % [get_quality_name(), _device_score])
        
        # Mobile: giới hạn chất lượng
        if is_mobile and graphics_quality > GraphicsQuality.MEDIUM:
                graphics_quality = GraphicsQuality.MEDIUM
                save_settings()

func _is_high_end_gpu(gpu_name: String) -> bool:
        """Kiểm tra GPU mạnh"""
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
        """Kiểm tra GPU trung bình"""
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
        config.set_value("device", "auto_detected", was_auto_detected)
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
                was_auto_detected = config.get_value("device", "auto_detected", false)

func set_graphics_quality(level: int):
        graphics_quality = clamp(level, GraphicsQuality.VERY_LOW, GraphicsQuality.HIGH)
        was_auto_detected = false
        emit_signal("graphics_quality_changed", graphics_quality)
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
