# Validation: Phase 3 — Home Shelf + Library Polish (MVP Deadline Deliverable)

## Acceptance Criteria
- [ ] Criterion 1: Home tab renders a real "All uploaded tracks" shelf — track cards (cover art, title, artist) come from `GET /tracks` via `tracksProvider`, never hardcoded.
- [ ] Criterion 2: Home has all four states — loading spinner, error message + working Retry, "No tracks yet" empty state, populated shelf.
- [ ] Criterion 3: Tapping a shelf card starts real playback (sound on device) and opens Now Playing; playback controls (seek/next/prev/shuffle/repeat) work from there.
- [ ] Criterion 4: Logout still works from the Home AppBar and returns to SignInScreen.
- [ ] Criterion 5: Library shows a header with the track count (e.g. `1 track` / `2 tracks`) and lists tracks newest-first (backed by the backend's `createdAt desc` ordering).
- [ ] Criterion 6: No regression — sign in, upload (progress bar → row), Library states, MiniPlayer, Now Playing, notification/lock-screen playback, auto-login all still pass as in Phase 2.
- [ ] Criterion 7: The app at this state is the MVP deadline deliverable — committed as `Phase 3: MVP deadline deliverable`.

## Merge Gate
- [ ] All Group verifies in plan.md pass, with pasted evidence (not paraphrase) for each
- [ ] Phase integrates without breaking prior phases: backend suite (`Test Suites: 7 passed, 7 total` / `Tests: 29 passed, 29 total`), client full suite (all green, exact `+N` recorded), e2e (`3 passed / 16 passed`)
- [ ] lint/typecheck clean: `cd client && flutter analyze` → `No issues found!`; `cd backend && npm run lint` → empty output, exit 0
- [ ] No mocks/stubs/placeholder logic outside what engineering-standards.md explicitly permits (fakes confined to `test/`)
- [ ] No debug console.log/print statements left in code: `rg 'print\(|console\.(log|debug)\(' client/lib backend/src` → exit 1 (no matches)
- [ ] Installed dependency versions match tech-stack.md's pinned versions — run `cd client && flutter pub deps | grep -E 'cached_network_image|flutter_riverpod'` and `cd backend && npm list music-metadata multer @nestjs/platform-express`, paste output (majors: `cached_network_image 3.4.1`, `flutter_riverpod ^2.6.x`, `music-metadata 7.14.0`, `multer 2.2.0`, `@nestjs/platform-express 11.x`)
- [ ] Diff summary reviewed — run `git diff --stat ea4274b..HEAD`, paste output, confirm the changed-file list matches plan.md Group 3's diff-review bullet (only `client/lib/features/home/home_screen.dart`, `client/lib/features/tracks/library_screen.dart`, `client/test/home_screen_test.dart`, `client/test/nav_shell_test.dart`, new Library count-label tests, `specs/2026-08-14-home-shelf/*`)
- [ ] Demo-able: on the device — launch → auto-login → Home shows the shelf of real uploaded tracks → tap a card → sound + Now Playing → Library shows the count and newest-first list → kill and relaunch → everything persists. This is the deadline demo.