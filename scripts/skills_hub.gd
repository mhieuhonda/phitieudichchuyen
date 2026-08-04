extends Control

## SkillsHub - Hub kỹ năng cho Vượt Ải (v2.4)
## - 15 kỹ năng trong grid 3 cột x 5 hàng (BÊN PHẢI màn hình)
## - Mỗi kỹ năng: icon emoji + tên + cooldown + description
## - KHÓA cho đến khi đạt level yêu cầu
## - Tap để kích hoạt (hiển thị cooldown countdown)
## - KHÔNG chồng lấn với joystick (joystick bên TRÁI)

signal skill_activated(skill_id: int, skill_name: String)

# Định nghĩa 15 kỹ năng
# Format: { id, key, name_vi, name_en, desc_vi, desc_en, icon, cooldown, unlock_level, type }
# type: "buff" (cần duration), "instant" (dùng ngay), "toggle"
const SKILLS := [
	{
		"id": 1, "key": "QUICK_SHOT",
		"name_vi": "Bắn nhanh", "name_en": "Quick Shot",
		"desc_vi": "Phi tiêu -50% CD 5s", "desc_en": "Dart CD -50% 5s",
		"icon": "⚡", "cooldown": 5.0, "unlock_level": 1, "type": "buff",
	},
	{
		"id": 2, "key": "HEAL",
		"name_vi": "Hồi máu", "name_en": "Heal",
		"desc_vi": "+30 HP", "desc_en": "+30 HP",
		"icon": "❤", "cooldown": 10.0, "unlock_level": 1, "type": "instant",
	},
	{
		"id": 3, "key": "SHIELD",
		"name_vi": "Khiên", "name_en": "Shield",
		"desc_vi": "Miễn damage 3s", "desc_en": "Invulnerable 3s",
		"icon": "🛡", "cooldown": 15.0, "unlock_level": 3, "type": "buff",
	},
	{
		"id": 4, "key": "MULTISHOT",
		"name_vi": "Bắn 3 phi tiêu", "name_en": "Multishot",
		"desc_vi": "8s bắn 3 phi tiêu", "desc_en": "8s triple shot",
		"icon": "🔱", "cooldown": 12.0, "unlock_level": 5, "type": "buff",
	},
	{
		"id": 5, "key": "FREEZE",
		"name_vi": "Đóng băng", "name_en": "Freeze",
		"desc_vi": "Đóng băng zombie 2s", "desc_en": "Freeze zombies 2s",
		"icon": "❄", "cooldown": 20.0, "unlock_level": 8, "type": "instant",
	},
	{
		"id": 6, "key": "BOMB",
		"name_vi": "Bomb", "name_en": "Bomb",
		"desc_vi": "Nổ AOE quanh player", "desc_en": "AOE blast around player",
		"icon": "💣", "cooldown": 25.0, "unlock_level": 12, "type": "instant",
	},
	{
		"id": 7, "key": "SPEED_BOOST",
		"name_vi": "Tăng tốc", "name_en": "Speed Boost",
		"desc_vi": "Tốc độ +50% 5s", "desc_en": "Speed +50% 5s",
		"icon": "🏃", "cooldown": 15.0, "unlock_level": 15, "type": "buff",
	},
	{
		"id": 8, "key": "PIERCE",
		"name_vi": "Xuyên phá", "name_en": "Pierce",
		"desc_vi": "Phi tiêu xuyên 3 zombie 8s", "desc_en": "Darts pierce 3 zombies 8s",
		"icon": "🎯", "cooldown": 10.0, "unlock_level": 20, "type": "buff",
	},
	{
		"id": 9, "key": "LIFE_STEAL",
		"name_vi": "Hút máu", "name_en": "Life Steal",
		"desc_vi": "+5 HP/kill 10s", "desc_en": "+5 HP per kill 10s",
		"icon": "🩸", "cooldown": 30.0, "unlock_level": 25, "type": "buff",
	},
	{
		"id": 10, "key": "SLOW_TIME",
		"name_vi": "Chậm thời gian", "name_en": "Slow Time",
		"desc_vi": "Slow zombie 3s", "desc_en": "Slow zombies 3s",
		"icon": "⏳", "cooldown": 40.0, "unlock_level": 30, "type": "instant",
	},
	{
		"id": 11, "key": "HOMING",
		"name_vi": "Tự tìm", "name_en": "Homing",
		"desc_vi": "Phi tiêu tự tìm 8s", "desc_en": "Homing darts 8s",
		"icon": "🧲", "cooldown": 15.0, "unlock_level": 40, "type": "buff",
	},
	{
		"id": 12, "key": "EXPLOSION",
		"name_vi": "Nổ dây chuyền", "name_en": "Explosion",
		"desc_vi": "Phi tiêu nổ chain 8s", "desc_en": "Chain explosion darts 8s",
		"icon": "💥", "cooldown": 20.0, "unlock_level": 50, "type": "buff",
	},
	{
		"id": 13, "key": "BERSERK",
		"name_vi": "Cuồng nộ", "name_en": "Berserk",
		"desc_vi": "Damage x2 trong 5s", "desc_en": "Damage x2 for 5s",
		"icon": "🔥", "cooldown": 25.0, "unlock_level": 75, "type": "buff",
	},
	{
		"id": 14, "key": "NUKE",
		"name_vi": "Nuke", "name_en": "Nuke",
		"desc_vi": "Tiêu diệt tất cả zombie", "desc_en": "Kill all zombies",
		"icon": "☢", "cooldown": 60.0, "unlock_level": 100, "type": "instant",
	},
	{
		"id": 15, "key": "INVINCIBLE",
		"name_vi": "Bất tử", "name_en": "Invincible",
		"desc_vi": "Bất tử 5s", "desc_en": "Invincible 5s",
		"icon": "👑", "cooldown": 90.0, "unlock_level": 150, "type": "buff",
	},
]

# State tracking
var current_level: int = 1
var _cooldowns: Dictionary = {}  # skill_id -> remaining_seconds
var _buttons: Dictionary = {}  # skill_id -> Button
var _cooldown_labels: Dictionary = {}  # skill_id -> Label (overlay)
var _lock_labels: Dictionary = {}  # skill_id -> Label (lock overlay)

@onready var grid: GridContainer = $Panel/Margin/VBox/Grid
@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel

func _ready():
	_build_grid()
	_refresh_ui()
	if I18N:
		I18N.language_changed.connect(func(_l): _refresh_ui())

func _build_grid():
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for skill in SKILLS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.add_theme_font_size_override("font_size", 24)
		btn.text = skill.icon
		# Dùng .bind(skill.id) để capture giá trị tại thời điểm bind (tránh closure bug)
		btn.pressed.connect(_on_skill_pressed.bind(skill.id))
		# Tooltip = description (theo ngôn ngữ hiện tại)
		btn.tooltip_text = "%s\n%s" % [_get_skill_name(skill), _get_skill_desc(skill)]
		# Container cho cooldown overlay + lock overlay
		var overlay_container = Control.new()
		overlay_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Cooldown overlay
		var cd_label = Label.new()
		cd_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd_label.add_theme_font_size_override("font_size", 18)
		cd_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		cd_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		cd_label.add_theme_constant_override("shadow_offset_y", 1)
		cd_label.add_theme_constant_override("shadow_outline_size", 2)
		cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd_label.visible = false
		# Lock overlay
		var lock_label = Label.new()
		lock_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 14)
		lock_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4, 0.95))
		lock_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		lock_label.add_theme_constant_override("shadow_offset_y", 1)
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_label.text = "🔒%d" % skill.unlock_level
		lock_label.visible = true  # default locked
		overlay_container.add_child(cd_label)
		overlay_container.add_child(lock_label)
		btn.add_child(overlay_container)
		grid.add_child(btn)
		_buttons[skill.id] = btn
		_cooldown_labels[skill.id] = cd_label
		_lock_labels[skill.id] = lock_label

func _process(delta):
	var needs_refresh := false
	for skill_id in _cooldowns.keys():
		var remaining = _cooldowns[skill_id]
		remaining -= delta
		if remaining <= 0:
			_cooldowns.erase(skill_id)
		else:
			_cooldowns[skill_id] = remaining
		needs_refresh = true
	if needs_refresh:
		_refresh_overlays()

func _refresh_overlays():
	for skill in SKILLS:
		var sid = skill.id
		var cd_label = _cooldown_labels.get(sid)
		var btn = _buttons.get(sid)
		if not btn:
			continue
		var is_locked = current_level < skill.unlock_level
		var is_on_cooldown = _cooldowns.has(sid)
		btn.disabled = is_locked or is_on_cooldown
		if cd_label:
			if is_on_cooldown:
				cd_label.visible = true
				cd_label.text = "%d" % ceil(_cooldowns[sid])
			else:
				cd_label.visible = false
		var lock_label = _lock_labels.get(sid)
		if lock_label:
			lock_label.visible = is_locked

func _refresh_ui():
	if title_label and I18N:
		title_label.text = I18N.t("endless.skills")
	_refresh_overlays()

## Cập nhật level → mở khóa skill
func set_level(level: int):
	current_level = level
	_refresh_overlays()

## Set cooldown cho skill (sau khi kích hoạt)
func _set_cooldown(skill_id: int, duration: float):
	_cooldowns[skill_id] = duration

func _on_skill_pressed(skill_id: int):
	var skill = null
	for s in SKILLS:
		if s.id == skill_id:
			skill = s
			break
	if not skill:
		return
	if current_level < skill.unlock_level:
		if AudioManager:
			AudioManager.play_error()
		return
	if _cooldowns.has(skill_id):
		return  # Đang cooldown
	_set_cooldown(skill_id, skill.cooldown)
	if AudioManager:
		AudioManager.play_powerup()
	emit_signal("skill_activated", skill_id, skill.key)

## Lấy thông tin skill theo id
func get_skill(skill_id: int) -> Dictionary:
	for s in SKILLS:
		if s.id == skill_id:
			return s
	return {}

## Reset toàn bộ cooldown khi vào level mới
func reset_cooldowns():
	_cooldowns.clear()
	_refresh_overlays()

## Lấy tên skill theo ngôn ngữ hiện tại
func _get_skill_name(skill: Dictionary) -> String:
	if I18N and I18N.is_en():
		return skill.get("name_en", skill.name_vi)
	return skill.name_vi

## Lấy mô tả skill theo ngôn ngữ hiện tại
func _get_skill_desc(skill: Dictionary) -> String:
	if I18N and I18N.is_en():
		return skill.get("desc_en", skill.desc_vi)
	return skill.desc_vi
