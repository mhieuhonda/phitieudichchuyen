# Changelog

Tất cả các thay đổi đáng chú ý của dự án sẽ được ghi lại trong file này.

## [0.5] - 2026-08-02

### Fixed
- **[CRITICAL] Fix lỗi đen màn hình khi vào game**: HUD scene không được instance đúng trong main.tscn, gây null reference crash
- **[CRITICAL] Fix player._die() đặt is_alive = true thay vì false**: Player không bao giờ "chết" thật
- Fix AI take_damage flash sai (trắng→trắng thay vì đỏ→trắng)
- Fix pickup collision mask không phát hiện AI (mask=1 → mask=9, thêm layer AI)
- Fix map.gd reference zone_fill không tồn tại (dead code removed)
- Fix map.tscn GridLines và ZoneFill node không dùng

### Added
- **Tính năng phát hiện thiết bị tự động**: Phát hiện CPU, GPU, RAM, màn hình để tự chọn đồ họa phù hợp
- **Loading screen**: Màn hình tải khi chuyển scene, tránh đen màn hình trên máy yếu
- **FPS counter**: Hiển thị FPS khi bật toggle trong cài đặt
- **Device info**: Hiển thị thông tin thiết bị trong HUD và Settings
- **Quality notice**: Thông báo tự động chọn đồ họa khi lần đầu chơi
- Device tier detection: LOW_END / MID_RANGE / HIGH_END
- GPU detection: Nhận diện GPU mạnh (RTX, Radeon RX, Apple M, Adreno 7, Mali-G7)
- Auto-save graphics quality khi người dùng thay đổi thủ công

### Changed
- Menu chuyển scene qua loading screen thay vì trực tiếp
- Version label cập nhật v0.5
- New feature label cập nhật v0.5
- Settings menu thêm device info label
- HUD thêm FPSLabel, DeviceLabel, QualityNotice
- Copyright năm cập nhật 2026
- Export version cập nhật 0.5

## [0.4] - 2026-08-02

### Fixed
- Fix GitHub Actions CI/CD: build APK và EXE tự động thành công
- Fix lỗi "Can't load cached ext-resource" khi export trên CI
- Fix lỗi "Code Signing: Could not find keystore" khi export Android APK
- Sử dụng Xvfb để chạy Godot editor import trên môi trường headless
- Patch export_presets.cfg với debug keystore tự động

### Changed
- Cải thiện workflow Build & Release: import project đúng cách trước khi export
- Cập nhật README chuẩn hóa

## [0.3] - 2026-08-02

### Added
- Polish giao diện và trải nghiệm mobile
- Cải thiện điều khiển joystick ảo

## [0.2] - 2026-08-02

### Added
- Hoàn thiện gameplay cơ bản
- Thêm AI đối thủ
- Thêm vật phẩm nhặt (phi tiêu, hồi máu)

## [0.1] - 2026-08-02

### Added
- Prototype offline đầu tiên
- Cơ chế ném phi tiêu và dịch chuyển
- Map cơ bản
