# Changelog

## v1.7 - Phi Tiêu Dịch Chuyển (2026-08-03)

### 🌐 Chơi Online - Multiplayer Real-Time!

Bản v1.7 là bản cập nhật lớn nhất từ trước đến nay, biến game từ offline-only thành **online multiplayer** với hệ thống matchmaking tự động, relay server, và đồng bộ trạng thái real-time giữa các người chơi.

### ✨ New Features

- **Mode Selection**: Màn hình chọn chế độ chơi mới. Khi ấn "Chơi Ngay", hiện 2 lựa chọn:
  - **Chơi Online**: Kết nối đến Relay Server, ghép trận với người chơi thật
  - **Chơi Offline**: Chơi với máy (AI bots) như các bản trước

- **Online Multiplayer**:
  - Relay Server WebSocket (Node.js) chạy trên VPS
  - Client kết nối qua `NetworkManager` autoload singleton
  - Đồng bộ vị trí, HP, size, score, kills giữa các client
  - Relay dart throws, teleports, kills, skill uses, respawns
  - State sync 20 ticks/giây (50ms interval)

- **Matchmaking**:
  - Tối thiểu 10 người, tối đa 20 người mỗi phòng
  - 30 giây timeout: nếu không đủ người, tự thêm bot AI để đủ 10
  - 5 giây countdown trước khi bắt đầu trận
  - Match duration: 5 phút, vòng bo thu nhỏ tự động

- **Remote Players**:
  - Người chơi khác hiển thị trên map với interpolation mượt
  - Hiển thị tên, HP bar, character sprite
  - Dart throws, teleports, kills, skills đồng bộ real-time

- **Relay Server** (Node.js + WebSocket + SQLite):
  - WebSocket port 25671, HTTP API port 25672
  - Room management, matchmaking queue, game tick loop
  - SQLite database: player stats (kills, deaths, wins, score, best_score)
  - REST API: `/health`, `/api/status`, `/api/leaderboard`, `/api/player/:id`
  - Dockerized, deployed qua Coolify trên VPS

- **GitHub Actions** (3 luồng song song):
  - Build Android, Windows, Linux chạy **đồng thời** (parallel jobs)
  - Build & push Relay Server Docker image lên GHCR
  - Tự tạo GitHub Release khi push tag `v*`
  - Tốc độ build tăng 2-3x so với chạy tuần tự

### 🛠️ Architecture

```
┌─────────────┐     WebSocket      ┌──────────────┐
│  Godot Client│◄──────────────────►│  Relay Server │
│  (Player 1) │     port 25671     │  (Node.js)   │
└─────────────┘                     │  + SQLite DB  │
┌─────────────┐     WebSocket      └──────────────┘
│  Godot Client│◄──────────────────┘
│  (Player 2) │     State Sync
└─────────────┘     20 ticks/s
```

### 📦 New Files
- `scripts/network_manager.gd` — Autoload singleton WebSocket client
- `scripts/mode_select.gd` — Mode selection screen logic
- `scripts/matchmaking_screen.gd` — Matchmaking UI logic
- `scripts/main_online.gd` — Online game scene logic
- `scripts/remote_player.gd` — Remote player entity logic
- `scenes/mode_select.tscn` — Mode selection scene
- `scenes/matchmaking.tscn` — Matchmaking scene
- `scenes/main_online.tscn` — Online game scene
- `scenes/remote_player.tscn` — Remote player scene
- `relay-server/` — Complete relay server (Node.js + Docker)
- `.github/workflows/build-release.yml` — Parallel CI/CD

### 📦 Release
- Bump `config/version` 1.6 → 1.7 trong `project.godot`
- Bump `version/code` 16 → 17, `version/name` "1.6" → "1.7" trong `export_presets.cfg`
- Bump `application/file_version` và `product_version` "1.6.0.0" → "1.7.0.0"
- Add `NetworkManager` autoload singleton trong `project.godot`
- Add collision layer 7 "RemotePlayer" trong `project.godot`
- `docker-compose.yml` cho VPS deployment
- README.md viết lại chuẩn cho v1.7
- CHANGELOG.md cập nhật cho v1.7

---

## v1.6 - Phi Tiêu Dịch Chuyển (2026-08-03)

### 🧹 Modern GDScript Cleanup — Tuyệt Đối Sạch Sẽ

Bản v1.5 đã fix hết lỗi parse + lỗi runtime + lỗi logic. v1.6 rà soát lại toàn bộ codebase để **modern hoá mọi cú pháp GDScript** theo chuẩn Godot 4.7, đồng thời đồng bộ các giá trị collision mask giữa `.tscn` và `.gd` để tránh inconsistent state, và dọn dẹp các dead config không ai dùng.

### 🐛 Bug Fixes
- **FIX: `scenes/ai_player.tscn` collision_mask mismatch.** File `.tscn` ghi `collision_mask = 28` nhưng `scripts/ai_player.gd:90` ghi `collision_mask = 1 | 4 | 16 = 21`. Đã sync `.tscn` → `21`.
- **FIX: `scripts/audio_manager.gd` debug `print()` chạy mỗi khởi động.** Đã wrap trong `if OS.is_debug_build():`.
- **FIX: `scripts/mobile_controls.gd` comment có ký tự Japanese stray.** "click通常 works" → "click bình thường works".
- **FIX: `project.godot` dead input actions.** Xoá `aim` và `throw_dart`.

### ✨ Code Quality
- **MODERN: Convert toàn bộ 45+ `emit_signal("name", args)` → `name.emit(args)`.**
- **NEW: `AudioManager._exit_tree()`.** Kill fade tween + stop pool players + null resource refs.

### ✅ Verification
- ✅ Project import sạch 100% trên Godot 4.7 stable (0 parse errors, 0 deprecated warnings)
- ✅ Headless run 30 frames: 0 SCRIPT ERROR, 0 push_error, 0 push_warning
- ✅ Không còn `emit_signal("` trên toàn bộ `scripts/`
- ✅ `scenes/ai_player.tscn` collision_mask = 21, sync với `scripts/ai_player.gd:90`
- ✅ AudioManager có `_exit_tree()` dọn dẹp

---

## v1.5 - Phi Tiêu Dịch Chuyển (2026-08-03)

### 🔧 Rà Soát Toàn Diện — Sạch Từng Ngóc Ngách
- Fix Python-style docstring parse error trong `player.gd`.
- Fix `skill_cooldowns` Dictionary khởi tạo ở class-level.
- Fix AI teleport kill radius dùng sai `GameManager.player_size`.
- Đảm bảo AI luôn trong group `ai_players`.

---

## v1.4 - Phi Tiêu Dịch Chuyển (2026-08-03)

### 🔧 Rà Soát Toàn Diện Godot 4.7 (Clean Sweep)
- Fix `dart.gd` gán trực tiếp `monitoring` → `set_deferred`.
- Fix `pickup.gd` hồi máu AI theo `ai.current_max_hp`.
- Refactor `AudioManager` thêm API `is_music_playing()`.

---

## v1.3 - Phi Tiêu Dịch Chuyển (2026-08-03)

### 🔧 Godot 4.7 Compatibility (CRITICAL)
- Fix: `class_name CharacterData` xung đột autoload singleton.
- Fix: parse error ternary-in-tuple.
- NEW: Kéo thả 6 nút bấm UI customization.

---

## v1.2 - Phi Tiêu Dịch Chuyển (2026-08-03)

- 12 nhân vật ninja/warrior với sprite đẹp.
- Màn hình Nhân Vật + Chỉnh Sửa Giao Diện.
- Character bonus: HP, tốc độ, phi tiêu, kỹ năng riêng.

---

## v1.1 - Phi Tiêu Dịch Chuyển (2026-08-03)

- Fix nhân vật quá to, không hiện, không dịch chuyển.
- Fix collision layers.
- Tăng walk_speed 80 → 120.

---

## v1.0 - Phi Tiêu Dịch Chuyển (Initial Release)

- Ném phi tiêu + Dịch chuyển + Ăn đối thủ.
- 5 AI đối thủ + Vòng bo thu nhỏ + Leaderboard.
- 3 kỹ năng: Dash, Shield, Multishot.
- 155+ sound effects + 5 nhạc nền.
- Mobile controls + Joystick ảo.
