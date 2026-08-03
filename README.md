# 🎯 Phi Tiêu Dịch Chuyển

> Ném phi tiêu - Dịch chuyển - Nuốt đối thủ! Game 2D top-down dành cho PC và Mobile.

[![Release](https://img.shields.io/badge/release-v0.9-blue.svg)](https://github.com/mhieuhonda/phitieudichchuyen/releases)
[![Godot](https://img.shields.io/badge/Godot-4.2.2-478CBF.svg)](https://godotengine.org/)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-green.svg)](https://github.com/mhieuhonda/phitieudichchuyen/releases)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

---

## 📖 Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down nơi bạn ném phi tiêu để tấn công, dịch chuyển tức thời đến vị trí phi tiêu để né tránh hoặc tiêu diệt đối thủ. Trò chơi tự động phát hiện thiết bị và chọn mức đồ họa phù hợp, đảm bảo trải nghiệm mượt mà trên mọi nền tảng.

### ✨ Tính năng nổi bật

- 🎯 **Ném phi tiêu & Dịch chuyển**: Cơ chế chiến đấu độc đáo - ném phi tiêu rồi dịch chuyển tức thời đến vị trí phi tiêu
- ⚡ **Dịch chuyển giữa chừng**: Dịch chuyển khi phi tiêu đang bay, tạo yếu tố bất ngờ
- 🤖 **AI thông minh**: 5 bot đối thủ với hành vi đa dạng (đi tuần, săn đuổi, né tránh, tấn công)
- 📱 **Hỗ trợ Mobile**: Joystick ảo + nút bấm, tự động hiện trên thiết bị di động
- 👆 **Multi-touch (v0.9)**: Giữ joystick di chuyển + nhấn nút bắn + nhấn nút dịch chuyển CÙNG LÚC - không bao giờ bị dừng giữa chừng
- 🔴 **Nút bắn phi tiêu**: Giữ nút → kẻ chỉ màu đỏ, kéo xoay hướng, thả để bắn
- 🖥️ **Full-screen landscape**: Tự động full màn hình + hướng ngang trên mọi thiết bị
- 🔊 **150+ sound effects + nhạc nền**: Âm thanh cho mọi action + 5 nhạc nền (menu/game/victory/defeat)
- 🔍 **Auto-detect thiết bị**: Tự nhận diện máy yếu/mạnh, chọn đồ họa phù hợp
- 🎮 **4 mức đồ họa**: Cực Thấp → Thấp → Trung Bình → Cao
- 💊 **Vật phẩm**: Hồi máu và nạp phi tiêu rải trên bản đồ
- 🔥 **Hệ thống Combo**: Tiêu diệt liên tiếp để nhân điểm
- ⭕ **Vòng bo thu nhỏ**: Khu vực an toàn thu dần, ép người chơi đối đầu
- 📊 **FPS Counter**: Hiển thị FPS và thông tin thiết bị
- 📐 **Responsive UI**: Tất cả UI dùng anchors + CanvasLayer, tự scale mọi kích thước màn hình

---

## 🎮 Cách chơi

| Hành động | PC (Bàn phím/Chuột) | Mobile (v0.9) |
|-----------|---------------------|----------------|
| Di chuyển | W/A/S/D hoặc Phím mũi tên | **Joystick bên trái** (200×200px, hỗ trợ multi-touch) |
| Ngắm phi tiêu | Giữ chuột phải, kéo để điều chỉnh lực | **Giữ nút Bắn** → kẻ chỉ màu đỏ xuất hiện |
| Xoay hướng ngắm | Kéo chuột | **Kéo ngón tay** quanh nút Bắn để xoay hướng |
| Ném phi tiêu | Thả chuột phải | **Thả nút Bắn** |
| Dịch chuyển | Space | **Nút Dịch chuyển** (140×140px, responsive) |
| Quay lại menu | Escape | Nút trên HUD |
| Đa chạm (multi-touch) | N/A | ✅ Giữ joystick + bắn + dịch chuyển cùng lúc |

### Cơ chế chính

- **Ném phi tiêu (PC)**: Giữ chuột phải để ngắm, kéo để điều chỉnh lực và hướng (slingshot), thả để ném. Tối đa 3 phi tiêu cùng lúc.
- **Ném phi tiêu (Mobile)**: Giữ nút Bắn → kẻ chỉ màu ĐỎ xuất hiện từ nhân vật. Kéo ngón tay quanh nút để xoay hướng. Kéo xa hơn = lực mạnh hơn. Thả nút để bắn.
- **Dịch chuyển**: Nhấn nút Dịch chuyển (Mobile) hoặc Space (PC) để dịch chuyển tức thời đến vị trí phi tiêu vừa ném.
- **Dịch chuyển giữa chừng**: Nhấn khi phi tiêu đang bay để dịch chuyển đến vị trí hiện tại của phi tiêu!
- **Nuốt đối thủ**: Dịch chuyển đến gần AI đối thủ để tiêu diệt, tăng kích thước và điểm số.
- **Vòng bo**: Khu vực an toàn thu nhỏ dần, ở ngoài sẽ mất máu.
- **Combo**: Tiêu diệt liên tiếp trong thời gian ngắn để nhân điểm (x1.5, x2.0, x2.5...).
- **Nhặt vật phẩm**: Đi qua vật phẩm để hồi máu hoặc nạp phi tiêu.

### 📱 Bố trí điều khiển Mobile (v0.9)

```
┌─────────────────────────────────────────────┐
│  [Điểm/HP/Phi tiêu]              [Kill Feed] │
│                                              │
│                                              │
│              [Vòng bo / Map]                 │
│                                              │
│                                              │
│  ┌──────┐                  ┌───┐  ┌───────┐ │
│  │      │                  │ T │  │       │ │
│  │ Joys │                  │ e │  │ Throw │ │
│  │ 200  │                  │ l │  │  180  │ │
│  │      │                  │ 140│  │       │ │
│  └──────┘                  └───┘  └───────┘ │
└─────────────────────────────────────────────┘
```

- **Joystick**: 200×200px, góc dưới-trái, cách cạnh 30px
- **Throw button**: 180×180px, góc dưới-phải, cách cạnh 30px
- **Teleport button**: 140×140px, bên trái Throw, gap 60px
- **Hit area**: Joystick +80px padding, Throw +25px, Teleport +15px (không overlap)

---

## 🐛 Lỗi đã fix trong v0.9

| # | Mô tả | Mức độ | File |
|---|-------|--------|------|
| 1 | **Joystick không di chuyển nhân vật**: `main.gd` dùng `$VirtualJoystick` nhưng node là con của `UILayer` → trả về `null` → joystick không connect với player | 🔴 Critical | `scripts/main.gd` |
| 2 | **Multi-touch broken: joystick dừng khi nhấn nút khác**: Mouse fallback (emulated từ touch) reset `is_pressed=false` khi BẤT KỲ mouse release nào xảy ra | 🔴 Critical | `scripts/virtual_joystick.gd`, `scripts/mobile_controls.gd` |
| 3 | **AI dart xuyên player không gây damage**: `dart.gd` `collision_mask` thiếu Player layer (1) | 🔴 Critical | `scripts/dart.gd` |
| 4 | **Teleport button không phản ứng**: Do bug #1, signal `teleport_pressed` không được connect | 🔴 Critical | `scripts/main.gd` |
| 5 | **Hit area overlap giữa throw và teleport button**: Touch vào teleport bị throw capture | 🟡 High | `scenes/mobile_controls.tscn`, `scripts/mobile_controls.gd` |
| 6 | **Duplicate teleport fire**: `teleport_btn.mouse_filter=STOP` + `_input` handling → teleport fire 2 lần | 🟡 High | `scripts/mobile_controls.gd` |
| 7 | **Duplicate screen shake khi teleport**: `_on_teleport_performed` + `screen_shake_requested` signal cùng trigger | 🟡 High | `scripts/main.gd` |
| 8 | **Button quá nhỏ (100×100)**: Quá nhỏ cho ngón cái mobile | 🟡 Medium | `scenes/mobile_controls.tscn` |
| 9 | **Joystick quá nhỏ (160×160)**: Khó điều khiển chính xác | 🟡 Medium | `scenes/virtual_joystick.tscn` |
| 10 | **`player.aim_touch_index = 0` ambiguous**: Trùng với touch index 0 thực tế | 🟢 Low | `scripts/player.gd` |
| 11 | **`player._die()` không reset dart_bonus/aim state**: Stuck aim line sau respawn | 🟢 Low | `scripts/player.gd` |
| 12 | **Empty `_input` trong `hud.gd`**: Dead code | 🟢 Low | `scripts/hud.gd` |

---

## 🔧 Tự phát hiện thiết bị

Phiên bản tự động phát hiện khả năng thiết bị và chọn mức đồ họa phù hợp:

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

### Phiên bản v0.9

**Tải xuống:** [Phi Tiêu Dịch Chuyển v0.9](https://github.com/mhieuhonda/phitieudichchuyen/releases/tag/v0.9)

**Nội dung bản phát hành:**
- 🐛 Fix 4 critical bugs (joystick, multi-touch, AI dart, teleport)
- 📱 Button mobile to hơn, layout tốt hơn
- ✨ Multi-touch: giữ joystick + bắn + dịch chuyển cùng lúc
- 🎨 Visual feedback khi nhấn nút
- 🧹 Code cleanup, remove dead code

---

## 🛠️ Công nghệ

| Công nghệ | Chi tiết |
|-----------|----------|
| **Engine** | [Godot 4.2.2](https://godotengine.org/) |
| **Ngôn ngữ** | GDScript |
| **Đồ họa** | 2D Sprite-based |
| **Nền tảng phát hành** | GitHub Actions CI/CD |
| **License** | MIT |

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
│   └── audio/                    # Âm thanh - 155 files
│       ├── sfx/                  # 150 sound effects (WAV)
│       └── music/                # 5 nhạc nền (WAV)
├── scenes/                       # Godot scene files (.tscn)
│   ├── main.tscn                 # Scene chính game
│   ├── menu.tscn                 # Menu chính
│   ├── loading.tscn              # Loading screen
│   ├── map.tscn                  # Bản đồ
│   ├── player.tscn               # Người chơi
│   ├── ai_player.tscn            # AI đối thủ
│   ├── dart.tscn                 # Phi tiêu
│   ├── hud.tscn                  # Giao diện HUD
│   ├── pickup.tscn               # Vật phẩm
│   ├── mobile_controls.tscn      # Nút bấm mobile (v0.9: button to hơn)
│   ├── virtual_joystick.tscn     # Joystick ảo (v0.9: 200×200)
│   └── settings.tscn             # Menu cài đặt
├── scripts/                      # GDScript files (.gd)
│   ├── main.gd                   # Scene chính logic (v0.9: fix @onready paths)
│   ├── menu.gd                   # Menu logic
│   ├── loading_screen.gd         # Loading screen
│   ├── player.gd                 # Người chơi logic (v0.9: reset state on die)
│   ├── ai_player.gd              # AI logic
│   ├── dart.gd                   # Phi tiêu logic (v0.9: fix collision_mask)
│   ├── hud.gd                    # HUD logic
│   ├── map.gd                    # Bản đồ logic
│   ├── pickup.gd                 # Vật phẩm logic
│   ├── game_manager.gd           # Singleton: quản lý game
│   ├── settings_manager.gd       # Singleton: cài đặt + device detect
│   ├── audio_manager.gd          # Singleton: âm thanh + nhạc
│   ├── mobile_controls.gd        # Nút bấm mobile (v0.9: multi-touch fix)
│   ├── virtual_joystick.gd       # Joystick ảo (v0.9: multi-touch fix)
│   └── settings_menu.gd          # Menu cài đặt
├── project.godot                 # Godot project config (v0.9)
├── export_presets.cfg            # Export presets (v0.9)
├── icon.svg                      # App icon
├── CHANGELOG.md                  # Lịch sử thay đổi
├── LICENSE                       # MIT License
└── README.md                     # File này
```

---

## 🔊 Hệ thống âm thanh (v0.8+)

Phiên bản 0.8 thêm **155 file âm thanh** (150 SFX + 5 nhạc nền), tất cả được generate procedurally bằng Python với nhiều kỹ thuật synthesis.

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
| **Music** | 5 | menu (1) + game (2) + victory (1) + defeat (1) |
| ... | ... | + nhiều categories khác |

### AudioManager API

```gdscript
# Helper methods (chọn random variation tự động)
AudioManager.play_throw()          # Random throw_whoosh_01..05
AudioManager.play_teleport()       # Random teleport_zap_01..05
AudioManager.play_hit()            # Random hit_impact_01..05
AudioManager.play_kill()           # Random kill_explosion_01..05
AudioManager.play_ui_click()
AudioManager.play_combo(count)     # Combo x2..x6

# Music
AudioManager.play_music("menu")    # Fade in menu music
AudioManager.play_music("game")    # Fade in game music
AudioManager.stop_music()
```

---

## 📜 Changelog

Xem [CHANGELOG.md](CHANGELOG.md) để biết chi tiết các thay đổi theo từng phiên bản.

### Tóm tắt các phiên bản

| Version | Tính năng chính |
|---------|-----------------|
| **v0.9** | Fix joystick, multi-touch, AI dart xuyên player, teleport button. Button to hơn. |
| **v0.8** | 150+ sound effects + nhạc nền, fix nút mobile, tối ưu |
| **v0.7** | Full-screen landscape, nút bắn phi tiêu mới (hold-red line-rotate-release) |
| **v0.6** | Sprite rewrite, fix AI dart, mobile throw, camera shake |
| **v0.5** | Auto-detect thiết bị, loading screen, FPS counter |
| **v0.4** | GitHub Actions CI/CD, build APK/EXE tự động |
| **v0.3** | Polish giao diện mobile, cải thiện joystick |
| **v0.2** | Gameplay cơ bản, AI đối thủ, vật phẩm |
| **v0.1** | Prototype offline đầu tiên |

---

## 📄 License

Dự án phân phối dưới giấy phép **MIT**. Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

## 🤝 Đóng góp

Đây là dự án cá nhân. Nếu bạn muốn đóng góp, vui lòng:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/amazing-feature`)
3. Commit thay đổi (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Mở Pull Request

---

## 📧 Liên hệ

- **GitHub**: [mhieuhonda](https://github.com/mhieuhonda)
- **Repository**: [phitieudichchuyen](https://github.com/mhieuhonda/phitieudichchuyen)

---

> 🎯 **Phi Tiêu Dịch Chuyển** - Ném phi tiêu, dịch chuyển, nuốt đối thủ!
