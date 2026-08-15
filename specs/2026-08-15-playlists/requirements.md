# Requirements: Phase 4 — Playlists

## Scope
- **In**:
  - Backend: `PlaylistsModule` (`PlaylistsController` + `PlaylistsService` + unit & e2e tests) with JWT authentication on all routes.
  - Backend endpoints:
    - `POST /playlists` — create new playlist with name.
    - `GET /playlists` — list user's owned playlists with track count and cover preview.
    - `GET /playlists/:id` — get playlist details (name, owner, tracks in order).
    - `PATCH /playlists/:id` — rename playlist.
    - `DELETE /playlists/:id` — delete playlist.
    - `POST /playlists/:id/tracks` — add a track to playlist (`trackId`, appends at next position).
    - `DELETE /playlists/:id/tracks/:trackId` — remove a track from playlist.
    - `POST /tracks/:id/like` & `DELETE /tracks/:id/like` — toggle track liked status (stored in `LikedTrack`).
    - `GET /me/liked-tracks` — list user's liked tracks (ordered newest liked first).
  - Client: `PlaylistsRepository`, `PlaylistsNotifier` / Riverpod providers.
  - Client UI:
    - **Create Playlist Flow**: Tapping `Playlist` in the Create modal bottom sheet prompts for a playlist name, creates it via backend, and navigates to the new playlist.
    - **Playlist Detail Screen**: Dynamic hero header (gradient background, title, subtitle, track count), play button, shuffle button, and track list.
    - **Add/Remove from Playlist**: Song options menu (three dots or long press) with "Add to playlist" showing a picker sheet of user playlists.
    - **Liked Songs System**: Heart icon in MiniPlayer, Now Playing screen, and track lists to toggle liked state; tapping the **Liked Songs** tile in Library opens the dedicated Liked Songs playlist screen.
    - **Library Integration**: User playlists automatically appear in "Your Library" under the "Playlists" filter tab and in the main list.
  - Full-suite automated tests (backend unit/e2e + Flutter widget/unit tests) and clean `flutter analyze` & `npm run lint`.
- **Out**:
  - Collaborative real-time playlist sync (WebSockets).
  - AI playlist generation logic (marked as Beta UI placeholder in modal).
  - Blend/Jam audio mesh streaming.
  - Playlist cover image custom uploads (uses default mosaic/gradient from tracks).

## Key Decisions
- **Relational Schema**: Uses existing Prisma `Playlist`, `PlaylistTrack`, and `LikedTrack` models from Phase 0 with cascading deletes.
- **Position Tracking**: `PlaylistTrack.position` is an integer auto-incremented on append and re-indexed on track removal.
- **Owner-Scoped Security**: Users can only modify/delete playlists they own. Liked songs are uniquely scoped per `(userId, trackId)`.
- **Liked Songs as Auto-Playlist**: Liked songs are aggregated via the `LikedTrack` relation, dynamically creating the standard Spotify "Liked Songs" view with purple gradient header.
- **Hero Header Aesthetic**: Uses subtle gradients derived from Spotify theme or album art tones for the hero header on Playlist Detail.

## Context from mission.md
- Core User Story 5: *"As a user, I want to create, rename, delete, and reorder playlists, and like individual songs, so that I can organize my library the way I want."*

## Context from tech-stack.md
- NestJS `^11.1.x`, Prisma `^6.x`, `@nestjs/passport` + `passport-jwt`.
- Flutter `3.44.x`, Riverpod `^2.6.x`, `cached_network_image ^3.4.1`, `dio ^5.x`.
- Known Issues carried forward:
  - Direct Postgres connection (`127.0.0.1:54324`) for Prisma migrations and server.
  - Supabase offset ports (54323 storage / 54324 db) active on host.

## User Stories Addressed
- Mission Story 5 (Playlists & Liked Songs management).

## Engineering Standards (carried from specs/engineering-standards.md)
- **Mocks / Stubs / Placeholder Data**: "Default: forbidden. No mocked API responses, no hardcoded 'sample' tracks/playlists standing in for real database records, no fake auth bypass, anywhere in committed code... The only exception: seed/fixture data explicitly labeled as a database seed script (e.g. prisma/seed.ts)."
- **Debug Logging**: "No console.log / print / ad-hoc debug statements left in committed code. Use the NestJS Logger class server-side and structured, removable debug prints client-side only when explicitly requested... and remove them before the feature is marked done."
- **Definition of Done (Production)**: Every acceptance criterion has an automated check (unit/e2e/widget test) and one manual walkthrough on the real system.
- **Rollback Policy**: "Default: revert. On an unrecoverable Verify failure, the executor reverts the failing group's changes back to the last passing group's committed state."

## External Dependencies
- Supabase Postgres (port 54324) and Storage (port 54323) running locally.
