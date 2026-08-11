extends Control

## Profile - Hồ sơ người chơi (v4.1)
## Scene: scenes/profile.tscn
## - Hiển thị: tên hiển thị, username, danh hiệu, level, EXP progress
## - Chuỗi online (số ngày đăng nhập liên tiếp)
## - Thống kê: số trận, số thắng, số kills, win rate
## - Nút đăng xuất
## - Có thể xem profile người khác qua ?username=

@onready var avatar_label: Label = $CenterContainer/VBox/TopHBox/AvatarLabel
@onready var display_name_label: Label = $CenterContainer/VBox/TopHBox/InfoVBox/DisplayNameLabel
@onready var username_label: Label = $CenterContainer/VBox/TopHBox/InfoVBox/UsernameLabel
@onready var title_label: Label = $CenterContainer/VBox/TopHBox/InfoVBox/TitleLabel
@onready var online_label: Label = $CenterContainer/VBox/TopHBox/InfoVBox/OnlineLabel
@onready var level_value_label: Label = $CenterContainer/VBox/StatsGrid/LevelVBox/LevelValueLabel
@onready var exp_bar: ProgressBar = $CenterContainer/VBox/StatsGrid/LevelVBox/ExpBar
@onready var exp_text_label: Label = $CenterContainer/VBox/StatsGrid/LevelVBox/ExpTextLabel
@onready var streak_value_label: Label = $CenterContainer/VBox/StatsGrid/StreakVBox/StreakValueLabel
@onready var streak_text_label: Label = $CenterContainer/VBox/StatsGrid/StreakVBox/StreakTextLabel
@onready var matches_value_label: Label = $CenterContainer/VBox/StatsGrid/MatchesVBox/MatchesValueLabel
@onready var wins_value_label: Label = $CenterContainer/VBox/StatsGrid/WinsVBox/WinsValueLabel
@onready var kills_value_label: Label = $CenterContainer/VBox/StatsGrid/KillsVBox/KillsValueLabel
@onready var winrate_value_label: Label = $CenterContainer/VBox/StatsGrid/WinRateVBox/WinRateValueLabel
@onready var refresh_button: Button = $CenterContainer/VBox/ButtonHBox/RefreshButton
@onready var logout_button: Button = $CenterContainer/VBox/ButtonHBox/LogoutButton
@onready var back_button: Button = $CenterContainer/VBox/ButtonHBox/BackButton
@onready var developer_label: Label = $DeveloperLabel

# For fetching other users' profiles via direct HTTP
var _http_request: HTTPRequest

const SCALE_UP := Vector2(1.05, 1.05)
const SCALE_NORMAL := Vector2(1.0, 1.0)

func _ready():
        _http_request = HTTPRequest.new()
        _http_request.timeout = 15.0
        # v4.3 FIX: Godot 4.7 xóa property `tls_options`, phải dùng method set_tls_options()
        # v4.3: Dùng HTTP nên TLS không cần thiết, nhưng vẫn set để đề phòng đổi lại HTTPS
        _http_request.set_tls_options(TLSOptions.client_unsafe())
        add_child(_http_request)
        refresh_button.pressed.connect(_on_refresh)
        logout_button.pressed.connect(_on_logout)
        back_button.pressed.connect(_on_back)
        AccountManager.profile_updated.connect(_on_profile_updated)
        AccountManager.logged_out.connect(_on_logged_out)
        # Style buttons (match menu.gd premium look)
        _style_button(refresh_button, Color(0.4, 0.9, 1.0))
        _style_button(logout_button, Color(1.0, 0.4, 0.3))
        _style_button(back_button, Color(1.0, 0.85, 0.3))
        # Hover & touch scale effects
        for btn in [refresh_button, logout_button, back_button]:
                if btn:
                        btn.mouse_entered.connect(_on_btn_hover.bind(btn, true))
                        btn.mouse_exited.connect(_on_btn_hover.bind(btn, false))
                        _setup_touch_scale(btn)
        # Branding
        if developer_label:
                developer_label.text = "Game developed by Hieu Louis"
        # Initial render
        _render_profile()
        # Fetch fresh data
        _on_refresh()
        AudioManager.play_music("menu")

# v4.2: Hover / touch scale effects (match menu.gd)
func _setup_touch_scale(btn: Control):
        if not btn:
                return
        btn.gui_input.connect(func(event: InputEvent):
                if event is InputEventMouseButton:
                        if event.pressed:
                                _animate_scale(btn, SCALE_UP, 0.1)
                        else:
                                _animate_scale(btn, SCALE_NORMAL, 0.15)
                elif event is InputEventScreenTouch:
                        if event.pressed:
                                _animate_scale(btn, SCALE_UP, 0.1)
                        else:
                                _animate_scale(btn, SCALE_NORMAL, 0.15)
        )

func _animate_scale(control: Control, target_scale: Vector2, duration: float):
        if not is_instance_valid(control):
                return
        var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
        tween.tween_property(control, "scale", target_scale, duration)

func _on_btn_hover(btn: Button, entering: bool):
        if not btn or not is_instance_valid(btn):
                return
        if entering:
                AudioManager.play_ui_hover()
                _animate_scale(btn, SCALE_UP, 0.1)
        else:
                _animate_scale(btn, SCALE_NORMAL, 0.15)

func _render_profile():
        var user = AccountManager.current_user
        if user.is_empty():
                display_name_label.text = "Khách (chưa đăng nhập)"
                username_label.text = "—"
                title_label.text = ""
                online_label.text = ""
                level_value_label.text = "—"
                exp_bar.value = 0
                exp_text_label.text = ""
                streak_value_label.text = "—"
                streak_text_label.text = "ngày liên tiếp"
                matches_value_label.text = "—"
                wins_value_label.text = "—"
                kills_value_label.text = "—"
                winrate_value_label.text = "—"
                avatar_label.text = "?"
                logout_button.visible = false
                refresh_button.visible = false
                return
        var display = String(user.get("display_name", "?"))
        var uname = String(user.get("username", "?"))
        var title = String(user.get("title", ""))
        var level = int(user.get("level", 1))
        var exp = int(user.get("exp", 0))
        var exp_to_next = int(user.get("exp_to_next", 0))
        var exp_pct = float(user.get("exp_progress_pct", 0))
        var streak = int(user.get("online_streak", 0))
        var matches = int(user.get("total_matches", 0))
        var wins = int(user.get("total_wins", 0))
        var kills = int(user.get("total_kills", 0))
        var win_rate = float(user.get("win_rate", 0))
        display_name_label.text = display
        username_label.text = "@%s" % uname
        title_label.text = "🏆 Danh hiệu: %s" % title
        online_label.text = "✓ Đang online"  # we're on this account, so online
        level_value_label.text = "Lv %d" % level
        exp_bar.value = exp_pct
        exp_text_label.text = "%d / %d EXP  (%.1f%%)" % [exp - _exp_at_level(level), exp - _exp_at_level(level) + exp_to_next, exp_pct]
        streak_value_label.text = "%d" % streak
        streak_text_label.text = "ngày liên tiếp 🔥"
        matches_value_label.text = "%d" % matches
        wins_value_label.text = "%d" % wins
        kills_value_label.text = "%d" % kills
        winrate_value_label.text = "%.1f%%" % win_rate
        avatar_label.text = display.substr(0, 1).to_upper() if display.length() > 0 else "?"
        logout_button.visible = true
        refresh_button.visible = true

func _exp_at_level(level: int) -> int:
        # Match server: total_exp_for_level(N) = 50 * (N-1) * N
        if level <= 1:
                return 0
        return 50 * (level - 1) * level

func _on_refresh():
        if not AccountManager.is_logged_in():
                return
        AccountManager.fetch_me()

func _on_profile_updated(_user: Dictionary):
        _render_profile()

func _on_logged_out():
        _render_profile()

func _on_logout():
        AccountManager.logout()

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
        normal.shadow_color = Color(0, 0, 0, 0.45)
        normal.shadow_size = 4
        normal.shadow_offset = Vector2(0, 2)
        var hover = normal.duplicate()
        hover.bg_color = Color(0.13, 0.11, 0.22, 0.98)
        hover.border_color = Color(accent.r, accent.g, accent.b, 0.9)
        var pressed = normal.duplicate()
        pressed.bg_color = Color(0.04, 0.04, 0.08, 0.98)
        pressed.border_color = Color(accent.r, accent.g, accent.b, 0.95)
        btn.add_theme_stylebox_override("normal", normal)
        btn.add_theme_stylebox_override("hover", hover)
        btn.add_theme_stylebox_override("pressed", pressed)
        btn.add_theme_stylebox_override("focus", normal)

func _unhandled_input(event: InputEvent):
        if event.is_action_pressed("menu_back"):
                get_viewport().set_input_as_handled()
                _on_back()
