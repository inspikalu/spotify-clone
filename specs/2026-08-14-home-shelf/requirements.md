# Requirements: Phase 3 — Home Shelf + Library Polish (MVP Deadline Deliverable)

## Scope
- **In**:
  - Home tab rebuilt as the MVP Home: a single "All uploaded tracks" shelf (horizontal scroll, Spotify-style cards: cover art + title + artist), fed by the real `tracksProvider` / `GET /tracks` (no mocked catalog).
  - Tap a shelf card → real playback via the existing `playbackControllerProvider` + NowPlaying screen opens (same controller/navigation pattern as MiniPlayer).
  - Home loading / error+retry / empty states (consistent with Library's existing four-state pattern).
  - Phase 1 logout preserved on Home (AppBar action) — no capability regression.
  - Library polish: section header + track count; ordering already newest-first from the backend (`GET /tracks` is `orderBy: { createdAt: 'desc' }`) — no client sort added.
  - Full-suite regression verification (Phase 1 + Phase 2 tests stay green), on-device walkthrough, and the deadline-state commit.
- **Out**:
  - Multi-shelf curation, "Made for you", genre grids, gradient hero headers — deferred to Phase 5/6 per `roadmap.md`.
  - Search functionality — Search tab stays an empty state (Phase 5).
  - Queue behavior from the shelf (shelf tap plays a single track; queue/shuffle/repeat remain as built in Phase 2, driven from Now Playing) — stakeholder decision 2026-08-14.
  - Any backend changes — the backend is untouched this phase (its `GET /tracks` already returns newest-first with cover URLs).

## Key Decisions
- Shelf = one horizontal row of ~150px cards (cover 140x140, title/artist) under a "All uploaded tracks" header — matches the roadmap's "single shelf" MVP wording; multi-shelf is Phase 5.
- Shelf tap-to-play = `playTrack(track)` + `Navigator.push(NowPlayingScreen)`, mirroring `mini_player.dart`'s existing push — one playback path everywhere, no new controller logic.
- Logout moves to the Home AppBar — Home's old body is being replaced; logout must not disappear with it (Phase 1 walkthrough capability).
- Library header/count only — no sort work because the backend already returns `createdAt desc` (verified in `tracks.service.ts:151`).
- No new dependencies, no tech-stack changes: shelf uses `cached_network_image` (covers), `flutter_riverpod` (`tracksProvider`), and the existing playback/player stack.

## Context from mission.md
- Core User Story 3 ("browse curated shelves… on a Home screen") — served in its minimal MVP form: one shelf over the real catalog; the full curated multi-shelf design is explicitly sequenced to Phase 5/6.
- Core User Story 4 ("upload my own audio tracks…") — Library already lists the uploaded catalog; this phase polishes that list (header + count) and surfaces it on Home.
- Core User Story 5 ("full playback controls… persist in the background") — shelf taps drive the existing Phase 2 playback pipeline end-to-end.

## Context from tech-stack.md
- Client stack used: `flutter_riverpod ^2.6.x` (state), `cached_network_image ^3.4.1` (shelf cover art — required for smooth 60fps shelf scrolling).
- Playback stack (`just_audio ^0.10.6`, `audio_service ^0.18.19`, `just_audio_background ^0.0.1-beta.17`) is unchanged — shelf reuses `playbackControllerProvider`.
- Pinned versions this phase depends on: `cached_network_image ^3.4.1` (verify via `flutter pub deps`), `flutter_riverpod ^2.6.x`.
- Known Issues carried forward (verbatim from tech-stack.md, relevant to this phase):
  - **"Silent playback despite the UI playing":** uploaded tracks' `coverUrl` (and the client's derived audio URL) are Supabase public URLs baked at upload time (`http://127.0.0.1:54323/storage/v1/object/public/...`); from the device `127.0.0.1:54323` points at the phone → ExoPlayer `HttpDataSourceException: Failed to connect to /127.0.0.1:54323`. Fixed for the walkthrough with `adb reverse tcp:54323 tcp:54323` (same pattern as `:3000`). NOTE for later phases: URLs are baked with the dev-machine's Supabase address — a real deployment must rewrite/serve these URLs via the API (or configure a public storage domain). **Impact on this phase:** the Home shelf's cover art is a `cached_network_image` over the same baked URLs — on-device walkthrough requires the `54323` reverse to be active (plan.md Group 3 device prereqs).

## User Stories Addressed
- US3 (browse shelves on Home) — minimal single-shelf version; multi-shelf flagged as Phase 5, not scope creep here.
- US4 (upload → playable catalog) — Library list polish; no new upload surface.
- US5 (playback controls) — shelf tap enters the existing playback flow.
- No other stories are pulled in; anything beyond the above would be scope creep and must be flagged, not built.

## Engineering Standards (carried from specs/engineering-standards.md)
- **Mocks / Stubs / Placeholder Data**: "**Default: forbidden.** No mocked API responses, no hardcoded 'sample' tracks/playlists standing in for real database records, no fake auth bypass, anywhere in committed code — including the MVP phase in `roadmap.md`. The one-day MVP must be a real, thin *slice* (fewer features), not a fake version of the full feature set. The only exception: seed/fixture data explicitly labeled as a database seed script (e.g. `prisma/seed.ts`) used to populate a dev/demo environment with realistic-looking rows — this is not the same as mocking application logic, and must still flow through the real upload/auth code paths, not bypass them." Widget tests use the established fake-repository pattern from `test/fakes.dart` — fakes exist only in test code, never in `lib/`.
- **Debug Logging**: "No `console.log` / `print` / ad-hoc debug statements left in committed code. Use the NestJS `Logger` class server-side and structured, removable debug prints client-side only when explicitly requested for a specific diagnostic reason — and remove them before the feature is marked done."
- **Definition of Done**: both (1) every acceptance criterion has a passing automated check (widget tests for the shelf states and tap behavior, updated Library test for the count label) and (2) one manual on-device walkthrough of the real flow (sign in → Home shelf of real uploaded tracks → tap → real playback → Library polish → regression) confirmed working.
- **What Counts as a Passing Verify Step**: every `Verify` bullet in plan.md is a literal command + exact expected output, or literal manual steps + exact expected screen state (all Group verifies above satisfy this).
- **Rollback Policy**: "**Default: revert.** On an unrecoverable Verify failure, the executor reverts the failing group's changes back to the last passing group's committed state (`git reset --hard <last-good-commit>` or equivalent) and reports BLOCKED against a clean tree. Partial/broken changes are not left in place unless a future spec explicitly states otherwise for a specific group."

## Design Reference (stakeholder-provided)
- Real Spotify screenshots committed at `specs/references/spotify-screenshots/` (6 jpgs, 2026-08-14). These are the visual source of truth for this phase's Home shelf and Library layout decisions — the executor must match spacing, card proportions, text sizing, and hierarchy to them as closely as the Flutter theme allows.
- Note: the theme already approximates Spotify tokens (Inter/Manrope font, dark background, green accent per tech-stack.md); this phase only adjusts layout structure, not the token system.
- Caveat for reviewers: the spec author could not view the images directly (no vision in the authoring model); the mapping of which screenshot shows which screen (Home / Library / Now Playing / Search) was not verified visually. If any layout detail conflicts with a screenshot, the screenshot wins and the executor should note the deviation in the execution report.

## External Dependencies
- No new credentials, APIs, or services. Existing, per `resources.md`:
  - Device `R3CR203BN8B` (USB) + the two real mp3s already pushed to `/sdcard/Download/` (Famous-Pluto, Rema-TEA) — walkthrough audio.
  - Local Supabase (API 54323, Postgres 54324) + local NestJS on `:3000` — already running; `adb reverse` for `3000` and `54323` required for on-device access.