# 🎯 Phi Tiêu Dịch Chuyển v1.5

> **Ném phi tiêu - Dịch chuyển - Nuốt đối thủ!**
>
> Game 2D top-down arena được xây dựng bằng Godot Engine 4.7

![Version](https://img.shields.io/badge/version-1.5-blue)
![Godot](https://img.shields.io/badge/Godot-4.7%20stable-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20PC%20%7C%20Web-green)
![Status](https://img.shields.io/badge/status-Stable-brightgreen)

---

## 🆕 Tính Năng v1.5

### 🔧 Rà Soát Toàn Diện Godot 4.7 — Sạch Từng Ngóc Ngách

Bản v1.4 đã fix nhiều lỗi runtime, nhưng vẫn còn sót lỗi cú pháp Python-style, lỗi logic AI, và lỗi khởi tạo biến. v1.5 rà soát **từng ký tự, từng dòng** trong 18 file GDScript để đảm bảo sạch sẽ tuyệt đối trên Godot 4.7 stable.

| Lỗi | Nguyên nhân | Cách sửa |
|-----|-------------|----------|
| Parse error `"""..."""` trong `player.gd` | Python-style docstring không hợp lệ trong GDScript 4.7 — Godot 4.2.2 vẫn chấp nhận, 4.7 thì báo lỗi | Đổi sang `## comment` chuẩn GDScript |
| `skill_cooldowns` khởi tạo sai | Khai báo `Dictionary` với enum key ở class-level → enum chưa sẵn sàng lúc parse | Chuyển khởi tạo vào `_ready()` khi enum đã load |
| `activate_skill()` dùng enum type | `GameManager.Skill` enum type trong function signature có thể gây parse issue | Đổi sang `int` type an toàn hơn |
| AI player không nhận diện group `ai_players` | Mặc dù .tscn có `groups=["ai_players"]`, nhưng code ghi đè `collision_layer/mask` mà không re-add group | Thêm `add_to_group("ai_players")` trong `_ready()` |
| AI dùng sai `GameManager.player_size` | `ai_player.gd` dùng `GameManager.player_size` (của player) thay vì `current_size` (của AI) → teleport kill radius sai | Đổi sang `current_size` |
| `_cleanup_pickups()` biến trùng tên | Biến `local_rng` trùng scope với biến ở hàm khác | Đổi tên thành `new_rng` |

### ✅ Verification (Clean trên Godot 4.7 stable)

- ✅ Project import sạch 100% (0 errors)
- ✅ Tất cả 18 file GDScript parse sạch — không còn `"""docstring"""`, không còn old 4.2 API
- ✅ Tất cả 14 scene file dùng node types 4.7 hợp lệ
- ✅ Không còn `find_node`, `yield`, `update()`, `Tween.new()`, `KinematicBody`, `Sprite`, `YSort`, `VisualServer`, `OS.get_window*`, `add_color_override`, `rect_*`, `margin_*`, `pause_mode`…
- ✅ Không còn `class_name` trùng autoload singleton
- ✅ Tất cả signal connect dùng cú pháp 4.x: `signal.connect(callable)`
- ✅ Tất cả tween dùng `create_tween()` + `tween_property/callback`
- ✅ Tất cả `monitoring`/`disabled`/`monitorable` đổi runtime dùng `set_deferred`
- ✅ AI player group được đảm bảo qua cả .tscn và `_ready()`
- ✅ `skill_cooldowns` khởi tạo đúng trong `_ready()` sau khi enum đã sẵn sàng

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
4. Vào trận và tận hưởng layout cá nhân hóa

Layout được lưu dưới dạng tọa độ chuẩn hóa (0..1) nên hoạt động đúng trên mọi độ phân giải màn hình.

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
| Chuột phải | Nhắm & ném phi tiêu |
| Space | Dịch chuyển đến phi tiêu |
| Q | Kỹ năng Dash |
| E | Kỹ năng Shield |
| Shift | Kỹ năng Multishot |
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

- **Engine**: Godot 4.7 stable
- **Ngôn ngữ**: GDScript
- **Nền tảng**: Android, iOS, PC (Windows/Linux/macOS), Web
- **Đồ họa**: Tự phát hiện thiết bị và chọn chất lượng phù hợp
- **Âm thanh**: Pool AudioStreamPlayer với 155+ sound effects
- **Lưu trữ**: ConfigFile cho settings + custom layout

## 📁 Cấu Trúc Dự Án

```
phitieudichchuyen/
├── assets/
│   ├── audio/
│   │   ├── music/          # 5 nhạc nền
│   │   └── sfx/            # 155+ sound effects
│   └── sprites/
│       └── characters/     # 12 nhân vật + AI sprites
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
├── project.godot               # Cấu hình Godot 4.7
├── export_presets.cfg          # Export Android / Windows / Linux
├── icon.svg                    # Icon game
├── LICENSE
├── README.md
└── CHANGELOG.md
```

## 📜 Lịch Sử Phiên Bản

### v1.5 (2026-08-03) — Rà Soát Toàn Diện Sạch Từng Ngóc Ngách
- **FIX SYNTAX**: `player.gd` dùng Python-style docstring `"""..."""` → parse error trên Godot 4.7. Đổi sang `## comment`.
- **FIX INIT**: `skill_cooldowns` khai báo Dictionary với enum key ở class-level → enum chưa sẵn sàng lúc parse. Chuyển khởi tạo vào `_ready()`.
- **FIX TYPE**: `activate_skill()` dùng `GameManager.Skill` enum type → đổi sang `int` an toàn hơn.
- **FIX LOGIC**: `ai_player.gd` dùng `GameManager.player_size` (của player) thay vì `current_size` (của AI) → teleport kill radius sai.
- **FIX GROUP**: AI player đảm bảo trong group `ai_players` qua cả .tscn và `add_to_group()` trong `_ready()`.
- **FIX NAMING**: `_cleanup_pickups()` đổi tên biến `local_rng` → `new_rng` tránh trùng.
- ✅ Verification: 0 parse error, 0 SCRIPT ERROR, 0 deprecated warnings trên Godot 4.7.

### v1.4 (2026-08-03) — Clean Sweep Godot 4.7
- **FIX CRITICAL**: `dart.gd` gán trực tiếp `monitoring` khi Area2D trong tree → lỗi runtime. Đổi sang `set_deferred`.
- **FIX LOGIC**: `pickup.gd` hồi máu AI theo `GameManager.player_max_hp` thay vì `ai.current_max_hp` → AI vượt max HP.
- **REFAC**: `AudioManager` thêm API `is_music_playing()` công khai; bỏ truy cập private field từ `loading_screen.gd`.
- **REFAC**: Đổi tên local `name` → `sfx_name`/`track_name` trong AudioManager (tránh shadow Node.name).

### v1.3 (2026-08-03)
- **CRITICAL**: Sửa lỗi `class_name CharacterData` xung đột autoload singleton (Godot 4.7)
- **CRITICAL**: Sửa lỗi parse ternary trong tuple của `character_screen.gd`
- **NEW**: Kéo thả 6 nút bấm (joystick, throw, teleport, 3 skill) + bấm Lưu
- **NEW**: `SettingsManager.custom_button_positions` + `use_custom_layout`
- **NEW**: Áp dụng layout tùy chỉnh trong `mobile_controls.gd` và `virtual_joystick.gd`

### v1.2 (2026-08-03)
- 12 nhân vật ninja/warrior với sprite đẹp, tách nền
- Màn hình Nhân Vật: xem chỉ số, kỹ năng, trang bị
- Màn hình Chỉnh Sửa Giao Diện: tùy chỉnh nút bấm, joystick, HUD (slider)
- Character bonus: mỗi nhân vật có HP, tốc độ, phi tiêu, kỹ năng riêng

### v1.1 (2026-08-03)
- Fix nhân vật quá to, không hiện, không dịch chuyển được
- Fix collision layers giữa player và AI
- Tăng walk_speed 80 → 120

### v1.0 (2026)
- Phi tiêu + Dịch chuyển + Ăn đối thủ
- 3 kỹ năng chủ động: Dash, Shield, Multishot
- AI đối thủ thông minh
- Vòng bo thu nhỏ
- Leaderboard cuối trận
- 155+ sound effects + 5 nhạc nền
- Tự phát hiện thiết bị

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

## 📄 Giấy Phép

Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

<p align="center">
  <b>Phi Tiêu Dịch Chuyển</b> — Ném phi tiêu, dịch chuyển, nuốt đối thủ!
</p>
