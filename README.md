# Phi Tiêu Dịch Chuyển

> **Ném phi tiêu — Dịch chuyển — Nuốt đối thủ!**
> Game 2D top-down PvP offline, Godot 4.7.

[![Version](https://img.shields.io/badge/version-3.4-gold.svg)]()
[![Engine](https://img.shields.io/badge/Godot-4.7-blue.svg)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down offline. Bạn được thả vào arena 2000×2000
cùng 5 AI. Mục tiêu: tích điểm cao nhất và đứng đầu leaderboard khi trận đấu 5 phút
kết thúc. Cơ chế độc đáo: **ném phi tiêu → dịch chuyển tới phi tiêu → ăn đối thủ**.

### Cơ chế chính

1. **Ném phi tiêu** — Kéo chuột (hoặc nút **NÉM** trên mobile) để nhắm & tăng lực,
   thả để ném. Phi tiêu bay thẳng, có thể **nảy 1 lần** khi chạm tường/đá.
2. **Dịch chuyển tức thời** — Bấm Space (hoặc nút **DỊCH** trên mobile) để dịch
   chuyển ngay tới phi tiêu gần nhất, tạo **knockback** cho kẻ địch xung quanh.
3. **Ăn đối thủ** — Dịch chuyển đến gần đối thủ trong bán kính 50px sẽ tiêu diệt chúng.
4. **Vòng bo thu nhỏ** — Mỗi 30 giây vòng bo thu hẹp, đứng ngoài mất HP liên tục.
5. **Combo kill** — Giết liên tiếp trong 2 giây để nhận combo bonus (×1.5, ×2.0...).

---

## Có gì mới trong v3.4

- **2 nút tròn** — Nút **DỊCH** (xanh lá) + nút **NÉM** (đỏ). Đã xóa 3 nút kỹ năng
  (Dash / Shield / Multishot) — giao diện tối giản, tập trung vào cơ chế cốt lõi.
- **Nút "Chỉnh sửa giao diện"** đã ra thẳng **sảnh chờ** — không còn giấu trong Settings.
- **Settings được dọn lại** theo 4 mục rõ ràng: Đồ Họa / Âm Thanh / Ngôn Ngữ / Giao Diện.
- **Ảnh nền `AnhNen.png`** được dùng làm nền trận đấu, scale vừa map 2000×2000.
- **Hiệu ứng mới**: shockwave ring khi dịch chuyển, screen flash khi kill/die/respawn,
  pulse animation cho nút bấm, camera shake mạnh hơn.
- **Sound effects mới**: `play_shockwave`, `play_kill_flash`, `play_zone_event` —
  mix nhiều variation tạo cảm giác chiến đấu ấn tượng hơn.
- **Hoàn thiện hook rỗng**: `_on_teleport_performed`, `_on_game_over` trong `main.gd`
  giờ thực sự spawn hiệu ứng.

---

## Điều khiển

### PC

| Phím | Hành động |
|---|---|
| **WASD** / **← ↑ ↓ →** | Di chuyển |
| **Chuột phải** (kéo → thả) | Nhắm & ném phi tiêu |
| **Space** | Dịch chuyển đến phi tiêu |
| **R** | Chơi lại (khi game over) |
| **P** / **ESC** | Pause menu / Quay lại |

### Mobile

- **Joystick trái** — Di chuyển
- **Nút NÉM (đỏ, tròn)** — Kéo để nhắm, thả để ném
- **Nút DỊCH (xanh, tròn)** — Dịch chuyển tức thời
- **Kéo thả nút** — Tùy chỉnh vị trí (Sảnh chờ → Chỉnh sửa giao diện)

---

## Nhân vật (12)

Tất cả nhân vật đều mở khóa sẵn. Mỗi nhân vật có bonus HP / Speed / Dart.

| # | Tên | Loại | HP | Speed | Dart |
|---|---|---|---|---|---|
| 0 | Rồng Đỏ | Chiến Binh | +15 | +0 | +0 |
| 1 | Phượng Xanh | Pháp Sư | +0 | +10 | +1 |
| 2 | Hổ Vàng | Quyền Sư | +25 | +0 | +0 |
| 3 | Báo Lục | Sát Thủ | -10 | +20 | +0 |
| 4 | Sói Tím | Chiến Binh | +10 | +5 | +0 |
| 5 | Cáo Hồng | Pháp Sư | -5 | +15 | +1 |
| 6 | Gấu Nâu | Quyền Sư | +30 | -10 | +0 |
| 7 | Diều Cam | Sát Thủ | -5 | +15 | +0 |
| 8 | Cọp Xanh | Chiến Binh | +10 | +10 | +0 |
| 9 | Chồn Bạc | Sát Thủ | -10 | +25 | +0 |
| 10 | Thiên Long | Pháp Sư | +5 | +5 | +2 |
| 11 | Hắc Vũ | Sát Thủ | -15 | +30 | +0 |

---

## Cài đặt & chạy

### Yêu cầu

- [Godot 4.7](https://godotengine.org/download) (Standard hoặc .NET, không cần .NET)
- GPU hỗ trợ OpenGL 3.3+ / GLES3

### Chạy từ source

```bash
git clone https://github.com/mhieuhonda/phitieudichchuyen.git
cd phitieudichchuyen
godot --path .  # Mở project trong Godot editor, F5 để chạy
```

### Build (export)

1. Mở project trong Godot 4.7
2. **Project → Export...**
3. Chọn preset: Android / Windows Desktop / Linux/X11
4. Bấm **Export Project...** → lưu file build vào `build/`

Export presets có sẵn trong `export_presets.cfg` (3 preset: Android APK, Windows EXE,
Linux binary).

---

## Cấu trúc dự án

```
phitieudichchuyen/
├── project.godot              # Godot config (autoloads, input, layers, version 3.4)
├── export_presets.cfg         # 3 export presets (Android/Windows/Linux)
├── icon.svg                   # App icon
├── README.md                  # This file
├── CHANGELOG.md               # History of changes
├── LICENSE
│
├── scenes/                    # Godot scenes (.tscn) — code-based UI
├── scripts/                   # GDScript files (.gd)
├── assets/
│   ├── sprites/               # Character + dart + joystick sprites + AnhNen.png
│   │   ├── characters/        # 12 character sprites (256×256)
│   │   ├── AnhNen.png         # Ảnh nền trận đấu (v3.4)
│   │   └── (joystick, dart, shield, pickup, ai_*)
│   └── audio/
│       ├── sfx/               # ~155 sound effects (.wav)
│       └── music/             # 5 music tracks (.wav)
│
└── .github/workflows/         # CI: build 3 platforms on tag push
```

### Autoload singletons

| Singleton | Vai trò |
|---|---|
| `SettingsManager` | Load/save settings, device detection, UI layout |
| `GameManager` | Match state, score, HP, zone, leaderboard, vật lý |
| `AudioManager` | 16-voice SFX pool + music playback + ~155 sound variations |
| `CharacterData` | 12 characters database, selected character |
| `I18N` | Vietnamese / English translations |

---

## Đa ngôn ngữ

Game hỗ trợ **Tiếng Việt** (mặc định) và **English**. Đổi ngôn ngữ trong
**Settings → NGÔN NGỮ**. Thay đổi áp dụng tức thời trên toàn UI.

---

## Settings (v3.4)

| Mục | Tùy chọn |
|---|---|
| **🎨 Đồ Họa** | Chất lượng (Cực Thấp / Thấp / Trung Bình / Cao), Hiện FPS, Rung màn hình, Hiện Joystick |
| **🔊 Âm Thanh** | Bật/tắt SFX + Music, Slider âm lượng SFX + Music |
| **🌐 Ngôn Ngữ** | Tiếng Việt / English |
| **🎛 Giao Diện** | Slider Joystick size / Button size / UI opacity, Nút CHỈNH SỬA GIAO DIỆN, Info thiết bị |

---

## Lịch sử phiên bản

| Version | Ngày | Tóm tắt |
|---|---|---|
| **3.4** | 2026-08-10 | 2 nút tròn (Xanh dịch / Đỏ ném). Xóa 3 skills. Nút chỉnh sửa giao diện ra sảnh chờ. Settings dọn theo 4 mục. Ảnh nền AnhNen.png. Shockwave + screen flash + pulse effects. |
| 3.3 | 2026-08-08 | Code-based UI (bỏ PNG buttons). Vật lý mới (ricochet, knockback, dash i-frames, teleport knockback). AI thông minh hơn (kiting, prediction, dodge, flee, pickup). |
| 3.2 | 2026-08-08 | Premium PNG UI (đã bị thay bằng code-based trong 3.3) |
| 3.1 | 2026-08-07 | Premium UI với ảnh nền + nút custom (đã bị thay) |
| 3.0 | 2026-08-07 | Phiên bản Offline hoàn toàn — xóa Zombie mode, Online mode, Guide, Gift Code |
| 2.8 | 2026-08 | Fix 15 bugs + thêm 5 features (combo, perf overlay, pause menu, death recap) |
| 2.4 | 2026-08 | EN/VI language + horror sounds |
| 2.0 | 2026-08 | Mode selection |
| 1.0 | 2026-07 | Phiên bản đầu tiên — Offline PvP với 5 AI |

Xem chi tiết tại [CHANGELOG.md](CHANGELOG.md).

---

## Công nghệ

- **Engine**: Godot 4.7 (stable, Mobile profile)
- **Ngôn ngữ**: GDScript 2.0
- **Physics**: 2D, 6 layers (Player/Dart/Wall/AI/Obstacle/Pickup) + ricochet + knockback
- **Audio**: 16-voice pool, WAV format, lazy-loading, ~155 sound variations
- **Đồ họa**: 2D CanvasLayer, CPUParticles2D, code-based UI (StyleBoxFlat)
- **CI/CD**: GitHub Actions (build Android + Windows + Linux song song)
- **Localization**: Custom I18N system (VI/EN)

---

## License

Xem [LICENSE](LICENSE).

---

## Đóng góp

Mọi góp ý / bug report / feature request — tạo issue tại:
<https://github.com/mhieuhonda/phitieudichchuyen/issues>

---

<p align="center">
  <strong>Phi Tiêu Dịch Chuyển v3.4</strong><br>
  <em>"Ném phi tiêu · Dịch chuyển · Nuốt đối thủ"</em>
</p>
