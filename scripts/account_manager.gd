extends Node

## AccountManager - Quản lý tài khoản người chơi (v4.1)
## Singleton autoload.
## - Đăng ký / đăng nhập qua REST API (https://phitieu.louis.vangioitutien.com/api/*)
## - Lưu token trong user://account.cfg
## - Cung cấp signals cho UI hook vào
## - Lấy profile + leaderboard qua HTTP

signal logged_in(user: Dictionary)
signal logged_out()
signal login_failed(reason: String)
signal register_failed(reason: String)
signal profile_updated(user: Dictionary)
signal level_up(old_level: int, new_level: int, new_title: String)
signal exp_gained(amount: int, total_exp: int)
signal leaderboard_loaded(entries: Array, online_count: int)

# Server URL — qua Traefik (https + domain)
const API_BASE := "https://phitieu.louis.vangioitutien.com/api"
const WS_BASE := "wss://phitieu.louis.vangioitutien.com/ws"
const SAVE_PATH := "user://account.cfg"

var token: String = ""
var current_user: Dictionary = {}  # id, username, display_name, title, level, exp, ...

var _http_request: HTTPRequest

func _ready():
	_http_request = HTTPRequest.new()
	_http_request.timeout = 15.0
	add_child(_http_request)
	_load_session()

# === Persistence ===

func _load_session():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	token = cfg.get_value("auth", "token", "")
	# Validate token by fetching /api/me
	if not token.is_empty():
		fetch_me()

func _save_session():
	var cfg = ConfigFile.new()
	cfg.set_value("auth", "token", token)
	if not current_user.is_empty():
		cfg.set_value("user", "username", current_user.get("username", ""))
		cfg.set_value("user", "display_name", current_user.get("display_name", ""))
		cfg.set_value("user", "level", current_user.get("level", 1))
		cfg.set_value("user", "title", current_user.get("title", ""))
	cfg.save(SAVE_PATH)

func _clear_session():
	token = ""
	current_user = {}
	var cfg = ConfigFile.new()
	cfg.clear(SAVE_PATH)
	cfg.save(SAVE_PATH)

# === Helpers ===

func is_logged_in() -> bool:
	return not token.is_empty() and not current_user.is_empty()

func get_display_name() -> String:
	if not current_user.is_empty():
		return String(current_user.get("display_name", ""))
	return ""

func get_username() -> String:
	if not current_user.is_empty():
		return String(current_user.get("username", ""))
	return ""

func get_level() -> int:
	if not current_user.is_empty():
		return int(current_user.get("level", 1))
	return 1

func get_title() -> String:
	if not current_user.is_empty():
		return String(current_user.get("title", ""))
	return ""

## URL WebSocket có kèm token (nếu đã đăng nhập)
func get_ws_url() -> String:
	if token.is_empty():
		return WS_BASE
	return WS_BASE + "?token=" + token

# === Async HTTP request helper ===
## Gọi REST API. Trả về: Dictionary có key "error" nếu thất bại, ngược lại là JSON parsed.
func _do_request(path: String, method: int, body: String, with_auth: bool = false) -> Dictionary:
	# Nếu đang có request đang chạy, cancel
	if _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_request.cancel_request()
		await get_tree().process_frame  # chờ 1 frame để cancel hoàn tất
	var headers = PackedStringArray()
	headers.append("Content-Type: application/json")
	if with_auth and not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	var url = API_BASE + path
	var err = _http_request.request(url, headers, method, body)
	if err != OK:
		return {"error": "Không thể gửi yêu cầu (code %d)" % err}
	var result = await _http_request.request_completed
	# result = [HTTPRequest.Result, response_code, PackedStringArray(headers), PackedByteArray(body)]
	var parsed = _parse_json(result[3])
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		return {"error": "Lỗi mạng — không thể kết nối server"}
	if result[1] != 200:
		var err_msg = String(parsed.get("error", "Lỗi HTTP %d" % result[1]))
		return {"error": err_msg, "response_code": result[1]}
	return parsed

# === API: Register ===

func register(username: String, password: String, display_name: String):
	if username.length() < 3:
		register_failed.emit("Tên đăng nhập phải 3-32 ký tự")
		return
	if password.length() < 6:
		register_failed.emit("Mật khẩu phải ít nhất 6 ký tự")
		return
	var body = JSON.stringify({
		"username": username.to_lower(),
		"password": password,
		"display_name": display_name if not display_name.is_empty() else username,
	})
	var resp = await _do_request("/register", HTTPClient.METHOD_POST, body, false)
	if resp.has("error"):
		register_failed.emit(resp["error"])
		return
	if not resp.has("token"):
		register_failed.emit("Phản hồi server không hợp lệ")
		return
	token = String(resp["token"])
	current_user = Dictionary(resp.get("user", {}))
	_save_session()
	logged_in.emit(current_user)
	print("[Account] Registered as %s (level %d)" % [current_user.get("username", "?"), current_user.get("level", 1)])

# === API: Login ===

func login(username: String, password: String):
	if username.is_empty() or password.is_empty():
		login_failed.emit("Thiếu tên đăng nhập hoặc mật khẩu")
		return
	var body = JSON.stringify({
		"username": username.to_lower(),
		"password": password,
	})
	var resp = await _do_request("/login", HTTPClient.METHOD_POST, body, false)
	if resp.has("error"):
		login_failed.emit(resp["error"])
		return
	if not resp.has("token"):
		login_failed.emit("Phản hồi server không hợp lệ")
		return
	token = String(resp["token"])
	current_user = Dictionary(resp.get("user", {}))
	_save_session()
	logged_in.emit(current_user)
	print("[Account] Logged in as %s (level %d)" % [current_user.get("username", "?"), current_user.get("level", 1)])

# === API: Logout ===

func logout():
	if token.is_empty():
		_clear_session()
		logged_out.emit()
		return
	# Best-effort: send logout to server, clear local regardless
	var _resp = await _do_request("/logout", HTTPClient.METHOD_POST, "", true)
	_clear_session()
	logged_out.emit()

# === API: Fetch me (validate token) ===

func fetch_me():
	if token.is_empty():
		return
	var resp = await _do_request("/me", HTTPClient.METHOD_GET, "", true)
	if resp.has("error"):
		_clear_session()
		return
	if not resp.has("user"):
		_clear_session()
		return
	var old_level = int(current_user.get("level", 0))
	current_user = Dictionary(resp.get("user", {}))
	_save_session()
	if old_level > 0 and int(current_user.get("level", old_level)) > old_level:
		level_up.emit(old_level, int(current_user["level"]), String(current_user.get("title", "")))
	profile_updated.emit(current_user)

# === API: Fetch leaderboard ===

func fetch_leaderboard(limit: int = 100):
	var resp = await _do_request("/leaderboard?limit=%d" % limit, HTTPClient.METHOD_GET, "", false)
	if resp.has("error"):
		leaderboard_loaded.emit([], 0)
		return
	var entries = Array(resp.get("leaderboard", []))
	var online_count = int(resp.get("online_count", 0))
	leaderboard_loaded.emit(entries, online_count)

# === API: Submit match result ===

func submit_match_result(kills: int, score: int, won: bool):
	if token.is_empty():
		return  # silently skip — guest user
	var body = JSON.stringify({
		"kills": kills,
		"score": score,
		"won": won,
	})
	var resp = await _do_request("/match_result", HTTPClient.METHOD_POST, body, true)
	if resp.has("error"):
		return
	var old_level = int(current_user.get("level", 0))
	current_user = Dictionary(resp.get("user", current_user))
	_save_session()
	var exp_gained_amt = int(resp.get("exp_gained", 0))
	if exp_gained_amt > 0:
		exp_gained.emit(exp_gained_amt, int(current_user.get("exp", 0)))
	if bool(resp.get("leveled_up", false)):
		var new_level = int(resp.get("new_level", old_level))
		var new_title = String(resp.get("new_title", ""))
		level_up.emit(old_level, new_level, new_title)
	profile_updated.emit(current_user)

# === Internal JSON parse ===

func _parse_json(body: PackedByteArray) -> Dictionary:
	if body.is_empty():
		return {}
	var text = body.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(text) != OK:
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data

# === WebSocket event handlers (called by MultiplayerManager) ===

## Khi server push event "level_up" qua WebSocket
func handle_ws_level_up(payload: Dictionary):
	var old_level = int(current_user.get("level", 0))
	var new_level = int(payload.get("new_level", old_level))
	var new_title = String(payload.get("new_title", ""))
	if new_level > old_level:
		current_user["level"] = new_level
		current_user["title"] = new_title
		_save_session()
		level_up.emit(old_level, new_level, new_title)
		profile_updated.emit(current_user)

## Khi server push event "exp_gained" qua WebSocket
func handle_ws_exp_gained(payload: Dictionary):
	var amount = int(payload.get("amount", 0))
	var total = int(payload.get("total_exp", 0))
	if amount > 0:
		current_user["exp"] = total
		_save_session()
		exp_gained.emit(amount, total)
		profile_updated.emit(current_user)
