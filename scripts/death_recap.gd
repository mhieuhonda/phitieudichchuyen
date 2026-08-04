extends Control

## DeathRecap - Hien thi thong tin chi tiet khi chet (v2.8)
## Nguoi/AI nao giet, bao nhieu damage, thoi gian song

@onready var killer_label: Label = $VBox/KillerLabel
@onready var damage_label: Label = $VBox/DamageLabel
@onready var survival_label: Label = $VBox/SurvivalLabel
@onready var kills_label: Label = $VBox/KillsLabel
@onready var close_button: Button = $VBox/CloseButton

var _total_damage_taken: float = 0.0
var _last_killer_name: String = ""
var _survival_time: float = 0.0
var _kills_before_death: int = 0

func _ready():
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close)
		close_button.mouse_entered.connect(func(): AudioManager.play_ui_hover())
	_apply_styling()

func _apply_styling():
	var panel = $Panel
	if panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.02, 0.02, 0.95)
		style.border_color = Color(0.8, 0.2, 0.2, 0.5)
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		panel.add_theme_stylebox_override("panel", style)

## Track damage received (called from player on take_damage)
func track_damage(amount: float, attacker_name: String):
	_total_damage_taken += amount
	_last_killer_name = attacker_name

## Show the recap when player dies
func show_recap(survival_time: float, kills: int):
	_survival_time = survival_time
	_kills_before_death = kills
	visible = true
	
	if killer_label:
		if _last_killer_name != "":
			killer_label.text = I18N.t("death_recap.killed_by", [_last_killer_name])
			killer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			killer_label.text = I18N.t("death_recap.killed_unknown")
			killer_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	
	if damage_label:
		damage_label.text = I18N.t("death_recap.damage_taken", [int(_total_damage_taken)])
		damage_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	
	if survival_label:
		var mins = int(_survival_time) / 60
		var secs = int(_survival_time) % 60
		survival_label.text = I18N.t("death_recap.survival_time", ["%02d:%02d" % [mins, secs]])
		survival_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	
	if kills_label:
		kills_label.text = I18N.t("death_recap.kills", [_kills_before_death])
		kills_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))

func _on_close():
	visible = false
	_total_damage_taken = 0.0
	_last_killer_name = ""
	AudioManager.play_ui_click()

func reset_tracking():
	_total_damage_taken = 0.0
	_last_killer_name = ""
