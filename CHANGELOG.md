# Changelog

Tất cả thay đổi quan trọng của dự án sẽ được ghi lại tại đây.

Định dạng dựa trên [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/),
và dự án tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
