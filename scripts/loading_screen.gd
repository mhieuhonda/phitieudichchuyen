extends Control

## LoadingScreen - Màn hình tải khi chuyển scene
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
	
	# Bắt đầu tải
	_start_loading()

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
