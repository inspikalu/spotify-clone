# Validation: Phase 4 — Playlists & Liked Songs

## Acceptance Criteria
- [ ] User can create a playlist with a custom name via the Create bottom sheet.
- [ ] Created playlists appear in "Your Library" and update in real-time.
- [ ] Playlist detail screen renders with a Spotify gradient hero header, owner name, track count, play button, and track list.
- [ ] User can add tracks to their playlist from any song's options menu and remove them from the playlist detail view.
- [ ] User can rename and delete playlists they own.
- [ ] User can like/unlike any track via a heart icon across Now Playing, MiniPlayer, and track lists.
- [ ] Pinned "Liked Songs" tile in Library dynamically counts liked songs and opens the dedicated Liked Songs auto-playlist screen.
- [ ] Tapping "Play" on a playlist queues all playlist tracks and starts playback.

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
- [ ] Demo-able: Real playlist created on mobile, tracks added, liked songs populated, and full playback verified.
