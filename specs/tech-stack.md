# Tech Stack

## Client
- **Flutter**: `3.44.x` (stable channel) — cross-platform, single codebase for iOS + Android, matches stakeholder requirement.
- **Dart**: `3.12.x` — ships with Flutter 3.44.
- **State management**: `flutter_riverpod ^2.6.x` — testable, scales better than `provider` for an app this size (auth state, playback state, library state all cross-cutting).
- **Audio playback**: `just_audio ^0.9.x` + `audio_service ^0.18.x` — the de facto standard for background/lock-screen audio playback in Flutter; anything homegrown here is a known time sink.
- **Secure token storage**: `flutter_secure_storage ^9.x`.
- **Image caching**: `cached_network_image ^3.x` — required for smooth 60fps scrolling on album art shelves.
- **HTTP client**: `dio ^4.x` — interceptors for attaching the JWT to every request and a single retry-on-401 refresh path; `http` would need the refresh logic hand-rolled in a wrapper.
- **Google sign-in (client)**: `google_sign_in ^6.x` — the standard native on-device Google OAuth flow on Android/iOS (returns an ID token the backend verifies).
- **Fonts**: `Inter` or `Manrope` (Google Fonts) as a visual substitute for Spotify's proprietary Circular typeface — do not bundle Circular itself, it is not licensed for use here. Delivered via `google_fonts ^6.x`.

## Backend
- **NestJS**: `^11.1.x` (stakeholder-mandated). Node.js `22.x LTS`.
- **ORM**: `Prisma ^6.x` — strong TypeScript integration with NestJS, straightforward migrations, good fit for the relational schema in `mission.md`'s data model.
- **Auth**: `@nestjs/passport` + `passport-jwt` (access + refresh token flow, own implementation) plus `passport-google-oauth20`, `passport-apple`, `passport-facebook` as optional social login strategies — mirrors Spotify's real login screen (email/password + Google/Apple/Facebook) without depending on any Spotify-proprietary system, which is undocumented/inaccessible anyway. Implementation details for the own-implementation flow: `@nestjs/jwt ^11.x` (JWT signing service), `bcryptjs ^3.x` (pure-JS password hashing, no native build step), `google-auth-library ^9.x` (server-side ID-token verification for the native `google_sign_in` flow — `passport-google-oauth20` alone cannot verify mobile ID tokens; it stays pinned for any future web redirect flow).
- **Transactional email**: `resend` (official SDK) — free tier (~3,000 emails/month) for the password-reset flow; a zero-cost fit given the deadline.
- **File uploads**: `@nestjs/platform-express` + `multer` for multipart handling, streamed to object storage (not held in server memory/disk longer than necessary).
- **Audio metadata extraction**: `music-metadata` (Node) — extract real duration/bitrate server-side; never trust client-reported duration.

## Database
- **PostgreSQL** via **Supabase** (free tier) — chosen over a self-hosted or split setup specifically because of the 1-day MVP deadline: one dashboard covers both Postgres and object storage, cutting setup time in the critical early phase. Free tier: 500MB database, 1GB file storage, 2GB bandwidth/month.
- **Development (current)**: local Supabase CLI instance (docker) per stakeholder decision at Phase 1 execution — same dashboard/services (Postgres, Storage, Studio, API) with zero account setup; cloud free-tier remains the documented target for deploy phases. On this host the local instance runs on offset ports (API 54323, Postgres 54324, Studio studio 54325) because a pre-existing unrelated Supabase stack already occupies the CLI defaults 54321/54322.

## File/Object Storage
- **Supabase Storage** (same free-tier project as the database) for audio files and cover art. Public bucket for cover art, signed-URL access for audio files (don't allow direct anonymous streaming links to bypass auth).

## Ruled Out
- **Firebase / Firestore** — ruled out: NoSQL doesn't fit the relational, join-heavy data model (ordered playlist tracks, many-to-many likes) as cleanly as Postgres; would fight the schema instead of fitting it.
- **Neon (Postgres) + Cloudflare R2 (storage) split setup** — technically viable and arguably more scalable long-term, but ruled out *for now* given the 1-day deadline: two dashboards/credential sets to wire up instead of one. Revisit post-MVP if Supabase's free-tier limits (500MB DB / 1GB storage) become a real constraint.
- **Railway / Render free Postgres** — ruled out: free tiers on both are more restrictive (spin-down/cold-start behavior, tighter storage caps) than Supabase's, with no bundled object storage.
- **GraphQL API** — ruled out: scope doesn't need it; REST is simpler to reason about and to write "exact command + expected output" Verify steps against.

## Change Log
- [2026-08-13] Phase 1: added `dio ^4.x` as the Flutter HTTP client because auth (and every later phase) needs client→API calls with a JWT-attach interceptor and a single refresh-on-401 path.
- [2026-08-13] Phase 1: added `google_sign_in ^6.x` (client) because on-device Google OAuth on Android/iOS requires the native platform flow; `passport-google-oauth20` covers only the server side.
- [2026-08-13] Phase 1: added `google_fonts ^6.x` as the delivery mechanism for the already-decided Inter/Manrope Google Fonts choice.
- [2026-08-13] Phase 1: added `@nestjs/jwt ^11.x`, `bcryptjs ^3.x`, and `google-auth-library ^9.x` because the own-implementation access/refresh flow needs a signing service, password hashing, and mobile ID-token verification respectively.
- [2026-08-13] Phase 1/Group 1: pivoted the *development* database to a local Supabase CLI instance (docker) per stakeholder decision — `supabase start` on offset ports (API 54323, Postgres 54324, Studio 54325) avoiding the pre-existing stack on 54321/54322; cloud free-tier stays the deployment target. Prisma `DATABASE_URL` is the direct local Postgres (no pooler involved).
- [2026-08-13] Phase 1/Group 1: tech-stack Known Issue added for the host's port collision (see Known Issues).
- [2026-08-13] Phase 1: added `resend` as the transactional email provider because the stakeholder-approved password-reset scope requires sending reset links from the own-implementation auth flow (Supabase Auth is not used).
- [2026-08-13] Phase 1: added `@nestjs/jwt ^11.x`, `bcryptjs ^3.x`, and `google-auth-library ^9.x` because the own-implementation access/refresh flow needs a signing service, password hashing, and mobile ID-token verification respectively.

## Known Issues
- **Local dev host port collision**: this machine runs a pre-existing unrelated Supabase docker stack on the CLI defaults 54321 (API) / 54322 (Postgres). Our local instance must keep the offset ports (API 54323, Postgres 54324, Studio 54325, etc.) configured in `supabase/config.toml`; `supabase start` without offsets will collide. Source: observed `docker ps` port mappings on this host.
- **Prisma × Supabase connection**: use the *direct* Postgres connection (port 5432) as `DATABASE_URL` for `prisma migrate`. Supabase's pooler (port 6543, transaction mode) breaks Prisma migrations and prepared-statement usage in some configurations. Pinning the direct port sidesteps a known class of P1001/P2010 failures. (Local instance: direct port 54324, no pooler.)
- **Resend free-tier sandbox**: until a sending domain is verified, Resend only delivers to the account owner's verified email address (the `resend.dev` sandbox). The password-reset walkthrough must use the account-owner email as the recipient, or a verified domain.
