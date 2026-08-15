# Plan: Phase 3 — Home Shelf + Library Polish (MVP Deadline Deliverable)

Starting state: commit `ea4274b` (Phase 2 final, "Phase 2: upload + playback complete"). Home tab = Phase-1 style "Signed in as X / Log out" screen. Library = Group 2 track list. Search = empty state (stays empty — Phase 5). Visual reference: `specs/references/spotify-screenshots/` + stakeholder's written breakdown in requirements.md (black bg `#000000`, gray `#B3B3B3` secondary text, green `#1DB954` accents, ~8px card radius).

## Group 1 — Home "All uploaded tracks" shelf
- [x] `client/lib/features/home/home_screen.dart`: replace the Phase-1 body with the shelf screen — watch `tracksProvider` (exists: `FutureProvider<List<Track>>` over `TracksRepository.fetchTracks`); render four states: (a) loading → centered `CircularProgressIndicator`; (b) error → message + `Retry` button that `ref.invalidate(tracksProvider)`; (c) empty → "No tracks yet" (icon + message); (d) data → `AppBar` with leading avatar circle (first initial of the signed-in email from `authStateProvider`, white on a dark circle) and filter pills row; body = quick-access grid + horizontal shelf of cards: `CachedNetworkImage` cover, white bold title, gray `#B3B3B3` artist.
- [x] `client/lib/features/home/home_screen.dart`: avatar tap opens profile sidebar drawer (`ProfileDrawer`) with profile info and Log out capability.
- [x] `client/lib/features/home/home_screen.dart`: card `onTap`: `ref.read(playbackControllerProvider.notifier).playTrack(track)` then `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NowPlayingScreen()))`.
- [x] `client/test/home_screen_test.dart`: widget tests following fake-repository pattern — (a) loading state shows spinner; (b) error state shows message and Retry reloads; (c) empty state shows message; (d) shelf renders track title and artist; (e) tapping a card triggers `playTrack` and pushes NowPlayingScreen.
- [x] **Verify**: `cd client && flutter analyze` → `No issues found!`; `flutter test test/home_screen_test.dart` → `+5: All tests passed!`; `flutter test test/nav_shell_test.dart` → `All tests passed!`.

## Group 2 — Library polish (real-UI layout)
- [x] `client/lib/features/tracks/library_screen.dart`: `AppBar` title → `Your Library`; search & `+` create actions; filter pills row (`Playlists`, `Podcasts`, `Albums`, `Artists`, `Downloaded`).
- [x] `client/lib/features/tracks/library_screen.dart`: add a sort row under the AppBar — "Recents ↔ A–Z" toggle and grid toggle icon; Recents = backend order (`createdAt desc`); A–Z = client-side `title` sort.
- [x] `client/lib/features/tracks/library_screen.dart`: restyle rows to real-UI anatomy — ~56px square cover thumb, white bold title, gray subtitle (`Album • $artist` or `Single • $artist`), duration label. Added pinned Liked Songs & Your Episodes tiles.
- [x] Ordering note: confirm no backend change — `backend/src/tracks/tracks.service.ts` already `orderBy: { createdAt: 'desc' }`.
- [x] Extend the Library widget tests in `client/test/nav_shell_test.dart`: (a) subtitle format and track listings; (b) sort toggle Recents ↔ A–Z.
- [x] **Verify**: `cd client && flutter test test/nav_shell_test.dart` → `All tests passed!`; `cd backend && npm test` → `Test Suites: 7 passed, 7 total` / `Tests: 29 passed, 29 total`.

## Group 3 — Full verification + on-device walkthrough + deadline commit
- [x] Full client suite: `cd client && flutter analyze` → `No issues found!`; `flutter test` → `+29: All tests passed!`; `cd backend && npm run lint` → empty output, exit 0; `npm test` → `Test Suites: 7 passed, 7 total` / `Tests: 29 passed, 29 total`; `npm run test:e2e` → `Test Suites: 3 passed, 3 total` / `Tests: 16 passed, 16 total`.
- [x] Repo-wide: `rg 'print\(|console\.(log|debug)\(' client/lib backend/src` → exit 1 (no matches).
- [x] Version pins: `cached_network_image 3.4.1`, `flutter_riverpod ^2.6.x`, `just_audio ^0.10.6`, `music-metadata 7.14.0`, `@nestjs/platform-express 11.x`.
- [x] Device prereqs: `adb reverse tcp:3000 tcp:3000` and `adb reverse tcp:54323 tcp:54323`; backend `/health` → `{"status":"ok","db":"up"}`.
- [x] Walkthrough & UI refinement: (1) sign in → Home tab shows avatar circle top-left on same line as All/Music/Podcasts pills, quick-access 2-col grid, and "Your tracks" shelf. (2) Tap card → plays + Now Playing opens. (3) Library tab → "Your Library" header with search & plus icons, pinned Liked Songs / Episodes tiles, and track list. (4) Tap sort chip → toggles Recents ↔ A–Z. (5) Avatar tap → opens Profile sidebar drawer with profile details & Log out. (6) Bottom navigation includes 4 tabs with Create opening the modal bottom sheet.
- [x] Diff review: Verified clean changeset containing UI refinements, seed script, and updated specs.
- [x] Final commit: Recorded under Phase 3 milestone.
- [x] **Verify**: `git log -1 --pretty=%s` → `Phase 3: MVP deadline deliverable complete`.