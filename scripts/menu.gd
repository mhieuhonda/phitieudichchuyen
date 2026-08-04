extends Control

## Menu - Menu chính (v2.4)
## v2.0: "Chơi Ngay" → Mode Selection (Online/Offline)
## v2.2: Thêm nút "Hướng Dẫn" → mở Guide screen
## v2.3: Xóa cấu hình Server URL - relay server đã hardcoded
## v2.4: Thêm nút "Vượt Ải" + đa ngôn ngữ (VI/EN) + ẩn mã bí mật

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var play_button: Button = $PlayButton
@onready var characters_button: Button = $CharactersButton
@onready var settings_button: Button = $SettingsButton
@onready var guide_button: Button = $GuideButton
@onready var quit_button: Button = $QuitButton
@onready var version_label: Label = $VersionLabel
@onready var new_feature_label: RichTextLabel = $NewFeatureLabel

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	characters_button.pressed.connect(_on_characters_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	if guide_button:
		guide_button.pressed.connect(_on_guide_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	for btn in [play_button, characters_button, settings_button, guide_button, quit_button]:
		if btn:
			btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

	# v2.4: Listen for language changes
	if I18N:
		I18N.language_changed.connect(func(_l): _refresh_ui())

	_refresh_ui()
	AudioManager.play_music("menu")

func _refresh_ui():
	if title_label:
		title_label.text = I18N.t("menu.title")
	if subtitle_label:
		subtitle_label.text = I18N.t("menu.subtitle")
	if play_button:
		play_button.text = I18N.t("menu.play")
	if characters_button:
		characters_button.text = I18N.t("menu.characters")
	if guide_button:
		guide_button.text = I18N.t("menu.guide")
	if settings_button:
		settings_button.text = I18N.t("menu.settings")
	if quit_button:
		quit_button.text = I18N.t("menu.quit")
	if version_label:
		version_label.text = "v2.4 - Phi Tiêu Dịch Chuyển"
	if new_feature_label:
		if I18N.is_vi():
			new_feature_label.text = "[color=#00ff88][b]v2.4:[/b][/color] Fix server online + Chế độ Vượt Ải (500 level)\n[color=#ffaa00][b]Ngôn ngữ[/b][/color]: Tiếng Việt / English trong Settings\n[color=#ff4444][b]Zombie horror[/b][/color]: Sound kinh dị cho chế độ Vượt Ải\n[color=#44aaff][b]15 Skills[/b][/color]: Hub kỹ năng gọn gàng + joystick tròn"
		else:
			new_feature_label.text = "[color=#00ff88][b]v2.4:[/b][/color] Fixed online server + Endless Mode (500 levels)\n[color=#ffaa00][b]Language[/b][/color]: Vietnamese / English in Settings\n[color=#ff4444][b]Zombie horror[/b][/color]: Horror sounds for Endless Mode\n[color=#44aaff][b]15 Skills[/b][/color]: Neat skill hub + round joystick"

func _on_play_pressed():
	AudioManager.play_ui_click()
	AudioManager.play_confirm()
	# v2.0: Chuyển sang Mode Selection để chọn Online/Offline/Endless
	get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _on_characters_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/character_screen.tscn")

func _on_settings_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_guide_pressed():
	AudioManager.play_ui_click()
	AudioManager.play_confirm()
	get_tree().change_scene_to_file("res://scenes/guide.tscn")

func _on_quit_pressed():
	AudioManager.play_cancel()
	get_tree().quit()
