# 🎯 Phi Tiêu Dịch Chuyển

> Ném phi tiêu - Dịch chuyển - Nuốt đối thủ! Game 2D top-down dành cho PC và Mobile.

[![Release](https://img.shields.io/badge/release-v0.5-blue.svg)](https://github.com/mhieuhonda/phitieudichchuyen/releases)
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
- 🔍 **Auto-detect thiết bị**: Tự nhận diện máy yếu/mạnh, chọn đồ họa phù hợp
- 🎮 **4 mức đồ họa**: Cực Thấp → Thấp → Trung Bình → Cao
- 💊 **Vật phẩm**: Hồi máu và nạp phi tiêu rải trên bản đồ
- 🔥 **Hệ thống Combo**: Tiêu diệt liên tiếp để nhân điểm
- ⭕ **Vòng bo thu nhỏ**: Khu vực an toàn thu dần, ép người chơi đối đầu
- 📊 **FPS Counter**: Hiển thị FPS và thông tin thiết bị

---

## 🎮 Cách chơi

| Hành động | PC (Bàn phím/Chuột) | Mobile |
|-----------|---------------------|--------|
| Di chuyển | W/A/S/D hoặc Phím mũi tên | Joystick trái |
| Ngắm phi tiêu | Giữ chuột phải | Nút Ném |
| Ném phi tiêu | Thả chuột phải | Thả nút Ném |
| Dịch chuyển | Space | Nút Dịch chuyển |
| Khởi động lại | R | Nút trên HUD |
| Quay lại menu | Escape | Nút trên HUD |

### Cơ chế chính

- **Ném phi tiêu**: Giữ chuột phải để ngắm, kéo để điều chỉnh lực, thả để ném. Tối đa 3 phi tiêu cùng lúc.
- **Dịch chuyển**: Nhấn Space để dịch chuyển tức thời đến vị trí phi tiêu vừa ném. Phi tiêu biến mất sau khi dịch chuyển.
- **Dịch chuyển giữa chừng**: Nhấn Space khi phi tiêu đang bay để dịch chuyển đến vị trí hiện tại của phi tiêu!
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
│   └── sprites/                  # Sprite tài nguyên (PNG)
│       ├── player_blue.png       # Sprite người chơi
│       ├── ai_*.png              # Sprite AI (10 màu)
│       ├── dart.png              # Sprite phi tiêu
│       ├── pickup_health.png     # Sprite hồi máu
│       ├── pickup_dart.png       # Sprite nạp phi tiêu
│       ├── joystick_base.png     # Joystick nền
│       ├── joystick_stick.png    # Joystick cần
│       ├── btn_teleport.png      # Nút dịch chuyển
│       ├── btn_throw.png         # Nút ném
│       └── teleport_effect.png   # Hiệu ứng dịch chuyển
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
