# Changelog

## [0.3.0] - 2024-08-02

### Thêm mới
- **Sprite đẹp mắt**: Tất cả nhân vật, phi tiêu, vật phẩm có sprite PNG thay vì ColorRect
  - Nhân vật: hình tròn với mắt, miệng, bóng, mũi tên hướng (10 màu khác nhau)
  - Phi tiêu: mũi nhọn bạc, thân vàng, cánh đỏ
  - Vật phẩm: icon hồi máu (thập tự xanh), hồi phi tiêu (phi tiêu vàng)
  - Joystick: vòng ngoài + cần trong suốt
  - Nút bấm: Teleport (sét xanh) + Throw (phi tiêu vàng)
- **Cài đặt đồ họa (Settings)**: 4 mức Cực Thấp → Cao
  - Cực Thấp: Tắt mọi hiệu ứng (0% particle, không glow, không trail)
  - Thấp: 30% particle, tắt glow
  - Trung Bình: 70% particle, glow nhẹ
  - Cao: 100% tất cả hiệu ứng
- **Joystick ảo**: Di chuyển bằng joystick cho mobile (góc dưới trái)
- **Mobile controls**: Nút Teleport + Nút Throw (góc dưới phải)
- **Auto-detect mobile**: Tự động hiển thị joystick trên Android
- **SettingsManager**: Singleton autoload, lưu/đọc cài đặt từ file
- **FPS counter**: Bật/tắt trong Settings
- **Screen shake toggle**: Bật/tắt trong Settings
- **Volume slider**: Âm thanh & nhạc (chuẩn bị cho v0.4)
- **GitHub Actions fix**: Sửa lỗi build APK, thêm keystore signing tự động

### Thay đổi
- ColorRect → Sprite2D cho tất cả nhân vật, phi tiêu, vật phẩm
- Thêm SettingsManager autoload (thứ 2, sau GameManager)
- Player scene: thêm TeleportReadyIndicator (Sprite2D)
- AI scene: load sprite tự động theo ai_id
- Particle được điều chỉnh theo cài đặt đồ họa
- Menu: thêm nút "Cài Đặt" → chuyển sang Settings scene
- Main scene: thêm VirtualJoystick + MobileControls
- GitHub Actions: fix sed command cho keystore, thêm sleep sau import

## [0.2.0] - 2024-08-02

### Thêm mới
- Dịch chuyển giữa chừng (Mid-Flight Teleport)
- Đường dự đoán (Predicted Line)
- Menu chính, combo system, respawn tự động
- Vật phẩm, screen shake, AI thông minh hơn
- Vòng bo nhanh dần, HUD nâng cao
- GitHub Actions: auto-build APK on release

## [0.1.0] - 2024-08-02

### Thêm mới
- Prototype offline đầu tiên
- Hệ thống ném phi tiêu, cắm, dịch chuyển
- AI đối thủ, HUD cơ bản, vòng bo
