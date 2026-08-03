# 🎯 Phi Tiêu Dịch Chuyển v1.2

> **Ném phi tiêu - Dịch chuyển - Nuốt đối thủ!**
> 
> Game 2D top-down multiplayer arena được xây dựng bằng Godot Engine 4.2

![Version](https://img.shields.io/badge/version-1.2-blue)
![Godot](https://img.shields.io/badge/Godot-4.2-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20PC-green)

---

## 🎮 Cách Chơi

1. **Ném phi tiêu** (chuột phải / nút Ném) → nhắm và ném phi tiêu vào đối thủ
2. **Dịch chuyển** (Space / nút Dịch Chuyển) → dịch chuyển tức thời đến vị trí phi tiêu
3. **Ăn đối thủ** → dịch chuyển đến gần đối thủ để tiêu diệt và thu thập điểm
4. **Thu thập** → nhặt vật phẩm hồi máu và tăng phi tiêu
5. **Sinh tồn** → tránh vòng bo thu nhỏ, sống sót đến cuối trận!

## 🆕 Tính Năng v1.2

### 🥷 12 Nhân Vật Độc Đáo
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

### 🎨 Chỉnh Sửa Giao Diện
- Kích thước joystick (50% - 150%)
- Kích thước nút bấm (50% - 150%)
- Độ trong suốt UI (30% - 100%)
- Bố cục nút kỹ năng (Ngang / Dọc trái / Dọc phải)
- Vị trí nút ném và dịch chuyển
- Bố cục HUD (Trên / Dưới / Tối giản)

### 🖼️ Nhân Vật Mới
- Sprite nhân vật đẹp, tách nền trong suốt
- Màn hình xem nhân vật: chỉ số, kỹ năng, trang bị
- Mỗi nhân vật có bonus chỉ số riêng
- Mỗi nhân vật có kỹ năng đặc biệt riêng

### ✨ Hiệu Ứng & Âm Thanh
- 155+ sound effects với variation ngẫu nhiên
- 5 nhạc nền (menu, game, game_alt, victory, defeat)
- Hiệu ứng particle khi: ném phi tiêu, dịch chuyển, kill, dash, shield
- Floating text cho damage, heal, kill
- Screen shake khi kill và dịch chuyển
- Combo hiển thị với âm thanh đặc biệt

### 🐛 Bug Fixes
- ✅ Fix: không bị khóa di chuyển khi đang ném phi tiêu
- ✅ Fix: teleport kill kiểm tra shield đúng cách
- ✅ Fix: nhân vật hiển thị đúng với sprite mới
- ✅ Fix: UI gọn gàng hơn, không rối mắt
- ✅ Fix: map đẹp hơn với nhiều decoration

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

- **Engine**: Godot 4.2
- **Ngôn ngữ**: GDScript
- **Nền tảng**: Android, iOS, PC, Web
- **Đồ họa**: Tự phát hiện thiết bị và chọn chất lượng phù hợp
- **Âm thanh**: Pool AudioStreamPlayer với 155+ sound effects

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
│   ├── main.tscn           # Scene chính game
│   ├── menu.tscn           # Menu chính
│   ├── character_screen.tscn # Màn hình nhân vật
│   ├── settings.tscn       # Cài đặt
│   ├── ui_customization.tscn # Chỉnh sửa giao diện
│   ├── hud.tscn            # HUD game
│   ├── player.tscn         # Player
│   ├── ai_player.tscn      # AI
│   ├── dart.tscn            # Phi tiêu
│   └── ...                 # Scenes khác
├── scripts/
│   ├── game_manager.gd     # Singleton quản lý game
│   ├── settings_manager.gd # Singleton cài đặt
│   ├── audio_manager.gd    # Singleton âm thanh
│   ├── character_data.gd   # Singleton dữ liệu nhân vật
│   ├── player.gd           # Script player
│   ├── ai_player.gd        # Script AI
│   └── ...                 # Scripts khác
└── project.godot           # Cấu hình Godot
```

## 📜 Lịch Sử Phiên Bản

### v1.2 (2026-08-03)
- 12 nhân vật ninja/warrior với sprite đẹp, tách nền
- Màn hình Nhân Vật: xem chỉ số, kỹ năng, trang bị
- Màn hình Chỉnh Sửa Giao Diện: tùy chỉnh nút bấm, joystick, HUD
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

## 📄 Giấy Phép

Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

<p align="center">
  <b>Phi Tiêu Dịch Chuyển</b> - Ném phi tiêu, dịch chuyển, nuốt đối thủ!
</p>
