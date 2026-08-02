# Changelog

Tất cả các thay đổi đáng chú ý của dự án sẽ được ghi lại trong file này.

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
