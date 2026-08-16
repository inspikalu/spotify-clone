# Spotify Clone — Backend

NestJS 11 REST API for the Spotify clone. See the [root README](../README.md) for the full project overview and setup.

## Stack

- NestJS 11, Prisma 6 + PostgreSQL 17 (Supabase), Passport/JWT auth, Supabase Storage (REST), `music-metadata`, `resend`

## Modules

| Module | Responsibility |
|---|---|
| `auth` | Email/password signup+login, Google OAuth ID-token verification, JWT access/refresh rotation, password reset emails |
| `tracks` | Multipart upload (audio ≤100 MB, cover ≤5 MB), duration extraction, signed URLs, like/unlike |
| `playlists` | CRUD, positioned track membership, liked tracks |
| `search` | Case-insensitive search across tracks, playlists, artists, albums |
| `storage` | Supabase Storage wrapper (upload, signed URLs, delete) |
| `users` | User lookup/create/password update |
| `health` | `GET /health` DB connectivity check |

## Setup

```bash
npm install
cp .env.example .env   # all vars except GOOGLE_CLIENT_ID are required
npx prisma migrate dev
npm run start:dev      # http://localhost:3000
```

## Scripts

| Script | Description |
|---|---|
| `npm run start:dev` | Watch mode |
| `npm run build` | Compile to `dist/` |
| `npm test` | 44 unit tests |
| `npm run test:e2e` | 25 e2e tests (needs running server + Supabase) |
| `npm run lint` | ESLint + Prettier fix |