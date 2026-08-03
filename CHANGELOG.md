# Changelog

Tất cả các thay đổi đáng chú ý của dự án sẽ được ghi lại trong file này.

## [1.0] - 2026-08-03

### Major Release - "Phi Tiêu Dịch Chuyển v1.0"

### Added
- **🎯 3 Kỹ năng chủ động**:
  - **Dash (Q)**: Lướt nhanh 200px theo hướng di chuyển, cooldown 8s, dùng để né/truy đuổi
  - **Shield (E)**: Khiên miễn damage 3 giây, cooldown 15s, có sprite khiên hex rune xoay
  - **Multishot (Shift)**: Bắn 3 phi tiêu cùng lúc với spread 0.3 rad, cooldown 12s
  - AI cũng có thể dùng dash để né dart hoặc rút lui
  - HUD hiển thị cooldown từng skill
  - 3 nút skill riêng trên mobile (DASH, SHIELD, MULTI)
- **❤️ Hệ thống máu mới**:
  - Max HP scale theo size: `max_hp = 100 + (size - 20) * 4`
  - Size 60 (max) = 260 HP max
  - Hồi **10% max HP** mỗi khi ăn đối thủ (cả player và AI)
  - Signal `player_hp_changed(hp, max_hp)` để HUD cập nhật dynamic max HP
- **⏱️ Trận đấu 5 phút**:
  - `match_duration = 300.0` trong GameManager
  - HUD hiển thị thời gian đếm ngược lớn ở giữa-top
  - Cảnh báo âm thanh khi còn 30s cuối
  - Tự động kết thúc trận khi hết giờ
- **🏆 Bảng xếp hạng cuối trận**:
  - Khi hết giờ hoặc trận kết thúc, hiện ResultsPanel full-screen
  - Hiển thị rank (#1 vàng, #2 bạc, #3 đồng), tên, điểm, số kill
  - Player được highlight màu cyan + "(Bạn)"
  - Nút "Chơi lại" và "Menu chính"
  - Sort theo score desc, rồi kills desc
- **🗺️ Map vẽ lại hoàn chỉnh**:
  - Grid pattern: lưới 100px nhẹ + lưới 500px đậm
  - 3 loại obstacles: đá (shape bất đối xứ), cây (tán 3 lớp), thùng gỗ (X chữ)
  - 20 obstacles đặt chiến lược
  - Decoration layer: 40 bụi cỏ, hoa, vết nứt (không collision)
  - Vòng bo: Line2D width 4 + Polygon2D fill nhẹ, màu đỏ/cam sống động
  - Tường viền nâu đá với border highlight
- **🎨 Sprite tách nền hoàn chỉnh** (regenerated bằng Python PIL):
  - Player/AI: ninja warrior tròn với body color, headband accent, mắt trắng+pupil, belt+buckle vàng, rim light, gradient highlight
  - 10 màu AI: red, green, purple, yellow, orange, cyan, pink, lime, teal, brown
  - Dart: metallic tip + shaft silver gradient + fletching đỏ với shadow
  - Pickup health: glowing halo + disc trắng + cross đỏ
  - Pickup dart: glowing halo + disc vàng + mini dart icon
  - Buttons: teleport (cyan swirl), throw (target rings), shield (hex rune)
  - Joystick: recessed base + glossy knob
  - **Tất cả corner pixels có alpha=0** (trong suốt hoàn toàn, không còn nền đen)
- **✨ Hiệu ứng thêm**:
  - Particle khi dash (cyan, hướng ngược dash direction)
  - Particle khi shield (blue, surround player)
  - Particle khi buff multishot (orange)
  - Particle khi kill (red explosion, gravity)
  - Particle khi level-up (gold, gravity âm)
  - Smoke puff khi throw dart
  - Floating text: "+100", "+26 HP", "-25", "BLOCK!" với tween rise+fade
  - Hit flash: sprite modulate red 0.05s
- **🎮 Input actions mới**: skill_dash (Q), skill_shield (E), skill_multishot (Shift)

### Fixed
- **[CRITICAL] AI teleport kill không kill được player**: `_check_teleport_kill` trong `ai_player.gd` chỉ gọi `p.take_damage_from(50, self)` → nếu player còn 50+ HP thì không chết nhưng AI vẫn ghi score/kill. Giờ fix: nếu player có shield → skip; ngược lại gọi `take_damage_from(9999.0, self)` để chắc chắn chết, chỉ ghi score/kill nếu player thực sự chết
- **[CRITICAL] AI dart giết đối thủ không ghi score/kill**: `_on_dart_hit_player` trong `ai_player.gd` chỉ gọi `take_damage_from` không check kết quả. Giờ check `was_alive` trước và `is_alive` sau, nếu chuyển từ alive→dead thì AI được +score/kill/size/heal
- **[CRITICAL] Player dart giết AI không ghi score/kill**: Tương tự, `_on_dart_hit_player` trong `player.gd` giờ check kết quả và ghi nhận +score/kill/size/heal + floating text
- **[HIGH] Player chết không reset skill state**: `_die()` không reset `shield_active`, `is_dashing`, `multishot_ready`. Giờ reset tất cả + hide shield_sprite
- **[HIGH] AI respawn không reset leaderboard**: `_respawn()` không set alive=true trong leaderboard. Giờ gọi `GameManager.set_ai_alive(ai_id, true)`, `update_ai_score(ai_id, 0)`, `update_ai_kills(ai_id, 0)`
- **[HIGH] Player respawn không update max HP**: `_respawn()` set `player_size` về initial nhưng không gọi `update_player_max_hp_for_size()`. Giờ gọi để max HP reset về 100
- **[MEDIUM] HUD hiển thị max HP cũ khi size thay đổi**: `hp_bar.max_value` hardcode 100. Giờ update theo `GameManager.player_max_hp` động
- **[MEDIUM] Match không có giới hạn thời gian**: Trận chạy vô tận. Giờ có 5 phút + bảng xếp hạng
- **[MEDIUM] Sprite nền đen opaque**: Player/AI sprite có nền đen (0,0,0,255) → nhìn như ô vuông. Giờ regenerate với nền trong suốt hoàn toàn
- **[LOW] `Line2D.get_point()` không tồn tại trong Godot 4**: Map.gd dùng `border.get_point(0)` → error. Giờ dùng `get_point_position(0)`
- **[LOW] `add_theme_font_size_override("font", ...)` sai tên**: Godot 4 dùng `"font_size"`. Đã fix
- **[LOW] `True`/`False` viết hoa**: GDScript dùng `true`/`false` viết thường. Đã fix trong game_manager.gd

### Changed
- `scripts/game_manager.gd`: Thêm `match_duration`, `hp_per_size_unit`, `heal_percent_on_kill`, skill cooldown config; thêm `compute_max_hp_for_size()`, `update_player_max_hp_for_size()`, `heal_percent()`, leaderboard API (`register_ai_leaderboard`, `update_ai_score`, `update_ai_kills`, `set_ai_alive`, `get_sorted_leaderboard`), `end_match()`; thêm `game_over` signal với leaderboard data; thêm `match_time_changed` signal; đổi `player_max_hp` từ const thành dynamic var
- `scripts/player.gd`: Thêm skill system (Dash/Shield/Multishot), shield_sprite, `skill_cooldowns` dict, `_update_skills()`, `_do_dash()`, `_do_shield()`, `_do_multishot()`, `_deactivate_shield()`, `is_shield_active()`, `_spawn_dash_effect()`, `_spawn_shield_effect()`, `_spawn_buff_effect()`, `_spawn_kill_effect()`, `_spawn_level_up_effect()`, `_spawn_smoke_puff()`, `_spawn_floating_text()`; `_check_teleport_kill` giờ heal 10% max HP; `_on_dart_hit_player` giờ check kill và ghi score; `take_damage_from` giờ check shield; `_die` reset skill state; `_respawn` update max HP
- `scripts/ai_player.gd`: Thêm `current_max_hp`, `ai_kills`, `ai_shield_active`, `dash_cooldown`; `_check_teleport_kill` giờ kill ngay (không phải 50 dmg); `_on_dart_hit_player` check kill; `_grow_size` update max HP; `_heal_on_kill` hồi 10% max HP; `_ai_dash` cho AI; `_spawn_level_up_effect`; `_respawn` reset leaderboard
- `scripts/hud.gd`: Thêm `MatchTimerLabel`, `SkillPanel` (3 labels), `ResultsPanel` (title + list + 2 buttons); `_update_skill_ui()`; `_on_match_time_changed()`; `_on_game_over()`; `_show_results()`; `_on_hp_changed()` cập nhật dynamic max HP; `_get_dart_info` hiển thị [MULTI!] khi multishot_ready
- `scripts/map.gd`: Rewrite hoàn toàn - `_setup_background`, `_create_grid` (2 layer grid), `_create_walls` với border, `_create_obstacles` với 3 types (rock/tree/crate), `_create_decorations` (grass/flower/crack), `_update_zone_visual` với fill polygon
- `scripts/mobile_controls.gd`: Thêm 3 skill button handlers (`skill_dash_pressed`, `skill_shield_pressed`, `skill_multishot_pressed` signals), `_dash_rect`, `_shield_rect`, `_multishot_rect`, touch tracking cho 3 skill buttons
- `scripts/main.gd`: Connect skill signals từ mobile_controls, `_on_mobile_skill_dash/shield/multishot` handlers, connect `game_over` signal
- `scenes/player.tscn`: Thêm `ShieldSprite` (load shield.png), `SkillCooldownLabel` (hidden), sprite scale 0.3
- `scenes/ai_player.tscn`: Sprite scale 0.3
- `scenes/dart.tscn`: Sprite scale 0.25, collision radius 10, collision_mask 29
- `scenes/pickup.tscn`: Sprite scale 0.4, collision radius 18, TypeLabel hidden
- `scenes/map.tscn`: Thêm `GridLayer`, `DecorLayer`, `ZoneFill` (Polygon2D)
- `scenes/hud.tscn`: Thêm `MatchTimerLabel`, `SkillPanel` (3 sub-labels), `ResultsPanel` (title + list + 2 buttons)
- `scenes/mobile_controls.tscn`: Thêm 3 skill buttons (DASH/SHIELD/MULTI), reposition teleport/throw
- `project.godot`: Version 1.0, thêm input actions skill_dash/shield/multishot

## [0.9] - 2026-08-03

### Fixed
- **[CRITICAL] Fix joystick không di chuyển nhân vật**: `main.gd` dùng `$VirtualJoystick` và `$MobileControls` (tìm con trực tiếp), nhưng các node này là con của `UILayer` (CanvasLayer) → trả về `null` → joystick không bao giờ được connect với player, mobile control signals không bao giờ được wire up. Giờ sửa thành `$UILayer/VirtualJoystick` và `$UILayer/MobileControls`
- **[CRITICAL] Fix multi-touch: joystick dừng khi nhấn nút khác**: `virtual_joystick.gd` có mouse fallback đặt `is_pressed = false` khi BẤT KỲ mouse release nào xảy ra. Trên mobile, `emulate_mouse_from_touch=true` khiến mọi touch đều sinh mouse event → khi user nhấn nút throw/teleport, mouse release của nút đó reset joystick. Giờ tách biệt hoàn toàn touch mode và mouse mode: trên touch device chỉ xử lý `InputEventScreenTouch`/`InputEventScreenDrag`, bỏ qua mouse events
- **[CRITICAL] Fix AI dart xuyên player không gây damage**: `dart.gd` set `collision_mask = 4 | 8 | 16` (Wall+AI+Obstacle) thiếu Player layer (1) → `_on_body_entered` không fire khi dart chạm player → AI bắn trúng player mà không gây sát thương. Giờ sửa thành `1 | 4 | 8 | 16 = 29`
- **[CRITICAL] Fix teleport button không phản ứng**: Do bug #1 (mobile_controls là null), signal `teleport_pressed` không bao giờ được connect → nút teleport không có effect. Ngoài ra, `mobile_controls.gd` chỉ track `aim_touch_index` cho nút throw, không track riêng cho teleport → giờ thêm `teleport_touch_index` riêng để hỗ trợ multi-touch (giữ joystick + nhấn teleport cùng lúc)
- **[HIGH] Fix hit area overlap giữa throw và teleport button**: Throw button hit area (`grow(30)`) overlap với teleport button hit area (`grow(20)`) → touch vào teleport có thể bị throw capture. Giờ redesign layout: throw 180×180 ở góc dưới-phải, teleport 140×140 bên trái throw với gap 60px, không overlap
- **[HIGH] Fix duplicate teleport fire**: `teleport_btn.mouse_filter=STOP` + handling trong `_input` → teleport fire 2 lần (1 từ _input, 1 từ GUI `pressed` signal do `emulate_mouse_from_touch`). Giờ set `teleport_btn.mouse_filter=IGNORE`, chỉ handle qua `_input`
- **[HIGH] Fix duplicate screen shake khi teleport**: `_on_teleport_performed` gọi `apply_screen_shake(4.0, 0.2)` trong khi `GameManager.screen_shake_requested` signal cũng đã trigger `apply_screen_shake` → rung màn hình 2 lần. Giờ bỏ duplicate call
- **[MEDIUM] Fix button quá nhỏ**: Throw/Teleport button chỉ 100×100px (quá nhỏ cho ngón cái). Giờ throw 180×180, teleport 140×140
- **[MEDIUM] Fix joystick quá nhỏ**: Joystick 160×160px. Giờ 200×200 với stick (knob) 100×100
- **[LOW] Fix `player.aim_touch_index = 0` ambiguous với touch index 0**: Đổi thành sentinel `AIM_MODE_MOBILE_SENTINEL = -2` để distinguish mobile mode vs actual touch index 0
- **[LOW] Fix `player._die()` không reset dart_bonus và aim state**: Player chết rồi respawn vẫn giữ dart bonus và aim line có thể stuck. Giờ reset cả hai
- **[LOW] Remove empty `_input` function trong `hud.gd`**: Dead code

### Added
- **Visual feedback khi nhấn nút mobile**: Throw button đổi màu cam khi hold, teleport button đổi màu xanh khi press. Dùng `Tween` cho smooth transition
- **Touch device cache**: `_is_touch_device()` giờ cache kết quả để tránh check lặp lại mỗi input event
- **HUD controls hint cập nhật cho v0.9**: Mô tả multi-touch capability mới
- **Menu version label cập nhật v0.9**

### Changed
- `scripts/main.gd`: `@onready var joystick = $UILayer/VirtualJoystick`, `@onready var mobile_controls = $UILayer/MobileControls`; bỏ duplicate `apply_screen_shake` trong `_on_teleport_performed`
- `scripts/virtual_joystick.gd`: Rewrite hoàn toàn - tách touch/mouse tracking, cache `_is_touch_device()`, thêm `is_mouse_pressed` field riêng
- `scripts/mobile_controls.gd`: Rewrite hoàn toàn - tách touch/mouse tracking, thêm `teleport_touch_index` cho multi-touch, thêm `_handle_touch_event`/`_handle_drag_event`/`_handle_mouse_event` helpers, thêm visual feedback
- `scripts/dart.gd`: `collision_mask = 1 | 4 | 8 | 16` (thêm Player layer)
- `scripts/player.gd`: Thêm `AIM_MODE_MOBILE_SENTINEL` const, reset aim state + dart_bonus trong `_die()`
- `scripts/hud.gd`: Cập nhật controls hint text cho v0.9, remove empty `_input`
- `scripts/menu.gd`: `version_label = "v0.9 - Multi-touch Fix"`, `new_feature_label` cập nhật
- `scenes/virtual_joystick.tscn`: Joystick 200×200 (từ 160×160), stick 100×100 (từ 80×80), margin 30px (từ 20px)
- `scenes/mobile_controls.tscn`: Throw button 180×180 (từ 100×100), teleport 140×140 (từ 100×100), gap 60px giữa 2 nút (từ 10px)
- `scenes/menu.tscn`: NewFeatureLabel + VersionLabel text v0.9
- `project.godot`: `config/version="0.9"`
- `export_presets.cfg`: `version/code=9`, `version/name="0.9"`, `file_version="0.9.0.0"`, `product_version="0.9.0.0"`
- `README.md`: Cập nhật badge v0.9, thêm section "Lỗi đã fix trong v0.9", cập nhật layout description

## [0.8] - 2026-08-03

### Fixed
- **[CRITICAL] Fix nút mobile không hiện/không hoạt động**: `MobileControls` và `VirtualJoystick` là con của `Main` (Node2D có Camera2D) → `button.global_position` ở tọa độ WORLD, nhưng touch event ở tọa độ SCREEN → `_is_point_in_throw_button()` luôn fail khi camera di chuyển. Giờ wrap cả 2 trong `CanvasLayer` (UILayer) trong `main.tscn` để global_position luôn ở screen coords
- **[CRITICAL] Fix visibility check chỉ chạy 1 lần**: `_update_visibility()` chỉ được gọi trong `_ready()`. Nếu device detection chậm hoặc settings thay đổi, controls không update. Giờ gọi mỗi frame trong `_process()`
- **[CRITICAL] Fix hit test dùng manual rect thay vì `get_global_rect()`**: `mobile_controls.gd` và `virtual_joystick.gd` dùng `Rect2(btn.global_position, btn.size)` manual, không accounting cho anchors/scale. Giờ dùng `Control.get_global_rect()` + `grow(padding)` cho hit area chính xác
- Fix `_is_touch_device()` không detect một số thiết bị Android cũ: thêm fallback check `OS.get_name() == "Android" or "iOS"` ngoài `OS.has_feature()`
- Fix `throw_btn.mouse_filter` mặc định (STOP) consume touch event trước khi `_input()` xử lý aim. Giờ set `MOUSE_FILTER_IGNORE` cho throw_btn để touch xuyên qua
- Fix `mobile_controls._input()` không gọi `set_input_as_handled()` → touch có thể leak sang joystick. Giờ mark handled khi nhấn nút
- Fix indentation không nhất quán (tab vs space) trong 4 file .gd. Giờ tất cả dùng space (4 spaces per indent level)

### Added
- **150+ sound effects**: Generate procedurally bằng Python (wave + struct + math) với 47 categories:
  - Throw (5), Teleport (5), Hit (5), Kill (5), Death (3), Pickup health (3), Pickup dart (3)
  - UI click (5), UI hover (3), UI toggle (2), Combo (5), Zone warning (3), Zone shrink (2)
  - Dart stick (3), Dart fly (2), Respawn (2), Footstep (5), Damage (3), Powerup (3), Notification (3)
  - Whoosh (5), Zap (5), Explosion (3), Sparkle (3), Chime (3)
  - Drum kick (2), Snare (2), Hihat (2), Crash (2)
  - Alarm (3), Heartbeat (2), Countdown (3), Success (3), Error (2), Warning (2), Info (2)
  - Spawn (2), Size grow (2), Aim start (2), Aim loop (1)
  - Laser (3), Magic (3), Coin (3), Bass (3)
  - Click light (5), Click heavy (3), Select (3), Confirm (2), Cancel (2), Achievement (2)
  - **5 nhạc nền**: menu (1), game (2), victory (1), defeat (1) - mỗi track 3-8s loop
- **AudioManager autoload singleton** (`scripts/audio_manager.gd`):
  - Pool 16 AudioStreamPlayer để phát nhiều sound cùng lúc
  - Lazy loading: chỉ load sound khi cần (preload common sounds)
  - Crossfade giữa music tracks
  - Helper methods: `play_throw()`, `play_teleport()`, `play_hit()`, `play_kill()`, `play_death()`, `play_pickup_health()`, `play_pickup_dart()`, `play_ui_click()`, `play_ui_hover()`, `play_combo(count)`, `play_zone_warning()`, `play_zone_shrink()`, `play_dart_stick()`, `play_respawn()`, `play_damage()`, `play_success()`, `play_error()`, `play_warning()`, `play_achievement()`, `play_size_grow()`, `play_aim_start()`, `play_spawn()`, `play_music(track)`, `stop_music()`
  - `play_variation(category)` chọn random sound từ category
- **Sound settings**: 2 CheckButton mới trong Settings: "Bật âm thanh" + "Bật nhạc nền" + 2 slider volume
- `SettingsManager.set_sound_volume()`, `set_music_volume()`, `set_sound_enabled()`, `set_music_enabled()`
- `SettingsManager.sound_enabled`, `music_enabled` fields
- `SettingsManager.sound_volume_changed`, `music_volume_changed` signals
- Wire sounds vào tất cả gameplay events: throw, teleport, hit, kill, death, respawn, pickup, damage, dart stick, combo, zone warning, zone shrink, UI click/hover, menu music, game music
- `assets/audio/sfx/` (150 files) + `assets/audio/music/` (5 files) directories
- `scripts/generate_sounds.py` - Python script generate all sounds

### Changed
- `project.godot`: thêm `AudioManager` autoload, `config/version="0.8"`, thêm `[audio]` section
- `scripts/main.gd`: thêm UILayer CanvasLayer chứa VirtualJoystick + MobileControls (FIX root cause mobile không hiện)
- `scripts/main.gd`: connect `zone_shrank` + `combo_achieved` signals để play sound
- `scripts/main.gd`: gọi `AudioManager.play_music("game")` khi vào game
- `scripts/mobile_controls.gd`: complete rewrite với `get_global_rect()`, `_process()` update visibility, `mouse_filter` fixes, `_is_touch_device()` robust
- `scripts/virtual_joystick.gd`: dùng `get_global_rect().grow(80)` cho hit area, `_is_touch_device()` robust
- `scripts/player.gd`: thêm `AudioManager.play_throw/teleport/kill/death/respawn/damage/pickup_health/pickup_dart/aim_start/size_grow` calls
- `scripts/ai_player.gd`: thêm sound cho AI throw/teleport/kill/death/hit/spawn
- `scripts/dart.gd`: thêm `AudioManager.play_dart_stick()` khi phi tiêu cắm
- `scripts/hud.gd`: zone warning sound mỗi 1.5s khi ngoài vòng bo
- `scripts/menu.gd`: play menu music, UI click/hover sounds, version v0.8
- `scripts/settings_menu.gd`: sound/music toggle + slider, UI sounds
- `scripts/loading_screen.gd`: play menu music if not playing
- `scenes/main.tscn`: thêm UILayer CanvasLayer
- `scenes/mobile_controls.tscn`: button size 100x100, anchors bottom-right
- `scenes/settings.tscn`: thêm SoundToggle, MusicToggle, rearrange layout
- `scenes/menu.tscn`: update NewFeatureLabel + VersionLabel cho v0.8
- `export_presets.cfg`: version/code 7 → 8, version/name "0.7" → "0.8", file_version "0.7.0.0" → "0.8.0.0"
- `.github/workflows/build-release.yml`: tăng import timeout 180s → 300s do có thêm 155 audio files
- `README.md`: cập nhật badge v0.8, thêm section âm thanh, cập nhật "Lỗi đã fix trong v0.8"

### Removed
- Dead code trong `mobile_controls.gd` (old `_is_point_in_throw_button` manual rect)
- Dead code trong `virtual_joystick.gd` (old `_is_in_joystick_area` manual rect)

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
