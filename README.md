# 🎯 Phi Tiêu Dịch Chuyển

> Ném phi tiêu - Dịch chuyển - Nuốt đối thủ! Game 2D top-down dành cho PC và Mobile.

[![Release](https://img.shields.io/badge/release-v0.8-blue.svg)](https://github.com/mhieuhonda/phitieudichchuyen/releases)
[![Godot](https://img.shields.io/badge/Godot-4.2.2-478CBF.svg)](https://godotengine.org/)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-green.svg)](https://github.com/mhieuhonda/phitieudichchuyen/releases)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)

---

## 📖 Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down nơi bạn ném phi tiêu để tấn công, dịch chuyển để né tránh và tiêu diệt đối thủ. Trò chơi tự động phát hiện thiết bị của bạn và chọn mức đồ họa phù hợp, đảm bảo trải nghiệm mượt mà trên mọi nền tảng.

### ✨ Tính năng nổi bật

- 🎯 **Ném phi tiêu & Dịch chuyển**: Cơ chế chiến đấu độc đáo - ném phi tiêu rồi dịch chuyển tức thời đến vị trí phi tiêu
- ⚡ **Dịch chuyển giữa chừng**: Dịch chuyển khi phi tiêu đang bay, tạo yếu tố bất ngờ
- 🤖 **AI thông minh**: 5 bot đối thủ với hành vi đa dạng (đi tuần, săn đuổi, né tránh, tấn công)
- 📱 **Hỗ trợ Mobile**: Joystick ảo + nút bấm, tự động hiện trên thiết bị di động
- 🔴 **Nút bắn phi tiêu (v0.7)**: Giữ nút → kẻ chỉ màu đỏ, kéo xoay hướng, thả để bắn
- 🖥️ **Full-screen landscape (v0.7)**: Tự động full màn hình + hướng ngang trên mọi thiết bị
- 🔊 **150+ sound effects + nhạc nền (v0.8)**: Âm thanh cho mọi action: ném, dịch chuyển, trúng đạn, tiêu diệt, hồi sinh, pickup, combo, UI, cảnh báo vòng bo, v.v. + 5 nhạc nền (menu/game/victory/defeat)
- 🔍 **Auto-detect thiết bị**: Tự nhận diện máy yếu/mạnh, chọn đồ họa phù hợp
- 🎮 **4 mức đồ họa**: Cực Thấp → Thấp → Trung Bình → Cao
- 💊 **Vật phẩm**: Hồi máu và nạp phi tiêu rải trên bản đồ
- 🔥 **Hệ thống Combo**: Tiêu diệt liên tiếp để nhân điểm
- ⭕ **Vòng bo thu nhỏ**: Khu vực an toàn thu dần, ép người chơi đối đầu
- 📊 **FPS Counter**: Hiển thị FPS và thông tin thiết bị
- 📐 **Responsive UI**: Tất cả UI dùng anchors + CanvasLayer, tự scale mọi kích thước màn hình

---

## 🎮 Cách chơi

| Hành động | PC (Bàn phím/Chuột) | Mobile (v0.8) |
|-----------|---------------------|--------|
| Di chuyển | W/A/S/D hoặc Phím mũi tên | Joystick trái |
| Ngắm phi tiêu | Giữ chuột phải, kéo để điều chỉnh lực | **Giữ nút Bắn** → kẻ chỉ màu đỏ xuất hiện |
| Xoay hướng ngắm | Kéo chuột | **Kéo ngón tay** quanh nút Bắn để xoay hướng |
| Ném phi tiêu | Thả chuột phải | **Thả nút Bắn** |
| Dịch chuyển | Space | Nút Dịch chuyển |
| Quay lại menu | Escape | Nút trên HUD |
| Tắt/bật âm thanh | Settings → Bật âm thanh | Settings → Bật âm thanh |
| Tắt/bật nhạc | Settings → Bật nhạc nền | Settings → Bật nhạc nền |

### Cơ chế chính

- **Ném phi tiêu (PC)**: Giữ chuột phải để ngắm, kéo để điều chỉnh lực và hướng (slingshot), thả để ném. Tối đa 3 phi tiêu cùng lúc.
- **Ném phi tiêu (Mobile v0.7)**: Giữ nút Bắn → kẻ chỉ màu ĐỎ xuất hiện. Kéo ngón tay quanh nút để xoay hướng. Kéo xa hơn = lực mạnh hơn. Thả nút để bắn.
- **Dịch chuyển**: Nhấn nút Dịch chuyển (Mobile) hoặc Space (PC) để dịch chuyển tức thời đến vị trí phi tiêu vừa ném.
- **Dịch chuyển giữa chừng**: Nhấn khi phi tiêu đang bay để dịch chuyển đến vị trí hiện tại của phi tiêu!
- **Nuốt đối thủ**: Dịch chuyển đến gần AI đối thủ để tiêu diệt, tăng kích thước và điểm số.
- **Vòng bo**: Khu vực an toàn thu nhỏ dần, ở ngoài sẽ mất máu.
- **Combo**: Tiêu diệt liên tiếp trong thời gian ngắn để nhân điểm (x1.5, x2.0, x2.5...).
- **Nhặt vật phẩm**: Đi qua vật phẩm để hồi máu hoặc nạp phi tiêu.

---

## 🔧 Tự phát hiện thiết bị (v0.5)

Phiên bản 0.5 tự động phát hiện khả năng thiết bị và chọn mức đồ họa phù hợp:

| Tiêu chí | Điểm | Mô tả |
|----------|------|-------|
| CPU cores | 0.5-3.0 | 8+ cores = 3 điểm, 4+ cores = 2 điểm |
| Độ phân giải | 1.0-2.0 | 1080p+ = 2 điểm, 720p+ = 1.5 điểm |
| GPU | 0.5-3.0 | RTX/RX 6000+/Apple M = 3 điểm |
| RAM | 0.5-2.0 | 8GB+ = 2 điểm, 4GB+ = 1.5 điểm |
| Mobile penalty | x0.7 | Nhân tổng điểm với 0.7 |

**Kết quả:**
- **Máy Yếu** (score < 4.5): Đồ họa Cực Thấp, tắt rung màn hình
- **Trung Bình** (score 4.5-8.0): Đồ họa Trung Bình
- **Máy Mạnh** (score 8.0+): Đồ họa Cao, tất cả hiệu ứng

> 💡 Bạn có thể thay đổi đồ họa thủ công trong menu Cài Đặt bất kỳ lúc nào.

---

## 🖥️ Nền tảng hỗ trợ

| Nền tảng | File | Yêu cầu |
|----------|------|---------|
| 🤖 Android | `.apk` | Android 7.0+ (API 24) |
| 🪟 Windows | `.zip` (chứa `.exe`) | Windows 10+ |
| 🐧 Linux | `.zip` (chứa `.x86_64`) | Ubuntu 20.04+ |

---

## 📥 Tải xuống

Truy cập [Releases](https://github.com/mhieuhonda/phitieudichchuyen/releases) để tải phiên bản mới nhất.

---

## 🛠️ Công nghệ

| Công nghệ | Chi tiết |
|-----------|----------|
| **Engine** | [Godot 4.2.2](https://godotengine.org/) |
| **Ngôn ngữ** | GDScript |
| **Đồ họa** | 2D Sprite-based |
| **Nền tảng phát hành** | GitHub Actions CI/CD |

---

## 📦 Build từ source

### Yêu cầu

- [Godot 4.2.2](https://godotengine.org/download) trở lên
- Android SDK + Java JDK 17 (nếu build APK)

### Các bước

1. **Clone repository:**
   ```bash
   git clone https://github.com/mhieuhonda/phitieudichchuyen.git
   cd phitieudichchuyen
   ```

2. **Mở project trong Godot Editor:**
   - File → Open Project → chọn thư mục đã clone
   - Godot sẽ tự động import tài nguyên

3. **Chạy game:**
   - Nhấn F5 hoặc nút Play trong Editor

4. **Export:**
   - Project → Export → chọn nền tảng → Export Project

---

## 📂 Cấu trúc project

```
phitieudichchuyen/
├── .github/
│   └── workflows/
│       └── build-release.yml     # CI/CD pipeline
├── assets/
│   ├── sprites/                  # Sprite tài nguyên (PNG)
│   │   ├── player_blue.png       # Sprite người chơi
│   │   ├── ai_*.png              # Sprite AI (10 màu)
│   │   ├── dart.png              # Sprite phi tiêu
│   │   ├── pickup_health.png     # Sprite hồi máu
│   │   ├── pickup_dart.png       # Sprite nạp phi tiêu
│   │   ├── joystick_base.png     # Joystick nền
│   │   ├── joystick_stick.png    # Joystick cần
│   │   ├── btn_teleport.png      # Nút dịch chuyển
│   │   ├── btn_throw.png         # Nút ném
│   │   └── teleport_effect.png   # Hiệu ứng dịch chuyển
│   └── audio/                    # Âm thanh (v0.8) - 155 files
│       ├── sfx/                  # 150 sound effects (WAV)
│       │   ├── throw_whoosh_*.wav       # Ném phi tiêu (5 biến thể)
│       │   ├── teleport_zap_*.wav       # Dịch chuyển (5)
│       │   ├── hit_impact_*.wav         # Trúng đạn (5)
│       │   ├── kill_explosion_*.wav     # Tiêu diệt (5)
│       │   ├── death_*.wav              # Chết (3)
│       │   ├── pickup_health_*.wav      # Nhặt máu (3)
│       │   ├── pickup_dart_*.wav        # Nhặt phi tiêu (3)
│       │   ├── ui_click_*.wav           # Click UI (5)
│       │   ├── ui_hover_*.wav           # Hover UI (3)
│       │   ├── combo_*.wav              # Combo (5)
│       │   ├── zone_warning_*.wav       # Cảnh báo vòng bo (3)
│       │   ├── dart_stick_*.wav         # Phi tiêu cắm (3)
│       │   ├── respawn_*.wav            # Hồi sinh (2)
│       │   ├── damage_*.wav             # Sát thương (3)
│       │   └── ...                      # + nhiều hơn nữa
│       └── music/                # 5 nhạc nền (WAV)
│           ├── menu_music_01.wav        # Nhạc menu
│           ├── game_music_01.wav        # Nhạc game 1
│           ├── game_music_02.wav        # Nhạc game 2
│           ├── victory_music_01.wav     # Nhạc thắng
│           └── defeat_music_01.wav      # Nhạc thua
├── scenes/                       # Godot scene files (.tscn)
│   ├── main.tscn                 # Scene chính game
│   ├── menu.tscn                 # Menu chính
│   ├── loading.tscn              # Loading screen (v0.5)
│   ├── map.tscn                  # Bản đồ
│   ├── player.tscn               # Người chơi
│   ├── ai_player.tscn            # AI đối thủ
│   ├── dart.tscn                 # Phi tiêu
│   ├── hud.tscn                  # Giao diện HUD
│   ├── pickup.tscn               # Vật phẩm
│   ├── mobile_controls.tscn      # Nút bấm mobile
│   ├── virtual_joystick.tscn     # Joystick ảo
│   └── settings.tscn             # Menu cài đặt
├── scripts/                      # GDScript files (.gd)
│   ├── main.gd                   # Scene chính logic
│   ├── menu.gd                   # Menu logic
│   ├── loading_screen.gd         # Loading screen (v0.5)
│   ├── player.gd                 # Người chơi logic
│   ├── ai_player.gd              # AI logic
│   ├── dart.gd                   # Phi tiêu logic
│   ├── hud.gd                    # HUD logic
│   ├── map.gd                    # Bản đồ logic
│   ├── pickup.gd                 # Vật phẩm logic
│   ├── game_manager.gd           # Singleton: quản lý game
│   ├── settings_manager.gd       # Singleton: cài đặt + device detect (v0.5)
│   ├── audio_manager.gd          # Singleton: âm thanh + nhạc (v0.8)
│   ├── mobile_controls.gd        # Nút bấm mobile
│   ├── virtual_joystick.gd       # Joystick ảo
│   └── settings_menu.gd          # Menu cài đặt
├── project.godot                 # Godot project config
├── export_presets.cfg            # Export presets (Android/Windows/Linux)
├── icon.svg                      # App icon
├── CHANGELOG.md                  # Lịch sử thay đổi
└── README.md                     # File này
```

---

## 🔊 Hệ thống âm thanh (v0.8)

Phiên bản 0.8 thêm **155 file âm thanh** (150 SFX + 5 nhạc nền), tất cả được generate procedurally bằng Python (wave + struct + math) với nhiều kỹ thuật synthesis:

### Kỹ thuật synthesis sử dụng
- **Sine wave + envelope**: Beep, chime, UI sounds
- **Filtered noise + sweep**: Whoosh, throw, explosion
- **Frequency sweep**: Zap, laser, teleport
- **Multiple oscillators (harmonics)**: Bell, magic, powerup
- **ADSR envelope**: Drum, percussion
- **AM/FM modulation**: Alarm, magic shimmer
- **Pitch drop**: Drum kick (150Hz → 40Hz)

### Categories (47 categories, 155 files)

| Category | Files | Mô tả |
|----------|-------|-------|
| throw_whoosh | 5 | Ném phi tiêu |
| teleport_zap | 5 | Dịch chuyển |
| hit_impact | 5 | Trúng đạn |
| kill_explosion | 5 | Tiêu diệt đối thủ |
| death | 3 | Chết |
| pickup_health | 3 | Nhặt máu |
| pickup_dart | 3 | Nhặt phi tiêu |
| ui_click | 5 | Click nút |
| ui_hover | 3 | Hover nút |
| combo | 5 | Combo (tăng dần theo combo count) |
| zone_warning | 3 | Cảnh báo ngoài vòng bo |
| zone_shrink | 2 | Vòng bo thu nhỏ |
| dart_stick | 3 | Phi tiêu cắm |
| respawn | 2 | Hồi sinh |
| damage | 3 | Bị sát thương |
| powerup | 3 | Power up |
| notification | 3 | Notification |
| whoosh | 5 | Whoosh tổng hợp |
| zap | 5 | Zap tổng hợp |
| explosion | 3 | Explosion |
| sparkle | 3 | Sparkle |
| chime | 3 | Chime |
| drum_kick/snare/hihat/crash | 8 | Trống |
| alarm | 3 | Alarm |
| heartbeat | 2 | Heartbeat |
| countdown | 3 | Countdown beep |
| success/error/warning/info | 9 | Feedback |
| spawn | 2 | Spawn |
| size_grow | 2 | Tăng kích thước |
| aim_start | 2 | Bắt đầu ngắm |
| laser/magic/coin/bass | 12 | Misc |
| click_light/heavy | 8 | Click variants |
| select/confirm/cancel | 7 | UI flow |
| achievement | 2 | Achievement |
| **Music** | 5 | menu (1) + game (2) + victory (1) + defeat (1) |

### AudioManager API

```gdscript
# Helper methods (chọn random variation tự động)
AudioManager.play_throw()          # Random throw_whoosh_01..05
AudioManager.play_teleport()       # Random teleport_zap_01..05
AudioManager.play_hit()            # Random hit_impact_01..05
AudioManager.play_kill()           # Random kill_explosion_01..05
AudioManager.play_death()          # Random death_01..03
AudioManager.play_pickup_health()  # Random pickup_health_01..03
AudioManager.play_pickup_dart()
AudioManager.play_ui_click()
AudioManager.play_ui_hover()
AudioManager.play_combo(count)     # Combo x2..x6 (chọn file theo combo)
AudioManager.play_zone_warning()
AudioManager.play_zone_shrink()
AudioManager.play_dart_stick()
AudioManager.play_respawn()
AudioManager.play_damage()
AudioManager.play_success()
AudioManager.play_error()
AudioManager.play_warning()
AudioManager.play_achievement()
AudioManager.play_size_grow()
AudioManager.play_aim_start()
AudioManager.play_spawn()

# Music
AudioManager.play_music("menu")    # Fade in menu music
AudioManager.play_music("game")    # Fade in game music
AudioManager.play_music("victory")
AudioManager.play_music("defeat")
AudioManager.stop_music()

# Low-level
AudioManager.play_sound("throw_whoosh_03", volume_db=2.0, pitch=1.05)
AudioManager.play_variation("throw")  # Random từ category
```

### Cài đặt âm thanh
- **Âm thanh SFX**: Toggle on/off + slider volume (0-100%)
- **Nhạc nền**: Toggle on/off + slider volume (0-100%)
- Lưu tự động vào `user://settings.cfg`
- Volume convert từ linear (0..1) sang dB

---

## 🐛 Lỗi đã fix trong v0.8

| # | Mô tả | Mức độ | File |
|---|-------|--------|------|
| 1 | **MobileControls/VirtualJoystick là con của Main (Node2D với Camera2D) → button.global_position ở tọa độ WORLD, nhưng touch event ở tọa độ SCREEN → hit test luôn fail khi camera di chuyển** | 🔴 Critical | `scenes/main.tscn`, `scripts/mobile_controls.gd`, `scripts/virtual_joystick.gd` |
| 2 | `_update_visibility()` chỉ gọi 1 lần trong `_ready()` → controls không update khi settings/device detection thay đổi | 🔴 Critical | `scripts/mobile_controls.gd` |
| 3 | Hit test dùng `Rect2(btn.global_position, btn.size)` manual, không accounting cho anchors/scale | 🔴 Critical | `scripts/mobile_controls.gd`, `scripts/virtual_joystick.gd` |
| 4 | `_is_touch_device()` không detect một số thiết bị Android cũ (thiếu fallback `OS.get_name()` check) | 🟡 High | `scripts/mobile_controls.gd`, `scripts/virtual_joystick.gd`, `scripts/settings_manager.gd` |
| 5 | `throw_btn.mouse_filter` mặc định (STOP) consume touch event trước khi `_input()` xử lý aim | 🟡 High | `scripts/mobile_controls.gd` |
| 6 | `mobile_controls._input()` không gọi `set_input_as_handled()` → touch leak sang joystick | 🟡 High | `scripts/mobile_controls.gd`, `scripts/virtual_joystick.gd` |
| 7 | Indentation không nhất quán (tab vs space) trong 4 file .gd | 🟢 Minor | All scripts |
| 8 | GitHub Actions import timeout quá ngắn (180s) cho 155+ audio files mới | 🟢 Minor | `.github/workflows/build-release.yml` |

---

## 🐛 Lỗi đã fix trong v0.7

| # | Mô tả | Mức độ | File |
|---|-------|--------|------|
| 1 | Game không full màn hình (window mode=2 = maximized, không phải fullscreen) | 🔴 Critical | `project.godot`, `scripts/settings_manager.gd` |
| 2 | Hướng màn hình portrait (orientation=1) thay vì landscape | 🔴 Critical | `project.godot` |
| 3 | Camera zoom=0.6 làm game trông "nhỏ" trên màn hình | 🔴 Critical | `scenes/main.tscn` |
| 4 | Mobile controls không hiện trên iOS (thiếu OS.has_feature("ios")) | 🔴 Critical | `scripts/mobile_controls.gd`, `scripts/virtual_joystick.gd` |
| 5 | Touch index không được track khi nhấn nút throw → drag không cập nhật aim | 🔴 Critical | `scripts/mobile_controls.gd` |
| 6 | **`dart.tscn` không có script attached** → dart không bay, không cắm, không gây damage | 🔴 Critical | `scenes/dart.tscn` |
| 7 | **`pickup.tscn` không có script attached** → pickup không nhặt được | 🔴 Critical | `scenes/pickup.tscn` |
| 8 | Signal `body_entered` connect 2 lần (cả trong .tscn và trong script _ready) | 🔴 Critical | `scripts/dart.gd`, `scripts/pickup.gd` |
| 9 | `CPUParticles2D.amount = 0` khi quality VERY_LOW → Godot error | 🟡 High | `scripts/dart.gd`, `scripts/player.gd`, `scripts/ai_player.gd` |
| 10 | `_get_active_touch_pos()` luôn trả về Vector2.ZERO (dead code) | 🟡 High | `scripts/mobile_controls.gd` |
| 11 | Mobile throw mechanic slingshot không trực quan - redesign thành hold-rotate-release | 🟡 High | `scripts/mobile_controls.gd`, `scripts/player.gd` |
| 12 | Aim line màu vàng thay vì màu đỏ như user yêu cầu | 🟡 High | `scenes/player.tscn`, `scripts/player.gd` |
| 13 | HUD/menu/settings dùng absolute positioning không scale trên màn hình khác | 🟡 High | `scenes/hud.tscn`, `scenes/menu.tscn`, `scenes/settings.tscn`, `scenes/loading.tscn` |
| 14 | Joystick/controls cố định pixel offset, không scale | 🟡 High | `scenes/virtual_joystick.tscn`, `scenes/mobile_controls.tscn` |
| 15 | `ai_player.take_damage_from` dùng single-line if có semicolon khó đọc | 🟢 Minor | `scripts/ai_player.gd` |
| 16 | `dart.gd._ready()` set sprite.scale trùng với .tscn (redundant) | 🟢 Minor | `scripts/dart.gd` |
| 17 | `virtual_joystick.gd` center_pos chỉ tính 1 lần ở _ready() - sai khi resize | 🟢 Minor | `scripts/virtual_joystick.gd` |
| 18 | HUD controls hint không mô tả cơ chế mobile mới | 🟢 Minor | `scripts/hud.gd` |

---

## ✨ Cải tiến v0.7

### 🖥️ Full-screen + Landscape
- `project.godot`: `window/size/mode=3` (FULLSCREEN) thay vì 2 (MAXIMIZED)
- `project.godot`: `window/handheld/orientation=4` (SENSOR_LANDSCAPE) thay vì 1 (PORTRAIT)
- `settings_manager.gd`: runtime enforce fullscreen + landscape trên mọi thiết bị

### 🔴 Nút bắn phi tiêu mới (Mobile)
- **Cơ chế mới**: Ấn giữ nút → kere chỉ màu ĐỎ xuất hiện từ player
- Kéo ngón tay quanh nút để xoay hướng bắn
- Kéo xa hơn = lực mạnh hơn (min_throw_power → max_throw_power)
- Thả nút → bắn phi tiêu theo hướng đã ngắm
- Touch index được track chính xác để drag hoạt động đúng
- Hit area mở rộng 20px để dễ chạm hơn

### 📐 Responsive UI
- Tất cả HUD elements dùng anchors (top-left, top-right, bottom-left, center, v.v.)
- Menu, settings, loading screen dùng anchor center cho mọi nút/label
- Mobile controls anchored bottom-right, joystick anchored bottom-left
- Joystick tự refresh center_pos mỗi frame để handle resize/rotation

### 📷 Camera
- Zoom 1.0 (full size) thay vì 0.6 (looking small)
- Characters và map hiện đúng kích thước trên màn hình

---

## 🐛 Lỗi đã fix trong v0.6

| # | Mô tả | Mức độ | File |
|---|-------|--------|------|
| 1 | GitHub Actions upload hardcode `tag_name: v0.4` → release mới không có artifact | 🔴 Critical | `.github/workflows/build-release.yml` |
| 2 | AI dart không kết nối signal `dart_hit_player` → không gây sát thương player | 🔴 Critical | `scripts/ai_player.gd` |
| 3 | Mobile throw emit cùng vị trí start/end → drag = 0, dart không bay | 🔴 Critical | `scripts/mobile_controls.gd`, `scripts/player.gd` |
| 4 | Tất cả `.tscn` dùng `ExtResource("res://path")` (cú pháp Godot 4 sai) | 🔴 Critical | `scenes/*.tscn` |
| 5 | `GameManager.screen_shake_requested` không kết nối tới camera | 🟡 High | `scripts/main.gd` |
| 6 | Chướng ngại vật tròn dùng `ColorRect` (vuông) | 🟡 Medium | `scripts/map.gd` |
| 7 | `DART_REFILL` pickup gọi `heal(15)` thay vì nạp phi tiêu | 🟡 Medium | `scripts/pickup.gd`, `scripts/player.gd` |
| 8 | HUD hint "R: Chơi lại" nhưng R không làm gì | 🟢 Minor | `scripts/hud.gd` |
| 9 | `AIPlayer.ai_name_index` static không reset khi restart | 🟢 Minor | `scripts/ai_player.gd`, `scripts/main.gd` |
| 10 | Unaccented Vietnamese trong `settings.tscn` (CAI DAT, Rung man hinh...) | 🟢 Minor | `scenes/settings.tscn` |
| 11 | Player death không hiện tên kẻ giết | 🟢 Minor | `scripts/player.gd`, `scripts/hud.gd` |
| 12 | `ai_player._check_teleport_kill` không clamp `current_size` | 🟢 Minor | `scripts/ai_player.gd` |

---

## ✨ Sprite rewrite trong v0.6

Tất cả sprite được vẽ lại bằng Python+PIL với chất lượng cao hơn:

| Sprite | Kích thước | Mô tả |
|--------|-----------|-------|
| `player_blue.png` | 64×64 | Ninja top-down: bóng đổ, body gradient, headband xanh, 2 mắt có catch light |
| `ai_*.png` (9 màu) | 64×64 | Cùng thiết kế, headband màu khác (đỏ/xanh lá/tím/vàng/cam/cyan/hồng/lime/teal) |
| `dart.png` | 64×64 | Dart shuriken với glow + gradient steel + center bolt |
| `pickup_health.png` | 64×64 | Medkit trắng + chữ thập đỏ + glow |
| `pickup_dart.png` | 64×64 | Shuriken 4 cánh vàng + glow |
| `btn_teleport.png` | 128×128 | Nút tròn gradient + icon sét |
| `btn_throw.png` | 128×128 | Nút tròn gradient + icon dart |
| `joystick_base.png` | 128×128 | Vòng ngoài + vòng trong + glow |
| `joystick_stick.png` | 64×64 | Knob gradient + highlight |
| `teleport_effect.png` | 64×64 | Sparkle cross + radial gradient |
| `icon.svg` | 128×128 | Ninja + dart + teleport trail |

---

## 🐛 Lỗi đã fix trong v0.5

| # | Mô tả | Mức độ | File |
|---|-------|--------|------|
| 1 | HUD không instance đúng → null crash → màn hình đen | 🔴 Critical | `main.tscn` |
| 2 | `player._die()` đặt `is_alive = true` thay vì `false` | 🔴 Critical | `player.gd` |
| 3 | AI flash damage sai (trắng→trắng) | 🟡 Medium | `ai_player.gd` |
| 4 | Pickup không phát hiện AI (collision_mask sai) | 🟡 Medium | `pickup.tscn` |
| 5 | Map.gd reference zone_fill không tồn tại | 🟢 Minor | `map.gd`, `map.tscn` |

---

## 📜 Changelog

Xem [CHANGELOG.md](CHANGELOG.md) để biết chi tiết các thay đổi theo từng phiên bản.

---

## 📄 License

Dự án phân phối dưới giấy phép riêng. Xem file [LICENSE](LICENSE) để biết thêm chi tiết.
