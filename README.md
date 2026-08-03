# 🎯 Phi Tiêu Dịch Chuyển v1.3

> **Ném phi tiêu - Dịch chuyển - Nuốt đối thủ!**
>
> Game 2D top-down multiplayer arena được xây dựng bằng Godot Engine 4.7

![Version](https://img.shields.io/badge/version-1.3-blue)
![Godot](https://img.shields.io/badge/Godot-4.7-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20PC-green)

---

## 🆕 Tính Năng v1.3

### 🔧 Sửa Toàn Bộ Lỗi Tương Thích Godot 4.7
Bản v1.2 không thể chạy trên Godot 4.7 do các thay đổi API nghiêm ngặt. v1.3 khắc phục:

| Lỗi | Nguyên nhân | Cách sửa |
|-----|-------------|----------|
| Khi vào trận không hiện gì, không hiện nhân vật, di chuyển không phản hồi, góc chỉ số không đổi | `class_name CharacterData` trong `character_data.gd` xung đột với autoload cùng tên → GameManager autoload không khởi tạo được | Bỏ `class_name`, dùng autoload singleton |
| Khi vào màn hình nhân vật bị lag ngay | `character_screen.gd` parse error khiến script nạp lại mỗi frame | Sửa cú pháp ternary trong tuple `% (...)` → chuyển sang `% [...]` |
| Không thể trang bị nhân vật | Script `character_screen.gd` không load được → `equip_btn.pressed.connect()` không chạy | Như trên |
| Không thể quay lại | Script không load → `back_btn.pressed.connect()` không chạy | Như trên |
| Không hiện danh sách nhân vật | `_populate_char_list()` không chạy được | Như trên |

### 🖱️ Kéo Thả Nút Bấm Tùy Chỉnh (NEW)
Người chơi giờ có thể **kéo thả** bất kỳ nút nào đến vị trí mong muốn và **lưu lại** để dùng trong trận:

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

### 🐛 Bug Fixes Khác
- ✅ Fix: `class_name CharacterData` conflicts with autoload singleton (Godot 4.7 strict check)
- ✅ Fix: ternary expression inside `% (tuple)` no longer parses — switched to `% [array]`
- ✅ Fix: project feature flag cập nhật từ `4.2` → `4.7`
- ✅ Fix: tất cả scene giờ import sạch trên Godot 4.7 stable

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

### Kéo Thả (v1.3 - MỚI)
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

- **Engine**: Godot 4.7 (stable)
- **Ngôn ngữ**: GDScript
- **Nền tảng**: Android, iOS, PC, Web
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
│   ├── hud.tscn                # HUD game
│   ├── player.tscn             # Player
│   ├── ai_player.tscn          # AI
│   ├── dart.tscn               # Phi tiêu
│   └── ...                     # Scenes khác
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
│   └── ...                     # Scripts khác
└── project.godot               # Cấu hình Godot 4.7
```

## 📜 Lịch Sử Phiên Bản

### v1.3 (2026-08-03)
- **CRITICAL**: Sửa lỗi `class_name CharacterData` xung đột autoload singleton (Godot 4.7)
- **CRITICAL**: Sửa lỗi parse ternary trong tuple của `character_screen.gd`
- **NEW**: Kéo thả 6 nút bấm (joystick, throw, teleport, 3 skill) + bấm Lưu
- **NEW**: `SettingsManager.custom_button_positions` + `use_custom_layout`
- **NEW**: Áp dụng layout tùy chỉnh trong `mobile_controls.gd` và `virtual_joystick.gd`
- Fix: project feature flag `4.2` → `4.7`
- Fix: tất cả scene import sạch sẽ trên Godot 4.7 stable

### v1.2 (2026-08-03)
- 12 nhân vật ninja/warrior với sprite đẹp, tách nền
- Màn hình Nhân Vật: xem chỉ số, kỹ năng, trang bị
- Màn hình Chỉnh Sửa Giao Diện: tùy chỉnh nút bấm, joystick, HUD (slider)
- Character bonus: mỗi nhân vật có HP, tốc độ, phi tiêu, kỹ năng riêng
- Fix: không bị khóa di chuyển khi ném phi tiêu
- Fix: teleport kill kiểm tra shield đúng cách
- Map đẹp hơn với nhiều decoration
- UI gọn gàng hơn

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
2. Project → Export → Add platform
3. Bấm Export Project

## 📄 Giấy Phép

Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

<p align="center">
  <b>Phi Tiêu Dịch Chuyển</b> - Ném phi tiêu, dịch chuyển, nuốt đối thủ!
</p>
