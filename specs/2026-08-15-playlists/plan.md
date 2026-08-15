# Plan: Phase 4 — Playlists & Liked Songs

## Group 1 — Backend Playlists & Liked Songs Module
- [x] `backend/src/playlists/dto/create-playlist.dto.ts`, `rename-playlist.dto.ts`, `add-track.dto.ts`: inline type validation in controller & service.
- [x] `backend/src/playlists/playlists.service.ts`: implement `create`, `listUserPlaylists`, `getPlaylistDetails`, `renamePlaylist`, `deletePlaylist`, `addTrackToPlaylist`, `removeTrackFromPlaylist`, `likeTrack`, `unlikeTrack`, and `getLikedTracks`.
- [x] `backend/src/playlists/playlists.controller.ts`: wire `/playlists` and `/tracks/:id/like` endpoints with `@UseGuards(JwtAuthGuard)` and request user extraction.
- [x] `backend/src/playlists/playlists.module.ts`: register in `app.module.ts`.
- [x] `backend/src/playlists/playlists.service.spec.ts`: unit tests for all playlist & liked songs business logic and error handling.
- [x] `backend/test/playlists.e2e-spec.ts`: e2e tests covering create → add track → get → list → like → unlike → delete.
- [x] **Verify**: `cd backend && npm run lint && npm test -- src/playlists/playlists.service.spec.ts && npm run test:e2e -- playlists.e2e-spec.ts` → GOT: "lint clean, Test Suites: 1 passed / Tests: 12 passed (service.spec), Test Suites: 1 passed / Tests: 6 passed (playlists.e2e-spec)" ✅

## Group 2 — Client Playlists & Likes Layer
- [x] `client/lib/features/playlists/models/playlist.dart`: create `Playlist` and `PlaylistDetail` data models with JSON serialization.
- [x] `client/lib/features/playlists/playlists_repository.dart`: API client methods for playlist CRUD, track addition/removal, and like/unlike endpoints.
- [x] `client/lib/features/playlists/playlists_providers.dart`: Riverpod providers for `userPlaylistsProvider`, `playlistDetailProvider(id)`, and `likedTracksProvider`.
- [x] `client/test/playlists_repository_test.dart`: unit tests verifying all repository calls and JSON parsing.
- [x] **Verify**: `cd client && flutter analyze && flutter test test/playlists_repository_test.dart` → GOT: "No issues found!, +5: All tests passed!" ✅

## Group 3 — Create Playlist & Add to Playlist Flow
- [x] `client/lib/core/widgets/create_bottom_sheet.dart`: wire the `Playlist` tile to show a create dialog/prompt ("Give your playlist a name"), invoke `createPlaylist`, and navigate to the newly created playlist screen.
- [x] `client/lib/features/playlists/widgets/add_to_playlist_modal.dart`: bottom sheet modal triggered from track options menu listing user's playlists with one-tap add.
- [x] `client/lib/features/playlists/widgets/track_options_sheet.dart`: three-dots modal with "Add to playlist", "Like/Unlike", and "View artist".
- [x] `client/test/create_playlist_flow_test.dart`: widget tests for creation flow and playlist selection modal.
- [x] **Verify**: `cd client && flutter test test/create_playlist_flow_test.dart` → GOT: "No issues found!, +2: All tests passed!" ✅

## Group 4 — Playlist Detail Screen & Liked Songs Auto-Playlist
- [x] `client/lib/features/playlists/screens/playlist_detail_screen.dart`: build Spotify playlist hero header (gradient background, title, creator, track count, large play button, shuffle button, three-dots menu to rename/delete).
- [x] `client/lib/features/playlists/screens/liked_songs_screen.dart`: dedicated Liked Songs playlist screen with purple gradient hero header (`#450af5` → `#8e8ee5`) fed by `likedTracksProvider`.
- [x] `client/lib/features/player/now_playing_screen.dart` & `client/lib/features/player/mini_player.dart`: wire interactive heart/like toggle button connected to `likedTracksProvider`.
- [x] `client/test/playlist_detail_screen_test.dart`: widget tests covering header display, track list, play all, like toggle, and empty states.
- [x] **Verify**: `cd client && flutter test test/playlist_detail_screen_test.dart` → GOT: "No issues found!, +2: All tests passed!" ✅

## Group 5 — Your Library Playlists Integration & Sort
- [ ] `client/lib/features/tracks/library_screen.dart`: integrate dynamic user playlists under the main list and under the `Playlists` filter pill; tapping "Liked Songs" opens `LikedSongsScreen`; tapping a playlist opens `PlaylistDetailScreen`.
- [ ] `client/lib/features/home/home_screen.dart`: display user's top playlists in the 2-column quick access grid alongside recent tracks.
- [ ] `client/test/nav_shell_test.dart`: regression tests confirming Library displays user playlists, filters correctly, and opens playlist screens on tap.
- [ ] **Verify**: `cd client && flutter analyze && flutter test test/nav_shell_test.dart` → expect `No issues found!` and `All tests passed!`.

## Group 6 — Full Verification & Regression Gate
- [ ] Backend check: `cd backend && npm run lint && npm test && npm run test:e2e` → expect 0 errors, all unit and e2e suites passing.
- [ ] Client check: `cd client && flutter analyze && flutter test` → expect 0 analysis issues and all test suites passing.
- [ ] Logging hygiene: `rg 'console\.(log|debug)|print\(' backend/src client/lib` → expect no matches.
- [ ] **Verify**: `cd backend && npm test && cd ../client && flutter test` → expect all backend tests pass (`30+ passed`) and all client tests pass (`32+ passed`).
