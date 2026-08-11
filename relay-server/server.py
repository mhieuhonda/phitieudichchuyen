# Phi Tiêu Dịch Chuyển — Multiplayer + Auth + Profile + Leaderboard Server (v4.2)
# Python aiohttp + asyncpg (PostgreSQL) + redis.
# Runs behind Traefik reverse proxy at https://phitieu.louis.vangioitutien.com
#
# Endpoints:
#     GET  /health                 → {"status": "ok"} (Coolify healthcheck)
#     GET  /                       → Info page (browser visits)
#     POST /api/register            → {username, password, display_name} → {token, user}
#     POST /api/login               → {username, password} → {token, user}
#     GET  /api/me                  → profile (requires Bearer token)
#     GET  /api/profile/{username}  → public profile
#     GET  /api/leaderboard         → top 100 players by level
#     POST /api/match_result        → submit match result (requires Bearer token)
#     WS   /ws?token=xxx            → Game protocol (JSON messages, optional auth)

"""
Phi Tiêu Dịch Chuyển — Server v4.2

Aiohttp server with:
  - PostgreSQL for persistent storage (users, sessions, match history)
  - Redis for online presence tracking
  - bcrypt password hashing
  - WebSocket game protocol (deathmatch rooms)
  - REST API for auth / profile / leaderboard
"""

import asyncio
import json
import logging
import random
import secrets
import string
import time
from datetime import date, datetime, timezone

import asyncpg
import bcrypt
import redis.asyncio as redis_async
from aiohttp import web, WSMsgType

# === Logging ===
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger("phitieu-server")

# === Constants ===
PORT = 3000
MAX_PLAYERS_PER_ROOM = 4
GAME_DURATION_SEC = 180  # 3 minutes
RESPAWN_TIME_SEC = 3.0
INITIAL_HP = 100
ARENA_W = 1280.0
ARENA_H = 720.0

# Token expiry (30 days)
TOKEN_TTL_SEC = 30 * 24 * 3600

# EXP curve: total EXP to reach level N = 50 * (N-1) * N
# i.e. level 1->2 needs 100, 2->3 needs 200, 3->4 needs 300, ...
def total_exp_for_level(level: int) -> int:
    """Total accumulated EXP needed to be AT this level (level 1 = 0 exp)."""
    if level <= 1:
        return 0
    return 50 * (level - 1) * level

def level_from_exp(exp: int) -> int:
    """Given accumulated EXP, return current level (>=1)."""
    # Solve 50 * (N-1) * N <= exp  →  N^2 - N - exp/50 <= 0
    # N = (1 + sqrt(1 + 4*exp/50)) / 2
    import math
    if exp <= 0:
        return 1
    n = (1 + math.sqrt(1 + 4 * exp / 50.0)) / 2.0
    return max(1, int(n))

def exp_to_next_level(current_level: int, current_exp: int) -> int:
    """EXP needed to advance from current state to next level."""
    next_total = total_exp_for_level(current_level + 1)
    return max(0, next_total - current_exp)

def exp_progress_pct(current_level: int, current_exp: int) -> float:
    """Percent progress (0..1) from this level to next."""
    base = total_exp_for_level(current_level)
    target = total_exp_for_level(current_level + 1)
    if target <= base:
        return 0.0
    return (current_exp - base) / float(target - base)

# Title system (danh hiệu) — based on level
def title_for_level(level: int) -> str:
    if level >= 100:
        return "Huyền Thoại"
    if level >= 50:
        return "Tông Sư"
    if level >= 20:
        return "Cao Thủ"
    if level >= 10:
        return "Tinh Anh"
    if level >= 5:
        return "Chiến Binh"
    return "Tân Binh"

# === Database / Redis connection ===
DB_DSN = "postgres://postgres:LouisTruyen2026Secure%21@exrf901linq3xhpif30c15ow:5432/postgres"
REDIS_URL = "redis://default:RedisLouis2026Secure%21@xa6aizv6utmwr57humdkuzzg:6379/0"

db_pool: asyncpg.Pool | None = None
redis_client: redis_async.Redis | None = None

async def init_db():
    """Create tables if they don't exist. Non-fatal: server starts even if DB fails."""
    global db_pool, redis_client
    try:
        db_pool = await asyncpg.create_pool(
            dsn=DB_DSN,
            min_size=1,
            max_size=8,
            command_timeout=30.0,
        )
        async with db_pool.acquire() as conn:
            await conn.execute("SELECT 1")
            log.info("Connected to PostgreSQL")
    except Exception as e:
        log.error(f"PostgreSQL connection FAILED: {e}")
        db_pool = None
        # Don't return — try Redis, server will start but DB endpoints will fail
    try:
        redis_client = redis_async.from_url(REDIS_URL, decode_responses=True)
        await redis_client.ping()
        log.info("Connected to Redis")
    except Exception as e:
        log.error(f"Redis connection FAILED: {e}")
        redis_client = None
    # Create schema (skip if DB unavailable)
    if db_pool is None:
        log.warning("Database unavailable — server starting in degraded mode (REST API will return 503)")
        return
    schema_statements = [
        """CREATE TABLE IF NOT EXISTS phitieu_users (
            id BIGSERIAL PRIMARY KEY,
            username VARCHAR(32) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            display_name VARCHAR(32) NOT NULL,
            title VARCHAR(64) NOT NULL DEFAULT 'Tan Binh',
            level INTEGER NOT NULL DEFAULT 1,
            exp INTEGER NOT NULL DEFAULT 0,
            online_streak INTEGER NOT NULL DEFAULT 0,
            last_login_date DATE,
            last_seen_at TIMESTAMPTZ,
            total_matches INTEGER NOT NULL DEFAULT 0,
            total_wins INTEGER NOT NULL DEFAULT 0,
            total_kills INTEGER NOT NULL DEFAULT 0,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )""",
        """CREATE TABLE IF NOT EXISTS phitieu_sessions (
            token VARCHAR(64) PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES phitieu_users(id) ON DELETE CASCADE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            expires_at TIMESTAMPTZ NOT NULL
        )""",
        """CREATE TABLE IF NOT EXISTS phitieu_match_history (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES phitieu_users(id) ON DELETE CASCADE,
            match_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            kills INTEGER NOT NULL DEFAULT 0,
            score INTEGER NOT NULL DEFAULT 0,
            won BOOLEAN NOT NULL DEFAULT FALSE,
            exp_gained INTEGER NOT NULL DEFAULT 0
        )""",
        "CREATE INDEX IF NOT EXISTS idx_phitieu_users_level ON phitieu_users(level DESC, exp DESC)",
        "CREATE INDEX IF NOT EXISTS idx_phitieu_sessions_user ON phitieu_sessions(user_id)",
        "CREATE INDEX IF NOT EXISTS idx_phitieu_match_history_user ON phitieu_match_history(user_id, match_date DESC)",
    ]
    async with db_pool.acquire() as conn:
        for i, stmt in enumerate(schema_statements):
            try:
                await conn.execute(stmt)
                log.info(f"Schema statement {i+1}/{len(schema_statements)} OK")
            except Exception as e:
                log.error(f"Schema statement {i+1} FAILED: {e}")
                log.error(f"Statement: {stmt[:200]}")
                # Continue with other statements
        log.info("Database schema initialization complete")

async def close_db():
    global db_pool, redis_client
    if redis_client:
        await redis_client.close()
    if db_pool:
        await db_pool.close()

# === Globals ===
clients: dict = {}  # websocket -> Client
rooms: dict = {}    # room_id -> Room
next_player_id = 1

def generate_room_id() -> str:
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=5))

def random_spawn_pos() -> tuple:
    return (
        random.uniform(100, ARENA_W - 100),
        random.uniform(100, ARENA_H - 100),
    )

# === Auth helpers ===

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")

def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))
    except Exception:
        return False

def generate_token() -> str:
    return secrets.token_urlsafe(48)

async def get_user_by_token(token: str) -> dict | None:
    if not token or not db_pool:
        return None
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow("""
            SELECT u.* FROM phitieu_users u
            JOIN phitieu_sessions s ON s.user_id = u.id
            WHERE s.token = $1 AND s.expires_at > NOW()
        """, token)
        return dict(row) if row else None

async def create_session(user_id: int) -> str:
    token = generate_token()
    async with db_pool.acquire() as conn:
        await conn.execute("""
            INSERT INTO phitieu_sessions (token, user_id, expires_at)
            VALUES ($1, $2, NOW() + INTERVAL '%d seconds')
        """ % TOKEN_TTL_SEC, token, user_id)
    return token

async def delete_session(token: str):
    async with db_pool.acquire() as conn:
        await conn.execute("DELETE FROM phitieu_sessions WHERE token = $1", token)

async def update_login_streak(user_id: int) -> int:
    """Update online streak; returns new streak value."""
    today = date.today()
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT last_login_date, online_streak FROM phitieu_users WHERE id = $1", user_id
        )
        if not row:
            return 0
        last = row["last_login_date"]
        streak = int(row["online_streak"] or 0)
        if last is None:
            streak = 1
        elif last == today:
            pass  # already logged in today
        else:
            # Streak continues if last login was yesterday, else reset
            from datetime import timedelta
            if last == today - timedelta(days=1):
                streak += 1
            else:
                streak = 1
        await conn.execute(
            "UPDATE phitieu_users SET last_login_date = $1, online_streak = $2 WHERE id = $3",
            today, streak, user_id,
        )
        return streak

async def refresh_user_seen(user_id: int):
    """Mark user as just seen (called when WS connects or HTTP request)."""
    if redis_client:
        await redis_client.sadd("online_users", str(user_id))
        await redis_client.set(f"user_seen:{user_id}", int(time.time()), ex=120)
    if db_pool:
        async with db_pool.acquire() as conn:
            await conn.execute(
                "UPDATE phitieu_users SET last_seen_at = NOW() WHERE id = $1", user_id
            )

async def is_user_online(user_id: int) -> bool:
    if not redis_client:
        return False
    return await redis_client.exists(f"user_seen:{user_id}") > 0

async def remove_user_online(user_id: int):
    if redis_client:
        await redis_client.srem("online_users", str(user_id))
        await redis_client.delete(f"user_seen:{user_id}")

async def get_online_count() -> int:
    if not redis_client:
        return 0
    return await redis_client.scard("online_users")

# === Auth middleware / decorator ===

async def get_auth_user(request: web.Request) -> dict | None:
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        token = auth[7:]
        return await get_user_by_token(token)
    return None

def require_auth(handler):
    async def wrapper(request: web.Request):
        user = await get_auth_user(request)
        if not user:
            return web.json_response({"error": "Unauthorized"}, status=401)
        request["user"] = user
        return await handler(request)
    return wrapper

def user_to_public_dict(user: dict) -> dict:
    return {
        "id": int(user["id"]),
        "username": str(user["username"]),
        "display_name": str(user["display_name"]),
        "title": str(user["title"]),
        "level": int(user["level"]),
        "exp": int(user["exp"]),
        "exp_to_next": exp_to_next_level(int(user["level"]), int(user["exp"])),
        "exp_progress_pct": round(exp_progress_pct(int(user["level"]), int(user["exp"])) * 100, 1),
        "online_streak": int(user["online_streak"] or 0),
        "total_matches": int(user["total_matches"]),
        "total_wins": int(user["total_wins"]),
        "total_kills": int(user["total_kills"]),
        "win_rate": round(int(user["total_wins"]) / max(1, int(user["total_matches"])) * 100, 1),
    }

# === REST endpoints ===

async def health_handler(request: web.Request) -> web.Response:
    # v4.1: Healthcheck must NOT depend on Redis/PG — just verify HTTP server is up
    return web.json_response({
        "status": "ok",
        "service": "phitieu-multiplayer",
        "version": "4.2",
        "db_ready": db_pool is not None,
        "redis_ready": redis_client is not None,
        "clients_online": len(clients),
        "rooms_active": len(rooms),
    })

async def index_handler(request: web.Request) -> web.Response:
    online = await get_online_count()
    room_list_html = ""
    if rooms:
        items = []
        for r in list(rooms.values())[:10]:
            items.append(
                f"<li><b>{r.name}</b> (id: <code>{r.id}</code>) "
                f"— {r.player_count}/{MAX_PLAYERS_PER_ROOM} người — {r.status}</li>"
            )
        room_list_html = "<ul>" + "".join(items) + "</ul>"
    else:
        room_list_html = "<p><i>Chưa có phòng nào. Mở game và tạo phòng!</i></p>"

    html = f"""<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8">
<title>Phi Tiêu Dịch Chuyển — Server v4.2</title>
<style>
body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
       background: linear-gradient(135deg, #0a0a18 0%, #1a1a2e 100%);
       color: #e0e0e8; padding: 40px 20px; margin: 0; min-height: 100vh; }}
.container {{ max-width: 760px; margin: 0 auto; background: rgba(20, 22, 36, 0.7); padding: 36px;
              border-radius: 16px; border: 1px solid rgba(255, 170, 0, 0.2);
              box-shadow: 0 8px 32px rgba(0,0,0,0.4); }}
h1 {{ color: #ffaa00; text-shadow: 0 2px 8px rgba(255, 170, 0, 0.4); margin: 0 0 8px; font-size: 32px; }}
h2 {{ color: #4afcff; margin-top: 28px; font-size: 20px; }}
.subtitle {{ color: #888; margin-bottom: 24px; font-size: 14px; }}
code {{ background: rgba(255,255,255,0.08); padding: 2px 6px; border-radius: 4px; color: #aaffaa;
        font-family: 'SF Mono', Menlo, Consolas, monospace; }}
.stats {{ background: rgba(74, 252, 255, 0.06); border-left: 3px solid #4afcff; padding: 14px 18px;
          margin: 16px 0; border-radius: 6px; font-family: 'SF Mono', Menlo, Consolas, monospace;
          font-size: 14px; line-height: 1.7; }}
ul {{ line-height: 1.9; padding-left: 20px; }}
.footer {{ margin-top: 28px; padding-top: 16px; border-top: 1px solid rgba(255,255,255,0.08);
           color: #666; font-size: 12px; text-align: center; }}
.status-ok {{ color: #44ff88; font-weight: bold; }}
</style>
</head>
<body>
<div class="container">
    <h1>🎯 Phi Tiêu Dịch Chuyển — Server v4.2</h1>
    <div class="subtitle">Multiplayer + Auth + Profile + Leaderboard</div>
    <p>Server backend cho game <b>Phi Tiêu Dịch Chuyển v4.2</b>. Bao gồm:</p>
    <ul>
        <li>🌐 WebSocket deathmatch (rooms 2-4 người, 3 phút/match)</li>
        <li>🔐 Đăng ký / đăng nhập (bcrypt + token)</li>
        <li>👤 Hồ sơ người chơi (danh hiệu, level, chuỗi online)</li>
        <li>📊 Bảng xếp hạng top 100 theo level</li>
        <li>⭐ Hệ thống EXP — không giới hạn level</li>
    </ul>

    <h2>📡 Trạng thái server</h2>
    <div class="stats">
        Status: <span class="status-ok">✓ ONLINE</span><br>
        Clients đang kết nối (WS): <b>{len(clients)}</b><br>
        Người dùng online: <b>{online}</b><br>
        Phòng active: <b>{len(rooms)}</b><br>
        Tối đa mỗi phòng: <b>{MAX_PLAYERS_PER_ROOM}</b> người<br>
        Thời lượng mỗi trận: <b>{GAME_DURATION_SEC}s</b> (3 phút)
    </div>

    <h2>🏠 Phòng đang hoạt động</h2>
    {room_list_html}

    <h2>🔌 Endpoints</h2>
    <div class="stats">
        REST API: <code>https://phitieu.louis.vangioitutien.com/api/...</code><br>
        WebSocket: <code>wss://phitieu.louis.vangioitutien.com/ws?token=TOKEN</code><br>
        Database: PostgreSQL 16 + Redis 7.2<br>
        Auth: bcrypt + 30-day token
    </div>

    <div class="footer">
        Phi Tiêu Dịch Chuyển v4.2 — by Hieu Louis<br>
        Backend: Python aiohttp · DB: PostgreSQL 16 · Cache: Redis 7.2 · Proxy: Traefik v3.6 + TLS
    </div>
</div>
</body>
</html>"""
    return web.Response(text=html, content_type="text/html")

async def api_register(request: web.Request) -> web.Response:
    try:
        data = await request.json()
    except Exception:
        return web.json_response({"error": "Invalid JSON"}, status=400)
    username = str(data.get("username", "")).strip().lower()
    password = str(data.get("password", ""))
    display_name = str(data.get("display_name", "")).strip()
    # Validate
    if len(username) < 3 or len(username) > 32:
        return web.json_response({"error": "Tên đăng nhập phải 3-32 ký tự"}, status=400)
    if not username.replace("_", "").replace(".", "").isalnum():
        return web.json_response({"error": "Tên đăng nhập chỉ chứa chữ cái, số, dấu _ và ."}, status=400)
    if len(password) < 6:
        return web.json_response({"error": "Mật khẩu phải ít nhất 6 ký tự"}, status=400)
    if not display_name:
        display_name = username
    if len(display_name) > 32:
        display_name = display_name[:32]
    # Check username exists
    async with db_pool.acquire() as conn:
        existing = await conn.fetchval("SELECT id FROM phitieu_users WHERE username = $1", username)
        if existing:
            return web.json_response({"error": "Tên đăng nhập đã tồn tại"}, status=409)
        # Create user
        pw_hash = hash_password(password)
        # Use parameter binding for Vietnamese title (safe with asyncpg UTF-8)
        row = await conn.fetchrow("""
            INSERT INTO phitieu_users (username, password_hash, display_name, title)
            VALUES ($1, $2, $3, $4)
            RETURNING id, username, display_name, title, level, exp, online_streak,
                      total_matches, total_wins, total_kills
        """, username, pw_hash, display_name, "Tân Binh")
    user = dict(row)
    await update_login_streak(user["id"])
    await refresh_user_seen(user["id"])
    token = await create_session(user["id"])
    log.info(f"User registered: {username} (id={user['id']})")
    return web.json_response({"token": token, "user": user_to_public_dict(user)})

async def api_login(request: web.Request) -> web.Response:
    try:
        data = await request.json()
    except Exception:
        return web.json_response({"error": "Invalid JSON"}, status=400)
    username = str(data.get("username", "")).strip().lower()
    password = str(data.get("password", ""))
    if not username or not password:
        return web.json_response({"error": "Thiếu tên đăng nhập hoặc mật khẩu"}, status=400)
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow("""
            SELECT id, username, password_hash, display_name, title, level, exp,
                   online_streak, last_login_date, total_matches, total_wins, total_kills
            FROM phitieu_users WHERE username = $1
        """, username)
    if not row or not verify_password(password, row["password_hash"]):
        return web.json_response({"error": "Sai tên đăng nhập hoặc mật khẩu"}, status=401)
    user = dict(row)
    await update_login_streak(user["id"])
    await refresh_user_seen(user["id"])
    token = await create_session(user["id"])
    log.info(f"User login: {username} (id={user['id']})")
    return web.json_response({"token": token, "user": user_to_public_dict(user)})

@require_auth
async def api_me(request: web.Request) -> web.Response:
    user = request["user"]
    # Refresh streak / seen
    await update_login_streak(user["id"])
    await refresh_user_seen(user["id"])
    # Re-fetch (streak may have changed)
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow("""
            SELECT id, username, display_name, title, level, exp, online_streak,
                   total_matches, total_wins, total_kills
            FROM phitieu_users WHERE id = $1
        """, user["id"])
    return web.json_response({"user": user_to_public_dict(dict(row))})

@require_auth
async def api_logout(request: web.Request) -> web.Response:
    auth = request.headers.get("Authorization", "")
    token = auth[7:] if auth.startswith("Bearer ") else ""
    if token:
        await delete_session(token)
    await remove_user_online(request["user"]["id"])
    return web.json_response({"ok": True})

async def api_profile(request: web.Request) -> web.Response:
    username = request.match_info["username"].strip().lower()
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow("""
            SELECT id, username, display_name, title, level, exp, online_streak,
                   total_matches, total_wins, total_kills
            FROM phitieu_users WHERE username = $1
        """, username)
    if not row:
        return web.json_response({"error": "Không tìm thấy người chơi"}, status=404)
    pub = user_to_public_dict(dict(row))
    pub["online"] = await is_user_online(pub["id"])
    return web.json_response({"user": pub})

async def api_leaderboard(request: web.Request) -> web.Response:
    try:
        limit = int(request.query.get("limit", "100"))
    except ValueError:
        limit = 100
    limit = max(1, min(100, limit))
    async with db_pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT id, username, display_name, title, level, exp, online_streak,
                   total_matches, total_wins, total_kills
            FROM phitieu_users
            ORDER BY level DESC, exp DESC, total_wins DESC
            LIMIT $1
        """, limit)
    leaderboard = []
    for i, row in enumerate(rows, 1):
        u = user_to_public_dict(dict(row))
        u["rank"] = i
        leaderboard.append(u)
    online_count = await get_online_count()
    return web.json_response({
        "leaderboard": leaderboard,
        "online_count": online_count,
    })

@require_auth
async def api_match_result(request: web.Request) -> web.Response:
    """Submit match result and award EXP. Body: {kills, score, won}"""
    try:
        data = await request.json()
    except Exception:
        return web.json_response({"error": "Invalid JSON"}, status=400)
    user = request["user"]
    kills = int(data.get("kills", 0))
    score = int(data.get("score", 0))
    won = bool(data.get("won", False))
    # EXP calculation:
    #   base 10 for participating
    #   +5 per kill
    #   +20 for winning
    #   +score bonus (score/4)
    exp_gained = 10 + kills * 5 + (20 if won else 0) + score // 4
    if exp_gained < 0:
        exp_gained = 0
    async with db_pool.acquire() as conn:
        async with conn.transaction():
            row = await conn.fetchrow("""
                UPDATE phitieu_users
                SET exp = exp + $1,
                    level = GREATEST(level, 1),
                    total_matches = total_matches + 1,
                    total_kills = total_kills + $2,
                    total_wins = total_wins + $3
                WHERE id = $4
                RETURNING exp, level, total_matches, total_kills, total_wins
            """, exp_gained, kills, 1 if won else 0, user["id"])
            # Recompute level from total exp
            new_exp = int(row["exp"])
            new_level = level_from_exp(new_exp)
            new_title = title_for_level(new_level)
            await conn.execute("""
                UPDATE phitieu_users SET level = $1, title = $2 WHERE id = $3
            """, new_level, new_title, user["id"])
            # Save match history
            await conn.execute("""
                INSERT INTO phitieu_match_history (user_id, kills, score, won, exp_gained)
                VALUES ($1, $2, $3, $4, $5)
            """, user["id"], kills, score, won, exp_gained)
            # Fetch full updated user
            row2 = await conn.fetchrow("""
                SELECT id, username, display_name, title, level, exp, online_streak,
                       total_matches, total_wins, total_kills
                FROM phitieu_users WHERE id = $1
            """, user["id"])
    pub = user_to_public_dict(dict(row2))
    leveled_up = new_level > int(user["level"])
    log.info(f"Match result: user={user['username']} kills={kills} score={score} won={won} exp+={exp_gained} new_level={new_level}")
    return web.json_response({
        "user": pub,
        "exp_gained": exp_gained,
        "leveled_up": leveled_up,
        "new_level": new_level,
        "new_title": new_title if leveled_up else None,
    })

# === Client / Room classes ===

class Client:
    def __init__(self, ws: web.WebSocketResponse):
        global next_player_id
        self.ws = ws
        self.player_id = next_player_id
        next_player_id += 1
        self.name = f"Player{self.player_id}"
        self.user: dict | None = None  # authenticated user (from token)
        self.room: "Room | None" = None
        self.hp = INITIAL_HP
        self.score = 0
        self.kills = 0
        self.alive = True
        self.pos_x, self.pos_y = random_spawn_pos()
        self.last_seen = time.time()
        self.dart_id_counter = 0

    def to_public_dict(self) -> dict:
        return {
            "id": self.player_id,
            "name": self.name,
            "pos_x": self.pos_x,
            "pos_y": self.pos_y,
            "hp": self.hp,
            "score": self.score,
            "alive": self.alive,
            "level": int(self.user["level"]) if self.user else 0,
            "title": str(self.user["title"]) if self.user else "",
            "authenticated": self.user is not None,
        }

    async def send(self, msg: dict):
        try:
            await self.ws.send_str(json.dumps(msg))
        except Exception as e:
            log.warning(f"Send failed to player {self.player_id}: {e}")

    async def send_error(self, message: str):
        await self.send({"type": "error", "message": message})

class Room:
    def __init__(self, room_id: str, name: str, host: Client):
        self.id = room_id
        self.name = name
        self.host = host
        self.clients: list[Client] = [host]
        self.status = "lobby"
        self.game_start_time: float = 0
        self.game_end_task: asyncio.Task | None = None
        self.dart_owners: dict = {}

    @property
    def player_count(self) -> int:
        return len(self.clients)

    def is_full(self) -> bool:
        return len(self.clients) >= MAX_PLAYERS_PER_ROOM

    def add_client(self, client: Client):
        if self.is_full():
            return False
        self.clients.append(client)
        client.room = self
        return True

    def remove_client(self, client: Client):
        if client in self.clients:
            self.clients.remove(client)
        client.room = None
        if not self.clients:
            return True
        if self.host is client and self.clients:
            self.host = self.clients[0]
        return False

    def to_public_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "player_count": self.player_count,
            "status": self.status,
        }

    async def broadcast(self, msg: dict, exclude: Client | None = None):
        dead = []
        for c in self.clients:
            if c is exclude:
                continue
            try:
                await c.ws.send_str(json.dumps(msg))
            except Exception:
                dead.append(c)
        for c in dead:
            await self._handle_disconnect(c)

    async def _handle_disconnect(self, client: Client):
        if client in self.clients:
            self.clients.remove(client)
            await self.broadcast({
                "type": "player_left",
                "player_id": client.player_id,
            })
            if self.host is client and self.clients:
                self.host = self.clients[0]
            if not self.clients:
                rooms.pop(self.id, None)
                if self.game_end_task:
                    self.game_end_task.cancel()
                    self.game_end_task = None

# === WebSocket handler ===

async def ws_handler(request: web.Request) -> web.WebSocketResponse:
    ws = web.WebSocketResponse(heartbeat=30, max_msg_size=65536)
    await ws.prepare(request)

    client = Client(ws)
    clients[ws] = client

    # Optional auth via query string ?token=...
    token = request.query.get("token", "")
    if token:
        user = await get_user_by_token(token)
        if user:
            client.user = user
            client.name = user["display_name"] or user["username"]
            await refresh_user_seen(user["id"])
            log.info(f"WS auth: user={user['username']} (id={user['id']}) → player_id={client.player_id}")
        else:
            await client.send({"type": "auth_failed", "message": "Token không hợp lệ hoặc đã hết hạn. Bạn vẫn có thể chơi nhưng không nhận EXP."})

    log.info(f"Client connected: player_id={client.player_id} (total: {len(clients)})")

    await client.send({
        "type": "hello",
        "player_id": client.player_id,
        "authenticated": client.user is not None,
        "user": user_to_public_dict(client.user) if client.user else None,
    })

    try:
        async for msg in ws:
            if msg.type == WSMsgType.TEXT:
                try:
                    data = json.loads(msg.data)
                except json.JSONDecodeError:
                    continue
                client.last_seen = time.time()
                await handle_message(client, data)
            elif msg.type == WSMsgType.PING:
                await ws.pong()
            elif msg.type == WSMsgType.ERROR:
                log.error(f"WS error for player {client.player_id}: {ws.exception()}")
                break
    finally:
        await cleanup_client(client)
        clients.pop(ws, None)
        if client.user:
            await remove_user_online(client.user["id"])
        log.info(f"Client disconnected: player_id={client.player_id} (remaining: {len(clients)})")

    return ws

async def handle_message(client: Client, msg: dict):
    msg_type = msg.get("type", "")

    if msg_type == "ping":
        await client.send({"type": "pong"})
        return

    if msg_type == "set_name":
        # Allow setting name (for guests without account)
        if not client.user:
            name = str(msg.get("name", ""))[:32]
            if name:
                client.name = name
        return

    if msg_type == "chat" and client.room:
        text = str(msg.get("message", ""))[:200]
        if text:
            await client.room.broadcast({
                "type": "chat",
                "sender_id": client.player_id,
                "sender_name": client.name,
                "message": text,
            })
        return

    if msg_type == "list_rooms":
        room_list = [r.to_public_dict() for r in rooms.values()]
        await client.send({
            "type": "room_list",
            "rooms": room_list,
        })
        return

    if msg_type == "create_room":
        if client.room:
            await client.send_error("Bạn đang ở trong phòng rồi")
            return
        room_name = str(msg.get("name", ""))[:32]
        if not room_name:
            room_name = f"Phòng của {client.name}"
        room_id = generate_room_id()
        while room_id in rooms:
            room_id = generate_room_id()
        room = Room(room_id, room_name, client)
        rooms[room_id] = room
        client.room = room
        log.info(f"Room created: id={room_id} name={room_name} host={client.name}")
        await client.send({
            "type": "room_joined",
            "room_id": room_id,
            "players": [client.to_public_dict()],
        })
        return

    if msg_type == "join_room":
        if client.room:
            await client.send_error("Bạn đang ở trong phòng rồi")
            return
        room_id = str(msg.get("room_id", ""))
        if room_id not in rooms:
            await client.send_error("Phòng không tồn tại")
            return
        room = rooms[room_id]
        if room.is_full():
            await client.send_error("Phòng đã đủ 4 người")
            return
        if room.status == "playing":
            await client.send_error("Phòng đang chơi, không thể vào")
            return
        room.add_client(client)
        log.info(f"Player {client.name} joined room {room_id}")
        await room.broadcast({
            "type": "player_joined",
            "player_id": client.player_id,
            "name": client.name,
            "player": client.to_public_dict(),
        }, exclude=client)
        await client.send({
            "type": "room_joined",
            "room_id": room_id,
            "players": [c.to_public_dict() for c in room.clients],
        })
        return

    if msg_type == "leave_room":
        await leave_room(client)
        return

    if msg_type == "start_game":
        if not client.room:
            await client.send_error("Bạn chưa vào phòng")
            return
        if client.room.host is not client:
            await client.send_error("Chỉ host mới được bắt đầu game")
            return
        if client.room.player_count < 1:
            await client.send_error("Cần ít nhất 1 người để bắt đầu")
            return
        await start_game(client.room)
        return

    if not client.room:
        await client.send_error("Bạn chưa vào phòng")
        return

    if msg_type == "player_state":
        client.pos_x = float(msg.get("pos_x", client.pos_x))
        client.pos_y = float(msg.get("pos_y", client.pos_y))
        client.hp = int(msg.get("hp", client.hp))
        client.score = int(msg.get("score", client.score))
        client.alive = bool(msg.get("alive", client.alive))
        await client.room.broadcast({
            "type": "player_state",
            "player_id": client.player_id,
            "pos_x": client.pos_x,
            "pos_y": client.pos_y,
            "hp": client.hp,
            "score": client.score,
            "alive": client.alive,
        }, exclude=client)
        return

    if msg_type == "dart_spawn":
        dart_id = int(msg.get("dart_id", 0))
        client.dart_id_counter = max(client.dart_id_counter, dart_id)
        client.room.dart_owners[dart_id] = client.player_id
        await client.room.broadcast({
            "type": "dart_spawn",
            "dart_id": dart_id,
            "owner_id": client.player_id,
            "pos_x": float(msg.get("pos_x", 0)),
            "pos_y": float(msg.get("pos_y", 0)),
            "vel_x": float(msg.get("vel_x", 0)),
            "vel_y": float(msg.get("vel_y", 0)),
        }, exclude=client)
        return

    if msg_type == "dart_remove":
        dart_id = int(msg.get("dart_id", 0))
        client.room.dart_owners.pop(dart_id, None)
        await client.room.broadcast({
            "type": "dart_remove",
            "dart_id": dart_id,
        }, exclude=client)
        return

    if msg_type == "hit":
        victim_id = int(msg.get("victim_id", -1))
        damage = int(msg.get("damage", 0))
        if victim_id < 0 or damage <= 0:
            return
        victim = None
        for c in client.room.clients:
            if c.player_id == victim_id:
                victim = c
                break
        if not victim or not victim.alive:
            return
        victim.hp = max(0, victim.hp - damage)
        log.info(f"Player {client.player_id} hit player {victim_id} for {damage} (hp now {victim.hp})")
        await client.room.broadcast({
            "type": "hit",
            "victim_id": victim_id,
            "killer_id": client.player_id,
            "damage": damage,
        })
        if victim.hp <= 0:
            victim.alive = False
            if victim is not client:
                client.score += 1
                client.kills += 1
            await client.room.broadcast({
                "type": "player_died",
                "victim_id": victim_id,
                "killer_id": client.player_id,
            })
            log.info(f"Player {victim_id} died by player {client.player_id}")
        return

    if msg_type == "respawn":
        if client.alive:
            return
        client.alive = True
        client.hp = INITIAL_HP
        client.pos_x, client.pos_y = random_spawn_pos()
        await client.room.broadcast({
            "type": "player_respawned",
            "player_id": client.player_id,
            "pos_x": client.pos_x,
            "pos_y": client.pos_y,
        })
        return

async def leave_room(client: Client):
    if not client.room:
        await client.send({"type": "room_left"})
        return
    room = client.room
    room_empty = room.remove_client(client)
    await client.send({"type": "room_left"})
    await room.broadcast({
        "type": "player_left",
        "player_id": client.player_id,
    })
    if room_empty:
        rooms.pop(room.id, None)
        if room.game_end_task:
            room.game_end_task.cancel()
            room.game_end_task = None
        log.info(f"Room {room.id} deleted (empty)")

async def start_game(room: Room):
    if room.status == "playing":
        return
    room.status = "playing"
    room.game_start_time = time.time()
    for c in room.clients:
        c.hp = INITIAL_HP
        c.score = 0
        c.kills = 0
        c.alive = True
        c.pos_x, c.pos_y = random_spawn_pos()
    players = [c.to_public_dict() for c in room.clients]
    await room.broadcast({
        "type": "game_start",
        "players": players,
    })
    log.info(f"Game started in room {room.id} with {len(room.clients)} players")
    room.game_end_task = asyncio.create_task(end_game_after(room, GAME_DURATION_SEC))

async def end_game_after(room: Room, delay: float):
    try:
        await asyncio.sleep(delay)
    except asyncio.CancelledError:
        return
    if room.status != "playing":
        return
    room.status = "lobby"
    scores = {}
    kills_map = {}
    for c in room.clients:
        scores[c.player_id] = c.score
        kills_map[c.player_id] = c.kills
    await room.broadcast({
        "type": "game_end",
        "scores": scores,
        "kills": kills_map,
    })
    log.info(f"Game ended in room {room.id}. Scores: {scores}")
    room.game_end_task = None

    # Award EXP for authenticated users
    if not db_pool:
        return
    for c in room.clients:
        if not c.user:
            continue
        score = c.score
        kills = c.kills
        won = False
        # Determine winner: highest score
        max_score = max(scores.values()) if scores else 0
        if max_score > 0 and c.score == max_score:
            won = True
        exp_gained = 10 + kills * 5 + (20 if won else 0) + score // 4
        if exp_gained <= 0:
            continue
        try:
            async with db_pool.acquire() as conn:
                async with conn.transaction():
                    row = await conn.fetchrow("""
                        UPDATE phitieu_users
                        SET exp = exp + $1,
                            total_matches = total_matches + 1,
                            total_kills = total_kills + $2,
                            total_wins = total_wins + $3
                        WHERE id = $4
                        RETURNING exp
                    """, exp_gained, kills, 1 if won else 0, c.user["id"])
                    if row:
                        new_exp = int(row["exp"])
                        new_level = level_from_exp(new_exp)
                        new_title = title_for_level(new_level)
                        old_level = int(c.user["level"])
                        await conn.execute("""
                            UPDATE phitieu_users SET level = $1, title = $2 WHERE id = $3
                        """, new_level, new_title, c.user["id"])
                        await conn.execute("""
                            INSERT INTO phitieu_match_history (user_id, kills, score, won, exp_gained)
                            VALUES ($1, $2, $3, $4, $5)
                        """, c.user["id"], kills, score, won, exp_gained)
                        if new_level > old_level:
                            await c.send({
                                "type": "level_up",
                                "old_level": old_level,
                                "new_level": new_level,
                                "new_title": new_title,
                                "exp_gained": exp_gained,
                            })
                        else:
                            await c.send({
                                "type": "exp_gained",
                                "amount": exp_gained,
                                "total_exp": new_exp,
                            })
                        log.info(f"Auto EXP: user={c.user['username']} +{exp_gained} (level {old_level}→{new_level})")
        except Exception as e:
            log.error(f"Failed to award EXP for user {c.user['username']}: {e}")

async def cleanup_client(client: Client):
    if client.room:
        await leave_room(client)

# === Background tasks ===

async def stale_client_sweeper(app: web.Application):
    while True:
        await asyncio.sleep(15)
        now = time.time()
        stale = []
        for ws, client in list(clients.items()):
            if now - client.last_seen > 60:
                stale.append((ws, client))
        for ws, client in stale:
            try:
                await ws.close()
            except Exception:
                pass
            log.info(f"Sweeping stale client: player_id={client.player_id}")
            await cleanup_client(client)
            clients.pop(ws, None)
            if client.user:
                await remove_user_online(client.user["id"])

async def online_presence_reaper(app: web.Application):
    """Reap expired online markers (60s without refresh = offline)."""
    while True:
        await asyncio.sleep(30)
        if not redis_client:
            continue
        try:
            keys = await redis_client.keys("user_seen:*")
            for key in keys:
                # Check TTL; if expired already gone
                ttl = await redis_client.ttl(key)
                if ttl is not None and ttl < 0:
                    user_id = key.split(":", 1)[1]
                    await redis_client.srem("online_users", user_id)
        except Exception as e:
            log.warning(f"Online reaper error: {e}")

async def start_background_tasks(app: web.Application):
    app["sweeper"] = asyncio.create_task(stale_client_sweeper(app))
    app["reaper"] = asyncio.create_task(online_presence_reaper(app))

async def cleanup_background_tasks(app: web.Application):
    for task_name in ("sweeper", "reaper"):
        if app.get(task_name):
            app[task_name].cancel()
            try:
                await app[task_name]
            except asyncio.CancelledError:
                pass

# === App ===

async def on_startup(app: web.Application):
    await init_db()

async def on_cleanup(app: web.Application):
    await close_db()

@web.middleware
async def cors_middleware(request: web.Request, handler):
    if request.method == "OPTIONS":
        resp = web.Response(status=204)
    else:
        resp = await handler(request)
    resp.headers["Access-Control-Allow-Origin"] = "*"
    resp.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS, PUT, DELETE"
    resp.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
    return resp

def create_app() -> web.Application:
    app = web.Application(client_max_size=65536, middlewares=[cors_middleware])
    app.router.add_get("/health", health_handler)
    app.router.add_get("/", index_handler)
    # REST API
    app.router.add_post("/api/register", api_register)
    app.router.add_post("/api/login", api_login)
    app.router.add_get("/api/me", api_me)
    app.router.add_post("/api/logout", api_logout)
    app.router.add_get("/api/profile/{username}", api_profile)
    app.router.add_get("/api/leaderboard", api_leaderboard)
    app.router.add_post("/api/match_result", api_match_result)
    # WebSocket
    app.router.add_get("/ws", ws_handler)
    app.on_startup.append(on_startup)
    app.on_startup.append(start_background_tasks)
    app.on_cleanup.append(cleanup_background_tasks)
    app.on_cleanup.append(on_cleanup)
    return app

def main():
    log.info("=" * 60)
    log.info("Phi Tiêu Dịch Chuyển — Server v4.2")
    log.info(f"Listening on 0.0.0.0:{PORT}")
    log.info("Endpoints:")
    log.info("  GET  /health  → Coolify healthcheck")
    log.info("  GET  /        → Info page")
    log.info("  POST /api/register    /api/login    /api/logout")
    log.info("  GET  /api/me  /api/profile/<username>  /api/leaderboard")
    log.info("  POST /api/match_result")
    log.info("  WS   /ws?token=TOKEN")
    log.info("Max players per room: %d", MAX_PLAYERS_PER_ROOM)
    log.info("Game duration: %ds", GAME_DURATION_SEC)
    log.info("=" * 60)
    web.run_app(create_app(), host="0.0.0.0", port=PORT, access_log=None)

if __name__ == "__main__":
    main()
