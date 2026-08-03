# Changelog

## v1.4 - Phi Tiêu Dịch Chuyển (2026-08-03)

### 🔧 Rà Soát Toàn Diện Godot 4.7 (Clean Sweep)
Bản v1.3 đã fix lỗi blocker chính (class_name conflict + ternary parse), nhưng còn sót một số lỗi runtime và logic nhỏ. v1.4 rà soát lại **mọi file GDScript + mọi scene** để đảm bảo sạch sẽ tuyệt đối trên Godot 4.7 stable.

### 🐛 Bug Fixes (Critical)
- **FIX: `dart.gd` gán trực tiếp `monitoring = false/true` khi Area2D đang trong SceneTree.** Godot 4.x cấm thay đổi `monitoring` trực tiếp khi node đã ở trong tree → sinh lỗi runtime. Đã đổi sang `set_deferred("monitoring", value)` ở cả `_ready()` (line 35) và `_physics_process()` (line 70).
- **FIX: `pickup.gd` hồi máu AI dựa trên `GameManager.player_max_hp`.** Khi AI nhặt health/dart refill, máu được clamp về max HP của **player** thay vì max HP của chính AI → AI có thể vượt quá giới hạn máu riêng. Đã sửa thành `ai.current_max_hp` ở cả 2 nhánh (HEALTH và DART_REFILL).

### 🛠️ Code Quality
- **REFAC: `AudioManager` thêm API công khai `is_music_playing()`.** Trước đây `loading_screen.gd` phải truy cập trực tiếp `AudioManager._music_player.playing` (private field) → vi phạm encapsulation. Giờ dùng `AudioManager.is_music_playing()`.
- **REFAC: Đổi tên biến/bán `name` thành `sfx_name` / `track_name` trong `AudioManager`.** Trong Godot 4.x, `name` là property của Node; dùng `name` làm biến cục bộ gây shadow và nhầm lẫn. Đã rename cho rõ nghĩa.
- **CLEANUP: Bỏ pattern `name = list[randi() % list.size()]` → `sfx_name = list[randi() % list.size()]`.**

### ✅ Verification
- ✅ Project import sạch 100% trên Godot 4.7 stable (199 assets reimport, 0 errors)
- ✅ Headless run 200+ frames: 0 SCRIPT ERROR, 0 push_error, 0 push_warning
- ✅ Editor mode load sạch: 0 deprecated warnings
- ✅ Tất cả 18 file GDScript parse sạch (no mixed indentation, no old 4.2 API)
- ✅ Tất cả 14 scene file dùng node types 4.7 hợp lệ (Sprite2D, CharacterBody2D, Area2D, …)
- ✅ Không còn `find_node`, `yield`, `update()`, `Tween.new()`, `KinematicBody`, `Sprite`, `YSort`, `VisualServer`, `OS.get_window*`, `add_color_override`, `rect_*`, `margin_*`, `pause_mode`…
- ✅ Không còn `class_name` trùng autoload singleton
- ✅ Tất cả signal connect dùng cú pháp 4.x: `signal.connect(callable)`
- ✅ Tất cả tween dùng `create_tween()` + `tween_property/callback`
- ✅ Tất cả `monitoring`/`disabled`/`monitorable` đổi runtime dùng `set_deferred`

### 📦 Release
- Bump `config/version` từ `1.3` → `1.4` trong `project.godot`
- Menu chính hiển thị badge v1.4 + tóm tắt thay đổi
- README.md viết lại chuẩn cho v1.4

---

## v1.3 - Phi Tiêu Dịch Chuyển (2026-08-03)

### 🔧 Godot 4.7 Compatibility (CRITICAL)
- **Fix: `class_name CharacterData` xung đột autoload singleton.** Godot 4.7 strict check không cho phép `class_name` trùng với autoload đã đăng ký. Đây là nguyên nhân gốc rễ khiến **toàn bộ** script reference CharacterData (GameManager, player.gd, character_screen.gd, …) fail parse → GameManager autoload không khởi tạo → game trắng tinh khi vào trận, không hiện nhân vật, không di chuyển, không cập nhật chỉ số.
- **Fix: parse error ternary-in-tuple.** Cú pháp `"%s%d" % ("+" if x else "", y)` không còn được chấp nhận trong Godot 4.7. Chuyển sang `"%s%d" % ["+" if x else "", y]` để parse sạch.
- Cập nhật `config/features` từ `4.2` → `4.7`.
- Cập nhật `config/version` từ `1.2` → `1.3`.

### 🐛 Bug Fixes (User-Reported)
- ✅ Khi vào trận không hiện một cái gì → sửa
- ✅ Không hiện nhân vật → sửa
- ✅ Di chuyển không phản hồi → sửa
- ✅ Góc chỉ số bên trên không thay đổi → sửa
- ✅ Khi vào màn hình nhân vật bị lag ngay → sửa (script parse error mỗi frame)
- ✅ Không thể trang bị nhân vật → sửa (equip_btn giờ connect đúng)
- ✅ Không thể quay lại → sửa (back_btn giờ connect đúng)
- ✅ Không hiện danh sách nhân vật → sửa (`_populate_char_list()` giờ chạy được)

### ✨ New Features
- **Kéo thả UI customization (v1.3):**
  - 6 nút có thể kéo: Joystick, Ném, Dịch chuyển, Dash, Shield, Multishot
  - "Khu vực kéo thả" hiển thị preview trực quan
  - Nút **"💾 LƯU VỊ TRÍ NÚT"** để persist layout vào `user://settings.cfg`
  - Nút **"↺ ĐẶT VỊ TRÍ VỀ MẶC ĐỊNH"** để restore
  - Layout lưu dạng tọa độ chuẩn hóa 0..1 theo viewport (hoạt động mọi độ phân giải)
- **SettingsManager API mới:**
  - `custom_button_positions: Dictionary`
  - `use_custom_layout: bool`
  - `get_button_position(name, default) -> Vector2`
  - `set_button_position(name, normalized_pos)`
  - `clear_custom_layout()` / `enable_custom_layout()`
- **Áp dụng runtime:**
  - `mobile_controls.gd` đọc layout khi `_ready()` và đặt vị trí 5 nút
  - `virtual_joystick.gd` đọc layout khi `_ready()` và đặt vị trí joystick
  - `ui_opacity` áp dụng cho toàn mobile controls
  - `button_size` scale áp dụng cho 5 nút mobile
  - `joystick_size` scale áp dụng cho joystick

### 🛠️ Maintenance
- `.gitignore` bổ sung `*.uid`
- `README.md` viết lại chuẩn cho v1.3 (Godot 4.7, hướng dẫn kéo thả, lịch sử đầy đủ)
- Menu chính hiển thị badge v1.3

---

## v1.2 - Phi Tiêu Dịch Chuyển (2026-08-03)

### Features
- 12 nhân vật ninja/warrior với sprite đẹp, tách nền
- Màn hình Nhân Vật: xem chỉ số, kỹ năng, trang bị
- Màn hình Chỉnh Sửa Giao Diện (slider): kích thước joystick, nút, opacity
- Character bonus: mỗi nhân vật có HP, tốc độ, phi tiêu, kỹ năng riêng
- Fix: không bị khóa di chuyển khi ném phi tiêu
- Fix: teleport kill kiểm tra shield đúng cách
- Map đẹp hơn với nhiều decoration
- UI gọn gàng hơn

---

## v1.1 - Phi Tiêu Dịch Chuyển (2026-08-03)

### 🐛 Bug Fixes
- **Nhân vật quá to**: Sửa lỗi sprite scale bị set 1.0 thay vì 0.3×ratio
- **Nhân vật không hiện**: Sửa lỗi visual size mismatch
- **Không thể dịch chuyển sau khi bắn**: Sửa lỗi dart stuck ngay khi spawn do `_on_body_entered` trigger với player body. Thêm spawn immunity 0.08s cho dart
- **Không thể dịch chuyển khi mũi tên đang bay**: Cùng fix với trên
- **Nút dịch chuyển chậm**: Sửa lỗi teleport button chỉ emit signal khi release
- **Không thể ăn đối thủ**: Sửa collision layers - player giờ có thể phát hiện AI layer (8)
- **Tốc độ di chuyển chậm**: Tăng walk_speed từ 80→120

### ✨ Improvements
- Giao diện gọn gàng hơn
- Map đẹp hơn
- UI elements không bị scale khi player size tăng

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
