extends CanvasLayer

## HUD - Giao diện người chơi (v1.2) - Premium UI
## - Giao diện gọn gàng, không rối mắt
## - Thanh máu, điểm, phi tiêu, kỹ năng
## - Leaderboard khi kết thúc trận
## - FIX: UI tối giản, không rối

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var hp_bar: ProgressBar = $TopBar/HpBar
@onready var dart_count_label: Label = $TopBar/DartCountLabel
@onready var zone_warning: Panel = $ZoneWarning
@onready var zone_timer_label: Label = $TopBar/ZoneTimerLabel
@onready var kill_feed: VBoxContainer = $KillFeed
@onready var alive_label: Label = $TopBar/AliveLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var restart_label: Label = $GameOverPanel/RestartLabel
@onready var combo_label: Label = $ComboLabel
@onready var match_timer_label: Label = $MatchTimerLabel
@onready var mid_flight_hint: Label = $MidFlightHint
@onready var fps_label: Label = $FPSLabel
@onready var skill_panel: Panel = $SkillPanel
@onready var skill_dash_label: Label = $SkillPanel/SkillDashLabel
@onready var skill_shield_label: Label = $SkillPanel/SkillShieldLabel
@onready var skill_multishot_label: Label = $SkillPanel/SkillMultishotLabel
@onready var results_panel: Panel = $ResultsPanel
@onready var results_title: Label = $ResultsPanel/ResultsTitle
@onready var results_list: VBoxContainer = $ResultsPanel/ResultsList
@onready var results_restart_btn: Button = $ResultsPanel/ResultsRestartBtn
@onready var results_menu_btn: Button = $ResultsPanel/ResultsMenuBtn

var player: CharacterBody2D = null
var zone_shrink_timer: float = 0.0
var combo_display_timer: float = 0.0
var fps_update_timer: float = 0.0
var zone_warning_sound_timer: float = 0.0
var was_outside_zone: bool = false
# v2.2: Track combo display state separately from status display
var _combo_display_active: bool = false
# v2.2: Kill streak tracking
var _kill_streak: int = 0
var _kill_streak_timer: float = 0.0
const KILL_STREAK_WINDOW: float = 5.0  # 5s giữa mỗi kill để duy trì streak

# Premium colors
const GOLD := Color(1.0, 0.85, 0.3)
const CYAN := Color(0.4, 0.9, 1.0)
const GREEN := Color(0.3, 1.0, 0.5)
const PURPLE := Color(0.7, 0.65, 1.0)

func _ready():
	GameManager.player_score_changed.connect(_on_score_changed)
	GameManager.player_size_changed.connect(_on_size_changed)
	GameManager.player_hp_changed.connect(_on_hp_changed)
	GameManager.zone_shrank.connect(_on_zone_shrank)
	GameManager.combo_achieved.connect(_on_combo_achieved)
	GameManager.screen_shake_requested.connect(_on_screen_shake)
	GameManager.match_time_changed.connect(_on_match_time_changed)
	GameManager.game_over.connect(_on_game_over)
	# v2.2: Add to "hud" group so player can find us via get_first_node_in_group
	add_to_group("hud")
	# v2.2: Listen for daily reward signal
	if not GameManager.daily_reward_granted.is_connected(_on_daily_reward):
		GameManager.daily_reward_granted.connect(_on_daily_reward)

	zone_shrink_timer = GameManager.zone_shrink_interval

	game_over_panel.visible = false
	zone_warning.visible = false
	combo_label.visible = false
	mid_flight_hint.visible = false
	results_panel.visible = false

	fps_label.visible = SettingsManager.show_fps

	if results_restart_btn:
		results_restart_btn.pressed.connect(_on_results_restart)
	if results_menu_btn:
		results_menu_btn.pressed.connect(_on_results_menu)

	# Apply premium styling
	_apply_premium_styling()
	# Apply UI opacity
	_apply_ui_opacity()

func _apply_premium_styling():
	# Style top bar panel
	if $TopBar:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.04, 0.08, 0.88)
		style.border_color = Color(0.25, 0.2, 0.4, 0.3)
		style.border_width_bottom = 2
		style.shadow_color = Color(0, 0, 0, 0.4)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 3)
		$TopBar.add_theme_stylebox_override("panel", style)

	# Style HP bar with gradient fill
	if hp_bar:
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.2, 0.85, 0.3)
		fill_style.corner_radius_top_left = 4
		fill_style.corner_radius_top_right = 4
		fill_style.corner_radius_bottom_left = 4
		fill_style.corner_radius_bottom_right = 4
		hp_bar.add_theme_stylebox_override("fill", fill_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
		bg_style.corner_radius_top_left = 4
		bg_style.corner_radius_top_right = 4
		bg_style.corner_radius_bottom_left = 4
		bg_style.corner_radius_bottom_right = 4
		hp_bar.add_theme_stylebox_override("background", bg_style)

	# Style skill panel
	if skill_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.04, 0.08, 0.85)
		style.border_color = Color(0.25, 0.2, 0.4, 0.25)
		style.border_width_top = 1
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		skill_panel.add_theme_stylebox_override("panel", style)

	# Style game over panel
	if game_over_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.02, 0.06, 0.92)
		style.border_color = Color(0.8, 0.2, 0.2, 0.5)
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.shadow_color = Color(0.3, 0, 0, 0.5)
		style.shadow_size = 10
		game_over_panel.add_theme_stylebox_override("panel", style)

	# Style results panel
	if results_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.02, 0.02, 0.05, 0.95)
		style.border_color = Color(0.5, 0.4, 0.15, 0.4)
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		results_panel.add_theme_stylebox_override("panel", style)

	# Style result buttons
	_style_result_button(results_restart_btn, Color(0.04, 0.1, 0.06, 0.9), GREEN)
	_style_result_button(results_menu_btn, Color(0.08, 0.06, 0.14, 0.9), PURPLE)

	# Style zone warning panel
	if zone_warning:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.04, 0.04, 0.85)
		style.border_color = Color(1.0, 0.2, 0.2, 0.6)
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_width_left = 1
		style.border_width_right = 1
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		zone_warning.add_theme_stylebox_override("panel", style)

func _style_result_button(btn: Button, bg_color: Color, accent_color: Color):
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
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8
	style_normal.content_margin_left = 18
	style_normal.content_margin_right = 18
	style_normal.shadow_color = Color(0, 0, 0, 0.3)
	style_normal.shadow_size = 4
	style_normal.shadow_offset = Vector2(0, 2)
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(bg_color.r + 0.04, bg_color.g + 0.04, bg_color.b + 0.06, bg_color.a)
	style_hover.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.6)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)

func _apply_ui_opacity():
	var opacity = SettingsManager.ui_opacity
	if $TopBar:
		$TopBar.modulate.a = opacity
	if skill_panel:
		skill_panel.modulate.a = opacity

func set_player(p: CharacterBody2D):
	player = p
	player.player_died.connect(_on_player_died)
	player.player_respawned.connect(_on_player_respawned)
	player.dart_thrown.connect(_on_dart_thrown)
	player.teleport_performed.connect(_on_teleport_performed)
	player.skill_cooldown_updated.connect(_on_skill_cooldown_updated)

func _process(delta):
	if not player:
		return

	# Cập nhật thanh máu - update HP bar fill color based on HP
	hp_bar.value = GameManager.player_hp
	hp_bar.max_value = GameManager.player_max_hp
	# Dynamic HP bar color: green→yellow→red
	var hp_ratio = GameManager.player_hp / GameManager.player_max_hp if GameManager.player_max_hp > 0 else 0
	var hp_fill = hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if hp_fill:
		if hp_ratio > 0.6:
			hp_fill.bg_color = Color(0.2, 0.85, 0.3)  # Green
		elif hp_ratio > 0.3:
			hp_fill.bg_color = Color(0.9, 0.8, 0.15)  # Yellow
		else:
			hp_fill.bg_color = Color(0.9, 0.2, 0.15)  # Red

	# Cập nhật số phi tiêu - gọn gàng
	var dart_info = _get_dart_info()
	dart_count_label.text = dart_info
	mid_flight_hint.visible = _has_flying_darts()

	# Cập nhật đếm ngược vòng bo
	zone_shrink_timer -= delta
	if zone_shrink_timer <= 0 and GameManager.game_active:
		GameManager.shrink_zone()
		zone_shrink_timer = GameManager.zone_shrink_interval
	zone_timer_label.text = "Bo: %.0fs" % zone_shrink_timer

	# Cảnh báo ngoài vòng bo
	if not GameManager.is_in_zone(player.global_position):
		zone_warning.visible = true
		zone_warning_sound_timer -= delta
		if zone_warning_sound_timer <= 0:
			AudioManager.play_zone_warning()
			zone_warning_sound_timer = 1.5
		was_outside_zone = true
	else:
		zone_warning.visible = false
		if was_outside_zone:
			was_outside_zone = false
			zone_warning_sound_timer = 0.0

	# Cập nhật số người còn sống
	var alive_count = 0
	for a in get_tree().get_nodes_in_group("ai_players"):
		if is_instance_valid(a) and "is_alive" in a and a.is_alive:
			alive_count += 1
	if is_instance_valid(player) and player.is_alive:
		alive_count += 1
	alive_label.text = "Sống: %d" % alive_count

	# Cập nhật thời gian trận
	match_timer_label.text = "%s" % GameManager.get_time_remaining_str()
	if GameManager.time_remaining <= 30.0:
		match_timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		match_timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

	# Combo display timer
	if combo_label.visible and _combo_display_active:
		combo_display_timer -= delta
		if combo_display_timer <= 0:
			combo_label.visible = false
			_combo_display_active = false

	# v2.2: Kill streak timer
	if _kill_streak > 0:
		_kill_streak_timer -= delta
		if _kill_streak_timer <= 0:
			_kill_streak = 0  # Reset streak sau khi hết thời gian

	# FPS counter
	fps_label.visible = SettingsManager.show_fps
	if SettingsManager.show_fps:
		fps_update_timer -= delta
		if fps_update_timer <= 0:
			fps_update_timer = 0.5
			fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	# Update skill UI
	_update_skill_ui()

func _update_skill_ui():
	if not player or not skill_panel:
		return
	if skill_dash_label:
		var cd = player.skill_cooldowns.get(GameManager.Skill.DASH, 0.0)
		if cd > 0:
			skill_dash_label.text = "Dash\n%.1fs" % cd
			skill_dash_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			skill_dash_label.text = "Dash\nSẴN SÀNG"
			skill_dash_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.9))
	if skill_shield_label:
		var cd = player.skill_cooldowns.get(GameManager.Skill.SHIELD, 0.0)
		if cd > 0:
			skill_shield_label.text = "Shield\n%.1fs" % cd
			skill_shield_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			skill_shield_label.text = "Shield\nSẴN SÀNG"
			skill_shield_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	if skill_multishot_label:
		var cd = player.skill_cooldowns.get(GameManager.Skill.MULTISHOT, 0.0)
		if cd > 0:
			skill_multishot_label.text = "Multi\n%.1fs" % cd
			skill_multishot_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			skill_multishot_label.text = "Multi\nSẴN SÀNG"
			skill_multishot_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	# v2.1: Hiển thị trạng thái Crown / SMG / Spawn Invul trong combo_label
	# v2.2 FIX: Không ghi đè combo display - chỉ hiện status khi combo_label chưa active
	if combo_label and not _combo_display_active:
		var status_text = ""
		var status_color = Color(1, 1, 1)
		if "is_classic_mode" in player and player.is_classic_mode:
			if "is_spawn_invulnerable" in player and player.is_spawn_invulnerable:
				status_text = "🛡 INVUL: %.1fs" % player.spawn_invulnerable_timer
				status_color = Color(0, 1, 0.5)
			elif "smg_active" in player and player.smg_active:
				status_text = "🔫 SMG: %.1fs" % player.smg_timer
				status_color = Color(1.0, 0.4, 0.2)
			elif "crown_active" in player and player.crown_active:
				status_text = "♛ CROWN: %.1fs (+50%%)" % player.crown_active_timer
				status_color = Color(1.0, 0.85, 0.2)
			elif "crown_cooldown_timer" in player and player.crown_cooldown_timer > 0:
				status_text = "Crown CD: %.0fs" % player.crown_cooldown_timer
				status_color = Color(0.6, 0.6, 0.6)
		if status_text != "":
			combo_label.text = status_text
			combo_label.visible = true
			combo_label.add_theme_color_override("font_color", status_color)
		else:
			combo_label.visible = false

func _on_skill_cooldown_updated(skill_id: int, remaining: float):
	pass

func _get_dart_info() -> String:
	var flying = 0
	var stuck = 0
	for dart in player.all_darts:
		if is_instance_valid(dart):
			if dart.is_flying():
				flying += 1
			elif dart.is_stuck():
				stuck += 1
	var max_darts = GameManager.max_darts_per_player + player.dart_bonus + player.char_dart_bonus
	if flying > 0:
		return "Phi tiêu: %d bay + %d cắm / %d" % [flying, stuck, max_darts]
	elif stuck > 0:
		return "Phi tiêu: %d cắm / %d" % [stuck, max_darts]
	else:
		return "Phi tiêu: 0/%d" % max_darts

func _has_flying_darts() -> bool:
	for dart in player.all_darts:
		if is_instance_valid(dart) and dart.is_flying():
			return true
	return false

func _on_score_changed(new_score: int):
	score_label.text = "Điểm: %d" % new_score

func _on_size_changed(new_size: float):
	pass

func _on_hp_changed(hp: float, max_hp: float):
	hp_bar.value = hp
	hp_bar.max_value = max_hp

func _on_match_time_changed(time_remaining: float):
	match_timer_label.text = "%s" % GameManager.get_time_remaining_str()
	if time_remaining <= 30.0:
		match_timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

func _on_zone_shrank(new_radius: float):
	_add_kill_feed("Vòng bo thu nhỏ!", Color(1.0, 0.5, 0.0))

func _on_combo_achieved(combo_count: int):
	combo_label.text = "COMBO x%d!" % combo_count
	combo_label.visible = true
	combo_display_timer = 2.0
	_combo_display_active = true  # v2.2: chặn status display trong 2s
	_add_kill_feed("COMBO x%d!" % combo_count, Color(1.0, 0.8, 0.0))

func _on_screen_shake(intensity: float, duration: float):
	var tween = create_tween()
	var steps = max(int(duration / 0.02), 1)
	for i in steps:
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(self, "offset", offset, 0.02)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.05)

func _on_player_died(p: CharacterBody2D):
	game_over_panel.visible = true
	var killer = p.get_killer_name()
	if killer != "":
		game_over_label.text = "BẠN BỊ %s TIÊU DIỆT!" % killer.to_upper()
	else:
		game_over_label.text = "BẠN ĐÃ BỊ TIÊU DIỆT!"
	restart_label.text = "Hồi sinh sau %.0fs..." % GameManager.respawn_time
	_add_kill_feed("Bạn đã bị tiêu diệt!", Color(1.0, 0.2, 0.2))
	# v2.2: Reset kill streak khi chết
	_kill_streak = 0
	_kill_streak_timer = 0.0

func _on_player_respawned(p: CharacterBody2D):
	game_over_panel.visible = false
	_add_kill_feed("Đã hồi sinh!", Color(0.2, 1.0, 0.2))

func _on_dart_thrown(dart: Node2D):
	mid_flight_hint.visible = true
	var hint_ref = mid_flight_hint
	var self_ref = self
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(hint_ref) and is_instance_valid(self_ref):
			if not self_ref._has_flying_darts():
				hint_ref.visible = false
	)

func _on_teleport_performed(player: CharacterBody2D, to_position: Vector2):
	pass

func _add_kill_feed(text: String, color: Color = Color.WHITE):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_constant_override("shadow_outline_size", 2)
	kill_feed.add_child(label)
	# Fade out over 3 seconds
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(label.queue_free)

## v2.2: Gọi khi player giết được 1 đối thủ để track kill streak
func register_player_kill():
	_kill_streak += 1
	_kill_streak_timer = KILL_STREAK_WINDOW
	# Chỉ announce từ kill thứ 2 trở đi
	if _kill_streak < 2:
		return
	var announcement = ""
	var color = Color(1.0, 0.85, 0.2)
	match _kill_streak:
		2:
			announcement = "⚔ DOUBLE KILL!"
			color = Color(0.4, 1.0, 0.5)
		3:
			announcement = "🔥 TRIPLE KILL!"
			color = Color(1.0, 0.7, 0.2)
		4:
			announcement = "💥 QUADRA KILL!"
			color = Color(1.0, 0.5, 0.3)
		5:
			announcement = "👑 PENTA KILL!"
			color = Color(1.0, 0.4, 0.7)
		6, 7, 8:
			announcement = "🚀 KILLING SPREE x%d!" % _kill_streak
			color = Color(1.0, 0.4, 0.5)
		9, 10:
			announcement = "💀 UNSTOPPABLE x%d!" % _kill_streak
			color = Color(1.0, 0.3, 0.5)
		_:
			# > 10
			announcement = "⚡ GODLIKE x%d!" % _kill_streak
			color = Color(1.0, 0.2, 0.8)
	if announcement != "":
		_add_kill_feed(announcement, color)
		# Show big combo label
		if combo_label:
			combo_label.text = announcement
			combo_label.visible = true
			combo_display_timer = 2.5
			_combo_display_active = true
			combo_label.add_theme_color_override("font_color", color)
		if _kill_streak >= 3:
			AudioManager.play_combo(min(_kill_streak, 5))

## v2.2: Lấy kill streak hiện tại
func get_kill_streak() -> int:
	return _kill_streak

## v2.2: Hiển thị thông báo daily reward
func _on_daily_reward(streak: int, hp_bonus_percent: float):
	var msg = "🎁 ĐĂNG NHẬP NGÀY %d!\n+%.0f%% HP bonus!" % [streak, hp_bonus_percent * 100]
	_add_kill_feed(msg, Color(1.0, 0.85, 0.2))
	if combo_label:
		combo_label.text = "🎁 DAY %d!\n+%.0f%% HP" % [streak, hp_bonus_percent * 100]
		combo_label.visible = true
		combo_display_timer = 4.0
		_combo_display_active = true
		combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	AudioManager.play_achievement()

func _restart_game():
	get_tree().reload_current_scene()

func _on_game_over(winner_name: String, leaderboard: Array):
	_show_results(winner_name, leaderboard)

func _show_results(winner_name: String, leaderboard: Array):
	game_over_panel.visible = false
	results_panel.visible = true
	results_title.text = "KẾT THÚC! %s thắng!" % winner_name
	if winner_name == "Player":
		results_title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		results_title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))

	for child in results_list.get_children():
		child.queue_free()

	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var rank_label = Label.new()
		rank_label.text = "#%d" % (i + 1)
		rank_label.custom_minimum_size = Vector2(60, 0)
		rank_label.add_theme_font_size_override("font_size", 20)
		rank_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		rank_label.add_theme_constant_override("shadow_offset_y", 1)
		rank_label.add_theme_constant_override("shadow_outline_size", 2)
		if i == 0:
			rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		elif i == 1:
			rank_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		elif i == 2:
			rank_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.3))
		row.add_child(rank_label)

		var name_label2 = Label.new()
		name_label2.text = entry["name"]
		name_label2.custom_minimum_size = Vector2(160, 0)
		name_label2.add_theme_font_size_override("font_size", 18)
		name_label2.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		name_label2.add_theme_constant_override("shadow_offset_y", 1)
		name_label2.add_theme_constant_override("shadow_outline_size", 2)
		if entry.get("is_player", false):
			name_label2.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
			name_label2.text = entry["name"] + " (Bạn)"
		row.add_child(name_label2)

		var score_lbl = Label.new()
		score_lbl.text = "Điểm: %d" % entry["score"]
		score_lbl.custom_minimum_size = Vector2(120, 0)
		score_lbl.add_theme_font_size_override("font_size", 18)
		score_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
		score_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		score_lbl.add_theme_constant_override("shadow_offset_y", 1)
		score_lbl.add_theme_constant_override("shadow_outline_size", 2)
		row.add_child(score_lbl)

		var kills_lbl = Label.new()
		kills_lbl.text = "Kill: %d" % entry["kills"]
		kills_lbl.custom_minimum_size = Vector2(80, 0)
		kills_lbl.add_theme_font_size_override("font_size", 18)
		kills_lbl.add_theme_color_override("font_color", Color(0.85, 0.4, 0.4))
		kills_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		kills_lbl.add_theme_constant_override("shadow_offset_y", 1)
		kills_lbl.add_theme_constant_override("shadow_outline_size", 2)
		row.add_child(kills_lbl)

		results_list.add_child(row)

	AudioManager.play_achievement()

func _on_results_restart():
	AudioManager.play_ui_click()
	get_tree().reload_current_scene()

func _on_results_menu():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
