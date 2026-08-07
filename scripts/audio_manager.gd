extends Node

## AudioManager - Quản lý âm thanh và nhạc nền (v0.8)
## Tự load ~155 sound effects + 5 nhạc nền
## Pool AudioStreamPlayer để phát nhiều sound cùng lúc
## Respect sound_volume + music_volume từ SettingsManager

signal sound_played(sound_name: String)
signal music_changed(track_name: String)

# === POOL ===
const POOL_SIZE := 16
var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

# === MUSIC ===
var _music_player: AudioStreamPlayer = null
var _music_fade_tween: Tween = null
var _current_music: String = ""

# === SOUND CACHE ===
var _sounds: Dictionary = {}  # name -> AudioStreamWAV
var _music_tracks: Dictionary = {}  # name -> AudioStreamWAV

# === VOLUMES ===
var _sound_volume_db: float = 0.0
var _music_volume_db: float = 0.0
var _sound_enabled: bool = true
var _music_enabled: bool = true

# === SOUND CATEGORIES (for random variation) ===
const VARIATIONS = {
    "throw": ["throw_whoosh_01", "throw_whoosh_02", "throw_whoosh_03", "throw_whoosh_04", "throw_whoosh_05"],
    "teleport": ["teleport_zap_01", "teleport_zap_02", "teleport_zap_03", "teleport_zap_04", "teleport_zap_05"],
    "hit": ["hit_impact_01", "hit_impact_02", "hit_impact_03", "hit_impact_04", "hit_impact_05"],
    "kill": ["kill_explosion_01", "kill_explosion_02", "kill_explosion_03", "kill_explosion_04", "kill_explosion_05"],
    "death": ["death_01", "death_02", "death_03"],
    "pickup_health": ["pickup_health_01", "pickup_health_02", "pickup_health_03"],
    "pickup_dart": ["pickup_dart_01", "pickup_dart_02", "pickup_dart_03"],
    "ui_click": ["ui_click_01", "ui_click_02", "ui_click_03", "ui_click_04", "ui_click_05"],
    "ui_hover": ["ui_hover_01", "ui_hover_02", "ui_hover_03"],
    "combo": ["combo_01", "combo_02", "combo_03", "combo_04", "combo_05"],
    "zone_warning": ["zone_warning_01", "zone_warning_02", "zone_warning_03"],
    "zone_shrink": ["zone_shrink_01", "zone_shrink_02"],
    "dart_stick": ["dart_stick_01", "dart_stick_02", "dart_stick_03"],
    "dart_fly": ["dart_fly_01", "dart_fly_02"],
    "respawn": ["respawn_01", "respawn_02"],
    "footstep": ["footstep_01", "footstep_02", "footstep_03", "footstep_04", "footstep_05"],
    "damage": ["damage_01", "damage_02", "damage_03"],
    "powerup": ["powerup_01", "powerup_02", "powerup_03"],
    "notification": ["notification_01", "notification_02", "notification_03"],
    "whoosh": ["whoosh_01", "whoosh_02", "whoosh_03", "whoosh_04", "whoosh_05"],
    "zap": ["zap_01", "zap_02", "zap_03", "zap_04", "zap_05"],
    "explosion": ["explosion_01", "explosion_02", "explosion_03"],
    "sparkle": ["sparkle_01", "sparkle_02", "sparkle_03"],
    "chime": ["chime_01", "chime_02", "chime_03"],
    "drum_kick": ["drum_kick_01", "drum_kick_02"],
    "drum_snare": ["drum_snare_01", "drum_snare_02"],
    "drum_hihat": ["drum_hihat_01", "drum_hihat_02"],
    "drum_crash": ["drum_crash_01", "drum_crash_02"],
    "alarm": ["alarm_01", "alarm_02", "alarm_03"],
    "heartbeat": ["heartbeat_01", "heartbeat_02"],
    "countdown": ["countdown_beep_01", "countdown_beep_02", "countdown_beep_03"],
    "success": ["success_01", "success_02", "success_03"],
    "error": ["error_01", "error_02"],
    "warning": ["warning_01", "warning_02"],
    "info": ["info_01", "info_02"],
    "spawn": ["spawn_01", "spawn_02"],
    "size_grow": ["size_grow_01", "size_grow_02"],
    "aim_start": ["aim_start_01", "aim_start_02"],
    "laser": ["laser_01", "laser_02", "laser_03"],
    "magic": ["magic_01", "magic_02", "magic_03"],
    "coin": ["coin_01", "coin_02", "coin_03"],
    "bass": ["bass_01", "bass_02", "bass_03"],
    "click_light": ["click_light_01", "click_light_02", "click_light_03", "click_light_04", "click_light_05"],
    "click_heavy": ["click_heavy_01", "click_heavy_02", "click_heavy_03"],
    "select": ["select_01", "select_02", "select_03"],
    "confirm": ["confirm_01", "confirm_02"],
    "cancel": ["cancel_01", "cancel_02"],
    "achievement": ["achievement_01", "achievement_02"],
}

const MUSIC_TRACKS = {
    "menu": "menu_music_01",
    "game": "game_music_01",
    "game_alt": "game_music_02",
    "victory": "victory_music_01",
    "defeat": "defeat_music_01",
}

const SFX_PATH = "res://assets/audio/sfx/"
const MUSIC_PATH = "res://assets/audio/music/"

func _ready():
    # Tạo pool
    for i in POOL_SIZE:
        var p = AudioStreamPlayer.new()
        p.bus = "Master"
        add_child(p)
        _pool.append(p)
    # Music player
    _music_player = AudioStreamPlayer.new()
    _music_player.bus = "Master"
    add_child(_music_player)
    # Load sounds (lazy: chỉ load khi cần để tránh lag startup)
    # Preload các sound quan trọng
    _preload_common_sounds()
    # Update volume
    _update_volumes()
    if OS.is_debug_build():
        print("[AudioManager] Loaded %d sound variations, %d music tracks" % [_sounds.size(), _music_tracks.size()])

func _preload_common_sounds():
    # Preload các sound hay dùng
    var common = ["throw_whoosh_01", "teleport_zap_01", "hit_impact_01", "kill_explosion_01",
                  "pickup_health_01", "pickup_dart_01", "ui_click_01", "ui_click_02",
                  "combo_01", "zone_warning_01", "dart_stick_01", "respawn_01",
                  "damage_01", "death_01", "success_01", "error_01"]
    for sfx_name in common:
        _load_sound(sfx_name)

func _load_sound(sfx_name: String) -> AudioStreamWAV:
    if _sounds.has(sfx_name):
        return _sounds[sfx_name]
    var path = SFX_PATH + sfx_name + ".wav"
    if not ResourceLoader.exists(path):
        push_warning("[AudioManager] Sound not found: %s" % sfx_name)
        return null
    var stream = load(path)
    if stream:
        _sounds[sfx_name] = stream
    return stream

func _load_music(track_name: String) -> AudioStreamWAV:
    if _music_tracks.has(track_name):
        return _music_tracks[track_name]
    var path = MUSIC_PATH + track_name + ".wav"
    if not ResourceLoader.exists(path):
        push_warning("[AudioManager] Music not found: %s" % track_name)
        return null
    var stream = load(path)
    if stream:
        _music_tracks[track_name] = stream
    return stream

# === PUBLIC API ===

## Phát sound theo tên (nếu không tìm thấy, thử load)
func play_sound(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0):
    if not _sound_enabled:
        return
    var stream = _sounds.get(sfx_name)
    if not stream:
        stream = _load_sound(sfx_name)
        if not stream:
            return
    _play_stream(stream, volume_db, pitch)
    sound_played.emit(sfx_name)

## Phát random variation của category (vd: play_variation("throw"))
func play_variation(category: String, volume_db: float = 0.0, pitch: float = 1.0):
    if not _sound_enabled:
        return
    if not VARIATIONS.has(category):
        push_warning("[AudioManager] Category not found: %s" % category)
        return
    var list = VARIATIONS[category]
    var sfx_name = list[randi() % list.size()]
    play_sound(sfx_name, volume_db, pitch)

## Phát nhạc nền (fade in)
func play_music(track_name: String, fade_time: float = 0.5):
    if not _music_enabled:
        return
    if _current_music == track_name and _music_player.playing:
        return
    var stream = _music_tracks.get(MUSIC_TRACKS.get(track_name, ""))
    if not stream:
        var file = MUSIC_TRACKS.get(track_name, track_name)
        stream = _load_music(file)
        if not stream:
            return
    # Fade out current
    if _music_player.playing and fade_time > 0:
        if _music_fade_tween:
            _music_fade_tween.kill()
        _music_fade_tween = create_tween()
        _music_fade_tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
        _music_fade_tween.tween_callback(func():
            _music_player.stream = stream
            _music_player.volume_db = -40.0
            _music_player.play()
        )
        _music_fade_tween.tween_property(_music_player, "volume_db", _music_volume_db, fade_time)
    else:
        _music_player.stream = stream
        _music_player.volume_db = _music_volume_db
        _music_player.play()
    _current_music = track_name
    music_changed.emit(track_name)

func stop_music(fade_time: float = 0.5):
    if not _music_player.playing:
        return
    if _music_fade_tween:
        _music_fade_tween.kill()
    if fade_time > 0:
        _music_fade_tween = create_tween()
        _music_fade_tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
        _music_fade_tween.tween_callback(_music_player.stop)
    else:
        _music_player.stop()
    _current_music = ""

func set_sound_enabled(enabled: bool):
    _sound_enabled = enabled

func set_music_enabled(enabled: bool):
    _music_enabled = enabled
    if not enabled:
        stop_music(0.3)

## Trả về true nếu nhạc nền đang phát (API công khai, thay vì truy cập _music_player từ ngoài).
func is_music_playing() -> bool:
    return _music_player != null and _music_player.playing

func _update_volumes():
    # Convert 0..1 linear to dB
    _sound_volume_db = linear_to_db(SettingsManager.sound_volume) if SettingsManager.sound_volume > 0.001 else -80.0
    _music_volume_db = linear_to_db(SettingsManager.music_volume) if SettingsManager.music_volume > 0.001 else -80.0
    for p in _pool:
        p.volume_db = _sound_volume_db
    if _music_player:
        _music_player.volume_db = _music_volume_db

func _play_stream(stream: AudioStream, volume_db: float, pitch: float):
    var p = _pool[_pool_index]
    _pool_index = (_pool_index + 1) % POOL_SIZE
    p.stream = stream
    p.volume_db = _sound_volume_db + volume_db
    p.pitch_scale = pitch
    p.play()

func _exit_tree():
    # Godot 4.7: clean up pool + music player + fade tween on quit to avoid
    # `ObjectDB instances were leaked at exit` / `resources still in use at exit`.
    if _music_fade_tween and is_instance_valid(_music_fade_tween):
        _music_fade_tween.kill()
        _music_fade_tween = null
    if _music_player:
        _music_player.stop()
        _music_player.stream = null
    for p in _pool:
        if p:
            p.stop()
            p.stream = null

## Helper methods cho gameplay events
func play_throw():
    play_variation("throw", 0.0, randf_range(0.9, 1.1))

func play_teleport():
    play_variation("teleport", 2.0, randf_range(0.95, 1.05))

func play_hit():
    play_variation("hit", 0.0, randf_range(0.9, 1.1))

func play_kill():
    play_variation("kill", 1.0, randf_range(0.9, 1.1))

func play_death():
    play_variation("death", 0.0, randf_range(0.9, 1.1))

func play_pickup_health():
    play_variation("pickup_health", 0.0, randf_range(0.95, 1.05))

func play_pickup_dart():
    play_variation("pickup_dart", 0.0, randf_range(0.95, 1.05))

func play_ui_click():
    play_variation("ui_click", -3.0, randf_range(0.95, 1.05))

func play_ui_hover():
    play_variation("ui_hover", -6.0, randf_range(0.95, 1.05))

func play_combo(combo_count: int):
    var idx = clamp(combo_count - 2, 0, 4)
    var list = VARIATIONS["combo"]
    play_sound(list[idx], 2.0, 1.0)

func play_zone_warning():
    play_variation("zone_warning", 0.0, 1.0)

func play_zone_shrink():
    play_variation("zone_shrink", 0.0, 1.0)

func play_dart_stick():
    play_variation("dart_stick", -2.0, randf_range(0.9, 1.1))

func play_respawn():
    play_variation("respawn", 0.0, 1.0)

func play_damage():
    play_variation("damage", 0.0, randf_range(0.9, 1.1))

func play_powerup():
    play_variation("powerup", 0.0, 1.0)

func play_notification():
    play_variation("notification", 0.0, 1.0)

func play_success():
    play_variation("success", 0.0, 1.0)

func play_error():
    play_variation("error", 0.0, 1.0)

func play_warning():
    play_variation("warning", 0.0, 1.0)

func play_achievement():
    play_variation("achievement", 1.0, 1.0)

func play_size_grow():
    play_variation("size_grow", 0.0, 1.0)

func play_aim_start():
    play_variation("aim_start", -3.0, 1.0)

func play_spawn():
    play_variation("spawn", 0.0, 1.0)
