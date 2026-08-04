extends Control

## CharacterScreen - Màn hình xem nhân vật (v1.2) - Premium UI
## Xem thông tin, chỉ số, kỹ năng, trang bị nhân vật

@onready var char_list: VBoxContainer = $LeftPanel/CharList
@onready var char_preview: TextureRect = $RightPanel/CharPreview
@onready var char_name_label: Label = $RightPanel/InfoPanel/CharNameLabel
@onready var char_title_label: Label = $RightPanel/InfoPanel/CharTitleLabel
@onready var char_type_label: Label = $RightPanel/InfoPanel/CharTypeLabel
@onready var char_lore_label: RichTextLabel = $RightPanel/InfoPanel/CharLoreLabel
@onready var hp_stat: Label = $RightPanel/InfoPanel/StatsPanel/HpStat
@onready var speed_stat: Label = $RightPanel/InfoPanel/StatsPanel/SpeedStat
@onready var dart_stat: Label = $RightPanel/InfoPanel/StatsPanel/DartStat
@onready var skill_name: Label = $RightPanel/InfoPanel/SkillPanel/SkillName
@onready var skill_desc: Label = $RightPanel/InfoPanel/SkillPanel/SkillDesc
@onready var equip_btn: Button = $RightPanel/EquipButton
@onready var back_btn: Button = $BackButton
@onready var lock_icon: Label = $RightPanel/LockIcon

var current_preview_id: int = 0

const GOLD := Color(1.0, 0.85, 0.3)
const CYAN := Color(0.4, 0.9, 1.0)

func _ready():
        back_btn.pressed.connect(_on_back_pressed)
        equip_btn.pressed.connect(_on_equip_pressed)
        
        # Populate character list
        _populate_char_list()
        
        # Show first character
        _show_character(CharacterData.selected_character_id)
        
        # Premium hover effects
        for btn in [back_btn, equip_btn]:
                btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
                btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
        
        _apply_premium_styling()

func _apply_premium_styling():
        # Style left panel
        var left_panel = $LeftPanel
        if left_panel:
                var style = StyleBoxFlat.new()
                style.bg_color = Color(0.06, 0.06, 0.12, 0.9)
                style.border_color = Color(0.25, 0.2, 0.4, 0.4)
                style.border_width_top = 1
                style.border_width_bottom = 1
                style.border_width_left = 1
                style.border_width_right = 1
                style.corner_radius_top_left = 10
                style.corner_radius_top_right = 10
                style.corner_radius_bottom_left = 10
                style.corner_radius_bottom_right = 10
                left_panel.add_theme_stylebox_override("panel", style)
        
        # Style right panel
        var right_panel = $RightPanel
        if right_panel:
                var style = StyleBoxFlat.new()
                style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
                style.border_color = Color(0.3, 0.25, 0.45, 0.4)
                style.border_width_top = 1
                style.border_width_bottom = 1
                style.border_width_left = 1
                style.border_width_right = 1
                style.corner_radius_top_left = 10
                style.corner_radius_top_right = 10
                style.corner_radius_bottom_left = 10
                style.corner_radius_bottom_right = 10
                right_panel.add_theme_stylebox_override("panel", style)
        
        # Style equip button
        _style_button(equip_btn, Color(0.15, 0.12, 0.04, 0.9), GOLD)
        _style_button(back_btn, Color(0.08, 0.08, 0.1, 0.8), Color(0.65, 0.65, 0.75))

func _style_button(btn: Button, bg_color: Color, accent_color: Color):
        if not btn:
                return
        var style_normal = StyleBoxFlat.new()
        style_normal.bg_color = bg_color
        style_normal.corner_radius_top_left = 8
        style_normal.corner_radius_top_right = 8
        style_normal.corner_radius_bottom_left = 8
        style_normal.corner_radius_bottom_right = 8
        style_normal.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.3)
        style_normal.border_width_top = 1
        style_normal.border_width_bottom = 1
        style_normal.border_width_left = 1
        style_normal.border_width_right = 1
        style_normal.content_margin_top = 6
        style_normal.content_margin_bottom = 6
        style_normal.content_margin_left = 14
        style_normal.content_margin_right = 14
        style_normal.shadow_color = Color(0, 0, 0, 0.35)
        style_normal.shadow_size = 4
        style_normal.shadow_offset = Vector2(0, 2)
        
        var style_hover = style_normal.duplicate()
        style_hover.bg_color = Color(bg_color.r + 0.05, bg_color.g + 0.05, bg_color.b + 0.06, bg_color.a)
        style_hover.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.6)
        
        var style_pressed = style_normal.duplicate()
        style_pressed.bg_color = Color(bg_color.r * 0.8, bg_color.g * 0.8, bg_color.b * 0.8, bg_color.a)
        
        var style_disabled = style_normal.duplicate()
        style_disabled.bg_color = Color(0.04, 0.04, 0.06, 0.6)
        style_disabled.border_color = Color(0.2, 0.2, 0.25, 0.2)
        
        btn.add_theme_stylebox_override("normal", style_normal)
        btn.add_theme_stylebox_override("hover", style_hover)
        btn.add_theme_stylebox_override("pressed", style_pressed)
        btn.add_theme_stylebox_override("disabled", style_disabled)

func _on_btn_hover(btn: Button, entering: bool):
        if not btn or not is_instance_valid(btn):
                return
        AudioManager.play_ui_hover()
        var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
        if entering:
                tween.tween_property(btn, "scale", Vector2(1.04, 1.06), 0.1)
        else:
                tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)

func _populate_char_list():
        # Clear existing
        for child in char_list.get_children():
                child.queue_free()
        
        var chars = CharacterData.get_all_characters()
        for i in range(chars.size()):
                var char_data = chars[i]
                var btn = Button.new()
                btn.text = char_data["name"]
                btn.custom_minimum_size = Vector2(160, 38)
                btn.add_theme_font_size_override("font_size", 14)
                
                # Color based on type
                var color = char_data["color"]
                btn.add_theme_color_override("font_color", color)
                
                if not CharacterData.is_unlocked(i):
                        btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
                        btn.text = "??? " + char_data["name"]
                
                # Style list buttons
                var list_style = StyleBoxFlat.new()
                list_style.bg_color = Color(0.06, 0.06, 0.12, 0.7)
                list_style.corner_radius_top_left = 6
                list_style.corner_radius_top_right = 6
                list_style.corner_radius_bottom_left = 6
                list_style.corner_radius_bottom_right = 6
                list_style.border_color = Color(color.r, color.g, color.b, 0.25)
                list_style.border_width_left = 3
                list_style.content_margin_left = 10
                list_style.content_margin_top = 4
                list_style.content_margin_bottom = 4
                
                var list_hover = list_style.duplicate()
                list_hover.bg_color = Color(0.1, 0.1, 0.18, 0.85)
                list_hover.border_color = Color(color.r, color.g, color.b, 0.5)
                
                btn.add_theme_stylebox_override("normal", list_style)
                btn.add_theme_stylebox_override("hover", list_hover)
                
                btn.pressed.connect(_on_char_btn_pressed.bind(i))
                btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())
                char_list.add_child(btn)

func _on_char_btn_pressed(id: int):
        AudioManager.play_ui_click()
        _show_character(id)

func _show_character(id: int):
        current_preview_id = id
        var char_data = CharacterData.get_character(id)
        var is_unlocked = CharacterData.is_unlocked(id)

        # Preview
        if is_unlocked:
                var tex = load(CharacterData.get_sprite_path(id))
                if tex:
                        char_preview.texture = tex
                char_preview.modulate = Color(1, 1, 1, 1)
                lock_icon.visible = false
        else:
                # Show silhouette
                var tex = load(CharacterData.get_sprite_path(id))
                if tex:
                        char_preview.texture = tex
                char_preview.modulate = Color(0.2, 0.2, 0.2, 0.8)
                lock_icon.visible = true
                # v2.1: Hiển thị gợi ý mã quà tặng cho Classic
                if char_data.has("file") and char_data["file"] == "char_hieu_louis_classic":
                        lock_icon.text = "🔒 MỞ KHÓA BẰNG MÃ BÍ MẬT\n(Nhập trong Settings → Nhập Mã Quà Tặng)"
                elif char_data.has("file") and char_data["file"] == "char_ma_ton":
                        lock_icon.text = "🔒 MỞ KHÓA BẰNG MÃ BÍ MẬT\n(Nhập trong Settings → Nhập Mã Quà Tặng)"
                else:
                        lock_icon.text = "🔒 CHƯA MỞ KHÓA"

        # Info
        char_name_label.text = char_data["name"]
        char_title_label.text = char_data["title"]
        char_type_label.text = "Loại: %s" % CharacterData.get_type_name(char_data["type"])
        char_lore_label.text = char_data["lore"]

        # Stats
        var hp_bonus = char_data["hp_bonus"]
        var speed_bonus = char_data["speed_bonus"]
        var dart_bonus = char_data["dart_bonus"]

        hp_stat.text = "HP: %s%d" % [("+" if hp_bonus >= 0 else ""), hp_bonus]
        hp_stat.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3) if hp_bonus >= 0 else Color(1.0, 0.3, 0.3))

        speed_stat.text = "Tốc độ: %s%.0f" % [("+" if speed_bonus >= 0 else ""), speed_bonus]
        speed_stat.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3) if speed_bonus >= 0 else Color(1.0, 0.3, 0.3))

        # v2.1: Classic mode hiển thị "VÔ HẠN" thay vì số
        if char_data.has("file") and char_data["file"] == "char_hieu_louis_classic":
                dart_stat.text = "Phi tiêu: VÔ HẠN"
                dart_stat.add_theme_color_override("font_color", Color(0, 1, 0.5))
        else:
                dart_stat.text = "Phi tiêu: %s%d" % [("+" if dart_bonus >= 0 else ""), dart_bonus]
                dart_stat.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3) if dart_bonus >= 0 else Color(1.0, 0.3, 0.3))

        # Skill
        skill_name.text = "Kỹ năng: %s" % char_data["skill_bonus"].to_upper()
        skill_desc.text = char_data["skill_desc"]

        # Equip button
        if is_unlocked:
                if id == CharacterData.selected_character_id:
                        equip_btn.text = "✓ ĐANG TRANG BỊ"
                        equip_btn.disabled = true
                else:
                        equip_btn.text = "TRANG BỊ"
                        equip_btn.disabled = false
        else:
                equip_btn.text = "CHƯA MỞ KHÓA"
                equip_btn.disabled = true

func _on_equip_pressed():
        AudioManager.play_confirm()
        CharacterData.select_character(current_preview_id)
        _show_character(current_preview_id)
        # Refresh list to update selection
        _populate_char_list()

func _on_back_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/menu.tscn")
