extends Control

## Menu - Menu chính

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
        
        new_feature_label.text = "[color=cyan][b]v0.4:[/b][/color] Fix CI/CD - Build APK + EXE + Linux tu dong!\n[color=yellow]v0.3:[/color] Sprite dep, Cai dat do hoa, Joystick ao"

func _on_play_pressed():
        get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_pressed():
        get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
        get_tree().quit()
