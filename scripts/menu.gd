extends Control

## Menu - Menu chính (v1.2)

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var play_button: Button = $PlayButton
@onready var characters_button: Button = $CharactersButton
@onready var settings_button: Button = $SettingsButton
@onready var quit_button: Button = $QuitButton
@onready var version_label: Label = $VersionLabel
@onready var new_feature_label: RichTextLabel = $NewFeatureLabel

func _ready():
        play_button.pressed.connect(_on_play_pressed)
        characters_button.pressed.connect(_on_characters_pressed)
        settings_button.pressed.connect(_on_settings_pressed)
        quit_button.pressed.connect(_on_quit_pressed)

        for btn in [play_button, characters_button, settings_button, quit_button]:
                btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())

        new_feature_label.text = "[color=cyan][b]v1.4:[/b][/color] Rà soát & sửa toàn bộ lỗi Godot 4.7 còn sót (dart monitoring, AI pickup HP, AudioManager API)\n[color=yellow]v1.4:[/color] V1.3 đã fix class_name conflict + ternary parse + UI drag-drop\n[color=green]v1.4:[/color] Clean code: bỏ truy cập private member, sửa logic AI max HP"
        version_label.text = "v1.4 - Phi Tiêu Dịch Chuyển"

        AudioManager.play_music("menu")

func _on_play_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        SettingsManager.pending_scene = "res://scenes/main.tscn"
        get_tree().change_scene_to_file("res://scenes/loading.tscn")

func _on_characters_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/character_screen.tscn")

func _on_settings_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
        AudioManager.play_cancel()
        get_tree().quit()
