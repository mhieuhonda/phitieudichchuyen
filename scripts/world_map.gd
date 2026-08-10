extends Control

## WorldMap - Bản đồ thế giới 4 vùng (v3.7)
## Player chọn vùng để đi → vào vùng đó (quán rượu, thủ lĩnh, tiền bối)

@onready var region_grid: GridContainer = $CenterContainer/VBox/ScrollContainer/RegionGrid
@onready var info_label: RichTextLabel = $CenterContainer/VBox/InfoLabel
@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var class_label: Label = $TopBar/ClassLabel
@onready var day_label: Label = $TopBar/DayLabel
@onready var back_button: Button = $TopBar/BackButton

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.15, 0.13, 0.25, 0.98)
const COL_BORDER := Color(0.45, 0.40, 0.65, 0.55)

func _ready():
	if back_button:
		back_button.pressed.connect(_on_back)
		_style_button(back_button, Color(1.0, 0.4, 0.3))
	_refresh_topbar()
	_build_region_buttons()
	AudioManager.play_music("menu")

func _style_button(btn: Button, accent: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = COL_BG
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_color = Color(accent.r, accent.g, accent.b, 0.5)
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	var hover = normal.duplicate()
	hover.bg_color = COL_BG_HOVER
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.9)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)

func _refresh_topbar():
	if coins_label:
		coins_label.text = "HL Coin: %d" % ProgressionManager.hl_coins
	if class_label:
		if ProgressionManager.current_class_id >= 0:
			class_label.text = "Class: %s" % SpeciesData.get_species_name(ProgressionManager.current_class_id)
		else:
			class_label.text = "Class: Chưa có (mutant)"
	if day_label:
		var cw_msg = ""
		if ProgressionManager.civil_war_active:
			var sp_name = "Tất cả"
			if ProgressionManager.civil_war_species >= 0:
				sp_name = SpeciesData.get_species_name(ProgressionManager.civil_war_species)
			cw_msg = " | ⚔️ Nội chiến loài %s (%ds)" % [sp_name, int(ProgressionManager.civil_war_timer)]
		day_label.text = "Ngày %d | Vùng: %s%s" % [WorldManager.day, WorldManager.get_region(WorldManager.current_region)["name"], cw_msg]

func _build_region_buttons():
	for child in region_grid.get_children():
		child.queue_free()
	for region in WorldManager.get_all_regions():
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(280, 120)
		btn.text = "%s %s\n%s" % [region["emoji"], region["name"], region["desc"]]
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_style_button(btn, region["color"])
		# Mark current region
		if region["id"] == WorldManager.current_region:
			btn.text = "▶ " + btn.text
		btn.pressed.connect(_on_region_pressed.bind(region["id"]))
		region_grid.add_child(btn)

func _on_region_pressed(region_id: String):
	AudioManager.play_ui_click()
	WorldManager.travel_to(region_id)
	_refresh_topbar()
	_build_region_buttons()
	# Show info panel
	var region = WorldManager.get_region(region_id)
	var leaders_text = ""
	for leader_key in region.get("leaders", []):
		if WorldManager.LEADER_LOCATIONS.has(leader_key):
			var loc = WorldManager.LEADER_LOCATIONS[leader_key]
			var sp = SpeciesData.get_species(loc["species"])
			leaders_text += "\n• %s (%s) — %s" % [sp["leader_name"], sp["name"], loc["name"]]
	var predecessor_text = ""
	if WorldManager.is_predecessor_here():
		predecessor_text = "\n\n[color=#ffaa00][b]💰 Tiền Bối đang ở đây![/b][/color] — Mở shop class/mặt nạ"
	info_label.text = "[b]Vùng: %s %s[/b]\n%s%s\n\n[b]Thủ lĩnh có thể gặp:[/b]%s\n\nVào [b]Quán Rượu[/b] để nhận quest + chiêu mộ. Vào [b]Tiền Bối[/b] để mua class/mặt nạ. Vào [b]Thủ Lĩnh[/b] để học skill." % [region["emoji"], region["name"], region["desc"], predecessor_text, leaders_text]
	# Show action buttons
	_show_action_buttons(region_id)

@onready var action_container: HBoxContainer = $CenterContainer/VBox/ActionButtons

func _show_action_buttons(region_id: String):
	for child in action_container.get_children():
		child.queue_free()
	# Quán rượu
	var tavern_btn = Button.new()
	tavern_btn.text = "🍺 Quán Rượu\n(Quest + Chiêu mộ)"
	tavern_btn.custom_minimum_size = Vector2(220, 80)
	_style_button(tavern_btn, Color(0.95, 0.75, 0.30))
	tavern_btn.pressed.connect(_on_tavern_pressed)
	action_container.add_child(tavern_btn)
	# Tiền bối (chỉ nếu ở đây)
	if WorldManager.is_predecessor_here():
		var pred_btn = Button.new()
		pred_btn.text = "💰 Tiền Bối\n(Mua class/mặt nạ)"
		pred_btn.custom_minimum_size = Vector2(220, 80)
		_style_button(pred_btn, Color(0.85, 0.55, 1.0))
		pred_btn.pressed.connect(_on_predecessor_pressed)
		action_container.add_child(pred_btn)
	# Thủ lĩnh
	var leader_btn = Button.new()
	leader_btn.text = "👑 Gặp Thủ Lĩnh\n(Học skill)"
	leader_btn.custom_minimum_size = Vector2(220, 80)
	_style_button(leader_btn, Color(0.4, 0.9, 1.0))
	leader_btn.pressed.connect(_on_leader_pressed)
	action_container.add_child(leader_btn)
	# Quest Log / Achievements
	var log_btn = Button.new()
	log_btn.text = "📜 Sổ Tay\n(Quest/Team/Thành tựu)"
	log_btn.custom_minimum_size = Vector2(220, 80)
	_style_button(log_btn, Color(0.5, 1.0, 0.5))
	log_btn.pressed.connect(_on_log_pressed)
	action_container.add_child(log_btn)

func _on_tavern_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/tavern.tscn")

func _on_predecessor_pressed():
	AudioManager.play_ui_click()
	WorldManager.visit_predecessor()
	get_tree().change_scene_to_file("res://scenes/predecessor_shop.tscn")

func _on_leader_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/skill_master.tscn")

func _on_log_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/quest_log.tscn")

func _on_back():
	AudioManager.play_cancel()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back()
