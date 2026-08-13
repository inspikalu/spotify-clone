# Validation: Phase 1 — Auth (incl. Phase 0 groundwork)

## Acceptance Criteria
- [ ] Criterion 1: Real email/password signup works end-to-end (API + on-device UI); duplicate email rejected with 409.
- [ ] Criterion 2: Real login works; wrong credentials rejected with 401 and an error surfaced in the UI.
- [ ] Criterion 3: JWT access/refresh flow works — `/auth/me` authenticates with the access token; refresh rotates the pair; invalid refresh rejected 401.
- [ ] Criterion 4: Auto-login on relaunch: app relaunched from the launcher lands on the authenticated HomeScreen without re-entering credentials.
- [ ] Criterion 5: Logout clears both tokens from secure storage and returns to SignInScreen.
- [ ] Criterion 6: Google sign-in works with a real Google account (native chooser → consent → authenticated HomeScreen), no mocked path.
- [ ] Criterion 7: Password reset works with a real Resend email: forgot-password → 202 → email delivered → deep link opens ResetPasswordScreen → new password accepted → login succeeds with it.
- [ ] Criterion 8: `GET /health` returns `{"status":"ok","db":"up"}` proving Prisma ↔ Supabase connectivity over the direct connection (port 5432).
- [ ] Criterion 9: Phase 0 schema (User, Track, Playlist, PlaylistTrack, LikedTrack) is migrated to Supabase with relations intact (`npx prisma migrate status` reports up to date).
- [ ] Criterion 10: No mocked auth path anywhere in `client/lib/` or `backend/src/` (runtime code calls the real API/DB; test doubles exist only in test files).

## Merge Gate
- [ ] All Group verifies in plan.md pass, with pasted evidence (exact command output, not paraphrase):
  - Group 1: `git log -1 --pretty=%s` → `baseline: specs/`; `git status --porcelain` → empty
  - Group 2: `curl -s http://localhost:3000/health` → `{"status":"ok","db":"up"}`
  - Group 3: `npm test` → `Test Suites: 5 passed, 5 total` / `Tests: 18 passed, 18 total`; `npm run test:e2e` → `Test Suites: 1 passed, 1 total` / `Tests: 10 passed, 10 total`
  - Group 4: `flutter analyze` → `No issues found!`; `flutter test` → `All tests passed!`
  - Group 5: manual walkthrough steps 1–5 with observed screen states (pasted)
  - Group 6: curl → `202`; adb deep link → ResetPasswordScreen; reset → SignInScreen; login with new password → HomeScreen
  - Group 7: lint exits 0 with empty output; `npm test` → 18/18; `npm run test:e2e` → `Test Suites: 2 passed, 2 total` / `Tests: 12 passed, 12 total`; `flutter analyze` → `No issues found!`; `flutter test` → `All tests passed!`; Google walkthrough evidence; `git log -1 --pretty=%s` → `Phase 1: auth complete`
- [ ] Phase integrates without breaking prior phases — no prior phases are complete (Phase 0 groundwork is folded into this spec by stakeholder decision); nothing regresses the baseline commit.
- [ ] Lint/typecheck clean: `cd backend && npm run lint` → clean output; `cd ../client && flutter analyze` → `No issues found!`
- [ ] No mocks/stubs/placeholder logic outside what engineering-standards.md explicitly permits — check `client/lib/` and `backend/src/` contain no sample/hardcoded data or fake auth paths; test doubles confined to `**/*.spec.ts` and `client/test/`.
- [ ] No debug console.log/print statements left in code — run `grep -rn --include='*.ts' -E 'console\.(log|debug)' backend/src backend/test` and `grep -rn --include='*.dart' '\bprint\(' client/lib` → expect no matches (exit 1, empty output).
- [ ] Installed dependency versions match tech-stack.md's pinned versions:
  - Backend: run `npm list @nestjs/core @nestjs/jwt @nestjs/passport passport-jwt bcryptjs google-auth-library resend prisma @prisma/client` in `backend/` → expect each listed with major matching the pins (NestJS 11.x, @nestjs/jwt 11.x, bcryptjs 3.x, Prisma 6.x; note prisma/dev deps are fine) and `node --version` → `v22.x`
  - Client: run `flutter pub deps --style=compact | grep -E '^(dio|google_sign_in|google_fonts|flutter_riverpod|flutter_secure_storage) '` in `client/` → expect dio `4.x`, google_sign_in `6.x`, google_fonts `6.x`, flutter_riverpod `2.6.x`, flutter_secure_storage `9.x`; and `flutter --version` → `Flutter 3.44.x` / `Dart 3.12.x`
  - Paste outputs into the execution report.
- [ ] Diff summary reviewed — run `git diff --stat baseline..HEAD` (baseline = the `baseline: specs/` commit from Group 1), paste output, and confirm the changed-file list matches the execution report's claims (backend/ modules, prisma/schema.prisma, client/lib structure, client/android manifest, test files, this spec directory).
- [ ] Demo-able: on the Android phone (USB-connected, `adb reverse` active) with the backend running — sign up with a fresh email, log out, log back in, relaunch (auto-login), Google sign-in with a real account, password reset through a real Resend email, and `curl http://localhost:3000/health` showing `{"status":"ok","db":"up"}`.
