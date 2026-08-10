extends Node

## TutorialManager - Quản lý hướng dẫn (v4.0)
## Singleton autoload.
## - Theo dõi trạng thái tutorial: đã xem chưa, đang ở step nào
## - Tự động hiện tutorial lần đầu vào menu
## - Cung cấp API để mở tutorial từ bất kỳ đâu

signal tutorial_finished()

const SAVE_PATH: String = "user://tutorial_state.cfg"

# Trạng thái tutorial
var tutorial_seen: bool = false  # đã xem full tutorial lần đầu chưa
var first_combat_hint_shown: bool = false
var first_world_hint_shown: bool = false
var first_tavern_hint_shown: bool = false
var first_shop_hint_shown: bool = false
var first_multiplayer_hint_shown: bool = false

func _ready():
	_load()

## Mở tutorial scene (từ menu hoặc bất kỳ đâu)
func open_tutorial():
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

## Đánh dấu đã xem tutorial full
func mark_tutorial_seen():
	tutorial_seen = true
	_save()
	tutorial_finished.emit()

## Auto-open tutorial lần đầu vào game
func maybe_auto_open_tutorial() -> bool:
	if not tutorial_seen:
		open_tutorial()
		return true
	return false

# === HINT CONTEXTUAL ===
## Hint cho combat scene (chỉ hiện 1 lần)
func should_show_combat_hint() -> bool:
	if not first_combat_hint_shown:
		first_combat_hint_shown = true
		_save()
		return true
	return false

func should_show_world_hint() -> bool:
	if not first_world_hint_shown:
		first_world_hint_shown = true
		_save()
		return true
	return false

func should_show_tavern_hint() -> bool:
	if not first_tavern_hint_shown:
		first_tavern_hint_shown = true
		_save()
		return true
	return false

func should_show_shop_hint() -> bool:
	if not first_shop_hint_shown:
		first_shop_hint_shown = true
		_save()
		return true
	return false

func should_show_multiplayer_hint() -> bool:
	if not first_multiplayer_hint_shown:
		first_multiplayer_hint_shown = true
		_save()
		return true
	return false

func _save():
	var cfg = ConfigFile.new()
	cfg.set_value("tutorial", "tutorial_seen", tutorial_seen)
	cfg.set_value("tutorial", "first_combat_hint_shown", first_combat_hint_shown)
	cfg.set_value("tutorial", "first_world_hint_shown", first_world_hint_shown)
	cfg.set_value("tutorial", "first_tavern_hint_shown", first_tavern_hint_shown)
	cfg.set_value("tutorial", "first_shop_hint_shown", first_shop_hint_shown)
	cfg.set_value("tutorial", "first_multiplayer_hint_shown", first_multiplayer_hint_shown)
	cfg.save(SAVE_PATH)

func _load():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	tutorial_seen = cfg.get_value("tutorial", "tutorial_seen", false)
	first_combat_hint_shown = cfg.get_value("tutorial", "first_combat_hint_shown", false)
	first_world_hint_shown = cfg.get_value("tutorial", "first_world_hint_shown", false)
	first_tavern_hint_shown = cfg.get_value("tutorial", "first_tavern_hint_shown", false)
	first_shop_hint_shown = cfg.get_value("tutorial", "first_shop_hint_shown", false)
	first_multiplayer_hint_shown = cfg.get_value("tutorial", "first_multiplayer_hint_shown", false)
