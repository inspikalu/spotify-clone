# Roadmap

## Flag: Deadline vs. Full Scope
The full scope in `mission.md` (all 6 user stories, pixel-close UI, production Definition of Done) is not realistically buildable, tested, and manually walked-through by tomorrow. Phase 0–3 below is the real, deadline-scoped MVP: a genuinely working (not faked) end-to-end slice covering signup → upload → play. Phases 4+ are the rest of the full scope, sequenced for after the deadline. Nothing in Phase 0–3 is a stub standing in for later phases — it's a smaller but fully real system.

---

## Phase 0 — Foundations (blocking everything else)
- Supabase project created; Postgres schema migrated via Prisma (`User`, `Track`, `Playlist`, `PlaylistTrack`, `LikedTrack` from `mission.md`'s data model)
- NestJS project skeleton: modules for `auth`, `tracks`, `playlists`, `users`
- Flutter project skeleton: navigation shell (bottom nav: Home / Search / Library), theme file with the color/type tokens
- **Merge Gate**: backend boots, connects to Supabase Postgres, and responds to a health-check endpoint; Flutter app builds and runs on a simulator showing the empty nav shell.

## Phase 1 — Auth (MVP scope)
- Email/password signup + login (JWT access + refresh, `flutter_secure_storage` for token persistence)
- Google OAuth login (Facebook and Apple deferred — see `resources.md` flag on Apple's paid requirement)
- Auto-login on relaunch, logout
- **Merge Gate**: a real account can be created, logged out of, and logged back into, on-device, with no mocked auth path.

## Phase 2 — Playback (MVP scope)
- Catalog streaming via signed/public URLs from Supabase Storage
- Track list screen showing catalog
- Mini-player + full Now Playing screen: play/pause/skip/seek, via `just_audio` + `audio_service`, background/lock-screen playback working
- **Merge Gate**: a catalog track can be played end-to-end, including background playback, on-device.

## Phase 3 — MVP Deadline Deliverable
- Home screen: "Your tracks" shelf + quick access grid (curated multi-shelf design deferred to Phase 5)
- Basic Library screen: list of tracks with sort (A-Z / Recents)
- **This is the state of the app at the stated deadline.** Everything below is post-deadline.

---

## Phase 4 — Playlists ✅ COMPLETE (2026-08-15, commit 1b82445)
- Create/rename/delete playlist; add/remove/reorder tracks; Liked Songs auto-playlist
- Playlist detail screen with gradient hero header

## Phase 5 — Search ✅ COMPLETE (2026-08-15, commit 4e2f544)
- Search bar with debounce, results across track/artist/album/playlist name
- Recent searches (local device storage)
- Pre-search browse/genre grid

## Phase 6 — Home Polish
- Multiple horizontal shelves ("Recently played," "Made for you" placeholder logic, genre browse grid)
- Gradient hero extraction from cover art on playlist/album detail

## Phase 7 — Remaining Social Auth
- Facebook Login integration
- Apple Sign In — **gated on stakeholder confirming a paid Apple Developer account is available** (see `resources.md`)

## Phase 8 — Hardening
- Full automated test coverage pass across critical paths (auth, upload, playback) per `engineering-standards.md`'s Definition of Done
- Empty states, loading skeletons, error/retry states throughout
- Performance pass: confirm 60fps shelf scrolling, cold start under 2s
