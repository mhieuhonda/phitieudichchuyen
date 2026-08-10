# Phi Tiêu Dịch Chuyển

> Vượt 20 ải · Ném phi tiêu · Dịch chuyển · Tiêu diệt Boss
> Game 2D top-down offline, Godot 4.7.

![Version](https://img.shields.io/badge/version-3.7-gold.svg)
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

### Thế giới (v3.7 meta-game)

| Hệ thống | Mô tả |
|---|---|
| **4 vùng** | Rừng Thông, Núi Băng, Vương Quốc RuY Băng, Đế Quốc Kẹo. Mỗi vùng có 1 quán rượu. |
| **10 loài động vật** | 6 loài chính (Gấu, Mèo, Ngựa, Thỏ, Chuột, Cáo) + 4 loài phụ (Hươu, Sư Tử, Sói, Chó). Mỗi loài có chỉ số gốc Magic/Physical/Agility tổng = 6. |
| **Class Player** | Player là quái đột biến (1/1/1). Mua class từ Tiền Bối (200 HL Coin). Đổi class cần mặt nạ (150 HL Coin). Đổi class không thay đổi chỉ số player. |
| **Thủ lĩnh** | 10 thủ lĩnh, mỗi loài 1 con. Vị trí cố định theo lore (Cáo ở chòi canh rừng thông, Gấu ở lâu đài đế quốc kẹo, v.v.). Dạy skill cho player duy nhất khi cùng class (100 HL Coin). |
| **Quán rượu** | Nơi nhận quest + chiêu mộ đồng đội. NPC random mỗi lần vào. |
| **Chiêu mộ đồng đội** | 3 cấp sao: 1★ (tổng 8, 1 skill), 2★ (tổng 10, 2 skill), 3★ (tổng 12, có ultimate, số lượng có hạn). Tối đa 5 thành viên (player + 4). Sau khi hoàn thành quest, đồng đội lấy phí thuê + chiến lợi phẩm rồi rời đi. |
| **Uy tín** | −100..100 cho mỗi loài. Cao → dễ chiêu mộ. Thất bại chiêu mộ → giảm uy tín. |
| **Độ thân mật** | 0..100 cho từng NPC 3 sao. Cao → có thể học skill đặc biệt. |
| **HL Coin** | Tiền tệ trong game. Kiếm từ kill AI (15), kill boss (500), quest, thành tựu. Dùng để mua class, mặt nạ, thuê người, học skill. |
| **Nội chiến** | Event ngẫu nhiên (5% mỗi ngày trong game) → giảm uy tín tạm thời. |
| **Thành tựu** | 14 thành tựu, mỗi cái thưởng HL Coin. |

## Điều khiển

| Hành động | PC | Mobile |
|---|---|---|
| Di chuyển | WASD / ← ↑ ↓ → | Joystick trái |
| Nhắm & ném | Chuột phải (kéo → thả) | Nút **NÉM** (đỏ, tròn) |
| Dịch chuyển | Space | Nút **DỊCH** (xanh, tròn) |
| Tạm dừng | P / ESC | — |

## Có gì mới trong v3.7

### Sửa lỗi
- **Fix laser boss không gây sát thương**: lỗi `abs(Vector2)` trả về Vector2 thay vì scalar, khiến so sánh `dist_perp > width * 0.5` không bao giờ đúng → laser không damage ai. Đã sửa bằng `.length()`.
- **Fix laser chỉ trúng player[0]**: nếu player[0] chết hoặc chưa spawn, laser không damage ai khác. Đã sửa iterate qua TẤT CẢ player trong group.

### Cân bằng
- **Boss ải 20**: sát thương từ 4x → **< 4x player** (player dart = 25, 4x = 100, boss = 80). Laser đốt **liên tục** mỗi frame (80 dmg/s rìa, 160 dmg/s center — vẫn < 4x = 400/s).
- **Boss HP**: 10M → 12M (bù lại vì laser đã fix sát thương đúng).
- **Tăng độ khó ải**: AI dodge/accuracy/kiting/pursuit tăng nhanh hơn. HP/damage mult cao hơn. Số mạng/ải giảm (3→2 ở ải đầu, 5→4 ở ải boss).

### Thêm mới
- **Chế độ Thế Giới** với 4 vùng, 10 loài, hệ thống class/đồng đội/HL Coin/uy tín/thành tựu.
- 5 scene UI mới: World Map, Tavern, Predecessor Shop, Skill Master, Quest Log.
- 3 autoload mới: `SpeciesData`, `ProgressionManager`, `WorldManager`.
- 14 thành tựu + 4 sự kiện nội chiến loài.

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
├── project.godot          # Godot config (9 autoloads, v3.7)
├── export_presets.cfg
├── README.md
├── CHANGELOG.md
├── LICENSE
├── scenes/                # 22 .tscn files (17 cũ + 5 mới v3.7)
├── scripts/               # 27 .gd files (24 cũ + 3 autoloads mới v3.7)
└── assets/
    ├── sprites/
    └── audio/
```

### Autoload singletons (v3.7)

| Singleton | Vai trò |
|---|---|
| `SettingsManager` | Settings, device detection, UI layout |
| `GameManager` | Stage state, score, HP, zone, vật lý |
| `AudioManager` | 16-voice SFX pool + music |
| `CharacterData` | 12 characters database |
| `I18N` | Vietnamese / English translations |
| `StageManager` | 20-stage progression, save/load tiến độ |
| `SpeciesData` | **v3.7** — 10 loài + chỉ số gốc |
| `ProgressionManager` | **v3.7** — Level, HL Coin, uy tín, intimacy, achievements |
| `WorldManager` | **v3.7** — 4 vùng, quán rượu, thủ lĩnh, tiền bối |

## Lịch sử phiên bản

| Version | Tóm tắt |
|---|---|
| **3.7** | Fix laser hitbox · Rebalance boss < 4x player · Tăng độ khó ải · Thêm chế độ Thế Giới (4 vùng, 10 loài, class, đồng đội, HL Coin, uy tín, thành tựu) |
| 3.6 | Fix crash khi ấn VƯỢT ẢI + sửa double-count mạng/địch |
| 3.5 | Vượt 20 ải · Boss 10M HP với laser + rage sweep · Lưu tiến độ local · Fix kill-steal |
| 3.4 | 2 nút tròn (Xanh dịch / Đỏ ném). Xóa 3 skills. AnhNen.png. Shockwave + screen flash |
| 3.3 | Code-based UI. Vật lý mới (ricochet, knockback). AI thông minh hơn |

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
  <strong>Phi Tiêu Dịch Chuyển v3.7</strong><br>
  <em>Vượt 20 ải · Thế giới 4 vùng · 10 loài động vật</em>
</p>
