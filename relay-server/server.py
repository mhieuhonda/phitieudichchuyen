"""
Phi Tiêu Dịch Chuyển — Multiplayer Server (v4.0)

Aiohttp WebSocket server for online deathmatch.
Runs behind Traefik reverse proxy at wss://phitieu.louis.vangioitutien.com/ws

Endpoints:
    GET  /health   → {"status": "ok"} (Coolify healthcheck)
    GET  /         → Info page (browser visits)
    WS   /ws       → Game protocol (JSON messages)

Game protocol (JSON over WebSocket):
    Client → Server:
        {type: "hello", name: str}  (implicit on connect, but client can send name)
        {type: "create_room", name: str}
        {type: "join_room", room_id: str}
        {type: "leave_room"}
        {type: "list_rooms"}
        {type: "start_game"}
        {type: "player_state", pos_x, pos_y, hp, score, alive}
        {type: "dart_spawn", dart_id, pos_x, pos_y, vel_x, vel_y}
        {type: "dart_remove", dart_id}
        {type: "hit", victim_id, damage}
        {type: "respawn"}
        {type: "chat", message: str}
        {type: "ping"}

    Server → Client:
        {type: "hello", player_id: int}
        {type: "room_joined", room_id, players: [{id, name, pos_x, pos_y, hp, score, alive}]}
        {type: "room_left"}
        {type: "player_joined", player_id, name}
        {type: "player_left", player_id}
        {type: "player_state", player_id, pos_x, pos_y, hp, score, alive}
        {type: "dart_spawn", dart_id, owner_id, pos_x, pos_y, vel_x, vel_y}
        {type: "dart_remove", dart_id}
        {type: "hit", victim_id, killer_id, damage}
        {type: "player_died", victim_id, killer_id}
        {type: "player_respawned", player_id, pos_x, pos_y}
        {type: "chat", sender_id, sender_name, message}
        {type: "game_start", players: [...]}
        {type: "game_end", scores: {player_id: score}}
        {type: "room_list", rooms: [{id, name, player_count, status}]}
        {type: "error", message: str}
        {type: "pong"}
"""

import asyncio
import json
import logging
import random
import string
import time
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
DISCONNECT_TIMEOUT_SEC = 30

# === Globals ===
# All connected clients: websocket -> Client
clients: dict = {}
# All rooms: room_id -> Room
rooms: dict = {}
# Player id counter
next_player_id = 1


def generate_room_id() -> str:
    """Generate a short, human-readable room ID like 'ABCD'."""
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=5))


def random_spawn_pos() -> tuple:
    """Random spawn position in arena."""
    return (
        random.uniform(100, ARENA_W - 100),
        random.uniform(100, ARENA_H - 100),
    )


class Client:
    """A connected WebSocket client."""

    def __init__(self, ws: web.WebSocketResponse):
        global next_player_id
        self.ws = ws
        self.player_id = next_player_id
        next_player_id += 1
        self.name = f"Player{self.player_id}"
        self.room: "Room | None" = None
        self.hp = INITIAL_HP
        self.score = 0
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
        }

    async def send(self, msg: dict):
        """Send a JSON message to this client."""
        try:
            await self.ws.send_str(json.dumps(msg))
        except Exception as e:
            log.warning(f"Send failed to player {self.player_id}: {e}")

    async def send_error(self, message: str):
        await self.send({"type": "error", "message": message})


class Room:
    """A multiplayer room (lobby + arena)."""

    def __init__(self, room_id: str, name: str, host: Client):
        self.id = room_id
        self.name = name
        self.host = host
        self.clients: list[Client] = [host]
        self.status = "lobby"  # "lobby" or "playing"
        self.game_start_time: float = 0
        self.game_end_task: asyncio.Task | None = None
        # Dart registry: dart_id -> owner_id (so we know who killed)
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
        # If room empty, schedule cleanup
        if not self.clients:
            return True  # caller should delete room
        # Transfer host if host left
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
        """Send message to all clients in room."""
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
        """Clean up a disconnected client inside a room."""
        if client in self.clients:
            self.clients.remove(client)
            # Notify others
            await self.broadcast({
                "type": "player_left",
                "player_id": client.player_id,
            })
            # Transfer host
            if self.host is client and self.clients:
                self.host = self.clients[0]
            # Delete room if empty
            if not self.clients:
                rooms.pop(self.id, None)
                if self.game_end_task:
                    self.game_end_task.cancel()
                    self.game_end_task = None


# === HTTP endpoints ===

async def health_handler(request: web.Request) -> web.Response:
    """Coolify healthcheck endpoint."""
    return web.json_response({
        "status": "ok",
        "service": "phitieu-multiplayer",
        "version": "4.0",
        "clients_online": len(clients),
        "rooms_active": len(rooms),
    })


async def index_handler(request: web.Request) -> web.Response:
    """Info page when visiting the domain in browser."""
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
<title>Phi Tiêu Dịch Chuyển — Multiplayer Server</title>
<style>
body {{
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: linear-gradient(135deg, #0a0a18 0%, #1a1a2e 100%);
    color: #e0e0e8;
    padding: 40px 20px;
    margin: 0;
    min-height: 100vh;
}}
.container {{
    max-width: 720px;
    margin: 0 auto;
    background: rgba(20, 22, 36, 0.7);
    padding: 36px;
    border-radius: 16px;
    border: 1px solid rgba(255, 170, 0, 0.2);
    box-shadow: 0 8px 32px rgba(0,0,0,0.4);
}}
h1 {{
    color: #ffaa00;
    text-shadow: 0 2px 8px rgba(255, 170, 0, 0.4);
    margin: 0 0 8px;
    font-size: 32px;
}}
h2 {{
    color: #4afcff;
    margin-top: 28px;
    font-size: 20px;
}}
.subtitle {{
    color: #888;
    margin-bottom: 24px;
    font-size: 14px;
}}
code {{
    background: rgba(255,255,255,0.08);
    padding: 2px 6px;
    border-radius: 4px;
    color: #aaffaa;
    font-family: 'SF Mono', Menlo, Consolas, monospace;
}}
.stats {{
    background: rgba(74, 252, 255, 0.06);
    border-left: 3px solid #4afcff;
    padding: 14px 18px;
    margin: 16px 0;
    border-radius: 6px;
    font-family: 'SF Mono', Menlo, Consolas, monospace;
    font-size: 14px;
    line-height: 1.7;
}}
ul {{
    line-height: 1.9;
    padding-left: 20px;
}}
.footer {{
    margin-top: 28px;
    padding-top: 16px;
    border-top: 1px solid rgba(255,255,255,0.08);
    color: #666;
    font-size: 12px;
    text-align: center;
}}
.status-ok {{ color: #44ff88; font-weight: bold; }}
</style>
</head>
<body>
<div class="container">
    <h1>🎯 Phi Tiêu Dịch Chuyển — Multiplayer Server</h1>
    <div class="subtitle">v4.0 — Online deathmatch relay server</div>

    <p>Đây là server multiplayer cho game <b>Phi Tiêu Dịch Chuyển</b>. Server chạy <b>WebSocket</b> qua <b>Traefik reverse proxy</b> với TLS.</p>

    <h2>📡 Trạng thái server</h2>
    <div class="stats">
        Status: <span class="status-ok">✓ ONLINE</span><br>
        Clients đang kết nối: <b>{len(clients)}</b><br>
        Phòng active: <b>{len(rooms)}</b><br>
        Tối đa mỗi phòng: <b>{MAX_PLAYERS_PER_ROOM}</b> người<br>
        Thời lượng mỗi trận: <b>{GAME_DURATION_SEC}s</b> (3 phút)
    </div>

    <h2>🏠 Phòng đang hoạt động</h2>
    {room_list_html}

    <h2>🎮 Cách chơi</h2>
    <ul>
        <li>Mở game <b>Phi Tiêu Dịch Chuyển v4.0</b></li>
        <li>Vào menu → <b>🌐 MULTIPLAYER</b></li>
        <li>Nhập tên → Ấn <b>Kết nối</b></li>
        <li>Tạo phòng mới hoặc vào phòng có sẵn</li>
        <li>Host ấn <b>⚔ Bắt đầu game</b> → Vào arena deathmatch!</li>
    </ul>

    <h2>🔌 WebSocket endpoint</h2>
    <div class="stats">
        URL: <code>wss://phitieu.louis.vangioitutien.com/ws</code><br>
        Protocol: JSON over WebSocket<br>
        Heartbeat: client ping mỗi 10s, server pong ngay
    </div>

    <div class="footer">
        Phi Tiêu Dịch Chuyển v4.0 — by mhieuhonda<br>
        Server: Python aiohttp · Proxy: Traefik v3.6 · TLS: Let's Encrypt
    </div>
</div>
</body>
</html>"""
    return web.Response(text=html, content_type="text/html")


# === WebSocket handler ===

async def ws_handler(request: web.Request) -> web.WebSocketResponse:
    ws = web.WebSocketResponse(heartbeat=30, max_msg_size=65536)
    await ws.prepare(request)

    client = Client(ws)
    clients[ws] = client

    log.info(f"Client connected: player_id={client.player_id} (total: {len(clients)})")

    # Send hello with player_id
    await client.send({
        "type": "hello",
        "player_id": client.player_id,
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
        log.info(f"Client disconnected: player_id={client.player_id} (remaining: {len(clients)})")

    return ws


async def handle_message(client: Client, msg: dict):
    msg_type = msg.get("type", "")

    if msg_type == "ping":
        await client.send({"type": "pong"})
        return

    if msg_type == "chat" and client.room:
        # Chat in lobby or in-game
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

    # All other commands require not being in a room (or being in a room)
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
        # Notify existing players
        await room.broadcast({
            "type": "player_joined",
            "player_id": client.player_id,
            "name": client.name,
        }, exclude=client)
        # Send room_joined to joiner
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

    # In-game commands require being in a room that's playing
    if not client.room:
        await client.send_error("Bạn chưa vào phòng")
        return

    if msg_type == "player_state":
        client.pos_x = float(msg.get("pos_x", client.pos_x))
        client.pos_y = float(msg.get("pos_y", client.pos_y))
        client.hp = int(msg.get("hp", client.hp))
        client.score = int(msg.get("score", client.score))
        client.alive = bool(msg.get("alive", client.alive))
        # Broadcast to others
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
        # Find victim
        victim = None
        for c in client.room.clients:
            if c.player_id == victim_id:
                victim = c
                break
        if not victim:
            return
        if not victim.alive:
            return
        victim.hp = max(0, victim.hp - damage)
        log.info(f"Player {client.player_id} hit player {victim_id} for {damage} (hp now {victim.hp})")
        # Broadcast hit
        await client.room.broadcast({
            "type": "hit",
            "victim_id": victim_id,
            "killer_id": client.player_id,
            "damage": damage,
        })
        # If victim died
        if victim.hp <= 0:
            victim.alive = False
            killer_score_delta = 1 if victim is not client else 0
            if victim is not client:
                client.score += 1
            await client.room.broadcast({
                "type": "player_died",
                "victim_id": victim_id,
                "killer_id": client.player_id,
            })
            log.info(f"Player {victim_id} died by player {client.player_id}")
        return

    if msg_type == "respawn":
        if client.alive:
            return  # only dead can respawn
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

    # Unknown message type — ignore


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
    # Reset all players
    for c in room.clients:
        c.hp = INITIAL_HP
        c.score = 0
        c.alive = True
        c.pos_x, c.pos_y = random_spawn_pos()
    # Broadcast game_start
    players = [c.to_public_dict() for c in room.clients]
    await room.broadcast({
        "type": "game_start",
        "players": players,
    })
    log.info(f"Game started in room {room.id} with {len(room.clients)} players")
    # Schedule game end
    room.game_end_task = asyncio.create_task(end_game_after(room, GAME_DURATION_SEC))


async def end_game_after(room: Room, delay: float):
    try:
        await asyncio.sleep(delay)
    except asyncio.CancelledError:
        return
    if room.status != "playing":
        return
    room.status = "lobby"
    scores = {c.player_id: c.score for c in room.clients}
    await room.broadcast({
        "type": "game_end",
        "scores": scores,
    })
    log.info(f"Game ended in room {room.id}. Scores: {scores}")
    room.game_end_task = None


async def cleanup_client(client: Client):
    """Remove client from any room and notify others."""
    if client.room:
        await leave_room(client)


# === Background tasks ===

async def stale_client_sweeper(app: web.Application):
    """Periodically check for stale clients (no heartbeat)."""
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


async def start_background_tasks(app: web.Application):
    app["sweeper"] = asyncio.create_task(stale_client_sweeper(app))


async def cleanup_background_tasks(app: web.Application):
    app["sweeper"].cancel()
    await asyncio.gather(app["sweeper"], return_exceptions=True)


# === App ===

def create_app() -> web.Application:
    app = web.Application(client_max_size=65536)
    app.router.add_get("/health", health_handler)
    app.router.add_get("/", index_handler)
    app.router.add_get("/ws", ws_handler)
    app.on_startup.append(start_background_tasks)
    app.on_cleanup.append(cleanup_background_tasks)
    return app


def main():
    log.info("=" * 60)
    log.info("Phi Tiêu Dịch Chuyển — Multiplayer Server v4.0")
    log.info(f"Listening on 0.0.0.0:{PORT}")
    log.info("Endpoints:")
    log.info("  GET  /health  → Coolify healthcheck")
    log.info("  GET  /        → Info page")
    log.info("  WS   /ws      → Game protocol")
    log.info("Max players per room: %d", MAX_PLAYERS_PER_ROOM)
    log.info("Game duration: %ds", GAME_DURATION_SEC)
    log.info("=" * 60)
    web.run_app(create_app(), host="0.0.0.0", port=PORT, access_log=None)


if __name__ == "__main__":
    main()
