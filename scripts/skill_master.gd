extends Control

## SkillMaster - Học skill từ 10 thủ lĩnh (v3.7)
## Mỗi thủ lĩnh chỉ dạy cho player duy nhất, và chỉ khi player cùng class.
## Thủ lĩnh có thể ẩn (Sói, Chó, Sư Tử) — chỉ gặp khi may mắn.

@onready var leader_list: VBoxContainer = $Center/VBox/ScrollContainer/LeaderList
@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var class_label: Label = $TopBar/ClassLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var info_label: Label = $Center/VBox/InfoLabel

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.15, 0.13, 0.25, 0.98)

func _ready():
	if back_button:
		back_button.pressed.connect(_on_back)
	_refresh_topbar()
	_build_leader_list()
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
		class_label.text = "Class: %s %s" % [
			SpeciesData.get_species(ProgressionManager.current_class_id)["emoji"],
			SpeciesData.get_species_name(ProgressionManager.current_class_id)
		]
	else:
		class_label.text = "Class: Chưa có (mutant)"

func _build_leader_list():
	for child in leader_list.get_children():
		child.queue_free()
	var leaders = WorldManager.get_leaders_in_region()
	if leaders.is_empty():
		var lbl = Label.new()
		lbl.text = "Không gặp thủ lĩnh nào ở vùng %s lúc này. Thử vùng khác." % WorldManager.get_region(WorldManager.current_region)["name"]
		lbl.modulate = Color(0.6, 0.7, 0.85)
		leader_list.add_child(lbl)
		return
	for leader in leaders:
		var item = _build_leader_item(leader)
		leader_list.add_child(item)
	# Also show skills already learned
	var learned_skills: Array = []
	for k in ProgressionManager.achievements.keys():
		if k.begins_with("learned_skill_"):
			var leader_key = k.substr("learned_skill_".length())
			learned_skills.append(leader_key)
	if not learned_skills.is_empty():
		var sep = HSeparator.new()
		leader_list.add_child(sep)
		var title = Label.new()
		title.text = "— Skill đã học —"
		title.modulate = Color(1.0, 0.85, 0.3)
		title.add_theme_font_size_override("font_size", 18)
		leader_list.add_child(title)
		for lk in learned_skills:
			if WorldManager.LEADER_LOCATIONS.has(lk):
				var loc = WorldManager.LEADER_LOCATIONS[lk]
				var sp = SpeciesData.get_species(loc["species"])
				var lbl = Label.new()
				lbl.text = "✓ %s (%s): %s" % [sp["leader_name"], sp["name"], sp["leader_skill"]]
				lbl.modulate = Color(0.5, 1.0, 0.5)
				leader_list.add_child(lbl)

func _build_leader_item(leader: Dictionary) -> PanelContainer:
	var key = leader["key"]
	var data = leader["data"]
	var hidden = leader.get("hidden", false)
	var sp = SpeciesData.get_species(data["species"])
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.18, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	if hidden:
		style.border_color = Color(0.6, 0.3, 0.6, 0.7)
	else:
		style.border_color = Color(0.4, 0.9, 1.0, 0.5)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", style)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = 3
	vbox.add_theme_constant_override("separation", 4)
	var name_lbl = Label.new()
	name_lbl.text = "%s %s — %s" % [sp["emoji"], sp["leader_name"], sp["name"]]
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.modulate = sp["color"] if not hidden else Color(0.85, 0.55, 1.0)
	vbox.add_child(name_lbl)
	var pos_lbl = Label.new()
	pos_lbl.text = "📍 Vị trí: %s (vùng %s)" % [data["name"], WorldManager.get_region(data["region"])["name"]]
	pos_lbl.modulate = Color(0.7, 0.8, 0.9)
	vbox.add_child(pos_lbl)
	var skill_lbl = Label.new()
	skill_lbl.text = "🎯 Skill: %s" % sp["leader_skill"]
	skill_lbl.modulate = Color(0.6, 0.85, 1.0)
	skill_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	skill_lbl.custom_minimum_size = Vector2(820, 30)
	vbox.add_child(skill_lbl)
	if hidden:
		var hint_lbl = Label.new()
		hint_lbl.text = "⚠️ Thủ lĩnh ẩn — chỉ gặp ngẫu nhiên (Sói/Chó/Sư Tử là quân bí mật hoặc trốn chui)"
		hint_lbl.modulate = Color(1.0, 0.5, 0.3)
		vbox.add_child(hint_lbl)
	var already_learned = ProgressionManager.achievements.has("learned_skill_%s" % key)
	var same_class = ProgressionManager.current_class_id == data["species"]
	var cost = 100
	var can_afford = ProgressionManager.hl_coins >= cost
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(150, 50)
	if already_learned:
		btn.text = "✓ Đã học"
		btn.disabled = true
		_style_button(btn, Color(0.5, 1.0, 0.5))
	elif not same_class:
		btn.text = "Cần class %s" % sp["name"]
		btn.disabled = true
		_style_button(btn, Color(0.4, 0.4, 0.4))
	elif not can_afford:
		btn.text = "Cần %d HL" % cost
		btn.disabled = true
		_style_button(btn, Color(0.4, 0.4, 0.4))
	else:
		btn.text = "Học (%d HL)" % cost
		_style_button(btn, Color(0.4, 0.9, 1.0))
		btn.pressed.connect(_on_learn.bind(key))
	vbox.add_child(btn)
	hbox.add_child(vbox)
	panel.add_child(hbox)
	return panel

func _on_learn(leader_key: String):
	AudioManager.play_ui_click()
	var result = WorldManager.learn_skill_from_leader(leader_key)
	if result.get("success", false):
		info_label.text = "✓ Đã học skill: %s" % result["skill"]
		info_label.modulate = Color(0.5, 1.0, 0.5)
		AudioManager.play_variation("chime", 2.0, 1.1)
	else:
		info_label.text = "✗ %s" % result.get("reason", "Không thể học")
		info_label.modulate = Color(1.0, 0.5, 0.3)
		AudioManager.play_variation("error", 0.0, 1.0)
	_refresh_topbar()
	_build_leader_list()

func _on_back():
	AudioManager.play_cancel()
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back()
