# Phi Tiêu Dịch Chuyển

> Vượt 20 ải · Ném phi tiêu · Dịch chuyển · Tiêu diệt Boss
> Game 2D top-down offline, Godot 4.7.

![Version](https://img.shields.io/badge/version-3.9-gold.svg)
![Engine](https://img.shields.io/badge/Godot-4.7-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down offline với cơ chế độc đáo: **ném phi tiêu → dịch chuyển tức thời tới phi tiêu → tiêu diệt đối thủ**. Có 2 chế độ chính:

- **Vượt Ải** — 20 ải với độ khó tăng dần, kết thúc bằng Boss cuối 12 triệu HP.
- **Thế Giới** — meta-game RPG với 4 vùng, 10 loài, hệ thống class, chiêu mộ đồng đội, HL Coin, uy tín, thành tựu và **Quest scene chơi được** (v3.9).

## Có gì mới trong v3.9

### Quest Mode — Thế Giới giờ có quest chơi được

Trước v3.9, Quest của Thế Giới chỉ là menu — player nhận quest, ấn "Hoàn thành" để nhận thưởng mà không cần đánh. v3.9 thêm **Quest scene chơi được** với 3 loại mục tiêu:

| Loại quest | Cách chơi |
|---|---|
| **kill X** | Tiêu diệt X quái AI (spawn theo wave, độ khó theo tier) |
| **boss mini** | Tiêu diệt 1 mini-boss (AI 4x HP, size lớn) |
| **find target** | Tìm và chạm vào NPC mục tiêu ( Area2D ) |

- Quest tự **hoàn thành ngay** khi đạt mục tiêu → tự quay về quán rượu + nhận thưởng
- 4 tier độ khó: easy / medium / hard / very_hard (scale HP, dmg, dodge, pursuit, max deaths)
- HUD hiển thị mục tiêu + progress (kill X/Y) trên cùng màn hình
- Thất bại (hết mạng) → panel cho "Thử lại Quest" hoặc "Về Quán Rượu"
- **Quest tab mới** trong Sổ Tay (Quest/Stats/Team/Achievements) — xem active + completed

### Meta-progression áp dụng vào combat

Trước v3.9, chỉ số Player (Magic/Physical/Agility), class, team bonus không ảnh hưởng combat. v3.9 wire tất cả vào player:

- **Magic** → +5% dart damage / point
- **Physical** → +5% HP + 2.5% damage / point
- **Agility** → +4% speed, -5% teleport cooldown / point
- **Class main species** → +1 dart, +10% HP
- **Team bonus** → +% HP/damage/speed theo tổng chỉ số đồng đội

### Fix 30 bugs (chi tiết trong CHANGELOG)

Critical fixes:
- **AI damage scale theo stage** — `ai_dmg_mult` config (0.80→1.30) đã được định nghĩa nhưng không bao giờ dùng. Giờ AI ải 19 gây 1.3x damage ải 1.
- **Player dart damage scale theo throw power** — trước đây flat 25 dù ném mạnh hay yếu. Giờ `dmg = base * power * meta_dmg_mult`.
- **Boss HP segments vẽ đúng** — trước đây 1 Line2D với 22 points → vẽ zigzag. Giờ 11 Line2D riêng biệt → đúng vertical lines.
- **Tiền bối không "move" về cùng vùng hiện tại** (25% tỉ lệ trước đây).
- **NPC 1 sao và 3 sao không trùng tên** (cả 2 đều dùng `RECRUIT_NAMES_BY_SPECIES[sid][0]`).
- **Day timer + civil war không tick trong combat** — tránh tụt uy tín không rõ lý do.
- **Bỏ penalty uy tín khi chiêu mộ thất bại** — chống soft-lock.
- **Xóa 2 dead scripts** (`pause_menu.gd`, `death_recap.gd`).
- **Boss.tscn HP 10M → 12M** (đồng bộ với `StageManager.BOSS_MAX_HP`).
- **`dissolve_team_after_quest` comment "10%" sửa thành "5%"** (đúng với code).

### Cân bằng lại toàn diện

- **AI dmg_mult**: 0.80→1.25 → **0.80→1.30** (ải cuối nguy hiểm hơn)
- **AI hp_mult**: 0.90→1.55 → **0.85→1.60** (tránh sponginess giữa, tăng ở cuối)
- **Boss dart damage**: dùng `StageManager.BOSS_DART_DAMAGE` làm single source of truth (DRY fix)
- **Quest difficulty preset**: 4 tier với stats cân bằng cho từng loại quest

## Cơ chế

### Vượt ải (cốt lõi)

| Cơ chế | Mô tả |
|---|---|
| **Ném phi tiêu** | Kéo chuột phải (PC) hoặc nút **NÉM** (mobile) để nhắm & tăng lực. Phi tiêu nảy 1 lần khi chạm tường. |
| **Dịch chuyển** | Space (PC) hoặc nút **DỊCH** (mobile) để dịch tới phi tiêu gần nhất, gây knockback cho địch xung quanh. |
| **Tiêu diệt** | Dịch chuyển đến gần AI trong bán kính 50px để tiêu diệt. |
| **Boss cuối (Ải 20)** | 12M HP, laser đốt liên tục (< 4x sát thương player), rage sweep 540° ở 12% HP. |

### Điều khiển

| Hành động | PC | Mobile |
|---|---|---|
| Di chuyển | WASD / ← ↑ ↓ → | Joystick trái |
| Nhắm & ném | Chuột phải (kéo → thả) | Nút **NÉM** (đỏ, tròn) |
| Dịch chuyển | Space | Nút **DỊCH** (xanh, tròn) |
| Tạm dừng | P / ESC | — |
| Quick retry (khi pause) | R | — |

### Quest Mode (v3.9)

1. Vào **🌍 THẾ GIỚI** → chọn vùng → vào **🍺 Quán Rượu**
2. Tab **Quest Board** → nhận quest (kiểm tra yêu cầu class/đội)
3. Ấn **⚔ Vào Ải** trên quest đang active → vào Quest scene
4. Đạt mục tiêu → quest tự hoàn thành → nhận thưởng + tự về tavern

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
├── project.godot          # Godot config (9 autoloads, v3.9)
├── export_presets.cfg
├── README.md
├── CHANGELOG.md
├── LICENSE
├── scenes/                # 21 .tscn files (quest_log.tscn có Quest tab mới)
├── scripts/               # 31 .gd files (đã xóa pause_menu.gd, death_recap.gd)
└── assets/
    ├── sprites/
    └── audio/
```

### Autoload singletons (v3.9)

| Singleton | Vai trò |
|---|---|
| `SettingsManager` | Settings, device detection, UI layout |
| `GameManager` | Stage + Quest state, score, HP, zone, vật lý, meta-progression combat bonus |
| `AudioManager` | 16-voice SFX pool + music |
| `CharacterData` | 12 characters database |
| `I18N` | Vietnamese / English translations |
| `StageManager` | 20-stage progression + Quest difficulty presets |
| `SpeciesData` | 10 loài + chỉ số gốc |
| `ProgressionManager` | Level, HL Coin, uy tín, intimacy, achievements, quests, team |
| `WorldManager` | 4 vùng, quán rượu, thủ lĩnh, tiền bối |

## Lịch sử phiên bản

| Version | Tóm tắt |
|---|---|
| **3.9** | Quest scene chơi được (kill/boss-mini/find) · Meta-progression áp dụng combat · Fix 30 bugs (AI dmg scale, player dart power scaling, boss HP segments, tiền bối move, NPC names, day timer, dead scripts) · Cân bằng AI dmg/hp curve · Quest tab trong Sổ Tay · 4-tier quest difficulty |
| 3.8 | Combat polish & boss arena quality: Pause menu, minimap, Boss Phase 2, kill streak, hit markers, low-HP heartbeat, boss off-screen arrow, aim ricochet preview, onboarding, 5 achievements mới, perfect/speed bonus, perf optimizations |
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
  <strong>Phi Tiêu Dịch Chuyển v3.9</strong><br>
  <em>Quest scene · Meta-progression combat · Balance overhaul</em>
</p>
