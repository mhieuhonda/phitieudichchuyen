extends Node

## I18N - Internationalization (v2.4)
## Hỗ trợ 2 ngôn ngữ: Tiếng Việt (vi) và English (en)
## Lưu language vào SettingsManager, gọi I18N.t("key") để lấy chuỗi đã dịch
## Khi user đổi language, emit signal `language_changed` để UI update

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
        "menu.guide": {
                "vi": "📖 HƯỚNG DẪN",
                "en": "📖 GUIDE",
        },
        "menu.settings": {
                "vi": "⚙ CÀI ĐẶT",
                "en": "⚙ SETTINGS",
        },
        "menu.quit": {
                "vi": "THOÁT",
                "en": "QUIT",
        },
        "menu.endless": {
                "vi": "🧟 VƯỢT ẢI",
                "en": "🧟 ENDLESS",
        },
        # === MODE SELECT ===
        "mode.title": {
                "vi": "CHƠI NGAY",
                "en": "PLAY NOW",
        },
        "mode.online": {
                "vi": "🌐 CHƠI ONLINE",
                "en": "🌐 ONLINE",
        },
        "mode.offline": {
                "vi": "🎮 CHƠI OFFLINE",
                "en": "🎮 OFFLINE",
        },
        "mode.endless": {
                "vi": "🧟 VƯỢT ẢI (500 LEVEL)",
                "en": "🧟 ENDLESS (500 LEVELS)",
        },
        "mode.back": {
                "vi": "← QUAY LẠI",
                "en": "← BACK",
        },
        "mode.retry": {
                "vi": "🔄 THỬ LẠI",
                "en": "🔄 RETRY",
        },
        "mode.checking_server": {
                "vi": "Đang kiểm tra server...",
                "en": "Checking server...",
        },
        "mode.connecting": {
                "vi": "Đang kết nối đến server...",
                "en": "Connecting to server...",
        },
        "mode.server_online": {
                "vi": "✅ Server online - Sẵn sàng chơi!",
                "en": "✅ Server online - Ready to play!",
        },
        "mode.server_offline": {
                "vi": "❌ Server offline: %s\nVui lòng kiểm tra kết nối mạng và thử lại.",
                "en": "❌ Server offline: %s\nPlease check your connection and try again.",
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
        "settings.giftcode_section": {
                "vi": "🎁 NHẬP MÃ QUÀ TẶNG",
                "en": "🎁 GIFT CODE",
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
        "settings.giftcode_desc": {
                "vi": "Nhập mã quà tặng để mở khóa nhân vật đặc biệt. (Mã bí mật - chỉ admin mới biết)",
                "en": "Enter gift code to unlock special character. (Secret code - admin only)",
        },
        "settings.giftcode_placeholder": {"vi": "Nhập mã quà tặng...", "en": "Enter gift code..."},
        "settings.redeem": {"vi": "ĐỔI MÃ", "en": "REDEEM"},
        "settings.ui_customize": {"vi": "🎨 CHỈNH SỬA GIAO DIỆN", "en": "🎨 CUSTOMIZE UI"},
        "settings.empty_code": {"vi": "⚠ Vui lòng nhập mã!", "en": "⚠ Please enter a code!"},
        "settings.code_invalid": {"vi": "❌ Mã không hợp lệ!", "en": "❌ Invalid code!"},
        "settings.code_valid": {"vi": "✅ %s", "en": "✅ %s"},
        "settings.device_info": {"vi": "Thiết bị: %s | CPU: %d core | GPU: %s | OS: %s%s", "en": "Device: %s | CPU: %d core | GPU: %s | OS: %s%s"},
        "settings.auto_detected": {"vi": "(tự động)", "en": "(auto)"},
        # === ENDLESS MODE ===
        "endless.title": {
                "vi": "🧟 VƯỢT ẢI",
                "en": "🧟 ENDLESS",
        },
        "endless.level": {"vi": "ẢI %d/500", "en": "LEVEL %d/500"},
        "endless.kills": {"vi": "Tiêu diệt: %d/%d", "en": "Kills: %d/%d"},
        "endless.hp": {"vi": "HP: %d/%d", "en": "HP: %d/%d"},
        "endless.game_over": {"vi": "💀 GAME OVER", "en": "💀 GAME OVER"},
        "endless.victory": {"vi": "🏆 HOÀN THÀNH ẢI %d!", "en": "🏆 LEVEL %d CLEARED!"},
        "endless.next_level": {"vi": "→ Sang ải %d", "en": "→ Level %d"},
        "endless.retry": {"vi": "🔄 CHƠI LẠI", "en": "🔄 RETRY"},
        "endless.menu": {"vi": "← MENU", "en": "← MENU"},
        "endless.kills_label": {"vi": "Giết: ", "en": "Kills: "},
        "endless.skills": {
                "vi": "KỸ NĂNG",
                "en": "SKILLS",
        },
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
