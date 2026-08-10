extends Node

## I18N - Internationalization (v3.0)
## Hỗ trợ 2 ngôn ngữ: Tiếng Việt (vi) và English (en)
## Lưu language vào SettingsManager, gọi I18N.t("key") để lấy chuỗi đã dịch
## Khi user đổi language, emit signal `language_changed` để UI update
##
## v3.0: Đã xóa các key liên quan đến Endless mode, Gift Code, Guide
##        (các tính năng này đã bị gỡ khỏi game).

signal language_changed(new_lang: String)

const LANG_VI := "vi"
const LANG_EN := "en"
const DEFAULT_LANG := "vi"

# Map key -> { lang -> text }
const TRANSLATIONS := {
        # === MENU ===
        "menu.title": {
                "vi": "PHI TIÊU DỊCH CHUYỂN",
                "en": "TELEPORT DARTS",
        },
        "menu.subtitle": {
                "vi": "✦ Ném phi tiêu • Dịch chuyển • Nuốt đối thủ ✦",
                "en": "✦ Throw darts • Teleport • Consume enemies ✦",
        },
        "menu.play": {
                "vi": "⚔ CHƠI NGAY",
                "en": "⚔ PLAY NOW",
        },
        "menu.characters": {
                "vi": "🥷 NHÂN VẬT",
                "en": "🥷 CHARACTERS",
        },
        "menu.settings": {
                "vi": "⚙ CÀI ĐẶT",
                "en": "⚙ SETTINGS",
        },
        "menu.quit": {
                "vi": "THOÁT",
                "en": "QUIT",
        },
        # === SETTINGS ===
        "settings.title": {
                "vi": "⚙ CÀI ĐẶT",
                "en": "⚙ SETTINGS",
        },
        "settings.back": {
                "vi": "← QUAY LẠI",
                "en": "← BACK",
        },
        "settings.graphics_section": {
                "vi": "🎨 ĐỒ HỌA",
                "en": "🎨 GRAPHICS",
        },
        "settings.audio_section": {
                "vi": "🔊 ÂM THANH",
                "en": "🔊 AUDIO",
        },
        "settings.language_section": {
                "vi": "🌐 NGÔN NGỮ",
                "en": "🌐 LANGUAGE",
        },
        "settings.ui_section": {
                "vi": "🎛 GIAO DIỆN",
                "en": "🎛 INTERFACE",
        },
        "settings.quality_label": {
                "vi": "Chất lượng đồ họa: %s",
                "en": "Graphics quality: %s",
        },
        "settings.quality_very_low": {"vi": "Cực Thấp", "en": "Very Low"},
        "settings.quality_low": {"vi": "Thấp", "en": "Low"},
        "settings.quality_medium": {"vi": "Trung Bình", "en": "Medium"},
        "settings.quality_high": {"vi": "Cao", "en": "High"},
        "settings.show_fps": {"vi": "Hiện FPS", "en": "Show FPS"},
        "settings.screen_shake": {"vi": "Rung màn hình", "en": "Screen shake"},
        "settings.show_joystick": {"vi": "Hiện Joystick", "en": "Show Joystick"},
        "settings.sound": {"vi": "Âm thanh", "en": "Sound"},
        "settings.music": {"vi": "Nhạc nền", "en": "Music"},
        "settings.sound_volume": {"vi": "Âm thanh: %d%%", "en": "Sound: %d%%"},
        "settings.music_volume": {"vi": "Nhạc: %d%%", "en": "Music: %d%%"},
        "settings.lang_vi": {"vi": "🇻🇳 Tiếng Việt", "en": "🇻🇳 Vietnamese"},
        "settings.lang_en": {"vi": "🇬🇧 English", "en": "🇬🇧 English"},
        "settings.ui_customize": {"vi": "🎨 CHỈNH SỬA GIAO DIỆN", "en": "🎨 CUSTOMIZE UI"},
        "settings.device_info": {"vi": "Thiết bị: %s | CPU: %d core | GPU: %s | OS: %s%s", "en": "Device: %s | CPU: %d core | GPU: %s | OS: %s%s"},
        "settings.auto_detected": {"vi": "(tự động)", "en": "(auto)"},
        # v3.4: UI sliders labels
        "settings.joystick_size": {"vi": "Kích thước joystick: %d%%", "en": "Joystick size: %d%%"},
        "settings.button_size": {"vi": "Kích thước nút: %d%%", "en": "Button size: %d%%"},
        "settings.ui_opacity": {"vi": "Độ trong suốt UI: %d%%", "en": "UI opacity: %d%%"},
        # === PAUSE MENU (v2.8) ===
        "pause.title": {"vi": "⏸ TẠM DỪNG", "en": "⏸ PAUSED"},
        "pause.resume": {"vi": "▶ TIẾP TỤC", "en": "▶ RESUME"},
        "pause.settings": {"vi": "⚙ CÀI ĐẶT", "en": "⚙ SETTINGS"},
        "pause.menu": {"vi": "← MENU", "en": "← MENU"},
        # === DEATH RECAP (v2.8) ===
        "death_recap.killed_by": {"vi": "Bị %s tiêu diệt", "en": "Killed by %s"},
        "death_recap.killed_unknown": {"vi": "Bị tiêu diệt", "en": "Eliminated"},
        "death_recap.damage_taken": {"vi": "Damage nhận: %d", "en": "Damage taken: %d"},
        "death_recap.survival_time": {"vi": "Sống sót: %s", "en": "Survived: %s"},
        "death_recap.kills": {"vi": "Giết: %d", "en": "Kills: %d"},
}

var _current_lang: String = DEFAULT_LANG

func _ready():
        if SettingsManager:
                _current_lang = SettingsManager.language
                if _current_lang == "":
                        _current_lang = DEFAULT_LANG

## Lấy chuỗi đã dịch. Hỗ trợ format args: I18N.t("key", [arg1, arg2])
func t(key: String, args: Array = []) -> String:
        var entry = TRANSLATIONS.get(key, {})
        var text = entry.get(_current_lang, entry.get(DEFAULT_LANG, key))
        if args.size() > 0:
                text = text % args
        return text

## Lấy ngôn ngữ hiện tại
func get_language() -> String:
        return _current_lang

## Đặt ngôn ngữ, lưu vào SettingsManager, emit signal
func set_language(lang: String):
        if lang != LANG_VI and lang != LANG_EN:
                push_warning("[I18N] Unsupported language: %s" % lang)
                return
        if lang == _current_lang:
                return
        _current_lang = lang
        if SettingsManager:
                SettingsManager.language = lang
                SettingsManager.save_settings()
        language_changed.emit(lang)

## Toggle giữa VI và EN
func toggle_language():
        set_language(LANG_EN if _current_lang == LANG_VI else LANG_VI)

func is_vi() -> bool:
        return _current_lang == LANG_VI

func is_en() -> bool:
        return _current_lang == LANG_EN
