FROM node:20-alpine
WORKDIR /app
RUN apk add --no-cache python3 make g++
COPY package.json ./
RUN npm install --production
COPY . .
RUN mkdir -p /app/data
EXPOSE 25671 25672
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:25672/health || exit 1
CMD ["node", "server.js"]
