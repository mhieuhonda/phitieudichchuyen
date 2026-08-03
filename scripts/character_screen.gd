extends Control

## CharacterScreen - Màn hình xem nhân vật (v1.2)
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

func _ready():
        back_btn.pressed.connect(_on_back_pressed)
        equip_btn.pressed.connect(_on_equip_pressed)
        
        # Populate character list
        _populate_char_list()
        
        # Show first character
        _show_character(CharacterData.selected_character_id)
        
        # Hover sounds
        for btn in [back_btn, equip_btn]:
                btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

func _populate_char_list():
        # Clear existing
        for child in char_list.get_children():
                child.queue_free()
        
        var chars = CharacterData.get_all_characters()
        for i in range(chars.size()):
                var char_data = chars[i]
                var btn = Button.new()
                btn.text = char_data["name"]
                btn.custom_minimum_size = Vector2(160, 36)
                btn.add_theme_font_size_override("font_size", 14)
                
                # Color based on type
                var color = char_data["color"]
                btn.add_theme_color_override("font_color", color)
                
                if not CharacterData.is_unlocked(i):
                        btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
                        btn.text = "??? " + char_data["name"]
                
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
