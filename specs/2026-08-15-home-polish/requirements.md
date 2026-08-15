# Requirements: Phase 6 — Home Polish

## Scope
- **In**:
  - **Multiple Horizontal Shelves** on HomeScreen:
    - *"Recently Played"* shelf (persisting up to 10 recently listened tracks via `TokenStorage`).
    - *"Made For You"* shelf (curated recommendations based on liked songs and artists in catalog).
    - *"Popular Albums & Singles"* shelf (album/single tracks group).
  - **Dynamic Cover Art Palette Extraction**:
    - Dominant ambient color extraction from cover art URL / fallback color derivation for hero headers in PlaylistDetailScreen and NowPlayingScreen.
  - **Home Filter Pills Interactivity**:
    - Sticky top filter pills (`All`, `Music`, `Podcasts`) filtering and re-rendering relevant shelves and empty states.
  - **Direct Shelf Tap-to-Play**:
    - Tapping any card in any shelf starts playback of that shelf queue immediately and opens Now Playing screen.
- **Out**:
  - Real machine-learning recommendation engine (deferred to future backend phases; uses catalog artist/liked matching heuristics).
  - Podcast episode streaming audio ingestion backend (uses placeholder podcast browse state).

## Key Decisions
- **Recently Played Storage**: Saved locally as track ID lists via `TokenStorage` (similar to `RecentSearchesNotifier`), loaded on app boot and updated whenever `playbackController.playTrack` is invoked.
- **Dynamic Palette Extraction**: Native Flutter `ImageProvider` pixel sampling / dominant hue calculation or deterministic color derivation from track art, ensuring 0 external native dependency bloat and instant smooth 60fps rendering without jank.
- **Shelf Separation**: Modular, reusable `_HorizontalShelf` widget handling title, subtitle, horizontal scrolling list, and tap-to-play interactions.

## Context from mission.md
- User Story 3: "As a listener, I want to browse curated shelves and genre categories on a Home screen, so that I can discover things in my catalog without knowing exactly what I want."
- User Story 4: "As a listener, I want full playback controls that persist in the background, so that listening feels seamless and matches the real Spotify experience."

## Context from tech-stack.md
- Client: `flutter_riverpod ^2.6.x`, `cached_network_image ^3.4.1`, `just_audio ^0.10.6`.
- Backend: NestJS `^11.1.x`, Prisma `^6.x`.
- Known Issues:
  - Local dev host port collision: keeping offset ports (API 54323, Postgres 54324).
  - Prisma direct connection required for migrations.

## User Stories Addressed
- **Story 3 (Browse/Discover)**: Multi-shelf Home screen layout with Recently Played, Made For You, and Popular Singles.
- **Story 4 (Playback Experience)**: Dynamic ambient color gradients on Now Playing & Playlists.

## Engineering Standards (carried from specs/engineering-standards.md)
- **Mocks / Stubs**: Default: forbidden. No mocked API responses, no hardcoded "sample" tracks standing in for real database records.
- **Debug Logging**: No `console.log` / `print` / ad-hoc debug statements left in committed code.
- **Definition of Done**: Passing automated unit/widget tests AND manual walkthrough confirmed.
- **Rollback Policy**: Default: revert failing group's changes back to the last passing group's committed state.

## External Dependencies
- Supabase Postgres and Storage bucket for catalog covers and audio streaming. No new external credentials needed.
