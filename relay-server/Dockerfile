FROM node:20-alpine
WORKDIR /app
RUN apk add --no-cache python3 make g++
COPY package.json ./
RUN npm install --production
COPY . .
RUN mkdir -p /app/data
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=5 \
  CMD wget -qO- http://localhost:3000/health || exit 1
ENV PORT=3000
CMD ["node", "server.js"]
