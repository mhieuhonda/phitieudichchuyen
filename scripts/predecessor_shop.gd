extends Control

## PredecessorShop - Shop tiền bối (v3.7)
## Tiền bối là NPC đặc biệt dành riêng cho player (mutant).
## Bán: 6 class khởi đầu (loài chính) + mặt nạ đổi class + vật phẩm đặc biệt

@onready var class_grid: GridContainer = $Center/VBox/ScrollContainer/ClassGrid
@onready var mask_button: Button = $Center/VBox/MaskHBox/BuyMaskButton
@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var current_class_label: Label = $TopBar/CurrentClassLabel
@onready var masks_owned_label: Label = $Center/VBox/MaskHBox/MasksOwnedLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var info_label: Label = $Center/VBox/InfoLabel

const CLASS_COST: int = 200        # giá mua 1 class
const MASK_COST: int = 150         # giá mua 1 mặt nạ

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.15, 0.13, 0.25, 0.98)

func _ready():
	if back_button:
		back_button.pressed.connect(_on_back)
	if mask_button:
		mask_button.pressed.connect(_on_buy_mask)
	_refresh_topbar()
	_build_class_items()
	AudioManager.play_music("menu")

func _style_button(btn: Button, accent: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = COL_BG
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	var hover = normal.duplicate()
	hover.bg_color = COL_BG_HOVER
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.9)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)

func _refresh_topbar():
	coins_label.text = "HL Coin: %d" % ProgressionManager.hl_coins
	if ProgressionManager.current_class_id >= 0:
		current_class_label.text = "Class: %s %s" % [
			SpeciesData.get_species(ProgressionManager.current_class_id)["emoji"],
			SpeciesData.get_species_name(ProgressionManager.current_class_id)
		]
	else:
		current_class_label.text = "Class: Chưa có (mutant — mua class đầu tiên miễn phí đổi)"
	masks_owned_label.text = "Mặt nạ đang có: %d" % ProgressionManager.owned_masks

func _build_class_items():
	for child in class_grid.get_children():
		child.queue_free()
	var main_ids = SpeciesData.get_main_species_ids()
	for sid in main_ids:
		var sp = SpeciesData.get_species(sid)
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(290, 200)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.10, 0.18, 0.95)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		var owned = ProgressionManager.has_class(sid)
		var is_current = ProgressionManager.current_class_id == sid
		if is_current:
			style.border_color = Color(0.95, 0.85, 0.3, 0.9)
		elif owned:
			style.border_color = Color(0.4, 0.9, 0.5, 0.6)
		else:
			style.border_color = Color(0.45, 0.4, 0.65, 0.5)
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		style.content_margin_left = 12
		style.content_margin_right = 12
		panel.add_theme_stylebox_override("panel", style)
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		var name_lbl = Label.new()
		name_lbl.text = "%s %s" % [sp["emoji"], sp["name"]]
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.modulate = sp["color"]
		vbox.add_child(name_lbl)
		var stats_lbl = Label.new()
		stats_lbl.text = "Magic %d | Physical %d | Agility %d" % [sp["magic"], sp["physical"], sp["agility"]]
		stats_lbl.modulate = Color(0.7, 0.8, 0.9)
		vbox.add_child(stats_lbl)
		var desc_lbl = Label.new()
		desc_lbl.text = sp["desc"]
		desc_lbl.modulate = Color(0.6, 0.7, 0.85)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.custom_minimum_size = Vector2(260, 60)
		vbox.add_child(desc_lbl)
		var skill_lbl = Label.new()
		skill_lbl.text = "Skill: %s" % sp["leader_skill"]
		skill_lbl.modulate = Color(0.6, 0.85, 1.0)
		skill_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		skill_lbl.custom_minimum_size = Vector2(260, 40)
		vbox.add_child(skill_lbl)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(260, 50)
		if is_current:
			btn.text = "✓ Đang dùng"
			btn.disabled = true
			_style_button(btn, Color(0.95, 0.85, 0.3))
		elif owned:
			btn.text = "🔄 Đổi sang (1 mask)"
			_style_button(btn, Color(0.4, 0.9, 1.0))
			btn.disabled = ProgressionManager.owned_masks <= 0
			btn.pressed.connect(_on_change_class.bind(sid))
		else:
			btn.text = "💰 Mua (%d HL)" % CLASS_COST
			_style_button(btn, Color(0.4, 0.9, 0.5) if ProgressionManager.hl_coins >= CLASS_COST else Color(0.4, 0.4, 0.4))
			btn.disabled = ProgressionManager.hl_coins < CLASS_COST
			btn.pressed.connect(_on_buy_class.bind(sid))
		vbox.add_child(btn)
		panel.add_child(vbox)
		class_grid.add_child(panel)
	# Minor species hint
	var hint = Label.new()
	hint.text = "💡 4 loài phụ (Hươu, Sư Tử, Sói, Chó) không mua được ở đây — tìm thủ lĩnh tương ứng trong thế giới để học skill (cần class phù hợp)."
	hint.modulate = Color(0.7, 0.8, 0.9)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.custom_minimum_size = Vector2(900, 60)
	class_grid.add_child(hint)

func _on_buy_class(sid: int):
	AudioManager.play_ui_click()
	var ok = ProgressionManager.buy_class(sid, CLASS_COST)
	if ok:
		info_label.text = "✓ Đã mua class: %s. Đây là class đầu tiên nên tự động áp dụng." % SpeciesData.get_species_name(sid)
		info_label.modulate = Color(0.5, 1.0, 0.5)
		AudioManager.play_variation("chime", 2.0, 1.1)
	else:
		info_label.text = "✗ Không đủ HL Coin hoặc đã sở hữu class này."
		info_label.modulate = Color(1.0, 0.5, 0.3)
		AudioManager.play_variation("error", 0.0, 1.0)
	_refresh_topbar()
	_build_class_items()

func _on_change_class(sid: int):
	AudioManager.play_ui_click()
	var ok = ProgressionManager.change_class(sid)
	if ok:
		info_label.text = "✓ Đã đổi class sang: %s. (Sử dụng 1 mặt nạ. Chỉ số player KHÔNG đổi.)" % SpeciesData.get_species_name(sid)
		info_label.modulate = Color(0.5, 1.0, 0.5)
		AudioManager.play_variation("chime", 1.0, 1.0)
	else:
		info_label.text = "✗ Cần ít nhất 1 mặt nạ để đổi class."
		info_label.modulate = Color(1.0, 0.5, 0.3)
		AudioManager.play_variation("error", 0.0, 1.0)
	_refresh_topbar()
	_build_class_items()

func _on_buy_mask():
	AudioManager.play_ui_click()
	var ok = ProgressionManager.buy_mask(MASK_COST)
	if ok:
		info_label.text = "✓ Đã mua 1 mặt nạ đổi class. Hiện có: %d" % ProgressionManager.owned_masks
		info_label.modulate = Color(0.5, 1.0, 0.5)
		AudioManager.play_variation("chime", 1.0, 1.0)
	else:
		info_label.text = "✗ Không đủ HL Coin (cần %d)" % MASK_COST
		info_label.modulate = Color(1.0, 0.5, 0.3)
		AudioManager.play_variation("error", 0.0, 1.0)
	_refresh_topbar()

func _on_back():
	AudioManager.play_cancel()
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back()
