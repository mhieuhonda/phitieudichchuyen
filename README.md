# Phi Tiêu Dịch Chuyển

> Vượt 20 ải · Ném phi tiêu · Dịch chuyển · Tiêu diệt Boss
> Game 2D top-down Godot 4.7 — Offline PvE + Online Multiplayer Deathmatch.

![Version](https://img.shields.io/badge/version-4.4-gold.svg)
![Engine](https://img.shields.io/badge/Godot-4.7-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

> **Game developed by Hieu Louis**

---

## v4.4 — Fix DNS resolution + Fix freeze at 00:00 + Bỏ double-EXP

Bản v4.4 sửa 2 lỗiCritical mà người chơi vẫn gặp sau v4.3, cộng thêm 1 bug nghiêm trọng phát hiện khi audit:

### 1. Fix "Không phân giải được tên miền server" khi login/register

**Nguyên nhân gốc** (sau khi audit `account_manager.gd` v4.3):
- HTTPRequest pool 4 nodes dùng `cancel_request()` rồi reuse ngay → race condition khiến request sau fail với `RESULT_CANT_RESOLVE`.
- Manual `Host:` header + `Connection: close` đôi khi conflict với internal logic của Godot 4.7 HTTPRequest.
- `set_tls_options(TLSOptions.client_unsafe())` được gọi cho URL HTTP (no-op nhưng có thể trigger mbedTLS init không cần thiết).
- Không có cơ chế retry khi DNS fail (network just came up on Android).

**Fix v4.4:**
- **DNS pre-resolve at startup**: Gọi `IP.resolve_hostname(SERVER_HOST, IP.TYPE_IPV4)` khi AccountManager `_ready()`. Cache IP vào `_resolved_ip`. Nếu fail (network chưa sẵn sàng), retry sau 2s.
- **Triple-layer fallback**:
  1. `HTTPRequest` với URL domain gốc `http://phitieu.louis.vangioitutien.com/api/...`
  2. Nếu #1 fail với CANT_RESOLVE → `HTTPRequest` với URL IP `http://<IP>:80/api/...` + `Host: phitieu.louis.vangioitutien.com` header (Traefik route theo Host header).
  3. Nếu #2 cũng fail → `HTTPClient` trực tiếp (low-level, bypass HTTPRequest wrapper) tới IP + Host header.
- **Per-request HTTPRequest** (bỏ pool): mỗi request tạo 1 node mới, `queue_free()` sau khi xong. Không còn race condition.
- **Bỏ manual Host/Connection headers** cho layer 1 (Godot tự set từ URL).
- **Bỏ `set_tls_options`** cho HTTP URL (chỉ cần cho HTTPS).
- **Better error messages**: log full URL, IP, error code, response preview.

### 2. Fix "Treo 00:00 sau khi kết thúc trận"

**Nguyên nhân gốc** (sau khi audit `multiplayer_arena.gd` v4.1):
- Khi timer client chạm 0:00, `_end_game()` set `game_active = false` và hiện "Hết giờ! Đang chờ kết quả..." — nhưng KHÔNG có UI nào cho user quay lại lobby.
- Nếu server's `game_end` message không tới (do timing drift, WS disconnect, hoặc room bị xoá), user stuck vĩnh viễn tại 0:00.
- `_process()` early-return khi `game_active = false`, nên không có cách nào thoát.

**Fix v4.4:**
- **Back-to-Lobby button**: Sau khi trận kết thúc (cả từ server's `game_end` lẫn client's timeout), hiển thị nút lớn "← Về sảnh chờ" ở giữa-bottom màn hình, có hover effect + premium styling (gold accent, shadow).
- **Auto-transition**: Nếu user không ấn nút trong 10s, tự chuyển về `multiplayer_lobby.tscn`. Nút hiển thị countdown "(10s) → (9s) → ...".
- **Safety timeout**: Nếu server's `game_end` không tới trong 5s sau khi client timer chạm 0, force `_on_game_end({}, {})` với data cục bộ → hiển thị nút back ngay.
- **`_process()` restructured**: Safety timeout + timer display chạy TRƯỚC `if not game_active: return`, đảm bảo countdown vẫn update và safety timeout vẫn fire.
- **Disconnect handling**: Khi mất kết nối WS giữa trận, cũng hiển thị nút "← Về sảnh chờ" (MultiplayerManager sẽ tự reconnect trong nền).

### 3. Bỏ double-EXP bug (Critical!)

**Bug phát hiện khi audit**: Trước đây, EXP được award **2 lần** cho mỗi trận:
1. **Client-side**: `multiplayer_arena._on_game_end()` gọi `AccountManager.submit_match_result()` → POST `/api/match_result` → server award EXP.
2. **Server-side**: `server.py:end_game_after()` tự award EXP qua DB direct khi timer 180s hết.

→ User nhận **gấp đôi EXP** thực tế!

**Fix v4.4:**
- Bỏ hoàn toàn client-side `submit_match_result()` call (function giờ là no-op, giữ lại chỉ để compat).
- Server's `end_game_after()` là **source of truth duy nhất** cho EXP award.
- Client chỉ nhận EXP qua WS events `level_up` / `exp_gained` do server push.
- Cập nhật `server.py:end_game_after()`: handle empty scores safely, thêm logging chi tiết.

### 4. Fix auto-reconnect bug trong MultiplayerManager

**Bug**: `MultiplayerManager._process()` chỉ auto-reconnect khi `is_connecting == true`. Nhưng `is_connecting` được set false ngay khi connect thành công → sau khi disconnect (do mạng nháy), reconnect KHÔNG BAO GIỜ trigger.

**Fix v4.4**: Track `_should_reconnect` riêng, set true khi user chủ động connect, false khi user chủ động disconnect. Reconnect trigger dựa trên flag này, không phụ thuộc `is_connecting`.

### 5. Connection timeout cho WebSocket

**Fix**: Nếu `STATUS_CONNECTING` kéo dài > 15s, force close + emit `connection_error`. Tránh user chờ vô hạn khi server không phản hồi.

Xem [CHANGELOG.md](CHANGELOG.md) để biết chi tiết đầy đủ.

---

## v4.3 — Sửa lỗi không đăng nhập/đăng ký được trên Godot 4.7

Bản v4.3 sửa triệt để lỗi người chơi **không thể đăng ký hoặc đăng nhập** sau ~50 lần fix không thành công. 3 root cause chồng lên nhau:

1. **Godot 4.7 đã xóa property `tls_options` trên HTTPRequest** — gán trực tiếp `_http_request.tls_options = ...` gây runtime error → TLS không được set → mọi request fail. Fix: dùng method `_http_request.set_tls_options(...)`.
2. **Godot 4.7's mbedTLS không gửi SNI trong TLS ClientHello** — Traefik v3.6 trả HTTP 503 cho request thiếu SNI. Workaround: dùng HTTP (port 80) thay HTTPS, đã remove redirect-to-https trên Traefik. HTTPS vẫn available cho browser/curl.
3. **`ConfigFile.clear()` trong Godot 4.7 nhận 0 args** — code cũ `cfg.clear(SAVE_PATH)` gây parse error → autoload AccountManager fail hoàn toàn.

Cải thiện thêm: HTTPRequest pool (4 nodes) tránh race condition, explicit Host header, HTTPClient fallback, extensive logging.

Xem [CHANGELOG.md](CHANGELOG.md) để biết chi tiết đầy đủ.

---

## v4.2 — Sửa UI Online + Fix Nút Bấm + Branding

Bản v4.2 tập trung sửa trải nghiệm online cho đồng bộ với ngoài sảnh và fix các lỗi phàn nàn nhiều nhất:

- **Yêu cầu đăng nhập trước khi vào Multiplayer** — ấn "🌐 MULTIPLAYER" từ menu giờ tự chuyển sang login scene nếu chưa đăng nhập (có nút "Chơi guest" để bỏ qua). Sau khi đăng nhập OK, tự forward về `multiplayer_lobby.tscn`.
- **Fix nút "Đăng nhập/Đăng ký" bị đóng băng** — thêm spinner + safety net 20s + re-enable nút trên mọi outcome (success/fail/timeout/logout). Enter key cũng trigger submit.
- **Fix chat không gửi được + nút "tê liệt"** — auto-connect WS khi vào lobby (không cần bấm "Kết nối" thủ công). Nếu chat khi chưa connect → tự trigger reconnect. Tất cả nút giờ có hover scale effect + premium styling (shadow + border + corner radius 8px) đồng bộ với `menu.gd`. Title có glow pulse animation.
- **Arena HUD fix** — `ArenaBg`/`ArenaBorder` set `mouse_filter = IGNORE` để không chặn clicks meant cho HUD buttons. `LeaveButton` thêm premium styling + hover effects.
- **Profile + Leaderboard** — hover scale effects + premium `_style_button()` (shadow + 3 stylebox) + `tls_options = TLSOptions.client_unsafe()` cho profile HTTPRequest (trước đó thiếu, có thể gây freeze).
- **Branding "Game developed by Hieu Louis"** — thêm `DeveloperLabel` ở bottom-right của mọi scene (menu, login, lobby, arena HUD, profile, leaderboard). Server footer + Dockerfile LABEL cũng đổi sang "Hieu Louis".
- **Sub-VPS networking** — toàn bộ traffic đi qua Traefik reverse proxy ở `https://phitieu.louis.vangioitutien.com` (REST + WS). `TLSOptions.client_unsafe()` accept Traefik default self-signed cert. Không có kết nối trực tiếp IP:Port nào.

Xem [CHANGELOG.md](CHANGELOG.md) để biết chi tiết đầy đủ.

---

## Giới thiệu

**Phi Tiêu Dịch Chuyển** là game 2D top-down offline với cơ chế độc đáo: **ném phi tiêu → dịch chuyển tức thời tới phi tiêu → tiêu diệt đối thủ**. Có 2 chế độ chính:

- **Vượt Ải** — 20 ải với độ khó tăng dần, kết thúc bằng Boss cuối 12 triệu HP.
- **Thế Giới** — meta-game RPG với 4 vùng, 10 loài, hệ thống class, chiêu mộ đồng đội, HL Coin, uy tín, thành tựu và **Quest scene chơi được** (v3.9).
- **Multiplayer Online** — deathmatch 2-4 người, 3 phút/trận, qua WebSocket. Đăng ký/đăng nhập để nhận EXP và lên level (không giới hạn).

## Điều khiển

| Hành động | PC | Mobile |
|---|---|---|
| Di chuyển | WASD / ← ↑ ↓ → | Joystick trái |
| Nhắm & ném | Chuột phải (kéo → thả) | Nút **NÉM** (đỏ, tròn) |
| Dịch chuyển | Space | Nút **DỊCH** (xanh, tròn) |
| Tạm dừng | P / ESC | — |
| Quick retry (khi pause) | R | — |
| Gửi chat (multiplayer) | Enter | Enter (bàn phím ảo) |

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

## Multiplayer Online

Server backend (Python + PostgreSQL + Redis) chạy ở `https://phitieu.louis.vangioitutien.com`:

- **REST API** — đăng ký, đăng nhập, profile, leaderboard, match result
- **WebSocket** — game protocol (rooms, chat, dart sync, hit detection)
- **Auth** — bcrypt + token 48 bytes, TTL 30 ngày
- **EXP** — curve `50 * (N-1) * N`, không giới hạn level
- **Danh hiệu** — Tân Binh → Chiến Binh → Tinh Anh → Cao Thủ → Tông Sư → Huyền Thoại

### Cách chơi multiplayer
1. Menu → **🌐 MULTIPLAYER**
2. Nếu chưa đăng nhập → scene login hiện ra → đăng ký/đăng nhập (hoặc ấn "Chơi guest")
3. Vào sảnh chờ → tự kết nối server → thấy danh sách phòng
4. **🏠 Tạo phòng** hoặc **Vào phòng** có sẵn
5. **⚔ Bắt đầu game** → vào arena deathmatch 3 phút
6. Hết trận → nhận EXP (nếu đã đăng nhập) → về sảnh chờ

## Cấu trúc dự án

```
phitieudichchuyen/
├── project.godot          # Godot config (13 autoloads, v4.2)
├── export_presets.cfg     # Android / Windows / Linux
├── README.md
├── CHANGELOG.md
├── LICENSE
├── scenes/                # .tscn files
├── scripts/               # .gd files (autoloads + scene scripts)
├── relay-server/          # Python backend (server.py + Dockerfile)
└── assets/
    ├── sprites/
    └── audio/
```

### Autoload singletons (v4.2)

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
| `TutorialManager` | Auto-open tutorial on first launch |
| `AccountManager` | Auth (login/register), token persistence, profile, leaderboard, match result |
| `MultiplayerManager` | WebSocket client, room state, dart/hit sync |
| `LoginRouter` | v4.2 —协调 chuyển scene giữa login và scene yêu cầu login |

## Lịch sử phiên bản

| Version | Tóm tắt |
|---|---|
| **4.4** | Fix "Không phân giải được tên miền server" (DNS pre-resolve + IP fallback + HTTPClient direct) · Fix "Treo 00:00 sau trận" (nút Về sảnh chờ + auto-transition + safety timeout) · Bỏ double-EXP bug (client + server cùng award → chỉ server) · Fix auto-reconnect WS (is_connecting race) · Connection timeout 15s cho WS |
| 4.3 | Sửa tls_options property đã bị xóa trong Godot 4.7 (dùng set_tls_options method) · Dùng HTTP thay HTTPS (mbedTLS không gửi SNI) · Fix ConfigFile.clear() 0 args · HTTPRequest pool + Host header + HTTPClient fallback |
| 4.2 | Sửa UI online đồng bộ với sảnh · Fix nút bấm đóng băng khi login/register · Auto-connect WS khi vào lobby · Yêu cầu đăng nhập trước khi vào Multiplayer · Branding "Game developed by Hieu Louis" trên mọi scene · Fix mouse_filter cho ArenaBg/ArenaBorder · Hover scale effects cho profile/leaderboard · `tls_options` cho profile HTTPRequest |
| 4.1 | Server backend mới (PostgreSQL + Redis + bcrypt) · Auth + Profile + Leaderboard + EXP không giới hạn level · Sửa crash multiplayer (sai node path) · Accept Traefik self-signed cert · Renames DB tables `phitieu_*` prefix |
| 3.9 | Quest scene chơi được (kill/boss-mini/find) · Meta-progression áp dụng combat · Fix 30 bugs · Cân bằng AI dmg/hp curve · Quest tab trong Sổ Tay · 4-tier quest difficulty |
| 3.8 | Combat polish & boss arena quality: Pause menu, minimap, Boss Phase 2, kill streak, hit markers, low-HP heartbeat, boss off-screen arrow, aim ricochet preview, onboarding, 5 achievements mới, perfect/speed bonus, perf optimizations |
| 3.7 | Fix laser hitbox · Rebalance boss < 4x player · Tăng độ khó ải · Thêm chế độ Thế Giới |
| 3.6 | Fix crash khi ấn VƯỢT ẢI + sửa double-count mạng/địch |
| 3.5 | Vượt 20 ải · Boss 10M HP với laser + rage sweep · Lưu tiến độ local · Fix kill-steal |
| 3.4 | 2 nút tròn (Xanh dịch / Đỏ ném). Xóa 3 skills. AnhNen.png. Shockwave + screen flash |

## Công nghệ

- **Engine**: Godot 4.7 (Mobile profile)
- **Ngôn ngữ**: GDScript 2.0
- **Physics**: 2D, 6 layers + ricochet + knockback
- **Audio**: 16-voice pool, WAV, lazy-loading, ~155 variations
- **Localization**: Custom I18N (VI/EN)
- **Save**: ConfigFile local (user://progress.cfg, user://progression.cfg, user://character_data.cfg, user://account.cfg)
- **Backend**: Python aiohttp + asyncpg (PostgreSQL) + redis + bcrypt + WebSocket
- **Deploy**: Docker + Coolify + Traefik reverse proxy (HTTPS + WSS)

## License

Xem [LICENSE](LICENSE).

## Đóng góp

Mọi góp ý / bug report / feature request — tạo issue tại:
<https://github.com/mhieuhonda/phitieudichchuyen/issues>

---

<p align="center">
  <strong>Phi Tiêu Dịch Chuyển v4.4</strong><br>
  <em>Game developed by Hieu Louis</em>
</p>
