# 🎯 Phi Tiêu Dịch Chuyển

> Ném phi tiêu - Dịch chuyển - Nuốt đối thủ! Game 2D top-down dành cho PC và Mobile.

[![Release](https://img.shields.io/badge/release-v1.0-blue.svg)](https://github.com/mhieuhonda/phitieudichchuyen/releases/tag/v1.0)
[![Godot](https://img.shields.io/badge/Godot-4.2.2-478CBF.svg)](https://godotengine.org/)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-green.svg)](https://github.com/mhieuhonda/phitieudichchuyen/releases)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

---

## 📖 Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down nơi bạn ném phi tiêu để tấn công, dịch chuyển tức thời đến vị trí phi tiêu để né tránh hoặc tiêu diệt đối thủ. Trò chơi tự động phát hiện thiết bị và chọn mức đồ họa phù hợp, đảm bảo trải nghiệm mượt mà trên mọi nền tảng.

Trận đấu diễn ra tối đa **5 phút**, người chơi và 5 bot AI chiến đấu để giành điểm số cao nhất. Khi hết giờ, bảng xếp hạng sẽ hiển thị toàn bộ người chơi kèm điểm số và số kill.

### ✨ Tính năng nổi bật (v1.0)

- 🎯 **Ném phi tiêu & Dịch chuyển**: Cơ chế chiến đấu độc đáo - ném phi tiêu rồi dịch chuyển tức thời đến vị trí phi tiêu
- ⚡ **Dịch chuyển giữa chừng**: Dịch chuyển khi phi tiêu đang bay, tạo yếu tố bất ngờ
- 🤖 **AI thông minh**: 5 bot đối thủ với hành vi đa dạng (đi tuần, săn đuổi, né tránh, tấn công, dash)
- 📱 **Hỗ trợ Mobile**: Joystick ảo + nút bấm, tự động hiện trên thiết bị di động
- 👆 **Multi-touch**: Giữ joystick di chuyển + nhấn nút bắn + nhấn nút dịch chuyển + kỹ năng CÙNG LÚC
- 🔴 **Nút bắn phi tiêu**: Giữ nút → kẻ chỉ màu đỏ, kéo xoay hướng, thả để bắn
- 🎮 **3 Kỹ năng chủ động**:
  - **Dash (Q)**: Lướt nhanh đến hướng di chuyển, cooldown 8s
  - **Shield (E)**: Khiên miễn damage 3s, cooldown 15s
  - **Multishot (Shift)**: Bắn 3 phi tiêu cùng lúc, cooldown 12s
- ❤️ **Hệ thống máu thông minh**:
  - Max HP tăng theo kích thước (càng lớn càng trâu)
  - Hồi **10% max HP** mỗi khi ăn được đối thủ
  - Khiên miễn damage hoàn toàn
- 🗺️ **Bản đồ đẹp hơn**: Grid pattern, chướng ngại vật đa dạng (đá, cây, thùng), decoration (hoa, cỏ, vết nứt), vòng bo gradient glow
- 🎨 **Sprite tách nền hoàn chỉnh**: Nhân vật ninja/warrior có mắt, đầu bụng, đai lưng - không còn ô vuông thô
- ⏱️ **Trận 5 phút**: Hiển thị thời gian đếm ngược, cảnh báo 30s cuối, kết thúc bằng bảng xếp hạng
- 🏆 **Bảng xếp hạng cuối trận**: Hiển thị rank, tên, điểm, số kill của tất cả người chơi
- 🔊 **155 sound effects + 5 nhạc nền**: Âm thanh cho mọi action + nhạc menu/game/victory/defeat
- ✨ **Hiệu ứng phong phú**: Particle khi teleport/kill/level-up/dash/shield, floating damage text, hit flash, smoke puff
- 💊 **Vật phẩm**: Hồi máu và nạp phi tiêu rải trên bản đồ
- 🔥 **Hệ thống Combo**: Tiêu diệt liên tiếp để nhân điểm
- ⭕ **Vòng bo thu nhỏ**: Khu vực an toàn thu dần, ép người chơi đối đầu
- 📐 **Responsive UI**: Tất cả UI dùng anchors + CanvasLayer, tự scale mọi kích thước màn hình

---

## 🎮 Cách chơi

| Hành động | PC (Bàn phím/Chuột) | Mobile |
|-----------|---------------------|----------------|
| Di chuyển | W/A/S/D hoặc Phím mũi tên | **Joystick bên trái** |
| Ngắm phi tiêu | Giữ chuột phải, kéo để điều chỉnh lực | **Giữ nút Bắn** → kẻ chỉ màu đỏ |
| Ném phi tiêu | Thả chuột phải | **Thả nút Bắn** |
| Dịch chuyển | Space | **Nút Dịch chuyển** |
| **Kỹ năng Dash** | **Q** | **Nút DASH** |
| **Kỹ năng Shield** | **E** | **Nút SHIELD** |
| **Kỹ năng Multishot** | **Shift** | **Nút MULTI** |
| Quay lại menu | Escape | Nút trên HUD |

### Cơ chế chính

- **Ném phi tiêu**: Giữ chuột phải (PC) hoặc giữ nút Bắn (mobile) để ngắm, kéo để điều chỉnh lực và hướng, thả để ném. Tối đa 3 phi tiêu cùng lúc.
- **Dịch chuyển**: Nhấn nút Dịch chuyển (mobile) hoặc Space (PC) để dịch chuyển tức thời đến vị trí phi tiêu vừa ném.
- **Dịch chuyển giữa chừng**: Nhấn khi phi tiêu đang bay để dịch chuyển đến vị trí hiện tại của phi tiêu!
- **Nuốt đối thủ**: Dịch chuyển đến gần AI đối thủ để tiêu diệt, tăng kích thước, điểm số, và hồi 10% HP.
- **Kỹ năng Dash**: Lướt nhanh 200px theo hướng di chuyển, hữu ích để né phi tiêu hoặc rút lui.
- **Kỹ năng Shield**: Kích hoạt khiên miễn damage 3 giây, có thể đánh đổi để băng qua vùng nguy hiểm.
- **Kỹ năng Multishot**: Bắn 3 phi tiêu cùng lúc với góc lệch nhẹ, gay tải sát thương diện rộng.
- **Max HP theo size**: Khi bạn lớn lên (nuốt đối thủ), max HP cũng tăng theo. Bạn càng lớn càng trâu bò, nhưng cũng là mục tiêu lớn hơn.
- **Vòng bo**: Khu vực an toàn thu nhỏ dần, ở ngoài sẽ mất máu.
- **Combo**: Tiêu diệt liên tiếp trong 2 giây để nhân điểm (x1.5, x2.0, x2.5...).
- **Trận đấu 5 phút**: Trận kết thúc khi hết giờ hoặc khi 1 người đạt top. Bảng xếp hạng sẽ hiển thị cuối trận.

### 📱 Bố trí điều khiển Mobile

```
┌──────────────────────────────────────────────────────────────┐
│  [Điểm/HP/Phi tiêu]                       [Kill Feed]        │
│                  [⏱ 05:00]                                   │
│                                                              │
│                    [Vòng bo / Map]                           │
│                                                              │
│                                                              │
│  ┌──────┐         ┌─────┐ ┌─────┐ ┌─────┐ ┌───┐ ┌───────┐   │
│  │      │         │DASH │ │SHIELD│ │MULTI│ │ T │ │ THROW │   │
│  │ Joys │         │  Q  │ │  E  │ │Shift│ │ 140│ │  180  │   │
│  │ 200  │         └─────┘ └─────┘ └─────┘ └───┘ └───────┘   │
│  │      │                                                   │
│  └──────┘                                                   │
└──────────────────────────────────────────────────────────────┘
```

---

## 🆕 Có gì mới trong v1.0

### 🗺️ Bản đồ vẽ lại
- **Grid pattern**: Lưới nhẹ 100px + lưới chính 500px cho cảm giác không gian
- **Obstacles đa dạng**: Đá (shape bất đối xứng), cây (tán nhiều lớp), thùng gỗ (X chữ)
- **Decoration**: Bụi cỏ, hoa nhỏ, vết nứt sàn không collision
- **Vòng bo gradient**: Glow đỏ/cam sống động, fill polygon nhẹ bên trong
- **Tường viền**: Nâu đá với border highlight

### 🎨 Sprite tách nền hoàn chỉnh
Tất cả sprite được vẽ lại bằng Python PIL với nền **trong suốt hoàn toàn** (alpha=0):
- **Player/AI**: Ninja/warrior hình tròn với body color, headband màu accent, mắt trắng + pupil, belt + buckle vàng, rim light, gradient highlight
- **Dart**: Metallic tip + shaft silver gradient + fletching đỏ
- **Pickups**: Glowing halo + disc + icon (cross/dart)
- **Buttons**: Teleport (cyan swirl), Throw (target rings)
- **Joystick**: Recessed base + glossy knob

### ❤️ Hệ thống máu mới
- `base_player_max_hp = 100` (size 20)
- `hp_per_size_unit = 4` → size 60 = 100 + (60-20)*4 = 260 HP max
- Hồi `10% max HP` mỗi khi ăn đối thủ (cả player và AI)
- Shield miễn damage 100% trong 3s

### 🎮 Kỹ năng chủ động
| Skill | Phím PC | Nút Mobile | Hiệu ứng | Cooldown |
|-------|---------|------------|----------|----------|
| Dash | Q | DASH | Lướt 200px theo hướng di chuyển | 8s |
| Shield | E | SHIELD | Khiên miễn damage 3s | 15s |
| Multishot | Shift | MULTI | Bắn 3 phi tiêu cùng lúc | 12s |

AI cũng có thể dùng dash để né/truy đuổi.

### 🏆 Bảng xếp hạng cuối trận
- Khi hết giờ 5 phút, hiện bảng xếp hạng với:
  - Rank (#1, #2, ... với màu vàng/bạc/đồng)
  - Tên người chơi (Player hiện màu cyan + "(Bạn)")
  - Điểm số
  - Số kill
- Nút "Chơi lại" và "Menu chính"

### ✨ Hiệu ứng thêm
- Particle dash (cyan), shield (blue), buff (orange), kill (red explosion), level-up (gold), smoke puff (grey)
- Floating text: "+100", "+26 HP", "-25", "BLOCK!" 
- Hit flash (sprite modulate red)
- Level-up effect khi tăng size

### 🐛 Lỗi đã fix
- AI teleport kill không kill được player (chỉ gây 50 dmg) → giờ kill ngay như player
- AI dart giết đối thủ không ghi score/kill → giờ ghi nhận đúng
- Player dart giết AI không ghi score/kill → giờ ghi nhận + heal + size
- Player chết không reset skill state (shield, dash, multishot) → giờ reset hết
- AI respawn không reset leaderboard entry → giờ reset alive=true, score=0, kills=0
- Match không có giới hạn thời gian → giờ 5 phút
- Sprite có nền đen opaque → giờ trong suốt hoàn toàn

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

### Phiên bản v1.0

**Tải xuống:** [Phi Tiêu Dịch Chuyển v1.0](https://github.com/mhieuhonda/phitieudichchuyen/releases/tag/v1.0)

**Nội dung bản phát hành:**
- 🗺️ Vẽ lại map đẹp: grid pattern, obstacles đa dạng, decoration
- 🎨 Sprite tách nền hoàn chỉnh: ninja warrior với mắt, đầu bụt, belt
- 🎮 3 kỹ năng chủ động: Dash, Shield, Multishot
- ❤️ Max HP theo size + hồi 10% HP khi ăn đối thủ
- ⏱️ Trận đấu 5 phút + bảng xếp hạng cuối trận
- ✨ Hiệu ứng: particle, floating text, hit flash, level-up
- 🐛 Fix toàn bộ lỗi logic game

---

## 🛠️ Công nghệ

| Công nghệ | Chi tiết |
|-----------|----------|
| **Engine** | [Godot 4.2.2](https://godotengine.org/) |
| **Ngôn ngữ** | GDScript |
| **Đồ họa** | 2D Sprite-based (PIL procedural generation) |
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
│   ├── sprites/                  # Sprite tài nguyên (PNG, v1.0: regenerated)
│   │   ├── player_blue.png       # Sprite người chơi (ninja xanh)
│   │   ├── ai_*.png              # Sprite AI (10 màu)
│   │   ├── dart.png              # Sprite phi tiêu (metallic + fletching)
│   │   ├── pickup_health.png     # Sprite hồi máu (cross đỏ)
│   │   ├── pickup_dart.png       # Sprite nạp phi tiêu (dart icon)
│   │   ├── shield.png            # Sprite khiên (hex rune)
│   │   ├── joystick_base.png     # Joystick nền
│   │   ├── joystick_stick.png    # Joystick cần
│   │   ├── btn_teleport.png      # Nút dịch chuyển (cyan swirl)
│   │   ├── btn_throw.png         # Nút ném (target rings)
│   │   └── teleport_effect.png   # Hiệu ứng dịch chuyển
│   └── audio/                    # Âm thanh - 155 files
│       ├── sfx/                  # 150 sound effects (WAV)
│       └── music/                # 5 nhạc nền (WAV)
├── scenes/                       # Godot scene files (.tscn)
│   ├── main.tscn                 # Scene chính game
│   ├── menu.tscn                 # Menu chính
│   ├── loading.tscn              # Loading screen
│   ├── map.tscn                  # Bản đồ (v1.0: grid + decor layers)
│   ├── player.tscn               # Người chơi (v1.0: +ShieldSprite)
│   ├── ai_player.tscn            # AI đối thủ
│   ├── dart.tscn                 # Phi tiêu
│   ├── hud.tscn                  # HUD (v1.0: +MatchTimer, +SkillPanel, +ResultsPanel)
│   ├── pickup.tscn               # Vật phẩm
│   ├── mobile_controls.tscn      # Nút bấm mobile (v1.0: +3 skill buttons)
│   ├── virtual_joystick.tscn     # Joystick ảo
│   └── settings.tscn             # Menu cài đặt
├── scripts/                      # GDScript files (.gd)
│   ├── main.gd                   # Scene chính logic (v1.0: +skill handlers)
│   ├── menu.gd                   # Menu logic
│   ├── loading_screen.gd         # Loading screen
│   ├── player.gd                 # Player (v1.0: +skills, +heal on kill, +floating text)
│   ├── ai_player.gd              # AI (v1.0: +max HP scale, +leaderboard, +dash)
│   ├── dart.gd                   # Phi tiêu logic
│   ├── hud.gd                    # HUD (v1.0: +skill UI, +results panel, +leaderboard)
│   ├── map.gd                    # Map (v1.0: +grid, +decorations, +obstacle types)
│   ├── pickup.gd                 # Vật phẩm logic
│   ├── game_manager.gd           # Singleton (v1.0: +match timer, +leaderboard, +skills config)
│   ├── settings_manager.gd       # Singleton: cài đặt + device detect
│   ├── audio_manager.gd          # Singleton: âm thanh + nhạc
│   ├── mobile_controls.gd        # Mobile controls (v1.0: +skill button handlers)
│   ├── virtual_joystick.gd       # Joystick ảo
│   └── settings_menu.gd          # Menu cài đặt
├── project.godot                 # Godot project config (v1.0)
├── export_presets.cfg            # Export presets
├── icon.svg                      # App icon
├── CHANGELOG.md                  # Lịch sử thay đổi
├── LICENSE                       # MIT License
└── README.md                     # File này
```

---

## 🔊 Hệ thống âm thanh

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
| combo | 5 | Combo (tăng dần theo combo count) |
| zone_warning | 3 | Cảnh báo ngoài vòng bo |
| powerup | 3 | Kích hoạt kỹ năng |
| whoosh | 5 | Dash skill |
| **Music** | 5 | menu (1) + game (2) + victory (1) + defeat (1) |
| ... | ... | + nhiều categories khác |

---

## 📜 Changelog

Xem [CHANGELOG.md](CHANGELOG.md) để biết chi tiết các thay đổi theo từng phiên bản.

### Tóm tắt các phiên bản

| Version | Tính năng chính |
|---------|-----------------|
| **v1.0** | Map đẹp + 3 kỹ năng chủ động + Max HP theo size + Hồi 10% HP khi ăn + Sprite tách nền + Bảng xếp hạng cuối trận + Trận 5 phút |
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

> 🎯 **Phi Tiêu Dịch Chuyển v1.0** - Ném phi tiêu, dịch chuyển, nuốt đối thủ, giành hạng nhất!
