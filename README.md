# Phi Tiêu Dịch Chuyển

> Vượt 20 ải · Ném phi tiêu · Dịch chuyển · Tiêu diệt Boss
> Game 2D top-down offline, Godot 4.7.

![Version](https://img.shields.io/badge/version-3.6-gold.svg)
![Engine](https://img.shields.io/badge/Godot-4.7-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down offline với cơ chế độc đáo: **ném phi tiêu → dịch chuyển tức thời tới phi tiêu → tiêu diệt đối thủ**. Chế độ chính là **Vượt Ải** — 20 ải với độ khó tăng dần, kết thúc bằng Boss cuối 10 triệu HP.

## Cơ chế

| Cơ chế | Mô tả |
|---|---|
| **Ném phi tiêu** | Kéo chuột phải (PC) hoặc nút **NÉM** (mobile) để nhắm & tăng lực. Phi tiêu nảy 1 lần khi chạm tường. |
| **Dịch chuyển** | Space (PC) hoặc nút **DỊCH** (mobile) để dịch tới phi tiêu gần nhất, gây knockback cho địch xung quanh. |
| **Tiêu diệt** | Dịch chuyển đến gần AI trong bán kính 50px để tiêu diệt. |
| **Vượt ải** | Tiêu diệt toàn bộ AI/Boss trong ải. Càng ải cao, AI càng thông minh. |
| **Boss cuối (Ải 20)** | 10M HP, laser (đứng giữa = 2x damage), rage sweep 360° ở 10% HP. Dịch chuyển tới boss = 250k damage. |

## Điều khiển

| Hành động | PC | Mobile |
|---|---|---|
| Di chuyển | WASD / ← ↑ ↓ → | Joystick trái |
| Nhắm & ném | Chuột phải (kéo → thả) | Nút **NÉM** (đỏ, tròn) |
| Dịch chuyển | Space | Nút **DỊCH** (xanh, tròn) |
| Tạm dừng | P / ESC | — |

## Cấu trúc ải

| ải | Số AI | Đặc điểm | Mạng |
|---|---|---|---|
| 1-5 | 1 | AI ngu — dodge thấp | 3 |
| 6-10 | 2 | AI trung bình — có kiting | 3 |
| 11-15 | 3 | AI thông minh — prediction, né | 4 |
| 16-19 | 4 | AI rất thông minh — full skills | 5 |
| **20** | **BOSS** | **10M HP, laser, rage sweep** | 5 |

## Có gì mới trong v3.6

- **Fix crash nghiêm trọng**: ấn nút "VƯỢT ẢI" ở sảnh chờ không còn văng game.
- **Fix double-count mạng**: `player_deaths_this_stage` tăng 2 lần/lần chết → player fail sớm. Sửa đúng số mạng quy định.
- **Fix double-count địch**: `stage_alive_ai` giảm 2 lần/AI chết → HUD hiển thị sai số địch. Sửa đúng tiến độ ải.

Chi tiết xem [CHANGELOG.md](CHANGELOG.md).

## Cài đặt & chạy

### Yêu cầu
- [Godot 4.7](https://godotengine.org/download) (Standard)
- GPU OpenGL 3.3+ / GLES3

### Chạy từ source
```bash
git clone https://github.com/mhieuhonda/phitieudichchuyen.git
cd phitieudichchuyen
godot --path .  # Mở project, F5 để chạy
```

### Build (export)
1. Mở project trong Godot 4.7
2. **Project → Export...**
3. Chọn preset: Android / Windows Desktop / Linux/X11
4. **Export Project...** → lưu vào `build/`

## Cấu trúc dự án

```
phitieudichchuyen/
├── project.godot          # Godot config (6 autoloads, v3.6)
├── export_presets.cfg     # 3 export presets (Android/Win/Linux)
├── README.md
├── CHANGELOG.md
├── LICENSE
├── scenes/                # 17 .tscn files
├── scripts/               # 24 .gd files
└── assets/
    ├── sprites/           # Boss.png, AnhNen.png, characters/, dart, ...
    └── audio/
        ├── sfx/           # ~155 sound effects (.wav)
        └── music/         # 5 music tracks
```

### Autoload singletons

| Singleton | Vai trò |
|---|---|
| `SettingsManager` | Settings, device detection, UI layout |
| `GameManager` | Stage state, score, HP, zone, vật lý |
| `AudioManager` | 16-voice SFX pool + music |
| `CharacterData` | 12 characters database |
| `I18N` | Vietnamese / English translations |
| `StageManager` | 20-stage progression, save/load tiến độ |

## Nhân vật (12)

Tất cả nhân vật đều mở khóa sẵn. Mỗi nhân vật có bonus HP / Speed / Dart.

| Loại | HP | Speed | Dart | Số lượng |
|---|---|---|---|---|
| Chiến Binh | +10..+15 | +0..+10 | +0 | 3 |
| Pháp Sư | -5..+5 | +5..+15 | +1..+2 | 3 |
| Quyền Sư | +25..+30 | -10..+0 | +0 | 2 |
| Sát Thủ | -15..-5 | +15..+30 | +0 | 4 |

## Đa ngôn ngữ

Game hỗ trợ **Tiếng Việt** (mặc định) và **English**. Đổi trong **Settings → NGÔN NGỮ**.

## Lịch sử phiên bản

| Version | Tóm tắt |
|---|---|
| **3.6** | Fix crash khi ấn VƯỢT ẢI + sửa double-count mạng/địch |
| 3.5 | Vượt 20 ải · Boss 10M HP với laser + rage sweep · Lưu tiến độ local · Fix kill-steal |
| 3.4 | 2 nút tròn (Xanh dịch / Đỏ ném). Xóa 3 skills. AnhNen.png. Shockwave + screen flash |
| 3.3 | Code-based UI. Vật lý mới (ricochet, knockback). AI thông minh hơn |
| 3.0 | Phiên bản Offline hoàn toàn |
| 2.8 | Fix 15 bugs + thêm 5 features (combo, perf overlay, pause menu, death recap) |

## Công nghệ

- **Engine**: Godot 4.7 (Mobile profile)
- **Ngôn ngữ**: GDScript 2.0
- **Physics**: 2D, 6 layers + ricochet + knockback
- **Audio**: 16-voice pool, WAV, lazy-loading, ~155 variations
- **Localization**: Custom I18N (VI/EN)
- **CI/CD**: GitHub Actions (build 3 platforms)

## License

Xem [LICENSE](LICENSE).

## Đóng góp

Mọi góp ý / bug report / feature request — tạo issue tại:
<https://github.com/mhieuhonda/phitieudichchuyen/issues>

---

<p align="center">
  <strong>Phi Tiêu Dịch Chuyển v3.6</strong><br>
  <em>Vượt 20 ải · Tiêu diệt Boss cuối</em>
</p>
