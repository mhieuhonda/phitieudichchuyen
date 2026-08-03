extends Control

## UICustomization - Chỉnh sửa giao diện (v1.2)
## Người chơi có thể thay đổi vị trí nút bấm, kích thước, opacity

@onready var back_btn: Button = $BackButton
@onready var joystick_size_slider: HSlider = $VBox/JoystickSizeSlider
@onready var joystick_size_label: Label = $VBox/JoystickSizeLabel
@onready var button_size_slider: HSlider = $VBox/ButtonSizeSlider
@onready var button_size_label: Label = $VBox/ButtonSizeLabel
@onready var ui_opacity_slider: HSlider = $VBox/UIOpacitySlider
@onready var ui_opacity_label: Label = $VBox/UIOpacityLabel
@onready var skill_btn_layout: OptionButton = $VBox/SkillBtnLayout
@onready var throw_btn_pos: OptionButton = $VBox/ThrowBtnPos
@onready var teleport_btn_pos: OptionButton = $VBox/TeleportBtnPos
@onready var hud_layout: OptionButton = $VBox/HUDLayout
@onready var reset_btn: Button = $VBox/ResetButton

func _ready():
	back_btn.pressed.connect(_on_back_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	
	joystick_size_slider.value_changed.connect(_on_joystick_size_changed)
	button_size_slider.value_changed.connect(_on_button_size_changed)
	ui_opacity_slider.value_changed.connect(_on_ui_opacity_changed)
	skill_btn_layout.item_selected.connect(_on_skill_layout_changed)
	throw_btn_pos.item_selected.connect(_on_throw_pos_changed)
	teleport_btn_pos.item_selected.connect(_on_teleport_pos_changed)
	hud_layout.item_selected.connect(_on_hud_layout_changed)
	
	# Populate OptionButtons
	skill_btn_layout.add_item("Ngang (mặc định)", 0)
	skill_btn_layout.add_item("Dọc (trái)", 1)
	skill_btn_layout.add_item("Dọc (phải)", 2)
	
	throw_btn_pos.add_item("Góc dưới phải", 0)
	throw_btn_pos.add_item("Góc dưới trái", 1)
	throw_btn_pos.add_item("Giữa dưới", 2)
	
	teleport_btn_pos.add_item("Trái ném", 0)
	teleport_btn_pos.add_item("Phải ném", 1)
	teleport_btn_pos.add_item("Trên ném", 2)
	
	hud_layout.add_item("Trên (mặc định)", 0)
	hud_layout.add_item("Dưới", 1)
	hud_layout.add_item("Ẩn tối giản", 2)
	
	# Hover sounds
	for btn in [back_btn, reset_btn]:
		btn.mouse_entered.connect(func(): AudioManager.play_ui_hover())
	
	_load_settings()

func _load_settings():
	joystick_size_slider.value = SettingsManager.joystick_size
	button_size_slider.value = SettingsManager.button_size
	ui_opacity_slider.value = SettingsManager.ui_opacity
	skill_btn_layout.select(SettingsManager.skill_btn_layout)
	throw_btn_pos.select(SettingsManager.throw_btn_pos)
	teleport_btn_pos.select(SettingsManager.teleport_btn_pos)
	hud_layout.select(SettingsManager.hud_layout)
	_update_labels()

func _update_labels():
	joystick_size_label.text = "Kích thước joystick: %d%%" % int(joystick_size_slider.value * 100)
	button_size_label.text = "Kích thước nút: %d%%" % int(button_size_slider.value * 100)
	ui_opacity_label.text = "Độ trong suốt UI: %d%%" % int(ui_opacity_slider.value * 100)

func _on_joystick_size_changed(val):
	SettingsManager.joystick_size = val
	SettingsManager.save_settings()
	_update_labels()
	AudioManager.play_ui_click()

func _on_button_size_changed(val):
	SettingsManager.button_size = val
	SettingsManager.save_settings()
	_update_labels()
	AudioManager.play_ui_click()

func _on_ui_opacity_changed(val):
	SettingsManager.ui_opacity = val
	SettingsManager.save_settings()
	_update_labels()
	AudioManager.play_ui_click()

func _on_skill_layout_changed(idx):
	SettingsManager.skill_btn_layout = idx
	SettingsManager.save_settings()
	AudioManager.play_ui_click()

func _on_throw_pos_changed(idx):
	SettingsManager.throw_btn_pos = idx
	SettingsManager.save_settings()
	AudioManager.play_ui_click()

func _on_teleport_pos_changed(idx):
	SettingsManager.teleport_btn_pos = idx
	SettingsManager.save_settings()
	AudioManager.play_ui_click()

func _on_hud_layout_changed(idx):
	SettingsManager.hud_layout = idx
	SettingsManager.save_settings()
	AudioManager.play_ui_click()

func _on_reset_pressed():
	AudioManager.play_ui_click()
	joystick_size_slider.value = 1.0
	button_size_slider.value = 1.0
	ui_opacity_slider.value = 1.0
	skill_btn_layout.select(0)
	throw_btn_pos.select(0)
	teleport_btn_pos.select(0)
	hud_layout.select(0)
	SettingsManager.joystick_size = 1.0
	SettingsManager.button_size = 1.0
	SettingsManager.ui_opacity = 1.0
	SettingsManager.skill_btn_layout = 0
	SettingsManager.throw_btn_pos = 0
	SettingsManager.teleport_btn_pos = 0
	SettingsManager.hud_layout = 0
	SettingsManager.save_settings()
	_update_labels()

func _on_back_pressed():
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
