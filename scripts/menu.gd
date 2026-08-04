extends Control

## Menu - Menu chính (v2.0)
## v2.0: "Chơi Ngay" → Mode Selection (Online/Offline)
##        + nút "Chơi Offline" nhanh cho người không cần online

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

        new_feature_label.text = "[color=#00ff88][b]v2.1:[/b][/color] Nhân vật mới Hieu Louis - Classic (mã: hieulouis99)\n[color=#ffaa00][b]Crown Skill[/b][/color]: ghim 5 đối thủ, +50% điểm\n[color=#ff4444][b]SMG Reward[/b][/color]: 50 kills → tiểu liên vô hạn 20s\n[color=#44aaff][b]Online fix[/b][/color]: sửa lỗi không vào được queue matchmaking"
        version_label.text = "v2.1 - Phi Tiêu Dịch Chuyển"

        AudioManager.play_music("menu")

func _on_play_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        # v2.0: Chuyển sang Mode Selection để chọn Online/Offline
        get_tree().change_scene_to_file("res://scenes/mode_select.tscn")

func _on_characters_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/character_screen.tscn")

func _on_settings_pressed():
        AudioManager.play_ui_click()
        get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_pressed():
        AudioManager.play_cancel()
        get_tree().quit()
