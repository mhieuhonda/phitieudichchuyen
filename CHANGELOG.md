# Changelog

Tất cả các thay đổi đáng chú ý của dự án sẽ được ghi lại trong file này.

## [0.6] - 2026-08-02

### Fixed
- **[CRITICAL] Fix GitHub Actions không tự build khi tạo release**: 3 bước upload bị hardcode `tag_name: v0.4` thay vì dùng tag hiện tại. Giờ dùng `${{ github.ref_name }}` (hoặc input cho `workflow_dispatch`), gộp 3 bước upload thành 1 bước duy nhất để tránh race condition
- **[CRITICAL] Fix AI dart không gây sát thương player**: `ai_player.gd._throw_dart_ai()` không kết nối signal `dart_hit_player` → dart của AI bay qua player mà không gây damage. Giờ AI có thể giết player bằng phi tiêu
- **[CRITICAL] Fix mobile throw không hoạt động**: `mobile_controls.gd` emit `throw_started` và `throw_ended` cùng vị trí (trung tâm nút) → drag distance = 0 → dart không có hướng/power. Giờ theo dõi vị trí ngón tay khi kéo và emit vị trí thực khi thả
- **[CRITICAL] Fix scene files dùng cú pháp Godot 4 sai**: Tất cả `.tscn` dùng `script = ExtResource("res://scripts/foo.gd")` (path-as-ID) là cú pháp không hợp lệ trong Godot 4. Giờ dùng `[ext_resource type="Script" path="..." id="N"]` + `ExtResource("N")` chuẩn. Cũng sửa `instance=load("...")` thành `instance=ExtResource("N")`
- Fix camera shake không hoạt động: `GameManager.screen_shake_requested` signal chưa được kết nối tới `main.gd` (hàm `apply_screen_shake` tồn tại nhưng là dead code). Giờ kết nối properly
- Fix chướng ngại vật tròn nhìn giống hình vuông: `_create_obstacles` dùng `ColorRect` (vuông) cho obstacle hình tròn → nhìn rất gớm. Giờ dùng `Polygon2D` 32 đỉnh + `Line2D` viền
- Fix `DART_REFILL` pickup sai semantics: pickup này gọi `player.heal(15)` (hồi máu) thay vì nạp phi tiêu. Giờ có `player.refill_darts(bonus, duration)` tăng giới hạn phi tiêu +1 trong 8s
- Fix HUD controls hint nói "R: Chơi lại (khi chết)" nhưng R không làm gì. Giờ hint là "Esc: Quay lại menu" và thực sự hoạt động
- Fix `ai_player.gd` static `ai_name_index` không reset khi restart game → tên bot bị lặp/index sai sau nhiều game. Giờ có `AIPlayer.reset_name_index()` gọi trong `main._ready()`
- Fix `ai_player.gd._check_teleport_kill()` không check `is_instance_valid(p)` → potential crash
- Fix `ai_player.gd` duplicate `add_to_group("ai_players")` (đã khai báo trong .tscn)
- Fix `player._check_teleport_kill()` không check `is_instance_valid(ai)`
- Fix `ai_player._check_teleport_kill()` `current_size += ...` không clamp → AI có thể to vô hạn
- Fix `hud.gd._on_screen_shake` loop `for i in int(duration / 0.02)` có thể = 0 khi duration nhỏ
- Fix unaccented Vietnamese trong `settings.tscn` (CAI DAT → CÀI ĐẶT, Rung man hinh → Rung màn hình, v.v.)
- Fix `hud.gd` kill feed dùng unaccented Vietnamese ("Ban da tieu diet" → "Bạn đã tiêu diệt")
- Fix player death không hiện tên kẻ giết → giờ hiện "BẠN BỊ <TÊN> TIÊU DIỆT!" thay vì generic
- Fix `ai_player.gd._respawn()` không reset `ai_name` label
- Fix outside-zone death không set `last_killer_name` → giờ hiện "BẠN BỊ VÒNG BO TIÊU DIỆT!"

### Added
- **Sprite nhân vật hoàn toàn mới**: Viết lại tất cả sprite bằng Python+PIL với:
  - Nhân vật ninja top-down: bóng đổ, body tròn gradient, headband màu (10 màu AI + 1 xanh dương player), 2 mắt trắng có pupil đen + catch light, headband tails (2 tam giác), gloss highlight cho 3D look
  - Dart: shuriken-style với glow, gradient steel, center bolt
  - Pickup health: medkit vòng tròn trắng + chữ thập đỏ + glow
  - Pickup dart: shuriken 4 cánh vàng + glow
  - Buttons (teleport/throw): tròn gradient + icon + glow
  - Joystick base/stick: gradient + glow
  - Teleport effect: sparkle cross + radial gradient
  - Icon.svg mới: ninja + dart + teleport trail
- `class_name AIPlayer` declared để có thể reference tĩnh (`AIPlayer.reset_name_index()`)
- `player.refill_darts(bonus, duration)` method cho DART_REFILL pickup
- `player.get_killer_name()` method để HUD hiển thị tên kẻ giết
- `player.dart_bonus` field + timer cho temporary max dart boost
- Escape key handling trong `main.gd._input()` để quay lại menu giữa game
- Kill feed message khi player chết (mention tên kẻ giết)
- Kill feed message khi AI chết (mention tên kẻ giết nếu có)
- `pickup.gd` pickup xoay nhẹ (`sprite.rotation`) để nổi bật
- HUD `dart_count_label` hiển thị bonus phi tiêu (+1) khi active

### Changed
- `export_presets.cfg`: version/code 5 → 6, version/name "0.5" → "0.6", file_version/product_version "0.5.0.0" → "0.6.0.0"
- `menu.gd` new_feature_label cập nhật v0.6 changelog
- `menu.gd` version_label = "v0.6 - Sprite Rewrite"
- `menu.tscn` NewFeatureLabel text = "MỚI v0.6: Sprite nhân vật mới + fix AI dart + mobile throw!"
- `menu.tscn` VersionLabel text = "v0.6 - Sprite Rewrite"
- `hud.gd` controls hint: "WASD: Di chuyển" (bỏ "chậm"), "Esc: Quay lại menu" thay cho "R: Chơi lại"
- `hud.gd` game_over_label hiển thị tên kẻ giết nếu có
- `main.gd._on_player_died` không còn `pass` — giờ emit kill feed
- `main.gd._on_player_respawned` không còn `pass` — giờ emit kill feed
- `main.gd._on_ai_died` xử lý 3 case: player giết AI, AI khác giết AI, zone/unknown giết AI
- `mobile_controls.gd` track finger position during drag và emit `throw_ended` với vị trí thực
- `player.gd._throw_dart` cập nhật `aim_current_pos` từ `mouse_pos` argument (trước đó dùng stale field)
- `player.gd._throw_dart` fallback direction `Vector2.RIGHT` nếu drag = 0
- `player.gd._input` handle `InputEventScreenDrag` cho mobile aim line update
- `player.gd._physics_process` giảm `dart_bonus_timer` và reset `dart_bonus` khi hết hạn
- `player._start_aiming` và `_throw_dart` dùng `_get_max_darts()` (bao gồm dart_bonus) thay vì `GameManager.max_darts_per_player` trực tiếp
- `ai_player.gd` thêm `name_label.text = ai_name` trong `_ready()`
- GitHub Actions workflow: thêm step "Resolve release tag" dùng `github.ref_name` hoặc input
- GitHub Actions workflow: gộp 3 bước upload (APK/Windows/Linux) thành 1 bước với `files: |` multi-line
- GitHub Actions workflow: thêm `generate_release_notes: true` để tự tạo release notes từ commits
- GitHub Actions workflow: thêm `name: Phi Tiêu Dịch Chuyển ${{ steps.tag.outputs.name }}` cho release title
- GitHub Actions workflow: thêm `inputs.tag_name` cho `workflow_dispatch` để có thể trigger manual
- GitHub Actions workflow: tăng timeout import từ 120s → 180s

### Removed
- Dead code: `main.gd.apply_screen_shake` giờ được gọi qua signal thay vì dead code
- `hud.gd._input` "restart" action handler không dùng (player tự respawn)

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
