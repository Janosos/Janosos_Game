# Authentication configuration

Janosos starts in the explicit local-development backend unless
`APP_BACKEND=supabase` is supplied. The local backend supports the complete
single-device campaign, economy, store, and Boss Rush with account-scoped
persistence. It neither publishes verified global results nor acts as a
production identity provider.

## Flutter defines

Never commit a Supabase secret/service-role key or a Google/Apple client
secret. The app accepts only public client configuration:

```powershell
C:\Users\junio\develop\flutter\bin\flutter.bat run `
  --dart-define=APP_BACKEND=supabase `
  --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_REPLACE_ME `
  --dart-define=AUTH_REDIRECT_URI=io.janosos.game://auth/callback `
  --dart-define=GOOGLE_WEB_CLIENT_ID=REPLACE_ME.apps.googleusercontent.com `
  --dart-define=GOOGLE_APPLE_CLIENT_ID=REPLACE_ME.apps.googleusercontent.com `
  --dart-define=CONTENT_VERSION=v6-preview-1
```

`GOOGLE_APPLE_CLIENT_ID` is the Google OAuth client ID for iOS/macOS, not an
Apple Sign-In identifier. Android uses the web client ID as its server client
ID. Missing provider IDs produce an actionable configuration error; they never
fall back to an insecure token flow.

## Supabase dashboard

1. Add `io.janosos.game://auth/callback` under Authentication > URL
   Configuration > Redirect URLs.
2. Enable email/password and decide whether email confirmation is mandatory.
3. Enable Google and Apple only after their public IDs and server-side secrets
   have been configured in the dashboard.
4. Enable manual identity linking before exposing the settings actions.
5. Enable secure password change.
6. Apply every checked-in migration in order with `supabase db push`.
7. Deploy all checked-in Edge Functions; JWT verification is defined in
   `supabase/config.toml`.

The delete function reads its service credential only from the Edge Function
environment. It accepts the signed-in user's JWT, requires a strong auth method
within ten minutes, and records only a SHA-256 user pseudonym plus an
idempotency receipt.

## Provider behavior

- Android, iOS, and macOS exchange native Google/Apple identity tokens directly
  with Supabase. Provider tokens are cleared after the exchange and are never
  stored by Janosos.
- Web, Windows, and Linux use browser-based OAuth with PKCE.
- Native Google requires the Google platform setup files/capabilities that
  correspond to the final package and bundle IDs.
- Native Apple requires the Sign in with Apple capability and a paid Apple
  Developer account before device testing.

## Deep links and packaging

Android, iOS, and macOS register `io.janosos.game://auth/callback` in their
checked-in platform manifests. Web needs no protocol registration; use an HTTPS
callback on a host that rewrites `/auth/callback` to the Flutter application if
you choose a web-specific redirect.

Windows protocol activation is forwarded by `windows/runner/main.cpp`. The
installer must register `io.janosos.game` as a protocol (MSIX
`protocol_activation`). An unpackaged debug executable cannot own a Windows
protocol without an explicit per-user registry registration, so that mutation
is intentionally not performed at application startup.

Linux uses the single-instance command-line/open handlers required by
`app_links`. Package `packaging/linux/io.janosos.game.desktop` with the final
binary and register its `x-scheme-handler/io.janosos.game` MIME entry during
installation.

## Protected local state

Native platforms persist the Supabase session only in
`flutter_secure_storage`. If secure storage cannot be verified, the app runs
fail-closed without persistent sessions or eligible offline progress. The web
implementation currently uses the same fail-closed behavior until an audited
Web Crypto + IndexedDB key lifecycle is delivered; it never downgrades session
tokens to plain `localStorage`.

## Drift web assets

The following official Drift 2.34.3 release assets are checked into `web/`:

- `sqlite3.wasm`: SHA-256
  `41CF968998241465D8B1DFFFB1EB60DD10C35DE5022A3647E14174EA3AF84143`
- `drift_worker.js`: SHA-256
  `4DB0469DE8CEABAD8D5CD3D920614486BA587E100E39523F36F704A3AEC5F26C`

Serve `.wasm` as `application/wasm` and keep both files at the Flutter web base
URL. Do not replace only one of the pair when upgrading Drift.
