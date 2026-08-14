# Requirements: Phase 2 — Upload + Playback

## Scope
- **In**
  - Backend: multipart `POST /tracks` (audio file + `title`/`artist`/`album?` fields + optional `cover` image) with multer diskStorage (temp file, streamed to storage — never held in server memory), server-side duration extraction via `music-metadata` (`parseFile` on the real file — never client-reported duration), MIME allowlist (audio: mpeg/mp4/m4a/wav/ogg/flac/aac/webm; cover: image only), 100MB audio / 5MB cover limits, auth via the existing `JwtAuthGuard`.
  - Backend: Supabase Storage (local CLI instance, offset ports) — new private bucket `audio` (signed-URL access only, 1h expiry, minted per `GET /tracks`) and public bucket `covers`; backend storage access via the Storage REST API with Node's built-in `fetch` + service-role key (no new SDK dependency).
  - Backend: Prisma migration — `Track.audioStorageKey` (object key in the audio bucket).
  - Backend: `GET /tracks` — owner-scoped list of the caller's tracks with freshly-minted signed `audioUrl` + public `coverUrl`.
  - Client: bottom-nav shell (Home / Search / Library) — the Phase 0 shell, deferred to Phase 2; Library hosts the track list; Home = the existing real screen (`Signed in as <email>` + Log out); Search = real empty state. No fake data anywhere.
  - Client: Library track list (loading / error+retry / empty / data states, pull-to-refresh, cover thumbnails via `cached_network_image`).
  - Client: upload UI via `file_picker` (audio + cover selection, title/artist required, album/cover optional, upload progress bar, dio FormData).
  - Client: playback via `just_audio` + `audio_service` + `just_audio_background` (the official bridge — no hand-rolled `AudioHandler`): play/pause/skip(prev/next, wrapping)/seek/queue/shuffle/repeat (off/one/all), mini-player above the nav bar, full Now Playing screen, background playback with media notification + lock-screen controls + artwork (Android `audio_service` service entries + `POST_NOTIFICATIONS`, iOS `UIBackgroundModes: audio`).
  - Queue/shuffle/repeat: **IN** per stakeholder decision (2026-08-14) — expands roadmap Phase 2's floor scope; traces to mission Core User Story 5.
- **Out**
  - Playlists, Liked Songs, likes (roadmap Phase 4).
  - Search functionality (roadmap Phase 5 — Search tab is a real empty state only).
  - Home curated shelves (roadmap Phase 3/6 — Home tab is the existing real signed-in screen).
  - Editing/deleting uploaded tracks; re-upload.
  - Transcoding: playback uses the raw uploaded file (ExoPlayer handles the allowlisted formats natively).
  - Resumable uploads, background-upload, upload retry.
  - Pagination of the track list (fine at MVP catalog scale).
  - Multi-user catalog browsing/sharing (target user is a single listener of a personal/shared catalog).
  - iOS on-device walkthrough (no iOS device available) — iOS platform config is still added for correctness.
  - The existing `Track.audioUrl` DB column is left unused this phase (replaced by `audioStorageKey` + per-request signed URLs); documented, not dropped.
  - Apple/Facebook auth (Phase 7); anything in user stories 1–2, 6 not listed above.

## Key Decisions
- **Storage client = REST + built-in `fetch`** — no `@supabase/supabase-js` SDK. The storage operations needed (create bucket, upload, signed URL, delete) are thin REST calls on `http://127.0.0.1:54323/storage/v1/*`; Node 22's global `fetch` covers them, keeps the dependency surface flat, and every call stays curl-verifiable.
- **Signed URLs minted per request** — `GET /tracks` returns each track's `audioUrl` as a fresh 1h signed URL from the private bucket. The DB never stores a long-lived audio URL (they expire); it stores the object key (`audioStorageKey`). Covers live in a public bucket with a permanent public URL (`coverUrl`).
- **Object keys**: `audio/<trackId>.<ext>` and `covers/<trackId>.<ext>` — deterministic, collision-free (trackId is a cuid), trivially deletable with the row.
- **Server-side duration is the only trusted duration** — `music-metadata.parseFile` on the temp file before the row is created; the client sends no duration at all.
- **Queue/shuffle/repeat in Phase 2** — stakeholder decision; traces to mission story 5 (full playback controls). Implemented in the PlaybackController over a thin `AudioEngine` interface (swap-able for tests) — no production mocks.
- **just_audio_background instead of a custom AudioHandler** — stakeholder-approved tech-stack addition; it is the official bridge that maps `just_audio` state to `audio_service`'s notification/lock-screen.
- **Upload form fields**: `title` + `artist` required, `album` + `cover` optional (matches the nullable schema columns).
- **Multer diskStorage + stream to storage** — honors tech-stack's "streamed to object storage (not held in server memory/disk longer than necessary)"; temp files are unlinked after upload in all paths.

## Context from mission.md
- Core User Story 4 (upload own audio with title/artist/album/cover metadata) — upload endpoint + UI.
- Core User Story 5 (full playback controls — play/pause/skip/seek/queue/shuffle/repeat — persisting in the background) — playback engine, mini-player, Now Playing, background notification.
- Core User Story 3 (browse shelves on Home) — not this phase; Home tab is the existing signed-in screen, shelves are Phase 3/6.
- Single-end-user target: all catalog operations are owner-scoped to the signed-in user.

## Context from tech-stack.md
- Client: `just_audio ^0.9.x` + `audio_service ^0.18.x` + `just_audio_background ^0.0.1-beta.x` (added this phase), `cached_network_image ^3.x`, `file_picker ^8.x` (added this phase), `dio` — NOTE: tech-stack pins `dio ^4.x` but Phase 1 execution resolved `^5.11.0` (pub.dev security advisories GHSA-9324-jv53-9cc8 / GHSA-jwpw-q68h-r678; interceptor API identical) — carry the deviation, do not re-pin 4.x. Flutter `3.44.x`, Dart `3.12.x`. **Group 2 version resolution**: `just_audio` → `^0.10.6`, `file_picker` → `^11.0.3` (both resolved from the plan's constraints; API deltas handled in code — see Change Log).
- Backend: NestJS `^11.1.x`, Node `22.x LTS` (host runs v24.14.0 — Phase 1 ran on it without issue), Prisma `^6.x` (installed `6.19.3`), `music-metadata` **`^7.14.0` — pinned, NOT latest** (v8+ is pure ESM and breaks both the CommonJS build (TS1479) and jest (`--experimental-vm-modules` required); 7.14.0 is the last CJS release — see tech-stack.md Known Issues), `multer` `^2.x`, `@nestjs/platform-express ^11.x`.
- Storage: Supabase Storage on the local CLI instance — `audio` bucket private (signed URLs only; "don't allow direct anonymous streaming links to bypass auth"), `covers` bucket public.
- **Pinned versions this phase depends on** (executor verifies installed versions match in Group 6): `just_audio ^0.10.6` (resolved; plan wrote ^0.9.x), `audio_service ^0.18.19`, `just_audio_background ^0.0.1-beta.17`, `cached_network_image ^3.4.1`, `file_picker ^11.0.3` (resolved; plan wrote ^8.x), `@nestjs/platform-express ^11.x`, `Prisma ^6.x` (6.19.3 installed), `music-metadata ^7.14.0` (pinned — see above).
- **Known Issues carried forward verbatim** (from tech-stack.md `## Known Issues`):
  1. "**Local Supabase health checks unreliable on this host**: `supabase start` fails with `container is not ready: unhealthy` for realtime/storage/studio even though their logs show "Server listening / Started Successfully" (storage-api v1.61.7, past the known v1.41.8 race fixed upstream). Workaround: `supabase start --ignore-health-check`, then verify DB connectivity directly (Prisma/psql), never via the container health state. Phase 2 must re-verify storage service health before relying on it. Source: observed 3 consecutive failing runs + supabase/cli issues #4632/#4941." — **active for this phase**: Group 1 verifies storage health via the bucket-list REST call before any upload code depends on it.
  2. "**Local dev host port collision**: this machine runs a pre-existing unrelated Supabase docker stack on the CLI defaults 54321 (API) / 54322 (Postgres). Our local instance must keep the offset ports (API 54323, Postgres 54324, Studio 54325, etc.) configured in `supabase/config.toml`; `supabase start` without offsets will collide. Source: observed `docker ps` port mappings on this host." — **active**: all storage URLs use port 54323.
  3. "**Prisma × Supabase connection**: use the *direct* Postgres connection (port 5432) as `DATABASE_URL` for `prisma migrate`. Supabase's pooler (port 6543, transaction mode) breaks Prisma migrations and prepared-statement usage in some configurations. Pinning the direct port sidesteps a known class of P1001/P2010 failures. (Local instance: direct port 54324, no pooler.)" — **active**: migrations run against `127.0.0.1:54324`.
  4. Resend sandbox entry — **not applicable** to this phase (no email work).

## User Stories Addressed
- Mission story **4** (upload tracks with metadata) → `POST /tracks`, upload UI, Library list.
- Mission story **5** (playback controls incl. background persistence) → playback engine, mini-player, Now Playing, queue/shuffle/repeat (stakeholder-expanded), media notification/lock-screen.
- Mission story **3** (browse/discover on Home) → only the shell structure this phase (Home content is Phase 3); the Library track list serves story 4's catalog visibility.
- Everything else in mission.md is explicitly deferred (see Out) — no scope creep added.

## Engineering Standards (carried from specs/engineering-standards.md)
- **Mocks / Stubs / Placeholder Data** (verbatim): "**Default: forbidden.** No mocked API responses, no hardcoded "sample" tracks/playlists standing in for real database records, no fake auth bypass, anywhere in committed code — including the MVP phase in `roadmap.md`. The one-day MVP must be a real, thin *slice* (fewer features), not a fake version of the full feature set. The only exception: seed/fixture data explicitly labeled as a database seed script (e.g. `prisma/seed.ts`) used to populate a dev/demo environment with realistic-looking rows — this is not the same as mocking application logic, and must still flow through the real upload/auth code paths, not bypass them." — this phase adds no seed data; the only test doubles are in `*.spec.ts`/`test/` files.
- **Debug Logging** (verbatim): "No `console.log` / `print` / ad-hoc debug statements left in committed code. Use the NestJS `Logger` class server-side and structured, removable debug prints client-side only when explicitly requested for a specific diagnostic reason — and remove them before the feature is marked done." — Group 6 greps for violations.
- **Definition of Done (Production)** (verbatim): "A feature is done when: 1. Every acceptance criterion in its feature-spec has a passing **automated check** (unit/integration/widget test as appropriate), and 2. One **manual walkthrough** of the real user flow has been performed end-to-end (real signup → real upload → real playback, not a stubbed path) and confirmed working. Both are required. A green test suite alone does not count as done; neither does "looks right in a screenshot" alone." — Group 5 is that manual walkthrough.
- **What Counts as a Passing Verify Step** (verbatim): "Every `Verify` bullet in any future `plan.md` must be one of: A literal shell/test command plus the exact expected output (e.g. `npm run test auth.service.spec.ts` → `Tests: 4 passed, 4 total`), or If no command exists (e.g. a UI interaction), the literal manual steps plus the exact expected screen state (e.g. "tap Sign Up with a valid email → redirected to Home screen, mini-player hidden, top-left avatar shows initials"). Vague verifies ("confirm it works," "check that auth is fine") are invalid and must be rewritten before a spec is accepted." — every Verify in plan.md conforms.
- **Rollback Policy** (verbatim): "**Default: revert.** On an unrecoverable Verify failure, the executor reverts the failing group's changes back to the last passing group's committed state (`git reset --hard <last-good-commit>` or equivalent) and reports BLOCKED against a clean tree. Partial/broken changes are not left in place unless a future spec explicitly states otherwise for a specific group." — applies unchanged.

## External Dependencies
- No new credentials beyond resources.md: local Supabase CLI instance provides Storage + the service-role key (from `supabase status` in the repo root) — nothing to purchase or sign up for.
- `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` / bucket names land in `backend/.env` (gitignored) and `backend/.env.example` (empty values, committed).
- Stakeholder-provided: one real rights-owned audio file (mp3/m4a) for the on-device walkthrough, phone `R3CR203BN8B` with USB debugging, `adb` access.
- Existing (unchanged) creds used by this phase's walkthrough: `API_BASE_URL` dart-define, Google web client ID dart-define for the prebuilt APK (Phase 1 value), backend JWT/Resend/Google env already in place.

## Change Log
- [2026-08-14] Group 2: version resolutions — `just_audio ^0.10.6` (plan wrote `^0.9.x`) and `file_picker ^11.0.3` (plan wrote `^8.x`) are what `flutter pub get` resolves today; both compile clean under Flutter 3.44. `file_picker` 11.x API deltas: no `FilePicker.platform` instance — static `FilePicker.pickFiles(...)`; test seam is `FilePickerPlatform.instance` (internal import, `implementation_imports` lint suppressed in the one test file). Logged to tech-stack.md Change Log + Known Issues.
- [2026-08-14] Group 2: `refreshTracksProvider` from the plan was not created — Riverpod's `ref.invalidate(tracksProvider)` is the idiomatic manual refresh (used for pull-to-refresh, Retry, and post-upload refresh) and needs no extra provider.
- [2026-08-14] Group 2: upload flow on success pops `true` and the Library caller invalidates `tracksProvider` (row appears immediately) — the plan's "snackbar `Track uploaded`" was dropped as redundant with the visible list change.
- [2026-08-14] Group 2: Library row taps are inert until Group 3 wires them to `playbackControllerProvider` (plan-authorized no-op while Group 3 lands immediately after; Group 5 walkthrough covers the wired path).
- [2026-08-14] Group 2: test count +7 (plan said +6): `tracks_repository_test.dart` has 4 tests (added a multipart `FormData` shape test — the plan's "parses JSON list", "surfaces API error", and "passes signed audioUrl through" were folded into 3; the 4th covers `uploadTrack` fields/files/optionality required by the upload acceptance criteria), plus 2 upload-screen widget tests and 1 nav-shell widget test. Full client suite: 17 passing (10 Phase 1 + 7 new); `flutter analyze` clean.
- [2026-08-14] Group 3: `AudioEngine.setQueue` takes `List<AudioQueueEntry>` (record: uri + title/artist/album/artUri) instead of the plan's `List<Uri>` — the notification/lock-screen needs `MediaItem` metadata per track and the record is the minimal carrier. just_audio 0.10 deprecates `ConcatenatingAudioSource` → `player.setAudioSources(...)`.
- [2026-08-14] Group 3: no engine-level shuffle — the `PlaybackController` owns the play order (`playOrder` in state) so shuffle is deterministic in tests (seed via `randomProvider` override); `next`/`previous` map playOrder → engine source index.
- [2026-08-14] Group 3: `JustAudioBackground.init` param is `notificationColor:` (0.0.1-beta.17), not `androidNotificationColor:`.
- [2026-08-14] Group 3: client suite now 23 passing (17 + 6 new); `flutter analyze` clean.
- [2026-08-14] Group 4: Now Playing repeat button uses `repeat` icon for both off and all modes (Flutter ships no distinct all-mode glyph); highlight + tooltip convey the mode.
- [2026-08-14] Group 4: widget tests seed a `ProviderContainer` and pump via `UncontrolledProviderScope` — `ProviderScope(container:)` was removed in flutter_riverpod 2.6.1. Shared `test/fakes.dart` holds `FakeAudioEngine` + `testTrack`.
- [2026-08-14] Group 4: client suite now 27 passing (23 + 4); `flutter analyze` clean.
