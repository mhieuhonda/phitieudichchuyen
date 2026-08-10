# Phi Tiêu Dịch Chuyển

> Vượt 20 ải · Ném phi tiêu · Dịch chuyển · Tiêu diệt Boss
> Game 2D top-down offline, Godot 4.7.

![Version](https://img.shields.io/badge/version-3.8-gold.svg)
![Engine](https://img.shields.io/badge/Godot-4.7-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down offline với cơ chế độc đáo: **ném phi tiêu → dịch chuyển tức thời tới phi tiêu → tiêu diệt đối thủ**. Chế độ chính là **Vượt Ải** — 20 ải với độ khó tăng dần, kết thúc bằng Boss cuối 12 triệu HP. Từ v3.7, game bổ sung chế độ **Thế Giới** — meta-game RPG với 4 vùng, 10 loài động vật, hệ thống class, chiêu mộ đồng đội, HL Coin, uy tín, thành tựu.

## Cơ chế

### Vượt ải (cốt lõi)

| Cơ chế | Mô tả |
|---|---|
| **Ném phi tiêu** | Kéo chuột phải (PC) hoặc nút **NÉM** (mobile) để nhắm & tăng lực. Phi tiêu nảy 1 lần khi chạm tường. |
| **Dịch chuyển** | Space (PC) hoặc nút **DỊCH** (mobile) để dịch tới phi tiêu gần nhất, gây knockback cho địch xung quanh. |
| **Tiêu diệt** | Dịch chuyển đến gần AI trong bán kính 50px để tiêu diệt. |
| **Boss cuối (Ải 20)** | 12M HP, laser đốt liên tục (< 4x sát thương player, center = 2x), rage sweep 360° ở 12% HP. |

### Điều khiển

| Hành động | PC | Mobile |
|---|---|---|
| Di chuyển | WASD / ← ↑ ↓ → | Joystick trái |
| Nhắm & ném | Chuột phải (kéo → thả) | Nút **NÉM** (đỏ, tròn) |
| Dịch chuyển | Space | Nút **DỊCH** (xanh, tròn) |
| Tạm dừng | P / ESC | — |
| Quick retry (khi pause) | R | — |

## Có gì mới trong v3.8

### Combat Polish & Boss Arena Quality Update

Bản nâng cấp lớn với **30+ features mới**, **5 achievements mới**, **3 critical bug fixes**, **~2000+ dòng code mới**.

### Sửa lỗi critical
- **Player darts không bị AI né được**: `player.gd::_spawn_single_dart()` thiếu `dart.add_to_group("darts")` → AI `_check_incoming_darts()` không bao giờ thấy dart của player → dodge_chance config vô nghĩa với player. Đã fix.
- **HUD boss HP hiển thị sai**: hardcoded "10,000,000 HP" trong khi `BOSS_MAX_HP` = 12M từ v3.7. Đã dùng dynamic text + `_format_big_number()` helper.
- **Boss double-laser spawn**: `_choose_next_action()` có thể spawn laser thứ hai khi laser đầu còn active. Đã check `is_instance_valid(active_laser)` trước.

### Combat & Boss Features
- **Boss Phase 2 (50% HP)**: boss bắn 3-dart spread thay vì 1, move_speed +25%, dart interval 2.5s→1.8s. Banner "PHASE 2!" khi kích hoạt.
- **Boss dramatic entrance**: 3-wave particle burst + big screen shake khi boss spawn.
- **Boss laser charge telegraph**: particles bay về phía boss trong 1s charge phase, báo hướng laser sẽ bắn.
- **Boss laser color tint theo phase**: Phase 1 = đỏ, Phase 2 = cam, Rage = trắng-rực.
- **Boss HP bar shake** khi nhận damage.
- **Boss phase badge**: "PHASE 1" / "PHASE 2" / "⚠ RAGE" bên trái HP bar.
- **Boss dramatic multi-stage death**: 7-wave explosion với color shift red→orange→yellow→white.
- **AI dodge burst**: `_ai_dash()` reactivated — vận tốc tức thời 380 units/s với 1.2s cooldown.
- **AI teleport warning sound**: 70% chance phát warning SFX trước khi AI teleport.
- **AI hit spark + scale punch**: 8 particle burst + scale 1.15x khi AI bị hit.

### UI/UX Features
- **Pause menu** (code-based): P/ESC mở overlay với 4 nút. R = quick retry.
- **Minimap radar**: 140x140px panel ở góc phải hiển thị player, AI, boss, darts, zone.
- **Stage transition animation**: fade-to-black + label "ẢI X" khi chuyển ải.
- **Stage intro banner**: "ẢI X — KHỞI ĐẦU/TRUNG BÌNH/KHÓ/RẤT KHÓ" khi bắt đầu stage.
- **Stage time warning**: banner "⏰ HÃY NHANH LÊN!" khi stage time > 5 phút.
- **Low-HP vignette + Heartbeat**: tint đỏ pulse + sound heartbeat khi HP < 30%.
- **Low-HP health pickup arrow**: mũi tên xanh chỉ hướng health pickup gần nhất.
- **Kill streak UI**: DOUBLE/TRIPLE/QUADRA/PENTA KILL, KILLING SPREE, UNSTOPPABLE, GODLIKE.
- **Hit marker**: ✕ symbol center-top khi dart trúng AI/boss.
- **Boss HP segments + % label**: 11 vạch chia HP bar + % lớn bên dưới.
- **Boss off-screen arrow**: mũi tên đỏ chỉ hướng boss khi ngoài tầm nhìn.
- **Aim ricochet preview**: line preview bending tại điểm chạm tường.
- **Dart glow power-scale**: glow color & intensity scale theo throw power.
- **Onboarding hints**: panel hướng dẫn controls ở ải 1.
- **Stage stats display**: time, PB 🏆, attempts, lives, perfect/speed bonus.
- **Reset confirm dialog**: hỏi xác nhận trước khi xóa tiến độ.
- **Difficulty color coding** trong stage_select.
- **Achievement toast notifications**: popup khi unlock achievement.
- **Coin pickup feedback**: floating "+X 💰" + gold particle burst.
- **Heal effect**: heart icon + green particle burst khi nhặt health.
- **Pickup burst effect**: particle burst khi nhặt vật phẩm.

### Reward Systems
- **Perfect Stage bonus**: không chết = (50 + stage * 10) HL Coin.
- **Speed bonus**: hoàn thành dưới 60s = (30 + (60 - elapsed)) HL Coin.
- **Kill streak bonus**: 3=10, 5=25, 7=50, 10=100, +100 mỗi 5 sau 10.
- **Best kill streak stat**: tracking kill streak cao nhất.
- **5 achievements mới**: kill_streak_5/10, perfect_stage, speed_runner, all_stages_clear.

### Settings UI (v3.8 section)
5 toggles mới trong Settings menu (saved/loaded qua ConfigFile):
- Hit Markers | Kill Streak | Low-HP Vignette | Boss Off-screen Arrow | Minimap Radar

### Tối ưu hiệu năng
- Cache dart count: gộp `_get_dart_info()` + `_has_flying_darts()` thành `_get_dart_stats()`.
- Dùng `GameManager.stage_alive_ai` thay vì lặp qua group `ai_players` mỗi frame.
- AudioManager: stop stream trước khi reuse pool player (tránh audio pop).
- Pickup cleanup: interval 1 giây thay vì mỗi frame.
- Player.gd: thêm `class_name Player` để type-check an toàn.

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
├── project.godot          # Godot config (9 autoloads, v3.8)
├── export_presets.cfg
├── README.md
├── CHANGELOG.md
├── LICENSE
├── scenes/                # 22 .tscn files
├── scripts/               # 28 .gd files
└── assets/
    ├── sprites/
    └── audio/
```

### Autoload singletons (v3.8)

| Singleton | Vai trò |
|---|---|
| `SettingsManager` | Settings, device detection, UI layout |
| `GameManager` | Stage state, score, HP, zone, vật lý |
| `AudioManager` | 16-voice SFX pool + music |
| `CharacterData` | 12 characters database |
| `I18N` | Vietnamese / English translations |
| `StageManager` | 20-stage progression, save/load tiến độ |
| `SpeciesData` | 10 loài + chỉ số gốc |
| `ProgressionManager` | Level, HL Coin, uy tín, intimacy, achievements |
| `WorldManager` | 4 vùng, quán rượu, thủ lĩnh, tiền bối |

## Lịch sử phiên bản

| Version | Tóm tắt |
|---|---|
| **3.8** | Combat polish & boss arena quality: Pause menu, minimap, Boss Phase 2, kill streak, hit markers, low-HP heartbeat, boss off-screen arrow, aim ricochet preview, onboarding, 5 achievements mới, perfect/speed bonus, perf optimizations |
| 3.7 | Fix laser hitbox · Rebalance boss < 4x player · Tăng độ khó ải · Thêm chế độ Thế Giới (4 vùng, 10 loài, class, đồng đội, HL Coin, uy tín, thành tựu) |
| 3.6 | Fix crash khi ấn VƯỢT ẢI + sửa double-count mạng/địch |
| 3.5 | Vượt 20 ải · Boss 10M HP với laser + rage sweep · Lưu tiến độ local · Fix kill-steal |
| 3.4 | 2 nút tròn (Xanh dịch / Đỏ ném). Xóa 3 skills. AnhNen.png. Shockwave + screen flash |

## Công nghệ

- **Engine**: Godot 4.7 (Mobile profile)
- **Ngôn ngữ**: GDScript 2.0
- **Physics**: 2D, 6 layers + ricochet + knockback
- **Audio**: 16-voice pool, WAV, lazy-loading, ~155 variations
- **Localization**: Custom I18N (VI/EN)
- **Save**: ConfigFile local (user://progress.cfg, user://progression.cfg, user://character_data.cfg)

## License

Xem [LICENSE](LICENSE).

## Đóng góp

Mọi góp ý / bug report / feature request — tạo issue tại:
<https://github.com/mhieuhonda/phitieudichchuyen/issues>

---

<p align="center">
  <strong>Phi Tiêu Dịch Chuyển v3.8</strong><br>
  <em>Vượt 20 ải · Combat polish · Boss arena quality</em>
</p>
