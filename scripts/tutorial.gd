extends Control

## Tutorial - Hướng dẫn chi tiết cách chơi (v4.0)
## Scene: scenes/tutorial.tscn
## Multi-page interactive guide. 12 trang covering:
##   1. Giới thiệu cốt truyện
##   2. Điều khiển cơ bản
##   3. Phi tiêu & Dịch chuyển
##   4. Hệ thống nhân vật (12 chars)
##   5. Hệ thống Class/Loài (10 loài)
##   6. Hệ thống Quest
##   7. Hệ thống đồng đội
##   8. Hệ thống kỹ năng
##   9. HL Coin & Tiền Bối shop
##   10. Uy tín & Thân mật
##   11. Thành tựu
##   12. Multiplayer online (mới v4.0)

@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var page_indicator: Label = $CenterContainer/VBox/PageIndicator
@onready var content: RichTextLabel = $CenterContainer/VBox/ScrollContainer/Content
@onready var prev_button: Button = $CenterContainer/VBox/NavHBox/PrevButton
@onready var next_button: Button = $CenterContainer/VBox/NavHBox/NextButton
@onready var finish_button: Button = $CenterContainer/VBox/NavHBox/FinishButton
@onready var skip_button: Button = $CenterContainer/VBox/SkipButton

var current_page: int = 0

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.15, 0.13, 0.25, 0.98)

# Nội dung 12 trang hướng dẫn (BBCode)
const PAGES = [
	{
		"title": "📖 Trang 1/12 — Giới thiệu",
		"content": """[b][color=#ffaa00]PHI TIÊU DỊCH CHUYỂN[/color][/b] — game 2D top-down với cơ chế độc đáo: [b]ném phi tiêu → dịch chuyển tức thời tới phi tiêu → tiêu diệt đối thủ[/b].

[b]Cốt truyện:[/b]
Bạn là một [b]Mutant[/b] (quái đột biến) không có hình dạng rõ. Trong thế giới 10 loài động vật thông minh, bạn là kẻ lạc lối. Để sinh tồn và trở thành huyền thoại, bạn phải:
• Vượt [b]20 ải[/b] với độ khó tăng dần (kết thúc bằng Boss cuối 12 triệu HP)
• Khám phá [b]thế giới mở[/b] 4 vùng: Rừng Thông, Núi Băng, Vương Quốc RuY Băng, Đế Quốc Kẹo
• Mua [b]class[/b] từ Tiền Bối để hòa mình vào các loài
• Chiêu mộ [b]đồng đội[/b], học [b]kỹ năng[/b] từ thủ lĩnh, tích lũy [b]uy tín[/b] và [b]thân mật[/b]

[b]Mục tiêu cuối cùng:[/b] Trở thành [b]Vạn Thú Quyền[/b] — bậc thầy tất cả 10 loài.

[color=#44ff88][b]Bắt đầu đâu?[/b][/color] Vào menu chính → "📖 HƯỚNG DẪN" (bạn đang xem) → "⚔ VƯỢT ẢI" để chơi PvE → "🌍 THẾ GIỚI" để vào meta-game → "🌐 MULTIPLAYER" để chơi online (mới v4.0)."""
	},
	{
		"title": "📖 Trang 2/12 — Điều khiển",
		"content": """[b][color=#ffaa00]BÀN PHÍM (PC):[/color][/b]
• [b]W / A / S / D[/b] hoặc [b]Mũi tên ←↑↓→[/b] — Di chuyển nhân vật
• [b]Space[/b] — Ném phi tiêu (giữ để lấy lực, thả để ném) + Dash/Teleport
• [b]P[/b] — Tạm dừng game (pause)
• [b]R[/b] — Chơi lại ải (restart)
• [b]Esc[/b] — Quay lại menu trước /Thoát

[b][color=#ffaa00]CHUỘT (PC):[/color][/b]
• Click trái — Ném phi tiêu về phía con trỏ
• Giữ + kéo — Lấy lực ném (dài hơn = mạnh hơn)

[b][color=#ffaa00]MOBILE (cảm ứng):[/color][/b]
• Joystick ảo (góc trái dưới) — Di chuyển
• Nút bấm (góc phải dưới) — Ném phi tiêu
• Vuốt — Dash/Teleport

[b][color=#ffaa00]TỐC ĐỘ FRAME:[/color][/b]
• Game chạy 60 FPS. Server multiplayer chạy 20 tick/giây."""
	},
	{
		"title": "📖 Trang 3/12 — Phi tiêu & Dịch chuyển",
		"content": """[b][color=#ffaa00]CƠ CHẾ PHI TIÊU DỊCH CHUYỂN:[/color][/b]

[b]1. Ném phi tiêu[/b] — Ấn [b]Space[/b] (hoặc click chuột) để ném 1 phi tiêu theo hướng đang hướng tới. Phi tiêu bay thẳng cho đến khi:
   • Trúng tường → biến mất
   • Trúng AI/đối thủ → gây damage + biến mất
   • Bay hết màn hình → biến mất

[b]2. Dịch chuyển[/b] — Khi có phi tiêu đang bay trên màn hình, ấn [b]Space[/b] lần nữa để [b]dịch chuyển tức thời[/b] tới vị trí phi tiêu gần nhất. Cooldown: 0.15s.

[b]3. Tiêu diệt đối thủ[/b] — Khi dịch chuyển tới phi tiêu đang trúng AI/đối thủ, bạn [b]nuốt[/b] chúng → [b]hồi 10% HP[/b] + tăng size + điểm.

[b]Chiến thuật:[/b]
• Ném phi tiêu xiên → dịch chuyển để ambush từ phía sau
• Ném phi tiêu xuyên tường (nếu char có skill "Dash xuyên tường") → trốn/kết liễu
• Ném nhiều phi tiêu (Multishot skill) → tạo "vùng dịch chuyển" rộng
• Dash [b]vô hình 1s[/b] (Hắc Vũ character) → né đòn

[b]Lưu ý:[/b] Boss cuối có [b]12 triệu HP[/b] — bạn không thể nuốt được, chỉ gây damage chip bằng dart (100/lần) và dịch chuyển (250k/lần)."""
	},
	{
		"title": "📖 Trang 4/12 — Hệ thống nhân vật",
		"content": """[b][color=#ffaa00]12 NHÂN VẬT — 4 LOẠI:[/color][/b]

[b]🐉 Chiến Binh (Warrior)[/b] — HP cao, dash mạnh
• Rồng Đỏ, Sói Tím, Cọp Xanh

[b]🦊 Pháp Sư (Mage)[/b] — Nhiều phi tiêu (multishot)
• Phượng Xanh, Cáo Hồng, Thiên Long

[b]🐻 Quyền Sư (Brawler)[/b] — Khiên chống đòn
• Hổ Vàng, Gấu Nâu

[b]🦉 Sát Thủ (Assassin)[/b] — Tốc độ cao, dash đặc biệt
• Báo Lục, Diều Cam, Chồn Bạc, Hắc Vũ

[b][color=#ffaa00]BONUS THEO NHÂN VẬT:[/color][/b]
• [b]HP bonus[/b] (Gấu Nâu +30, Hổ Vàng +25, Rồng Đỏ +15, ...)
• [b]Speed bonus[/b] (Hắc Vũ +30, Chồn Bạc +25, Báo Lục +20, ...)
• [b]Dart bonus[/b] (Thiên Long +2 phi tiêu, Phượng Xanh/Cáo Hồng +1, ...)
• [b]Skill bonus[/b] đặc biệt (Dash mạnh hơn, Multishot bắn 4-5, Shield lâu hơn, ...)

[color=#44ff88][b]Cách chọn:[/b][/color] Menu → "NHÂN VẬT" → Click nhân vật muốn dùng → Đỏ = đang chọn. [b]Tất cả 12 nhân vật đều mở khóa sẵn[/b] (v3.0+)."""
	},
	{
		"title": "📖 Trang 5/12 — Hệ thống Class / Loài",
		"content": """[b][color=#ffaa00]10 LOÀI ĐỘNG VẬT[/color][/b] — Bạn (Mutant) có thể [b]mua class[/b] để biến thành 1 trong 6 loài chính:

[b]6 loài chính (class khởi đầu, mua ở Tiền Bối shop):[/b]
• 🐰 Thỏ (Magic 3 / Physical 0 / Agility 3) — Hiệu trưởng trường phép Núi Băng
• 🐭 Chuột (3/1/2) — Vua Chuột Lữ Khách (đi khắp map)
• 🦊 Cáo (0/3/3) — Cáo Lão chòi canh Rừng Thông
• 🐱 Mèo (1/2/3) — Nữ Hoàng vương quốc RuY Băng
• 🐻 Gấu (1/3/2) — Vua Gấu Đế Quốc Kẹo
• 🐴 Ngựa (2/1/3) — Tướng Ngựa biên giới Núi Băng

[b]4 loài phụ (không mua được, gặp thủ lĩnh trong thế giới):[/b]
• 🦌 Hươu (Rừng Thông rải rác)
• 🦁 Sư Tử (đấu trường RuY Băng, phe Mèo)
• 🐺 Sói (tầng hầm lâu đài Kẹo, quân bí mật)
• 🐕 Chó (trốn chui trong Đế Quốc Kẹo)

[b][color=#ffaa00]CLASS ẢNH HƯỞNG COMBAT:[/color][/b]
• Class khớp với loài thủ lĩnh → [b]học được skill[/b] của loài đó
• Class main species → [b]+1 dart, +10% HP[/b] trong combat
• Đổi class = cần [b]mặt nạ[/b] (mua 150 HL Coin). [b]Class đầu tiên tự áp dụng miễn phí.[/b]

[color=#44ff88][b]Lưu ý quan trọng (v4.0):[/b][/color] Bạn [b]KHÔNG cần class để nhận quest[/b]. Trước v4.0 có 5 quest chặn cứng nếu chưa mua class — đã sửa thành "khuyên dùng" (nhận được nhưng khó hơn)."""
	},
	{
		"title": "📖 Trang 6/12 — Hệ thống Quest",
		"content": """[b][color=#ffaa00]QUEST — Nhận ở quán rượu, hoàn thành để nhận thưởng.[/color][/b]

[b]Cách nhận quest:[/b]
1. Menu → "🌍 THẾ GIỚI" → Chọn vùng (4 vùng) → "🍺 Quán Rượu"
2. Tab [b]Quest Board[/b] → Xem quest khả dụng ở vùng đó
3. Click [b]"Nhận"[/b] → Quest vào danh sách đang làm (tối đa 5 quest cùng lúc)
4. Click [b]"⚔ Vào Ải"[/b] → Vào scene combat với mục tiêu quest

[b]3 loại mục tiêu quest:[/b]
• [b]kill X[/b] — Tiêu diệt X quái AI (spawn theo wave)
• [b]boss mini[/b] — Tiêu diệt 1 mini-boss (HP 4x, size lớn)
• [b]find target[/b] — Tìm và chạm vào NPC mục tiêu

[b]4 tier độ khó:[/b] easy / medium / hard / very_hard (scale HP, damage, dodge, pursuit, max deaths)

[b]Phần thưởng:[/b]
• [b]HL Coin[/b] (50-350 mỗi quest)
• [b]Uy tín[/b] với loài tương ứng (+5 đến +25)
• Bonus nếu class khớp với quest

[b][color=#ffaa00]SAU KHI HOÀN THÀNH:[/b][/b]
• Tự động quay về quán rượu + nhận thưởng
• [b]Đồng đội giải tán[/b] (mỗi thành viên lấy 5% HL Coin làm phí thuê + chiến lợi phẩm)
• Quest đã hoàn thành [b]không lặp lại[/b]

[color=#44ff88][b]Mẹo:[/b][/color] Để đạt "Bá Chủ Quest" (10 quest) nhanh, làm quest easy trước, mua class phù hợp để được bonus uy tín."""
	},
	{
		"title": "📖 Trang 7/12 — Hệ thống đồng đội",
		"content": """[b][color=#ffaa00]ĐỘI TẠM THỜI — Chiêu mộ NPC ở quán rượu.[/color][/b]

[b]Cách chiêu mộ:[/b]
1. Quán Rượu → Tab [b]Recruitment[/b]
2. Xem danh sách 5-8 NPC ngẫu nhiên (đổi mỗi lần vào)
3. NPC có 3 cấp sao: [b]1 sao[/b] (20 HL), [b]2 sao[/b] (60 HL), [b]3 sao[/b] (200 HL — đặc biệt, số lượng có hạn)
4. Click [b]"Chiêu Mộ"[/b] → Trừ tiền → Có tỉ lệ thành công (dựa trên uy tín với loài đó)
5. Tối đa [b]4 đồng đội + 1 player = 5 thành viên[/b]

[b]Bonus cho player khi có đội:[/b]
• [b]+% HP[/b] = tổng Physical đồng đội × 1%
• [b]+% Damage[/b] = (Physical + Magic)/2 × 0.5%
• [b]+% Speed[/b] = tổng Agility × 1%
• [b]+% Magic[/b] = tổng Magic × 1%

[b]Cấp sao NPC = sức mạnh:[/b]
• 1 sao: tổng chỉ số 8, 1 skill cơ bản
• 2 sao: tổng 10, 2 skill
• 3 sao: tổng 12, 3 skill (có ultimate)

[b]Độ thân mật (intimacy):[/b] Mỗi NPC 3 sao có thanh intimacy 0-100. Chiêu mộ thành công +5, hoàn thành quest có reward_intimacy +n. Đạt 100 mở achievement "Tri Kỷ" (250 HL Coin).

[color=#ff0000][b]Lưu ý:[/b][/color] Đồng đội [b]chỉ tồn tại trong 1 quest[/b]. Sau quest, họ lấy 5% HL Coin mỗi người làm phí + chiến lợi phẩm rồi mất hút."""
	},
	{
		"title": "📖 Trang 8/12 — Hệ thống kỹ năng",
		"content": """[b][color=#ffaa00]SKILL — Học từ thủ lĩnh loài.[/color][/b]

[b]Cách học skill:[/b]
1. Menu → "🌍 THẾ GIỚI" → Vào vùng có thủ lĩnh loài đó
2. Click [b]"👑 Gặp Thủ Lĩnh"[/b]
3. Nếu class hiện tại [b]khớp với loài thủ lĩnh[/b] → Học được skill
4. Phí: [b]100 HL Coin[/b] mỗi lần
5. Skill áp dụng vĩnh viễn (cho đến khi đổi class)

[b]10 thủ lĩnh — 10 skill:[/b]
• 🐰 Hiệu Trưởng Thỏ Trắng — [b]Vụt Tai Phép Thuật[/b] (dash 2 lần + ảo ảnh)
• 🐭 Vua Chuột Lữ Khách — [b]Lủi Trốn[/b] (dịch chuyển ngắn + bất tử 1s)
• 🦊 Cáo Lão Chòi Canh — [b]Ảo Cáo[/b] (tạo 3 ảo ảnh đánh lạc hướng 2s)
• 🐱 Nữ Hoàng Mèo Anh — [b]Cửu Mệnh[/b] (hồi 80% HP khi sắp chết, 1 lần/ải)
• 🐻 Vua Gấu Kẹo Mạch Nha — [b]Gấu Trầm Mộc[/b] (bất tử 3s + phản damage 50%)
• 🐴 Tướng Ngựa Biên Cương — [b]Kỵ Sĩ Xung Kích[/b] (dash xuyên tường + knockback)
• 🦌 Hươu Cổ Trận Địa — [b]Hươu Vương[/b] (+30% tốc toàn đội 5s)
• 🦁 Sư Tử Đấu Trường — [b]Sư Hổ Giận[/b] (damage x2 + không slow 4s)
• 🐺 Sói Tầng Hầm — [b]Sói Đơn Độc[/b] (dash 3 lần, mỗi dash gây damage)
• 🐕 Chó Lạc Đàn Bí Ẩn — [b]Khứu Giác Bí Ẩn[/b] (nhìn qua tường + crit 100% 3s)

[color=#44ff88][b]Achievement "Vạn Thú Quyền":[/b][/color] Học skill từ tất cả 10 thủ lĩnh → nhận [b]1000 HL Coin[/b]. Cần đổi class nhiều lần (mua mặt nạ)."""
	},
	{
		"title": "📖 Trang 9/12 — HL Coin & Tiền Bối",
		"content": """[b][color=#ffaa00]HL COIN — Tiền tệ trong game.[/color][/b]

[b]Cách kiếm HL Coin:[/b]
• Hoàn thành quest: 50-350 coin/quest
• Hoàn thành achievement: 30-1000 coin/achievement
• Ăn coin trong combat (pickup rơi ra khi giết quái)
• Vượt ải mới (bonus milestone)

[b]Cách tiêu HL Coin:[/b]
• Mua class (200 coin) — Tiền Bối shop
• Mua mặt nạ đổi class (150 coin) — Tiền Bối shop
• Chiêu mộ đồng đội (20-200 coin) — Quán rượu
• Học skill (100 coin) — Thủ lĩnh

[b][color=#ffaa00]TIỀN BỐI SHOP:[/color][/b]
NPC đặc biệt dành riêng cho Mutant (bạn). Xuất hiện ngẫu nhiên ở 1 trong 4 vùng, [b]vị trí thay đổi mỗi 2 lần thăm[/b].

[b]Cách tìm Tiền Bối:[/b]
1. Menu → "🌍 THẾ GIỚI" → Xem vùng nào có dòng "[b]💰 Tiền Bối đang ở đây![/b]"
2. Click vùng đó → "💰 Tiền Bối" → Vào shop
3. Mua class đầu tiên → [b]tự áp dụng miễn phí[/b] (không cần mặt nạ)
4. Lần thăm thứ 2 → Tiền Bối di chuyển vùng khác

[b]Mặt nạ đổi class:[/b]
• Mua 1 mặt nạ = 150 HL Coin
• Cần 1 mặt nạ mỗi lần đổi class (sau lần đầu)
• [b]Đổi class KHÔNG reset chỉ số player[/b] (Magic/Physical/Agility giữ nguyên)
• Mở achievement "Đổi Thân Phận" (80 HL Coin)"""
	},
	{
		"title": "📖 Trang 10/12 — Uy tín & Thân mật",
		"content": """[b][color=#ffaa00]UY TÍN (REPUTATION) — Tương tác với 10 loài.[/color][/b]

Thanh uy tín mỗi loài: [b]-100 đến +100[/b]. Mặc định = 0.

[b]Cách tăng uy tín:[/b]
• Hoàn thành quest có reward_rep (+5 đến +25)
• Chiêu mộ NPC loài đó (+5 mỗi lần)
• Học skill từ thủ lĩnh loài đó (+10)

[b]Cách giảm uy tín:[/b]
• Nội chiến loài (-8 đến -15)
• (Không có cách chủ động giảm — game không phạt player)

[b]Tác động của uy tín:[/b]
• [b]Tỉ lệ chiêu mộ NPC[/b] = 30% + (uy tín / 200) → uy tín 100 = 80% tỉ lệ
• Uy tín < 0 → tỉ lệ chiêu mộ < 30% (khó thuê NPC loài đó)
• [b]Uy tín 100 với 1 loài[/b] → mở achievement "Huyền Thoại Uy Tín" (200 HL Coin)

[b][color=#ffaa00]NỘI CHIẾN LOÀI:[/color][/b]
Event ngẫu nhiên 5% mỗi ngày trong game (5 phút = 1 ngày). 1 loài hoặc tất cả loài giảm uy tín tạm thời. Kéo dài 120s. Mở achievement "Sống Sót Nội Chiến" (120 HL Coin).

[b][color=#ffaa00]THÂN MẬT (INTIMACY):[/color][/b]
Chỉ áp dụng cho [b]NPC 3 sao[/b] (mỗi loài có 1 NPC 3 sao đặc biệt).
• Thanh 0-100
• Chiêu mộ NPC 3 sao: +5 intimacy
• Quest có reward_intimacy: +n
• Đạt 100 → mở achievement "Tri Kỷ" (250 HL Coin)"""
	},
	{
		"title": "📖 Trang 11/12 — Thành tựu",
		"content": """[b][color=#ffaa00]19 THÀNH TỰU — Xem ở Sổ Tay.[/color][/b]

[b]Cách xem:[/b] Menu → "🌍 THẾ GIỚI" → "📜 Sổ Tay" → Tab [b]Thành tựu[/b]

[b]Danh sách thành tựu (phần thưởng HL Coin):[/b]

[color=#ffaa00]Combat:[/color]
• Máu Đầu Tiên (50) — Tiêu diệt quái đầu tiên
• Sát Thủ Boss (500) — Tiêu diệt boss màn 20
• Hạ Gục 5 Liên Tiếp (80) — Kill streak 5
• Bất Tử Chi Thân (200) — Kill streak 10
• Hoàn Hảo (100) — Hoàn ải mà không chết
• Tốc Độ Ánh Sáng (150) — Hoàn ải dưới 60s

[color=#ffaa00]Vượt ải:[/color]
• Người Mới Vượt Ải (100) — Vượt ải 5
• Chiến Binh Lành Lẽ (200) — Vượt ải 10
• Cao Thủ (300) — Vượt ải 15
• Huyền Thoại Vượt Ải (1000) — Hoàn thành tất cả 20 ải

[color=#ffaa00]Meta-game:[/color]
• Đội Trưởng (30) — Chiêu mộ đồng đội đầu tiên
• Đội Hình Khủng (100) — Có NPC 3 sao trong đội
• Sưu Tầm Class (300) — Sở hữu tất cả 6 class khởi đầu
• Vạn Thú Quyền (1000) — Học skill từ tất cả 10 thủ lĩnh
• Đổi Thân Phận (80) — Đổi class lần đầu bằng mặt nạ
• Huyền Thoại Uy Tín (200) — Uy tín 100 với 1 loài
• Tri Kỷ (250) — Thân mật 100 với NPC 3 sao
• Bá Chủ Quest (150) — Hoàn thành 10 quest
• Sống Sót Nội Chiến (120) — Trải qua 1 cuộc nội chiến

[b]Tổng giá trị:[/b] 4,510 HL Coin nếu hoàn thành tất cả."""
	},
	{
		"title": "📖 Trang 12/12 — Multiplayer Online (v4.0)",
		"content": """[b][color=#ffaa00]MULTIPLAYER — Chơi online với bạn bè (mới v4.0).[/color][/b]

[b]Cách vào:[/b]
1. Menu → "🌐 MULTIPLAYER"
2. Nhập tên hiển thị (username)
3. [b]Tạo phòng mới[/b] hoặc [b]Vào phòng có sẵn[/b] (tối đa 4 người/phòng)
4. Host ấn [b]"Bắt đầu"[/b] → Tất cả vào arena deathmatch

[b][color=#ffaa00]SERVER:[/color][/b]
• Domain: [b]wss://phitieu.louis.vangioitutien.com/ws[/b]
• Chạy trên VPS của tôi (qua Traefik reverse proxy + TLS)
• WebSocket protocol (chấp nhận được qua HTTP/HTTPS proxy)
• Server-authoritative: server quyết định hit, vị trí, score

[b][color=#ffaa00]CHƠI THẾ NÀO:[/color][/b]
• WASD — Di chuyển
• Space — Ném phi tiêu
• Dash — Tự động khi có phi tiêu đang bay
• [b]Mục tiêu:[/b] Tiêu diệt player khác bằng phi tiêu
• [b]Hồi sinh[/b] sau 3s khi chết
• [b]Score:[/b] +1 mỗi kill, hiển thị trên HUD
• [b]Vòng đấu:[/b] 3 phút, player có score cao nhất thắng

[b][color=#ffaa00]CHAT:[/color][/b]
• Nhập text + Enter để gửi cho cả phòng
• Tự động cuộn, hiển thị 10 tin gần nhất

[b][color=#ffaa00]RỜI PHÒNG:[/color][/b]
• Click "← Rời phòng" → Về lobby
• Mất kết nối 30s → Tự kick

[color=#44ff88][b]Lưu ý:[/b][/color] Multiplayer là [b]mode riêng[/b], không ảnh hưởng tiến độ PvE. Player của bạn trong multiplayer luôn có stats cơ bản (HP 100, dart damage 25) để cân bằng.

[color=#ffaa00][b]CHÚC BẠN CHƠI GAME VUI VẺ![/b][/color] 🎯✨"""
	},
]

func _ready():
	prev_button.pressed.connect(_on_prev)
	next_button.pressed.connect(_on_next)
	finish_button.pressed.connect(_on_finish)
	skip_button.pressed.connect(_on_finish)
	_style_button(prev_button, Color(0.4, 0.9, 1.0))
	_style_button(next_button, Color(0.4, 0.9, 0.5))
	_style_button(finish_button, Color(1.0, 0.85, 0.3))
	_style_button(skip_button, Color(1.0, 0.4, 0.3))
	content.bbcode_enabled = true
	_show_page(0)
	AudioManager.play_music("menu")

func _style_button(btn: Button, accent: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = COL_BG
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	var hover = normal.duplicate()
	hover.bg_color = COL_BG_HOVER
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.9)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)

func _show_page(idx: int):
	current_page = clamp(idx, 0, PAGES.size() - 1)
	var page = PAGES[current_page]
	title_label.text = page["title"]
	content.text = page["content"]
	page_indicator.text = "Trang %d / %d" % [current_page + 1, PAGES.size()]
	prev_button.disabled = current_page == 0
	prev_button.modulate = Color(1, 1, 1, 0.4) if prev_button.disabled else Color.WHITE
	next_button.visible = current_page < PAGES.size() - 1
	finish_button.visible = current_page == PAGES.size() - 1

func _on_prev():
	AudioManager.play_ui_click()
	_show_page(current_page - 1)

func _on_next():
	AudioManager.play_ui_click()
	_show_page(current_page + 1)

func _on_finish():
	AudioManager.play_confirm()
	TutorialManager.mark_tutorial_seen()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_finish()
