extends Control

## Menu - Menu chính (v1.0)

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var play_button: Button = $PlayButton
@onready var settings_button: Button = $SettingsButton
@onready var quit_button: Button = $QuitButton
@onready var version_label: Label = $VersionLabel
@onready var new_feature_label: RichTextLabel = $NewFeatureLabel

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	for btn in [play_button, settings_button, quit_button]:
		btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

	new_feature_label.text = "[color=cyan][b]v1.0:[/b][/color] Map mới + Skill chủ động (Dash/Shield/Multishot) + Xếp hạng cuối trận\n[color=yellow]v1.0:[/color] Max HP theo size + Hồi 10% HP khi ăn đối thủ + Sprite tách nền đẹp\n[color=green]v1.0:[/color] Trận 5 phút + Hiệu ứng đẹp + Fix toàn bộ lỗi logic"
	version_label.text = "v1.0 - Phi Tiêu Dịch Chuyển"

	AudioManager.play_music("menu")

func _on_play_pressed():
	AudioManager.play_ui_click()
	AudioManager.play_confirm()
	SettingsManager.pending_scene = "res://scenes/main.tscn"
	get_tree().change_scene_to_file("res://scenes/loading.tscn")

func _on_settings_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
	AudioManager.play_cancel()
	get_tree().quit()
