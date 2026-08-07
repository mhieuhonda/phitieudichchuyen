# 🎯 Phi Tiêu Dịch Chuyển

> **Ném phi tiêu — Dịch chuyển — Nuốt đối thủ!**
>
> Game 2D top-down action offline. Godot 4.7.

[![Version](https://img.shields.io/badge/version-3.0-gold.svg)]()
[![Engine](https://img.shields.io/badge/Godot-4.7-blue.svg)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 📖 Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down offline, kết hợp cơ chế ném phi tiêu +
dịch chuyển tức thời để "ăn" đối thủ. Bạn được thả vào arena 2000×2000 cùng 5 AI, mục
tiêu: tích điểm cao nhất và đứng đầu leaderboard khi trận đấu 5 phút kết thúc.

### Cơ chế độc đáo

1. **Ném phi tiêu** — Kéo chuột (hoặc nút Throw trên mobile) để nhắm và tăng lực, thả
   để ném. Phi tiêu bay thẳng, cắm vào tường/đất, tồn tại 5 giây.
2. **Dịch chuyển tức thời** — Bấm Space (hoặc nút Teleport) để dịch chuyển ngay đến
   phi tiêu gần nhất. Có thể dịch chuyển khi phi tiêu đang bay (mid-flight) hoặc đã cắm.
3. **Ăn đối thủ** — Dịch chuyển đến gần đối thủ trong bán kính 50px sẽ tiêu diệt chúng
   ngay lập tức. Càng ăn nhiều, kích thước càng to, HP max càng cao — nhưng cũng dễ bị
   bắn trúng hơn.
4. **Vòng bo thu nhỏ** — Mỗi 30 giây vòng bo thu hẹp, đứng ngoài sẽ mất HP liên tục.
5. **Combo kill** — Giết liên tiếp trong 2 giây để nhận combo bonus (×1.5, ×2.0, ×2.5...).

---

## ✨ Tính năng chính (v3.0)

- 🎮 **Offline PvP hoàn toàn** — Chơi với 5 AI, không cần Internet, không server.
- 🥷 **12 nhân vật** — 4 loại (Chiến Binh / Pháp Sư / Quyền Sư / Sát Thủ), mỗi nhân
  vật có bonus chỉ số + skill bonus riêng. Tất cả đều mở khóa sẵn.
- ⚔ **3 kỹ năng chủ động** — Dash, Shield, Multishot (cooldown 8s / 15s / 12s).
- 🎯 **Arena 2000×2000** — Vòng bo thu nhỏ dần, kích hoạt combat giữa những người sống sót.
- 🏆 **Leaderboard đầy đủ** — Xếp hạng theo điểm + kill count, có kill feed realtime.
- 🌐 **Đa ngôn ngữ** — Tiếng Việt / English, chuyển đổi tức thời trong Settings.
- 📱 **Hỗ trợ mobile** — Joystick ảo + nút bấm cảm ứng, drag-drop tùy chỉnh vị trí.
- 🎨 **Premium UI** — Hover effects, glow pulse, dark theme vàng-tím nhất quán.
- 🔊 **~150 sound effects** + 5 nhạc nền, variation system tránh lặp âm.
- ⚙ **4 mức chất lượng đồ họa** — Tự phát hiện thiết bị, tối ưu cho máy yếu đến máy mạnh.
- 📊 **Daily login reward** — Streak ngày liên tiếp = +HP bonus (tối đa +30%).
- 🎮 **Pause menu + Death recap** — Tạm dừng khi cần, xem chi tiết khi chết.

---

## 🎮 Điều khiển

### PC

| Phím | Hành động |
|---|---|
| **WASD** / **← ↑ ↓ →** | Di chuyển |
| **Chuột phải** (kéo → thả) | Nhắm & ném phi tiêu |
| **Space** | Dịch chuyển đến phi tiêu |
| **Q** | Kỹ năng Dash |
| **E** | Kỹ năng Shield |
| **Shift** | Kỹ năng Multishot |
| **R** | Chơi lại (khi game over) |
| **P** / **ESC** | Pause menu |
| **ESC** | Quay lại (trong menu/settings) |

### Mobile

- **Joystick trái** — Di chuyển
- **Nút Throw** — Kéo để nhắm, thả để ném
- **Nút Teleport** — Dịch chuyển tức thời
- **Nút Dash / Shield / Multishot** — Kỹ năng

---

## 🥷 Nhân vật (12)

Tất cả nhân vật đều mở khóa sẵn. Mỗi nhân vật có bonus HP / Speed / Dart + 1 skill bonus.

| # | Tên | Loại | HP | Speed | Dart | Skill bonus |
|---|---|---|---|---|---|---|
| 0 | Rồng Đỏ | Chiến Binh | +15 | +0 | +0 | Dash mạnh hơn 20% |
| 1 | Phượng Xanh | Pháp Sư | +0 | +10 | +1 | Multishot 4 phi tiêu |
| 2 | Hổ Vàng | Quyền Sư | +25 | +0 | +0 | Shield lâu +50% |
| 3 | Báo Lục | Sát Thủ | -10 | +20 | +0 | Dash CD -30% |
| 4 | Sói Tím | Chiến Binh | +10 | +5 | +0 | Dash mạnh hơn 20% |
| 5 | Cáo Hồng | Pháp Sư | -5 | +15 | +1 | Multishot 4 phi tiêu |
| 6 | Gấu Nâu | Quyền Sư | +30 | -10 | +0 | Shield lâu +50% |
| 7 | Diều Cam | Sát Thủ | -5 | +15 | +0 | Dash CD -30% |
| 8 | Cọp Xanh | Chiến Binh | +10 | +10 | +0 | Dash mạnh hơn 20% |
| 9 | Chồn Bạc | Sát Thủ | -10 | +25 | +0 | Dash CD -30% |
| 10 | Thiên Long | Pháp Sư | +5 | +5 | +2 | Multishot 5 phi tiêu |
| 11 | Hắc Vũ | Sát Thủ | -15 | +30 | +0 | Dash CD -30% |

---

## 🛠 Cài đặt & chạy

### Yêu cầu

- [Godot 4.7](https://godotengine.org/download) (Standard hoặc .NET, không cần .NET)
- GPU hỗ trợ OpenGL 3.3+ / GLES3

### Chạy từ source

```bash
git clone https://github.com/mhieuhonda/phitieudichchuyen.git
cd phitieudichchuyen
godot --path .  # Mở project trong Godot editor
# F5 để chạy game
```

### Build (export)

1. Mở project trong Godot 4.7
2. **Project → Export...**
3. Chọn preset: Android / Windows Desktop / Linux/X11
4. Bấm **Export Project...** → lưu file build vào `build/`

Export presets có sẵn trong `export_presets.cfg` (3 preset: Android APK, Windows EXE,
Linux binary). Android preset sử dụng prebuilt APK template (no gradle build).

---

## 📁 Cấu trúc dự án

```
phitieudichchuyen/
├── project.godot              # Godot project config (autoloads, input, layers)
├── export_presets.cfg         # 3 export presets (Android/Windows/Linux)
├── icon.svg                   # App icon
├── README.md                  # This file
├── BAO_CAO_GAME.txt           # Detailed game report (Vietnamese)
├── CHANGELOG.md               # History of changes
├── LICENSE
│
├── scenes/                    # 13 Godot scenes (.tscn)
├── scripts/                   # 21 GDScript files (.gd)
├── assets/
│   ├── sprites/               # Character + UI sprites (PNG)
│   │   └── characters/        # 12 character sprites (256×256)
│   └── audio/
│       ├── sfx/               # ~150 sound effects (.wav)
│       └── music/             # 5 music tracks (.wav)
│
└── .github/workflows/
    └── build-release.yml      # CI: build 3 platforms on tag push
```

### Autoload singletons

| Singleton | Vai trò |
|---|---|
| `SettingsManager` | Load/save settings, device detection, UI layout |
| `GameManager` | Match state, score, HP, zone, leaderboard |
| `AudioManager` | 16-voice SFX pool + music playback |
| `CharacterData` | 12 characters database, selected character |
| `I18N` | Vietnamese / English translations |

---

## 🌐 Đa ngôn ngữ

Game hỗ trợ **Tiếng Việt** (mặc định) và **English**. Đổi ngôn ngữ trong
**Settings → 🌐 NGÔN NGỮ**. Thay đổi áp dụng tức thời trên toàn UI.

---

## ⚙ Cài đặt (Settings)

| Section | Tùy chọn |
|---|---|
| **🎨 Đồ Họa** | Chất lượng (Cực Thấp / Thấp / Trung Bình / Cao), Hiện FPS, Rung màn hình, Hiện Joystick |
| **🔊 Âm Thanh** | Bật/tắt SFX + Music, Slider âm lượng SFX + Music |
| **🌐 Ngôn Ngữ** | Tiếng Việt / English |
| **🎛 Giao Diện** | Chỉnh sửa vị trí nút (drag-drop), Info thiết bị |

---

## 🔄 Lịch sử phiên bản

| Version | Ngày | Tóm tắt |
|---|---|---|
| **3.0** | 2026-08-07 | Phiên bản Offline hoàn toàn — xóa Zombie mode, Online mode, Guide, Gift Code, nhân vật Ma Tôn / Hieu Louis. 12 nhân vật đều mở khóa. |
| 2.9 | 2026-08 | Fix sprite Ma Tôn + sắp xếp lại Settings + sửa lỗi ESC |
| 2.8 | 2026-08 | Fix 15 bugs + thêm 5 features (combo, perf overlay, pause menu, death recap) |
| 2.7 | 2026-08 | Ma Tôn character + 6 bug fixes + Zombie graphics overhaul + Premium UI redesign |
| 2.4 | 2026-08 | Vượt Ải mode (500 level) + EN/VI language + horror sounds |
| 2.0 | 2026-08 | Mode selection (Online/Offline/Endless) |
| 1.0 | 2026-07 | Phiên bản đầu tiên — Offline PvP với 5 AI |

Xem chi tiết tại [CHANGELOG.md](CHANGELOG.md).

---

## 🛠 Công nghệ

- **Engine**: Godot 4.7 (stable, Mobile profile)
- **Ngôn ngữ**: GDScript 2.0
- **Physics**: 2D, 6 layers (Player/Dart/Wall/AI/Obstacle/Pickup)
- **Audio**: 16-voice pool, WAV format, lazy-loading
- **Đồ họa**: 2D CanvasLayer, CPUParticles2D, StyleBoxFlat premium UI
- **CI/CD**: GitHub Actions (build Android + Windows + Linux song song)
- **Localization**: Custom I18N system (VI/EN)

---

## 📜 License

Xem [LICENSE](LICENSE).

---

## 🤝 Đóng góp

Mọi góp ý / bug report / feature request — tạo issue tại:
<https://github.com/mhieuhonda/phitieudichchuyen/issues>

---

<p align="center">
  <strong>Phi Tiêu Dịch Chuyển v3.0</strong><br>
  <em>"Ném phi tiêu • Dịch chuyển • Nuốt đối thủ"</em>
</p>
