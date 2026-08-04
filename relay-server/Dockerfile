FROM node:20-alpine
WORKDIR /app
RUN apk add --no-cache python3 make g++
COPY package.json ./
RUN npm install --production
COPY . .
RUN mkdir -p /app/data
EXPOSE 3000
# No HEALTHCHECK here — let Coolify manage health check (start_period=60s, interval=10s)
# Coolify's HTTP health check on /health:3000 is more reliable than Docker's native HEALTHCHECK
# because Coolify properly handles start_period and won't kill the container prematurely
ENV PORT=3000
CMD ["node", "server.js"]
