# Phi Tiêu Dịch Chuyển — Multiplayer + Auth + Profile + Leaderboard Server (v4.1)
# Python aiohttp + asyncpg (PostgreSQL) + redis.
# Listens on port 3000. HTTP /health for Coolify healthcheck. WS /ws for game.

FROM python:3.12-slim

LABEL maintainer="mhieuhonda"
LABEL description="Phi Tiêu Dịch Chuyển server v4.1 - multiplayer + auth + profile + leaderboard"
LABEL version="4.1"

WORKDIR /app

# Install wget (needed by Coolify healthcheck: wget -qO- http://localhost:3000/health)
# Install build-essential + libffi-dev as fallback for bcrypt (usually pre-built wheels work).
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
# Long start_period: DB schema init can take 30+ seconds on first run
HEALTHCHECK --interval=10s --timeout=5s --retries=10 --start-period=120s \
    CMD wget -qO- http://localhost:3000/health || exit 1

# Run server
CMD ["python", "-u", "server.py"]
