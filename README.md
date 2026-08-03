# 🎯 Phi Tiêu Dịch Chuyển

> Ném phi tiêu - Dịch chuyển - Nuốt đối thủ!

Game 2D top-down multiplayer-like được làm bằng **Godot 4.2**. Bạn ném phi tiêu, dịch chuyển tới vị trí phi tiêu, và tiêu diệt đối thủ!

![Version](https://img.shields.io/badge/version-1.1-blue)
![Godot](https://img.shields.io/badge/Godot-4.2-blue)
![Platform](https://img.shields.io/badge/platform-PC%20%7C%20Android%20%7C%20iOS-green)

---

## 🎮 Cách Chơi

1. **Di chuyển**: WASD / Joystick ảo
2. **Ném phi tiêu**: Chuột phải (PC) / Nút Bắn (Mobile) - Kéo và thả để ngắm
3. **Dịch chuyển**: Space (PC) / Nút Dịch Chuyển (Mobile) - Dịch chuyển tức thì tới phi tiêu đang bay hoặc đã cắm
4. **Ăn đối thủ**: Dịch chuyển tới vị trí có đối thủ gần phi tiêu để tiêu diệt
5. **Kỹ năng**:
   - **Q / Dash**: Lao nhanh về phía trước
   - **E / Shield**: Khiên bảo vệ 3 giây
   - **Shift / Multi**: Lần ném tiếp bắn 3 phi tiêu cùng lúc
6. **Vòng bo**: Thu nhỏ dần, ở ngoài sẽ mất máu
7. **Pickups**: Nhặt máu (+) và phi tiêu bổ sung (D)

## ✨ Tính Năng

- 🎯 Ném phi tiêu + dịch chuyển tức thì (mid-flight teleport)
- 🤖 5 AI đối thủ với hành vi thông minh (né, rượt, bắn, dash)
- 🔄 Vòng bo thu nhỏ dần (battle royale)
- ⚔️ 3 kỹ năng chủ động: Dash, Shield, Multishot
- 💊 Pickups: Hồi máu + Tăng giới hạn phi tiêu
- 🏆 Xếp hạng cuối trận (leaderboard)
- 💚 Hồi 10% max HP khi ăn đối thủ
- 📱 Mobile controls + Joystick ảo
- 🖥️ Tự động chọn đồ họa theo thiết bị
- 🎵 Âm thanh & hiệu ứng đầy đủ

## 🛠️ Cài Đặt & Chạy

### Yêu cầu
- [Godot 4.2+](https://godotengine.org/download)

### Chạy
1. Clone repo:
   ```bash
   git clone https://github.com/mhieuhonda/phitieudichchuyen.git
   ```
2. Mở project bằng Godot Editor
3. Nhấn **Play** (F5)

### Export
- **Android**: Project → Export → Add Android, cấu hình keystore và export
- **iOS**: Project → Export → Add iOS
- **Windows/Linux/Mac**: Project → Export → Add Desktop

## 📁 Cấu Trúc Project

```
phitieudichchuyen/
├── scenes/           # Godot scenes (.tscn)
│   ├── main.tscn     # Scene game chính
│   ├── menu.tscn     # Menu chính
│   ├── player.tscn   # Nhân vật người chơi
│   ├── ai_player.tscn # AI đối thủ
│   ├── dart.tscn     # Phi tiêu
│   ├── map.tscn      # Bản đồ
│   ├── hud.tscn      # Giao diện HUD
│   ├── pickup.tscn   # Vật phẩm nhặt
│   ├── mobile_controls.tscn
│   ├── settings.tscn
│   ├── loading.tscn
│   └── virtual_joystick.tscn
├── scripts/          # GDScript (.gd)
│   ├── player.gd     # Logic người chơi
│   ├── ai_player.gd  # Logic AI
│   ├── dart.gd       # Logic phi tiêu
│   ├── game_manager.gd # Singleton quản lý game
│   ├── map.gd        # Logic bản đồ + obstacles + pickups
│   ├── hud.gd        # Logic giao diện
│   ├── main.gd       # Scene chính
│   ├── mobile_controls.gd
│   ├── menu.gd
│   ├── settings_menu.gd
│   ├── audio_manager.gd
│   ├── settings_manager.gd
│   ├── pickup.gd
│   ├── virtual_joystick.gd
│   └── loading_screen.gd
├── assets/
│   ├── sprites/      # Hình ảnh PNG
│   └── audio/        # Âm thanh WAV
├── project.godot     # Cấu hình Godot
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## 🎮 Điều Khiển

| Hành động | PC | Mobile |
|-----------|-----|--------|
| Di chuyển | WASD / Arrow keys | Joystick trái |
| Ngắm & Ném | Chuột phải (kéo-thả) | Nút Bắn (kéo-thả) |
| Dịch chuyển | Space | Nút Dịch Chuyển |
| Dash | Q | Nút Dash |
| Shield | E | Nút Shield |
| Multishot | Shift | Nút Multi |
| Quay menu | Esc | Nút Back |

## 📋 Changelog

### v1.1 (2026-08-03)
- Fix nhân vật quá to / không hiện
- Fix không thể dịch chuyển sau khi bắn / khi phi tiêu đang bay
- Fix nút dịch chuyển phản hồi chậm
- Fix không thể ăn đối thủ
- Giao diện gọn gàng hơn
- Map đẹp hơn
- Tăng tốc độ di chuyển & teleport kill radius

### v1.0
- Phiên bản đầu tiên

## 📄 License

Xem file [LICENSE](LICENSE) để biết chi tiết.

---

**Phi Tiêu Dịch Chuyển** - Made with ❤️ using Godot Engine
