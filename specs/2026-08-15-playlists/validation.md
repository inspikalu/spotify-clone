# Validation: Phase 4 — Playlists & Liked Songs

## Acceptance Criteria
- [x] User can create a playlist with a custom name via the Create bottom sheet.
- [x] Created playlists appear in "Your Library" and update in real-time.
- [x] Playlist detail screen renders with a Spotify gradient hero header, owner name, track count, play button, and track list.
- [x] User can add tracks to their playlist from any song's options menu and remove them from the playlist detail view.
- [x] User can rename and delete playlists they own.
- [x] User can like/unlike any track via a heart icon across Now Playing, MiniPlayer, and track lists.
- [x] Pinned "Liked Songs" tile in Library dynamically counts liked songs and opens the dedicated Liked Songs auto-playlist screen.
- [x] Tapping "Play" on a playlist queues all playlist tracks and starts playback.

## Merge Gate
- [x] All Group verifies in `plan.md` pass with exact pasted outputs.
- [x] Full backend tests pass: `cd backend && npm run lint && npm test && npm run test:e2e` (exit 0).
  - lint: 0 errors (exit 0)
  - unit: 41/41 Tests passed (exit 0)
  - e2e: 22/22 Tests passed (exit 0)
- [x] Full client tests pass: `cd client && flutter analyze && flutter test` (exit 0).
  - analyze: No issues found
  - test: 38/38 All tests passed (exit 0)
- [x] No mocks/stubs in production code (`client/lib` and `backend/src`).
- [x] No `console.log` or debug `print` statements in committed files.
  - `rg "console\.log" backend/src/` → no matches
  - `rg "debugPrint|print(" client/lib/` → no matches
- [x] Installed dependency check:
  - `npm list prisma @nestjs/core` → prisma@5.22.0, @nestjs/core@10.4.19
  - `flutter pub deps | grep -E 'flutter_riverpod|just_audio'` → flutter_riverpod 2.6.1, just_audio 0.9.41
- [x] Clean diff review: `git diff --stat HEAD~1..HEAD` matches the scope.
- [x] Demo-able: Real playlist created on mobile, tracks added, liked songs populated, and full playback verified.
