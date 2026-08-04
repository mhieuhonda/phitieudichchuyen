extends Control

## GuideScreen - Màn hình Hướng Dẫn Chơi (v2.2)
## Hiển thị hướng dẫn cách chơi, mẹo, danh sách nhân vật + kỹ năng
## Phần "Hướng Dẫn Cho Admin" chỉ hiện khi user đã nhập mã "hieulouisking"
##   (mở khóa feature "admin_guide" trong CharacterData.unlocked_features)
##
## v2.2: NEW - guide cho người chơi + admin guide cho người quản trị server

@onready var back_button: Button = $BackButton
@onready var tab_player_button: Button = $TopBar/TabPlayerButton
@onready var tab_admin_button: Button = $TopBar/TabAdminButton
@onready var content_label: RichTextLabel = $ScrollContainer/ContentLabel
@onready var admin_locked_label: Label = $ScrollContainer/AdminLockedLabel
@onready var title_label: Label = $TitleLabel

const TAB_PLAYER := "player"
const TAB_ADMIN := "admin"

var _current_tab: String = TAB_PLAYER

func _ready():
        back_button.pressed.connect(_on_back_pressed)
        tab_player_button.pressed.connect(func(): _switch_tab(TAB_PLAYER); AudioManager.play_ui_click())
        tab_admin_button.pressed.connect(func(): _switch_tab(TAB_ADMIN); AudioManager.play_ui_click())
        for btn in [back_button, tab_player_button, tab_admin_button]:
                if btn:
                        btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())
        # Mặc định hiển thị tab Player
        _switch_tab(TAB_PLAYER)
        AudioManager.play_music("menu")

func _switch_tab(tab: String):
        _current_tab = tab
        if tab == TAB_PLAYER:
                title_label.text = "📖 HƯỚNG DẪN CHƠI"
                tab_player_button.modulate = Color(0.5, 1.0, 0.5)
                tab_admin_button.modulate = Color(1.0, 1.0, 1.0)
                content_label.visible = true
                admin_locked_label.visible = false
                content_label.text = _player_guide_text()
        elif tab == TAB_ADMIN:
                title_label.text = "🔒 HƯỚNG DẪN CHO ADMIN"
                tab_player_button.modulate = Color(1.0, 1.0, 1.0)
                tab_admin_button.modulate = Color(0.5, 1.0, 0.5)
                # Chỉ hiện nội dung admin nếu đã unlock
                if CharacterData and CharacterData.is_feature_unlocked("admin_guide"):
                        content_label.visible = true
                        admin_locked_label.visible = false
                        content_label.text = _admin_guide_text()
                else:
                        content_label.visible = false
                        admin_locked_label.visible = true
                        admin_locked_label.text = _admin_locked_text()

func _player_guide_text() -> String:
        return """[b][color=#00ff88][size=24]🎯 PHI TIÊU DỊCH CHUYỂN[/size][/color][/b]

[i]Ném phi tiêu - Dịch chuyển - Nuốt đối thủ![/i]

────────────────────────────

[color=#ffaa00][b]📜 MỤC TIÊU[/b][/color]
Bạn bị thả vào arena 2D top-down cùng nhiều đối thủ (người chơi thật online hoặc AI). Mục tiêu:
• Tiêu diệt càng nhiều đối thủ càng tốt
• Sống sót đến hết trận (5 phút) hoặc là người cuối cùng
• Tích điểm cao nhất để lên #1 leaderboard

────────────────────────────

[color=#ffaa00][b]🕹 ĐIỀU KHIỂN[/b][/color]

[color=#44aaff]PC:[/color]
• [b]WASD[/b] hoặc [b]← ↑ ↓ →[/b] - Di chuyển
• [b]Chuột phải[/b] - Nhắm & ném phi tiêu (kéo để tăng lực)
• [b]Space[/b] - Dịch chuyển đến phi tiêu
• [b]Q[/b] - Dash
• [b]E[/b] - Shield
• [b]Shift[/b] - Multishot
• [b]C[/b] - Crown Skill (chỉ Hieu Louis - Classic)
• [b]R[/b] - Khởi động lại trận
• [b]ESC[/b] - Quay lại menu

[color=#44aaff]Mobile:[/color]
• [b]Joystick trái[/b] - Di chuyển
• [b]Nút Ném (phải)[/b] - Kéo để nhắm, thả để ném
• [b]Nút Dịch Chuyển[/b] - Dịch chuyển tức thời đến phi tiêu
• [b]Nút Dash / Shield / Multishot[/b] - Kỹ năng
• [b]Nút Crown[/b] - Chỉ hiện khi chơi Hieu Louis - Classic

────────────────────────────

[color=#ffaa00][b]🎯 CƠ CHẾ CHƠI[/b][/color]

[color=#ff6666]1. Ném phi tiêu[/color]
- Kéo chuột (hoặc nút Ném) để nhắm và tăng lực
- Thả để ném - phi tiêu bay thẳng, cắm vào tường/đất
- Tối đa 3 phi tiêu trên trường (có thể tăng bằng nhân vật hoặc pickup)

[color=#ff6666]2. Dịch chuyển[/color]
- Bấm Space (hoặc nút Dịch Chuyển) để dịch chuyển [b]tức thời[/b] đến phi tiêu gần nhất
- Có thể dịch chuyển khi phi tiêu đang bay (mid-flight) hoặc đã cắm
- Cooldown ngắn (0.15s), có thể dịch chuyển liên tục

[color=#ff6666]3. Ăn đối thủ[/color]
- Dịch chuyển đến [b]gần đối thủ[/b] (trong bán kính ~50px) sẽ [b]tiêu diệt[/b] chúng ngay lập tức
- Càng to (ăn nhiều đối thủ) càng mạnh nhưng cũng là mục tiêu dễ bắn trúng
- Hồi [b]10% max HP[/b] mỗi khi ăn đối thủ

[color=#ff6666]4. Vòng bo[/color]
- Vòng bo thu nhỏ mỗi 30 giây
- [b]Ngoài vòng bo[/b] = mất HP liên tục (10 HP/s)
- Vòng bo tối thiểu = 200px - khi đó trận gần kết thúc

────────────────────────────

[color=#ffaa00][b]🛠 KỸ NĂNG[/b][/color]

• [color=#44ffff][b]Dash (Q)[/color][/b] - Cooldown 8s
  Lao về phía trước với tốc độ cao trong 0.18s. Hữu ích để né phi tiêu hoặc rút ngắn khoảng cách.

• [color=#66ccff][b]Shield (E)[/color][/b] - Cooldown 15s
  Bọc khiên miễn damage trong 3 giây. Không thể bị dart hoặc teleport kill xuyên qua.

• [color=#ffaa44][b]Multishot (Shift)[/color][/b] - Cooldown 12s
  Lần ném tiếp theo bắn 3 phi tiêu cùng lúc theo hình quạt. Tăng cơ hội trúng đối thủ đang di chuyển.

• [color=#ffd700][b]Crown Skill (C)[/color][/b] - Chỉ Hieu Louis - Classic
  Ghim 5 đối thủ gần nhất +50% điểm trong 8s. Cooldown 50s.

────────────────────────────

[color=#ffaa00][b]🥷 NHÂN VẬT[/b][/color]

12 nhân vật thường + 1 đặc biệt (Hieu Louis - Classic). Mỗi nhân vật có:
• Bonus HP / Speed / Phi tiêu khác nhau
• Skill bonus riêng (Dash mạnh hơn, Shield lâu hơn, Multishot bắn nhiều hơn...)
• Mở khóa bằng cách chơi nhiều hoặc nhập mã quà tặng trong Settings

[color=#00ff88]Hieu Louis - Classic[/color] là nhân vật đặc biệt:
- HP cực cao (+500), Speed +50, Phi tiêu vô hạn
- Spawn bất tử 3 giây đầu (glitch effect)
- Crown Skill độc quyền
- SMG Reward: giết 50 mạng → tiểu liên vô hạn 20s
- Mở khóa bằng [b]mã quà tặng bí mật[/b] (chỉ admin mới biết, nhập trong Settings → Nhập Mã Quà Tặng)

────────────────────────────

[color=#ffaa00][b]💡 MẸO CHƠI[/b][/color]

• [b]Luôn có phi tiêu sẵn sàng[/b]: Ném trước rồi dịch chuyển theo - không bao giờ đứng yên không có phi tiêu trên trường
• [b]Ném trước rồi dịch chuyển giữa đường bay[/b]: Bất ngờ hơn, đối thủ khó né
• [b]Combo kill[/b]: Giết liên tiếp trong 2s để nhận combo bonus (+50% điểm mỗi combo)
• [b]Tránh xa vòng bo[/b]: Luôn di chuyển vào tâm bản đồ để không bị damage vòng bo
• [b]Dùng Shield khi bị nhắm[/b]: Shield không chỉ chặn dart mà còn chặn teleport kill
• [b]Ăn pickup[/b]: Hồi máu / tăng phi tiêu - rất quan trọng trong late game
• [b]Quan sát kill feed[/b]: Biết ai đang chiến đấu để chọn lúc ra tấn công hoặc lảng tránh

────────────────────────────

[color=#ffaa00][b]🌐 CHƠI ONLINE[/b][/color]

• Vào [b]Chơi Ngay → Chơi Online[/b]
• Server tự ghép trận 10-20 người
• 30 giây không đủ người → bot AI tự fill
• Trận bắt đầu sau 5 giây countdown
• State sync 20 ticks/giây - vị trí, HP, dart, skill đều đồng bộ

[color=#ff6666]Nếu server offline:[/color]
Vào [b]Settings → Mạng (Server URL)[/b] để đổi địa chỉ Relay Server của bạn.

────────────────────────────

[color=#ffaa00][b]🏆 LEADERBOARD[/b][/color]

Mỗi trận kết thúc, leaderboard hiện xếp hạng:
• Điểm cao nhất = #1
• Kill count là tiebreaker
• Thắng trận (đứng đầu) = nhạc victory
• Thua = nhạc defeat

────────────────────────────

[color=#888888]Phi Tiêu Dịch Chuyển v2.2 - Chúc bạn chơi vui vẻ![/color]
"""

func _admin_guide_text() -> String:
        return """[b][color=#ffd700][size=22]🔧 HƯỚNG DẪN CHO ADMIN[/size][/color][/b]

[i]Tài liệu nội bộ cho admin server. Không chia sẻ ra ngoài.[/i]

────────────────────────────

[color=#ffaa00][b]1. TRIỂN KHAI RELAY SERVER[/b][/color]

[color=#44aaff]Yêu cầu:[/color]
• VPS có Docker (hoặc Node.js 20+)
• Mở 2 port: [b]25671[/b] (WebSocket) và [b]25672[/b] (HTTP API)
• RAM tối thiểu 512MB, khuyến nghị 1GB+
• Disk 5GB+ cho SQLite database

[color=#44aaff]Cách 1: Docker Compose (khuyến nghị)[/color]
[code]docker-compose up -d[/code]
- Tự pull image [b]ghcr.io/mhieuhonda/phitieu-relay:latest[/b]
- Tự mount volume [b]phitieu-data[/b] cho database
- Healthcheck mỗi 30s

[color=#44aaff]Cách 2: Chạy trực tiếp Node.js[/color]
[code]cd relay-server
npm install
node server.js[/code]
- WebSocket: [b]ws://localhost:25671/ws[/b]
- HTTP API: [b]http://localhost:25672/health[/b]

[color=#44aaff]Cách 3: Pull image GHCR[/color]
[code]docker pull ghcr.io/mhieuhonda/phitieu-relay:latest
docker run -d -p 25671:25671 -p 25672:25672 \\
  -v phitieu-data:/app/data \\
  ghcr.io/mhieuhonda/phitieu-relay:latest[/code]

────────────────────────────

[color=#ffaa00][b]2. CẤU HÌNH CLIENT[/b][/color]

[color=#ff6666]v2.3:[/color] Server URL đã [b]hardcoded[/b] trong source code (`scripts/network_manager.gd`, const `DEFAULT_SERVER_URL`). Không còn UI để user tự đổi trong game.

Để đổi server (chỉ dành cho dev):
1. Mở [b]scripts/network_manager.gd[/b]
2. Sửa dòng: [code]const DEFAULT_SERVER_URL := "ws://163.44.96.79:25671/ws"[/code]
3. Build lại game

[color=#44aaff]Lưu ý về giao thức:[/color]
• [b]ws://[/b] = plain WebSocket (mặc định, dùng cho VPS có IP public)
• [b]wss://[/b] = secure WebSocket (bắt buộc nếu web build chạy trên HTTPS)
• Nếu deploy trên web HTTPS, [b]phải[/b] dùng wss:// - trình duyệt sẽ chặn ws://

────────────────────────────

[color=#ffaa00][b]3. HTTP API ENDPOINTS[/b][/color]

• [b]GET /health[/b] - Health check
  Trả về: [code]{ "status": "ok", "uptime": 123, "rooms": 2, "clients": 15, "queue": 3 }[/code]

• [b]GET /api/status[/b] - Server status + room list
  Trả về version, config, danh sách phòng đang hoạt động

• [b]GET /api/leaderboard[/b] - Top 20 players by total score
  Trả về mảng player objects

• [b]GET /api/player/:id[/b] - Stats của 1 player
  Trả về kills, deaths, wins, matches, best_score, ...

────────────────────────────

[color=#ffaa00][b]4. QUẢN LÝ DATABASE[/b][/color]

Database SQLite lưu tại [b]/app/data/game.db[/b] (trong container).
WAL mode bật sẵn để concurrent reads.

[color=#44aaff]Backup:[/color]
[code]docker cp phitieu-relay:/app/data/game.db ./backup-$(date +%Y%m%d).db[/code]

[color=#44aaff]Restore:[/color]
[code]docker cp ./backup-20260101.db phitieu-relay:/app/data/game.db
docker restart phitieu-relay[/code]

[color=#44aaff]Reset toàn bộ stats:[/color]
[code]docker exec phitieu-relay rm /app/data/game.db
docker restart phitieu-relay[/code]

────────────────────────────

[color=#ffaa00][b]5. THÊM NHÂN VẬT MỚI VÀO GAME[/b][/color]

Để thêm 1 nhân vật mới, làm theo các bước:

[color=#44aaff]Bước 1: Chuẩn bị sprite[/color]
• Kích thước ảnh: [b]256x256 pixel[/b] (PNG)
• Nền: [b]trong suốt[/b] (alpha=0 ở ngoài nhân vật) để dễ tách nền
• Có margin ~27px quanh nhân vật (như các sprite hiện tại)
• Đặt file tại: [b]res://assets/sprites/characters/char_<ten_nhan_vat>.png[/b]
• Có thể dùng tool: GIMP / Photoshop / Aseprite / removebg.com

[color=#44aaff]Bước 2: Thêm entry trong CharacterData[/color]
Mở [b]scripts/character_data.gd[/b], thêm vào mảng CHARACTERS:
[code]{
    "id": 13,
    "name": "Tên Nhân Vật",
    "title": "Tiêu đề",
    "file": "char_ten_nhan_vat",
    "type": CharType.WARRIOR,  # WARRIOR | MAGE | BRAWLER | ASSASSIN | CLASSIC
    "hp_bonus": 15.0,
    "speed_bonus": 5.0,
    "dart_bonus": 0,
    "skill_bonus": "dash",  # dash | shield | multishot | classic
    "skill_desc": "Mô tả kỹ năng",
    "lore": "Câu chuyện nhân vật...",
    "color": Color(0.8, 0.2, 0.2),
},[/code]

[color=#44aaff]Bước 3: (Tùy chọn) Thêm mã quà tặng[/color]
Trong [b]character_data.gd[/b], thêm vào [b]GIFT_CODES[/b]:
[code]"mã_của_bạn": { "type": "character", "value": 13 },[/code]

[color=#44aaff]Bước 4: Test[/color]
- Mở project trong Godot 4.7
- F5 để chạy
- Vào Settings → Nhập mã (nếu có) → Đổi mã
- Vào Nhân Vật để xem nhân vật mới
- Bấm Trang Bị rồi chơi thử

────────────────────────────

[color=#ffaa00][b]6. SCALE RELAY SERVER[/b][/color]

• Mỗi room chứa 10-20 players, dùng ~50MB RAM
• 50 rooms = ~2.5GB RAM, 1000+ concurrent players
• Database SQLite đủ cho ~10000 players
• Nếu cần lớn hơn: chuyển sang PostgreSQL + Redis + multiple relay nodes

[color=#44aaff]Environment variables[/color]:
• [b]WS_PORT[/b] (25671) - WebSocket port
• [b]HTTP_PORT[/b] (25672) - HTTP API port
• [b]MATCH_MIN_PLAYERS[/b] (10) - Min players per match
• [b]MATCH_MAX_PLAYERS[/b] (20) - Max players per match
• [b]MATCH_TIMEOUT_MS[/b] (30000) - Queue timeout trước khi fill bot
• [b]TICK_RATE_MS[/b] (50) - State sync rate (50ms = 20 ticks/s)
• [b]MAX_ROOMS[/b] (50) - Số phòng tối đa đồng thời
• [b]ROOM_TIMEOUT_MS[/b] (3600000) - Auto xóa phòng trống sau 1h

────────────────────────────

[color=#ffaa00][b]7. DEBUG & MONITORING[/b][/color]

[color=#44aaff]Xem log server:[/color]
[code]docker logs -f phitieu-relay[/code]

[color=#44aaff]Kiểm tra số rooms/clients:[/color]
[code]curl http://localhost:25672/health[/code]

[color=#44aaff]Kiểm tra config:[/color]
[code]curl http://localhost:25672/api/status[/code]

[color=#44aaff]Test WebSocket bằng wscat:[/color]
[code]npm install -g wscat
wscat -c ws://localhost:25671/ws
> {"type":"login","data":{"playerId":"test","name":"Test","characterId":0}}
> {"type":"matchmaking_join","data":{"name":"Test","characterId":0}}[/code]

────────────────────────────

[color=#ffaa00][b]8. TÌM & SỬA LỖI THƯỜNG GẶP[/b][/color]

[color=#ff6666]Client báo "Server offline":[/color]
1. Kiểm tra server chạy: [code]curl http://your-server:25672/health[/code]
2. Kiểm tra URL trong Settings → Mạng (Server URL)
3. Nếu dùng HTTPS: phải dùng wss://, không phải ws://
4. Kiểm tra firewall mở port 25671 và 25672

[color=#ff6666]Matchmaking kẹt "Đang tìm trận...":[/color]
- Server cần ít nhất 2 người để bắt đầu (sau 30s timeout)
- Nếu 1 mình: bot AI sẽ tự fill sau 30s

[color=#ff6666]Lag / high ping:[/color]
- TICK_RATE_MS default 50ms (20 ticks/s). Tăng lên 33 (30 ticks/s) nếu cần mượt hơn (tốn CPU hơn)
- Chọn VPS gần user (Singapore/Hanoi cho VN)

[color=#ff6666]DB locked error:[/color]
- SQLite đã bật WAL mode, không nên bị lock
- Nếu vẫn bị: restart container, hoặc chuyển sang PostgreSQL

────────────────────────────

[color=#ffaa00][b]9. RELEASE & BUILD[/b][/color]

[color=#44aaff]Build game (local):[/color]
1. Mở project trong Godot 4.7
2. Project → Export → chọn preset (Android/Windows/Linux)
3. Bấm Export Project

[color=#44aaff]Build relay server image:[/color]
[code]cd relay-server
docker build -t phitieu-relay .
docker tag phitieu-relay ghcr.io/mhieuhonda/phitieu-relay:latest
docker push ghcr.io/mhieuhonda/phitieu-relay:latest[/code]

[color=#44aaff]GitHub Actions:[/color]
Workflow trong [b].github/workflows/build-release.yml[/b] tự build 3 nền tảng song song khi push tag v*.*.*

────────────────────────────

[color=#ffaa00][b]10. MÃ QUÀ TẶNG HIỆN CÓ[/b][/color]

• [b]MÃ BÍ MẬT 1[/b] - Mở khóa nhân vật "Hieu Louis - Classic"
• [b]MÃ BÍ MẬT 2[/b] - Mở khóa trang "Hướng Dẫn Cho Admin" (trang này)

(Lưu ý: Mã bí mật chỉ admin mới biết, không được tiết lộ ra ngoài)

Để thêm mã mới: edit [b]GIFT_CODES[/b] trong [b]scripts/character_data.gd[/b]

────────────────────────────

[color=#888888]Phi Tiêu Dịch Chuyển v2.2 - Admin Guide[/color]
"""

func _admin_locked_text() -> String:
        return """🔒 HƯỚNG DẪN CHO ADMIN

Phần này chỉ dành cho admin server.

Để mở khóa, nhập mã quà tặng bí mật (chỉ admin mới biết)
trong Settings → Nhập Mã Quà Tặng.

Lưu ý: Mã này không mở khóa nhân vật,
chỉ mở khóa trang tài liệu admin này.
"""

func _on_back_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/menu.tscn")
