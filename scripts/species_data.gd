extends Node

## SpeciesData - Dữ liệu 10 loài động vật (v3.7)
## Singleton autoload. Mỗi loài có 3 chỉ số gốc (Magic / Physical / Agility),
## tổng = 6 (theo spec user). Player chọn 1 loài làm class khởi đầu.
##
## Bảng chỉ số gốc (theo spec):
##   Loài     Magic  Physical  Agility
##   Thỏ     :  3      0         3
##   Chuột   :  3      1         2
##   Cáo     :  0      3         3
##   Mèo     :  1      2         3
##   Gấu     :  1      3         2
##   Ngựa    :  2      1         3
##   Hươu    :  2      3         1
##   Sư tử   :  3      3         0
##   Sói     :  2      2         2
##   Chó     :  3      2         1
##
## 6 loài chính (đông dân nhất, là class khởi đầu cho player):
##   Gấu, Mèo, Ngựa, Thỏ, Chuột, Cáo
##
## 4 loài phụ (số lượng ít / trốn chui / quân bóng tối):
##   Hươu (rừng thông), Sư tử (đấu trường phe mèo),
##   Sói (tầng hầm đế quốc kẹo — quân bí mật đế quốc),
##   Chó (trốn chui trong đế quốc kẹo)

enum SpeciesId {
	RABBIT,   # Thỏ
	MOUSE,    # Chuột
	FOX,      # Cáo
	CAT,      # Mèo
	BEAR,     # Gấu
	HORSE,    # Ngựa
	DEER,     # Hươu
	LION,     # Sư tử
	WOLF,     # Sói
	DOG,      # Chó
}

const SPECIES = {
	SpeciesId.RABBIT: {
		"id": SpeciesId.RABBIT,
		"name": "Thỏ",
		"name_en": "Rabbit",
		"magic": 3, "physical": 0, "agility": 3,
		"main": true,  # 6 loài chính
		"color": Color(0.95, 0.95, 0.95),
		"emoji": "🐰",
		"desc": "Hiền lành, nhanh nhẹn. Thủ lĩnh làm hiệu trưởng trường phép thuật ở núi băng.",
		"leader_pos": "ice_mountain",  # Trường phép thuật núi tuyết
		"leader_name": "Hiệu Trưởng Thỏ Trắng",
		"leader_skill": "Vụt Tai Phép Thuật — dash 2 lần liên tiếp + tạo ảo ảnh",
	},
	SpeciesId.MOUSE: {
		"id": SpeciesId.MOUSE,
		"name": "Chuột",
		"name_en": "Mouse",
		"magic": 3, "physical": 1, "agility": 2,
		"main": true,
		"color": Color(0.55, 0.45, 0.35),
		"emoji": "🐭",
		"desc": "Nhỏ bé nhưng thông minh. Thủ lĩnh đi loanh quanh khắp map, không có chỗ ở cố định.",
		"leader_pos": "wandering",  # Đi loanh quanh khắp map
		"leader_name": "Vua Chuột Lữ Khách",
		"leader_skill": "Lủi Trốn — dịch chuyển ngắn + bất tử 1s",
	},
	SpeciesId.FOX: {
		"id": SpeciesId.FOX,
		"name": "Cáo",
		"name_en": "Fox",
		"magic": 0, "physical": 3, "agility": 3,
		"main": true,
		"color": Color(0.95, 0.55, 0.15),
		"emoji": "🦊",
		"desc": "Lanh lợi, xảo quyệt. Thủ lĩnh ở chòi canh trong rừng thông.",
		"leader_pos": "pine_forest",
		"leader_name": "Cáo Lão Chòi Canh",
		"leader_skill": "Ảo Cáo — tạo 3 ảo ảnh đánh lạc hướng đối thủ 2s",
	},
	SpeciesId.CAT: {
		"id": SpeciesId.CAT,
		"name": "Mèo",
		"name_en": "Cat",
		"magic": 1, "physical": 2, "agility": 3,
		"main": true,
		"color": Color(0.55, 0.45, 0.65),
		"emoji": "🐱",
		"desc": "Linh hoạt, hoàng gia. Thủ lĩnh ở lâu đài vương quốc ruy băng.",
		"leader_pos": "ribbon_kingdom",
		"leader_name": "Nữ Hoàng Mèo Anh",
		"leader_skill": "Cửu Mệnh — hồi 80% HP khi sắp chết (1 lần/ải)",
	},
	SpeciesId.BEAR: {
		"id": SpeciesId.BEAR,
		"name": "Gấu",
		"name_en": "Bear",
		"magic": 1, "physical": 3, "agility": 2,
		"main": true,
		"color": Color(0.55, 0.32, 0.15),
		"emoji": "🐻",
		"desc": "Mạnh mẽ, vững chãi. Thủ lĩnh ở lâu đài đế quốc kẹo.",
		"leader_pos": "candy_empire",
		"leader_name": "Vua Gấu Kẹo Mạch Nha",
		"leader_skill": "Gấu Trầm Mộc — bất tử 3s + phản damage 50%",
	},
	SpeciesId.HORSE: {
		"id": SpeciesId.HORSE,
		"name": "Ngựa",
		"name_en": "Horse",
		"magic": 2, "physical": 1, "agility": 3,
		"main": true,
		"color": Color(0.65, 0.45, 0.25),
		"emoji": "🐴",
		"desc": "Nhanh nhẹn, trung thành. Thủ lĩnh ở biên giới núi băng.",
		"leader_pos": "ice_border",  # biên giới núi băng
		"leader_name": "Tướng Ngựa Biên Cương",
		"leader_skill": "Kỵ Sĩ Xung Kích — dash xuyên tường + gây knockback",
	},
	SpeciesId.DEER: {
		"id": SpeciesId.DEER,
		"name": "Hươu",
		"name_en": "Deer",
		"magic": 2, "physical": 3, "agility": 1,
		"main": false,  # loài phụ
		"color": Color(0.75, 0.55, 0.30),
		"emoji": "🦌",
		"desc": "Loài phụ, sống rải rác trong rừng thông. Tìm đại ở đâu cũng thấy.",
		"leader_pos": "pine_forest",
		"leader_name": "Hươu Cổ Trận Địa",
		"leader_skill": "Hươu Vương — tăng 30% tốc cho toàn đội 5s",
	},
	SpeciesId.LION: {
		"id": SpeciesId.LION,
		"name": "Sư Tử",
		"name_en": "Lion",
		"magic": 3, "physical": 3, "agility": 0,
		"main": false,
		"color": Color(0.92, 0.75, 0.18),
		"emoji": "🦁",
		"desc": "Quân bí mật phe mèo. Ở đấu trường vương quốc ruy băng.",
		"leader_pos": "ribbon_arena",  # đấu trường vương quốc ruy băng
		"leader_name": "Sư Tử Đấu Trường",
		"leader_skill": "Sư Hổ Giận — sát thương x2 + không bị slow 4s",
	},
	SpeciesId.WOLF: {
		"id": SpeciesId.WOLF,
		"name": "Sói",
		"name_en": "Wolf",
		"magic": 2, "physical": 2, "agility": 2,
		"main": false,
		"color": Color(0.42, 0.42, 0.50),
		"emoji": "🐺",
		"desc": "Quân bí mật đế quốc kẹo. Ở tầng hầm lâu đài đế quốc.",
		"leader_pos": "candy_basement",  # tầng hầm lâu đài đế quốc
		"leader_name": "Sói Tầng Hầm",
		"leader_skill": "Sói Đơn Độc — dash 3 lần + mỗi dash gây damage",
	},
	SpeciesId.DOG: {
		"id": SpeciesId.DOG,
		"name": "Chó",
		"name_en": "Dog",
		"magic": 3, "physical": 2, "agility": 1,
		"main": false,
		"color": Color(0.72, 0.50, 0.25),
		"emoji": "🐕",
		"desc": "Trốn chui lủi trong đế quốc kẹo. Ít ai gặp được.",
		"leader_pos": "candy_hideout",  # chỗ trốn trong đế quốc
		"leader_name": "Chó Lạc Đàn Bí Ẩn",
		"leader_skill": "Khứu Giác Bí Ẩn — nhìn thấy quái qua tường + crit 100% 3s",
	},
}

## Lấy data loài
func get_species(id: int) -> Dictionary:
	if SPECIES.has(id):
		return SPECIES[id]
	return SPECIES[SpeciesId.RABBIT]

## Danh sách 6 loài chính (class khởi đầu)
func get_main_species_ids() -> Array:
	var out: Array = []
	for id in SPECIES.keys():
		if SPECIES[id].get("main", false):
			out.append(id)
	out.sort()
	return out

## Danh sách 4 loài phụ
func get_minor_species_ids() -> Array:
	var out: Array = []
	for id in SPECIES.keys():
		if not SPECIES[id].get("main", false):
			out.append(id)
	out.sort()
	return out

## Tên hiển thị
func get_species_name(id: int) -> String:
	return get_species(id)["name"]

## Tổng chỉ số gốc của loài (luôn = 6 theo spec)
func get_base_total(id: int) -> int:
	var s = get_species(id)
	return int(s["magic"]) + int(s["physical"]) + int(s["agility"])

## Tính bonus chỉ số cho đồng đội theo cấp sao (1/2/3 sao)
## - 1 sao: tổng = 8 (gốc 6 + 2)  → 1 skill cơ bản
## - 2 sao: tổng = 10 (gốc 6 + 4)  → 2 skill cơ bản
## - 3 sao: tổng = 12 (gốc 6 + 6)  → 2 skill cơ bản + 1 ultimate
func get_recruit_stats(species_id: int, stars: int) -> Dictionary:
	var base = get_species(species_id)
	# Phân bổ điểm tăng theo tỉ lệ gốc (loài nào giỏi chỉ số đó thì được thêm nhiều vào)
	var extra_pool = {1: 2, 2: 4, 3: 6}.get(stars, 2)
	var total_base = get_base_total(species_id)
	if total_base <= 0:
		total_base = 6
	var extra_magic = int(round(float(base["magic"]) / total_base * extra_pool))
	var extra_phys  = int(round(float(base["physical"]) / total_base * extra_pool))
	var extra_agi   = extra_pool - extra_magic - extra_phys
	return {
		"magic": int(base["magic"]) + extra_magic,
		"physical": int(base["physical"]) + extra_phys,
		"agility": int(base["agility"]) + extra_agi,
		"stars": stars,
		"skill_count": {1: 1, 2: 2, 3: 3}.get(stars, 1),  # 3sao có ultimate
		"has_ultimate": stars >= 3,
	}

## Tên skill theo cấp sao (cho UI hiển thị)
func get_recruit_skill_names(species_id: int, stars: int) -> Array:
	var base_skills = {
		SpeciesId.RABBIT:  ["Vụt Tai Phép", "Nhanh Như Chớp", "Tia Sét Thỏ"],
		SpeciesId.MOUSE:   ["Lủi Trốn", "Cắn Nhỏ", "Vua Chuột Hầm"],
		SpeciesId.FOX:     ["Ảo Cáo", "Lừa Cáo", "Cửu Vỹ Hồ"],
		SpeciesId.CAT:     ["Mèo Lười", "Cửu Mệnh", "Mẹo Mèo Hoàng"],
		SpeciesId.BEAR:    ["Ôm Gấu", "Gấu Trầm Mộc", "Vua Gấu Bắc"],
		SpeciesId.HORSE:   ["Phi Nhanh", "Kỵ Sĩ Xung Kích", "Mã Vương Cứu Viện"],
		SpeciesId.DEER:    ["Hươu Vương", "Góc Nhanh", "Cổ Trận Linh Hồn"],
		SpeciesId.LION:    ["Sư Hổ Giận", "Bạo Chúa", "Vạn Thú Chi Vương"],
		SpeciesId.WOLF:    ["Sói Đơn Độc", "Hào Sói", "Trăng Máu"],
		SpeciesId.DOG:     ["Khứu Giác", "Trung Thành", "Thần Hộ Mệnh"],
	}.get(species_id, ["?", "?", "?"])
	var out: Array = []
	for i in range({1: 1, 2: 2, 3: 3}.get(stars, 1)):
		if i < base_skills.size():
			out.append(base_skills[i])
	return out
