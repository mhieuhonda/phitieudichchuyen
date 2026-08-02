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

				new_feature_label.text = "[color=cyan][b]v0.7:[/b][/color] Full-screen landscape + nút bắn phi tiêu mới (hold-red line-rotate-release) + tối ưu mobile\n[color=yellow]v0.6:[/color] Sprite nhân vật mới, Fix AI dart, Mobile throw, Camera shake, Esc menu\n[color=green]v0.5:[/color] Auto-detect thiết bị, Fix lỗi đen màn hình, Tối ưu hiệu suất"
				version_label.text = "v0.7 - Full-screen + Mobile Aim"

func _on_play_pressed():
				# Lưu target scene vào global, rồi chuyển sang loading screen
				SettingsManager.pending_scene = "res://scenes/main.tscn"
				get_tree().change_scene_to_file("res://scenes/loading.tscn")

func _on_settings_pressed():
				get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
				get_tree().quit()
