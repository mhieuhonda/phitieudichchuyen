extends Node

## WorldManager - Hệ thống thế giới 4 vùng (v3.7)
## Singleton autoload. Quản lý vùng, quán rượu, vị trí thủ lĩnh, tiền bối.
##
## 4 vùng chính:
##   1. Rừng Thông (Pine Forest)     — thủ lĩnh Cáo ở chòi canh, Hươu rải rác
##   2. Núi Băng (Ice Mountain)      — trường phép thuật, thủ lĩnh Thỏ làm hiệu trưởng,
##                                      Ngựa ở biên giới
##   3. Vương Quốc RuY Băng (Ribbon) — lâu đài thủ lĩnh Mèo, đấu trường Sư Tử
##   4. Đế Quốc Kẹo (Candy Empire)   — lâu đài thủ lĩnh Gấu, tầng hầm Sói,
##                                      Chó trốn chui, Ngựa biên giới gần đây
##
## Mỗi vùng có 1 quán rượu (4 quán tổng cộng). Player gặp NPC, nhận quest, chiêu mộ.
##
## Tiền bối (Predecessor): NPC đặc biệt bán class cho player (mutant). Xuất hiện
## ngẫu nhiên ở 1 trong 4 vùng, vị trí thay đổi mỗi lần.

signal predecessor_moved(region_id: String)
signal day_advanced(day: int)

const REGIONS = {
        "pine_forest": {
                "id": "pine_forest",
                "name": "Rừng Thông",
                "name_en": "Pine Forest",
                "color": Color(0.20, 0.45, 0.25),
                "emoji": "🌲",
                "desc": "Rừng thông rậm rạp, có chòi canh của Cáo Lão. Hươu thỉnh thoảng xuất hiện.",
                "has_tavern": true,
                "leaders": ["fox", "deer"],
        },
        "ice_mountain": {
                "id": "ice_mountain",
                "name": "Núi Băng",
                "name_en": "Ice Mountain",
                "color": Color(0.55, 0.78, 0.95),
                "emoji": "🏔️",
                "desc": "Núi tuyết trắng xóa, có trường phép thuật do Thỏ Trắng làm hiệu trưởng.",
                "has_tavern": true,
                "leaders": ["rabbit", "horse"],
        },
        "ribbon_kingdom": {
                "id": "ribbon_kingdom",
                "name": "Vương Quốc RuY Băng",
                "name_en": "Ribbon Kingdom",
                "color": Color(0.85, 0.55, 0.75),
                "emoji": "🎀",
                "desc": "Vương quốc ruy băng với lâu đài của Nữ Hoàng Mèo và đấu trường Sư Tử.",
                "has_tavern": true,
                "leaders": ["cat", "lion"],
        },
        "candy_empire": {
                "id": "candy_empire",
                "name": "Đế Quốc Kẹo",
                "name_en": "Candy Empire",
                "color": Color(0.95, 0.55, 0.65),
                "emoji": "🍭",
                "desc": "Đế quốc kẹo ngọt. Lâu đài Vua Gấu, tầng hầm Sói, và Chó trốn chui đâu đó.",
                "has_tavern": true,
                "leaders": ["bear", "wolf", "dog"],
        },
}

## Vị trí chi tiết của từng thủ lĩnh (theo spec user)
var LEADER_LOCATIONS = {
        "bear":   {"name": "Lâu Đài Đế Quốc Kẹo",    "region": "candy_empire",   "species": SpeciesData.SpeciesId.BEAR},
        "wolf":   {"name": "Tầng Hầm Lâu Đài Kẹo",   "region": "candy_empire",   "species": SpeciesData.SpeciesId.WOLF, "hidden": true},
        "dog":    {"name": "Chỗ Trốn Bí Ẩn",          "region": "candy_empire",   "species": SpeciesData.SpeciesId.DOG,  "hidden": true},
        "cat":    {"name": "Lâu Đài RuY Băng",        "region": "ribbon_kingdom", "species": SpeciesData.SpeciesId.CAT},
        "lion":   {"name": "Đấu Trường RuY Băng",     "region": "ribbon_kingdom", "species": SpeciesData.SpeciesId.LION, "hidden": true},
        "rabbit": {"name": "Trường Phép Thuật Núi Băng", "region": "ice_mountain", "species": SpeciesData.SpeciesId.RABBIT},
        "horse":  {"name": "Biên Giới Núi Băng",      "region": "ice_mountain",   "species": SpeciesData.SpeciesId.HORSE},
        "fox":    {"name": "Chòi Canh Rừng Thông",    "region": "pine_forest",    "species": SpeciesData.SpeciesId.FOX},
        "deer":   {"name": "Rừng Thông (Rải Rác)",    "region": "pine_forest",    "species": SpeciesData.SpeciesId.DEER},
        "mouse":  {"name": "Đi Loanh Quanh Khắp Map", "region": "wandering",      "species": SpeciesData.SpeciesId.MOUSE},
}

# === STATE ===
var current_region: String = "pine_forest"
var predecessor_region: String = "pine_forest"  # vùng có tiền bối hiện tại
var predecessor_visit_count: int = 0
var day: int = 1
var day_timer: float = 0.0
const DAY_LENGTH: float = 300.0  # 5 phút = 1 ngày trong game

# Quest template pool — mỗi vùng có 1 pool quest khác nhau
var QUEST_POOL = {
        "pine_forest": [
                {"id": "pf_q1", "name": "Quét Sạch Quái Rừng", "target": "kill 5", "reward_coins": 50, "reward_rep_species": SpeciesData.SpeciesId.FOX, "reward_rep": 5, "require_min_team": 1},
                {"id": "pf_q2", "name": "Hồ Gươm Đẫm Máu", "target": "boss mini", "reward_coins": 120, "reward_rep_species": SpeciesData.SpeciesId.DEER, "reward_rep": 8, "require_class": SpeciesData.SpeciesId.FOX},
                {"id": "pf_q3", "name": "Đêm Trăng Đầy", "target": "kill 10", "reward_coins": 200, "reward_rep_species": SpeciesData.SpeciesId.FOX, "reward_rep": 15, "require_min_team": 3},
        ],
        "ice_mountain": [
                {"id": "im_q1", "name": "Phép Thuật Băng Giá", "target": "kill 5", "reward_coins": 60, "reward_rep_species": SpeciesData.SpeciesId.RABBIT, "reward_rep": 5, "require_class": SpeciesData.SpeciesId.RABBIT},
                {"id": "im_q2", "name": "Phá Hủy Băng Tuyết", "target": "boss mini", "reward_coins": 150, "reward_rep_species": SpeciesData.SpeciesId.HORSE, "reward_rep": 10, "require_min_team": 2},
                {"id": "im_q3", "name": "Trường Phép Nguy Hiểm", "target": "kill 12", "reward_coins": 250, "reward_rep_species": SpeciesData.SpeciesId.RABBIT, "reward_rep": 20, "require_min_team": 3},
        ],
        "ribbon_kingdom": [
                {"id": "rk_q1", "name": "Anh Vệ Sĩ Hoàng Gia", "target": "kill 6", "reward_coins": 70, "reward_rep_species": SpeciesData.SpeciesId.CAT, "reward_rep": 6, "require_class": SpeciesData.SpeciesId.CAT},
                {"id": "rk_q2", "name": "Đấu Trường Tử Thần", "target": "boss mini", "reward_coins": 180, "reward_rep_species": SpeciesData.SpeciesId.LION, "reward_rep": 12, "require_min_team": 3},
                {"id": "rk_q3", "name": "Tiệc Trà Đẫm Máu", "target": "kill 15", "reward_coins": 280, "reward_rep_species": SpeciesData.SpeciesId.CAT, "reward_rep": 20, "require_min_team": 4},
        ],
        "candy_empire": [
                {"id": "ce_q1", "name": "Vua Kẹo Đang Ngủ", "target": "kill 6", "reward_coins": 70, "reward_rep_species": SpeciesData.SpeciesId.BEAR, "reward_rep": 6, "require_class": SpeciesData.SpeciesId.BEAR},
                {"id": "ce_q2", "name": "Tầng Hầm Bí Mật", "target": "boss mini", "reward_coins": 200, "reward_rep_species": SpeciesData.SpeciesId.WOLF, "reward_rep": 12, "require_class": SpeciesData.SpeciesId.BEAR, "require_min_team": 2},
                {"id": "ce_q3", "name": "Chó Săn Đánh Rơi", "target": "find dog", "reward_coins": 300, "reward_rep_species": SpeciesData.SpeciesId.DOG, "reward_rep": 25, "require_min_team": 3},
                {"id": "ce_q4", "name": "Săn Lùng Chó Lạc", "target": "kill 18", "reward_coins": 350, "reward_rep_species": SpeciesData.SpeciesId.BEAR, "reward_rep": 25, "require_min_team": 4},
        ],
}

# NPC pool cho quán rượu — randomNPC theo loài + cấp sao + giá
# spawn mỗi khi vào tavern. Mỗi loài có 1 pool 3sao cố định (số lượng có hạn)
var RECRUIT_NAMES_BY_SPECIES = {
        SpeciesData.SpeciesId.RABBIT: ["Thỏ Trắng", "Thỏ Nâu", "Thỏ Xám", "Thỏ Vàng"],
        SpeciesData.SpeciesId.MOUSE:  ["Chuột Lữ", "Chuột Đen", "Chuột Đỏ", "Chuột Bạc"],
        SpeciesData.SpeciesId.FOX:    ["Cáo Lão", "Cáo Đỏ", "Cáo Bạc", "Cáo Huyết"],
        SpeciesData.SpeciesId.CAT:    ["Mèo Hoàng", "Mèo Mun", "Mèo Vàng", "Mèo Tâm"],
        SpeciesData.SpeciesId.BEAR:   ["Gấu Nâu", "Gấu Trắng", "Gấu Đen", "Gấu Vua"],
        SpeciesData.SpeciesId.HORSE:  ["Ngựa Tinh", "Ngựa Vương", "Ngựa Chiến", "Ngựa Bạch"],
        SpeciesData.SpeciesId.DEER:   ["Hươu Cổ", "Hươu Nai", "Hươu Vàng", "Hươu Trắng"],
        SpeciesData.SpeciesId.LION:   ["Sư Tử Vương", "Sư Tử Bạo", "Sư Tử Hoàng", "Sư Tử Chiến"],
        SpeciesData.SpeciesId.WOLF:   ["Sói Đen", "Sói Bạc", "Sói Trăng", "Sói Máu"],
        SpeciesData.SpeciesId.DOG:    ["Chó Săn", "Chó Lạc", "Chó Trung", "Chó Bí Ẩn"],
}

# 3sao NPC cố định (số lượng có hạn) — khi đã thuê rồi thì ko còn
# Format: "species_id:name" → true nếu còn available
var three_star_available: Dictionary = {}

func _ready():
        # Khởi tạo pool 3sao: mỗi loài có 1 con 3sao đặc biệt
        for id in SpeciesData.SPECIES.keys():
                var key = "%d:%s" % [id, RECRUIT_NAMES_BY_SPECIES[id][0]]
                three_star_available[key] = true
        # Random vị trí tiền bối ban đầu
        _random_move_predecessor()

func get_region(id: String) -> Dictionary:
        return REGIONS.get(id, REGIONS["pine_forest"])

func get_all_regions() -> Array:
        return REGIONS.values()

func travel_to(region_id: String):
        if REGIONS.has(region_id):
                current_region = region_id

## Lấy danh sách quest có thể nhận ở vùng hiện tại
func get_available_quests() -> Array:
        var pool = QUEST_POOL.get(current_region, [])
        var out: Array = []
        for q in pool:
                if not ProgressionManager.completed_quests.has(q["id"]):
                        # Convert reward_rep_species → reward_species cho ProgressionManager.accept_quest
                        var q_copy = q.duplicate()
                        q_copy["reward_species"] = q.get("reward_rep_species", -1)
                        out.append(q_copy)
        return out

## Sinh NPC ngẫu nhiên ở quán rượu (5-8 NPC mỗi lần vào)
func generate_tavern_npcs() -> Array:
        var out: Array = []
        # Lấy loài phù hợp với vùng (ưu tiên loài chính ở vùng đó)
        var region = get_region(current_region)
        var region_species: Array = []
        for leader_key in region.get("leaders", []):
                if LEADER_LOCATIONS.has(leader_key):
                        region_species.append(LEADER_LOCATIONS[leader_key]["species"])
        # Thêm 6 loài chính có xác suất thấp
        for sid in SpeciesData.get_main_species_ids():
                if not region_species.has(sid):
                        if randf() < 0.4:
                                region_species.append(sid)
        # Sinh 5-8 NPC
        var count = randi_range(5, 8)
        for i in range(count):
                var sid = region_species[randi() % region_species.size()]
                # Random star rating: 60% 1sao, 30% 2sao, 10% 3sao (chỉ nếu còn available)
                var r = randf()
                var stars = 1
                if r < 0.10:
                        stars = 3
                elif r < 0.40:
                        stars = 2
                # Check 3sao còn available
                if stars == 3:
                        var key = "%d:%s" % [sid, RECRUIT_NAMES_BY_SPECIES[sid][0]]
                        if not three_star_available.get(key, false):
                                stars = 2  # downgrade nếu hết 3sao
                var name_idx = (stars - 1) % RECRUIT_NAMES_BY_SPECIES[sid].size()
                var npc_name = RECRUIT_NAMES_BY_SPECIES[sid][name_idx]
                if stars == 3:
                        npc_name = RECRUIT_NAMES_BY_SPECIES[sid][0]  # tên đặc biệt
                var stats = SpeciesData.get_recruit_stats(sid, stars)
                var skills = SpeciesData.get_recruit_skill_names(sid, stars)
                # Giá thuê: 1sao = 20, 2sao = 60, 3sao = 200
                var hire_cost = {1: 20, 2: 60, 3: 200}[stars]
                # Tỉ lệ chiêu mộ thành công dựa trên uy tín
                var rep = ProgressionManager.get_reputation(sid)
                var recruit_chance = clamp(0.3 + rep / 200.0, 0.1, 0.95)
                out.append({
                        "species_id": sid,
                        "name": npc_name,
                        "stars": stars,
                        "stats": stats,
                        "skills": skills,
                        "hire_cost": hire_cost,
                        "recruit_chance": recruit_chance,
                        "is_three_star": stars == 3,
                        "npc_id": "%d:%s" % [sid, npc_name] if stars == 3 else "",
                })
        return out

## Thử chiêu mộ 1 NPC → trả về kết quả
func try_recruit(npc: Dictionary) -> Dictionary:
        # Check tiền
        if ProgressionManager.hl_coins < npc["hire_cost"]:
                return {"success": false, "reason": "Không đủ HL Coin"}
        # Check đội đầy
        if not ProgressionManager.can_recruit():
                return {"success": false, "reason": "Đội đã đủ 5 thành viên"}
        # Check tỉ lệ thành công
        if randf() > npc["recruit_chance"]:
                # Thất bại → giảm uy tín nhẹ
                ProgressionManager.add_reputation(npc["species_id"], -2)
                return {"success": false, "reason": "Từ chối (uy tín thấp)"}
        # Thành công → trừ tiền, thêm vào đội
        ProgressionManager.spend_coins(npc["hire_cost"])
        ProgressionManager.add_reputation(npc["species_id"], 5)
        # 3sao: đánh dấu đã thuê
        if npc.get("is_three_star", false) and npc.get("npc_id", "") != "":
                three_star_available[npc["npc_id"]] = false
                # Tăng intimacy cho NPC 3sao này
                ProgressionManager.add_intimacy(npc["npc_id"], 5)
        var member = {
                "species_id": npc["species_id"],
                "name": npc["name"],
                "stars": npc["stars"],
                "hire_cost": npc["hire_cost"],
                "stats": npc["stats"],
                "skills": npc["skills"],
                "npc_id": npc.get("npc_id", ""),
        }
        ProgressionManager.add_team_member(member)
        return {"success": true, "member": member}

## Lấy danh sách thủ lĩnh có thể gặp ở vùng hiện tại
func get_leaders_in_region() -> Array:
        var out: Array = []
        for leader_key in LEADER_LOCATIONS.keys():
                var loc = LEADER_LOCATIONS[leader_key]
                if loc["region"] == current_region:
                        # Hidden leaders (sói, chó, sư tử) chỉ gặp nếu uy tín đủ cao hoặc ngẫu nhiên
                        if loc.get("hidden", false):
                                # 30% cơ hội gặp
                                if randf() < 0.30:
                                        out.append({"key": leader_key, "data": loc, "hidden": true})
                        else:
                                out.append({"key": leader_key, "data": loc, "hidden": false})
        # Chuột luôn có 25% cơ hội gặp ở mọi vùng
        if randf() < 0.25:
                out.append({"key": "mouse", "data": LEADER_LOCATIONS["mouse"], "hidden": false})
        return out

## Tiền bối: random vùng hiện tại
func _random_move_predecessor():
        var regions = REGIONS.keys()
        predecessor_region = regions[randi() % regions.size()]
        predecessor_moved.emit(predecessor_region)

## Tiền bối di chuyển sau mỗi lần player thăm
func visit_predecessor() -> bool:
        if predecessor_region != current_region:
                return false
        predecessor_visit_count += 1
        # Sau mỗi 2 lần thăm, tiền bối di chuyển vùng khác
        if predecessor_visit_count >= 2:
                predecessor_visit_count = 0
                _random_move_predecessor()
        return true

func is_predecessor_here() -> bool:
        return predecessor_region == current_region

## Học skill từ thủ lĩnh — phí 100 HL Coin
func learn_skill_from_leader(leader_key: String) -> Dictionary:
        if not LEADER_LOCATIONS.has(leader_key):
                return {"success": false, "reason": "Không tìm thấy thủ lĩnh"}
        var loc = LEADER_LOCATIONS[leader_key]
        var sid = loc["species"]
        # Check class — chỉ học được nếu player đang là class đó (theo spec "thủ lĩnh chỉ dạy cho duy nhất player")
        if ProgressionManager.current_class_id != sid:
                return {"success": false, "reason": "Phải cùng class mới học được"}
        # Check phí
        var cost = 100
        if ProgressionManager.hl_coins < cost:
                return {"success": false, "reason": "Cần %d HL Coin" % cost}
        ProgressionManager.spend_coins(cost)
        ProgressionManager.add_reputation(sid, 10)
        # Check achievement "all_species_mastered" (10 thủ lĩnh)
        var learned_key = "learned_skill_%s" % leader_key
        if not ProgressionManager.achievements.has(learned_key):
                ProgressionManager.achievements[learned_key] = true
                var learned_count = 0
                for k in ProgressionManager.achievements.keys():
                        if k.begins_with("learned_skill_"):
                                learned_count += 1
                if learned_count >= 10:
                        ProgressionManager.unlock_achievement("all_species_mastered")
                ProgressionManager._save()
        return {"success": true, "skill": SpeciesData.get_species(sid)["leader_skill"]}

func _process(delta):
        day_timer += delta
        if day_timer >= DAY_LENGTH:
                day_timer = 0.0
                day += 1
                day_advanced.emit(day)
                # Random nội chiến (5% mỗi ngày)
                if randf() < 0.05:
                        var species_ids = SpeciesData.SPECIES.keys()
                        ProgressionManager.trigger_civil_war(species_ids[randi() % species_ids.size()], 120.0)
