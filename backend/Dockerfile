# ── Build stage ──────────────────────────────────────────────────────
FROM node:22-slim AS builder

# OpenSSL needed by Prisma's native engine
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install ALL dependencies (dev + prod) — nest build needs @nestjs/cli
COPY package.json package-lock.json ./
RUN npm ci

# Copy Prisma schema and generate the client (needs native binaries)
COPY prisma ./prisma
RUN npx prisma generate

# Copy the rest of the source and build the NestJS app
COPY src ./src
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
RUN npm run build

# ── Production stage ─────────────────────────────────────────────────
FROM node:22-slim

# OpenSSL needed by Prisma at runtime
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install only production dependencies
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy generated Prisma client + schema (needed for migrate deploy at startup)
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma/client ./node_modules/@prisma/client
COPY --from=builder /app/prisma ./prisma

# Copy compiled NestJS output
COPY --from=builder /app/dist ./dist

EXPOSE 3000

# Run migrations on every deploy, then start the server
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/src/main.js"]
