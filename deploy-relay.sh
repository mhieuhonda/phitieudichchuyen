#!/bin/bash
# ================================================================
# Deploy Script cho Phi Tiêu Dịch Chuyển Relay Server v1.9 (v2.5)
# Chạy qua Coolify API — KHÔNG SSH trực tiếp
# VPS là sub-VPS sau Traefik reverse proxy
# Domain: phitieu.louis.vangioitutien.com
# ================================================================

set -e

COOLIFY_URL="https://coolify.buppou.com"
COOLIFY_API_TOKEN="${COOLIFY_API_TOKEN:-}"

if [ -z "$COOLIFY_API_TOKEN" ]; then
    echo "❌ Cần đặt COOLIFY_API_TOKEN environment variable"
    echo "   export COOLIFY_API_TOKEN='your-token'"
    exit 1
fi

echo "🎯 Phi Tiêu Dịch Chuyển - Relay Server Deployment (v2.5)"
echo "========================================================="
echo ""
echo "📍 Server info:"
echo "   - Domain: phitieu.louis.vangioitutien.com"
echo "   - VPS IP: 10.187.247.3 (sub-VPS, chỉ truy cập qua Traefik)"
echo "   - WSS endpoint: wss://phitieu.louis.vangioitutien.com/ws"
echo "   - Health: https://phitieu.louis.vangioitutien.com/health"
echo ""

# Kiểm tra health endpoint (qua domain, không qua IP trực tiếp)
echo "🏥 Checking server health..."
HEALTH=$(curl -s "https://phitieu.louis.vangioitutien.com/health" 2>/dev/null || echo '{"status":"error"}')
echo "Health response: $HEALTH"

# Kiểm tra Coolify API
echo ""
echo "🔍 Checking Coolify API..."
STATUS=$(curl -s -H "Authorization: Bearer $COOLIFY_API_TOKEN" "$COOLIFY_URL/api/v1/servers" 2>/dev/null || echo '{"error":"unreachable"}')
echo "Coolify API response: $STATUS"

echo ""
echo "✅ Deploy script ready!"
echo "   Sử dụng Coolify dashboard hoặc API để deploy:"
echo "   $COOLIFY_URL"
echo ""
echo "   WebSocket:  wss://phitieu.louis.vangioitutien.com/ws"
echo "   HTTP API:   https://phitieu.louis.vangioitutien.com/health"
echo "   Leaderboard: https://phitieu.louis.vangioitutien.com/api/leaderboard"
