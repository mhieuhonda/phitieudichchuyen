extends Control

## Leaderboard - Bảng xếp hạng người chơi (v4.1)
## Scene: scenes/leaderboard.tscn
## - Hiển thị top 100 người chơi theo level
## - Highlight người chơi hiện tại nếu có trong bảng
## - Hiển thị số người đang online

@onready var online_label: Label = $CenterContainer/VBox/TopHBox/OnlineLabel
@onready var refresh_button: Button = $CenterContainer/VBox/TopHBox/RefreshButton
@onready var list_container: VBoxContainer = $CenterContainer/VBox/ScrollContainer/ListContainer
@onready var back_button: Button = $CenterContainer/VBox/BackButton
@onready var status_label: Label = $CenterContainer/VBox/StatusLabel

func _ready():
	refresh_button.pressed.connect(_on_refresh)
	back_button.pressed.connect(_on_back)
	AccountManager.leaderboard_loaded.connect(_on_leaderboard_loaded)
	_style_button(refresh_button, Color(0.4, 0.9, 1.0))
	_style_button(back_button, Color(1.0, 0.4, 0.3))
	# Initial fetch
	_on_refresh()
	AudioManager.play_music("menu")

func _on_refresh():
	status_label.text = "Đang tải bảng xếp hạng..."
	status_label.modulate = Color(0.7, 0.85, 1.0)
	refresh_button.disabled = true
	AccountManager.fetch_leaderboard(100)

func _on_leaderboard_loaded(entries: Array, online_count: int):
	refresh_button.disabled = false
	online_label.text = "🟢 %d người đang online" % online_count
	online_label.modulate = Color(0.4, 1.0, 0.5)
	# Clear
	for child in list_container.get_children():
		child.queue_free()
	if entries.is_empty():
		var lbl = Label.new()
		lbl.text = "Chưa có người chơi nào. Hãy là người đầu tiên!"
		lbl.modulate = Color(0.7, 0.8, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_container.add_child(lbl)
		status_label.text = ""
		return
	# Build header
	var header = _make_row("#", "Người chơi", "Lv", "Danh hiệu", "Trận", "Thắng", "Kills", true)
	list_container.add_child(header)
	# Build rows
	var my_username = AccountManager.get_username().to_lower()
	for entry in entries:
		var rank = int(entry.get("rank", 0))
		var uname = String(entry.get("username", "?"))
		var display = String(entry.get("display_name", "?"))
		var level = int(entry.get("level", 1))
		var title = String(entry.get("title", ""))
		var matches = int(entry.get("total_matches", 0))
		var wins = int(entry.get("total_wins", 0))
		var kills = int(entry.get("total_kills", 0))
		var is_me = uname.to_lower() == my_username and not my_username.is_empty()
		var row = _make_row(str(rank), "%s\n@%s" % [display, uname], str(level), title, str(matches), str(wins), str(kills), false, is_me)
		list_container.add_child(row)
	status_label.text = "✓ Top %d người chơi" % entries.size()
	status_label.modulate = Color(0.5, 1.0, 0.5)

func _make_row(rank_s: String, name_s: String, level_s: String, title_s: String, matches_s: String, wins_s: String, kills_s: String, is_header: bool, is_me: bool = false) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	var style = StyleBoxFlat.new()
	if is_header:
		style.bg_color = Color(0.15, 0.12, 0.25, 0.95)
		style.border_color = Color(0.7, 0.65, 1.0, 0.7)
	elif is_me:
		style.bg_color = Color(0.18, 0.20, 0.10, 0.95)
		style.border_color = Color(1.0, 0.85, 0.3, 0.9)
	else:
		style.bg_color = Color(0.08, 0.08, 0.14, 0.85)
		style.border_color = Color(0.35, 0.35, 0.5, 0.4)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	panel.add_theme_stylebox_override("panel", style)
	# HBox with columns
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	# Rank
	var rank_lbl = _make_cell(rank_s, 50, Color(1.0, 0.85, 0.3) if is_header else (Color(0.4, 1.0, 0.5) if rank_s == "1" else Color(0.85, 0.85, 0.95)), is_header, 18)
	hbox.add_child(rank_lbl)
	# Name
	var name_lbl = _make_cell(name_s, 280, Color(1, 1, 1) if is_header else Color(0.9, 0.95, 1.0), is_header, 14)
	name_lbl.size_flags_horizontal = 3
	hbox.add_child(name_lbl)
	# Level
	var lvl_lbl = _make_cell(level_s, 60, Color(1, 0.85, 0.3) if is_header else Color(1.0, 0.85, 0.3), is_header, 16)
	hbox.add_child(lvl_lbl)
	# Title
	var title_lbl = _make_cell(title_s, 140, Color(0.7, 0.65, 1.0), is_header, 13)
	hbox.add_child(title_lbl)
	# Matches
	var m_lbl = _make_cell(matches_s, 70, Color(0.7, 0.8, 0.9), is_header, 13)
	hbox.add_child(m_lbl)
	# Wins
	var w_lbl = _make_cell(wins_s, 70, Color(0.4, 1.0, 0.5), is_header, 13)
	hbox.add_child(w_lbl)
	# Kills
	var k_lbl = _make_cell(kills_s, 70, Color(1.0, 0.5, 0.5), is_header, 13)
	hbox.add_child(k_lbl)
	panel.add_child(hbox)
	return panel

func _make_cell(text: String, min_w: int, color: Color, is_header: bool, font_size: int) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(min_w, 0)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if is_header or min_w != 280 else HORIZONTAL_ALIGNMENT_LEFT
	return lbl

func _on_back():
	AudioManager.play_cancel()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _style_button(btn: Button, accent: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.07, 0.14, 0.95)
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
	hover.bg_color = Color(0.15, 0.13, 0.25, 0.98)
	hover.border_color = Color(accent.r, accent.g, accent.b, 0.9)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("menu_back"):
		get_viewport().set_input_as_handled()
		_on_back()
