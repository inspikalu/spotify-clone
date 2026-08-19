# Spotify Clone

A pixel-close, production-grade Spotify clone built with **Flutter** (client), **NestJS** (backend), and **PostgreSQL + Supabase Storage**, a complete, self-hosted listening experience: sign up, upload and play your own catalog, search, and build playlists.

> **Note:** "Spotify" is an internal working title only. It is a live trademark. Rename the app before any public release.

## Architecture

```
spotify-clone/
├── backend/     # NestJS 11 REST API (auth, tracks, playlists, search, storage)
├── client/      # Flutter mobile app (Android + iOS)
├── supabase/    # Local Supabase config (fallback — online is primary)
└── specs/       # Mission, tech-stack, roadmap, and per-phase plan/validation docs
```

| Layer | Technology |
|---|---|
| Mobile app | Flutter 3.44 / Dart 3.12, Riverpod, `just_audio` + `audio_service` |
| API | NestJS 11, Passport/JWT, `bcryptjs`, `music-metadata`, `resend` |
| Database | PostgreSQL 17 via Prisma 6 (Supabase) |
| Object storage | Supabase Storage (signed URLs for audio, public covers) |
| Email | Resend (password reset) |

## Features

**Auth**: email/password sign-up and login (JWT access + rotating refresh tokens), Google OAuth (ID-token verification), session restore, logout, forgot/reset password delivered via `spotifyclone://` deep link.

**Upload & playback**: multipart upload of audio (≤100 MB: mp3, m4a, wav, ogg, flac, aac, webm) with optional cover art (≤5 MB), server-side duration extraction, storage rollback on failure. Playback via `just_audio` with background/lock-screen controls (`audio_service`), play/pause, next/previous, seek, shuffle, repeat (off/one/all), mini player, Now Playing screen.

**Home**: multi-shelf layout (Recently played / Made for you / Your tracks / Popular releases), quick-access grid, All/Music/Podcasts filter pills, pull-to-refresh, deterministic ambient gradient extraction per track.

**Search**: 300ms-debounced search across tracks, playlists, artists, and albums; persisted recent searches; browse category grid.

**Playlists**: create/rename/delete, add/remove tracks (positioned), add-to-playlist modal, track options sheet, Liked Songs with optimistic like/unlike, playlist detail with gradient hero header.

**Library**: Your Library tab with playlists, pinned Liked Songs, A–Z/Recents sorting, empty states.

## Getting Started

### Prerequisites

- Node.js 22 LTS and npm
- Flutter 3.44.x stable (Dart 3.12.x)
- A Supabase project (free tier) — provides Postgres + Storage
- _(Optional)_ Docker + Supabase CLI — only needed for local Supabase fallback

### 1. Supabase (Online)

The project uses an **online Supabase project** (free tier) for both the PostgreSQL database and object storage. Credentials are in `backend/.env` (gitignored).

To switch back to a local Supabase instance, comment out the online values in `.env` and uncomment the local block (see the `.env` comments for details).

### 2. Backend

```bash
cd backend
npm install
cp .env.example .env   # fill in DATABASE_URL, JWT_SECRET, SUPABASE_*, RESEND_*, etc.
npx prisma migrate deploy   # apply schema to the online DB
npm run start:dev           # http://localhost:3000
```

All env vars except `GOOGLE_CLIENT_ID` are required: startup fails fast if any are missing. `DATABASE_URL` should point at the Supabase **direct** Postgres connection (port 5432), not the pooler.

### 3. Client

```bash
cd client
flutter pub get
flutter run          # defaults to http://10.0.2.2:3000 (Android emulator)
```

Point the app at another host with `--dart-define=API_BASE_URL=http://<host>:3000`. Google sign-in requires `--dart-define=GOOGLE_CLIENT_ID=<id>`. No `adb reverse` for storage — covers and audio are served directly from the online Supabase project.

## API Overview

Public: `GET /health` (DB connectivity).

JWT-guarded:
- **Auth**: `POST /auth/signup`, `POST /auth/login`, `POST /auth/google`, `POST /auth/refresh`, `POST /auth/forgot-password`, `POST /auth/reset-password`, `GET /auth/me`
- **Tracks**: `POST /tracks` (multipart upload), `GET /tracks`, `POST /tracks/:id/like`, `DELETE /tracks/:id/like`
- **Playlists**: `POST /playlists`, `GET /playlists`, `GET /playlists/:id`, `PATCH /playlists/:id`, `DELETE /playlists/:id`, `POST /playlists/:id/tracks`, `DELETE /playlists/:id/tracks/:trackId`
- **Search**: `GET /search?q=`
- **Library**: `GET /me/liked-tracks`

## Testing

Backend: 69 tests (44 unit + 25 e2e; e2e hit a real server, DB, and the online Supabase):

```bash
cd backend
npm test          # unit tests
npm run test:e2e  # end-to-end tests (requires running server + Supabase)
```

Client: 62 tests (unit + widget, using fakes for audio engine and token storage):

```bash
cd client
flutter test
```

## Deploying to Render

The backend deploys as a Docker web service on Render. The database and storage stay on Supabase (no Render Postgres needed).

### Quick start

1. Push this repo to GitHub/GitLab
2. Go to [dashboard.render.com](https://dashboard.render.com) → **New** → **Blueprint** → connect the repo
3. Render reads `render.yaml` and creates the service automatically
4. In the Render dashboard, go to the service → **Environment** and paste these secrets:
   - `DATABASE_URL` — your Supabase direct Postgres connection string
   - `SUPABASE_URL` — e.g. `https://<ref>.supabase.co`
   - `SUPABASE_SERVICE_ROLE_KEY` — from Supabase dashboard → Settings → API
   - `JWT_SECRET` — your existing secret
   - `RESEND_API_KEY` — from Resend dashboard
5. Deploy — Render builds the Docker image, runs `prisma migrate deploy`, and starts the server

The health check URL is `https://<service>.onrender.com/health`.

### Client configuration

When building the Flutter app for the deployed backend:

```bash
flutter run --dart-define=API_BASE_URL=https://<your-service>.onrender.com
```

### Free tier caveat

Render's free web service spins down after 15 minutes of inactivity, causing a ~30-second cold start on the next request. The `starter` plan ($7/mo) removes this. See `render.yaml` for the plan setting.

## Roadmap

Phases 0–3 delivered the deadline MVP (signup → upload → play). Phases 4–6 are complete: playlists, search, and home polish. Remaining: Phase 7 (Facebook/Apple sign-in) and Phase 8 (hardening: full coverage, empty/error states, performance pass). See `specs/roadmap.md` for details; each phase's plan, requirements, and validation live in `specs/`.

## License

Proprietary. Internal project.