FROM node:20.19-alpine
# v2.6: Rebuild clean — force Docker cache invalidation
ARG BUILD_DATE=2026-08-04-v2
LABEL build_date=$BUILD_DATE
WORKDIR /app
RUN apk add --no-cache python3 make g++
COPY package.json ./
RUN npm install --production
COPY . .
RUN mkdir -p /app/data
EXPOSE 3000
# Explicitly disable Docker HEALTHCHECK — Coolify manages health check via HTTP
# HEALTHCHECK NONE prevents Docker from running any health check on this container
# Coolify's own health check (start_period=60s, interval=10s) is more reliable
HEALTHCHECK NONE
ENV PORT=3000
CMD ["node", "server.js"]
