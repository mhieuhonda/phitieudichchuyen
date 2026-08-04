extends Control

## Menu - Menu chính (v2.2)
## v2.0: "Chơi Ngay" → Mode Selection (Online/Offline)
##        + nút "Chơi Offline" nhanh cho người không cần online
## v2.2: Thêm nút "Hướng Dẫn" → mở Guide screen

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

        new_feature_label.text = "[color=#00ff88][b]v2.2:[/b][/color] Hướng Dẫn chơi mới + Admin Guide (mã: hieulouisking)\n[color=#ffaa00][b]Server URL config[/b][/color]: đổi relay server trong Settings\n[color=#ff4444][b]Bug fixes[/b][/color]: dart/teleport vs remote players, HUD status overlap\n[color=#44aaff][b]Kill Streaks[/b][/color]: Double/Triple/Quadra/Penta Kill!"
        version_label.text = "v2.2 - Phi Tiêu Dịch Chuyển"

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

func _on_guide_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        get_tree().change_scene_to_file("res://scenes/guide.tscn")

func _on_quit_pressed():
        AudioManager.play_cancel()
        get_tree().quit()
