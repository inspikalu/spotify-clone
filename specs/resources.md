# Resources

External services, APIs, and credentials this project depends on. No secret values are ever recorded here — names and where to obtain them only.

| Service | Purpose | Where to obtain | Tier |
|---|---|---|---|
| Supabase | Postgres database + object storage (audio files, cover art) | https://supabase.com — create a free project, get `DATABASE_URL`, storage bucket keys from Project Settings → API | Free |
| Google OAuth | "Continue with Google" login | https://console.cloud.google.com — create OAuth 2.0 Client IDs: **Android** (package name + SHA-1 of debug keystore), **iOS** (bundle id), and **Web** (the `serverClientId` used by `google_sign_in` and the server-side ID-token audience) | Free |
| Resend | Password-reset emails | https://resend.com — create an account, get `RESEND_API_KEY` from API Keys; sandbox mode only delivers to the account-owner email until a domain is verified | Free |
| Apple Sign In | "Continue with Apple" login | https://developer.apple.com — requires a paid Apple Developer account ($99/yr) to configure Sign In with Apple; **flagged as a real cost**, not free-tier — confirm with stakeholder whether this is in scope for MVP or deferred | Paid (Apple Developer Program) |
| Facebook Login | "Continue with Facebook" login | https://developers.facebook.com — create an App, enable Facebook Login product | Free |
| JWT signing secret | Own email/password auth token signing | Generated locally (e.g. `openssl rand -base64 64`), stored as an env var — not a third-party service | N/A |

## Flag
Apple Sign In requires a paid Apple Developer account. Given the tight MVP deadline and zero-cost constraint stated for the database, recommend **deferring Apple Sign In past the MVP phase** unless the stakeholder already has a paid Apple Developer account. Google and Facebook login, plus core email/password auth, cover the MVP without any paid dependency. See `roadmap.md` for where this is sequenced.
