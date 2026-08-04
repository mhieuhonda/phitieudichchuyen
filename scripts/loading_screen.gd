extends Control

## LoadingScreen - Màn hình tải khi chuyển scene - Premium UI
## Hiển thị tiến trình, phát hiện thiết bị, tránh đen màn hình

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var device_label: Label = $DeviceLabel
@onready var quality_label: Label = $QualityLabel
@onready var sub_label: Label = $SubLabel

var load_progress: float = 0.0
var target_scene: String = ""

func _ready():
	# Hiển thị thông tin thiết bị
	device_label.text = "Thiết bị: %s" % SettingsManager.get_device_tier_name()
	quality_label.text = "Đồ họa: %s" % SettingsManager.get_quality_name()

	if SettingsManager.was_auto_detected:
		sub_label.text = "Tự động chọn đồ họa: %s" % SettingsManager.get_quality_name()

	# Đọc target scene từ global
	target_scene = SettingsManager.pending_scene
	SettingsManager.pending_scene = ""

	# Phát nhạc menu nếu đang loading từ menu
	if not AudioManager.is_music_playing():
		AudioManager.play_music("menu")

	# Apply premium styling
	_apply_premium_styling()
	# Bắt đầu tải
	_start_loading()

func _apply_premium_styling():
	# Style progress bar
	if progress_bar:
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.5, 0.4, 0.8)
		fill_style.corner_radius_top_left = 5
		fill_style.corner_radius_top_right = 5
		fill_style.corner_radius_bottom_left = 5
		fill_style.corner_radius_bottom_right = 5
		progress_bar.add_theme_stylebox_override("fill", fill_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
		bg_style.corner_radius_top_left = 5
		bg_style.corner_radius_top_right = 5
		bg_style.corner_radius_bottom_left = 5
		bg_style.corner_radius_bottom_right = 5
		bg_style.border_color = Color(0.3, 0.25, 0.5, 0.3)
		bg_style.border_width_top = 1
		bg_style.border_width_bottom = 1
		bg_style.border_width_left = 1
		bg_style.border_width_right = 1
		progress_bar.add_theme_stylebox_override("background", bg_style)

func _process(delta):
	if load_progress < 1.0:
		load_progress = min(load_progress + delta * 1.2, 1.0)
		progress_bar.value = load_progress * 100.0

func _start_loading():
	# Đợi 2 frame để UI hiển thị
	await get_tree().process_frame
	await get_tree().process_frame
	
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
