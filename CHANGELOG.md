# Changelog

Tất cả thay đổi quan trọng của dự án sẽ được ghi lại tại đây.

Định dạng dựa trên [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/),
và dự án tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-08-02

### Thêm mới
- **⚡ Dịch chuyển giữa chừng (Mid-Flight Teleport)**: Nhấn Space khi phi tiêu đang bay để dịch chuyển tới vị trí phi tiêu hiện tại — cơ chế cốt lõi mới
- **Đường dự đoán (Predicted Line)**: Hiển thị quỹ đạo dự đoán khi phi tiêu đang bay
- **Menu chính**: Màn hình tiêu đề với nút "Chơi Ngay", "Cài Đặt", "Thoát"
- **Combo system**: Tiêu diệt liên tiếp trong 2s được cộng điểm nhân (x1.5, x2.0, x2.5...)
- **Respawn tự động**: Chết 3s sau tự respawn tại vị trí ngẫu nhiên trong vùng an toàn
- **Vật phẩm (Pickups)**: Hồi máu (xanh) và hồi phi tiêu (vàng) rải trên bản đồ, respawn sau 10s
- **Screen shake**: Rung màn hình khi dịch chuyển và nuốt đối thủ
- **AI thông minh hơn**:
  - Né tránh phi tiêu đang bay hướng tới (dodge)
  - Săn mồi (hunting): di chuyển về phía người chơi
  - Dịch chuyển giữa chừng (mid-flight teleport)
  - Lead aim: dự đoán vị trí người chơi khi nhắm
  - Tự động đi vào vùng an toàn khi ngoài vòng bo
- **HUD nâng cao**:
  - Combo hiển thị (x2, x3...)
  - Kích thước người chơi
  - Thời gian game
  - Hint "Space: Dịch chuyển tới phi tiêu đang bay!"
  - Phân biệt phi tiêu bay + cắm
- **Vòng bo nhanh dần**: Thu nhỏ với tốc độ tăng dần (x1.1 mỗi lần)
- **Chướng ngại vật đa dạng**: Hình chữ nhật + hình tròn, màu sắc đa dạng
- **Indicator**: Hiển thị thanh xanh khi có thể dịch chuyển, flash đỏ khi bị đánh
- **Tầm bay tối đa**: Phi tiêu bay tối đa 1500px rồi tự cắm
- **GitHub Actions**: Auto-build signed APK khi tạo release
- **Điều khiển mũi tên**: Hỗ trợ WASD + Arrow keys

### Thay đổi
- Người chơi respawn thay vì phải restart toàn bộ game
- AI có thêm trạng thái HUNTING và DODGING
- Vòng bo thu nhỏ nhanh dần thay vì tuyến tính
- Thông số game được tổ chức thành export groups
- `all_darts` thay thế `stuck_darts` — theo dõi cả phi tiêu đang bay và cắm
- Menu chính là scene mặc định (thay vì game scene)

## [0.1.0] - 2024-08-02

### Thêm mới
- Scene bản đồ với tường bao và chướng ngại vật ngẫu nhiên
- Nhân vật người chơi với di chuyển chậm (WASD)
- Hệ thống ném phi tiêu: aim & release (chuột phải kéo thả), quỹ đạo đường thẳng
- Phi tiêu cắm vào bề mặt (tường, sàn, chướng ngại vật)
- Phi tiêu tự biến mất sau 5 giây (nhấp nháy cảnh báo trước 1.5s)
- Hệ thống dịch chuyển tức thời (Space) tới phi tiêu đã cắm
- Cơ chế "nuốt" đối thủ khi dịch chuyển trúng
- Phi tiêu trúng đối thủ gây sát thương (25 HP)
- AI đối thủ (5 bot) với trạng thái: Idle, Wandering, Aiming, Throwing, Teleporting, Fleeing
- AI tự respawn sau 3 giây khi bị tiêu diệt
- HUD: điểm số, thanh máu, số phi tiêu, đếm ngược vòng bo
- Vòng bo thu nhỏ dần (mỗi 30s, giảm 50px)
- Sát thương ngoài vòng bo (10 HP/s)
- Hiệu ứng particles khi dịch chuyển (biến mất/xuất hiện)
- Hiệu ứng particles khi chết
- Kill feed thông báo
- Cảnh báo ngoài vòng bo
- Màn hình Game Over với nút restart (R)
- Cấu hình export Android (min SDK 24 / Android 7.0)
- Cấu hình export Windows & Linux
