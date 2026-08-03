extends Node

## CharacterData - Dữ liệu 12 nhân vật (v1.2)
## Mỗi nhân vật có: tên, chỉ số, kỹ năng, sprite, màu sắc
## Singleton autoload (đăng ký trong project.godot, không dùng class_name
## vì Godot 4.7 cấm class_name trùng tên autoload singleton)

enum CharType { WARRIOR, MAGE, BRAWLER, ASSASSIN }

# 12 nhân vật
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
]

# Nhân vật đang được chọn
var selected_character_id: int = 0
var unlocked_characters: Array = [0]  # Mặc định mở nhân vật 0

signal character_changed(char_id: int)

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

func get_sprite_path(id: int) -> String:
        var char_data = get_character(id)
        return "res://assets/sprites/characters/%s.png" % char_data["file"]

func get_type_name(type: int) -> String:
        match type:
                CharType.WARRIOR: return "Chiến Binh"
                CharType.MAGE: return "Pháp Sư"
                CharType.BRAWLER: return "Quyền Sư"
                CharType.ASSASSIN: return "Sát Thủ"
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
        config.save("user://character_data.cfg")

func _load_unlock_data():
        var config = ConfigFile.new()
        if config.load("user://character_data.cfg") == OK:
                selected_character_id = config.get_value("characters", "selected", 0)
                unlocked_characters = config.get_value("characters", "unlocked", [0])
        else:
                # Mặc định mở 4 nhân vật đầu
                unlocked_characters = [0, 1, 2, 3]
                _save_unlock_data()
