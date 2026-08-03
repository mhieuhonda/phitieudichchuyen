# 🎯 Phi Tiêu Dịch Chuyển v1.9

> **Ném phi tiêu - Dịch chuyển - Nuốt đối thủ!**
>
> Game 2D top-down arena được xây dựng bằng Godot Engine 4.7 — giờ đã có **Online Multiplayer**!

![Version](https://img.shields.io/badge/version-1.9-blue)
![Godot](https://img.shields.io/badge/Godot-4.7%20stable-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20PC%20%7C%20Linux-green)
![Status](https://img.shields.io/badge/status-Stable-brightgreen)
![Multiplayer](https://img.shields.io/badge/multiplayer-Online%20%2B%20Offline-orange)

---

## 🆕 Tính Năng v1.9 — Fix Lỗi APK Corrupted!

Bản v1.9 tập trung sửa lỗi nghiêm trọng: **APK v1.8 báo "Gói dường như bị hỏng"** khi tải về cài đặt trên Android.

### 🔥 Fix Lỗi APK "Gói dường như bị hỏng"

**Nguyên nhân**: APK v1.8 được Godot export ra **không có chữ ký số** (no v1/v2/v3 signature). Android từ chối cài đặt APK không ký → báo "package seems corrupted".

**Cách fix**: CI workflow thêm 2 step sau khi Godot export:

1. `zipalign` — Căn chỉnh 4-byte cho .so files
2. `apksigner sign` — Ký APK với v1+v2+v3 signature schemes

APK v1.9 giờ đã ký đúng chuẩn, cài đặt trên Android không còn báo lỗi.

### 🐛 Bug Fixes Khác

- **NetworkManager**: `get_latency()` luôn return 0; `_try_reconnect` stack-up timers; `disconnect_from_server()` không phân biệt user-initiated vs network-drop
- **ModeSelect/Matchmaking/MainOnline**: Signal leaks khi rời scene → crash "Invalid access to freed instance"
- **AIPlayer**: `_find_nearest_player` không check `is_instance_valid`; `target_player` không guard trong HUNTING/FLEEING; `kill()` respawn timer không guard
- **Player**: `_die()` respawn timer không guard
- **HUD**: Filter `ai_players` không check `is_instance_valid`; `_on_dart_thrown` lambda truy cập freed node
- **Main/MainOnline**: Screen shake chia 0 khi `duration=0`

---

## 🆕 Tính Năng v1.7 — Chơi Online!

### 🌐 Multiplayer Real-Time

Bản v1.7 biến game thành **online multiplayer** với hệ thống matchmaking tự động:

- **Mode Selection**: Ấn "Chơi Ngay" → chọn **Online** hoặc **Offline**
- **Online**: Ghép trận 10-20 người chơi thật qua Relay Server
- **Offline**: Chơi với AI bots như các bản trước
- **Matchmaking**:
  - Tối thiểu 10 người, tối đa 20 người mỗi phòng
  - 30 giây timeout → tự thêm bot AI nếu chưa đủ 10 người
  - 5 giây countdown trước khi trận bắt đầu
- **State Sync**: Đồng bộ vị trí, HP, size, score, kills, darts, skills ở 20 ticks/giây
- **Relay Server**: WebSocket server Node.js + SQLite database cho player stats

### ⚡ GitHub Actions Parallel Builds

Workflow build 3 nền tảng **song song** (Android, Windows, Linux) → tốc độ build tăng 2-3x:

```
┌─ Build Android ─┐
├─ Build Windows ──┤  ← chạy đồng thời
├─ Build Linux ────┤
└─ Build Relay ────┘
```

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

Relay Server chạy trên VPS, xử lý:
- **WebSocket** (port 25671): Game traffic real-time
- **HTTP API** (port 25672): Health check, leaderboard, player stats

```
API Endpoints:
  GET /health           → Server health check
  GET /api/status       → Server status + room list
  GET /api/leaderboard  → Top 20 players by score
  GET /api/player/:id   → Player stats
```

### Deploy Relay Server

```bash
# Dùng docker-compose
docker-compose up -d

# Hoặc pull image từ GHCR
docker pull ghcr.io/mhieuhonda/phitieu-relay:latest
docker run -d -p 25671:25671 -p 25672:25672 \
  -v phitieu-data:/app/data \
  ghcr.io/mhieuhonda/phitieu-relay:latest
```

## 🥷 12 Nhân Vật Độc Đáo

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

## 🛠️ Kỹ Năng

| Kỹ năng | Phím | Cooldown | Mô tả |
|---------|------|----------|-------|
| Dash | Q | 8s | Lao về phía trước với tốc độ cao |
| Shield | E | 15s | Miễn damage trong 3 giây |
| Multishot | Shift | 12s | Lần ném tiếp theo bắn 3 phi tiêu cùng lúc |

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
| R | Restart |
| ESC | Quay lại menu |

### Mobile
- Joystick ảo (trái): Di chuyển
- Nút Ném (phải): Nhắm & ném phi tiêu
- Nút Dịch Chuyển: Dịch chuyển đến phi tiêu
- Nút Dash / Shield / Multishot: Kỹ năng

## 🏗️ Công Nghệ

- **Engine**: Godot 4.7 stable
- **Ngôn ngữ**: GDScript (modern 4.7 idioms)
- **Networking**: WebSocket (Godot WebSocketPeer ↔ Node.js ws)
- **Relay Server**: Node.js 20 + ws + better-sqlite3
- **Database**: SQLite (WAL mode) cho player stats
- **Nền tảng**: Android, PC (Windows/Linux), Web
- **CI/CD**: GitHub Actions — 3 parallel build jobs
- **Container**: Docker + GHCR (GitHub Container Registry)
- **Âm thanh**: 155+ sound effects + 5 nhạc nền
- **Physics**: 7 collision layers (Player, Dart, Wall, AI, Obstacle, Pickup, RemotePlayer)

## 📁 Cấu Trúc Dự Án

```
phitieudichchuyen/
├── .github/workflows/
│   └── build-release.yml    # Parallel CI/CD (3 builds + relay + release)
├── assets/
│   ├── audio/               # 155+ SFX + 5 music
│   └── sprites/characters/  # 12 characters + 10 AI sprites
├── relay-server/
│   ├── server.js            # WebSocket relay + matchmaking + SQLite
│   ├── package.json         # Node.js dependencies
│   ├── Dockerfile           # Docker image for VPS deployment
│   └── .dockerignore
├── scenes/
│   ├── main.tscn            # Offline game scene
│   ├── main_online.tscn     # Online game scene
│   ├── menu.tscn            # Main menu
│   ├── mode_select.tscn     # Online/Offline selection
│   ├── matchmaking.tscn     # Matchmaking screen
│   ├── remote_player.tscn   # Remote player entity
│   ├── player.tscn, ai_player.tscn, dart.tscn, ...
│   └── hud.tscn, map.tscn, ...
├── scripts/
│   ├── network_manager.gd   # Network autoload (WebSocket client)
│   ├── main_online.gd       # Online game logic
│   ├── mode_select.gd       # Mode selection logic
│   ├── matchmaking_screen.gd# Matchmaking UI logic
│   ├── remote_player.gd     # Remote player logic
│   ├── game_manager.gd, player.gd, ai_player.gd, ...
│   └── audio_manager.gd, settings_manager.gd, ...
├── docker-compose.yml       # VPS deployment
├── project.godot            # Godot 4.7 config (v1.7)
├── export_presets.cfg       # Export Android / Windows / Linux
├── icon.svg
├── LICENSE
├── README.md
└── CHANGELOG.md
```

## 🚀 Cài Đặt & Chạy

### Yêu cầu
- Godot 4.7 stable (hoặc mới hơn)
- Nền tảng: Windows / macOS / Linux / Android

### Chạy từ source
```bash
git clone https://github.com/mhieuhonda/phitieudichchuyen.git
cd phitieudichchuyen
# Mở project.godot bằng Godot 4.7
# F5 để chạy game
```

### Export
1. Mở project trong Godot 4.7
2. Project → Export → Add platform (đã có sẵn preset Android, Windows, Linux)
3. Bấm Export Project

### Chạy Relay Server (local test)
```bash
cd relay-server
npm install
node server.js
# WebSocket: ws://localhost:25671/ws
# HTTP API: http://localhost:25672/health
```

## 📜 Lịch Sử Phiên Bản

### v1.7 (2026-08-03) — Online Multiplayer
- **NEW**: Chơi Online qua WebSocket Relay Server
- **NEW**: Matchmaking 10-20 người, 30s timeout, bot AI fill
- **NEW**: Mode Selection (Online / Offline)
- **NEW**: GitHub Actions parallel builds (3x faster)
- **NEW**: Relay Server (Node.js + SQLite) Docker deployment

### v1.6 (2026-08-03) — Modern GDScript Cleanup
- Modern hoá 45+ `emit_signal()` → `.emit()`
- Fix collision_mask sync, dead input actions, AudioManager cleanup

### v1.5 (2026-08-03) — Rà Soát Toàn Diện
- Fix Python docstring, skill_cooldowns init, AI group, AI size bug

### v1.4 (2026-08-03) — Clean Sweep
- Fix `set_deferred`, AI pickup HP, AudioManager API

### v1.3 (2026-08-03) — UI Customization
- Fix class_name conflict, kéo thả 6 nút bấm

### v1.2 (2026-08-03) — 12 Nhân Vật
- Character selection, bonus stats, sprite đẹp

### v1.1 (2026-08-03) — Bug Fixes
- Fix sprite scale, collision, teleport, speed

### v1.0 (2026) — Initial Release
- Ném phi tiêu + Dịch chuyển + Ăn đối thủ
- AI + Vòng bo + Leaderboard + 155+ SFX

## 📄 Giấy Phép

Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

<p align="center">
  <b>Phi Tiêu Dịch Chuyển</b> — Ném phi tiêu, dịch chuyển, nuốt đối thủ!
</p>
