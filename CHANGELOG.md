# Changelog

Tất cả các thay đổi đáng chú ý của dự án sẽ được ghi lại trong file này.

## [0.7] - 2026-08-02

### Fixed
- **[CRITICAL] Fix game không full màn hình**: `project.godot` có `window/size/mode=2` (MAXIMIZED) thay vì 3 (FULLSCREEN). Giờ set mode=3 + runtime enforce fullscreen qua `DisplayServer.window_set_mode()` trong `settings_manager._ready()`
- **[CRITICAL] Fix hướng màn hình sai (portrait thay vì landscape)**: `project.godot` có `window/handheld/orientation=1` (PORTRAIT). Giờ set =4 (SENSOR_LANDSCAPE) + runtime enforce `DisplayServer.screen_set_orientation(SCREEN_SENSOR_LANDSCAPE)` trên mobile
- **[CRITICAL] Fix game trông "nhỏ" trên màn hình**: `Camera2D.zoom=0.6` làm game world chỉ hiện 60% kích thước thật. Giờ zoom=1.0 (full size)
- **[CRITICAL] Fix mobile controls không hiện trên iOS**: visibility check chỉ có `OS.has_feature("mobile") or OS.has_feature("android")`, thiếu iOS. Giờ thêm `OS.has_feature("ios") or DisplayServer.is_touchscreen_available()`
- **[CRITICAL] Fix touch index không track khi nhấn nút throw**: `mobile_controls.gd` dùng `button_down`/`button_up` signal nhưng không biết được touch index nào đã nhấn. Giờ track touch index trực tiếp trong `_input()` bằng cách check `InputEventScreenTouch` press trong rect của nút
- Fix `_get_active_touch_pos()` luôn trả về Vector2.ZERO (dead code) - removed trong refactor mobile_controls
- Fix `virtual_joystick.gd._ready()` chỉ tính `center_pos` 1 lần - sai khi resize/rotation. Giờ refresh mỗi frame trong `_process` và mỗi input
- Fix `ai_player.take_damage_from` dùng single-line if có semicolon `if current_hp <= 0: current_hp = 0; kill(attacker)` khó đọc. Giờ multi-line block
- Fix `dart.gd._ready()` set `sprite.scale = Vector2(0.5, 0.5)` trùng với .tscn (redundant)
- Fix `player.tscn` AimLine color vàng (1,1,0,0.8) thay vì đỏ như user yêu cầu. Giờ Color(1, 0.15, 0.15, 0.9)
- Fix HUD controls hint không mô tả cơ chế mobile mới

### Added
- **Nút bắn phi tiêu mới (Mobile v0.7)**: Cơ chế "hold-rotate-release":
  - Ấn giữ nút → kere chỉ màu ĐỎ xuất hiện từ player
  - Kéo ngón tay quanh nút để xoay hướng bắn
  - Kéo xa hơn = lực mạnh hơn (min → max throw power)
  - Thả nút → bắn phi tiêu theo hướng đã ngắm
- `player.start_aim_mobile()`, `update_aim_mobile(direction, power)`, `throw_dart_mobile(direction, power)` - public API cho mobile
- `player.aim_direction`, `player.aim_power` fields cho direction-based aim (thay vì slingshot)
- `player.aim_touch_index` field để distinguish desktop vs mobile aim mode
- `player._spawn_dart(direction, power)` helper chia sẻ giữa desktop/mobile
- `mobile_controls.throw_started`, `throw_aim_updated`, `throw_ended` signals (không còn pass position, pass direction + power)
- `settings_manager._is_touch_device()` helper - check mobile/android/ios/touchscreen
- `settings_manager._apply_display_settings()` - enforce fullscreen + landscape at runtime
- Mobile controls hit area mở rộng 20px mỗi chiều để dễ chạm hơn
- Joystick hit area mở rộng 80px padding để dễ chạm bằng ngón cái
- `config/version="0.7"` trong project.godot

### Changed
- `project.godot`: window mode 2 → 3 (fullscreen), orientation 1 → 4 (sensor_landscape)
- `scenes/main.tscn`: Camera2D zoom 0.6 → 1.0
- `scenes/player.tscn`: AimLine width 3.0 → 4.0, color vàng → đỏ
- `scenes/mobile_controls.tscn`: dùng anchors bottom-right thay vì absolute offset, button size 80x80, stretch_mode=0 (SCALE)
- `scenes/virtual_joystick.tscn`: dùng anchors bottom-left thay vì absolute offset, base fills container, stick anchored center
- `scenes/hud.tscn`: tất cả elements dùng anchors (top-left, top-right, bottom, center) thay vì absolute pixel offsets
- `scenes/menu.tscn`: tất cả buttons/labels dùng anchor center, responsive trên mọi màn hình
- `scenes/settings.tscn`: dùng HBoxContainer cho quality buttons, anchors center cho các controls khác
- `scenes/loading.tscn`: dùng anchor center cho tất cả elements
- `scripts/mobile_controls.gd`: hoàn toàn rewrite với direction-based aim mechanic + touch index tracking
- `scripts/virtual_joystick.gd`: refresh center_pos mỗi frame, dùng `stick.global_position` thay vì `stick.position`, hit area padding 80px
- `scripts/player.gd`: tách aim logic thành desktop slingshot (`_start_aim_desktop`, `_throw_dart_desktop`) và mobile direction-based (`start_aim_mobile`, `update_aim_mobile`, `throw_dart_mobile`)
- `scripts/main.gd`: wire up `throw_aim_updated` signal mới
- `scripts/settings_manager.gd`: thêm `_is_touch_device()`, `_apply_display_settings()`, enforce fullscreen + landscape
- `scripts/hud.gd`: controls hint mô tả cơ chế mobile mới (hold-red line-rotate-release)
- `scripts/menu.gd`: version_label = "v0.7 - Full-screen + Mobile Aim", new_feature_label mô tả v0.7
- `scripts/settings_menu.gd`: `$QualityVeryLow` → `$QualityButtons/QualityVeryLow` (do dùng HBoxContainer)
- `export_presets.cfg`: version/code 6 → 7, version/name "0.6" → "0.7", file_version "0.6.0.0" → "0.7.0.0"
- `README.md`: cập nhật badge v0.7, thêm section "Lỗi đã fix trong v0.7", cập nhật "Cách chơi" cho mobile aim mới

### Removed
- `mobile_controls._get_active_touch_pos()` (dead code)
- `mobile_controls._on_throw_down`, `_on_throw_up` (button_down/up signals không còn dùng, thay bằng `_input` tracking)
- `mobile_controls.aim_start_pos`, `aim_current_pos`, `active_throw_touch_index` (thay bằng `aim_touch_index`, `aim_touch_pos`)
- `player._start_aiming()`, `player._throw_dart()` (public, replaced by `_start_aim_desktop`/`_throw_dart_desktop` for desktop + `start_aim_mobile`/`throw_dart_mobile` for mobile)
- `player._update_aim_line()` color logic (Color(t, 1.0-t, 0.0) gradient) - replaced by fixed red color
- `player._calculate_power()` (slingshot power) - renamed to `_calculate_power_slingshot()` for clarity

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
