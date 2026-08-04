# 🎯 Phi Tiêu Dịch Chuyển v2.7

> **Ném phi tiêu - Dịch chuyển - Nuốt đối thủ!**
>
> Game 2D top-down arena được xây dựng bằng Godot Engine 4.7 — với **Online Multiplayer**, **14 Nhân Vật**, và **Premium UI**!

![Version](https://img.shields.io/badge/version-2.7-blue)
![Godot](https://img.shields.io/badge/Godot-4.7%20stable-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20PC%20%7C%20Linux-green)
![Status](https://img.shields.io/badge/status-Stable-brightgreen)
![Multiplayer](https://img.shields.io/badge/multiplayer-Online%20%2B%20Offline-orange)
![Characters](https://img.shields.io/badge/characters-14-purple)

---

## 🆕 Tính Năng v2.7 — Ma Tôn + Bug Fixes + Zombie Overhaul + Premium UI

### 👑 Nhân Vật Mới: Ma Tôn — Ma Vương Siêu Cấp

Nhân vật siêu cấp khắc chế hoàn toàn **Hieu Louis - Classic**:

| Chỉ số | Classic (id=12) | **Ma Tôn (id=13)** | Lợi thế |
|--------|-----------------|---------------------|---------|
| HP Bonus | +500 | **+1000** | 2× |
| Speed Bonus | +50 | **+80** | 1.6× |
| Dart Bonus | 100 | **200** | 2× |
| Skill | Crown (ghim 5 đối thủ) | **Ma Tôn Quyền** (instant-kill Classic, immune Crown, +100% score) | Siêu việt |
| Spawn Invul | 3s glitch | **5s bất tử** | 1.67× |
| Color | Hacker Green | **Supernatural Purple** | 👑 |

**Cách mở khóa**: Settings → Nhập Mã Quà Tặng → nhập `maton99` → Đổi Mã

**Ma Tôn Quyền** — Kỹ năng đặc biệt:
- Instant-kill bất kỳ nhân vật Classic nào trúng đạn
- Miễn nhiễm hoàn toàn với Crown Skill
- +100% score multiplier khi active
- 5 giây bất tử khi spawn (vs Classic 3s)

### 🐛 6 Bug Fixes Nghiêm Trọng

| # | Bug | Mô tả | Fix |
|---|-----|-------|-----|
| 1 | **Level softlock** | Zombie thoát khỏi màn hình → level không complete được | Đếm zombie escaped, điều chỉnh completion check |
| 2 | **Pickups undetectable** | Remote player không nhặt được pickup (sai collision_mask) | Thêm layer 64 vào pickup collision_mask |
| 3 | **Stale killer name** | Sau respawn, killer name cũ vẫn hiện | Reset `last_killer_name` trong `_respawn()` |
| 4 | **Invincibility leak** | Shield/Invincible mang qua level mới | Reset `invincible_remaining` trong `reset_temporary_skills()` |
| 5 | **Missing refill_darts** | EndlessPlayer thiếu method, crash nếu có pickup | Thêm `refill_darts()` method |
| 6 | **Dart crash on free** | EndlessDart crash nếu freed trong spawn immunity | Thêm `is_instance_valid` check sau await |

### 🧟 Zombie Graphics Overhaul — 6 Hệ Thống Visual

1. **Scary Color Palettes** — Mỗi zombie type có màu riêng rẽ, đáng sợ hơn
2. **Wobble Animation** — Chuyển động S-shape, mỗi type có "tính cách" riêng
3. **Damage Flash** — Flash trắng-vàng khi bị hit
4. **Freeze/Ice Effect** — Xanh nhạt + scale pulse khi đóng băng
5. **BRUTE Pulsing Glow** — Glow oscillating cho zombie to nhất
6. **Dramatic Death** — 6-phase death animation (flash → expand → dark → splat → fade → free)

### 🎨 Premium UI Redesign — Dark Luxury Theme

Toàn bộ 14 UI files được redesign với:
- **Color Palette**: Deep dark + Gold accent + Cyan + Purple
- **StyleBoxFlat Buttons**: Rounded corners, gradient, hover glow, press feedback
- **Font Shadows**: Tất cả labels có shadow tạo chiều sâu
- **Panel Styling**: Semi-transparent dark + purple border + drop shadow
- **Hover Effects**: Tween-based scale animation trên mọi button
- **HP Bar**: Dynamic gradient (green → yellow → red)
- **Kill Feed**: Fade-out messages mượt mà

---

## 🥷 14 Nhân Vật Độc Đáo

| # | Tên | Loại | Đặc điểm | Kỹ năng riêng |
|---|------|------|-----------|---------------|
| 1 | Rồng Đỏ | Chiến Binh | +15 HP | Dash mạnh hơn 20% |
| 2 | Phượng Xanh | Pháp Sư | +1 Phi tiêu | Multishot bắn 4 phi tiêu |
| 3 | Hổ Vàng | Quyền Sư | +25 HP | Shield lâu hơn 50% |
| 4 | Báo Lục | Sát Thủ | +20 Tốc độ | Dash cooldown giảm 30% |
| 5 | Sói Tím | Chiến Binh | +10 HP, +5 Tốc độ | Dash để lại vệt tối |
| 6 | Cáo Hồng | Pháp Sư | +1 Phi tiêu, +15 Tốc độ | Phi tiêu homing nhẹ |
| 7 | Gấu Nâu | Quyền Sư | +30 HP | Shield phản damage 20% |
| 8 | Diều Cam | Sát Thủ | +15 Tốc độ | Dash xuyên đối thủ |
| 9 | Cọp Xanh | Chiến Binh | +10 HP, +10 Tốc độ | Dash tạo sóng nước |
| 10 | Chồn Bạc | Sát Thủ | +25 Tốc độ | Dash 2 lần liên tiếp |
| 11 | Thiên Long | Pháp Sư | +2 Phi tiêu | Multishot bắn 5 phi tiêu |
| 12 | Hắc Vũ | Sát Thủ | +30 Tốc độ | Dash vô hình 1s |
| 13 | Hieu Louis - Classic | Hacker | +500 HP, +50 Tốc độ, 100 Dart | Crown Skill + SMG + Spawn Invul 3s |
| 14 | **Ma Tôn** | **Ma Tôn** | **+1000 HP, +80 Tốc độ, 200 Dart** | **Ma Tôn Quyền + Spawn Invul 5s** |

### Mã Quà Tặng

| Mã | Mở khóa |
|----|---------|
| `hieulouis99` | Hieu Louis - Classic (id=13) |
| `maton99` | **Ma Tôn** — Ma Vương Siêu Cấp (id=14) |
| `hieulouisking` | Admin Guide trong Hướng Dẫn |

---

## 🧟 Chế Độ Vượt Ải — 500 Level

- 500 level với độ khó tăng dần
- 3 loại zombie: Walker (chậm), Runner (nhanh), Brute (mạnh)
- 15 kỹ năng mở khóa dần theo level
- Đồ họa zombie đã được overhauled hoàn toàn (v2.7)
- Horror sound effects đặc biệt

### 15 Kỹ Năng Vượt Ải

| # | Kỹ năng | Mô tả | Unlock Level |
|---|---------|-------|-------------|
| 1 | Bắn nhanh | CD -50% 5s | 1 |
| 2 | Hồi máu | +30 HP | 1 |
| 3 | Khiên | Miễn damage 3s | 3 |
| 4 | Multishot | 8s bắn 3 phi tiêu | 5 |
| 5 | Đóng băng | Đóng băng zombie 2s | 8 |
| 6 | Bomb | Nổ AOE | 12 |
| 7 | Tăng tốc | Speed +50% 5s | 15 |
| 8 | Xuyên phá | Phi tiêu xuyên zombie 8s | 20 |
| 9 | Hút máu | +5 HP/kill 10s | 25 |
| 10 | Chậm thời gian | Slow zombie 3s | 30 |
| 11 | Tự tìm | Homing darts 8s | 40 |
| 12 | Nổ dây chuyền | Chain explosion 8s | 50 |
| 13 | Cuồng nộ | Damage x2 5s | 75 |
| 14 | Nuke | Kill all zombies | 100 |
| 15 | Bất tử | Invincible 5s | 150 |

---

## 🎮 Cách Chơi

1. **Ném phi tiêu** (chuột phải / nút Ném) → nhắm và ném phi tiêu vào đối thủ
2. **Dịch chuyển** (Space / nút Dịch Chuyển) → dịch chuyển tức thời đến vị trí phi tiêu
3. **Ăn đối thủ** → dịch chuyển đến gần đối thủ để tiêu diệt và thu thập điểm
4. **Thu thập** → nhặt vật phẩm hồi máu và tăng phi tiêu
5. **Sinh tồn** → tránh vòng bo thu nhỏ, sống sót đến cuối trận!

## 🌐 Chơi Online

### Cách kết nối
1. Mở game → **Chơi Ngay** → **Chơi Online**
2. Game tự động kết nối đến Relay Server
3. Đợi ghép trận (10-20 người)
4. Nếu 30 giây không đủ người → bot AI tự fill
5. Trận bắt đầu sau 5 giây countdown!

### Relay Server

```
API Endpoints:
  GET /health           → Server health check
  GET /api/status       → Server status + room list
  GET /api/leaderboard  → Top 20 players by score
  GET /api/player/:id   → Player stats
```

### Deploy Relay Server

```bash
docker-compose up -d

# Hoặc pull từ GHCR
docker pull ghcr.io/mhieuhonda/phitieu-relay:latest
docker run -d -p 25671:25671 -p 25672:25672 \
  -v phitieu-data:/app/data \
  ghcr.io/mhieuhonda/phitieu-relay:latest
```

---

## 🛠️ Kỹ Năng (Offline Mode)

| Kỹ năng | Phím | Cooldown | Mô tả |
|---------|------|----------|-------|
| Dash | Q | 8s | Lao về phía trước với tốc độ cao |
| Shield | E | 15s | Miễn damage trong 3 giây |
| Multishot | Shift | 12s | Lần ném tiếp theo bắn 3 phi tiêu cùng lúc |
| Crown | C | 50s | Ghim 5 đối thủ + +50% điểm (Classic only) |

---

## 🕹️ Điều Khiển

### PC
| Phím | Hành động |
|------|-----------|
| WASD / ←↑↓→ | Di chuyển |
| Chuột phải | Nhắm & ném phi tiêu |
| Space | Dịch chuyển đến phi tiêu |
| Q | Dash |
| E | Shield |
| Shift | Multishot |
| C | Crown Skill (Classic only) |
| R | Restart |
| ESC | Quay lại menu |

### Mobile
- Joystick ảo (trái): Di chuyển
- Nút Ném (phải): Nhắm & ném phi tiêu
- Nút Dịch Chuyển: Dịch chuyển đến phi tiêu
- Nút Dash / Shield / Multishot: Kỹ năng

---

## 🏗️ Công Nghệ

- **Engine**: Godot 4.7 stable
- **Ngôn ngữ**: GDScript (modern 4.7 idioms)
- **Networking**: WebSocket (Godot WebSocketPeer ↔ Node.js ws)
- **Relay Server**: Node.js 20 + ws + better-sqlite3
- **Database**: SQLite (WAL mode) cho player stats
- **Nền tảng**: Android, PC (Windows/Linux), Web
- **CI/CD**: GitHub Actions — 3 parallel build jobs
- **Container**: Docker + GHCR (GitHub Container Registry)
- **Âm thanh**: 155+ sound effects + 5 nhạc nền + horror SFX
- **Physics**: 7 collision layers (Player, Dart, Wall, AI, Obstacle, Pickup, RemotePlayer)
- **I18N**: Tiếng Việt / English

---

## 📁 Cấu Trúc Dự Án

```
phitieudichchuyen/
├── .github/workflows/
│   └── build-release.yml    # Parallel CI/CD
├── assets/
│   ├── audio/               # 155+ SFX + 5 music + horror SFX
│   └── sprites/characters/  # 14 characters + 10 AI sprites
├── relay-server/
│   ├── server.js            # WebSocket relay + matchmaking + SQLite
│   ├── package.json
│   ├── Dockerfile
│   └── .dockerignore
├── scenes/                  # 20+ scene files
├── scripts/                 # 20+ GDScript files
├── docker-compose.yml
├── project.godot            # Godot 4.7 config (v2.7)
├── export_presets.cfg
├── icon.svg
├── LICENSE
├── README.md
└── CHANGELOG.md
```

---

## 🚀 Cài Đặt & Chạy

### Yêu cầu
- Godot 4.7 stable (hoặc mới hơn)

### Chạy từ source
```bash
git clone https://github.com/mhieuhonda/phitieudichchuyen.git
cd phitieudichchuyen
# Mở project.godot bằng Godot 4.7
# F5 để chạy game
```

### Export
1. Mở project trong Godot 4.7
2. Project → Export → Add platform
3. Bấm Export Project

### Chạy Relay Server (local test)
```bash
cd relay-server
npm install
node server.js
# WebSocket: ws://localhost:25671/ws
# HTTP API: http://localhost:25672/health
```

---

## 📜 Lịch Sử Phiên Bản

### v2.7 (2026-08-04) — Ma Tôn + Bug Fixes + Zombie Overhaul + Premium UI
- **NEW**: Nhân vật Ma Tôn — Ma Vương Siêu Cấp (khắc chế Classic)
- **NEW**: Gift code `maton99` mở khóa Ma Tôn
- **FIX**: 6 bugs nghiêm trọng (level softlock, pickup collision, stale killer, invincibility leak, missing method, dart crash)
- **VISUAL**: Zombie graphics overhaul — 6 hệ thống visual mới
- **VISUAL**: Premium UI redesign — 14 files, dark luxury theme

### v2.6 (2026-08-04) — Coolify Deployment Fix
- Fix Docker HEALTHCHECK --start-period
- Fix Git repo URL format cho Coolify

### v2.4 (2026-08-04) — Endless Mode + I18N
- Chế độ Vượt Ải (500 level, 15 skills)
- Đa ngôn ngữ Tiếng Việt / English
- Horror sound effects cho zombie mode

### v2.2 (2026-08-04) — Fix Online + Kill Streaks + Daily Login
- Fix online mode, kill streak announcements
- Daily login reward, gift code system

### v2.1 (2026-08-03) — Hieu Louis - Classic
- Nhân vật đặc biệt + Crown Skill + SMG Reward
- Gift code `hieulouis99`

### v2.0 (2026-08-03) — Regression Fixes
- Fix Python docstring parse error
- Full regression audit

### v1.7 (2026-08-03) — Online Multiplayer
- WebSocket multiplayer, matchmaking, relay server

### v1.0 (2026) — Initial Release
- Ném phi tiêu + Dịch chuyển + Ăn đối thủ + 12 nhân vật

---

## 📄 Giấy Phép

Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

<p align="center">
  <b>Phi Tiêu Dịch Chuyển v2.7</b> — Ném phi tiêu, dịch chuyển, nuốt đối thủ!
</p>
