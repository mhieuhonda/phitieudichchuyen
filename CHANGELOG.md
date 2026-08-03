# Changelog

## v1.1 - Phi Tiêu Dịch Chuyển (2026-08-03)

### 🐛 Bug Fixes
- **Nhân vật quá to**: Sửa lỗi sprite scale bị set 1.0 thay vì 0.3×ratio, nhân vật giờ hiển thị đúng kích thước
- **Nhân vật không hiện**: Sửa lỗi visual size mismatch giữa sprite và collision shape
- **Không thể dịch chuyển sau khi bắn**: Sửa lỗi dart stuck ngay khi spawn do `_on_body_entered` trigger với player body. Thêm spawn immunity 0.08s cho dart
- **Không thể dịch chuyển khi mũi tên đang bay**: Cùng fix với trên - dart giờ bay tự do và teleportable ngay lập tức
- **Nút dịch chuyển chậm**: Sửa lỗi teleport button chỉ emit signal khi release, giờ teleport ngay khi press/click
- **Không thể ăn đối thủ**: Sửa collision layers - player giờ có thể phát hiện AI layer (8), tăng teleport_kill_radius từ 40→50
- **Tốc độ di chuyển chậm**: Tăng walk_speed từ 80→120 để game mượt hơn

### ✨ Improvements
- **Giao diện gọn gàng**: Thiết kế lại HUD với TopBar gọn, bỏ các label thao (SizeLabel, TimeLabel, ControlsLabel, DeviceLabel, QualityNotice)
- **Map đẹp hơn**: Giữ nguyên grid + obstacles + decorations, đổi màu zone circle sang xanh lá mềm hơn
- **UI elements không bị scale**: HpBar, NameLabel, SizeIndicator không bị to khi player size tăng
- **Kill feed font nhỏ hơn**: 13px thay vì mặc định, không che màn hình

### 🎮 Gameplay
- Tăng teleport_kill_radius: 40 → 50 (dễ ăn đối thủ hơn)
- Tăng walk_speed: 80 → 120 (di chuyển nhanh hơn)
- Dart spawn immunity: 0.08s (tránh dart stuck ngay khi ném)

---

## v1.0 - Phi Tiêu Dịch Chuyển (Initial Release)

### Features
- Ném phi tiêu và dịch chuyển tới vị trí phi tiêu
- 5 AI đối thủ với hành vi thông minh
- Vòng bo thu nhỏ dần
- 3 kỹ năng chủ động: Dash, Shield, Multishot
- Pickups: Hồi máu + Tăng phi tiêu
- Xếp hạng cuối trận
- Hồi 10% HP khi ăn đối thủ
- Mobile controls + Joystick ảo
- Tự động chọn đồ họa theo thiết bị
