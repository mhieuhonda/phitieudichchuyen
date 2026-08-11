extends Node

## AccountManager - Quản lý tài khoản người chơi (v4.4)
## Singleton autoload.
## - Đăng ký / đăng nhập qua REST API (http://phitieu.louis.vangioitutien.com/api/*)
## - Lưu token trong user://account.cfg
## - Cung cấp signals cho UI hook vào
## - Lấy profile + leaderboard qua HTTP
##
## v4.4 CRITICAL FIXES:
## - **DNS pre-resolve**: Tại startup gọi IP.resolve_hostname(SERVER_HOST) để verify
##   DNS. Nếu Godot 4.7 resolver trả IP (string), cache lại. Khi HTTPRequest fail với
##   RESULT_CANT_RESOLVE, retry ngay bằng URL http://<IP>/api/... + Host header.
##   Traefik route theo Host header → request vẫn tới backend, bypass DNS bug.
## - **Per-request HTTPRequest**: Bỏ pool (4 nodes) vì `cancel_request()` race
##   condition khiến request sau fail với CANT_RESOLVE. Mỗi request tạo 1 node
##   HTTPRequest mới, queue_free() sau khi xong. Đơn giản, không race.
## - **Bỏ manual Host header**: Godot tự set từ URL. Set thủ công gây conflict.
## - **Bỏ Connection: close**: Traefik + aiohttp giữ keep-alive mặc định tốt hơn.
## - **Bỏ set_tls_options() cho HTTP**: TLS options chỉ cần cho HTTPS. Set cho HTTP
##   là no-op nhưng có thể trigger mbedTLS init không cần thiết.
## - **Triple-layer fallback**: HTTPRequest(domain) → HTTPRequest(IP+Host) →
##   HTTPClient(IP+Host). Đảm bảo request tới được server.
## - **Better error messages**: Log full URL, IP, error code, response preview.
##
## v4.3 (giữ lại):
## - Godot 4.7 đã XÓA property `tls_options` trên HTTPRequest. Phải dùng
##   `_http_request.set_tls_options(...)` method.
## - Dùng HTTP (không TLS) cho REST API vì Godot 4.7's mbedTLS KHÔNG gửi SNI
##   trong TLS ClientHello → Traefik v3.6 trả 503. HTTPS vẫn available cho
##   browser/curl (gửi SNI đúng).

signal logged_in(user: Dictionary)
signal logged_out()
signal login_failed(reason: String)
signal register_failed(reason: String)
signal profile_updated(user: Dictionary)
signal level_up(old_level: int, new_level: int, new_title: String)
signal exp_gained(amount: int, total_exp: int)
signal leaderboard_loaded(entries: Array, online_count: int)

# Server URL — qua Traefik (http + domain)
# v4.4: Dùng HTTP vì Godot 4.7 mbedTLS không gửi SNI → Traefik trả 503 cho HTTPS.
# Coolify Traefik được config KHÔNG redirect HTTP→HTTPS nên HTTP hoạt động.
const API_BASE := "http://phitieu.louis.vangioitutien.com/api"
const WS_BASE := "ws://phitieu.louis.vangioitutien.com/ws"
const SAVE_PATH := "user://account.cfg"
const SERVER_HOST := "phitieu.louis.vangioitutien.com"
const SERVER_PORT := 80
const HTTP_TIMEOUT := 15.0

var token: String = ""
var current_user: Dictionary = {}  # id, username, display_name, title, level, exp, ...

# v4.4: Cached IP from pre-resolve. Empty if DNS hasn't been resolved yet.
# When HTTPRequest fails with CANT_RESOLVE, retry using this IP + Host header.
var _resolved_ip: String = ""
var _dns_check_done: bool = false

func _ready():
        # v4.4: Pre-resolve hostname at startup to verify DNS works.
        # This also primes Godot's internal DNS cache.
        _check_dns_resolution()
        print("[Account] v4.4 ready — API_BASE=%s, resolved_ip=%s" % [API_BASE, _resolved_ip if not _resolved_ip.is_empty() else "(pending)"])
        _load_session()

# === v4.4: DNS pre-resolution ===

func _check_dns_resolution():
        if _dns_check_done:
                return
        _dns_check_done = true
        print("[Account] Pre-resolving hostname: %s" % SERVER_HOST)
        # IP.resolve_hostname uses the system resolver (getaddrinfo).
        # In Godot 4.7, returns String (single IP) or "" on failure.
        var ip_str = IP.resolve_hostname(SERVER_HOST, IP.TYPE_IPV4)
        if not ip_str.is_empty():
                _resolved_ip = ip_str
                print("[Account] ✓ DNS resolved: %s → %s" % [SERVER_HOST, _resolved_ip])
        else:
                print("[Account] ✗ DNS resolution returned empty for %s — will retry in 2s" % SERVER_HOST)
                # Schedule a retry in 2s (network may not be ready on app start, esp. Android)
                get_tree().create_timer(2.0).timeout.connect(func():
                        var retry = IP.resolve_hostname(SERVER_HOST, IP.TYPE_IPV4)
                        if not retry.is_empty():
                                _resolved_ip = retry
                                print("[Account] ✓ DNS resolved (retry): %s → %s" % [SERVER_HOST, _resolved_ip])
                        else:
                                print("[Account] ✗ DNS still failing for %s — will use HTTPClient fallback on demand" % SERVER_HOST)
                )

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
        # v4.3 FIX: ConfigFile.clear() in Godot 4.7 takes 0 args.
        var cfg = ConfigFile.new()
        cfg.clear()
        cfg.save(SAVE_PATH)
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

# === v4.4: Per-request HTTPRequest factory ===

## Tạo một HTTPRequest mới, add làm child, return. Sau khi request xong,
## caller phải queue_free() nó. Tránh pool race condition.
func _make_http_request() -> HTTPRequest:
        var hr = HTTPRequest.new()
        hr.timeout = HTTP_TIMEOUT
        hr.accept_gzip = true
        # v4.4: KHÔNG set_tls_options() cho HTTP URL — TLS options chỉ cần cho HTTPS.
        # Set cho HTTP là no-op nhưng có thể trigger mbedTLS init không cần thiết,
        # và trong Godot 4.7 đôi khi gây ra trạng thái internal lạ.
        # (Nếu sau này đổi sang HTTPS, Uncomment dòng dưới:)
        # hr.set_tls_options(TLSOptions.client_unsafe())
        add_child(hr)
        return hr

# === Async HTTP request helper (v4.4: triple-layer fallback) ===

## Gọi REST API. Trả về: Dictionary có key "error" nếu thất bại, ngược lại là JSON parsed.
##
## Fallback chain (v4.4):
## 1. HTTPRequest với URL domain gốc (http://domain/api/...)
## 2. HTTPRequest với URL IP + Host header (http://<IP>/api/... + Host: domain)
## 3. HTTPClient trực tiếp với IP + Host header (low-level, bypass HTTPRequest)
##
## Fallback 2&3 chỉ trigger nếu #1 fail với CANT_RESOLVE (DNS bug).
func _do_request(path: String, method: int, body: String, with_auth: bool = false) -> Dictionary:
        var method_names = {
                HTTPClient.METHOD_GET: "GET",
                HTTPClient.METHOD_POST: "POST",
                HTTPClient.METHOD_PUT: "PUT",
                HTTPClient.METHOD_DELETE: "DELETE",
        }
        var method_str = method_names.get(method, str(method))
        print("[Account] → %s %s (body=%d bytes, auth=%s)" % [
                method_str, path, body.length(), with_auth and not token.is_empty(),
        ])

        # Layer 1: HTTPRequest with domain URL
        var result = await _do_request_httprequest(API_BASE + path, method, body, with_auth, false)
        if not result.has("error"):
                return result
        # If error is NOT DNS-related, return immediately
        var err_str = String(result["error"])
        var is_dns_error = err_str.find("phân giải") >= 0 or err_str.find("resolve") >= 0 or err_str.find("kết nối") >= 0 or err_str.find("connect") >= 0
        if not is_dns_error:
                return result

        print("[Account] ⚠ Layer 1 failed with DNS/connect error: %s" % err_str)
        # Re-check DNS (maybe network just came up)
        if _resolved_ip.is_empty():
                _check_dns_resolution()
                # Wait briefly for DNS
                await get_tree().create_timer(0.5).timeout

        if _resolved_ip.is_empty():
                print("[Account] ✗ Cannot resolve %s even after retry — giving up" % SERVER_HOST)
                return result  # original error

        # Layer 2: HTTPRequest with IP URL + Host header
        print("[Account] ↳ Layer 2: HTTPRequest via IP %s + Host header" % _resolved_ip)
        var result2 = await _do_request_httprequest("http://%s:%d/api%s" % [_resolved_ip, SERVER_PORT, path], method, body, with_auth, true)
        if not result2.has("error"):
                return result2

        print("[Account] ⚠ Layer 2 also failed: %s" % String(result2["error"]))
        # Layer 3: HTTPClient direct (bypass HTTPRequest wrapper entirely)
        print("[Account] ↳ Layer 3: HTTPClient direct via IP %s" % _resolved_ip)
        var result3 = await _do_request_httpclient(path, method, body, with_auth)
        if not result3.has("error"):
                return result3

        print("[Account] ✗ All 3 layers failed. Last error: %s" % String(result3.get("error", "?")))
        # Return the most informative error
        return {"error": "Không kết nối được server sau 3 lần thử. Chi tiết: %s" % String(result3.get("error", "?"))}

## Layer 1 & 2: HTTPRequest-based. If use_ip=true, URL contains IP and Host header is added.
func _do_request_httprequest(url: String, method: int, body: String, with_auth: bool, use_ip: bool) -> Dictionary:
        var hr = _make_http_request()
        var headers = PackedStringArray()
        headers.append("Content-Type: application/json")
        headers.append("Accept: application/json")
        # v4.4: Only add Host header when using IP (Traefik routes by Host header).
        # When using domain URL, Godot sets Host automatically — setting it manually
        # can conflict in some edge cases.
        if use_ip:
                headers.append("Host: " + SERVER_HOST)
        # v4.4: Removed "Connection: close" — let aiohttp/Traefik handle keep-alive.
        if with_auth and not token.is_empty():
                headers.append("Authorization: Bearer " + token)
        var err = hr.request(url, headers, method, body)
        if err != OK:
                hr.queue_free()
                print("[Account] ✗ HTTPRequest.request() failed: err=%d url=%s" % [err, url])
                return {"error": "Không thể gửi yêu cầu (code %d)" % err}
        var result_arr = await hr.request_completed
        # result_arr = [HTTPRequest.Result, response_code, PackedStringArray(headers), PackedByteArray(body)]
        var result_code = result_arr[0]
        var http_code = result_arr[1]
        var body_bytes = result_arr[3]
        var body_preview = body_bytes.get_string_from_utf8().substr(0, 200) if body_bytes else ""
        print("[Account] ← result=%d http=%d body_len=%d preview=%s" % [result_code, http_code, body_bytes.size(), body_preview])
        # Free the HTTPRequest now that we have the result
        hr.queue_free()

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
                # Traefik returns 503 when SNI missing (HTTPS) or when backend is down.
                # v4.4: With HTTP, 503 means backend is genuinely down — return error.
                return {"error": "Server tạm thời không khả dụng (503). Thử lại sau giây lát."}

        if http_code != 200:
                var parsed_err = _parse_json(body_bytes)
                var err_msg = String(parsed_err.get("error", "Lỗi HTTP %d" % http_code))
                return {"error": err_msg, "response_code": http_code}

        return _parse_json(body_bytes)

## Layer 3: HTTPClient direct (low-level). Bypasses HTTPRequest wrapper.
## Uses cached IP + Host header.
func _do_request_httpclient(path: String, method: int, body: String, with_auth: bool) -> Dictionary:
        if _resolved_ip.is_empty():
                return {"error": "Không có IP để fallback (DNS chưa resolve)"}
        var http = HTTPClient.new()
        # v4.4: Connect directly to the resolved IP (bypass DNS).
        var err = http.connect_to_host(_resolved_ip, SERVER_PORT)
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

        # Gửi request — path is the relative path (e.g., /api/login)
        var headers = PackedStringArray()
        headers.append("Host: " + SERVER_HOST)
        headers.append("Content-Type: application/json")
        headers.append("Accept: application/json")
        if with_auth and not token.is_empty():
                headers.append("Authorization: Bearer " + token)
        var method_str = "GET"
        match method:
                HTTPClient.METHOD_POST: method_str = "POST"
                HTTPClient.METHOD_PUT: method_str = "PUT"
                HTTPClient.METHOD_DELETE: method_str = "DELETE"
        print("[Account] HTTPClient → %s %s (via %s)" % [method_str, path, _resolved_ip])
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
# v4.4: KHÔNG dùng nữa — server tự award EXP qua end_game_after() task khi
# trận đấu kết thúc. Gọi API này sẽ gây DOUBLE EXP. Giữ lại hàm以防 cần
# (nhưng không gọi từ multiplayer_arena.gd nữa).
func submit_match_result(kills: int, score: int, won: bool):
        if token.is_empty():
                return  # silently skip — guest user
        print("[Account] ⚠ submit_match_result() is DEPRECATED in v4.4 — server auto-awards EXP. Ignoring call.")
        return
        # (legacy code below — kept for reference but unreachable)
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
