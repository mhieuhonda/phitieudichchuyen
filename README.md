# 🎯 Phi Tiêu Dịch Chuyển

> Ném phi tiêu - Dịch chuyển - Nuốt đối thủ! Game 2D top-down dành cho PC và Mobile.

## 📖 Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down nơi bạn ném phi tiêu để tấn công, dịch chuyển để né tránh và tiêu diệt đối thủ. Game hỗ trợ cả điều khiển bàn phím/chuột (PC) và joystick ảo (Mobile).

## 🎮 Cách chơi

| Hành động | PC (Bàn phím/Chuột) | Mobile |
|-----------|---------------------|--------|
| Di chuyển | W/A/S/D hoặc Phím mũi tên | Joystick trái |
| Ngắm phi tiêu | Chuột phải | Nút Ngắm |
| Ném phi tiêu | Chuột phải | Nút Ném |
| Dịch chuyển | Space | Nút Dịch chuyển |
| Khởi động lại | R | Nút trên HUD |
| Quay lại menu | Escape | Nút trên HUD |

### Cơ chế chính

- **Ném phi tiêu**: Ném phi tiêu theo hướng ngắm để tấn công AI đối thủ
- **Dịch chuyển**: Nhấn dịch chuyển để dịch chuyển tức thời đến vị trí phi tiêu vừa ném
- **Nhặt vật phẩm**: Đi qua vật phẩm để nhặt thêm phi tiêu và hồi máu
- **Nuốt đối thủ**: Tiêu diệt AI bằng phi tiêu để tăng điểm

## 🖥️ Nền tảng hỗ trợ

| Nền tảng | File | Ghi chú |
|----------|------|---------|
| 🤖 Android | `.apk` | Yêu cầu Android 7.0+ (API 24) |
| 🪟 Windows | `.zip` (chứa `.exe`) | Windows 10+ |
| 🐧 Linux | `.zip` (chứa `.x86_64`) | Ubuntu 20.04+ |

## 📥 Tải xuống

Truy cập [Releases](https://github.com/mhieuhonda/phitieudichchuyen/releases) để tải phiên bản mới nhất.

## 🛠️ Công nghệ

- **Engine**: [Godot 4.2.2](https://godotengine.org/)
- **Ngôn ngữ**: GDScript
- **Đồ họa**: 2D Sprite-based
- **Nền tảng phát hành**: GitHub Actions CI/CD

## 📦 Build từ source

### Yêu cầu

- Godot 4.2.2 trở lên
- Android SDK (nếu build APK)
- Java JDK 17 (nếu build APK)

### Các bước

1. Clone repository:
   ```bash
   git clone https://github.com/mhieuhonda/phitieudichchuyen.git
   cd phitieudichchuyen
   ```

2. Mở project trong Godot Editor:
   - File → Open Project → chọn thư mục đã clone
   - Godot sẽ tự động import tài nguyên

3. Chạy game:
   - Nhấn F5 hoặc nút Play trong Editor

4. Export:
   - Project → Export → chọn nền tảng → Export

## 📂 Cấu trúc project

```
phitieudichchuyen/
├── .github/
│   └── workflows/
│       └── build-release.yml    # CI/CD pipeline
├── assets/
│   └── sprites/                 # Sprite tài nguyên
├── scenes/                      # Godot scene files
│   ├── main.tscn
│   ├── menu.tscn
│   ├── map.tscn
│   ├── player.tscn
│   ├── ai_player.tscn
│   ├── dart.tscn
│   ├── hud.tscn
│   ├── pickup.tscn
│   ├── mobile_controls.tscn
│   ├── virtual_joystick.tscn
│   └── settings.tscn
├── scripts/                     # GDScript files
│   ├── main.gd
│   ├── menu.gd
│   ├── player.gd
│   ├── ai_player.gd
│   ├── dart.gd
│   ├── hud.gd
│   ├── map.gd
│   ├── pickup.gd
│   ├── game_manager.gd
│   ├── mobile_controls.gd
│   ├── virtual_joystick.gd
│   ├── settings_menu.gd
│   └── settings_manager.gd
├── project.godot                # Godot project config
├── export_presets.cfg           # Export presets
├── icon.svg                     # App icon
├── CHANGELOG.md
└── README.md
```

## 📜 Changelog

Xem [CHANGELOG.md](CHANGELOG.md) để biết chi tiết các thay đổi theo từng phiên bản.

## 📄 License

Dự án phân phối dưới giấy phép riêng. Xem file [LICENSE](LICENSE) để biết thêm chi tiết.
