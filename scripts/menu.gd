extends Control

## Menu - Menu chính (v0.8)

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

    # UI hover sounds
    for btn in [play_button, settings_button, quit_button]:
        btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

    new_feature_label.text = "[color=cyan][b]v0.9:[/b][/color] Fix joystick + multi-touch + nút to hơn + fix AI dart xuyên player\n[color=yellow]v0.8:[/color] 150+ sound effects + nhạc nền + fix nút mobile + tối ưu\n[color=green]v0.7:[/color] Full-screen landscape + nút bắn phi tiêu mới (hold-red line-rotate-release)"
    version_label.text = "v0.9 - Multi-touch Fix"

    # Phát nhạc menu
    AudioManager.play_music("menu")

func _on_play_pressed():
    AudioManager.play_ui_click()
    AudioManager.play_confirm()
    # Lưu target scene vào global, rồi chuyển sang loading screen
    SettingsManager.pending_scene = "res://scenes/main.tscn"
    get_tree().change_scene_to_file("res://scenes/loading.tscn")

func _on_settings_pressed():
    AudioManager.play_ui_click()
    get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
    AudioManager.play_cancel()
    get_tree().quit()
