# 🎯 Phi Tiêu Dịch Chuyển v2.2

> **Ném phi tiêu - Dịch chuyển - Nuốt đối thủ!**
>
> Game 2D top-down arena được xây dựng bằng Godot Engine 4.7 — giờ đã có **Online Multiplayer**!

![Version](https://img.shields.io/badge/version-2.2-blue)
![Godot](https://img.shields.io/badge/Godot-4.7%20stable-blue)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20PC%20%7C%20Linux-green)
![Status](https://img.shields.io/badge/status-Stable-brightgreen)
![Multiplayer](https://img.shields.io/badge/multiplayer-Online%20%2B%20Offline-orange)

---

## 🆕 Tính Năng v2.2 — Fix Online + Hướng Dẫn + Admin Guide + Kill Streaks

### 🔥 FIX: Lỗi Không Thể Chơi Online

Trước đây, client báo "Server offline" ngay cả khi relay server đã cấu hình đầy đủ. Nguyên nhân: server URL bị hardcode, không có timeout, không có cách đổi URL trong UI.

**Giải pháp**:
- Thêm mục **🌐 MẠNG (SERVER URL)** trong Settings để user cấu hình relay server của mình
- **Connection timeout 8s**: nếu server không phản hồi, tự báo lỗi thay vì đợi mãi mãi
- Nút **"🔄 Thử lại"** trong Mode Select khi server offline
- Nút **"⚙ Đổi SERVER URL"** để vào Settings nhanh
- Nút **"💾 LƯU & TEST"** trong Settings - test kết nối ngay sau khi đổi URL
- Thông báo lỗi chi tiết (close code + reason từ server)
- Hỗ trợ cả `ws://` (LAN/test) và `wss://` (HTTPS production)

### 📖 NEW: Hướng Dẫn Chơi + Admin Guide

Thêm nút **"📖 HƯỚNG DẪN"** trong menu chính với 2 tab:

- **Tab Player**: Hướng dẫn đầy đủ - mục tiêu, điều khiển PC/Mobile, cơ chế chơi, 4 kỹ năng, 13 nhân vật, mẹo chơi, leaderboard
- **Tab Admin**: Mở khóa bằng mã `hieulouisking`. Bao gồm:
  - Hướng dẫn deploy relay server (Docker, Node.js, GHCR)
  - Cấu hình client (ws:// vs wss://)
  - HTTP API endpoints (health, status, leaderboard, player)
  - Quản lý SQLite database (backup, restore, reset)
  - **Cách thêm nhân vật mới** vào game (kích thước ảnh 256x256, nền trong suốt, vị trí file, edit CharacterData)
  - Scale relay server, env vars, debug & monitoring
  - Tìm & sửa lỗi thường gặp
  - Build & release workflow

### 🎁 Mở Rộng Mã Quà Tặng

- `hieulouis99` - Mở khóa nhân vật **Hieu Louis - Classic** (cũ)
- `hieulouisking` - Mở khóa **Admin Guide** trong mục Hướng Dẫn (mới)

Hệ thống gift codes refactor thành `{type, value}`:
- `type=character`: mở khóa nhân vật
- `type=feature`: mở khóa tính năng đặc biệt

### 🐛 FIX BUGS NGHIÊM TRỌNG

- **Dart không va chạm remote_players**: thêm layer 64 (RemotePlayer) vào collision_mask + check group
- **Teleport không kill remote_players**: thêm loop qua `remote_players` group trong `_check_teleport_kill`
- **Remote_player thiếu method `take_damage_from`**: implement method với hit flash + death effect
- **HUD combo_label bị ghi đè**: thêm flag `_combo_display_active` để tách biệt combo display và status display
- **MainOnline._on_match_end không gọi end_match()**: fix để stop game tick + record stats
- **Settings ONE_SHOT handlers leak**: cleanup trong `_exit_tree()`

### 🎨 FIX: Sprite "Hieu Louis - Classic"

Ảnh gốc 1024x1024 + nền tối → sprite mới 256x256 với:
- Hacker hooded silhouette (dark green body)
- Glowing green matrix-style eyes
- Binary code snippets bay quanh
- Vương miện vàng (Crown skill motif)
- Nền trong suốt hoàn toàn

### 🚀 NEW: Kill Streak Announcements

- Track kill streak (5s window giữa mỗi kill)
- Hiện announcement lớn ở giữa màn hình:
  - ⚔ DOUBLE KILL! → 🔥 TRIPLE KILL! → 💥 QUADRA KILL! → 👑 PENTA KILL!
  - 🚀 KILLING SPREE → 💀 UNSTOPPABLE → ⚡ GODLIKE
- Reset streak khi player chết

### 🎁 NEW: Daily Login Reward

- Track số ngày liên tiếp đã chơi
- Reward HP bonus: 5% max HP × streak (capped 30%)
- Hiện popup "🎁 ĐĂNG NHẬP NGÀY N!" khi vào trận đầu tiên trong ngày
- Track stats: total_matches, total_wins, total_kills

---

## 🆕 Tính Năng v2.1 — Hieu Louis - Classic + Online Fix + UI Redesign

### 🔥 FIX CRITICAL: Online Mode Hoạt Động!

- **Lỗi gốc**: `matchmaking_screen.gd` KHÔNG BAO GIỜ gọi `NetworkManager.join_matchmaking()` → user stuck "Đang tìm trận..." mãi mãi dù server online. Đã fix: tự động join queue khi login success, retry 5 lần nếu fail.
- **Fix chồng lấn nút**: TeleportButton chồng lên SkillMultishotButton (overlap 110x60px). Đã reposition layout gọn hơn, không chồng lấn.
- **Fix priority check**: Multishot được check trước Teleport → vùng overlap trigger sai nút. Đã đổi: Teleport check TRƯỚC skill buttons.

### 👑 Nhân Vật Mới: Hieu Louis - Classic

Nhân vật đặc biệt "hacker huyền thoại" với bộ kỹ năng cực ngầu:

- **Spawn Glitch 3s Bất Tử**: Khi vào trận, nhân vật bị glitch + tỏa ra các dòng code hacker (`0xCC`, `ROOT`, `BREACH`, `0xBEEF`...) trong 3 giây. Trong 3 giây đó là **bất tử**.
- **Vô Hạn Đạn**: Không giới hạn số phi tiêu trên trường (max 999 darts).
- **Không Cooldown Bắn**: Không bị giới hạn tần suất bắn liên tục.
- **Máu Cực Nhiều**: HP bonus +500, thanh HP dài hơn nhân vật thường.
- **Tốc Độ Cao**: +50 speed bonus.
- **Teleport Cooldown Cực Thấp**: 0.05s thay vì 0.15s.
- **Crown Skill (♛)**: Nút kỹ năng hình tròn có vương miện.
  - Ghim 5 đối thủ gần nhất bằng phi tiêu
  - +50% điểm trong thời gian ghim (8s)
  - Cooldown 50 giây
- **SMG Reward**: Khi giết đủ 50 mạng, nhận tiểu liên bắn rất nhanh, vô hạn đạn, tồn tại 20 giây.
- **Vòng Tròn Đỏ Highlight**: Khi nút xoay (joystick/aim) chĩa đúng vào đối thủ nào, đối thủ đó sẽ hiện vòng tròn đỏ xung quanh để dễ bắn trúng hơn.

**Cách mở khóa**: Vào Settings → Nhập Mã Quà Tặng → nhập `hieulouis99` → Đổi Mã.

### 🎨 Redesign UI

- **Menu chính**: Title 56px với glow shadow, gradient background, badges nổi bật.
- **Settings**: Scroll container, section headers (🎨 Đồ Họa / 🔊 Âm Thanh / 🎁 Nhập Mã Quà Tặng / 🎛 Giao Diện), layout 2 cột cho toggles.
- **Mode Select**: Button text lớn 24px, accents màu xanh dương.
- **Mobile Controls**: Layout gọn, không chồng lấn. Teleport button tách biệt khỏi skill buttons.
- **HUD**: Hiển thị trạng thái Crown/SMG/Spawn Invul realtime.

### 🐛 Bug Fixes Khác

- **Mobile controls**: Touch priority teleport > skill buttons (fix overlap)
- **Network signals**: MatchmakingScreen cleanup `login_success` + `connection_error` handlers
- **Auto-retry join matchmaking**: Nếu chưa vào queue sau 2s, tự retry (max 5 lần)
- **Crown button visibility**: Chỉ hiện khi đang chơi Hieu Louis - Classic
- **Target highlight**: Vòng tròn đỏ pulsing quanh đối thủ trong đường ngắm
- **Character screen**: Hiển thị "Phi tiêu: VÔ HẠN" cho Classic, gợi ý mã quà tặng cho nhân vật chưa mở khóa

### 📦 Version Bump
- `project.godot`: config/version `2.0` → `2.1`
- `export_presets.cfg`: version/code `20` → `21`, version/name `"2.0"` → `"2.1"`
- `export_presets.cfg`: application/file_version + product_version `"2.0.0.0"` → `"2.1.0.0"`
- `menu.gd`: version label `v2.0` → `v2.1`
- New input action: `skill_crown` (phím C)

### ✅ Verification
- ✅ Matchmaking tự join queue khi vào màn hình
- ✅ Teleport button không bị overlap với multishot
- ✅ Hieu Louis - Classic spawn glitch effect hoạt động
- ✅ Crown skill ghim 5 đối thủ + +50% điểm
- ✅ SMG reward sau 50 kills
- ✅ Target highlight vòng tròn đỏ
- ✅ Gift code "hieulouis99" mở khóa nhân vật
- ✅ UI redesign đẹp, chuyên nghiệp hơn

---

## 🆕 Tính Năng v2.0 — Sửa Hết Regressions, Hoàn Thiện!

Bản v2.0 tập trung **so sánh toàn diện v1.6 vs v1.9**, sửa hết regressions và hoàn thiện mọi thứ.

### 🔥 Fix Blocker: Python Docstring Parse Error

`remote_player.gd` sử dụng `"""..."""` (Python docstring) — Godot 4.7 báo parse error. Online multiplayer **hoàn toàn broken** vì `remote_player.tscn` không load được. Đã fix bằng `## ...` (GDScript doc comment).

### 🟡 Fix: Mid-Flight Hint Flicker

Hint nhấp nháy vì luôn ẩn sau 1.5s kể cả khi phi tiêu vẫn bay. Đã restore logic v1.6 (check `_has_flying_darts()`).

### 🟡 Fix: UX Regression — Extra Click cho Offline

Nút "Chơi Ngay" giờ cần thêm 1 click (Mode Select). Đã cải thiện UX cho màn hình chọn chế độ.

### 📋 Regression Audit Hoàn Chỉnh

| Loại | Số lượng | Chi tiết |
|------|----------|----------|
| 🔴 Blocker | 1 | Python docstring parse error |
| 🟡 Minor | 2 | Extra click; hint flicker |
| 🟢 Bug fixes (genuine) | 10+ | is_instance_valid guards, respawn safety, etc. |
| ✅ Unchanged | 11 scripts + 14 scenes | Core game không thay đổi |

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
