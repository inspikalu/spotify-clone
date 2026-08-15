# Validation: Phase 5 — Search

## Acceptance Criteria
- [ ] User can search by typing a query in the Search bar and receive debounced results across tracks, playlists, artists, and albums.
- [ ] Tapping a track in search results starts playback immediately via `playbackControllerProvider` and updates Now Playing / MiniPlayer.
- [ ] Tapping a playlist in search results navigates to the playlist detail screen.
- [ ] When search query is empty, "Browse all" 2-column genre grid is displayed with Spotify vibrant card styling.
- [ ] Recent search queries are saved locally and displayed in pre-search state with one-tap query execution and individual/clear-all removal.
- [ ] Search filter pills (Top, Songs, Playlists, Artists, Albums) allow filtering results by category.
- [ ] Empty search result shows Spotify "No results found for '{query}'" state with suggestion to check spelling.

## Merge Gate
- [ ] All Group verifies in `plan.md` pass with exact pasted outputs.
- [ ] Full backend tests pass: `cd backend && npm run lint && npm test && npm run test:e2e` (exit 0).
- [ ] Full client tests pass: `cd client && flutter analyze && flutter test` (exit 0).
- [ ] No mocks/stubs in production code (`client/lib` and `backend/src`).
- [ ] No `console.log` or debug `print` statements in committed files.
- [ ] Installed dependency check:
  - `npm list prisma @nestjs/core`
  - `flutter pub deps | grep -E 'flutter_riverpod|just_audio'`
- [ ] Clean diff review: `git diff --stat HEAD~1..HEAD` matches the scope.
- [ ] Demo-able: Search for a seeded song or artist (e.g. "Seyi Vibez" or "Apala"), play directly from search, view matching playlists, and verify recent searches persist.
