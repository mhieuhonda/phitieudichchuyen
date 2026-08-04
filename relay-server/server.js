/**
 * Phi Tiêu Dịch Chuyển - Relay Server v1.9 (v2.5 release)
 *
 * WebSocket relay server cho game online:
 * - Matchmaking: min 10, max 20 người mỗi phòng
 * - 30s timeout → tự fill bot AI nếu chưa đủ 10 người
 * - SQLite database cho player stats
 * - Room management với state sync
 *
 * v1.9 (v2.5): Fix server cho sub-VPS sau Traefik reverse proxy
 * - HTTP server bind rõ ràng 0.0.0.0 (trong Docker cần expose tất cả interface)
 * - Xử lý X-Forwarded-For, X-Forwarded-Proto headers từ Traefik
 * - Trust proxy: ghi nhận client IP thật qua X-Forwarded-For
 * - Health endpoint trả về thêm proxy info
 * - Landing page hiện đúng WSS URL dựa trên Host header
 *
 * v1.8 (v2.4): Refactor để chạy trên 1 port duy nhất (PORT env, default 3000)
 * - HTTP server và WebSocket server dùng chung 1 port
 * - Tương thích Traefik reverse proxy (wss://domain/ws)
 * - Healthcheck đơn giản trên cùng port
 * - Hỗ trợ cả ws:// (direct) và wss:// (qua proxy TLS)
 */

const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');

// === DATABASE (SQLite) ===
let db;
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'data', 'game.db');

function initDatabase() {
  const dir = path.dirname(DB_PATH);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  try {
    const Database = require('better-sqlite3');
    db = new Database(DB_PATH);
    db.pragma('journal_mode = WAL');
    db.pragma('synchronous = NORMAL');

    db.exec(`
      CREATE TABLE IF NOT EXISTS players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT 'Player',
        character_id INTEGER NOT NULL DEFAULT 0,
        total_kills INTEGER NOT NULL DEFAULT 0,
        total_deaths INTEGER NOT NULL DEFAULT 0,
        total_wins INTEGER NOT NULL DEFAULT 0,
        total_matches INTEGER NOT NULL DEFAULT 0,
        total_score INTEGER NOT NULL DEFAULT 0,
        best_score INTEGER NOT NULL DEFAULT 0,
        last_seen TEXT NOT NULL DEFAULT (datetime('now')),
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      CREATE TABLE IF NOT EXISTS matches (
        id TEXT PRIMARY KEY,
        mode TEXT NOT NULL DEFAULT 'online',
        player_count INTEGER NOT NULL DEFAULT 0,
        bot_count INTEGER NOT NULL DEFAULT 0,
        winner_id TEXT,
        duration_seconds REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        ended_at TEXT
      );

      CREATE INDEX IF NOT EXISTS idx_players_last_seen ON players(last_seen);
      CREATE INDEX IF NOT EXISTS idx_matches_created ON matches(created_at);
    `);

    console.log(`[DB] SQLite initialized at ${DB_PATH}`);
  } catch (err) {
    console.warn(`[DB] SQLite not available (${err.message}), using in-memory store`);
    db = null;
  }
}

// In-memory fallback
const memStore = { players: new Map(), matches: new Map() };

function dbGetPlayer(id) {
  if (db) {
    return db.prepare('SELECT * FROM players WHERE id = ?').get(id);
  }
  return memStore.players.get(id) || null;
}

function dbUpsertPlayer(id, name, charId) {
  if (db) {
    db.prepare(`
      INSERT INTO players (id, name, character_id) VALUES (?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET name = ?, character_id = ?, last_seen = datetime('now')
    `).run(id, name, charId, name, charId);
  } else {
    const existing = memStore.players.get(id) || {
      id, name, character_id: charId, total_kills: 0, total_deaths: 0,
      total_wins: 0, total_matches: 0, total_score: 0, best_score: 0
    };
    existing.name = name;
    existing.character_id = charId;
    memStore.players.set(id, existing);
  }
}

function dbUpdatePlayerStats(id, kills, deaths, score, won) {
  if (db) {
    db.prepare(`
      UPDATE players SET total_kills = total_kills + ?, total_deaths = total_deaths + ?,
        total_score = total_score + ?, best_score = MAX(best_score, ?),
        total_wins = total_wins + ?, total_matches = total_matches + 1,
        last_seen = datetime('now')
      WHERE id = ?
    `).run(kills, deaths, score, score, won ? 1 : 0, id);
  } else {
    const p = memStore.players.get(id);
    if (p) {
      p.total_kills += kills;
      p.total_deaths += deaths;
      p.total_score += score;
      p.best_score = Math.max(p.best_score, score);
      if (won) p.total_wins++;
      p.total_matches++;
    }
  }
}

function dbCreateMatch(id, mode, playerCount, botCount) {
  if (db) {
    db.prepare('INSERT INTO matches (id, mode, player_count, bot_count) VALUES (?, ?, ?, ?)').run(id, mode, playerCount, botCount);
  } else {
    memStore.matches.set(id, { id, mode, player_count: playerCount, bot_count: botCount });
  }
}

function dbEndMatch(id, winnerId, duration) {
  if (db) {
    db.prepare('UPDATE matches SET winner_id = ?, duration_seconds = ?, ended_at = datetime(\'now\') WHERE id = ?').run(winnerId, duration, id);
  }
}

function dbGetLeaderboard(limit = 20) {
  if (db) {
    return db.prepare('SELECT id, name, total_score, total_kills, total_wins, total_matches, best_score FROM players ORDER BY total_score DESC LIMIT ?').all(limit);
  }
  return Array.from(memStore.players.values())
    .sort((a, b) => b.total_score - a.total_score)
    .slice(0, limit);
}

// === CONFIG ===
const CONFIG = {
  PORT: parseInt(process.env.PORT) || parseInt(process.env.WS_PORT) || 3000,
  HOST: process.env.HOST || '0.0.0.0',  // v1.9: bind tất cả interface cho Docker
  MATCH_MIN_PLAYERS: parseInt(process.env.MATCH_MIN_PLAYERS) || 10,
  MATCH_MAX_PLAYERS: parseInt(process.env.MATCH_MAX_PLAYERS) || 20,
  MATCH_TIMEOUT_MS: parseInt(process.env.MATCH_TIMEOUT_MS) || 30000,
  TICK_RATE_MS: parseInt(process.env.TICK_RATE_MS) || 50,
  MAX_ROOMS: parseInt(process.env.MAX_ROOMS) || 50,
  ROOM_TIMEOUT_MS: parseInt(process.env.ROOM_TIMEOUT_MS) || 3600000,
  PING_INTERVAL_MS: 30000,
};

// === REVERSE PROXY HELPER (v1.9) ===
// Trích xuất client IP thật từ X-Forwarded-For (Traefik đặt header này)
function getClientIp(req) {
  const xff = req.headers['x-forwarded-for'];
  if (xff) {
    // X-Forwarded-For có thể chứa nhiều IP: client, proxy1, proxy2...
    // IP đầu tiên là client thật
    return xff.split(',')[0].trim();
  }
  return req.socket.remoteAddress;
}

// Kiểm tra kết nối đến qua HTTPS (Traefik TLS termination)
function isSecure(req) {
  const proto = req.headers['x-forwarded-proto'];
  if (proto) return proto === 'https';
  // Fallback: check direct TLS socket
  return req.socket.encrypted === true;
}

// === STATE ===
const clients = new Map();
const matchmakingQueue = new Map();
let matchTimeout = null;
const rooms = new Map();

class Room {
  constructor(id) {
    this.id = id;
    this.players = new Map();
    this.state = 'waiting';
    this.countdownTimer = 5;
    this.createdAt = Date.now();
    this.matchDuration = 300;
    this.gameTime = 0;
    this.tickInterval = null;
    this.zoneRadius = 900;
    this.zoneCenter = { x: 1000, y: 1000 };
    this.zoneShrinkInterval = 30;
    this.zoneShrinkTimer = 30;
  }

  addPlayer(playerId, ws, name, characterId, isBot = false) {
    this.players.set(playerId, {
      ws, name, characterId, isBot, alive: true,
      score: 0, kills: 0,
      x: 0, y: 0, hp: 100, maxHp: 100, size: 20,
      lastSync: Date.now()
    });
    this.broadcast('room_player_joined', {
      playerId, name, characterId, isBot,
      playerCount: this.players.size
    });
  }

  removePlayer(playerId) {
    this.players.delete(playerId);
    this.broadcast('room_player_left', { playerId, playerCount: this.players.size });
  }

  broadcast(type, data, excludeId = null) {
    const msg = JSON.stringify({ type, data, t: Date.now() });
    for (const [pid, p] of this.players) {
      if (pid !== excludeId && !p.isBot && p.ws && p.ws.readyState === WebSocket.OPEN) {
        p.ws.send(msg);
      }
    }
  }

  startCountdown() {
    this.state = 'countdown';
    this.countdownTimer = 5;
    this.broadcast('match_countdown', { seconds: this.countdownTimer });

    const cdInterval = setInterval(() => {
      this.countdownTimer--;
      if (this.countdownTimer <= 0) {
        clearInterval(cdInterval);
        this.startGame();
      } else {
        this.broadcast('match_countdown', { seconds: this.countdownTimer });
      }
    }, 1000);
  }

  startGame() {
    this.state = 'playing';
    this.gameTime = 0;
    this.zoneRadius = 900;
    this.zoneShrinkTimer = this.zoneShrinkInterval;

    const playerList = [];
    for (const [pid, p] of this.players) {
      const angle = Math.random() * Math.PI * 2;
      const dist = Math.random() * 400;
      p.x = this.zoneCenter.x + Math.cos(angle) * dist;
      p.y = this.zoneCenter.y + Math.sin(angle) * dist;
      p.hp = 100;
      p.maxHp = 100;
      p.alive = true;
      playerList.push({
        playerId: pid, name: p.name, characterId: p.characterId,
        isBot: p.isBot, x: p.x, y: p.y
      });
    }

    this.broadcast('match_start', {
      roomId: this.id,
      players: playerList,
      zoneCenter: this.zoneCenter,
      zoneRadius: this.zoneRadius,
      matchDuration: this.matchDuration
    });

    dbCreateMatch(this.id, 'online',
      Array.from(this.players.values()).filter(p => !p.isBot).length,
      Array.from(this.players.values()).filter(p => p.isBot).length
    );

    this.tickInterval = setInterval(() => this.gameTick(), CONFIG.TICK_RATE_MS);
  }

  gameTick() {
    if (this.state !== 'playing') return;

    this.gameTime += CONFIG.TICK_RATE_MS / 1000;
    const timeRemaining = Math.max(0, this.matchDuration - this.gameTime);

    this.zoneShrinkTimer -= CONFIG.TICK_RATE_MS / 1000;
    if (this.zoneShrinkTimer <= 0) {
      this.zoneRadius = Math.max(200, this.zoneRadius - 50);
      this.zoneShrinkTimer = this.zoneShrinkInterval;
      this.broadcast('zone_shrank', { radius: this.zoneRadius });
    }

    const alivePlayers = Array.from(this.players.values()).filter(p => p.alive && !p.isBot);
    const aliveBots = Array.from(this.players.values()).filter(p => p.alive && p.isBot);
    const totalAlive = alivePlayers.length + aliveBots.length;

    if (timeRemaining <= 0 || totalAlive <= 1) {
      this.endMatch();
      return;
    }

    const stateUpdate = {
      timeRemaining: timeRemaining.toFixed(1),
      zoneRadius: this.zoneRadius,
      zoneCenter: this.zoneCenter,
      players: []
    };

    for (const [pid, p] of this.players) {
      stateUpdate.players.push({
        playerId: pid, x: Math.round(p.x * 10) / 10, y: Math.round(p.y * 10) / 10,
        hp: Math.round(p.hp), maxHp: Math.round(p.maxHp),
        size: Math.round(p.size), alive: p.alive, score: p.score, kills: p.kills,
        isBot: p.isBot
      });
    }

    this.broadcast('state_sync', stateUpdate);
  }

  endMatch() {
    if (this.state === 'ended') return;
    this.state = 'ended';
    if (this.tickInterval) clearInterval(this.tickInterval);

    const sorted = Array.from(this.players.entries())
      .sort((a, b) => b[1].score - a[1].score);
    const winnerId = sorted.length > 0 ? sorted[0][0] : null;
    const winnerName = sorted.length > 0 ? sorted[0][1].name : 'Nobody';

    const leaderboard = sorted.map(([pid, p], i) => ({
      rank: i + 1, playerId: pid, name: p.name,
      score: p.score, kills: p.kills, isBot: p.isBot
    }));

    this.broadcast('match_end', { winnerId, winnerName, leaderboard });

    const duration = this.gameTime;
    dbEndMatch(this.id, winnerId, duration);
    for (const [pid, p] of this.players) {
      if (!p.isBot) {
        dbUpdatePlayerStats(pid, p.kills, p.alive ? 0 : 1, p.score, pid === winnerId);
      }
    }

    setTimeout(() => {
      rooms.delete(this.id);
      console.log(`[Room] Deleted room ${this.id}`);
    }, 10000);
  }

  handlePlayerUpdate(playerId, data) {
    const p = this.players.get(playerId);
    if (!p || !p.alive) return;

    if (data.x !== undefined) p.x = data.x;
    if (data.y !== undefined) p.y = data.y;
    if (data.hp !== undefined) p.hp = data.hp;
    if (data.maxHp !== undefined) p.maxHp = data.maxHp;
    if (data.size !== undefined) p.size = data.size;
    if (data.score !== undefined) p.score = data.score;
    if (data.kills !== undefined) p.kills = data.kills;
    if (data.alive !== undefined) p.alive = data.alive;
    p.lastSync = Date.now();
  }

  handleDartThrow(playerId, data) {
    this.broadcast('dart_thrown', { playerId, ...data }, playerId);
  }

  handleTeleport(playerId, data) {
    this.broadcast('player_teleport', { playerId, ...data }, playerId);
  }

  handleKill(killerId, victimId, data) {
    const killer = this.players.get(killerId);
    const victim = this.players.get(victimId);
    if (killer) { killer.kills++; killer.score += (data.score || 100); }
    if (victim) { victim.alive = false; }
    this.broadcast('player_killed', { killerId, victimId, killerName: killer?.name, victimName: victim?.name, ...data });
  }

  handleSkillUse(playerId, data) {
    this.broadcast('skill_used', { playerId, ...data }, playerId);
  }

  handleRespawn(playerId, data) {
    const p = this.players.get(playerId);
    if (p) {
      p.alive = true;
      p.hp = p.maxHp;
      const angle = Math.random() * Math.PI * 2;
      const dist = Math.random() * this.zoneRadius * 0.6;
      p.x = this.zoneCenter.x + Math.cos(angle) * dist;
      p.y = this.zoneCenter.y + Math.sin(angle) * dist;
    }
    this.broadcast('player_respawned', { playerId, x: p?.x, y: p?.y, ...data });
  }

  handleChat(playerId, message) {
    const p = this.players.get(playerId);
    if (!p) return;
    this.broadcast('chat_message', { playerId, name: p.name, message });
  }
}

// === MATCHMAKING ===
function enqueuePlayer(playerId, ws, name, characterId) {
  if (matchmakingQueue.has(playerId)) return false;
  matchmakingQueue.set(playerId, { ws, name, characterId, enqueuedAt: Date.now() });
  console.log(`[Match] Player ${name}(${playerId}) enqueued. Queue size: ${matchmakingQueue.size}`);

  for (const [pid, entry] of matchmakingQueue) {
    if (entry.ws.readyState === WebSocket.OPEN) {
      entry.ws.send(JSON.stringify({
        type: 'matchmaking_update',
        data: { queueSize: matchmakingQueue.size, minPlayers: CONFIG.MATCH_MIN_PLAYERS, maxPlayers: CONFIG.MATCH_MAX_PLAYERS }
      }));
    }
  }

  if (matchmakingQueue.size >= CONFIG.MATCH_MIN_PLAYERS) {
    createMatchFromQueue();
  } else if (!matchTimeout) {
    matchTimeout = setTimeout(() => {
      console.log(`[Match] Timeout reached. Queue: ${matchmakingQueue.size} players`);
      if (matchmakingQueue.size >= 2) {
        createMatchFromQueue();
      } else {
        for (const [pid, entry] of matchmakingQueue) {
          if (entry.ws.readyState === WebSocket.OPEN) {
            entry.ws.send(JSON.stringify({ type: 'matchmaking_timeout', data: { message: 'Không đủ người chơi, đang thêm bot AI...' } }));
          }
        }
        createMatchFromQueue();
      }
      matchTimeout = null;
    }, CONFIG.MATCH_TIMEOUT_MS);
  }

  return true;
}

function dequeuePlayer(playerId) {
  matchmakingQueue.delete(playerId);
  if (matchmakingQueue.size === 0 && matchTimeout) {
    clearTimeout(matchTimeout);
    matchTimeout = null;
  }
}

function createMatchFromQueue() {
  if (rooms.size >= CONFIG.MAX_ROOMS) {
    console.warn('[Match] Max rooms reached, cannot create new match');
    return;
  }

  const roomId = uuidv4();
  const room = new Room(roomId);

  const entries = Array.from(matchmakingQueue.entries());
  const realPlayers = entries.slice(0, CONFIG.MATCH_MAX_PLAYERS);

  for (const [pid] of realPlayers) {
    matchmakingQueue.delete(pid);
  }

  for (const [pid, entry] of realPlayers) {
    room.addPlayer(pid, entry.ws, entry.name, entry.characterId, false);
    clients.set(entry.ws, { playerId: pid, roomId });
  }

  const botsNeeded = Math.max(0, CONFIG.MATCH_MIN_PLAYERS - realPlayers.length);
  const botNames = ['Rồng', 'Phượng', 'Hổ', 'Báo', 'Sói', 'Cáo', 'Gấu', 'Diều', 'Cọp', 'Chồn', 'Thiên Long', 'Hắc Vũ'];
  for (let i = 0; i < botsNeeded; i++) {
    const botId = `bot_${roomId}_${i}`;
    const botName = botNames[i % botNames.length];
    room.addPlayer(botId, null, botName, i % 12, true);
  }

  rooms.set(roomId, room);
  console.log(`[Match] Room ${roomId} created: ${realPlayers.length} players + ${botsNeeded} bots`);

  if (matchTimeout) {
    clearTimeout(matchTimeout);
    matchTimeout = null;
  }

  room.broadcast('match_found', {
    roomId,
    playerCount: realPlayers.length,
    botCount: botsNeeded,
    totalPlayers: room.players.size
  });

  setTimeout(() => room.startCountdown(), 1000);
}

// === HTTP SERVER (health + REST API on same port as WebSocket) ===
const httpServer = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Content-Type', 'application/json');

  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const url = req.url || '/';
  // v1.9: Lấy client IP thật qua X-Forwarded-For
  const clientIp = getClientIp(req);
  const secure = isSecure(req);
  // Xác định scheme cho URL hiển thị (wss:// nếu qua HTTPS proxy)
  const wsScheme = secure ? 'wss' : 'ws';
  const httpScheme = secure ? 'https' : 'http';
  // Host từ header (Traefik đặt Host header = domain gốc)
  const host = req.headers['host'] || `${CONFIG.HOST}:${CONFIG.PORT}`;

  if (url === '/health') {
    res.writeHead(200);
    res.end(JSON.stringify({
      status: 'ok',
      version: '1.9.0',
      gameVersion: '2.5',
      uptime: process.uptime(),
      rooms: rooms.size,
      clients: clients.size,
      matchmaking: matchmakingQueue.size,
      db: db ? 'sqlite' : 'memory',
      // v1.9: Proxy info để debug
      proxy: {
        xForwardedFor: req.headers['x-forwarded-for'] || null,
        xForwardedProto: req.headers['x-forwarded-proto'] || null,
        clientIp,
        secure,
      }
    }));
  } else if (url === '/api/status') {
    res.writeHead(200);
    res.end(JSON.stringify({
      version: '1.9.0',
      gameVersion: '2.5',
      uptime: process.uptime(),
      rooms: rooms.size,
      clients: clients.size,
      matchmaking: matchmakingQueue.size,
      db: db ? 'sqlite' : 'memory'
    }));
  } else if (url === '/api/leaderboard') {
    res.writeHead(200);
    res.end(JSON.stringify(dbGetLeaderboard(20)));
  } else if (url === '/') {
    // Landing page — hiển thị đúng WSS URL dựa trên Host header
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.writeHead(200);
    res.end(`<!DOCTYPE html><html><head><title>Phi Tiêu Dịch Chuyển - Relay Server v1.9</title></head><body style="font-family:monospace;padding:40px;color:#333"><h1>Phi Tiêu Dịch Chuyển - Relay Server v1.9 (v2.5)</h1><p>HTTP + WebSocket on port ${CONFIG.PORT}</p><p>WS endpoint: <code>${wsScheme}://${host}/ws</code></p><p>Health: <a href="${httpScheme}://${host}/health">${httpScheme}://${host}/health</a></p><p>Leaderboard: <a href="${httpScheme}://${host}/api/leaderboard">${httpScheme}://${host}/api/leaderboard</a></p><hr><p>Clients: ${clients.size} | Rooms: ${rooms.size} | Queue: ${matchmakingQueue.size} | DB: ${db ? 'SQLite' : 'Memory'}</p></body></html>`);
  } else {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found' }));
  }
});

// === WEBSOCKET SERVER (mounted on same HTTP server, path /ws) ===
const wss = new WebSocketServer({ server: httpServer, path: '/ws' });

wss.on('connection', (ws, req) => {
  // v1.9: Log client IP thật thay vì proxy IP
  const clientIp = getClientIp(req);
  console.log(`[WS] New connection from ${clientIp} (proxy: ${req.socket.remoteAddress}). Total: ${wss.clients.size}`);

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw); } catch { return; }

    const { type, data } = msg;

    switch (type) {
      case 'login': {
        const { playerId, name, characterId } = data || {};
        const pid = playerId || uuidv4();
        dbUpsertPlayer(pid, name || 'Player', characterId || 0);
        clients.set(ws, { playerId: pid, roomId: null });
        ws.send(JSON.stringify({ type: 'login_ok', data: { playerId: pid } }));
        console.log(`[WS] Player ${name}(${pid}) logged in from ${clientIp}`);
        break;
      }

      case 'matchmaking_join': {
        const clientInfo = clients.get(ws);
        if (!clientInfo) return;
        const player = dbGetPlayer(clientInfo.playerId);
        const name = data?.name || player?.name || 'Player';
        const charId = data?.characterId ?? player?.character_id ?? 0;
        clientInfo.name = name;
        clientInfo.characterId = charId;
        enqueuePlayer(clientInfo.playerId, ws, name, charId);
        break;
      }

      case 'matchmaking_leave': {
        const clientInfo = clients.get(ws);
        if (!clientInfo) return;
        dequeuePlayer(clientInfo.playerId);
        ws.send(JSON.stringify({ type: 'matchmaking_left' }));
        break;
      }

      case 'player_update': {
        const clientInfo = clients.get(ws);
        if (!clientInfo?.roomId) return;
        const room = rooms.get(clientInfo.roomId);
        if (room) room.handlePlayerUpdate(clientInfo.playerId, data || {});
        break;
      }

      case 'dart_throw': {
        const clientInfo = clients.get(ws);
        if (!clientInfo?.roomId) return;
        const room = rooms.get(clientInfo.roomId);
        if (room) room.handleDartThrow(clientInfo.playerId, data || {});
        break;
      }

      case 'player_teleport': {
        const clientInfo = clients.get(ws);
        if (!clientInfo?.roomId) return;
        const room = rooms.get(clientInfo.roomId);
        if (room) room.handleTeleport(clientInfo.playerId, data || {});
        break;
      }

      case 'player_kill': {
        const clientInfo = clients.get(ws);
        if (!clientInfo?.roomId) return;
        const room = rooms.get(clientInfo.roomId);
        if (room) room.handleKill(clientInfo.playerId, data?.victimId, data || {});
        break;
      }

      case 'skill_use': {
        const clientInfo = clients.get(ws);
        if (!clientInfo?.roomId) return;
        const room = rooms.get(clientInfo.roomId);
        if (room) room.handleSkillUse(clientInfo.playerId, data || {});
        break;
      }

      case 'player_respawn': {
        const clientInfo = clients.get(ws);
        if (!clientInfo?.roomId) return;
        const room = rooms.get(clientInfo.roomId);
        if (room) room.handleRespawn(clientInfo.playerId, data || {});
        break;
      }

      case 'chat': {
        const clientInfo = clients.get(ws);
        if (!clientInfo?.roomId) return;
        const room = rooms.get(clientInfo.roomId);
        if (room) room.handleChat(clientInfo.playerId, data?.message || '');
        break;
      }

      case 'ping': {
        ws.send(JSON.stringify({ type: 'pong', t: Date.now() }));
        break;
      }
    }
  });

  ws.on('close', () => {
    const clientInfo = clients.get(ws);
    if (clientInfo) {
      dequeuePlayer(clientInfo.playerId);
      if (clientInfo.roomId) {
        const room = rooms.get(clientInfo.roomId);
        if (room) {
          room.removePlayer(clientInfo.playerId);
          if (room.players.size === 0) {
            rooms.delete(clientInfo.roomId);
            console.log(`[Room] Room ${clientInfo.roomId} empty, deleted`);
          }
        }
      }
      clients.delete(ws);
      console.log(`[WS] Player ${clientInfo.playerId} disconnected`);
    }
  });
});

// === CLEANUP ===
setInterval(() => {
  const now = Date.now();
  for (const [id, room] of rooms) {
    if (now - room.createdAt > CONFIG.ROOM_TIMEOUT_MS && room.state !== 'playing') {
      room.broadcast('room_expired', { roomId: id });
      rooms.delete(id);
      console.log(`[Cleanup] Expired room ${id}`);
    }
  }
}, 60000);

// === START ===
initDatabase();
httpServer.listen(CONFIG.PORT, CONFIG.HOST, () => {
  console.log(`[Server] Phi Tiêu Dịch Chuyển Relay Server v1.9 (v2.5)`);
  console.log(`[Server] HTTP + WebSocket on ${CONFIG.HOST}:${CONFIG.PORT}`);
  console.log(`[Server] WS endpoint: ws://${CONFIG.HOST}:${CONFIG.PORT}/ws`);
  console.log(`[Server] Match config: ${CONFIG.MATCH_MIN_PLAYERS}-${CONFIG.MATCH_MAX_PLAYERS} players, ${CONFIG.MATCH_TIMEOUT_MS}ms timeout`);
  console.log(`[Server] Reverse proxy: X-Forwarded-For/Proto headers supported`);
});
