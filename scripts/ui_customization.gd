extends Control

## UICustomization - Chỉnh sửa giao diện (v3.4) - Code-based UI
## v3.4: Chỉ còn 3 nút kéo thả: Joystick / Throw / Teleport (đã xóa 3 skills).
##       Sliders kích thước joystick/nút/opacity đã chuyển sang Settings (mục Giao Diện).
## v3.3: Bỏ PNG buttons, dùng Button (Godot Control) với StyleBoxFlat
## - Kéo thả nút bấm vào vị trí mong muốn + bấm Lưu để áp dụng

@onready var back_btn: Button = $BackButton
@onready var reset_btn: Button = $LeftPanel/VBox/ResetButton
@onready var save_layout_btn: Button = $LeftPanel/VBox/SaveLayoutButton
@onready var clear_layout_btn: Button = $LeftPanel/VBox/ClearLayoutButton
@onready var layout_status_label: Label = $LeftPanel/VBox/LayoutStatusLabel
@onready var title_label: Label = $TitleLabel

## Preview area (kéo thả nút ở đây)
@onready var preview_area: Panel = $PreviewArea
@onready var preview_label: Label = $PreviewArea/PreviewLabel
@onready var hint_label: Label = $PreviewArea/HintLabel

## Map giữa node trong preview và tên nút để lưu vào SettingsManager
const DRAG_KEY_JOYSTICK := "joystick"
const DRAG_KEY_THROW := "throw"
const DRAG_KEY_TELEPORT := "teleport"

## Vị trí mặc định chuẩn hóa (0..1) cho mỗi nút (v3.4: chỉ 3 nút)
const DEFAULT_POSITIONS := {
        DRAG_KEY_JOYSTICK: Vector2(0.18, 0.78),
        DRAG_KEY_THROW: Vector2(0.92, 0.82),
        DRAG_KEY_TELEPORT: Vector2(0.80, 0.85),
}

## Palette
const COL_GOLD := Color(1.0, 0.85, 0.3)
const COL_GREEN := Color(0.3, 1.0, 0.5)
const COL_CYAN := Color(0.4, 0.9, 1.0)
const COL_RED := Color(1.0, 0.4, 0.3)
const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.13, 0.11, 0.22, 0.98)
const SCALE_UP := Vector2(1.04, 1.04)
const SCALE_NORMAL := Vector2(1.0, 1.0)

## Các nút preview có thể kéo (ColorRect đại diện + label)
var drag_widgets: Dictionary = {}  # name -> { "node": Control, "dragging": bool, "offset": Vector2 }
var _active_drag_name: String = ""
var _drag_offset: Vector2 = Vector2.ZERO

func _ready():
        back_btn.pressed.connect(_on_back_pressed)
        reset_btn.pressed.connect(_on_reset_pressed)
        save_layout_btn.pressed.connect(_on_save_layout_pressed)
        clear_layout_btn.pressed.connect(_on_clear_layout_pressed)

        # Style buttons
        _style_button(back_btn, COL_GOLD)
        _style_button(save_layout_btn, COL_GREEN)
        _style_button(clear_layout_btn, COL_CYAN)
        _style_button(reset_btn, COL_RED)

        # Hover sounds + scale
        for btn in [back_btn, reset_btn, save_layout_btn, clear_layout_btn]:
                if btn:
                        btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
                        btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))

        _build_preview_widgets()
        _apply_loaded_positions_to_preview()
        _update_layout_status_label()

        # Listen for language changes
        if I18N:
                I18N.language_changed.connect(func(_l): _refresh_ui())

func _refresh_ui():
        if title_label:
                title_label.text = I18N.t("settings.ui_customize") + " — KÉO THẢ NÚT"
        if back_btn:
                back_btn.text = I18N.t("settings.back")

func _on_btn_hover(btn: Button, entering: bool):
        if not btn or not is_instance_valid(btn):
                return
        if entering:
                AudioManager.play_ui_hover()
                _animate_scale(btn, SCALE_UP, 0.1)
        else:
                _animate_scale(btn, SCALE_NORMAL, 0.12)

func _animate_scale(control: Control, target_scale: Vector2, duration: float):
        if not is_instance_valid(control):
                return
        var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
        tween.tween_property(control, "scale", target_scale, duration)

func _style_button(btn: Button, accent: Color):
        if not btn:
                return
        var normal = StyleBoxFlat.new()
        normal.bg_color = COL_BG
        normal.corner_radius_top_left = 8
        normal.corner_radius_top_right = 8
        normal.corner_radius_bottom_left = 8
        normal.corner_radius_bottom_right = 8
        normal.border_width_top = 1
        normal.border_width_bottom = 1
        normal.border_width_left = 1
        normal.border_width_right = 1
        normal.border_color = Color(accent.r, accent.g, accent.b, 0.4)
        normal.content_margin_top = 8
        normal.content_margin_bottom = 8
        normal.content_margin_left = 18
        normal.content_margin_right = 18
        normal.shadow_color = Color(0, 0, 0, 0.4)
        normal.shadow_size = 5
        normal.shadow_offset = Vector2(0, 2)

        var hover = normal.duplicate()
        hover.bg_color = COL_BG_HOVER
        hover.border_color = Color(accent.r, accent.g, accent.b, 0.8)

        btn.add_theme_stylebox_override("normal", normal)
        btn.add_theme_stylebox_override("hover", hover)
        btn.add_theme_stylebox_override("pressed", normal)
        btn.add_theme_stylebox_override("focus", normal)

## Khởi tạo 3 nút preview trong vùng PreviewArea (v3.4: chỉ joystick/throw/teleport)
func _build_preview_widgets():
        # v3.4: Teleport = nút tròn XANH, Throw = nút tròn ĐỎ (match in-game)
        var configs := [
                { "key": DRAG_KEY_JOYSTICK,   "label": "JOYSTICK", "color": Color(0.30, 0.55, 0.95, 0.85), "size": Vector2(110, 110) },
                { "key": DRAG_KEY_TELEPORT,   "label": "DỊCH",     "color": Color(0.20, 0.95, 0.40, 0.90), "size": Vector2(90, 90) },
                { "key": DRAG_KEY_THROW,      "label": "NÉM",      "color": Color(1.00, 0.22, 0.22, 0.90), "size": Vector2(90, 90) },
        ]
        for cfg in configs:
                var panel := Panel.new()
                panel.custom_minimum_size = cfg["size"]
                panel.size = cfg["size"]
                panel.modulate = cfg["color"]
                # Bo góc tròn cho nút DỊCH và NÉM (match in-game)
                if cfg["key"] == DRAG_KEY_TELEPORT or cfg["key"] == DRAG_KEY_THROW:
                        var radius = int(min(cfg["size"].x, cfg["size"].y) * 0.5)
                        var style = StyleBoxFlat.new()
                        style.bg_color = Color(cfg["color"].r * 0.5, cfg["color"].g * 0.5, cfg["color"].b * 0.5, 0.92)
                        style.corner_radius_top_left = radius
                        style.corner_radius_top_right = radius
                        style.corner_radius_bottom_left = radius
                        style.corner_radius_bottom_right = radius
                        style.border_width_top = 3
                        style.border_width_bottom = 3
                        style.border_width_left = 3
                        style.border_width_right = 3
                        style.border_color = Color(cfg["color"].r, cfg["color"].g, cfg["color"].b, 1.0)
                        panel.add_theme_stylebox_override("panel", style)
                var lbl := Label.new()
                lbl.text = cfg["label"]
                lbl.anchors_preset = Control.PRESET_FULL_RECT
                lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
                lbl.add_theme_font_size_override("font_size", 13)
                lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
                lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
                lbl.add_theme_constant_override("outline_size", 3)
                panel.add_child(lbl)
                preview_area.add_child(panel)
                drag_widgets[cfg["key"]] = {
                        "node": panel,
                        "dragging": false,
                        "size": cfg["size"],
                }
        call_deferred("_apply_loaded_positions_to_preview")

## Áp dụng vị trí đã lưu (hoặc mặc định) lên preview widgets
func _apply_loaded_positions_to_preview():
        if not preview_area or drag_widgets.is_empty():
                return
        var area_size := preview_area.size
        if area_size.x <= 1 or area_size.y <= 1:
                call_deferred("_apply_loaded_positions_to_preview")
                return
        for key in drag_widgets.keys():
                var w = drag_widgets[key]
                var n: Control = w["node"]
                var default_pos: Vector2 = DEFAULT_POSITIONS[key]
                var normalized := SettingsManager.get_button_position(key, default_pos)
                var px := Vector2(normalized.x * area_size.x, normalized.y * area_size.y)
                n.position = px - (w["size"] as Vector2) * 0.5
                _clamp_widget_position(key)

func _clamp_widget_position(key: String):
        var w = drag_widgets[key]
        var n: Control = w["node"]
        var sz: Vector2 = w["size"]
        var area_size := preview_area.size
        n.position.x = clamp(n.position.x, 0, max(0, area_size.x - sz.x))
        n.position.y = clamp(n.position.y, 0, max(0, area_size.y - sz.y))

func _process(_delta):
        if not is_instance_valid(preview_area):
                return
        _update_layout_status_label()

## === INPUT: hỗ trợ cả mouse và touch ===
func _input(event: InputEvent):
        _handle_drag_input(event)

func _handle_drag_input(event: InputEvent):
        if event is InputEventScreenTouch:
                if event.pressed:
                        _try_start_drag_at(event.position)
                else:
                        _end_drag()
                return
        if event is InputEventScreenDrag:
                _update_drag(event.position)
                return
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
                if event.pressed:
                        _try_start_drag_at(event.position)
                else:
                        _end_drag()
                return
        if event is InputEventMouseMotion and _active_drag_name != "":
                _update_drag(event.position)
                return

func _try_start_drag_at(screen_pos: Vector2):
        if not is_instance_valid(preview_area):
                return
        var local := preview_area.get_global_rect()
        if not local.has_point(screen_pos) and _active_drag_name == "":
                return
        for key in drag_widgets.keys():
                var w = drag_widgets[key]
                var n: Control = w["node"]
                var rect := Rect2(n.global_position, n.size)
                if rect.has_point(screen_pos):
                        _active_drag_name = key
                        _drag_offset = screen_pos - n.global_position
                        w["dragging"] = true
                        preview_area.move_child(n, -1)
                        AudioManager.play_ui_click()
                        return

func _update_drag(screen_pos: Vector2):
        if _active_drag_name == "":
                return
        if not drag_widgets.has(_active_drag_name):
                _active_drag_name = ""
                return
        var w = drag_widgets[_active_drag_name]
        var n: Control = w["node"]
        var new_pos := screen_pos - _drag_offset
        var local_pos := new_pos - preview_area.global_position
        n.position = local_pos
        _clamp_widget_position(_active_drag_name)

func _end_drag():
        if _active_drag_name == "":
                return
        if drag_widgets.has(_active_drag_name):
                drag_widgets[_active_drag_name]["dragging"] = false
        _active_drag_name = ""

## Đọc vị trí hiện tại của các widget trong preview → lưu tạm (chưa ghi file)
func _snapshot_positions_to_settings():
        if not is_instance_valid(preview_area) or drag_widgets.is_empty():
                return
        var area_size := preview_area.size
        for key in drag_widgets.keys():
                var w = drag_widgets[key]
                var n: Control = w["node"]
                var sz: Vector2 = w["size"]
                var center := n.position + sz * 0.5
                var normalized := Vector2(center.x / max(1.0, area_size.x), center.y / max(1.0, area_size.y))
                SettingsManager.set_button_position(key, normalized)

## === CALLBACKS ===
func _on_save_layout_pressed():
        AudioManager.play_confirm()
        _snapshot_positions_to_settings()
        SettingsManager.enable_custom_layout()
        _update_layout_status_label()
        hint_label.text = "✓ Đã LƯU vị trí! Vào trận để kiểm tra."
        hint_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
        get_tree().create_timer(3.0).timeout.connect(func():
                if is_instance_valid(hint_label):
                        hint_label.text = "Kéo thả các nút vào vị trí mong muốn → bấm LƯU để áp dụng."
                        hint_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 1.0))
        )

func _on_clear_layout_pressed():
        AudioManager.play_cancel()
        SettingsManager.clear_custom_layout()
        for key in drag_widgets.keys():
                var w = drag_widgets[key]
                var n: Control = w["node"]
                var default_pos: Vector2 = DEFAULT_POSITIONS[key]
                var area_size := preview_area.size
                n.position = Vector2(default_pos.x * area_size.x, default_pos.y * area_size.y) - (w["size"] as Vector2) * 0.5
                _clamp_widget_position(key)
        _update_layout_status_label()
        hint_label.text = "Đã đặt lại vị trí mặc định."
        hint_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 1.0))

func _on_reset_pressed():
        AudioManager.play_ui_click()
        SettingsManager.clear_custom_layout()
        SettingsManager.joystick_size = 1.0
        SettingsManager.button_size = 1.0
        SettingsManager.ui_opacity = 1.0
        for key in drag_widgets.keys():
                var w = drag_widgets[key]
                var n: Control = w["node"]
                var default_pos: Vector2 = DEFAULT_POSITIONS[key]
                var area_size := preview_area.size
                n.position = Vector2(default_pos.x * area_size.x, default_pos.y * area_size.y) - (w["size"] as Vector2) * 0.5
                _clamp_widget_position(key)
        SettingsManager.save_settings()
        _update_layout_status_label()

func _update_layout_status_label():
        if not layout_status_label:
                return
        if SettingsManager.use_custom_layout:
                layout_status_label.text = "Layout tùy chỉnh: ĐANG BẬT ✓"
                layout_status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
        else:
                layout_status_label.text = "Layout tùy chỉnh: TẮT (dùng mặc định)"
                layout_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))

func _on_back_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/settings.tscn")

## v2.9: ESC key also goes back to settings
func _unhandled_input(event: InputEvent):
        if event.is_action_pressed("menu_back"):
                if _active_drag_name != "":
                        return
                get_viewport().set_input_as_handled()
                _on_back_pressed()
