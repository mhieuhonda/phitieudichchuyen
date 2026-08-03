#!/bin/bash
# ================================================================
# Deploy Script cho Phi Tiêu Dịch Chuyển Relay Server
# Chạy trên VPS qua Coolify Terminal hoặc SSH
# ================================================================

set -e

echo "🎯 Phi Tiêu Dịch Chuyển - Relay Server Deployment"
echo "=================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ docker-compose not found. Please install docker-compose first."
    exit 1
fi

# Stop existing container if running
echo "⏹️  Stopping existing phitieu-relay container..."
docker stop phitieu-relay 2>/dev/null || true
docker rm phitieu-relay 2>/dev/null || true

# Pull latest image from GHCR
echo "📥 Pulling latest relay server image..."
docker pull ghcr.io/mhieuhonda/phitieu-relay:latest

# Create data volume if not exists
docker volume create phitieu-data 2>/dev/null || true

# Run the relay server
echo "🚀 Starting Phi Tiêu Relay Server..."
docker run -d \
  --name phitieu-relay \
  --restart unless-stopped \
  -p 25671:25671 \
  -p 25672:25672 \
  -v phitieu-data:/app/data \
  -e NODE_ENV=production \
  -e WS_PORT=25671 \
  -e HTTP_PORT=25672 \
  -e DB_PATH=/app/data/game.db \
  -e MATCH_MIN_PLAYERS=10 \
  -e MATCH_MAX_PLAYERS=20 \
  -e MATCH_TIMEOUT_MS=30000 \
  -e TICK_RATE_MS=50 \
  -e MAX_ROOMS=50 \
  ghcr.io/mhieuhonda/phitieu-relay:latest

# Wait for container to start
sleep 3

# Check health
echo "🏥 Checking health..."
HEALTH=$(curl -s http://localhost:25672/health 2>/dev/null || echo '{"status":"error"}')
echo "Health response: $HEALTH"

# Show container status
echo ""
echo "📊 Container Status:"
docker ps --filter name=phitieu-relay --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✅ Relay Server deployed successfully!"
echo "   WebSocket: ws://10.187.247.3:25671/ws"
echo "   HTTP API:  http://10.187.247.3:25672/health"
echo "   Leaderboard: http://10.187.247.3:25672/api/leaderboard"
