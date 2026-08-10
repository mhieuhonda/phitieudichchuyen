extends Control

## QuestLog - Sổ tay: Quest/Team/Thành tựu/Stats (v3.7)
## Player xem tất cả tiến độ meta-game ở đây.

@onready var tab_buttons: HBoxContainer = $TopBar/TabButtons
@onready var stats_tab: Button = $TopBar/TabButtons/StatsTab
@onready var quest_tab: Button = $TopBar/TabButtons/QuestTab
@onready var team_tab: Button = $TopBar/TabButtons/TeamTab
@onready var achievement_tab: Button = $TopBar/TabButtons/AchievementTab
@onready var stats_panel: VBoxContainer = $Center/VBox/StatsPanel
@onready var quest_panel: VBoxContainer = $Center/VBox/QuestPanel
@onready var team_panel: VBoxContainer = $Center/VBox/TeamPanel
@onready var achievement_panel: VBoxContainer = $Center/VBox/AchievementPanel
@onready var stats_list: VBoxContainer = $Center/VBox/StatsPanel/ScrollContainer/StatsList
@onready var quest_list: VBoxContainer = $Center/VBox/QuestPanel/ScrollContainer/QuestList
@onready var team_list: VBoxContainer = $Center/VBox/TeamPanel/ScrollContainer/TeamList
@onready var achievement_list: VBoxContainer = $Center/VBox/AchievementPanel/ScrollContainer/AchievementList
@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var info_label: Label = $Center/VBox/InfoLabel

var current_tab: int = 0

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.15, 0.13, 0.25, 0.98)

func _ready():
        if back_button:
                back_button.pressed.connect(_on_back)
        stats_tab.pressed.connect(func(): _show_tab(0))
        quest_tab.pressed.connect(func(): _show_tab(1))
        team_tab.pressed.connect(func(): _show_tab(2))
        achievement_tab.pressed.connect(func(): _show_tab(3))
        _refresh_topbar()
        _show_tab(0)
        AudioManager.play_music("menu")

func _style_button(btn: Button, accent: Color):
        var normal = StyleBoxFlat.new()
        normal.bg_color = COL_BG
        normal.corner_radius_top_left = 8
        normal.corner_radius_top_right = 8
        normal.corner_radius_bottom_left = 8
        normal.corner_radius_bottom_right = 8
        normal.border_width_left = 2
        normal.border_width_right = 2
        normal.border_width_top = 2
        normal.border_width_bottom = 2
        normal.border_color = Color(accent.r, accent.g, accent.b, 0.5)
        normal.content_margin_top = 8
        normal.content_margin_bottom = 8
        normal.content_margin_left = 16
        normal.content_margin_right = 16
        var hover = normal.duplicate()
        hover.bg_color = COL_BG_HOVER
        hover.border_color = Color(accent.r, accent.g, accent.b, 0.9)
        btn.add_theme_stylebox_override("normal", normal)
        btn.add_theme_stylebox_override("hover", hover)
        btn.add_theme_stylebox_override("pressed", normal)

func _refresh_topbar():
        coins_label.text = "HL Coin: %d" % ProgressionManager.hl_coins

func _show_tab(tab: int):
        current_tab = tab
        stats_panel.visible = (tab == 0)
        quest_panel.visible = (tab == 1)
        team_panel.visible = (tab == 2)
        achievement_panel.visible = (tab == 3)
        stats_tab.modulate = Color(1.2, 1.2, 1.0) if tab == 0 else Color(0.6, 0.6, 0.6)
        quest_tab.modulate = Color(1.2, 1.2, 1.0) if tab == 1 else Color(0.6, 0.6, 0.6)
        team_tab.modulate = Color(1.2, 1.2, 1.0) if tab == 2 else Color(0.6, 0.6, 0.6)
        achievement_tab.modulate = Color(1.2, 1.2, 1.0) if tab == 3 else Color(0.6, 0.6, 0.6)
        match tab:
                0: _build_stats()
                1: _build_quests()
                2: _build_team()
                3: _build_achievements()

func _make_label(text: String, color: Color, size: int = 14) -> Label:
        var l = Label.new()
        l.text = text
        l.modulate = color
        l.add_theme_font_size_override("font_size", size)
        return l

func _build_stats():
        for child in stats_list.get_children():
                child.queue_free()
        # Player stats
        var title = _make_label("📊 Chỉ số Player (Mutant)", Color(1.0, 0.85, 0.3), 22)
        stats_list.add_child(title)
        # Base stats (111 theo spec = 1/1/1)
        stats_list.add_child(_make_label("Chỉ số gốc: Magic 1 / Physical 1 / Agility 1 (tổng 3, aka '111')", Color(0.7, 0.8, 0.9)))
        # Current stats
        stats_list.add_child(_make_label("Chỉ số hiện tại: Magic %d / Physical %d / Agility %d (tổng %d)" % [
                ProgressionManager.player_magic, ProgressionManager.player_physical, ProgressionManager.player_agility,
                ProgressionManager.player_magic + ProgressionManager.player_physical + ProgressionManager.player_agility
        ], Color(0.5, 1.0, 0.5), 18))
        # Level
        stats_list.add_child(_make_label("Cấp: %d / %d (mỗi cấp +2 điểm)" % [ProgressionManager.player_level, ProgressionManager.MAX_LEVEL], Color(0.7, 0.8, 0.9)))
        stats_list.add_child(_make_label("Điểm chưa dùng: %d" % ProgressionManager.points_to_spend, Color(1.0, 0.85, 0.3), 16))
        # Allocate buttons if has points
        if ProgressionManager.points_to_spend > 0:
                var hbox = HBoxContainer.new()
                hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
                hbox.add_theme_constant_override("separation", 10)
                for stat in ["magic", "physical", "agility"]:
                        var btn = Button.new()
                        btn.text = "+1 %s" % stat
                        btn.custom_minimum_size = Vector2(140, 44)
                        _style_button(btn, Color(0.4, 0.9, 0.5))
                        btn.pressed.connect(_on_allocate_stat.bind(stat))
                        hbox.add_child(btn)
                stats_list.add_child(hbox)
        # Class
        if ProgressionManager.current_class_id >= 0:
                var sp = SpeciesData.get_species(ProgressionManager.current_class_id)
                stats_list.add_child(_make_label("Class hiện tại: %s %s" % [sp["emoji"], sp["name"]], Color(0.4, 0.9, 1.0), 16))
        else:
                stats_list.add_child(_make_label("Class: Chưa có (mutant). Mua ở Tiền Bối shop.", Color(1.0, 0.5, 0.3), 16))
        stats_list.add_child(_make_label("Class đã sở hữu: %d/6 (mặt nạ đổi class: %d)" % [ProgressionManager.owned_classes.size(), ProgressionManager.owned_masks], Color(0.7, 0.8, 0.9)))
        # Reputation per species
        stats_list.add_child(_make_label("", Color.WHITE))
        stats_list.add_child(_make_label("🤝 Uy tín theo loài (−100..100):", Color(1.0, 0.85, 0.3), 18))
        for id in SpeciesData.SPECIES.keys():
                var sp = SpeciesData.get_species(id)
                var rep = ProgressionManager.get_reputation(id)
                var rep_color = Color(0.5, 1.0, 0.5) if rep > 0 else (Color(1.0, 0.5, 0.3) if rep < 0 else Color(0.7, 0.8, 0.9))
                stats_list.add_child(_make_label("  %s %s: %d%s" % [sp["emoji"], sp["name"], rep, " (chính)" if sp["main"] else ""], rep_color))
        # Intimacy for 3-star NPCs
        var intimacy_count = 0
        for npc_id in ProgressionManager.intimacy.keys():
                if ProgressionManager.intimacy[npc_id] > 0:
                        intimacy_count += 1
        if intimacy_count > 0:
                stats_list.add_child(_make_label("", Color.WHITE))
                stats_list.add_child(_make_label("💕 Độ thân mật NPC 3 sao:", Color(1.0, 0.85, 0.3), 18))
                for npc_id in ProgressionManager.intimacy.keys():
                        var val = ProgressionManager.intimacy[npc_id]
                        if val > 0:
                                stats_list.add_child(_make_label("  %s: %d/100" % [npc_id, val], Color(0.85, 0.55, 1.0)))

func _on_allocate_stat(stat: String):
        AudioManager.play_ui_click()
        var ok = ProgressionManager.add_stat(stat, 1)
        if ok:
                info_label.text = "✓ Đã nâng %s +1" % stat
                info_label.modulate = Color(0.5, 1.0, 0.5)
                AudioManager.play_variation("chime", 1.0, 1.1)
        else:
                info_label.text = "✗ Không đủ điểm"
                info_label.modulate = Color(1.0, 0.5, 0.3)
        _refresh_topbar()
        _build_stats()

# v3.9: Quest tab — hiển thị active quests + completed quests
func _build_quests():
        for child in quest_list.get_children():
                child.queue_free()
        var title = _make_label("📜 Quest của bạn", Color(1.0, 0.85, 0.3), 22)
        quest_list.add_child(title)
        # Active quests
        var active = ProgressionManager.active_quests
        if active.is_empty():
                quest_list.add_child(_make_label("Chưa có quest nào đang làm. Vào quán rượu để nhận quest.", Color(0.7, 0.8, 0.9)))
        else:
                quest_list.add_child(_make_label("⚔ Quest đang làm (%d / 5):" % active.size(), Color(0.5, 1.0, 0.7), 18))
                for q in active:
                        var panel = PanelContainer.new()
                        panel.custom_minimum_size = Vector2(880, 0)
                        var style = StyleBoxFlat.new()
                        style.bg_color = Color(0.18, 0.15, 0.08, 0.95)
                        style.corner_radius_top_left = 8
                        style.corner_radius_top_right = 8
                        style.corner_radius_bottom_left = 8
                        style.corner_radius_bottom_right = 8
                        style.border_width_left = 2
                        style.border_width_right = 2
                        style.border_width_top = 2
                        style.border_width_bottom = 2
                        style.border_color = Color(0.95, 0.75, 0.3, 0.7)
                        style.content_margin_top = 8
                        style.content_margin_bottom = 8
                        style.content_margin_left = 14
                        style.content_margin_right = 14
                        panel.add_theme_stylebox_override("panel", style)
                        var vbox = VBoxContainer.new()
                        vbox.add_theme_constant_override("separation", 3)
                        var name_lbl = _make_label("📋 %s" % q.get("name", ""), Color(1.0, 0.85, 0.3), 16)
                        vbox.add_child(name_lbl)
                        vbox.add_child(_make_label("Mục tiêu: %s" % q.get("target", ""), Color(0.7, 0.8, 0.9)))
                        var reward_str = "Phần thưởng: %d HL Coin" % q.get("reward_coins", 0)
                        if q.has("reward_species") and q["reward_species"] >= 0:
                                reward_str += " + %d uy tín %s" % [q.get("reward_rep", 0), SpeciesData.get_species_name(q["reward_species"])]
                        vbox.add_child(_make_label(reward_str, Color(0.5, 1.0, 0.5)))
                        vbox.add_child(_make_label("💡 Vào quán rượu và ấn \"⚔ Vào Ải\" để làm quest.", Color(0.6, 0.7, 0.85), 12))
                        panel.add_child(vbox)
                        quest_list.add_child(panel)
        # Completed quests
        var completed = ProgressionManager.completed_quests
        if not completed.is_empty():
                quest_list.add_child(_make_label("", Color.WHITE))
                quest_list.add_child(_make_label("✓ Quest đã hoàn thành (%d):" % completed.size(), Color(0.5, 1.0, 0.7), 18))
                # Tìm quest data từ WorldManager.QUEST_POOL để hiển thị tên
                for qid in completed:
                        var qname = _find_quest_name_by_id(qid)
                        quest_list.add_child(_make_label("  ✓ %s" % qname, Color(0.6, 0.85, 0.7)))

# v3.9: Helper — tìm quest name từ QUEST_POOL dựa trên id
func _find_quest_name_by_id(qid: String) -> String:
        for region_quests in WorldManager.QUEST_POOL.values():
                for q in region_quests:
                        if q.get("id", "") == qid:
                                return q.get("name", qid)
        return qid

func _build_team():
        for child in team_list.get_children():
                child.queue_free()
        var title = _make_label("👥 Đội hiện tại (tối đa 5 = player + 4 đồng đội)", Color(1.0, 0.85, 0.3), 22)
        team_list.add_child(title)
        if ProgressionManager.team.is_empty():
                team_list.add_child(_make_label("Chưa có đồng đội. Vào quán rượu để chiêu mộ.", Color(0.7, 0.8, 0.9)))
        else:
                for i in range(ProgressionManager.team.size()):
                        var m = ProgressionManager.team[i]
                        var sp = SpeciesData.get_species(m["species_id"])
                        var stats = m["stats"]
                        team_list.add_child(_make_label("%d. %s %s %s (Loài %s)" % [
                                i + 1, sp["emoji"], m["name"], "★".repeat(m["stars"]), sp["name"]
                        ], sp["color"], 18))
                        team_list.add_child(_make_label("   Magic %d | Physical %d | Agility %d (tổng %d)" % [
                                stats["magic"], stats["physical"], stats["agility"],
                                stats["magic"] + stats["physical"] + stats["agility"]
                        ], Color(0.7, 0.8, 0.9)))
                        team_list.add_child(_make_label("   Skills: %s" % ", ".join(m["skills"]), Color(0.6, 0.85, 1.0)))
                        team_list.add_child(_make_label("   Giá thuê đã trả: %d HL Coin" % m["hire_cost"], Color(1.0, 0.85, 0.3)))
                        if m.get("npc_id", "") != "":
                                var int_val = ProgressionManager.get_intimacy(m["npc_id"])
                                team_list.add_child(_make_label("   💕 Độ thân mật: %d/100" % int_val, Color(0.85, 0.55, 1.0)))
                # Team total stats
                var ts = ProgressionManager.get_team_total_stats()
                team_list.add_child(_make_label("", Color.WHITE))
                team_list.add_child(_make_label("Tổng chỉ số đồng đội: Magic %d | Physical %d | Agility %d (tổng %d)" % [
                        ts["magic"], ts["physical"], ts["agility"], ts["total"]
                ], Color(0.5, 1.0, 0.5), 16))
                var bonus = ProgressionManager.get_team_bonus_for_player()
                team_list.add_child(_make_label("Bonus cho player: +%d%% HP, +%d%% damage, +%d%% speed, +%d%% magic" % [
                        int(bonus["hp_bonus_pct"]), int(bonus["damage_bonus_pct"]),
                        int(bonus["speed_bonus_pct"]), int(bonus["magic_bonus_pct"])
                ], Color(0.5, 1.0, 0.5), 16))
                team_list.add_child(_make_label("⚠️ Sau khi hoàn thành quest, đồng đội lấy chiến lợi phẩm + phí thuê rồi mất hút.", Color(1.0, 0.5, 0.3), 13))
        # Player
        team_list.add_child(_make_label("", Color.WHITE))
        team_list.add_child(_make_label("Bạn (Player — Mutant)", Color(1.0, 0.85, 0.3), 18))
        team_list.add_child(_make_label("  Magic %d | Physical %d | Agility %d | Cấp %d/5" % [
                ProgressionManager.player_magic, ProgressionManager.player_physical,
                ProgressionManager.player_agility, ProgressionManager.player_level
        ], Color(0.7, 0.8, 0.9)))

func _build_achievements():
        for child in achievement_list.get_children():
                child.queue_free()
        var progress = ProgressionManager.get_achievement_progress()
        var title = _make_label("🏆 Thành tựu (%d / %d)" % [progress["unlocked"], progress["total"]], Color(1.0, 0.85, 0.3), 22)
        achievement_list.add_child(title)
        for ach_id in ProgressionManager.ACHIEVEMENTS_DEF.keys():
                var def = ProgressionManager.ACHIEVEMENTS_DEF[ach_id]
                var unlocked = ProgressionManager.is_achievement_unlocked(ach_id)
                var panel = PanelContainer.new()
                var style = StyleBoxFlat.new()
                style.bg_color = Color(0.10, 0.10, 0.18, 0.95) if unlocked else Color(0.05, 0.05, 0.10, 0.95)
                style.corner_radius_top_left = 8
                style.corner_radius_top_right = 8
                style.corner_radius_bottom_left = 8
                style.corner_radius_bottom_right = 8
                style.border_width_left = 2
                style.border_width_right = 2
                style.border_width_top = 2
                style.border_width_bottom = 2
                style.border_color = Color(0.95, 0.85, 0.3, 0.7) if unlocked else Color(0.3, 0.3, 0.4, 0.5)
                style.content_margin_top = 8
                style.content_margin_bottom = 8
                style.content_margin_left = 14
                style.content_margin_right = 14
                panel.add_theme_stylebox_override("panel", style)
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 2)
                var name_lbl = _make_label("%s %s" % ["✓" if unlocked else "🔒", def["name"]], Color(0.95, 0.85, 0.3) if unlocked else Color(0.5, 0.5, 0.55), 16)
                vbox.add_child(name_lbl)
                vbox.add_child(_make_label(def["desc"], Color(0.7, 0.8, 0.9) if unlocked else Color(0.4, 0.4, 0.45)))
                vbox.add_child(_make_label("Phần thưởng: %d HL Coin" % def["coins"], Color(0.5, 1.0, 0.5) if unlocked else Color(0.4, 0.5, 0.4)))
                panel.add_child(vbox)
                achievement_list.add_child(panel)

func _on_back():
        AudioManager.play_cancel()
        get_tree().change_scene_to_file("res://scenes/world_map.tscn")

func _unhandled_input(event: InputEvent):
        if event.is_action_pressed("menu_back"):
                get_viewport().set_input_as_handled()
                _on_back()
