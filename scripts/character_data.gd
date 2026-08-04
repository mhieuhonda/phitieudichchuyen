extends Node

## CharacterData - Dữ liệu nhân vật (v2.3)
## Mỗi nhân vật có: tên, chỉ số, kỹ năng, sprite, màu sắc
## Singleton autoload (đăng ký trong project.godot, không dùng class_name
## vì Godot 4.7 cấm class_name trùng tên autoload singleton)
##
## v2.1: Thêm nhân vật đặc biệt "Hieu Louis - Classic" (id=12)
## - HP cực cao, speed cao, dart bonus cực cao (vô hạn)
## - Có skill đặc biệt "classic" (Crown skill - ghim 5 đối thủ, +50% điểm)
## - Chỉ mở khóa qua mã quà tặng "hieulouis99"
##
## v2.2: Mở rộng hệ thống mã quà tặng
## - "hieulouis99": mở khóa nhân vật Hieu Louis - Classic (char_id=12)
## - "hieulouisking": mở khóa "Hướng Dẫn Cho Admin" trong mục Hướng Dẫn
##   (không lộ thông tin nhạy cảm, chỉ là tài liệu nội bộ cho admin)
##
## v2.3: Thêm nhân vật "Ma Tôn" (id=13)
## - HARD COUNTER Hieu Louis - Classic: mọi chỉ số đều cao hơn
## - HP 1000 (gấp đôi Classic's 500), Speed 80 (vs 50), Dart 200 (vs 100)
## - Skill "Ma Tôn Quyền": instant-kill Classic, immune Crown, +100% score, 5s invincibility
## - Chỉ mở khóa qua mã quà tặng "maton99"

enum CharType { WARRIOR, MAGE, BRAWLER, ASSASSIN, CLASSIC, MATON }

# 14 nhân vật (12 cũ + 1 v2.1 + 1 v2.3)
const CHARACTERS = [
        {
                "id": 0,
                "name": "Rồng Đỏ",
                "title": "Chiến Binh Hỏa Diệm",
                "file": "char_dragon_red",
                "type": CharType.WARRIOR,
                "hp_bonus": 15.0,
                "speed_bonus": 0.0,
                "dart_bonus": 0,
                "skill_bonus": "dash",
                "skill_desc": "Dash mạnh hơn 20%",
                "lore": "Chiến binh huyền thoại với sức mạnh rồng lửa. Mỗi cú dash mang theo hỏa diệm thiêu rụi.",
                "color": Color(0.8, 0.15, 0.15),
        },
        {
                "id": 1,
                "name": "Phượng Xanh",
                "title": "Pháp Sư Băng Giá",
                "file": "char_phoenix_blue",
                "type": CharType.MAGE,
                "hp_bonus": 0.0,
                "speed_bonus": 10.0,
                "dart_bonus": 1,
                "skill_bonus": "multishot",
                "skill_desc": "Multishot bắn 4 phi tiêu thay vì 3",
                "lore": "Pháp sư điều khiển băng giá, bay lượn như phượng hoàng. Số phi tiêu nhiều hơn bất kỳ ai.",
                "color": Color(0.12, 0.4, 0.8),
        },
        {
                "id": 2,
                "name": "Hổ Vàng",
                "title": "Quyền Sư Hoàng Kim",
                "file": "char_tiger_gold",
                "type": CharType.BRAWLER,
                "hp_bonus": 25.0,
                "speed_bonus": 0.0,
                "dart_bonus": 0,
                "skill_bonus": "shield",
                "skill_desc": "Shield lâu hơn 50%",
                "lore": "Quyền sư với thân thể thép, không gì xuyên thủng được. Khiên bảo vệ cực kỳ vững chắc.",
                "color": Color(0.8, 0.63, 0.12),
        },
        {
                "id": 3,
                "name": "Báo Lục",
                "title": "Sát Thủ Lục Lâm",
                "file": "char_leopard_green",
                "type": CharType.ASSASSIN,
                "hp_bonus": -10.0,
                "speed_bonus": 20.0,
                "dart_bonus": 0,
                "skill_bonus": "dash",
                "skill_desc": "Dash cooldown giảm 30%",
                "lore": "Sát thủ nhanh nhất rừng xanh. Di chuyển như chớp, biến mất trong bóng tối.",
                "color": Color(0.12, 0.6, 0.24),
        },
        {
                "id": 4,
                "name": "Sói Tím",
                "title": "Chiến Binh Hắc Ám",
                "file": "char_wolf_purple",
                "type": CharType.WARRIOR,
                "hp_bonus": 10.0,
                "speed_bonus": 5.0,
                "dart_bonus": 0,
                "skill_bonus": "dash",
                "skill_desc": "Dash để lại vệt tối gây damage",
                "lore": "Chiến binh bóng tối, mỗi bước đi đều mang theo sức mạnh hắc ám.",
                "color": Color(0.4, 0.15, 0.63),
        },
        {
                "id": 5,
                "name": "Cáo Hồng",
                "title": "Pháp Sư Ảo Ảnh",
                "file": "char_fox_pink",
                "type": CharType.MAGE,
                "hp_bonus": -5.0,
                "speed_bonus": 15.0,
                "dart_bonus": 1,
                "skill_bonus": "multishot",
                "skill_desc": "Phi tiêu homing nhẹ",
                "lore": "Pháp sư ảo ảnh với khả năng đánh lừa đối thủ. Phi tiêu của cô luôn tìm được mục tiêu.",
                "color": Color(0.86, 0.31, 0.51),
        },
        {
                "id": 6,
                "name": "Gấu Nâu",
                "title": "Quyền Sư Sắt Đá",
                "file": "char_bear_brown",
                "type": CharType.BRAWLER,
                "hp_bonus": 30.0,
                "speed_bonus": -10.0,
                "dart_bonus": 0,
                "skill_bonus": "shield",
                "skill_desc": "Shield phản damage 20%",
                "lore": "Quyền sư với thân thể sắt đá, không gì có thể làm tổn thương. Khiên phản đòn nguy hiểm.",
                "color": Color(0.55, 0.31, 0.12),
        },
        {
                "id": 7,
                "name": "Diều Cam",
                "title": "Sát Thủ Chớp Nhoáng",
                "file": "char_kite_orange",
                "type": CharType.ASSASSIN,
                "hp_bonus": -5.0,
                "speed_bonus": 15.0,
                "dart_bonus": 0,
                "skill_bonus": "dash",
                "skill_desc": "Dash xuyên qua đối thủ",
                "lore": "Sát thủ di chuyển như chớp, có thể xuyên qua đối thủ khi dash.",
                "color": Color(0.9, 0.51, 0.12),
        },
        {
                "id": 8,
                "name": "Cọp Xanh",
                "title": "Chiến Binh Đại Dương",
                "file": "char_tiger_teal",
                "type": CharType.WARRIOR,
                "hp_bonus": 10.0,
                "speed_bonus": 10.0,
                "dart_bonus": 0,
                "skill_bonus": "dash",
                "skill_desc": "Dash tạo sóng nước làm chậm",
                "lore": "Chiến binh đại dương với sức mạnh thủy quái. Mỗi cú dash tạo sóng nước.",
                "color": Color(0.12, 0.6, 0.6),
        },
        {
                "id": 9,
                "name": "Chồn Bạc",
                "title": "Sát Thủ Bóng Đêm",
                "file": "char_marten_silver",
                "type": CharType.ASSASSIN,
                "hp_bonus": -10.0,
                "speed_bonus": 25.0,
                "dart_bonus": 0,
                "skill_bonus": "dash",
                "skill_desc": "Dash 2 lần liên tiếp",
                "lore": "Sát thủ nhanh nhất trong bóng đêm, có thể dash 2 lần liên tiếp.",
                "color": Color(0.55, 0.55, 0.63),
        },
        {
                "id": 10,
                "name": "Thiên Long",
                "title": "Pháp Sư Thần Thánh",
                "file": "char_dragon_divine",
                "type": CharType.MAGE,
                "hp_bonus": 5.0,
                "speed_bonus": 5.0,
                "dart_bonus": 2,
                "skill_bonus": "multishot",
                "skill_desc": "Multishot bắn 5 phi tiêu",
                "lore": "Pháp sư thần thánh với sức mạnh rồng trời. Số phi tiêu nhiều nhất, bắn dày đặc.",
                "color": Color(0.71, 0.55, 0.12),
        },
        {
                "id": 11,
                "name": "Hắc Vũ",
                "title": "Sát Thủ Tử Thần",
                "file": "char_dark_feather",
                "type": CharType.ASSASSIN,
                "hp_bonus": -15.0,
                "speed_bonus": 30.0,
                "dart_bonus": 0,
                "skill_bonus": "dash",
                "skill_desc": "Dash vô hình 1s",
                "lore": "Sát thủ chết chóc, di chuyển trong bóng tối. Khi dash trở nên vô hình.",
                "color": Color(0.16, 0.16, 0.2),
        },
        # === v2.1: NHÂN VẬT ĐẶC BIỆT ===
        {
                "id": 12,
                "name": "Hieu Louis - Classic",
                "title": "Hacker Huyền Thoại",
                "file": "char_hieu_louis_classic",
                "type": CharType.CLASSIC,
                "hp_bonus": 500.0,        # Máu cực nhiều
                "speed_bonus": 50.0,      # Tốc độ rất cao
                "dart_bonus": 100,        # Vô hạn đạn (100 darts max)
                "skill_bonus": "classic", # Skill đặc biệt: Crown
                "skill_desc": "Crown Skill: Ghim 5 đối thủ +50% điểm. Spawn glitch 3s bất tử. Vô hạn đạn, không cooldown bắn.",
                "lore": "Hacker huyền thoại từ deep web. Khi spawn, code glitch tỏa ra 3 giây bất tử. Crown skill ghim 5 đối thủ cùng lúc, +50% điểm. Số darts vô hạn, không bị giới hạn tần suất bắn. Máu cực nhiều, thanh HP dài hơn hẳn. Khi giết 50 mạng, nhận tiểu liên vô hạn 20s. Chỉ mở khóa qua mã quà tặng bí mật.",
                "color": Color(0.0, 1.0, 0.5),  # Hacker green
        },
        # === v2.3: MA TÔN - HARD COUNTER CLASSIC ===
        {
                "id": 13,
                "name": "Ma Tôn",
                "title": "Ma Vương Siêu Cấp",
                "file": "char_ma_ton",
                "type": CharType.MATON,
                "hp_bonus": 1000.0,       # Gấp đôi Classic's 500
                "speed_bonus": 80.0,      # Vượt Classic's 50
                "dart_bonus": 200,        # Gấp đôi Classic's 100
                "skill_bonus": "maton",   # Ma Tôn Quyền - hard counter Classic
                "skill_desc": "Ma Tôn Quyền: Instant-kill bất kỳ Classic character, immune Crown skill, +100% score multiplier, permanent invincibility 5s on spawn.",
                "lore": "Ma Vương Siêu Cấp - thực thể siêu nhiên tối thượng sinh ra để khắc phục Hieu Louis - Classic. Ma Tôn Quyền đấm xuyên mọi lớp bảo vệ, instant-kill bất kỳ Classic character. Miễn nhiễm hoàn toàn với Crown skill. Nhân hệ số điểm x2 (+100%). Khi spawn, tỏa aura bất tử 5 giây - lâu hơn glitch 3s của Classic. Mọi chỉ số đều áp đảo: HP 1000 (gấp đôi Classic), Speed 80, 200 darts. Ma Tôn là答复 cuối cùng cho mọi hacker.",
                "color": Color(0.8, 0.0, 1.0),  # Deep purple, supernatural
        },
]

# Nhân vật đang được chọn
var selected_character_id: int = 0
var unlocked_characters: Array = [0]  # Mặc định mở nhân vật 0

# v2.2: Tracks feature unlocks (e.g. admin_guide) redeemed via gift codes
var unlocked_features: Array = []

signal character_changed(char_id: int)

# v2.2: Mã quà tặng - mỗi mã có "type" và "value"
# type="character": value=char_id (mở khóa nhân vật)
# type="feature":   value=feature_name (mở khóa tính năng đặc biệt, vd: admin_guide)
const GIFT_CODES: Dictionary = {
        "hieulouis99": { "type": "character", "value": 12 },          # Mở khóa Hieu Louis - Classic
        "hieulouisking": { "type": "feature", "value": "admin_guide" }, # Mở khóa Admin Guide
        "maton99": { "type": "character", "value": 13 },               # Mở khóa Ma Tôn (v2.3)
}

# v2.2: Lưu message từ lần redeem gần nhất để UI hiển thị
var _last_redeem_message: String = ""

func _ready():
        _load_unlock_data()

func get_character(id: int) -> Dictionary:
        if id < 0 or id >= CHARACTERS.size():
                return CHARACTERS[0]
        return CHARACTERS[id]

func get_all_characters() -> Array:
        return CHARACTERS

func get_selected() -> Dictionary:
        return get_character(selected_character_id)

func select_character(id: int):
        if id >= 0 and id < CHARACTERS.size():
                selected_character_id = id
                _save_unlock_data()
                character_changed.emit(id)

func is_unlocked(id: int) -> bool:
        return id in unlocked_characters

func unlock_character(id: int):
        if not id in unlocked_characters:
                unlocked_characters.append(id)
                _save_unlock_data()

## v2.2: Mở khóa một feature (admin_guide, ...)
func unlock_feature(feature_name: String):
        if not feature_name in unlocked_features:
                unlocked_features.append(feature_name)
                _save_unlock_data()

## v2.2: Kiểm tra feature đã được mở khóa chưa
func is_feature_unlocked(feature_name: String) -> bool:
        return feature_name in unlocked_features

## v2.2: Nhập mã quà tặng. Trả về true nếu hợp lệ và đã mở khóa.
func redeem_gift_code(code: String) -> bool:
        var normalized = code.to_lower().strip_edges()
        _last_redeem_message = ""
        if GIFT_CODES.has(normalized):
                var entry = GIFT_CODES[normalized]
                var entry_type = entry.get("type", "")
                var entry_value = entry.get("value", null)
                if entry_type == "character" and entry_value != null:
                        var char_id = int(entry_value)
                        if not char_id in unlocked_characters:
                                unlock_character(char_id)
                                var char_data = get_character(char_id)
                                _last_redeem_message = "Mã hợp lệ! Đã mở khóa nhân vật: %s" % char_data["name"]
                        else:
                                var char_data = get_character(char_id)
                                _last_redeem_message = "Mã hợp lệ! Nhân vật %s đã được mở khóa từ trước." % char_data["name"]
                        return true
                elif entry_type == "feature" and entry_value != null:
                        var feature_name = str(entry_value)
                        if not feature_name in unlocked_features:
                                unlock_feature(feature_name)
                                _last_redeem_message = "Mã hợp lệ! Đã mở khóa tính năng: %s" % _feature_display_name(feature_name)
                        else:
                                _last_redeem_message = "Mã hợp lệ! Tính năng %s đã được mở khóa từ trước." % _feature_display_name(feature_name)
                        return true
        return false

## v2.2: Lấy message từ lần redeem gần nhất (cho UI hiển thị)
func get_last_redeem_message() -> String:
        return _last_redeem_message if _last_redeem_message != "" else "Mã hợp lệ!"

## v2.2: Tên hiển thị thân thiện cho feature
func _feature_display_name(feature_name: String) -> String:
        match feature_name:
                "admin_guide": return "Hướng Dẫn Cho Admin"
                _: return feature_name

## v2.1: Kiểm tra character hiện tại có phải là Hieu Louis - Classic không
func is_classic_mode() -> bool:
        var char_data = get_selected()
        return char_data.has("file") and char_data["file"] == "char_hieu_louis_classic"

func get_sprite_path(id: int) -> String:
        var char_data = get_character(id)
        return "res://assets/sprites/characters/%s.png" % char_data["file"]

func get_type_name(type: int) -> String:
        match type:
                CharType.WARRIOR: return "Chiến Binh"
                CharType.MAGE: return "Pháp Sư"
                CharType.BRAWLER: return "Quyền Sư"
                CharType.ASSASSIN: return "Sát Thủ"
                CharType.CLASSIC: return "Hacker"
                CharType.MATON: return "Ma Tôn"
                _: return "Khác"

func get_hp_bonus(id: int) -> float:
        return get_character(id)["hp_bonus"]

func get_speed_bonus(id: int) -> float:
        return get_character(id)["speed_bonus"]

func get_dart_bonus(id: int) -> int:
        return get_character(id)["dart_bonus"]

func get_skill_bonus(id: int) -> String:
        return get_character(id)["skill_bonus"]

func _save_unlock_data():
        var config = ConfigFile.new()
        config.set_value("characters", "selected", selected_character_id)
        config.set_value("characters", "unlocked", unlocked_characters)
        # v2.2: persist feature unlocks (e.g. admin_guide)
        config.set_value("features", "unlocked", unlocked_features)
        config.save("user://character_data.cfg")

func _load_unlock_data():
        var config = ConfigFile.new()
        if config.load("user://character_data.cfg") == OK:
                selected_character_id = config.get_value("characters", "selected", 0)
                unlocked_characters = config.get_value("characters", "unlocked", [0])
                # v2.2: load feature unlocks (migrate cũ: mặc định [])
                unlocked_features = config.get_value("features", "unlocked", [])
        else:
                # Mặc định mở 4 nhân vật đầu
                unlocked_characters = [0, 1, 2, 3]
                unlocked_features = []
                _save_unlock_data()
