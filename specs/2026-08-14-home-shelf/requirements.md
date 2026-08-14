# Requirements: Phase 3 — Home Shelf + Library Polish (MVP Deadline Deliverable)

## Scope
- **In**:
  - Home tab rebuilt as the MVP Home: profile avatar (initials circle, top-left, opens a menu incl. Log out — preserves the Phase 1 logout capability), and a single "All uploaded tracks" horizontal shelf of square cards (cover art + title + artist), fed by the real `tracksProvider` / `GET /tracks` (no mocked catalog).
  - Tap a shelf card → real playback via the existing `playbackControllerProvider` + Now Playing screen opens (same pattern as MiniPlayer).
  - Home loading / error+retry / empty states.
  - Library polish to match the real app's layout: "Your Library" header, a "↓↑ Recents" ↔ "A–Z" sort toggle (Recents = backend's existing `createdAt desc`; alphabetical = client-side title sort), and row subtitles in Spotify's format ("Album • artist" when an album is set, else "Single • artist").
  - Full-suite regression verification (Phase 1 + Phase 2 tests stay green), on-device walkthrough, and the deadline-state commit.
- **Out** (deferred, with reasons):
  - Filter pills (All/Music/Podcasts), grid view toggle, Library search — need a track-type taxonomy and search; those are Phase 5 scope.
  - Multi-shelf curation, "New Music Friday"-style editorial carousels, Recents/Show all, video cards — Phase 5/6 per `roadmap.md`.
  - **Create tab (real Spotify's 4th tab)** — flagged deviation: `roadmap.md` Phase 0 locked the bottom nav to Home/Search/Library; a Create modal would list Playlist/Collaborative/Blend/AI/Jam options that don't exist in our data model yet (playlists are Phase 4), and building it with dead rows would be placeholder UI (forbidden by engineering-standards). Revisit when playlists land in Phase 4.
  - Library "N tracks" count label — dropped: the stakeholder's real-Spotify screenshots (added as reference) show no count in the real Library; the visual reference supersedes the earlier polish idea.
  - Any backend changes — the backend is untouched this phase (`GET /tracks` already returns newest-first with cover URLs).

## Key Decisions
- Shelf = one horizontal row of 160px-square cover cards (rounded ~8px) with bold white title + gray artist beneath — matches the roadmap's "single shelf" MVP wording AND the stakeholder's screenshots (Recents-style card anatomy); multi-shelf is Phase 5.
- Shelf tap-to-play = `playTrack(track)` + `Navigator.push(NowPlayingScreen)`, mirroring `mini_player.dart`'s existing push — one playback path everywhere, no new controller logic.
- Avatar circle (email initials) replaces the old full-width "Signed in as X" body; tapping it opens a small menu with "Log out" — real-Spotify placement, Phase 1 logout capability preserved.
- Library sort toggle is real: two states cycling (Recents → A–Z → Recents); Recents is the backend's existing order, A–Z is a client-side title sort of the fetched list. Toggle state is local widget state (no new providers needed).
- Library row subtitle: `Album • artist` when `album != null`, else `Single • artist` — mirrors the real "EP • artist" / "Single • artist" formats with the data we actually have.
- No new dependencies, no tech-stack changes: shelf uses `cached_network_image` (covers), `flutter_riverpod` (`tracksProvider`), and the existing playback/player stack.

## Context from mission.md
- Core User Story 3 ("browse curated shelves… on a Home screen") — served in its minimal MVP form: one shelf over the real catalog; the full curated multi-shelf design is explicitly sequenced to Phase 5/6.
- Core User Story 4 ("upload my own audio tracks…") — Library already lists the uploaded catalog; this phase polishes that list to the real app's layout.
- Core User Story 5 ("full playback controls… persist in the background") — shelf taps drive the existing Phase 2 playback pipeline end-to-end.

## Context from tech-stack.md
- Client stack used: `flutter_riverpod ^2.6.x` (state), `cached_network_image ^3.4.1` (shelf cover art — required for smooth 60fps shelf scrolling).
- Playback stack (`just_audio ^0.10.6`, `audio_service ^0.18.19`, `just_audio_background ^0.0.1-beta.17`) is unchanged — shelf reuses `playbackControllerProvider`.
- Pinned versions this phase depends on: `cached_network_image ^3.4.1` (verify via `flutter pub deps`), `flutter_riverpod ^2.6.x`.
- Known Issues carried forward (verbatim from tech-stack.md, relevant to this phase):
  - **"Silent playback despite the UI playing":** uploaded tracks' `coverUrl` (and the client's derived audio URL) are Supabase public URLs baked at upload time (`http://127.0.0.1:54323/storage/v1/object/public/...`); from the device `127.0.0.1:54323` points at the phone → ExoPlayer `HttpDataSourceException: Failed to connect to /127.0.0.1:54323`. Fixed for the walkthrough with `adb reverse tcp:54323 tcp:54323` (same pattern as `:3000`). NOTE for later phases: URLs are baked with the dev-machine's Supabase address — a real deployment must rewrite/serve these URLs via the API (or configure a public storage domain). **Impact on this phase:** the Home shelf's cover art is a `cached_network_image` over the same baked URLs — on-device walkthrough requires the `54323` reverse to be active (plan.md Group 3 device prereqs).

## Design Reference (stakeholder-provided, screenshots committed)
- Real Spotify screenshots: `specs/references/spotify-screenshots/` (6 jpgs, committed `1a65ebc`). These are the visual source of truth for layout decisions in this phase.
- Stakeholder's written breakdown (2026-08-14) of all six screens, encoded into this spec:
  - **Global tokens**: pure black (`#000000`) background everywhere; white primary text; gray `#B3B3B3` secondary text; Spotify green (`#1DB954`) accents; rounded corners ~8px on thumbnails/cards; pill-shaped filter buttons; mini player sticky above the bottom nav on every screen.
  - **Home**: profile avatar circle top-left; bold white section headers; horizontal carousels of square/portrait cards with title + subtitle beneath; "Recents"-style cards = square thumbnail + title/subtitle under the art.
  - **Library**: "Your Library" title top-left; filter pill row (deferred); sort row with "↓↑ Recents" toggle left; list rows = square thumbnail + title + subtitle (format: `EP • artist` / `Playlist • owner` / `Album • artist` / `Single • artist`); download/pin icon indicators (not applicable to our catalog — omitted, not faked).
  - **Mini player**: small square art thumbnail, track title / artist, right-aligned controls, thin progress bar under the player (already matches Phase 2's implementation).
- Caveat: the spec author could not view the images directly (no vision in the authoring model); the written breakdown above was provided by the stakeholder and is treated as authoritative. If any layout detail conflicts with a screenshot, the screenshot wins and the executor notes the deviation in the execution report.

## User Stories Addressed
- US3 (browse shelves on Home) — minimal single-shelf version; multi-shelf flagged as Phase 5, not scope creep here.
- US4 (upload → playable catalog) — Library list polish; no new upload surface.
- US5 (playback controls) — shelf tap enters the existing playback flow.
- No other stories are pulled in; the Create tab and filter pills would be scope creep at this phase (see Out) and are explicitly flagged, not built.

## Engineering Standards (carried from specs/engineering-standards.md)
- **Mocks / Stubs / Placeholder Data**: "**Default: forbidden.** No mocked API responses, no hardcoded 'sample' tracks/playlists standing in for real database records, no fake auth bypass, anywhere in committed code — including the MVP phase in `roadmap.md`. The one-day MVP must be a real, thin *slice* (fewer features), not a fake version of the full feature set. The only exception: seed/fixture data explicitly labeled as a database seed script (e.g. `prisma/seed.ts`) used to populate a dev/demo environment with realistic-looking rows — this is not the same as mocking application logic, and must still flow through the real upload/auth code paths, not bypass them." Widget tests use the established fake-repository pattern from `test/fakes.dart` — fakes exist only in test code, never in `lib/`.
- **Debug Logging**: "No `console.log` / `print` / ad-hoc debug statements left in committed code. Use the NestJS `Logger` class server-side and structured, removable debug prints client-side only when explicitly requested for a specific diagnostic reason — and remove them before the feature is marked done."
- **Definition of Done**: both (1) every acceptance criterion has a passing automated check (widget tests for the shelf states/tap, sort toggle, subtitle format, header) and (2) one manual on-device walkthrough of the real flow (sign in → Home shelf of real uploaded tracks → tap → real playback → Library layout + sort → regression) confirmed working.
- **What Counts as a Passing Verify Step**: every `Verify` bullet in plan.md is a literal command + exact expected output, or literal manual steps + exact expected screen state (all Group verifies above satisfy this).
- **Rollback Policy**: "**Default: revert.** On an unrecoverable Verify failure, the executor reverts the failing group's changes back to the last passing group's committed state (`git reset --hard <last-good-commit>` or equivalent) and reports BLOCKED against a clean tree. Partial/broken changes are not left in place unless a future spec explicitly states otherwise for a specific group."

## External Dependencies
- No new credentials, APIs, or services. Existing, per `resources.md`:
  - Device `R3CR203BN8B` (USB) + the two real mp3s already pushed to `/sdcard/Download/` (Famous-Pluto, Rema-TEA) — walkthrough audio.
  - Local Supabase (API 54323, Postgres 54324) + local NestJS on `:3000` — already running; `adb reverse` for `3000` and `54323` required for on-device access.