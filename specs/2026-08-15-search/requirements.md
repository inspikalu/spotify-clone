# Requirements: Phase 5 — Search

## Scope
- **In**:
  - Backend search endpoint `GET /search?q={query}` supporting multi-entity query matching across:
    - Tracks: title, artist, album
    - Playlists: public / user accessible playlist names
  - Backend search service returning categorized search results `{ tracks: Track[], playlists: Playlist[], artists: string[], albums: string[] }`
  - Signed storage URLs generated for matching track audio and album cover art
  - Client `SearchRepository` and Riverpod search providers (`searchQueryProvider`, `searchResultsProvider`, `recentSearchesProvider`)
  - Debounced search query input (300ms debounce) in Flutter search bar
  - Pre-search state: Spotify browse & genre category grid (e.g., Pop, Hip-Hop, Afrobeats, Rock, R&B, Chill, Podcasts, New Releases) with vibrant solid/gradient cards
  - Active search state: categorized results list with "Top Result", matching tracks (tap to play), matching playlists (tap to view playlist detail), and artist/album groupings
  - Recent searches history persisted on device via `flutter_secure_storage` or shared prefs, with tap-to-re-search and clear/remove action
  - Full automated tests: NestJS unit tests, NestJS e2e tests, Flutter repository tests, and Flutter widget tests for `SearchScreen`

- **Out**:
  - Full text indexing engine (e.g., Elasticsearch / Meilisearch) — PostgreSQL `ILIKE` / Prisma `mode: 'insensitive'` is sufficient for the catalog scale.
  - Voice search / audio recognition (deferred to future stretch goals).
  - External Spotify web API proxying (all search operates against our real Supabase/Prisma database).

## Key Decisions
- **Unified Search Endpoint**: `GET /search?q={query}` returns unified JSON containing matching tracks, playlists, distinct artists, and distinct albums in a single round-trip to minimize client latency.
- **Debounced Search**: 300ms debounce on client text input to avoid firing requests on every keystroke.
- **Pre-Search Browse Grid**: When query is empty, render Spotify's 2-column browse categories with Spotify signature colored tiles (e.g., `#E13300`, `#1E3264`, `#8D67AB`, `#E8115B`, `#148A08`, `#503750`).
- **Recent Searches Storage**: Local device storage for query strings with max 10 recent items, individual item removal, and "Clear recent searches" button.

## Context from mission.md
- Core User Story 2: **"As a listener, I want to search for tracks, artists, and albums, so that I can quickly find and play something specific."**

## Context from tech-stack.md
- **Client**: Flutter `3.44.x`, Dart `3.12.x`, `flutter_riverpod ^2.6.x`, `cached_network_image ^3.4.1`, `dio ^4.x`, `flutter_secure_storage ^11.0.0`
- **Backend**: NestJS `^11.1.x`, Node.js `22.x LTS`, Prisma `^6.x`, Supabase PostgreSQL
- **Known Issues relevant to this phase**:
  - `flutter_secure_storage ^11.0.0` with `compileSdk = 37`
  - Signed URLs for audio files generated via backend `StorageService`

## User Stories Addressed
- **Story 2**: Search for tracks, artists, and albums to play music.
- **Story 3**: Browse genre categories.

## Engineering Standards (carried from specs/engineering-standards.md)
- **Mocks/Stubs**: Default forbidden. No mocked API responses, no hardcoded sample tracks/playlists standing in for real database records, no fake search responses in committed production code. Test-only mocks isolated in test files.
- **Debug Logging**: No `console.log` / `print` statements left in committed code. Use NestJS `Logger` server-side.
- **Definition of Done**: Automated checks pass + real manual walkthrough confirmed working.
- **Rollback Policy**: Revert failing groups on unrecoverable verify failure (`git reset --hard`).

## External Dependencies
- Supabase PostgreSQL database + Storage (already configured and verified).
- No new external APIs or paid services required.
