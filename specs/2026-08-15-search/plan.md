# Plan: Phase 5 — Search

## Group 1 — Backend Search Module & Endpoints
- [ ] `backend/src/search/search.service.ts`: implement multi-entity search method querying Prisma with case-insensitive `contains` across `Track` (title, artist, album) and `Playlist` (name, only owned by user or public), with audio signed URLs via `StorageService`.
- [ ] `backend/src/search/search.controller.ts`: expose `GET /search?q={query}` endpoint protected by `JwtAuthGuard` and extracting user ID.
- [ ] `backend/src/search/search.module.ts`: register SearchModule and import into `app.module.ts`.
- [ ] `backend/src/search/search.service.spec.ts`: unit tests for empty query, matching tracks, matching playlists, artist matches, and audio signing.
- [ ] `backend/test/search.e2e-spec.ts`: e2e tests verifying `GET /search?q=...` returns HTTP 200 with structured results when authenticated.
- [ ] **Verify**: `cd backend && npm run lint && npm test -- src/search/search.service.spec.ts && npm run test:e2e -- search.e2e-spec.ts` → expect `0 errors`, all search unit and e2e suites passing.

## Group 2 — Client Search Models & Repository Layer
- [ ] `client/lib/features/search/models/search_result.dart`: define `SearchResults` model parsing `{ tracks: Track[], playlists: Playlist[], artists: String[], albums: String[] }`.
- [ ] `client/lib/features/search/search_repository.dart`: API client method `search(String query)` calling `GET /search?q=...`.
- [ ] `client/lib/features/search/search_providers.dart`: Riverpod providers for `searchQueryProvider`, `searchResultsProvider(query)`, and `recentSearchesProvider` (persisting recent strings to local storage).
- [ ] `client/test/search_repository_test.dart`: unit tests verifying SearchResults JSON parsing, repository query encoding, and recent searches persistence.
- [ ] **Verify**: `cd client && flutter analyze && flutter test test/search_repository_test.dart` → expect `No issues found!` and `All tests passed!`.

## Group 3 — Pre-Search Browse / Genre Grid UI
- [ ] `client/lib/features/search/models/browse_category.dart`: model defining standard Spotify browse cards (e.g. Pop, Afrobeats, Hip-Hop, Rock, Chill, R&B, Podcasts, Dance) with custom background colors and sample cover art icons.
- [ ] `client/lib/features/search/widgets/browse_category_card.dart`: Spotify-styled 2-column diagonal/tilted card component with bold typography and angled thumbnail preview.
- [ ] `client/lib/features/search/widgets/recent_searches_view.dart`: chips / list of recently searched terms with tap-to-search and clear button.
- [ ] `client/test/browse_category_test.dart`: widget tests verifying browse cards render in a 2-column grid and respond to tap.
- [ ] **Verify**: `cd client && flutter test test/browse_category_test.dart` → expect `No issues found!` and `All tests passed!`.

## Group 4 — Search Screen with Debounced Live Results & Navigation
- [ ] `client/lib/features/search/search_screen.dart`: build full Spotify search screen:
  - Sticky search bar with clear button and 300ms debounce
  - Filter pills row (Top, Songs, Playlists, Artists, Albums)
  - Pre-search view: Recent Searches + "Browse all" 2-column genre grid
  - Live results view: "Top result" card, matching Songs (tap to play), matching Playlists (tap to open `PlaylistDetailScreen`), and Artist/Album tiles
- [ ] `client/test/search_screen_test.dart`: widget tests covering initial browse view, debounced typing, results rendering, and tap-to-play interactions.
- [ ] **Verify**: `cd client && flutter analyze && flutter test test/search_screen_test.dart` → expect `No issues found!` and `All tests passed!`.

## Group 5 — Navigation Integration & Full Regression Gate
- [ ] `client/lib/core/navigation/nav_shell.dart`: ensure Search tab opens the real `SearchScreen` and preserves bottom player / navigation state.
- [ ] `client/test/nav_shell_test.dart`: update tests to verify switching to Search tab renders search bar and browse grid.
- [ ] Backend check: `cd backend && npm run lint && npm test && npm run test:e2e` → expect 0 errors, all test suites passing.
- [ ] Client check: `cd client && flutter analyze && flutter test` → expect 0 analysis issues and all test suites passing.
- [ ] Logging hygiene: `rg 'console\.log' backend/src/` → no matches; `rg 'debugPrint|print(' client/lib/` → no matches.
- [ ] **Verify**: `cd backend && npm test && cd ../client && flutter test` → expect all backend tests pass (`45+ passed`) and all client tests pass (`40+ passed`).
