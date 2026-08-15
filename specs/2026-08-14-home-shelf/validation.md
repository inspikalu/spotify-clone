# Validation: Phase 3 — Home Shelf + Library Polish (MVP Deadline Deliverable)

## Acceptance Criteria
- [x] Criterion 1: Home tab renders a real "Your tracks" shelf & quick access 2-col grid — track cards come from `GET /tracks` via `tracksProvider`, matching screenshot layout.
- [x] Criterion 2: Home has all four states — loading spinner, error message + working Retry, "No tracks yet" empty state, populated shelf.
- [x] Criterion 3: Home top-left shows avatar circle on same line as All/Music/Podcasts pills; tapping it opens the Spotify profile sidebar drawer with user details & Log out.
- [x] Criterion 4: Tapping a shelf card or quick-access tile starts playback and opens Now Playing screen.
- [x] Criterion 5: Library shows "Your Library" header, search & plus buttons, filter pills, pinned Liked Songs / Episodes tiles, and "Recents ↔ A–Z" sort toggle.
- [x] Criterion 6: No regression — sign in, session restore, background playback, and auto-login all pass without issue.
- [x] Criterion 7: The app at this state is the MVP deadline deliverable.

## Merge Gate
- [x] All Group verifies in plan.md pass:
  - Client analysis: `cd client && flutter analyze` → `No issues found!`
  - Client tests: `flutter test` → `29 passed, 0 failed`
  - Backend lint: `npm run lint` → 0 errors
  - Backend unit tests: `npm test` → `7 suites passed, 29 passed`
  - Backend e2e tests: `npm run test:e2e` → `3 suites passed, 16 passed`
- [x] Phase integrates cleanly without breaking prior phases.
- [x] No mocks/stubs in production client/backend code.
- [x] No debug console.log or print statements in production code: `rg 'print\(|console\.(log|debug)\(' client/lib backend/src` exited with code 1.
- [x] Installed dependency versions match pinned versions in `tech-stack.md`.
- [x] Demo-able: On device/simulator — launch → home header layout with avatar + pills → quick-access grid + horizontal shelf → play track → floating mini-player & now playing → Library with pinned playlists & sort → Profile sidebar drawer → Create modal sheet.