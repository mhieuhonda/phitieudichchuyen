extends Control

## Tavern - Quán rượu (v3.7)
## 2 tab: Quest Board (nhận quest) và Recruitment (chiêu mộ đồng đội)

@onready var tab_buttons: HBoxContainer = $TopBar/TabButtons
@onready var quest_tab_btn: Button = $TopBar/TabButtons/QuestTabBtn
@onready var recruit_tab_btn: Button = $TopBar/TabButtons/RecruitTabBtn
@onready var quest_panel: VBoxContainer = $Center/VBox/QuestPanel
@onready var recruit_panel: VBoxContainer = $Center/VBox/RecruitPanel
@onready var quest_list: VBoxContainer = $Center/VBox/QuestPanel/ScrollContainer/QuestList
@onready var npc_list: VBoxContainer = $Center/VBox/RecruitPanel/ScrollContainer/NpcList
@onready var coins_label: Label = $TopBar/CoinsLabel
@onready var team_label: Label = $TopBar/TeamLabel
@onready var info_label: Label = $Center/VBox/InfoLabel
@onready var back_button: Button = $TopBar/BackButton

var current_tab: int = 0  # 0=quest, 1=recruit
var tavern_npcs: Array = []

const COL_BG := Color(0.07, 0.07, 0.14, 0.95)
const COL_BG_HOVER := Color(0.15, 0.13, 0.25, 0.98)

func _ready():
        if back_button:
                back_button.pressed.connect(_on_back)
        quest_tab_btn.pressed.connect(_show_quest_tab)
        recruit_tab_btn.pressed.connect(_show_recruit_tab)
        # Generate NPCs when entering
        tavern_npcs = WorldManager.generate_tavern_npcs()
        _refresh_topbar()
        _show_quest_tab()
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
        team_label.text = "Đội: %d/5 (player + %d)" % [ProgressionManager.team.size() + 1, ProgressionManager.team.size()]

func _show_quest_tab():
        current_tab = 0
        quest_panel.visible = true
        recruit_panel.visible = false
        quest_tab_btn.modulate = Color(1.2, 1.2, 1.0)
        recruit_tab_btn.modulate = Color(0.6, 0.6, 0.6)
        _refresh_quests()

func _show_recruit_tab():
        current_tab = 1
        quest_panel.visible = false
        recruit_panel.visible = true
        recruit_tab_btn.modulate = Color(1.2, 1.2, 1.0)
        quest_tab_btn.modulate = Color(0.6, 0.6, 0.6)
        _refresh_npcs()

func _refresh_quests():
        for child in quest_list.get_children():
                child.queue_free()
        var quests = WorldManager.get_available_quests()
        if quests.is_empty():
                var lbl = Label.new()
                lbl.text = "Không còn quest ở vùng này. Thử vùng khác hoặc hoàn thành quest đang active."
                lbl.modulate = Color(0.6, 0.7, 0.85)
                quest_list.add_child(lbl)
                return
        for q in quests:
                var item = _build_quest_item(q)
                quest_list.add_child(item)
        # Show active quests
        if ProgressionManager.active_quests.size() > 0:
                var sep = HSeparator.new()
                quest_list.add_child(sep)
                var act_title = Label.new()
                act_title.text = "— Quest đang nhận —"
                act_title.modulate = Color(1.0, 0.85, 0.3)
                act_title.add_theme_font_size_override("font_size", 18)
                quest_list.add_child(act_title)
                for q in ProgressionManager.active_quests:
                        var item = _build_quest_item(q, true)
                        quest_list.add_child(item)

func _build_quest_item(q: Dictionary, is_active: bool = false) -> PanelContainer:
        var panel = PanelContainer.new()
        panel.custom_minimum_size = Vector2(880, 0)
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.10, 0.10, 0.18, 0.95) if not is_active else Color(0.18, 0.15, 0.08, 0.95)
        style.corner_radius_top_left = 8
        style.corner_radius_top_right = 8
        style.corner_radius_bottom_left = 8
        style.corner_radius_bottom_right = 8
        style.border_width_left = 2
        style.border_width_right = 2
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.border_color = Color(0.45, 0.4, 0.65, 0.5) if not is_active else Color(0.95, 0.75, 0.3, 0.7)
        style.content_margin_top = 10
        style.content_margin_bottom = 10
        style.content_margin_left = 14
        style.content_margin_right = 14
        panel.add_theme_stylebox_override("panel", style)
        var hbox = HBoxContainer.new()
        hbox.add_theme_constant_override("separation", 16)
        var vbox = VBoxContainer.new()
        vbox.size_flags_horizontal = 3
        vbox.add_theme_constant_override("separation", 4)
        var name_lbl = Label.new()
        name_lbl.text = "📋 %s" % q.get("name", "")
        name_lbl.add_theme_font_size_override("font_size", 18)
        name_lbl.modulate = Color(1.0, 0.85, 0.3)
        vbox.add_child(name_lbl)
        var target_lbl = Label.new()
        target_lbl.text = "Mục tiêu: %s" % q.get("target", "")
        target_lbl.modulate = Color(0.7, 0.8, 0.9)
        vbox.add_child(target_lbl)
        var reward_str = "Phần thưởng: %d HL Coin" % q.get("reward_coins", 0)
        if q.has("reward_species") and q["reward_species"] >= 0:
                reward_str += " + %d uy tín %s" % [q.get("reward_rep", 0), SpeciesData.get_species_name(q["reward_species"])]
        vbox.add_child(_make_label(reward_str, Color(0.5, 1.0, 0.5)))
        var req_str = ""
        if q.has("require_class") and q["require_class"] >= 0:
                req_str += "Yêu cầu class: %s" % SpeciesData.get_species_name(q["require_class"])
        if q.has("require_min_team") and q["require_min_team"] > 0:
                if req_str != "": req_str += " | "
                req_str += "Yêu cầu đội ≥ %d người" % q["require_min_team"]
        if req_str != "":
                var has_class = (not q.has("require_class")) or (ProgressionManager.current_class_id == q["require_class"])
                var has_team = (not q.has("require_min_team")) or (ProgressionManager.team.size() + 1 >= q["require_min_team"])
                var ok = has_class and has_team
                vbox.add_child(_make_label(req_str, Color(1.0, 0.5, 0.3) if not ok else Color(0.7, 0.9, 0.7)))
        hbox.add_child(vbox)
        # Button
        if not is_active:
                var btn = Button.new()
                btn.text = "Nhận"
                btn.custom_minimum_size = Vector2(100, 50)
                var can = (not q.has("require_class") or ProgressionManager.current_class_id == q["require_class"]) and (not q.has("require_min_team") or ProgressionManager.team.size() + 1 >= q["require_min_team"])
                _style_button(btn, Color(0.4, 0.9, 0.5) if can else Color(0.4, 0.4, 0.4))
                btn.disabled = not can
                btn.pressed.connect(_on_accept_quest.bind(q))
                hbox.add_child(btn)
        else:
                # Active quest → chỉ còn nút "Vào ải" (v3.9: bỏ nút "Hoàn thành" manual)
                var btn = Button.new()
                btn.text = "⚔ Vào Ải"
                btn.custom_minimum_size = Vector2(120, 50)
                _style_button(btn, Color(0.95, 0.55, 0.3))
                btn.pressed.connect(_on_do_quest.bind(q))
                hbox.add_child(btn)
        panel.add_child(hbox)
        return panel

func _make_label(text: String, color: Color) -> Label:
        var l = Label.new()
        l.text = text
        l.modulate = color
        l.add_theme_font_size_override("font_size", 14)
        return l

func _refresh_npcs():
        for child in npc_list.get_children():
                child.queue_free()
        if tavern_npcs.is_empty():
                var lbl = Label.new()
                lbl.text = "Không có NPC nào trong quán rượu lúc này. Ra ngoài và quay lại sau."
                lbl.modulate = Color(0.6, 0.7, 0.85)
                npc_list.add_child(lbl)
                return
        for npc in tavern_npcs:
                var item = _build_npc_item(npc)
                npc_list.add_child(item)

func _build_npc_item(npc: Dictionary) -> PanelContainer:
        var panel = PanelContainer.new()
        panel.custom_minimum_size = Vector2(880, 0)
        var style = StyleBoxFlat.new()
        var star_colors = {1: Color(0.6, 0.6, 0.6), 2: Color(0.4, 0.8, 1.0), 3: Color(1.0, 0.85, 0.3)}
        style.bg_color = Color(0.10, 0.10, 0.18, 0.95)
        style.corner_radius_top_left = 8
        style.corner_radius_top_right = 8
        style.corner_radius_bottom_left = 8
        style.corner_radius_bottom_right = 8
        style.border_width_left = 2
        style.border_width_right = 2
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.border_color = star_colors.get(npc["stars"], Color(0.5, 0.5, 0.5))
        style.content_margin_top = 10
        style.content_margin_bottom = 10
        style.content_margin_left = 14
        style.content_margin_right = 14
        panel.add_theme_stylebox_override("panel", style)
        var hbox = HBoxContainer.new()
        hbox.add_theme_constant_override("separation", 14)
        var vbox = VBoxContainer.new()
        vbox.size_flags_horizontal = 3
        vbox.add_theme_constant_override("separation", 4)
        var sp = SpeciesData.get_species(npc["species_id"])
        var stars_str = "★".repeat(npc["stars"])
        var name_lbl = Label.new()
        name_lbl.text = "%s %s %s" % [sp["emoji"], npc["name"], stars_str]
        name_lbl.add_theme_font_size_override("font_size", 18)
        name_lbl.modulate = star_colors.get(npc["stars"], Color(1, 1, 1))
        vbox.add_child(name_lbl)
        var stats = npc["stats"]
        var stats_str = "Loài: %s | Magic %d | Physical %d | Agility %d (tổng %d)" % [
                sp["name"], stats["magic"], stats["physical"], stats["agility"],
                stats["magic"] + stats["physical"] + stats["agility"]
        ]
        vbox.add_child(_make_label(stats_str, Color(0.7, 0.8, 0.9)))
        var skills_str = "Skills: " + ", ".join(npc["skills"])
        vbox.add_child(_make_label(skills_str, Color(0.6, 0.85, 1.0)))
        var cost_str = "Giá thuê: %d HL Coin | Tỉ lệ: %d%%" % [npc["hire_cost"], int(npc["recruit_chance"] * 100)]
        vbox.add_child(_make_label(cost_str, Color(1.0, 0.85, 0.3)))
        if npc.get("is_three_star", false):
                vbox.add_child(_make_label("⭐ NPC 3 SAO ĐẶC BIỆT — Hạn chế!", Color(1.0, 0.5, 0.3)))
        hbox.add_child(vbox)
        var btn = Button.new()
        btn.text = "Chiêu Mộ"
        btn.custom_minimum_size = Vector2(120, 50)
        var can_afford = ProgressionManager.hl_coins >= npc["hire_cost"]
        var can_team = ProgressionManager.can_recruit()
        _style_button(btn, Color(0.4, 0.9, 0.5) if (can_afford and can_team) else Color(0.4, 0.4, 0.4))
        btn.disabled = not (can_afford and can_team)
        btn.pressed.connect(_on_recruit.bind(npc))
        hbox.add_child(btn)
        panel.add_child(hbox)
        return panel

func _on_accept_quest(q: Dictionary):
        AudioManager.play_ui_click()
        var q_copy = q.duplicate()
        # Convert reward keys
        q_copy["reward_species"] = q.get("reward_rep_species", -1)
        var ok = ProgressionManager.accept_quest(q_copy)
        if ok:
                info_label.text = "✓ Đã nhận quest: %s" % q["name"]
                info_label.modulate = Color(0.5, 1.0, 0.5)
        else:
                info_label.text = "✗ Không đủ điều kiện nhận quest"
                info_label.modulate = Color(1.0, 0.5, 0.3)
        _refresh_topbar()
        _refresh_quests()

func _on_do_quest(q: Dictionary):
        AudioManager.play_ui_click()
        # v3.9: Thay vì gửi player qua stage_select, ta launch trực tiếp
        # main.tscn với quest_mode = true. GameManager sẽ đọc quest data
        # và setup ải quest tương ứng (kill X / boss mini / find target).
        # Quest sẽ tự complete khi player đạt objective → tự quay về tavern.
        GameManager.active_quest_id = String(q.get("id", ""))
        GameManager.active_quest_data = q
        GameManager.quest_mode = true  # flag cho main.gd::_ready nhận biết
        info_label.text = "⚔ Vào quest: %s — tiêu diệt hết mục tiêu để nhận thưởng!" % q.get("name", "")
        info_label.modulate = Color(0.7, 0.85, 1.0)
        get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_complete_quest(q: Dictionary):
        # v3.9: Đã bỏ "✓ Hoàn thành" manual button — quest tự complete khi
        # player hoàn thành objective trong main.tscn. Hàm này giữ lại
        # để tránh broken reference nhưng chỉ hiển thị thông báo.
        AudioManager.play_ui_click()
        info_label.text = "✗ Quest chỉ hoàn thành khi bạn vào ải và đạt mục tiêu. Ấn \"⚔ Vào Ải\" để bắt đầu."
        info_label.modulate = Color(1.0, 0.5, 0.3)
        _refresh_topbar()
        _refresh_quests()

func _on_recruit(npc: Dictionary):
        AudioManager.play_ui_click()
        var result = WorldManager.try_recruit(npc)
        if result["success"]:
                info_label.text = "✓ Đã chiêu mộ: %s (%d★)" % [npc["name"], npc["stars"]]
                info_label.modulate = Color(0.5, 1.0, 0.5)
                AudioManager.play_variation("chime", 1.0, 1.1)
                # Remove from tavern list
                tavern_npcs.erase(npc)
        else:
                info_label.text = "✗ %s" % result["reason"]
                info_label.modulate = Color(1.0, 0.5, 0.3)
                AudioManager.play_variation("error", 0.0, 1.0)
        _refresh_topbar()
        _refresh_npcs()

func _on_back():
        AudioManager.play_cancel()
        get_tree().change_scene_to_file("res://scenes/world_map.tscn")

func _unhandled_input(event: InputEvent):
        if event.is_action_pressed("menu_back"):
                get_viewport().set_input_as_handled()
                _on_back()
