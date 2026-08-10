# Phi Tiêu Dịch Chuyển — Multiplayer Server (v4.0)
# Python aiohttp WebSocket server, runs behind Traefik reverse proxy.
# Listens on port 3000. HTTP /health for Coolify healthcheck. WS /ws for game.

FROM python:3.12-slim

LABEL maintainer="mhieuhonda"
LABEL description="Phi Tiêu Dịch Chuyển multiplayer relay server"
LABEL version="4.0"

WORKDIR /app

# Install wget (needed by Coolify healthcheck: wget -qO- http://localhost:3000/health)
# python:3.12-slim doesn't include wget by default.
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies first (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy server code
COPY server.py .

# Expose port 3000 (Traefik routes phitieu.louis.vangioitutien.com → here)
EXPOSE 3000

# Healthcheck (Coolify uses wget -qO- http://localhost:3000/health)
HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=15s \
    CMD wget -qO- http://localhost:3000/health || exit 1

# Run server
CMD ["python", "-u", "server.py"]
