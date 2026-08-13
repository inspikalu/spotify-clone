# Engineering Standards

Calibrated to project type: **Production application.** These rules are binding on every future feature-spec and executor run. Silence in any subsection below means the strictest reasonable default applies, as stated in each.

## Mocks / Stubs / Placeholder Data
**Default: forbidden.** No mocked API responses, no hardcoded "sample" tracks/playlists standing in for real database records, no fake auth bypass, anywhere in committed code — including the MVP phase in `roadmap.md`. The one-day MVP must be a real, thin *slice* (fewer features), not a fake version of the full feature set. The only exception: seed/fixture data explicitly labeled as a database seed script (e.g. `prisma/seed.ts`) used to populate a dev/demo environment with realistic-looking rows — this is not the same as mocking application logic, and must still flow through the real upload/auth code paths, not bypass them.

## Debug Logging
No `console.log` / `print` / ad-hoc debug statements left in committed code. Use the NestJS `Logger` class server-side and structured, removable debug prints client-side only when explicitly requested for a specific diagnostic reason — and remove them before the feature is marked done.

## Definition of Done (Production)
A feature is done when:
1. Every acceptance criterion in its feature-spec has a passing **automated check** (unit/integration/widget test as appropriate), and
2. One **manual walkthrough** of the real user flow has been performed end-to-end (real signup → real upload → real playback, not a stubbed path) and confirmed working.

Both are required. A green test suite alone does not count as done; neither does "looks right in a screenshot" alone.

## What Counts as a Passing Verify Step
Every `Verify` bullet in any future `plan.md` must be one of:
- A literal shell/test command plus the exact expected output (e.g. `npm run test auth.service.spec.ts` → `Tests: 4 passed, 4 total`), or
- If no command exists (e.g. a UI interaction), the literal manual steps plus the exact expected screen state (e.g. "tap Sign Up with a valid email → redirected to Home screen, mini-player hidden, top-left avatar shows initials").

Vague verifies ("confirm it works," "check that auth is fine") are invalid and must be rewritten before a spec is accepted.

## Rollback Policy
**Default: revert.** On an unrecoverable Verify failure, the executor reverts the failing group's changes back to the last passing group's committed state (`git reset --hard <last-good-commit>` or equivalent) and reports BLOCKED against a clean tree. Partial/broken changes are not left in place unless a future spec explicitly states otherwise for a specific group.

## Standards-Amendment Protocol
This file is not frozen, but it is never silently edited mid-build. If the same class of blocker, tech-stack gap, or research finding recurs across two or more feature specs, the executor proposes (does not make) an addition here, logged below with a decision.

## Amendment History
_(no entries yet)_
