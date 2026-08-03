# 🎯 Phi Tiêu Dịch Chuyển v1.6

> **Ném phi tiêu - Dịch chuyển - Nuốt đối thủ!**
>
> Game 2D top-down arena được xây dựng bằng Godot Engine 4.7

![Version](https://img.shields.io/badge/version-1.6-blue)
![Godot](https://img.shields.io/badge/Godot-4.7%20stable-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20PC%20%7C%20Web-green)
![Status](https://img.shields.io/badge/status-Stable-brightgreen)

---

## 🆕 Tính Năng v1.6

### 🧹 Dọn Dẹp Code Toàn Diện — Modern GDScript Idioms

Bản v1.5 đã fix hết lỗi parse và lỗi runtime. v1.6 rà soát lại toàn bộ codebase để **modern hoá mọi cú pháp GDScript** theo chuẩn Godot 4.7, đồng thời đồng bộ các giá trị collision mask giữa `.tscn` và `.gd` để tránh inconsistent state.

| Hạng mục | Trước v1.6 | v1.6 |
|----------|-----------|------|
| Signal emit | `emit_signal("name", args)` (legacy 4.x) | `name.emit(args)` (modern 4.7) |
| AI collision_mask trong `.tscn` | `28` (sai — không phát hiện Player) | `21` (đúng — matches `.gd`) |
| Dead input actions | `aim`, `throw_dart` defined nhưng không bao giờ đọc | Đã xoá |
| Debug print | `print()` chạy mỗi khi khởi động | Chỉ in khi `OS.is_debug_build()` |
| AudioManager cleanup | Không có `_exit_tree` → leak warning | Có `_exit_tree` kill tween + stop streams |
| Comment stray | "click通常 works" (Japanese leak) | "click bình thường works" |

### ✅ Verification (Clean trên Godot 4.7 stable)

- ✅ Project import sạch 100% (0 parse errors, 0 deprecated warnings)
- ✅ Headless run 30 frames: 0 SCRIPT ERROR, 0 push_error, 0 push_warning
- ✅ Tất cả 18 file GDScript dùng modern signal syntax: `signal.emit(args)`
- ✅ Tất cả 14 scene file dùng node types 4.7 hợp lệ
- ✅ `scenes/ai_player.tscn` collision_mask sync với `scripts/ai_player.gd` (cùng giá trị 21)
- ✅ Không còn `emit_signal("string", ...)` ở bất kỳ file nào
- ✅ Không còn dead input actions trong `project.godot`
- ✅ AudioManager có `_exit_tree()` dọn dẹp pool + music player + fade tween
- ✅ Tất cả signal connect dùng `signal.connect(callable)`
- ✅ Tất cả tween dùng `create_tween()` + `tween_property/callback`
- ✅ Tất cả `monitoring`/`disabled` đổi runtime dùng `set_deferred`

### 🖱️ Kéo Thả Nút Bấm Tùy Chỉnh (từ v1.3)
Người chơi có thể **kéo thả** bất kỳ nút nào đến vị trí mong muốn và **lưu lại** để dùng trong trận:

- Joystick ảo
- Nút Ném phi tiêu
- Nút Dịch chuyển
- Nút Dash / Shield / Multishot

**Cách dùng:**
1. Menu chính → Cài đặt → 🎨 Chỉnh Sửa Giao Diện
2. Kéo các nút trong "Khu vực kéo thả" đến vị trí mong muốn
3. Bấm **"💾 LƯU VỊ TRÍ NÚT"** để lưu
4. Vào trận và tận hưởng layout cá nhân hoá

Layout được lưu dưới dạng tọa độ chuẩn hoá (0..1) nên hoạt động đúng trên mọi độ phân giải màn hình.

## 🎮 Cách Chơi

1. **Ném phi tiêu** (chuột phải / nút Ném) → nhắm và ném phi tiêu vào đối thủ
2. **Dịch chuyển** (Space / nút Dịch Chuyển) → dịch chuyển tức thời đến vị trí phi tiêu
3. **Ăn đối thủ** → dịch chuyển đến gần đối thủ để tiêu diệt và thu thập điểm
4. **Thu thập** → nhặt vật phẩm hồi máu và tăng phi tiêu
5. **Sinh tồn** → tránh vòng bo thu nhỏ, sống sót đến cuối trận!

## 🥷 12 Nhân Vật Độc Đáo

| # | Tên | Loại | Đặc điểm | Kỹ năng riêng |
|---|------|------|-----------|---------------|
| 1 | Rồng Đỏ | Chiến Binh | +15 HP | Dash mạnh hơn 20% |
| 2 | Phượng Xanh | Pháp Sư | +1 Phi tiêu | Multishot bắn 4 phi tiêu |
| 3 | Hổ Vàng | Quyền Sư | +25 HP | Shield lâu hơn 50% |
| 4 | Báo Lục | Sát Thủ | +20 Tốc độ | Dash cooldown giảm 30% |
| 5 | Sói Tím | Chiến Binh | +10 HP, +5 Tốc độ | Dash để lại vệt tối |
| 6 | Cáo Hồng | Pháp Sư | +1 Phi tiêu, +15 Tốc độ | Phi tiêu homing nhẹ |
| 7 | Gấu Nâu | Quyền Sư | +30 HP | Shield phản damage 20% |
| 8 | Diều Cam | Sát Thủ | +15 Tốc độ | Dash xuyên đối thủ |
| 9 | Cọp Xanh | Chiến Binh | +10 HP, +10 Tốc độ | Dash tạo sóng nước |
| 10 | Chồn Bạc | Sát Thủ | +25 Tốc độ | Dash 2 lần liên tiếp |
| 11 | Thiên Long | Pháp Sư | +2 Phi tiêu | Multishot bắn 5 phi tiêu |
| 12 | Hắc Vũ | Sát Thủ | +30 Tốc độ | Dash vô hình 1s |

## 🎨 Chỉnh Sửa Giao Diện

### Slider (v1.2)
- Kích thước joystick (50% - 150%)
- Kích thước nút bấm (50% - 150%)
- Độ trong suốt UI (30% - 100%)

### Kéo Thả (v1.3+)
- 6 nút có thể kéo thả tự do trong "Khu vực kéo thả"
- Bấm **Lưu vị trí** để áp dụng vào game
- Bấm **Đặt vị trí về mặc định** để khôi phục
- Layout được lưu trong `user://settings.cfg`

## 🕹️ Điều Khiển

### PC
| Phím | Hành động |
|------|-----------|
| WASD / ←↑↓→ | Di chuyển |
| Chuột phải | Nhắm & ném phi tiêu (slingshot) |
| Space | Dịch chuyển đến phi tiêu |
| Q | Kỹ năng Dash |
| E | Kỹ năng Shield |
| Shift | Kỹ năng Multishot |
| R | Restart trận |
| ESC | Quay lại menu |

### Mobile
- Joystick ảo (trái): Di chuyển
- Nút Ném (phải): Nhắm & ném phi tiêu
- Nút Dịch Chuyển: Dịch chuyển đến phi tiêu
- Nút Dash / Shield / Multishot: Kỹ năng

## 🛠️ Kỹ Năng

| Kỹ năng | Phím | Cooldown | Mô tả |
|---------|------|----------|-------|
| Dash | Q | 8s | Lao về phía trước với tốc độ cao |
| Shield | E | 15s | Miễn damage trong 3 giây |
| Multishot | Shift | 12s | Lần ném tiếp theo bắn 3 phi tiêu cùng lúc |

## 🏗️ Công Nghệ

- **Engine**: Godot 4.7 stable (official build `5b4e0cb0f`)
- **Ngôn ngữ**: GDScript (modern 4.7 idioms — `signal.emit()`, `create_tween()`, `set_deferred()`)
- **Nền tảng**: Android, iOS, PC (Windows/Linux/macOS), Web
- **Đồ họa**: Tự phát hiện thiết bị và chọn chất lượng phù hợp
- **Âm thanh**: Pool AudioStreamPlayer với 155+ sound effects + 5 nhạc nền
- **Lưu trữ**: ConfigFile cho settings + custom layout + character unlock data
- **Physics**: 6 collision layers (Player, Dart, Wall, AI, Obstacle, Pickup)

## 📁 Cấu Trúc Dự Án

```
phitieudichchuyen/
├── assets/
│   ├── audio/
│   │   ├── music/          # 5 nhạc nền
│   │   └── sfx/            # 155+ sound effects
│   └── sprites/
│       └── characters/     # 12 nhân vật + 10 AI sprites
├── scenes/
│   ├── main.tscn              # Scene chính game
│   ├── menu.tscn              # Menu chính
│   ├── character_screen.tscn  # Màn hình nhân vật
│   ├── settings.tscn          # Cài đặt
│   ├── ui_customization.tscn  # Chỉnh sửa giao diện + kéo thả
│   ├── hud.tscn               # HUD game
│   ├── player.tscn            # Player
│   ├── ai_player.tscn         # AI
│   ├── dart.tscn              # Phi tiêu
│   └── ...                    # Scenes khác
├── scripts/
│   ├── game_manager.gd         # Singleton quản lý game
│   ├── settings_manager.gd     # Singleton cài đặt + custom layout
│   ├── audio_manager.gd        # Singleton âm thanh
│   ├── character_data.gd       # Singleton dữ liệu nhân vật
│   ├── ui_customization.gd     # Logic kéo thả UI
│   ├── mobile_controls.gd      # Áp dụng layout vào mobile controls
│   ├── virtual_joystick.gd     # Áp dụng layout vào joystick
│   ├── player.gd               # Script player
│   ├── ai_player.gd            # Script AI
│   ├── dart.gd                 # Script phi tiêu
│   ├── pickup.gd               # Script vật phẩm
│   ├── map.gd                  # Script bản đồ
│   ├── hud.gd                  # Script HUD
│   ├── main.gd                 # Script scene chính
│   ├── menu.gd                 # Script menu
│   ├── loading_screen.gd       # Script màn hình tải
│   ├── settings_menu.gd        # Script menu cài đặt
│   └── character_screen.gd     # Script màn hình nhân vật
├── project.godot               # Cấu hình Godot 4.7 (config_version=5)
├── export_presets.cfg          # Export Android / Windows / Linux
├── icon.svg                    # Icon game
├── LICENSE
├── README.md
└── CHANGELOG.md
```

## 📜 Lịch Sử Phiên Bản

### v1.6 (2026-08-03) — Modern GDScript Cleanup
- **MODERN**: Convert toàn bộ 45+ `emit_signal("name", args)` → `name.emit(args)` trên 8 file (modern Godot 4.7 idiom).
- **FIX**: `scenes/ai_player.tscn` `collision_mask = 28` → `21` để sync với `scripts/ai_player.gd:90` (Player+Wall+Obstacle).
- **FIX**: Xoá 2 dead input actions `aim` và `throw_dart` khỏi `project.godot` (không script nào reference).
- **FIX**: `audio_manager.gd` debug `print()` giờ chỉ chạy khi `OS.is_debug_build()`.
- **FIX**: Comment stray "click通常 works" → "click bình thường works" trong `mobile_controls.gd`.
- **NEW**: `AudioManager._exit_tree()` để kill fade tween + stop streams + null resource refs khi quit.
- Bump `config/version` 1.5 → 1.6, `version/code` 15 → 16, file_version 1.5.0.0 → 1.6.0.0.

### v1.5 (2026-08-03) — Rà Soát Toàn Diện Sạch Từng Ngóc Ngách
- Fix Python-style docstring `"""..."""` parse error trong `player.gd`.
- Fix `skill_cooldowns` Dictionary khởi tạo ở class-level khi enum chưa sẵn sàng.
- Fix `activate_skill()` enum type signature → `int`.
- Fix AI teleport kill radius dùng sai `GameManager.player_size`.
- Đảm bảo AI luôn trong group `ai_players` qua cả `.tscn` và `_ready()`.

### v1.4 (2026-08-03) — Clean Sweep Godot 4.7
- Fix `dart.gd` gán trực tiếp `monitoring` khi Area2D trong tree → `set_deferred`.
- Fix `pickup.gd` hồi máu AI theo `GameManager.player_max_hp` thay vì `ai.current_max_hp`.
- Refactor `AudioManager` thêm API `is_music_playing()` công khai.
- Rename local `name` → `sfx_name`/`track_name` tránh shadow `Node.name`.

### v1.3 (2026-08-03)
- Fix critical `class_name CharacterData` xung đột autoload singleton (Godot 4.7).
- Fix parse error ternary-in-tuple trong `character_screen.gd`.
- NEW: Kéo thả 6 nút bấm (joystick, throw, teleport, 3 skill) + bấm Lưu.
- NEW: `SettingsManager.custom_button_positions` + `use_custom_layout`.

### v1.2 (2026-08-03)
- 12 nhân vật ninja/warrior với sprite đẹp, tách nền.
- Màn hình Nhân Vật + Màn hình Chỉnh Sửa Giao Diện (slider).
- Character bonus: mỗi nhân vật có HP, tốc độ, phi tiêu, kỹ năng riêng.

### v1.1 (2026-08-03)
- Fix nhân vật quá to, không hiện, không dịch chuyển được.
- Fix collision layers giữa player và AI.
- Tăng walk_speed 80 → 120.

### v1.0 (2026)
- Phi tiêu + Dịch chuyển + Ăn đối thủ.
- 3 kỹ năng chủ động: Dash, Shield, Multishot.
- AI đối thủ thông minh + Vòng bo thu nhỏ + Leaderboard cuối trận.
- 155+ sound effects + 5 nhạc nền.
- Tự phát hiện thiết bị.

## 🚀 Cài Đặt & Chạy

### Yêu cầu
- Godot 4.7 stable (hoặc mới hơn)
- Nền tảng: Windows / macOS / Linux / Android / iOS

### Chạy từ source
```bash
git clone https://github.com/mhieuhonda/phitieudichchuyen.git
cd phitieudichchuyen
# Mở project.godot bằng Godot 4.7
# F5 để chạy game
```

### Export
1. Mở project trong Godot 4.7
2. Project → Export → Add platform (đã có sẵn preset Android, Windows, Linux)
3. Bấm Export Project

> **Lưu ý Android**: Preset dùng `gradle_build/use_gradle_build=true`, `min_sdk=24`, `target_sdk=33`. Cài Android Studio + export template trước khi export.

> **Lưu ý iOS**: Tạo preset mới (chưa có sẵn) — Godot 4.7 support iOS export.

## 📄 Giấy Phép

Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

<p align="center">
  <b>Phi Tiêu Dịch Chuyển</b> — Ném phi tiêu, dịch chuyển, nuốt đối thủ!
</p>
