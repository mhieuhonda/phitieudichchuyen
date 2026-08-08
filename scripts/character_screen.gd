extends Control

## CharacterScreen - Màn hình xem nhân vật (v3.2) - Premium PNG UI
## Xem thông tin, chỉ số, kỹ năng, trang bị nhân vật
## v3.2: BackButton + EquipButton dùng PNG (TextureButton)

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
@onready var equip_btn: TextureButton = $RightPanel/EquipButton
@onready var back_btn: TextureButton = $BackButton
@onready var lock_icon: Label = $RightPanel/LockIcon

# Equip button label overlay (for showing status text on TextureButton)
var equip_status_label: Label = null

var current_preview_id: int = 0

const GOLD := Color(1.0, 0.85, 0.3)
const CYAN := Color(0.4, 0.9, 1.0)
const SCALE_UP := Vector2(1.06, 1.06)
const SCALE_NORMAL := Vector2(1.0, 1.0)

func _ready():
	back_btn.pressed.connect(_on_back_pressed)
	equip_btn.pressed.connect(_on_equip_pressed)
	
	# Create equip status label overlay
	equip_status_label = Label.new()
	equip_status_label.anchors_preset = Control.PRESET_FULL_RECT
	equip_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equip_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equip_status_label.add_theme_font_size_override("font_size", 20)
	equip_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 0.9))
	equip_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equip_btn.add_child(equip_status_label)
	
	# Populate character list
	_populate_char_list()
	
	# Show first character
	_show_character(CharacterData.selected_character_id)
	
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
	
	# Hover effects for TextureButtons
	for btn in [back_btn, equip_btn]:
		if btn:
			btn.mouse_entered.connect(_on_tex_hover.bind(btn))
			btn.mouse_exited.connect(_on_tex_unhover.bind(btn))

func _on_tex_hover(btn: TextureButton):
	if not btn or not is_instance_valid(btn):
		return
	AudioManager.play_ui_hover()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "scale", SCALE_UP, 0.1)

func _on_tex_unhover(btn: TextureButton):
	if not btn or not is_instance_valid(btn):
		return
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "scale", SCALE_NORMAL, 0.12)

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
		var tex = load(CharacterData.get_sprite_path(id))
		if tex:
			char_preview.texture = tex
		char_preview.modulate = Color(0.2, 0.2, 0.2, 0.8)
		lock_icon.visible = true
		lock_icon.text = "CHƯA MỞ KHÓA"

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

	# Equip button status
	if equip_status_label:
		if is_unlocked:
			if id == CharacterData.selected_character_id:
				equip_status_label.text = "ĐANG TRANG BỊ"
				equip_status_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 0.9))
				equip_btn.disabled = true
				equip_btn.modulate = Color(0.6, 0.6, 0.6, 0.8)
			else:
				equip_status_label.text = ""
				equip_btn.disabled = false
				equip_btn.modulate = Color(1, 1, 1, 1)
		else:
			equip_status_label.text = "CHƯA MỞ KHÓA"
			equip_status_label.add_theme_color_override("font_color", Color(0.85, 0.45, 0.45, 0.9))
			equip_btn.disabled = true
			equip_btn.modulate = Color(0.4, 0.4, 0.4, 0.6)

func _on_equip_pressed():
	AudioManager.play_confirm()
	CharacterData.select_character(current_preview_id)
	_show_character(current_preview_id)
	_populate_char_list()

func _on_back_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
