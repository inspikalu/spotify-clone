# Spotify Clone

A pixel-close, production-grade Spotify clone built with **Flutter** (client), **NestJS** (backend), and **PostgreSQL + Supabase Storage**, a complete, self-hosted listening experience: sign up, upload and play your own catalog, search, and build playlists.

> **Note:** "Spotify" is an internal working title only. It is a live trademark. Rename the app before any public release.

## Architecture

```
spotify-clone/
├── backend/     # NestJS 11 REST API (auth, tracks, playlists, search, storage)
├── client/      # Flutter mobile app (Android + iOS)
├── supabase/    # Local Supabase config (Postgres + Storage, offset ports)
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
- Docker (for local Supabase)
- Supabase CLI

### 1. Local Supabase

The local instance runs on offset ports due to a host port collision: API `54323`, Postgres `54324`, Studio `54325`.

```bash
cd supabase
supabase start
```

If health checks are flaky on this host, use `supabase start --ignore-health-check`.

### 2. Backend

```bash
cd backend
npm install
cp .env.example .env   # fill in DATABASE_URL, JWT_SECRET, SUPABASE_*, RESEND_*, etc.
npx prisma migrate dev
npm run start:dev      # http://localhost:3000
```

All env vars except `GOOGLE_CLIENT_ID` are required: startup fails fast if any are missing. Prisma must connect directly to the Postgres port (`54324`), not the pooler.

### 3. Client

```bash
cd client
flutter pub get
flutter run          # defaults to http://10.0.2.2:3000 (Android emulator)
```

Point the app at another host with `--dart-define=API_BASE_URL=http://<host>:3000`. Google sign-in requires `--dart-define=GOOGLE_CLIENT_ID=<id>`. For local Supabase storage URLs, run `adb reverse tcp:54323 tcp:54323`.

## API Overview

Public: `GET /health` (DB connectivity).

JWT-guarded:
- **Auth**: `POST /auth/signup`, `POST /auth/login`, `POST /auth/google`, `POST /auth/refresh`, `POST /auth/forgot-password`, `POST /auth/reset-password`, `GET /auth/me`
- **Tracks**: `POST /tracks` (multipart upload), `GET /tracks`, `POST /tracks/:id/like`, `DELETE /tracks/:id/like`
- **Playlists**: `POST /playlists`, `GET /playlists`, `GET /playlists/:id`, `PATCH /playlists/:id`, `DELETE /playlists/:id`, `POST /playlists/:id/tracks`, `DELETE /playlists/:id/tracks/:trackId`
- **Search**: `GET /search?q=`
- **Library**: `GET /me/liked-tracks`

## Testing

Backend: 69 tests (44 unit + 25 e2e; e2e hit a real server, DB, and Supabase):

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

## Roadmap

Phases 0–3 delivered the deadline MVP (signup → upload → play). Phases 4–6 are complete: playlists, search, and home polish. Remaining: Phase 7 (Facebook/Apple sign-in) and Phase 8 (hardening: full coverage, empty/error states, performance pass). See `specs/roadmap.md` for details; each phase's plan, requirements, and validation live in `specs/`.

## License

Proprietary. Internal project.