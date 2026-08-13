# Requirements: Phase 1 — Auth (incl. Phase 0 groundwork)

## Scope
- **In**:
  - Phase 0 groundwork required by auth: git repo + baseline commit (rollback anchor), Supabase free-tier project, Prisma schema with the full Phase 0 data model (User, Track, Playlist, PlaylistTrack, LikedTrack) migrated to Supabase, NestJS skeleton (`auth` + `users` modules, health check with DB ping), Flutter project with theme tokens, Riverpod, dio, secure storage.
  - Email/password signup + login; JWT access (15m) + refresh (30d) tokens with rotation; `GET /auth/me`.
  - Auto-login on relaunch (validates stored tokens, single refresh-on-401 retry); logout (client discards both tokens).
  - Google OAuth: native `google_sign_in` → ID token → server `google-auth-library` verification → upsert User → token pair.
  - Password reset (stakeholder-approved addition): `POST /auth/forgot-password` → Resend email with deep-link token → `POST /auth/reset-password`; custom scheme `spotifyclone://auth/reset?token=...` handled on cold start.
  - Post-auth landing screen (email + logout) — minimal, real.
  - Automated tests per engineering-standards Definition of Done: 18 backend unit tests, 12 backend e2e tests, 7 client tests, plus manual on-device walkthrough.
- **Out** (explicitly deferred, no contradictions with In):
  - Facebook and Apple OAuth (roadmap defers; Apple gated on a paid Developer account per resources.md).
  - Server-side refresh-token revocation / server `logout` endpoint — stateless refresh tokens; revocation is a Phase 8 hardening item.
  - Email verification, profile editing, "change password" (only reset is in scope).
  - Empty `tracks`/`playlists` NestJS module scaffolding — created in their own phases with real content, not as dead structure now.
  - 3-tab bottom nav shell (Home/Search/Library) — deferred to Phase 2 where it gets real content; this phase's landing is the minimal authenticated screen.
  - Deep-link handling on warm launch (app already running when the link arrives) — cold-start handling only this phase.
  - iOS build/run — host is Linux, no iOS simulator; iOS platform code is generated for a future macOS host, Android emulator is the on-device verification target.
  - `go_router` or any router package — named routes driven by Riverpod auth state suffice for this phase.

## Key Decisions
- **Full Phase 0 schema migrated now** (all 5 models), even though auth only touches `User` — avoids a second migration when Phase 2 lands, and honors roadmap.md's Phase 0 schema.
- **Stateless refresh tokens, no session table**: refresh is a signed JWT with rotation; logout = client discards tokens. Keeps roadmap's 5-model data model intact; server-side revocation deferred to Phase 8 and flagged there.
- **Reset tokens are purpose-scoped signed JWTs** (`purpose: "password_reset"`, 15m), not DB rows — no schema change, and the `forgot-password` endpoint returns 202 for known and unknown emails alike (no user enumeration).
- **Google flow is the native mobile pattern**: `google_sign_in` (client) + `google-auth-library.verifyIdToken` (server, audience = Web client ID). `passport-google-oauth20` stays pinned for any future web redirect flow but cannot verify mobile ID tokens, hence `google-auth-library`.
- **Custom scheme deep link, cold start only**, read via `platformDispatcher.defaultRouteName` — no `url_launcher`/`app_links` dependency this phase.
- **Auth-first client, no dead UI**: landing screen shows the signed-in email + logout; the 3-tab nav shell is deliberately not built until Phase 2 gives it content.
- **Single refresh-on-401 retry** in the dio interceptor; on refresh failure → tokens cleared, logged-out state.
- **bcryptjs** (pure JS, no native build risk) for password hashing at cost 10.
- **Verification target is a physical Android phone (Android 8+, USB debugging, Google Play services)** connected via `adb` — `google_sign_in` requires Google Play services, and a phone sidesteps emulator resource limits. Backend reachability via `adb reverse tcp:3000 tcp:3000` (phone's `localhost:3000` → host's port 3000) with `API_BASE_URL=http://127.0.0.1:3000`; the emulator's `10.0.2.2` path remains as a default fallback. Cleartext HTTP allowed only in the debug manifest overlay, never release.
- **Reset email recipient must be the Resend-verified owner email** (sandbox limitation, see Known Issues below).

## Context from mission.md
- Core User Story 1 (sign up / log in, secure access from any device) is the phase's primary target; password reset was explicitly approved by the stakeholder as a supporting addition to Story 1.
- Stories 2–6 (search, browse, upload, playback, playlists) are not addressed by this phase — they map to roadmap Phases 2, 4, 5, 6 and are not scope creep here because the roadmap sequences them later.
- Naming flag: "Spotify" is an internal working title; no public store/domain under that name (app package `com.spotifyclone.*` is internal).
- Deadline vs. scope flag: this spec implements roadmap Phases 0 + 1 (the pre-deadline critical path), with Facebook/Apple and the nav shell explicitly deferred per roadmap.

## Context from tech-stack.md
- Client: Flutter `3.44.x`, Dart `3.12.x`; `flutter_riverpod ^2.6.x`; `flutter_secure_storage ^9.x`; `dio ^4.x` (new, this phase); `google_sign_in ^6.x` (new, this phase); `google_fonts ^6.x` (new, this phase); fonts Inter/Manrope.
- Backend: NestJS `^11.1.x`, Node.js `22.x LTS`; Prisma `^6.x`; `@nestjs/passport` + `passport-jwt`; `@nestjs/jwt ^11.x`, `bcryptjs ^3.x`, `google-auth-library ^9.x` (new, this phase); `resend` SDK (new, this phase).
- Database: PostgreSQL via Supabase free tier, **direct connection port 5432** (not the 6543 pooler).
- Pinned version check command (executor must verify before finishing): `npm list @nestjs/core @nestjs/jwt @nestjs/passport passport-jwt bcryptjs google-auth-library resend prisma @prisma/client` in `backend/`, and `flutter pub deps --style=compact | grep -E '^(dio|google_sign_in|google_fonts|flutter_riverpod|flutter_secure_storage) '` in `client/`.
- Known Issues carried forward verbatim (from tech-stack.md `## Known Issues`):
  - *Prisma × Supabase connection*: use the *direct* Postgres connection (port 5432) as `DATABASE_URL` for `prisma migrate`. Supabase's pooler (port 6543, transaction mode) breaks Prisma migrations and prepared-statement usage in some configurations. Pinning the direct port sidesteps a known class of P1001/P2010 failures.
  - *Resend free-tier sandbox*: until a sending domain is verified, Resend only delivers to the account owner's verified email address (the `resend.dev` sandbox). The password-reset walkthrough must use the account-owner email as the recipient, or a verified domain.

## User Stories Addressed
- Core User Story 1 (sign up + log in, email/password and Google; auto-login; logout). Password reset: explicitly stakeholder-approved addition serving Story 1 (recovering access is part of "securely access my account").
- Nothing else — any requirement not traceable to Story 1 or the approved reset addition was excluded (see Out), not silently included.

## Engineering Standards (carried from specs/engineering-standards.md)
- **Mocks/stubs policy** (verbatim): *Default: forbidden. No mocked API responses, no hardcoded "sample" tracks/playlists standing in for real database records, no fake auth bypass, anywhere in committed code — including the MVP phase in `roadmap.md`. The one-day MVP must be a real, thin slice (fewer features), not a fake version of the full feature set. The only exception: seed/fixture data explicitly labeled as a database seed script (e.g. `prisma/seed.ts`) used to populate a dev/demo environment with realistic-looking rows — this is not the same as mocking application logic, and must still flow through the real upload/auth code paths, not bypass them.*
  - Scoped application: test doubles (mocked PrismaService, mocked dio HTTP adapter, mocked secure-storage plugin) are permitted inside test files only, and only to isolate the code under test at an external boundary — they are test doubles, not app-logic mocks, and never appear in `lib/` or `src/` runtime code.
- **Debug logging** (verbatim): *No `console.log` / `print` / ad-hoc debug statements left in committed code. Use the NestJS `Logger` class server-side and structured, removable debug prints client-side only when explicitly requested for a specific diagnostic reason — and remove them before the feature is marked done.* No carve-out is granted this phase (the reset token must never be logged; it travels only in the email link).
- **Definition of Done (Production)** (verbatim): *A feature is done when: 1. Every acceptance criterion in its feature-spec has a passing automated check (unit/integration/widget test as appropriate), and 2. One manual walkthrough of the real user flow has been performed end-to-end (real signup → real upload → real playback, not a stubbed path) and confirmed working. Both are required. A green test suite alone does not count as done; neither does "looks right in a screenshot" alone.* This phase's manual walkthrough is: real signup → real login → real Google sign-in → real password reset (via real Resend email) → auto-login on relaunch → logout, all on the Android emulator.
- **Passing Verify steps** (verbatim): *Every `Verify` bullet in any future `plan.md` must be one of: a literal shell/test command plus the exact expected output, or, if no command exists (e.g. a UI interaction), the literal manual steps plus the exact expected screen state.* All Verify bullets in this plan.md follow this rule; vague verifies are invalid.
- **Rollback policy** (verbatim): *Default: revert. On an unrecoverable Verify failure, the executor reverts the failing group's changes back to the last passing group's committed state (`git reset --hard <last-good-commit>` or equivalent) and reports BLOCKED against a clean tree. Partial/broken changes are not left in place unless a future spec explicitly states otherwise for a specific group.* Group 1's `baseline: specs/` commit makes this executable; each group boundary is a natural commit point.

## External Dependencies
- **Supabase** project + `DATABASE_URL` (direct, port 5432) — created in Group 1 (per resources.md; user's supabase.com account required). No secret values in this repo.
- **Resend** API key + verified account-owner email — created in Group 1 (per resources.md; new row added this phase).
- **Google Cloud** OAuth client IDs (Android, iOS, Web) — created in Group 7 (per resources.md; user's Google account required; Android needs the debug keystore SHA-1).
- **Physical Android phone** (Android 8+, USB debugging enabled, Google Play services present) connected via adb — primary on-device verification target per stakeholder decision; emulator not required. iOS code is generated but not verifiable on this Linux host.
- **A real Google account signed in on the phone** for the Group 7 Google sign-in walkthrough.
- **JWT signing secret** — generated locally in Group 1 (`openssl rand -base64 64`), env-only.
