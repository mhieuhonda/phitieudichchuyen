extends Control

## Menu - Menu chính (v1.7)
## v1.7: "Chơi Ngay" → Mode Selection (Online/Offline)

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

        new_feature_label.text = "[color=cyan][b]v1.7:[/b][/color] CHƠI ONLINE! Ghép trận 10-20 người, matchmaking tự động, bot AI fill\n[color=yellow]v1.7:[/color] Relay Server + WebSocket, đồng bộ trạng thái real-time giữa các người chơi\n[color=green]v1.6:[/color] Rà soát toàn diện Godot 4.7 - Modern GDScript idioms, collision mask sync"
        version_label.text = "v1.7 - Phi Tiêu Dịch Chuyển"

        AudioManager.play_music("menu")

func _on_play_pressed():
        AudioManager.play_ui_click()
        AudioManager.play_confirm()
        # v1.7: Chuyển sang Mode Selection thay vì vào game ngay
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
