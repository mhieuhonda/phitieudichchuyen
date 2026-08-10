extends Node

## ProgressionManager - Hệ thống tiến hóa player (v3.7)
## Singleton autoload. Lưu vào user://progression.cfg
##
## - Player là quái đột biến của đột biến, ko hình dạng rõ
## - Base stats: Magic=1, Physical=1, Agility=1 (tổng = 3, KHÔNG phải 111)
##   → spec nói "Chỉ số gốc của player là 111" (tức 1/1/1 = 111 khi viết liền)
## - 5 level, mỗi level được 2 điểm nâng
## - Class hiện tại = loài đang chọn (mua ở shop tiền bối)
## - Mask = vật phẩm đổi class (không reset stats)
## - HL Coin: tiền tệ trong game để mua skin, thuê người, học skill
## - Uy tín (reputation) với mỗi loài: -100..100
## - Độ thân mật (intimacy) với từng NPC 3 sao: 0..100
## - Thành tựu (achievements): đã đạt / chưa
## - Nội chiến (civil_war): event ngẫu nhiên giảm uy tín tạm thời

signal coins_changed(new_coins: int)
signal level_changed(new_level: int, points_to_spend: int)
signal stats_changed(magic: int, physical: int, agility: int)
signal reputation_changed(species_id: int, new_value: int)
signal intimacy_changed(npc_id: String, new_value: int)
signal achievement_unlocked(achievement_id: String)
signal class_changed(new_species_id: int)
signal team_changed(team_size: int)

const SAVE_PATH: String = "user://progression.cfg"

# === PLAYER PROGRESSION ===
var player_magic: int = 1
var player_physical: int = 1
var player_agility: int = 1
var player_level: int = 1
var points_to_spend: int = 0   # điểm chưa dùng
const MAX_LEVEL: int = 5
const POINTS_PER_LEVEL: int = 2

# === CLASS ===
var current_class_id: int = -1  # -1 = chưa có class (chưa mua)
var owned_classes: Array = []   # các loài đã mua
var owned_masks: int = 0         # số mặt nạ đổi class còn

# === CURRENCY ===
var hl_coins: int = 0

# === REPUTATION ===  (-100..100 cho mỗi loài)
var reputation: Dictionary = {}  # species_id -> int

# === INTIMACY === (0..100 cho mỗi NPC 3 sao)
var intimacy: Dictionary = {}  # "species_id_npc_name" -> int

# === ACHIEVEMENTS ===
var achievements: Dictionary = {}  # achievement_id -> true (unlocked)

# === TEAM (đội tạm thời cho 1 quest) ===
# Mỗi entry: { species_id, stars, name, hire_cost, stats{magic,physical,agility}, skills[] }
var team: Array = []

# === CIVIL WAR (event ngẫu nhiên giảm uy tín) ===
var civil_war_active: bool = false
var civil_war_timer: float = 0.0  # seconds còn lại
var civil_war_species: int = -1   # loài đang nội chiến (hoặc -1 = toàn bộ)

# === QUEST BOARD ===
# Quest đang active (đã nhận)
var active_quests: Array = []  # mỗi entry: { id, name, target, reward_coins, reward_rep, require_class, require_min_team, completed }

# Quest đã hoàn thành (để không lặp lại)
var completed_quests: Array = []

const MAX_TEAM_SIZE: int = 4  # +1 player = 5 thành viên

const ACHIEVEMENTS_DEF = {
        "first_blood": {"name": "Máu Đầu Tiên", "desc": "Tiêu diệt quái đầu tiên", "coins": 50},
        "boss_slayer": {"name": "Sát Thủ Boss", "desc": "Tiêu diệt boss màn 20", "coins": 500},
        "first_recruit": {"name": "Đội Trưởng", "desc": "Chiêu mộ đồng đội đầu tiên", "coins": 30},
        "three_star_team": {"name": "Đội Hình Khủng", "desc": "Có đồng đội 3 sao trong đội", "coins": 100},
        "all_classes": {"name": "Sưu Tầm Class", "desc": "Sở hữu tất cả 6 class khởi đầu", "coins": 300},
        "all_species_mastered": {"name": "Vạn Thú Quyền", "desc": "Học skill từ tất cả 10 thủ lĩnh", "coins": 1000},
        "first_class_change": {"name": "Đổi Thân Phận", "desc": "Đổi class lần đầu bằng mặt nạ", "coins": 80},
        "rep_max": {"name": "Huyền Thoại Uy Tín", "desc": "Đạt uy tín 100 với 1 loài", "coins": 200},
        "intimacy_max": {"name": "Tri Kỷ", "desc": "Đạt độ thân mật 100 với NPC 3 sao", "coins": 250},
        "quest_master": {"name": "Bá Chủ Quest", "desc": "Hoàn thành 10 quest", "coins": 150},
        "survive_civil_war": {"name": "Sống Sót Nội Chiến", "desc": "Trải qua 1 cuộc nội chiến loài", "coins": 120},
        "stage_5_clear": {"name": "Người Mới Vượt Ải", "desc": "Vượt ải 5", "coins": 100},
        "stage_10_clear": {"name": "Chiến Binh Lành Lẽ", "desc": "Vượt ải 10", "coins": 200},
        "stage_15_clear": {"name": "Cao Thủ", "desc": "Vượt ải 15", "coins": 300},
        # v3.8: New achievements
        "kill_streak_5": {"name": "Hạ Gục 5 Liên Tiếp", "desc": "Đạt kill streak 5", "coins": 80},
        "kill_streak_10": {"name": "Bất Tử Chi Thân", "desc": "Đạt kill streak 10", "coins": 200},
        "perfect_stage": {"name": "Hoàn Hảo", "desc": "Hoàn thành ải mà không chết", "coins": 100},
        "speed_runner": {"name": "Tốc Độ Ánh Sáng", "desc": "Hoàn thành ải dưới 60 giây", "coins": 150},
        "all_stages_clear": {"name": "Huyền Thoại Vượt Ải", "desc": "Hoàn thành tất cả 20 ải", "coins": 1000},
}

func _ready():
        _load()
        # Khởi tạo reputation default = 0 cho mọi loài
        for id in SpeciesData.SPECIES.keys():
                if not reputation.has(id):
                        reputation[id] = 0

# === SAVE / LOAD ===

func _save():
        var cfg = ConfigFile.new()
        cfg.set_value("player", "magic", player_magic)
        cfg.set_value("player", "physical", player_physical)
        cfg.set_value("player", "agility", player_agility)
        cfg.set_value("player", "level", player_level)
        cfg.set_value("player", "points_to_spend", points_to_spend)
        cfg.set_value("player", "current_class_id", current_class_id)
        cfg.set_value("player", "owned_classes", owned_classes)
        cfg.set_value("player", "owned_masks", owned_masks)
        cfg.set_value("currency", "hl_coins", hl_coins)
        cfg.set_value("rep", "reputation", reputation)
        cfg.set_value("rep", "intimacy", intimacy)
        cfg.set_value("achievements", "unlocked", achievements)
        cfg.set_value("quests", "completed", completed_quests)
        cfg.save(SAVE_PATH)

func _load():
        var cfg = ConfigFile.new()
        if cfg.load(SAVE_PATH) != OK:
                return
        player_magic = cfg.get_value("player", "magic", 1)
        player_physical = cfg.get_value("player", "physical", 1)
        player_agility = cfg.get_value("player", "agility", 1)
        player_level = cfg.get_value("player", "level", 1)
        points_to_spend = cfg.get_value("player", "points_to_spend", 0)
        current_class_id = cfg.get_value("player", "current_class_id", -1)
        owned_classes = cfg.get_value("player", "owned_classes", [])
        owned_masks = cfg.get_value("player", "owned_masks", 0)
        hl_coins = cfg.get_value("currency", "hl_coins", 0)
        reputation = cfg.get_value("rep", "reputation", {})
        intimacy = cfg.get_value("rep", "intimacy", {})
        achievements = cfg.get_value("achievements", "unlocked", {})
        completed_quests = cfg.get_value("quests", "completed", [])

# === STATS API ===

func get_total_stats() -> Dictionary:
        return {
                "magic": player_magic,
                "physical": player_physical,
                "agility": player_agility,
                "total": player_magic + player_physical + player_agility,
        }

func add_stat(stat_name: String, amount: int = 1) -> bool:
        # stat_name: "magic" / "physical" / "agility"
        if points_to_spend < amount:
                return false
        match stat_name:
                "magic":    player_magic += amount
                "physical": player_physical += amount
                "agility":  player_agility += amount
                _: return false
        points_to_spend -= amount
        stats_changed.emit(player_magic, player_physical, player_agility)
        _save()
        return true

func gain_xp_and_level(_xp: int):
        # v3.7: spec nói "5 level, mỗi level 2 điểm". Cấp theo số ải vượt qua.
        # Mỗi ải vượt = 1 level (và 2 điểm). Max level 5.
        var new_level = clamp(StageManager.max_stage_unlocked, 1, MAX_LEVEL)
        if new_level > player_level:
                var gained = (new_level - player_level) * POINTS_PER_LEVEL
                player_level = new_level
                points_to_spend += gained
                level_changed.emit(player_level, points_to_spend)
                _save()

# === CLASS API ===

func has_class(species_id: int) -> bool:
        return owned_classes.has(species_id)

func buy_class(species_id: int, cost: int) -> bool:
        if hl_coins < cost:
                return false
        if has_class(species_id):
                return false
        hl_coins -= cost
        owned_classes.append(species_id)
        # Nếu chưa có class nào → set luôn làm class hiện tại
        if current_class_id < 0:
                current_class_id = species_id
                class_changed.emit(species_id)
        coins_changed.emit(hl_coins)
        _save()
        # Check achievement "all_classes"
        if owned_classes.size() >= 6:
                unlock_achievement("all_classes")
        return true

func change_class(species_id: int) -> bool:
        if not has_class(species_id):
                return false
        # Cần 1 mặt nạ (trừ khi là class đầu tiên)
        if current_class_id >= 0 and owned_masks <= 0:
                return false
        if current_class_id >= 0:
                owned_masks -= 1
        current_class_id = species_id
        class_changed.emit(species_id)
        unlock_achievement("first_class_change")
        _save()
        return true

func buy_mask(cost: int) -> bool:
        if hl_coins < cost:
                return false
        hl_coins -= cost
        owned_masks += 1
        coins_changed.emit(hl_coins)
        _save()
        return true

# === COINS API ===

## v3.8: add_coins — emit signal 'coins_added' với amount để HUD/UI spawn particle
signal coins_added(amount: int, total: int)

func add_coins(amount: int):
        hl_coins += amount
        coins_changed.emit(hl_coins)
        coins_added.emit(amount, hl_coins)
        _save()

func spend_coins(amount: int) -> bool:
        if hl_coins < amount:
                return false
        hl_coins -= amount
        coins_changed.emit(hl_coins)
        _save()
        return true

# === REPUTATION API ===

func get_reputation(species_id: int) -> int:
        return int(reputation.get(species_id, 0))

func add_reputation(species_id: int, amount: int):
        var cur = get_reputation(species_id)
        var new_val = clamp(cur + amount, -100, 100)
        reputation[species_id] = new_val
        reputation_changed.emit(species_id, new_val)
        if new_val >= 100:
                unlock_achievement("rep_max")
        _save()

# === INTIMACY API === (chỉ NPC 3 sao)

func get_intimacy(npc_id: String) -> int:
        return int(intimacy.get(npc_id, 0))

func add_intimacy(npc_id: String, amount: int):
        var cur = get_intimacy(npc_id)
        var new_val = clamp(cur + amount, 0, 100)
        intimacy[npc_id] = new_val
        intimacy_changed.emit(npc_id, new_val)
        if new_val >= 100:
                unlock_achievement("intimacy_max")
        _save()

# === ACHIEVEMENTS API ===

func unlock_achievement(achievement_id: String):
        if achievements.has(achievement_id):
                return
        achievements[achievement_id] = true
        var def = ACHIEVEMENTS_DEF.get(achievement_id, {})
        if def.has("coins"):
                add_coins(int(def["coins"]))
        achievement_unlocked.emit(achievement_id)
        _save()

func is_achievement_unlocked(achievement_id: String) -> bool:
        return achievements.has(achievement_id)

func get_achievement_progress() -> Dictionary:
        var unlocked = 0
        var total = ACHIEVEMENTS_DEF.size()
        for id in ACHIEVEMENTS_DEF.keys():
                if achievements.has(id):
                        unlocked += 1
        return {"unlocked": unlocked, "total": total}

# === TEAM API ===

func get_team_size() -> int:
        return team.size()

func can_recruit() -> bool:
        return team.size() < MAX_TEAM_SIZE

func add_team_member(member: Dictionary) -> bool:
        if not can_recruit():
                return false
        team.append(member)
        team_changed.emit(team.size())
        if team.size() == 1:
                unlock_achievement("first_recruit")
        for m in team:
                if m.get("stars", 0) >= 3:
                        unlock_achievement("three_star_team")
                        break
        return true

func clear_team():
        team.clear()
        team_changed.emit(0)

func get_team_total_stats() -> Dictionary:
        var m = 0
        var p = 0
        var a = 0
        for member in team:
                var s = member.get("stats", {})
                m += int(s.get("magic", 0))
                p += int(s.get("physical", 0))
                a += int(s.get("agility", 0))
        return {"magic": m, "physical": p, "agility": a, "total": m + p + a}

## Tính bonus % cho player khi có team (chỉ số đồng đội quy đổi ra bonus)
func get_team_bonus_for_player() -> Dictionary:
        # Mỗi điểm chỉ số đồng đội = 1% bonus cho stat tương ứng của player
        var team_stats = get_team_total_stats()
        return {
                "hp_bonus_pct":      team_stats["physical"] * 1.0,
                "damage_bonus_pct":  team_stats["physical"] * 0.5 + team_stats["magic"] * 0.5,
                "speed_bonus_pct":   team_stats["agility"] * 1.0,
                "magic_bonus_pct":   team_stats["magic"] * 1.0,
        }

## Sau khi đánh xong quái, đồng đội lấy chiến lợi phẩm + tiền thuê → mất hút
func dissolve_team_after_quest():
        # v3.9: Sửa comment cho đúng — 5% mỗi thành viên
        # Mỗi thành viên lấy 5% HL Coin hiện có làm "phí thuê + chiến lợi phẩm"
        var fee_per_member = int(hl_coins * 0.05)  # 5% mỗi thành viên
        var total_fee = fee_per_member * team.size()
        if total_fee > 0:
                hl_coins = max(0, hl_coins - total_fee)
                coins_changed.emit(hl_coins)
        clear_team()
        _save()

# === CIVIL WAR ===

## Kích hoạt nội chiến cho 1 loài (random hoặc gọi từ quest event)
func trigger_civil_war(species_id: int = -1, duration: float = 120.0):
        if civil_war_active:
                return
        civil_war_active = true
        civil_war_timer = duration
        civil_war_species = species_id
        if species_id >= 0:
                add_reputation(species_id, -15)
        else:
                # Toàn bộ loài giảm uy tín
                for id in SpeciesData.SPECIES.keys():
                        add_reputation(id, -8)
        unlock_achievement("survive_civil_war")

func update_civil_war(delta: float):
        if not civil_war_active:
                return
        civil_war_timer -= delta
        if civil_war_timer <= 0:
                civil_war_active = false
                civil_war_species = -1
                civil_war_timer = 0.0
                _save()

# === QUEST API ===

func accept_quest(quest: Dictionary) -> bool:
        # v4.0: FIX BUG — yêu cầu class/team giờ là SOFT (khuyên dùng), không chặn nhận quest.
        # Trước v4.0: Player mới (current_class_id = -1, mutant) không nhận được 5/13 quest
        # vì `require_class` chặn cứng. Giờ player có thể nhận bất kỳ quest nào, nhưng UI
        # vẫn hiện cảnh báo "Khuyên dùng class X" để player biết sẽ khó hơn / thiếu bonus.
        if active_quests.size() >= 5:
                return false
        # (Đã bỏ hard check require_class và require_min_team)
        # Cảnh báo soft hiển thị ở tavern.gd::_build_quest_item
        # v3.9: Đảm bảo quest có reward_species key
        if not quest.has("reward_species") and quest.has("reward_rep_species"):
                quest["reward_species"] = quest["reward_rep_species"]
        active_quests.append(quest)
        _save()
        return true

func complete_quest(quest_id: String):
        for i in range(active_quests.size()):
                if active_quests[i].get("id", "") == quest_id:
                        var q = active_quests[i]
                        active_quests.remove_at(i)
                        if not completed_quests.has(quest_id):
                                completed_quests.append(quest_id)
                        # Reward
                        if q.has("reward_coins"):
                                add_coins(int(q["reward_coins"]))
                        if q.has("reward_rep") and q.has("reward_species"):
                                add_reputation(int(q["reward_species"]), int(q["reward_rep"]))
                        if q.has("reward_intimacy") and q.has("reward_npc"):
                                add_intimacy(String(q["reward_npc"]), int(q["reward_intimacy"]))
                        # Đồng đội giải tán sau quest
                        dissolve_team_after_quest()
                        # Achievement quest_master
                        if completed_quests.size() >= 10:
                                unlock_achievement("quest_master")
                        _save()
                        return true
        return false

# v3.9: Helper — lấy quest active theo id (dùng cho main.gd)
func get_active_quest_by_id(quest_id: String) -> Dictionary:
        for q in active_quests:
                if q.get("id", "") == quest_id:
                        return q
        return {}

# v3.9: Helper — đếm quest đã hoàn thành
func get_completed_quest_count() -> int:
        return completed_quests.size()

# v3.9: Gate civil war timer — chỉ tick khi đang ở world scene, không tick khi trong combat
# (giảm side-effect không mong muốn khi đang đánh ải)
func _is_world_scene() -> bool:
        var tree = get_tree()
        if not tree or not tree.current_scene:
                return false
        var fname = tree.current_scene.scene_file_path
        return fname.find("world_map") >= 0 or fname.find("tavern") >= 0 \
                or fname.find("quest_log") >= 0 or fname.find("skill_master") >= 0 \
                or fname.find("predecessor_shop") >= 0 or fname.find("menu") >= 0

func _process(delta):
        if _is_world_scene():
                update_civil_war(delta)
