# دايرة / Daira

Flutter app for rotating savings circles (جمعيات), backed only by the Odoo 19
module `daira_backend`. Package `com.daira.circles`, links `daira://`
(the previous app uses `daira-legacy://`).

## Two apps: dev and prod

| | dev | prod |
|---|---|---|
| Android id | `com.daira.circles.dev` ("Daira Dev", grey icon) | `com.daira.circles` ("Daira") |
| Server | local Odoo (`config/local.json`) | production HTTPS (`config/prod.json`) |
| Links | `daira-dev://` | `daira://` |

Both install side by side. Each Odoo database has its own users, settings and
App Releases; set the backend setting "App link scheme" to `daira-dev` on the
dev database. Push uses one Firebase project with both apps.

Files kept out of git: `android/app/google-services.json` (Firebase),
`android/key.properties` and the `.jks` upload key, `config/local.json`.

## Run locally (dev)

1. In PyCharm run Odoo with `D:\odoo19\conf\daira.conf` (database `19_daira`, port `8019`).
2. Connect the phone with USB debugging and run `.\tool\run.ps1`
   (opens the adb tunnel, checks Odoo, runs the dev flavor).

## Release (prod)

1. Once: `.\tool\make-keystore.ps1` (back up the key and password).
2. Set `ODOO_URL` in `config/prod.json`, raise `version:` in `pubspec.yaml`.
3. `.\tool\release.ps1` builds `build\app\outputs\bundle\prodRelease\app-prod-release.aab`.
4. Upload to Google Play, then add the build in Odoo (Daira → App Releases)
   and choose optional or mandatory.

## Structure

| Folder | What lives there |
|---|---|
| `lib/core/api` | `ApiClient` for `/daira/api/v1`: envelope, client headers, token refresh, Idempotency-Key, app-wide signals |
| `lib/core/models` | Typed models (circle, round, obligation, home, notifications, app settings) and exact `Money` |
| `lib/core/data` | Repositories, one per API area |
| `lib/core/providers.dart` | Riverpod wiring, session, language/theme, start-up gates |
| `lib/app` | `DairaApp` and the router (gates → sign-in → app) |
| `lib/design` | Identity v2 tokens (generated colors), theme, Phosphor `AppIcons`, components |
| `lib/features` | Screens |
| `lib/l10n` | Arabic/English ARB files and message helpers |

The backend decides at start-up (`GET /app/config`): maintenance, forced or
optional update per build, currencies (suggested from the phone's country),
limits, feature flags and announcements. Any call that meets maintenance or a
forced update sends the app back to the right gate.

Money is always integers in minor units. Every money action sends the record
`version` and one `Idempotency-Key` per user action, reused on retry, so it is
applied once.

## Design

Colors come from `design/identity-v2/design-tokens.json`. After editing the JSON:

```powershell
python tool/gen_colors.py
```

Use `context.colors` for color roles, `AppIcons` for icons, `RingLoader` for
loading (the amber segment orbits the ring), `Skeleton` for lists and
`MessageView` for empty/blocked states.

## Checks

```powershell
dart format lib test
flutter analyze
flutter test
```
