extends Node

## AccountManager - Quản lý tài khoản người chơi (v4.3)
## Singleton autoload.
## - Đăng ký / đăng nhập qua REST API (https://phitieu.louis.vangioitutien.com/api/*)
## - Lưu token trong user://account.cfg
## - Cung cấp signals cho UI hook vào
## - Lấy profile + leaderboard qua HTTP
##
## v4.3 CRITICAL FIX:
## - Godot 4.7 đã XÓA property `tls_options` trên HTTPRequest. Gán trực tiếp
##   `_http_request.tls_options = ...` gây runtime error → TLS không được set →
##   mọi request đều fail. Phải dùng `_http_request.set_tls_options(...)` method.
## - Thêm explicit `Host` header để đảm bảo Traefik route đúng.
## - Thêm extensive logging để debug.
## - Dùng HTTPRequest pool (1 request/node) tránh race condition giữa
##   fetch_me() và login()/register() cùng share 1 HTTPRequest.
## - HTTPClient fallback nếu HTTPRequest trả 503 (một số môi trường
##   mbedTLS có vẻ không tương thích tốt với Traefik default cert).

signal logged_in(user: Dictionary)
signal logged_out()
signal login_failed(reason: String)
signal register_failed(reason: String)
signal profile_updated(user: Dictionary)
signal level_up(old_level: int, new_level: int, new_title: String)
signal exp_gained(amount: int, total_exp: int)
signal leaderboard_loaded(entries: Array, online_count: int)

# Server URL — qua Traefik (http + domain)
# v4.3: Godot 4.7's mbedTLS KHÔNG gửi SNI trong TLS ClientHello.
# Traefik v3.6 yêu cầu SNI = domain configured, nếu không có SNI → trả 503.
# Workaround: dùng HTTP (không TLS) cho REST API. HTTPS vẫn available cho
# browser/curl (gửi SNI đúng). Khi Godot fix lỗi SNI, có thể đổi lại sang HTTPS.
const API_BASE := "http://phitieu.louis.vangioitutien.com/api"
const WS_BASE := "ws://phitieu.louis.vangioitutien.com/ws"
const SAVE_PATH := "user://account.cfg"
const SERVER_HOST := "phitieu.louis.vangioitutien.com"

var token: String = ""
var current_user: Dictionary = {}  # id, username, display_name, title, level, exp, ...

# Pool of HTTPRequest nodes — mỗi request dùng 1 node riêng để tránh race
var _http_pool: Array[HTTPRequest] = []
const POOL_SIZE := 4

func _ready():
        # Tạo pool HTTPRequest
        for i in POOL_SIZE:
                var hr = HTTPRequest.new()
                hr.timeout = 15.0
                hr.accept_gzip = true
                # v4.3: HTTP (không TLS) nên không cần tls_options
                # Nhưng vẫn set để đề phòng đổi lại HTTPS sau này
                hr.set_tls_options(TLSOptions.client_unsafe())
                add_child(hr)
                _http_pool.append(hr)
        print("[Account] v4.3 ready — HTTPRequest pool=%d, API_BASE=%s" % [POOL_SIZE, API_BASE])
        _load_session()

# === Persistence ===

func _load_session():
        var cfg = ConfigFile.new()
        if cfg.load(SAVE_PATH) != OK:
                return
        token = cfg.get_value("auth", "token", "")
        # Validate token by fetching /api/me
        if not token.is_empty():
                print("[Account] Found saved token, validating...")
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
        # v4.3 FIX: ConfigFile.clear() in Godot 4.7 takes 0 args (clears all sections).
        # To delete the file, use DirAccess.remove_absolute() — if it fails (file doesn't
        # exist), just save an empty config as fallback.
        var cfg = ConfigFile.new()
        cfg.clear()  # clears all sections in memory
        cfg.save(SAVE_PATH)
        # Also try to delete the file entirely
        DirAccess.remove_absolute(SAVE_PATH)

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

# === HTTPRequest pool ===

## Lấy 1 HTTPRequest rảnh từ pool (status == DISCONNECTED)
func _get_idle_http() -> HTTPRequest:
        for hr in _http_pool:
                if hr.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
                        return hr
        # Nếu tất cả đều bận, cancel cái đầu tiên
        var first = _http_pool[0]
        first.cancel_request()
        return first

# === Async HTTP request helper ===

## Gọi REST API. Trả về: Dictionary có key "error" nếu thất bại, ngược lại là JSON parsed.
func _do_request(path: String, method: int, body: String, with_auth: bool = false) -> Dictionary:
        var hr = _get_idle_http()
        # Đảm bảo status là DISCONNECTED trước khi request
        if hr.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
                hr.cancel_request()
                await get_tree().process_frame
                # Chờ thêm 1 frame nếu vẫn chưa disconnect
                if hr.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
                        await get_tree().process_frame
        
        var headers = PackedStringArray()
        # v4.3: Explicit Host header — đảm bảo Traefik route đúng kể cả khi
        # Godot's default Host header bị sai (một số edge case trên Android)
        headers.append("Host: " + SERVER_HOST)
        headers.append("Content-Type: application/json")
        headers.append("Accept: application/json")
        headers.append("Connection: close")
        if with_auth and not token.is_empty():
                headers.append("Authorization: Bearer " + token)
        var url = API_BASE + path
        var method_names = {
                HTTPClient.METHOD_GET: "GET",
                HTTPClient.METHOD_POST: "POST",
                HTTPClient.METHOD_PUT: "PUT",
                HTTPClient.METHOD_DELETE: "DELETE",
        }
        print("[Account] → %s %s (body=%d bytes, auth=%s)" % [
                method_names.get(method, str(method)),
                path, body.length(), with_auth and not token.is_empty(),
        ])
        var err = hr.request(url, headers, method, body)
        if err != OK:
                print("[Account] ✗ HTTPRequest.request() failed: err=%d" % err)
                return {"error": "Không thể gửi yêu cầu (code %d)" % err}
        var result = await hr.request_completed
        # result = [HTTPRequest.Result, response_code, PackedStringArray(headers), PackedByteArray(body)]
        var result_code = result[0]
        var http_code = result[1]
        var body_bytes = result[3]
        var parsed = _parse_json(body_bytes)
        var body_preview = body_bytes.get_string_from_utf8().substr(0, 200) if body_bytes else ""
        print("[Account] ← result=%d http=%d body_len=%d preview=%s" % [result_code, http_code, body_bytes.size(), body_preview])
        
        if result_code != HTTPRequest.RESULT_SUCCESS:
                var err_map = {
                        HTTPRequest.RESULT_CANT_CONNECT: "Không thể kết nối server",
                        HTTPRequest.RESULT_CANT_RESOLVE: "Không phân giải được tên miền server",
                        HTTPRequest.RESULT_CONNECTION_ERROR: "Lỗi kết nối server",
                        HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR: "Lỗi TLS handshake — cert server không hợp lệ",
                        HTTPRequest.RESULT_TIMEOUT: "Hết thời gian chờ server",
                        HTTPRequest.RESULT_NO_RESPONSE: "Server không phản hồi",
                }
                var msg = err_map.get(result_code, "Lỗi mạng (result=%d)" % result_code)
                return {"error": msg}
        
        if http_code == 503:
                # Traefik trả 503 — thử fallback qua HTTPClient
                print("[Account] ⚠ HTTP 503 from proxy — trying HTTPClient fallback...")
                var fb = await _do_request_httpclient(path, method, body, with_auth)
                if not fb.has("error"):
                        return fb
                return {"error": "Server tạm thời không khả dụng (503). Thử lại sau giây lát."}
        
        if http_code != 200:
                var err_msg = String(parsed.get("error", "Lỗi HTTP %d" % http_code))
                return {"error": err_msg, "response_code": http_code}
        
        return parsed

## Fallback: dùng HTTPClient trực tiếp (bypass HTTPRequest wrapper)
## v4.3: Dùng HTTP (port 80) thay vì HTTPS vì Godot 4.7 mbedTLS không gửi SNI.
func _do_request_httpclient(path: String, method: int, body: String, with_auth: bool) -> Dictionary:
        var http = HTTPClient.new()
        # v4.3: HTTP (port 80) — không cần TLS
        var err = http.connect_to_host(SERVER_HOST, 80)
        if err != OK:
                return {"error": "HTTPClient connect failed: %d" % err}
        
        # Poll cho đến khi connected
        var t0 = Time.get_ticks_msec()
        while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
                http.poll()
                await get_tree().create_timer(0.05).timeout
                if Time.get_ticks_msec() - t0 > 10000:
                        http.close()
                        return {"error": "HTTPClient connect timeout"}
        
        if http.get_status() != HTTPClient.STATUS_CONNECTED:
                http.close()
                return {"error": "HTTPClient không kết nối được (status=%d)" % http.get_status()}
        
        # Gửi request
        var headers = PackedStringArray()
        headers.append("Host: " + SERVER_HOST)
        headers.append("Content-Type: application/json")
        headers.append("Accept: application/json")
        headers.append("Connection: close")
        if with_auth and not token.is_empty():
                headers.append("Authorization: Bearer " + token)
        var method_str = "GET"
        match method:
                HTTPClient.METHOD_POST: method_str = "POST"
                HTTPClient.METHOD_PUT: method_str = "PUT"
                HTTPClient.METHOD_DELETE: method_str = "DELETE"
        print("[Account] HTTPClient → %s %s" % [method_str, path])
        err = http.request(method, path, headers, body)
        if err != OK:
                http.close()
                return {"error": "HTTPClient request failed: %d" % err}
        
        # Poll cho response
        t0 = Time.get_ticks_msec()
        while http.get_status() == HTTPClient.STATUS_REQUESTING:
                http.poll()
                await get_tree().create_timer(0.05).timeout
                if Time.get_ticks_msec() - t0 > 15000:
                        http.close()
                        return {"error": "HTTPClient request timeout"}
        
        if not http.has_response():
                http.close()
                return {"error": "HTTPClient không nhận được response"}
        
        var http_code = http.get_response_code()
        print("[Account] HTTPClient ← http=%d" % http_code)
        
        # Đọc body
        var body_bytes = PackedByteArray()
        t0 = Time.get_ticks_msec()
        while http.get_status() == HTTPClient.STATUS_BODY:
                http.poll()
                var chunk = http.read_response_body_chunk()
                if chunk.size() > 0:
                        body_bytes.append_array(chunk)
                else:
                        await get_tree().create_timer(0.05).timeout
                if Time.get_ticks_msec() - t0 > 15000:
                        break
        
        http.close()
        
        var parsed = _parse_json(body_bytes)
        print("[Account] HTTPClient body: %s" % body_bytes.get_string_from_utf8().substr(0, 200))
        
        if http_code != 200:
                var err_msg = String(parsed.get("error", "Lỗi HTTP %d" % http_code))
                return {"error": err_msg, "response_code": http_code}
        
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
        print("[Account] ✓ Registered as %s (level %d)" % [current_user.get("username", "?"), current_user.get("level", 1)])

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
        print("[Account] ✓ Logged in as %s (level %d)" % [current_user.get("username", "?"), current_user.get("level", 1)])

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
                print("[Account] Token validation failed: %s — clearing session" % resp["error"])
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
                print("[Account] JSON parse failed for: %s" % text.substr(0, 200))
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
