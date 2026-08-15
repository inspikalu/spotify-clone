# Plan: Phase 6 — Home Polish

## Group 1 — Recently Played Tracking & Local Persistence
- [x] `client/lib/features/home/providers/recently_played_provider.dart`: implement `RecentlyPlayedNotifier` saving/loading played track IDs via `TokenStorage` and exposing `recentlyPlayedTracksProvider`.
- [x] `client/lib/features/player/playback_controller.dart`: hook into `playTrack` to register the track with `RecentlyPlayedNotifier`.
- [x] `client/test/recently_played_provider_test.dart`: unit tests verifying track addition, deduplication, max 10 cap, and loading from storage.
- [x] **Verify**: `cd client && flutter test test/recently_played_provider_test.dart` → expect `All tests passed!` — GOT: `00:04 +5: All tests passed!` ✅

## Group 2 — Dynamic Color Palette Extraction Utility
- [x] `client/lib/core/color_extractor.dart`: implement lightweight, non-blocking dominant color helper for cover art and artist gradients with smooth dark fallback tones.
- [x] `client/test/color_extractor_test.dart`: unit tests verifying deterministic hue derivation and color contrast.
- [x] **Verify**: `cd client && flutter test test/color_extractor_test.dart` → expect `All tests passed!` — GOT: `00:04 +7: All tests passed!` ✅

## Group 3 — Multi-Shelf Home Screen Implementation
- [x] `client/lib/features/home/widgets/horizontal_shelf.dart`: build reusable Spotify horizontal shelf widget supporting custom titles, subtitles, 160px cover cards, and tap-to-play.
- [x] `client/lib/features/home/home_screen.dart`: refactor `HomeScreen` to render:
  - Sticky top avatar and interactive filter pills (`All`, `Music`, `Podcasts`)
  - 2-column quick-access grid (top 6 tracks)
  - "Recently played" horizontal shelf
  - "Made For You" / "Recommended for today" shelf
  - "Popular releases" shelf
  - Dedicated Podcasts empty state when "Podcasts" filter is selected
- [x] `client/test/home_screen_test.dart`: update and add widget tests verifying multi-shelf rendering, filter pill toggling, and quick-access grid.
- [x] **Verify**: `cd client && flutter analyze && flutter test test/home_screen_test.dart` → expect `No issues found!` and `All tests passed!` — GOT: `No issues found!` / `00:07 +8: All tests passed!` ✅

## Group 4 — Ambient Gradient Extraction on Detail & Player Screens
- [x] `client/lib/features/playlists/screens/playlist_detail_screen.dart`: enhance hero header gradient to use dynamic ambient cover color.
- [x] `client/lib/features/player/now_playing_screen.dart`: enhance background gradient to adapt dynamically to playing track cover palette.
- [x] `client/test/playlist_detail_screen_test.dart`: verify playlist detail screen renders with ambient gradient.
- [x] `client/test/now_playing_screen_test.dart`: verify now playing screen renders with dynamic background gradient.
- [x] **Verify**: `cd client && flutter test test/playlist_detail_screen_test.dart test/now_playing_screen_test.dart` → expect `All tests passed!` — GOT: `00:09 +6: All tests passed!` ✅

## Group 5 — Full Regression & Quality Gate
- [x] Backend check: `cd backend && npm run lint && npm test && npm run test:e2e` → expect 0 errors, all test suites passing — GOT: lint clean, `Tests: 44 passed`, `Tests: 25 passed` ✅
- [x] Client check: `cd client && flutter analyze && flutter test` → expect 0 analysis issues and all test suites passing — GOT: `No issues found!`, `00:48 +57: All tests passed!` ✅
- [x] Logging hygiene check: `rg 'console\.log' backend/src/` → no matches; `rg 'debugPrint|print(' client/lib/` → no matches — GOT: no matches ✅
- [x] **Verify**: `cd backend && npm test && cd ../client && flutter test` → expect all backend tests pass (`44+ passed`) and all client tests pass (`40+ passed`) — GOT: backend `44 passed`, client `57 passed` ✅
