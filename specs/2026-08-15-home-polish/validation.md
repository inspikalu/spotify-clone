# Validation: Phase 6 — Home Polish

## Acceptance Criteria
- [ ] Home screen displays multiple horizontal shelves ("Recently played", "Made for you", "Popular releases") with smooth horizontal scrolling.
- [ ] Tapping any card in any horizontal shelf begins immediate playback with the full shelf queue and opens the player.
- [ ] Listening to a song updates the "Recently played" shelf dynamically and persists across app restarts.
- [ ] Top filter pills (`All`, `Music`, `Podcasts`) dynamically toggle visible content and display tailored views.
- [ ] Dynamic ambient gradients adapt to cover art color across Playlist detail hero header and Now Playing screen background.

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
- [ ] Demo-able: Home screen with rich multiple shelves, interactive category pills, instant shelf playback, and dynamic cover art ambient gradients.
