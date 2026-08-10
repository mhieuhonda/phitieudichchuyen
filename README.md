# Phi Tiêu Dịch Chuyển

> **Vượt 20 ải · Ném phi tiêu · Dịch chuyển · Tiêu diệt Boss**
> Game 2D top-down offline, Godot 4.7.

![Version](https://img.shields.io/badge/version-3.5-gold.svg)
![Engine](https://img.shields.io/badge/Godot-4.7-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## Giới thiệu

**Phi Tiêu Dịch Chuyển v3.5** là game 2D top-down offline với cơ chế độc đáo: **ném phi tiêu → dịch chuyển tức thời tới phi tiêu → tiêu diệt đối thủ**. Chế độ chính là **Vượt Ải** — 20 ải với độ khó tăng dần, kết thúc bằng trận chiến với Boss cuối có 10 triệu HP.

### Cơ chế chính

- **Ném phi tiêu** — Kéo chuột phải (hoặc nút **NÉM** mobile) để nhắm & tăng lực. Phi tiêu có thể nảy 1 lần khi chạm tường.
- **Dịch chuyển tức thời** — Space (hoặc nút **DỊCH** mobile) để dịch ngay tới phi tiêu gần nhất, tạo knockback cho kẻ địch xung quanh.
- **Tiêu diệt đối thủ** — Dịch chuyển đến gần AI trong bán kính 50px để tiêu diệt.
- **Vượt ải** — Tiêu diệt tất cả AI/Boss trong ải để vượt. Càng ải cao, AI càng thông minh.
- **Boss cuối (Ải 20)** — 10M HP, bắn laser liên tục (đứng giữa tia = 2x damage), có cảnh báo trước khi bắn. Khi còn 10% HP → rage mode với chiêu quét quay vòng. Dịch chuyển tới boss = 250k damage/lần.

---

## Có gì mới trong v3.5

- **🎮 Chế độ Vượt Ải (20 ải)** — Thay thế chế độ PvP 5 phút. Ải 1-19 đấu với AI (1→4 quái, độ khó tăng dần), ải 20 là Boss cuối.
- **👹 Boss cuối (10M HP)** — Dùng `Boss.png` làm sprite. Laser có pha cảnh báo (tia mờ mờ) trước khi bắn, đứng giữa tia = sát thương gấp đôi. Rage mode ở 10% HP với chiêu quét 360°.
- **💾 Lưu tiến độ local** — `user://progress.cfg` lưu ải đã mở khóa, best time mỗi ải, số lần thử, tổng số chết, số boss đã giết.
- **⚖️ Cân bằng lại** — Fix lỗi đớp kill liên tục: AI chỉ tấn công player, không tấn công AI khác. AI teleport không còn instakill player (chỉ 80 damage).
- **🎯 Sát thương boss** — Dịch chuyển tới boss = 250k damage (40 lần dịch chuyển để giết). Dart trúng boss = 6.25 chip damage.
- **🔊 Sound effects cho boss** — spawn, laser warning, laser fire, rage roar, sweep whoosh, hurt, death.
- **📊 UI mới** — Thanh máu boss lớn trên cùng, label "Ải X/20", số mạng còn lại, panel Vượt ải/Thất bại.
- **🗺️ Màn hình chọn ải** — Xem 20 ải dạng lưới, hiển thị best time, có nút Reset tiến độ.
- **🏠 Respawn thông minh** — Khi chết, respawn ở vị trí xa enemy nhất. Số mạng giới hạn theo ải (3-5 mạng).

---

## Điều khiển

| Hành động | PC | Mobile |
|---|---|---|
| Di chuyển | WASD / ← ↑ ↓ → | Joystick trái |
| Nhắm & ném | Chuột phải (kéo → thả) | Nút **NÉM** (đỏ, tròn) |
| Dịch chuyển | Space | Nút **DỊCH** (xanh, tròn) |
| Tạm dừng | P / ESC | — |
| Quay lại menu | ESC (từ menu) | — |

---

## Cấu trúc ải

| ải | Số AI | Đặc điểm |
|---|---|---|
| 1-5 | 1 | AI ngu — dodge thấp, không kiting |
| 6-10 | 2 | AI trung bình — có kiting, né đôi chút |
| 11-15 | 3 | AI thông minh — prediction, né dart, flee khi HP thấp |
| 16-19 | 4 | AI rất thông minh — full skills, pursuit speed boost |
| **20** | **BOSS** | **10M HP, laser, rage sweep ở 10% HP** |

**Số mạng tối đa mỗi ải**: ải 1-10 = 3 mạng, ải 11-15 = 4 mạng, ải 16-20 = 5 mạng.

---

## Cài đặt & chạy

### Yêu cầu
- [Godot 4.7](https://godotengine.org/download) (Standard)
- GPU hỗ trợ OpenGL 3.3+ / GLES3

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
4. Bấm **Export Project...** → lưu vào `build/`

Export presets có sẵn trong `export_presets.cfg`.

---

## Cấu trúc dự án

```
phitieudichchuyen/
├── project.godot              # Godot config (6 autoloads, version 3.5)
├── export_presets.cfg         # 3 export presets
├── README.md                  # Tài liệu này
├── CHANGELOG.md               # Lịch sử thay đổi
├── LICENSE
├── scenes/                    # Godot scenes (.tscn)
├── scripts/                   # GDScript files (.gd)
└── assets/
    ├── sprites/               # Boss.png, AnhNen.png, characters/, dart, ...
    └── audio/
        ├── sfx/               # ~155 sound effects (.wav)
        └── music/             # 5 music tracks
```

### Autoload singletons

| Singleton | Vai trò |
|---|---|
| `SettingsManager` | Load/save settings, device detection, UI layout |
| `GameManager` | Stage state, score, HP, zone, leaderboard, vật lý |
| `AudioManager` | 16-voice SFX pool + music + ~155 sound variations |
| `CharacterData` | 12 characters database, selected character |
| `I18N` | Vietnamese / English translations |
| `StageManager` | **v3.5**: 20-stage progression, save/load tiến độ |

---

## Đa ngôn ngữ

Game hỗ trợ **Tiếng Việt** (mặc định) và **English**. Đổi trong **Settings → NGÔN NGỮ**.

---

## Nhân vật (12)

Tất cả nhân vật đều mở khóa sẵn. Mỗi nhân vật có bonus HP / Speed / Dart.

| Loại | HP | Speed | Dart | Số lượng |
|---|---|---|---|---|
| Chiến Binh | +10..+15 | +0..+10 | +0 | 3 |
| Pháp Sư | -5..+5 | +5..+15 | +1..+2 | 3 |
| Quyền Sư | +25..+30 | -10..+0 | +0 | 2 |
| Sát Thủ | -15..-5 | +15..+30 | +0 | 4 |

---

## Lịch sử phiên bản

| Version | Tóm tắt |
|---|---|
| **3.5** | Vượt 20 ải · Boss 10M HP với laser + rage sweep · Lưu tiến độ local · Fix kill-steal |
| 3.4 | 2 nút tròn (Xanh dịch / Đỏ ném). Xóa 3 skills. AnhNen.png. Shockwave + screen flash |
| 3.3 | Code-based UI. Vật lý mới (ricochet, knockback). AI thông minh hơn (kiting, prediction) |
| 3.0 | Phiên bản Offline hoàn toàn — xóa Zombie/Online/Guide/Gift Code |
| 2.8 | Fix 15 bugs + thêm 5 features (combo, perf overlay, pause menu, death recap) |

Xem chi tiết tại [CHANGELOG.md](CHANGELOG.md).

---

## Công nghệ

- **Engine**: Godot 4.7 (Mobile profile)
- **Ngôn ngữ**: GDScript 2.0
- **Physics**: 2D, 6 layers + ricochet + knockback
- **Audio**: 16-voice pool, WAV, lazy-loading, ~155 variations
- **Localization**: Custom I18N (VI/EN)
- **CI/CD**: GitHub Actions (build 3 platforms)

---

## License

Xem [LICENSE](LICENSE).

---

## Đóng góp

Mọi góp ý / bug report / feature request — tạo issue tại:
<https://github.com/mhieuhonda/phitieudichchuyen/issues>

---

<p align="center">
  <strong>Phi Tiêu Dịch Chuyển v3.5</strong><br>
  <em>Vượt 20 ải · Tiêu diệt Boss cuối</em>
</p>
